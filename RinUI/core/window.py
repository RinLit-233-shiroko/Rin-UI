import ctypes
import os
import platform
from ctypes import wintypes

import win32con
from PySide6.QtCore import (
    QAbstractNativeEventFilter,
    QByteArray,
    QObject,
    QPoint,
    QPointF,
    Qt,
    QTimer,
    Slot,
)
from PySide6.QtGui import QCursor, QGuiApplication
from PySide6.QtQuick import QQuickItem, QQuickWindow
from win32api import GetSystemMetrics, MonitorFromWindow, SendMessage
from win32com.shell.shellcon import (
    ABM_GETSTATE,
    ABM_GETTASKBARPOS,
    ABS_AUTOHIDE,
)
from win32con import (
    HTMAXBUTTON,
    MONITOR_DEFAULTTONEAREST,
    MONITOR_DEFAULTTOPRIMARY,
    SM_CXVIRTUALSCREEN,
    SM_CYVIRTUALSCREEN,
    SW_MAXIMIZE,
)
from win32gui import FindWindow, GetWindowPlacement, ReleaseCapture

from RinUI.core.config import is_win11, is_windows
from RinUI.core.logger import logger


# [RinUI FIX] 标题栏是否交给 Windows 原生拖动(HTCAPTION)。
# 设为 0 可以退回旧行为(标题栏判成 HTCLIENT、由 QML 手动移动窗口), 出问题时可快速回滚。
NATIVE_CAPTION_DRAG = os.environ.get("RINUI_NATIVE_CAPTION_DRAG", "1").strip().lower() not in (
    "0",
    "false",
    "no",
    "off",
)


def native_caption_drag_disabled(window) -> bool:
    """窗口是否显式要求不要走原生标题栏拖动。

    供标题栏里放了自定义可交互内容的应用使用: 在窗口上设置
    ``titleBarNativeDragDisabled: true`` 即可让整条标题栏保持在客户区。
    """
    try:
        return bool(window.property("titleBarNativeDragDisabled"))
    except Exception:
        return False


def title_bar_button_width_px(window, dp_ratio: float) -> int:
    """标题栏右侧窗口控制按钮区的宽度(物理像素)。

    QML 侧 TitleBar 会把 ``windowControls.width`` 推到窗口的
    ``titleBarButtonWidth`` 属性上; 取不到时按三个 48px 按钮兜底。
    """
    try:
        width = float(window.property("titleBarButtonWidth") or 0)
    except Exception:
        width = 0.0
    if width <= 0:
        width = 144.0  # CtrlBtn 默认 48x48, 最小化 / 最大化 / 关闭共三个
    return int(width * dp_ratio)


# Windows 11 的 DWM 窗口圆角偏好(DWMWA_WINDOW_CORNER_PREFERENCE)
DWMWA_WINDOW_CORNER_PREFERENCE = 33
DWMWCP_DONOTROUND = 1
DWMWCP_ROUND = 2


def _snap_target_rects(work: wintypes.RECT):
    """Win11 贴靠布局可能产生的窗口矩形(相对工作区, 物理像素)。"""
    left, top = work.left, work.top
    width = work.right - work.left
    height = work.bottom - work.top
    targets = []

    def add(fx: float, fy: float, fw: float, fh: float):
        targets.append(
            (
                left + int(fx * width),
                top + int(fy * height),
                left + int((fx + fw) * width),
                top + int((fy + fh) * height),
            )
        )

    add(0.0, 0.0, 0.5, 1.0)  # 左半屏
    add(0.5, 0.0, 0.5, 1.0)  # 右半屏
    add(0.0, 0.0, 1.0, 0.5)  # 上半屏
    add(0.0, 0.5, 1.0, 0.5)  # 下半屏
    for index in range(3):  # 三分栏
        add(index / 3.0, 0.0, 1.0 / 3.0, 1.0)
    add(0.0, 0.0, 2.0 / 3.0, 1.0)  # 1/3 + 2/3(靠左)
    add(1.0 / 3.0, 0.0, 2.0 / 3.0, 1.0)  # 1/3 + 2/3(靠右)
    for fx in (0.0, 0.5):  # 四分栏
        for fy in (0.0, 0.5):
            add(fx, fy, 0.5, 0.5)
    return targets


def is_window_snapped(hwnd: int, tolerance: int = 12) -> bool:
    """窗口是否正处在贴靠(Snap)状态。

    Windows 没有公开的"这个窗口被贴靠了"接口, 这里拿窗口矩形去比对 Win11
    贴靠布局能产生的那些矩形(半屏 / 三分栏 / 四分栏)。留 tolerance 像素的
    余量, 因为贴靠时相邻窗口之间有一条几像素的间隙, 而且 DPR 换算也会差
    一两个像素。
    """
    try:
        user32 = ctypes.windll.user32
        rect = wintypes.RECT()
        if not user32.GetWindowRect(hwnd, ctypes.byref(rect)):
            return False
        monitor = user32.MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)
        info = MONITORINFO()
        info.cbSize = ctypes.sizeof(MONITORINFO)
        if not user32.GetMonitorInfoW(monitor, ctypes.byref(info)):
            return False
        work = info.rcWork
        if work.right - work.left <= 0 or work.bottom - work.top <= 0:
            return False
        for target in _snap_target_rects(work):
            if (
                abs(rect.left - target[0]) <= tolerance
                and abs(rect.top - target[1]) <= tolerance
                and abs(rect.right - target[2]) <= tolerance
                and abs(rect.bottom - target[3]) <= tolerance
            ):
                return True
        return False
    except Exception:
        return False


def title_bar_max_button_rect(window, dp_ratio: float):
    """最大化按钮在窗口内容区里的矩形(物理像素), 取不到返回 None。

    QML 侧 TitleBar 会把 ``maximizeBtn`` 的位置和尺寸推到窗口的
    ``titleBarMaxButtonRect`` 属性上。有了它, WM_NCHITTEST 才能对这一小块
    返回 HTMAXBUTTON, 让 Windows 11 认出"这是最大化按钮"。
    """
    try:
        rect = window.property("titleBarMaxButtonRect")
    except Exception:
        return None
    if rect is None:
        return None
    try:
        rect_x = float(rect.x())
        rect_y = float(rect.y())
        rect_w = float(rect.width())
        rect_h = float(rect.height())
    except Exception:
        return None
    if rect_w <= 1 or rect_h <= 1:
        return None
    return (
        int(rect_x * dp_ratio),
        int(rect_y * dp_ratio),
        int(rect_w * dp_ratio),
        int(rect_h * dp_ratio),
    )


# [RinUI FIX] 标题栏里承载应用自定义内容的两块"插槽"(TitleBar.qml 里的 objectName)
TITLE_BAR_LEADING_HOST = "rinuiTitleBarLeadingHost"
TITLE_BAR_CONTENT_HOST = "rinuiTitleBarContentHost"


def title_bar_safe_width_px(window, dp_ratio: float) -> int:
    """三个窗口按钮左边那条"必定可拖动"安全区的宽度(物理像素)。"""
    try:
        width = float(window.property("titleBarSafeWidth"))
    except Exception:
        width = 0.0
    if width <= 0:
        width = 32.0
    return int(width * dp_ratio)


def _walk_title_bar_hosts(root_item):
    """在窗口内容树的标题栏里找出两块内容插槽。"""
    hosts = []
    stack = [root_item]

    while stack:
        item = stack.pop()
        if item is None:
            continue
        try:
            if item.objectName() in (TITLE_BAR_LEADING_HOST, TITLE_BAR_CONTENT_HOST):
                hosts.append(item)
                continue
            stack.extend(item.childItems())
        except Exception:
            continue
    return hosts


def _accepts_left_button(item) -> bool:
    # QQuickItem::acceptedMouseButtons() 只有会接鼠标的项才返回非空:
    # ToolButton / TextField / MouseArea 之类是 LeftButton, 纯 Text、图标、矩形是 NoButton。
    try:
        return bool(item.acceptedMouseButtons() & Qt.MouseButton.LeftButton)
    except Exception:
        return False


# 文本类图元本身会接左键(选中/链接/悬停), 但在标题栏里它们只是图标和标题,
# 必须留给系统当拖动区域 —— 否则标题文字又变成"点住拖不动"了。
_PLAIN_TEXT_CLASSES = ("QQuickText", "QQuickPlaceholderText")


def _is_plain_text(item) -> bool:
    try:
        class_name = item.metaObject().className()
    except Exception:
        return False
    if class_name in _PLAIN_TEXT_CLASSES:
        return True
    # QML 里自定义的 Text / Label 组件, 类名形如 Text_QMLTYPE_28
    return class_name.startswith(("Text_QMLTYPE", "Label_QMLTYPE"))


def _collect_interactive_rects(item, target, out, depth=0):
    """收集插槽里真正会接鼠标的那些控件的矩形(相对 target)。"""
    if item is None or depth > 24:
        return
    try:
        if not item.isVisible() or not item.isEnabled():
            return
        item_w = item.width()
        item_h = item.height()
    except Exception:
        return
    if item_w <= 1 or item_h <= 1:
        return

    if _accepts_left_button(item) and not _is_plain_text(item):
        try:
            origin = item.mapToItem(target, QPointF(0.0, 0.0))
        except Exception:
            return
        out.append((origin.x(), origin.y(), item_w, item_h))
        # 命中一个控件就不再往里钻, 免得把它内部的零件也算成独立热区
        return

    try:
        children = item.childItems()
    except Exception:
        return
    for child in children:
        _collect_interactive_rects(child, target, out, depth + 1)


def title_bar_interactive_rects(window, dp_ratio: float):
    """标题栏里应用自己塞进来的控件的矩形(物理像素)。

    标题栏整体交给系统做 HTCAPTION 之后, 应用放到 ``titleBarArea`` /
    ``titleBarLeadingArea`` 里的控件(搜索框、返回按钮……)就落在了非客户区,
    鼠标事件会被 Windows 当成"拖动窗口"吃掉, 控件完全点不动。

    这里沿着项树找出插槽里真正接收鼠标左键的项(标题文字的 Text、图标都不算),
    把它们换算成窗口坐标的物理像素矩形; WM_NCHITTEST 命中时返回 HTCLIENT,
    把这一小块还给 QML —— 图标和标题文字则继续留在 HTCAPTION 上, 可以拖动。
    """
    try:
        root_item = window.contentItem()
    except Exception:
        return []
    if root_item is None:
        return []

    rects = []
    for host in _walk_title_bar_hosts(root_item):
        try:
            if not host.isVisible():
                continue
        except Exception:
            continue
        found = []
        _collect_interactive_rects(host, root_item, found)

        for rect_x, rect_y, rect_w, rect_h in found:
            rects.append(
                (
                    int(rect_x * dp_ratio),
                    int(rect_y * dp_ratio),
                    int(rect_w * dp_ratio),
                    int(rect_h * dp_ratio),
                )
            )
    return rects


# 定义 Windows 类型
ULONG_PTR = (
    ctypes.c_ulong if ctypes.sizeof(ctypes.c_void_p) == 4 else ctypes.c_ulonglong
)
LONG = ctypes.c_long


# 自定义结构体 MONITORINFO
class MONITORINFO(ctypes.Structure):
    _fields_ = [
        ("cbSize", wintypes.DWORD),
        ("rcMonitor", wintypes.RECT),
        ("rcWork", wintypes.RECT),
        ("dwFlags", wintypes.DWORD),
    ]


class MSG(ctypes.Structure):
    _fields_ = [
        ("hwnd", ctypes.c_void_p),
        ("message", wintypes.UINT),
        ("wParam", wintypes.WPARAM),
        ("lParam", wintypes.LPARAM),
        ("time", wintypes.DWORD),
        ("pt", wintypes.POINT),
    ]


class PWINDOWPOS(ctypes.Structure):
    _fields_ = [
        ("hWnd", wintypes.HWND),
        ("hwndInsertAfter", wintypes.HWND),
        ("x", ctypes.c_int),
        ("y", ctypes.c_int),
        ("cx", ctypes.c_int),
        ("cy", ctypes.c_int),
        ("flags", wintypes.UINT),
    ]


class NCCALCSIZE_PARAMS(ctypes.Structure):
    _fields_ = [("rgrc", wintypes.RECT * 3), ("lppos", ctypes.POINTER(PWINDOWPOS))]


class APPBARDATA(ctypes.Structure):
    _fields_ = [
        ("cbSize", wintypes.UINT),
        ("hWnd", wintypes.HWND),
        ("uCallbackMessage", wintypes.UINT),
        ("uEdge", wintypes.UINT),
        ("rc", wintypes.RECT),
        ("lParam", wintypes.LPARAM),
    ]


class MARGINS(ctypes.Structure):
    _fields_ = [
        ("cxLeftWidth", ctypes.c_int),
        ("cxRightWidth", ctypes.c_int),
        ("cyTopHeight", ctypes.c_int),
        ("cyBottomHeight", ctypes.c_int),
    ]


user32 = ctypes.windll.user32

# 定义必要的 Windows 常量
WM_NCCALCSIZE = 0x0083
WM_NCHITTEST = 0x0084
WM_SYSCOMMAND = 0x0112
WM_GETMINMAXINFO = 0x0024
WM_SIZE = 0x0005
WM_PAINT = 0x000F
WM_ERASEBKGND = 0x0014
WM_WINDOWPOSCHANGED = 0x0047
WM_DWMCOMPOSITIONCHANGED = 0x031E
WM_ACTIVATE = 0x0006
WM_NCACTIVATE = 0x0086
WM_ACTIVATEAPP = 0x001C
WM_SHOWWINDOW = 0x0018
WM_NCLBUTTONDOWN = 0x00A1
WM_NCLBUTTONUP = 0x00A2
WM_NCLBUTTONDBLCLK = 0x00A3
WM_NCMOUSEMOVE = 0x00A0
WM_MOUSEMOVE = 0x0200
WM_LBUTTONUP = 0x0202

WS_CAPTION = 0x00C00000
WS_THICKFRAME = 0x00040000
WS_BORDER = 0x00800000

SC_MINIMIZE = 0xF020
SC_MAXIMIZE = 0xF030
SC_RESTORE = 0xF120


class MINMAXINFO(ctypes.Structure):
    _fields_ = [
        ("ptReserved", wintypes.POINT),
        ("ptMaxSize", wintypes.POINT),
        ("ptMaxPosition", wintypes.POINT),
        ("ptMinTrackSize", wintypes.POINT),
        ("ptMaxTrackSize", wintypes.POINT),
    ]


def is_maximized(hwnd: int) -> bool:
    placement = GetWindowPlacement(hwnd)
    return placement[1] == SW_MAXIMIZE


def is_composition_enabled() -> bool:
    result = ctypes.c_int(0)
    ctypes.windll.dwmapi.DwmIsCompositionEnabled(ctypes.byref(result))
    return bool(result.value)


def find_window(hwnd: int):
    if not hwnd:
        return None

    windows = QGuiApplication.topLevelWindows()
    if not windows:
        return None

    for window in windows:
        if window and int(window.winId()) == hwnd:
            return window
    return None


def get_resize_border_thickness(hwnd: wintypes.HWND, horizontal=True) -> int:
    window = find_window(int(hwnd))
    if not window:
        return 0

    frame = win32con.SM_CXSIZEFRAME if horizontal else win32con.SM_CYSIZEFRAME
    result = GetSystemMetrics(frame) + GetSystemMetrics(92)

    if result > 0:
        return result

    thickness = 8 if is_composition_enabled() else 4
    return round(thickness * window.devicePixelRatio())


def is_exact_monitor_sized_window(window: QQuickWindow, hwnd: int) -> bool:
    if not window:
        return False

    monitor = user32.MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)
    if not monitor:
        return False

    monitor_info = MONITORINFO()
    monitor_info.cbSize = ctypes.sizeof(MONITORINFO)
    monitor_info.dwFlags = 0
    if not user32.GetMonitorInfoW(monitor, ctypes.byref(monitor_info)):
        return False

    rect = wintypes.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    geometry_matches_monitor = (
        rect.left == monitor_info.rcMonitor.left
        and rect.top == monitor_info.rcMonitor.top
        and rect.right == monitor_info.rcMonitor.right
        and rect.bottom == monitor_info.rcMonitor.bottom
    )
    if geometry_matches_monitor:
        return True

    screen = window.screen()
    ratio = screen.devicePixelRatio() if screen else window.devicePixelRatio()
    width = round(window.width() * ratio)
    height = round(window.height() * ratio)
    return (
        width == monitor_info.rcMonitor.right - monitor_info.rcMonitor.left
        and height == monitor_info.rcMonitor.bottom - monitor_info.rcMonitor.top
    )


class WinEventManager(QObject):
    def __init__(self):
        super().__init__()
        self.windows = []
        self.on_window_frame_changed = None
        self.pending_frame_sync_windows = []

    def set_windows(self, windows: list, on_window_frame_changed=None):
        self.windows = windows
        self.on_window_frame_changed = on_window_frame_changed

    def flush_pending_frame_sync_windows(self):
        pending_windows = self.pending_frame_sync_windows
        self.pending_frame_sync_windows = []
        for window in pending_windows:
            self.syncWindowFrame(window)

    @Slot(QObject, result=int)
    def getWindowId(self, window):
        """获取窗口的句柄"""
        logger.debug("GetWindowId: %s", window.winId())
        return int(window.winId())

    @Slot(result=QPoint)
    def cursorPos(self):
        """鼠标的全局坐标（设备无关像素, 与 window.x/y 同一坐标系）。

        QML 的 mouse.x/mouse.y 是"窗口内相对坐标", 窗口一移动坐标系就跟着移动,
        用它计算窗口位移会形成正反馈 —— 表现为拖动时窗口抖动甚至飞出屏幕。
        改用全局光标坐标做绝对定位就没有这个问题。
        """
        return QCursor.pos()

    @Slot(int)
    def drag_window_event(self, hwnd: int):
        """在Windows 用原生方法拖动"""
        if not is_windows() or type(hwnd) is not int or hwnd == 0:
            logger.debug(
                "Use Qt method to drag window on: %s"
                if not is_windows()
                else "Invalid window handle: %s",
                platform.system() if not is_windows() else hwnd,
            )
            return

        ReleaseCapture()
        SendMessage(
            hwnd, win32con.WM_SYSCOMMAND, win32con.SC_MOVE | win32con.HTCAPTION, 0
        )

    @Slot(QObject)
    def syncWindowFrame(self, window):
        if not is_windows() or window is None:
            return

        try:
            hwnd = int(window.winId())
        except Exception:
            if window not in self.pending_frame_sync_windows:
                self.pending_frame_sync_windows.append(window)
            return

        if not self.windows:
            if window not in self.pending_frame_sync_windows:
                self.pending_frame_sync_windows.append(window)
            return

        style = user32.GetWindowLongPtrW(hwnd, -16)
        user32.SetWindowLongPtrW(hwnd, -16, style | WS_CAPTION | WS_THICKFRAME)
        if window.property("backdropEnabled") and is_composition_enabled():
            margins = MARGINS(-1, -1, -1, -1)
            ctypes.windll.dwmapi.DwmExtendFrameIntoClientArea(
                hwnd, ctypes.byref(margins)
            )
        user32.SendMessageW(hwnd, WM_ACTIVATEAPP, 1, 0)
        user32.SendMessageW(hwnd, WM_NCACTIVATE, 1, 0)
        user32.SendMessageW(hwnd, WM_ACTIVATE, 1, 0)
        user32.SetWindowPos(
            hwnd, 0, 0, 0, 0, 0, 0x0002 | 0x0001 | 0x0004 | 0x0010 | 0x0020
        )
        window.requestActivate()
        if self.on_window_frame_changed is not None:
            QTimer.singleShot(0, self.on_window_frame_changed)

    @Slot(QObject)
    def maximizeWindow(self, window):
        """在Windows上最大化或还原窗口"""
        if not is_windows() or window is None:
            logger.debug(
                "Use Qt method to toggle window state on: %s"
                if not is_windows()
                else "Invalid window object",
                platform.system(),
            )
            return

        try:
            hwnd = int(window.winId())
            if is_maximized(hwnd):
                window.showNormal()
            else:
                window.showMaximized()

        except Exception as err:
            logger.error("Error toggling window state: %s", err)


class WinEventFilter(QAbstractNativeEventFilter):
    def __init__(self, windows: list, on_window_visible=None):
        super().__init__()
        self.windows = windows  # 接受多个窗口
        self.hwnds = {}  # 用于存储每个窗口的 hwnd
        self.resize_border = 8
        # 最大化按钮的"按下中"状态: 按下只记录, 松开才真正切换窗口状态,
        # 和 QML 里其它 CtrlBtn(MouseArea.onClicked) 的手感保持一致
        self.max_button_pressed_hwnd = 0
        # 每个窗口当前写入的圆角偏好, 只在状态变化时才调 DwmSetWindowAttribute
        self._corner_state = {}

        for window in self.windows:
            # 使用lambda创建闭包来捕获特定的窗口对象
            window.visibleChanged.connect(
                lambda visible, w=window: self._on_visible_changed(visible, w)
            )

    def initialize_windows(self):
        for window in self.windows:
            self._init_window_handle(window)

    def _on_visible_changed(self, visible: bool, window: QQuickWindow):
        if visible and self.hwnds.get(window) is None:
            self._init_window_handle(window)

    def _update_window_corner(self, window: QQuickWindow, hwnd: int):
        """按贴靠 / 最大化状态切换窗口圆角。

        Windows 11 里被贴靠(或最大化)的窗口是直角, 手动拖离贴靠之后才恢复
        圆角。主题层启动时一律写成了 DWMWCP_ROUND, 于是贴靠状态下还留着
        圆角, 这里跟着几何状态把它纠正过来。
        """
        if not is_win11():
            return
        try:
            square = is_maximized(hwnd) or is_window_snapped(hwnd)
        except Exception:
            return
        value = DWMWCP_DONOTROUND if square else DWMWCP_ROUND
        if self._corner_state.get(hwnd) == value:
            return
        preference = ctypes.c_int(value)
        try:
            result = ctypes.windll.dwmapi.DwmSetWindowAttribute(
                hwnd,
                DWMWA_WINDOW_CORNER_PREFERENCE,
                ctypes.byref(preference),
                ctypes.sizeof(preference),
            )
        except Exception:
            return
        if result == 0:
            self._corner_state[hwnd] = value
        # 让 QML 那边也知道要不要画圆角: 贴靠/最大化时窗口内容是直角的,
        # 背景矩形的 radius 和关闭按钮高亮的圆角都得跟着变
        try:
            if bool(window.property("windowCornersSquare")) != square:
                window.setProperty("windowCornersSquare", square)
        except Exception:
            pass

    def _toggle_maximize(self, window: QQuickWindow):
        """最大化 / 还原切换(给非客户区最大化按钮的点击兜底用)。"""
        try:
            hwnd = int(window.winId())
            if is_maximized(hwnd):
                window.showNormal()
            else:
                window.showMaximized()
        except Exception as exc:  # noqa: BLE001
            logger.debug("[RinUI] toggle maximize failed: %s", exc)

    def _pointer_over_max_button(self, window: QQuickWindow) -> bool:
        """光标当前是否停在最大化按钮上(物理像素比较, 与命中测试口径一致)。"""
        try:
            hwnd = self.hwnds.get(window) or int(window.winId())
            screen = window.screen()
            dp_ratio = screen.devicePixelRatio() if screen else 1.0
            max_rect = title_bar_max_button_rect(window, dp_ratio)
            if max_rect is None:
                return False
            point = wintypes.POINT()
            user32.GetCursorPos(ctypes.byref(point))
            origin = wintypes.POINT(0, 0)
            user32.ClientToScreen(hwnd, ctypes.byref(origin))
            cx = point.x - origin.x
            cy = point.y - origin.y
            mx, my, mw, mh = max_rect
            return mx <= cx < mx + mw and my <= cy < my + mh
        except Exception:
            return False

    def _set_max_button_pressed(self, window: QQuickWindow, pressed: bool):
        """把最大化按钮的按下状态回填给 QML(CtrlBtn 的按下态高亮)。"""
        try:
            if bool(window.property("titleBarMaxButtonPressed")) != pressed:
                window.setProperty("titleBarMaxButtonPressed", pressed)
        except Exception:
            pass

    def _set_max_button_hover(self, window: QQuickWindow, hovered: bool):
        """把最大化按钮的悬停状态回填给 QML。

        那一小块被 WM_NCHITTEST 判成 HTMAXBUTTON 之后就不再产生客户区鼠标
        事件, QML 的 HoverHandler 永远收不到进入/离开, 按钮的高亮和 ToolTip
        都出不来。这里只在状态变化时写一次属性, 避免每次命中测试都触发绑定。
        """
        try:
            if bool(window.property("titleBarMaxButtonHovered")) != hovered:
                window.setProperty("titleBarMaxButtonHovered", hovered)
        except Exception:
            pass

    def _init_window_handle(self, window: QQuickWindow):
        hwnd = int(window.winId())
        self.hwnds[window] = hwnd
        self.sync_window_backdrop(window)

    def sync_window_backdrop(self, window: QQuickWindow):
        self.set_window_styles(window)
        self.extend_frame_into_client_area(window)
        self.apply_fullscreen_opengl_border_workaround(window)

    def set_window_styles(self, window: QQuickWindow):
        hwnd = self.hwnds.get(window)
        if hwnd is None:
            return

        style = user32.GetWindowLongPtrW(hwnd, -16)  # GWL_STYLE
        new_style = style | WS_CAPTION | WS_THICKFRAME
        if new_style == style:
            return

        user32.SetWindowLongPtrW(hwnd, -16, new_style)  # GWL_STYLE
        window.setProperty("_rinuiWindowStyleChanged", True)
        self.refresh_window_frame(window)

    def refresh_window_frame(self, window: QQuickWindow):
        hwnd = self.hwnds.get(window)
        if hwnd is None:
            return

        user32.SetWindowPos(
            hwnd, 0, 0, 0, 0, 0, 0x0002 | 0x0001 | 0x0004 | 0x0010 | 0x0020
        )  # SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED

    def refresh_window_frame_if_needed(self, window: QQuickWindow):
        hwnd = self.hwnds.get(window)
        if hwnd is None:
            return

        if not window.property("_rinuiWindowStyleChanged"):
            return

        window.setProperty("_rinuiWindowStyleChanged", False)
        self.refresh_window_frame(window)

    def extend_frame_into_client_area(self, window: QQuickWindow):
        if not window.property("backdropEnabled"):
            return

        hwnd = self.hwnds.get(window)
        if hwnd is None or not is_composition_enabled():
            return

        margins = MARGINS(-1, -1, -1, -1)
        ctypes.windll.dwmapi.DwmExtendFrameIntoClientArea(
            hwnd, ctypes.byref(margins)
        )

    def apply_fullscreen_opengl_border_workaround(self, window: QQuickWindow):
        if not window.property("enableFullscreenOpenGLBorderWorkaround"):
            return

        hwnd = self.hwnds.get(window)
        if hwnd is None or not is_exact_monitor_sized_window(window, hwnd):
            return

        style = user32.GetWindowLongPtrW(hwnd, -16)
        if style & WS_BORDER:
            return

        user32.SetWindowLongPtrW(hwnd, -16, style | WS_BORDER)
        self.refresh_window_frame(window)

    def nativeEventFilter(self, event_type: QByteArray, message):
        if event_type not in (b"windows_generic_MSG", b"windows_dispatcher_MSG"):
            return False, 0

        try:
            message_addr = int(message)
        except Exception:
            buf = memoryview(message)
            message_addr = ctypes.addressof(ctypes.c_char.from_buffer(buf))

        # 直接使用内存地址访问 MSG 字段
        hwnd = ctypes.c_void_p.from_address(message_addr).value
        message_id = wintypes.UINT.from_address(
            message_addr + ctypes.sizeof(ctypes.c_void_p)
        ).value
        w_param = wintypes.WPARAM.from_address(
            message_addr + 2 * ctypes.sizeof(ctypes.c_void_p)
        ).value
        l_param = wintypes.LPARAM.from_address(
            message_addr + 3 * ctypes.sizeof(ctypes.c_void_p)
        ).value

        # 遍历每个窗口，检查哪个窗口收到了消息
        for window in self.windows:
            hwnd_window = self.hwnds.get(window)
            if hwnd_window != hwnd:
                continue

            if message_id in (
                WM_SIZE,
                WM_WINDOWPOSCHANGED,
                WM_SHOWWINDOW,
                WM_ACTIVATE,
                WM_NCACTIVATE,
                WM_ACTIVATEAPP,
                WM_DWMCOMPOSITIONCHANGED,
            ):
                self.extend_frame_into_client_area(window)

            if message_id in (
                WM_SIZE,
                WM_WINDOWPOSCHANGED,
                WM_DWMCOMPOSITIONCHANGED,
            ):
                self.apply_fullscreen_opengl_border_workaround(window)

            if message_id in (
                WM_SIZE,
                WM_WINDOWPOSCHANGED,
                WM_DWMCOMPOSITIONCHANGED,
                0x0232,  # WM_EXITSIZEMOVE: 拖拽/贴靠结束后再判一次
            ):
                self._update_window_corner(window, hwnd_window)

            if message_id in (WM_NCLBUTTONDOWN, WM_NCLBUTTONDBLCLK) and (
                w_param == HTMAXBUTTON
            ):
                # [RinUI FIX] 最大化按钮的点击得由我们自己兜住。
                #
                # WM_NCCALCSIZE 把整个非客户区都去掉了, DefWindowProc 的非客户区
                # 按钮状态机找不到按钮矩形, 于是这声点击被直接吞掉 —— 表现就是
                # "能弹出 Snap 布局选择器, 但点按钮完全没反应"。
                #
                # 按下时只记录状态, 真正切换留到松开: QML 里的最小化/关闭是
                # MouseArea.onClicked, 也是松开才触发, 这样三个按钮手感一致。
                self.max_button_pressed_hwnd = hwnd_window
                self._set_max_button_pressed(window, True)
                # 抓住鼠标: 否则指针一离开窗口, 松开消息就再也收不到,
                # 按下态会一直亮着(这正是最初"挪开不消失"的原因)
                user32.SetCapture(hwnd_window)
                return True, 0

            if message_id in (WM_NCLBUTTONUP, WM_LBUTTONUP) and (
                self.max_button_pressed_hwnd == hwnd_window
            ):
                self.max_button_pressed_hwnd = 0
                self._set_max_button_pressed(window, False)
                user32.ReleaseCapture()
                # 松开时指针还在按钮上才算一次点击(和 MouseArea.onClicked 一致);
                # 按住在外面松开只是取消, 不改窗口状态
                if self._pointer_over_max_button(window):
                    # 延后到下一轮事件循环, 避免在松开处理的调用栈里跑
                    # SetWindowPos(那样会引起嵌套的窗口消息分发)
                    QTimer.singleShot(0, lambda w=window: self._toggle_maximize(w))
                return True, 0

            if self.max_button_pressed_hwnd and message_id in (0x0201, 0x001F):
                # WM_LBUTTONDOWN / WM_CANCELMODE: 按下后滑走或被取消, 清掉挂起状态
                self.max_button_pressed_hwnd = 0
                self._set_max_button_pressed(window, False)
                user32.ReleaseCapture()

            if message_id == WM_NCHITTEST:
                x = ctypes.c_short(l_param & 0xFFFF).value
                y = ctypes.c_short((l_param >> 16) & 0xFFFF).value

                # 每次命中测试先把悬停状态复位, 命中最大化按钮时再置 True
                self._set_max_button_hover(window, False)

                rect = wintypes.RECT()
                user32.GetWindowRect(hwnd_window, ctypes.byref(rect))
                left, top, right, bottom = (
                    rect.left,
                    rect.top,
                    rect.right,
                    rect.bottom,
                )
                border = self.resize_border

                if left <= x < left + border:
                    if top <= y < top + border:
                        return True, 13  # HTTOPLEFT
                    if bottom - border <= y < bottom:
                        return True, 16  # HTBOTTOMLEFT
                    return True, 10  # HTLEFT
                if right - border <= x < right:
                    if top <= y < top + border:
                        return True, 14  # HTTOPRIGHT
                    if bottom - border <= y < bottom:
                        return True, 17  # HTBOTTOMRIGHT
                    return True, 11  # HTRIGHT
                if top <= y < top + border:
                    return True, 12  # HTTOP
                if bottom - border <= y < bottom:
                    return True, 15  # HTBOTTOM

                # 标题栏区域返回 HTCAPTION 让 Windows 处理原生窗口交互
                try:
                    title_bar_height = window.property("titleBarHeight")
                except Exception:
                    title_bar_height = None
                if not title_bar_height:
                    title_bar_height = 32
                screen = window.screen()
                dp_ratio = screen.devicePixelRatio() if screen else 1.0
                title_bar_height_px = int(title_bar_height * dp_ratio)
                if top <= y < top + title_bar_height_px:
                    # [RinUI FIX] 这里必须返回真正的 HTCAPTION, 也就是 2。
                    #
                    # 原来返回的 1 是 HTCLIENT —— 注释写着 HTCAPTION, 数值却是客户区。
                    # 于是系统从来没有接管过标题栏拖动, 全靠 QML 的 onPressed 里
                    # 同步 SendMessage(WM_SYSCOMMAND, SC_MOVE) 手动进入模态移动循环;
                    # 那个循环会吞掉 WM_LBUTTONUP, 而它前面的 ReleaseCapture() 又
                    # 提前清掉了 Qt 的隐式抓取, 导致 Qt 补发的 QRelease 送不回那个
                    # MouseArea —— pressed 永久停在 true, 之后每一次按下都被丢弃,
                    # 表现就是"标题栏按了没反应 / 拖不动"。
                    #
                    # 现在除右侧窗口控制按钮区外, 整条标题栏都交给系统原生处理,
                    # 顺带找回双击最大化、Aero Snap、拖到屏幕边缘贴靠等行为。
                    if NATIVE_CAPTION_DRAG and not native_caption_drag_disabled(window):
                        # [RinUI FIX] 最大化按钮单独返回 HTMAXBUTTON(9)。
                        # Windows 11 的 Snap Layouts(把鼠标停在最大化按钮上
                        # 弹出的布局选择器)只认这个命中码 —— 返回 HTCLIENT 时
                        # 系统根本不知道那块地方是"最大化按钮", 也就不会弹。
                        # 其余按钮仍然留在客户区, 交给 QML 的 CtrlBtn 处理。
                        client_pt = wintypes.POINT(0, 0)
                        user32.ClientToScreen(hwnd_window, ctypes.byref(client_pt))
                        cx = x - client_pt.x
                        cy = y - client_pt.y

                        max_rect = title_bar_max_button_rect(window, dp_ratio)
                        if max_rect is not None:
                            mx, my, mw, mh = max_rect
                            # 外扩 2px: DPR 取整后按钮边缘可能差一两个像素
                            if (
                                mx - 2 <= cx < mx + mw + 2
                                and my - 2 <= cy < my + mh + 2
                            ):
                                self._set_max_button_hover(window, True)
                                return True, HTMAXBUTTON

                        button_px = title_bar_button_width_px(window, dp_ratio)
                        safe_px = title_bar_safe_width_px(window, dp_ratio)
                        # 三个按钮左边一定留一条可拖动的安全区: 窗口再窄、
                        # 标题栏里的控件再长, 也不至于整条标题栏都没地方按住。
                        drag_limit = (right - left) - button_px - safe_px

                        # [RinUI FIX] 标题栏里应用自己塞进来的控件必须留在客户区。
                        # 整条标题栏判成 HTCAPTION 之后, 搜索框、返回按钮这些控件
                        # 就落在非客户区, 按下会被系统当成"开始拖动窗口", 控件
                        # 完全点不动 —— 这里把这些矩形扣出来还给 QML。
                        # 只有"会接鼠标左键"的项算控件: 窗口图标和标题文字的
                        # Text 不算, 它们仍然留在 HTCAPTION 上, 可以拖动窗口。
                        if cx < drag_limit:
                            for ix, iy, iw, ih in title_bar_interactive_rects(
                                window, dp_ratio
                            ):
                                # 控件再长也压不过安全区
                                if (
                                    ix <= cx < min(ix + iw, drag_limit)
                                    and iy <= cy < iy + ih
                                ):
                                    return True, 1  # HTCLIENT: 交给 QML 处理

                        if x < right - button_px:
                            return True, 2  # HTCAPTION
                        return True, 1  # 窗口控制按钮: 留在客户区交给 QML

                    return True, 1  # 原生拖动被关闭时的旧行为

                # 其他区域不处理
                return False, 0

            if message_id in (0x02A2, 0x02A3):  # WM_NCMOUSELEAVE / WM_MOUSELEAVE
                # 光标离开窗口时补一次悬停复位, 免得高亮卡在最大化按钮上。
                # 按下态不在这里清: 按住挪出按钮再松开时, 高亮应该保持到松开为止
                # (和 QML 里另外两个按钮的 MouseArea 表现一致)。
                self._set_max_button_hover(window, False)

            # 移除标题栏
            if message_id == WM_NCCALCSIZE and w_param:
                client_rect = ctypes.cast(
                    l_param, ctypes.POINTER(NCCALCSIZE_PARAMS)
                ).contents.rgrc[0]
                if is_maximized(hwnd):
                    ty = get_resize_border_thickness(hwnd, False)
                    client_rect.top += ty
                    client_rect.bottom -= ty
                    tx = get_resize_border_thickness(hwnd, True)
                    client_rect.left += tx
                    client_rect.right -= tx
                    abd = APPBARDATA()
                    ctypes.memset(ctypes.byref(abd), 0, ctypes.sizeof(abd))
                    abd.cbSize = ctypes.sizeof(APPBARDATA)
                    taskbar_state = ctypes.windll.shell32.SHAppBarMessage(
                        ABM_GETSTATE, ctypes.byref(abd)
                    )
                    if taskbar_state & ABS_AUTOHIDE:
                        edge = -1
                        abd2 = APPBARDATA()
                        ctypes.memset(ctypes.byref(abd2), 0, ctypes.sizeof(abd2))
                        abd2.cbSize = ctypes.sizeof(APPBARDATA)
                        abd2.hWnd = FindWindow("Shell_TrayWnd", None)
                        if abd2.hWnd:
                            window_monitor = MonitorFromWindow(
                                hwnd, MONITOR_DEFAULTTONEAREST
                            )
                            if window_monitor:
                                taskbar_monitor = MonitorFromWindow(
                                    abd2.hWnd, MONITOR_DEFAULTTOPRIMARY
                                )
                                if (
                                    taskbar_monitor
                                    and taskbar_monitor == window_monitor
                                ):
                                    ctypes.windll.shell32.SHAppBarMessage(
                                        ABM_GETTASKBARPOS, ctypes.byref(abd2)
                                    )
                                    edge = abd2.uEdge
                        top = edge == 1
                        bottom = edge == 3
                        left = edge == 0
                        right = edge == 2
                        if top:
                            client_rect.top += 1
                        elif bottom:
                            client_rect.bottom -= 1
                        elif left:
                            client_rect.left += 1
                        elif right:
                            client_rect.right -= 1
                        else:
                            client_rect.bottom -= 1
                return True, 0

            # 支持动画
            if message_id == WM_SYSCOMMAND:
                return False, 0

            # 处理 WM_GETMINMAXINFO 消息以支持 Snap 功能
            if message_id == WM_GETMINMAXINFO:
                # 获取屏幕工作区大小
                monitor = user32.MonitorFromWindow(
                    hwnd_window, 2
                )  # MONITOR_DEFAULTTONEAREST

                # 使用自定义的 MONITORINFO 结构
                monitor_info = MONITORINFO()
                monitor_info.cbSize = ctypes.sizeof(MONITORINFO)
                monitor_info.dwFlags = 0
                user32.GetMonitorInfoW(monitor, ctypes.byref(monitor_info))

                # 获取 MINMAXINFO 结构
                minmax_info = MINMAXINFO.from_address(l_param)

                # 最大化位置和大小
                # [RinUI FIX] 原来 ptMaxSize 用的是 rcWork.right - rcMonitor.left,
                # 把"工作区右边界"和"显示器左边界"相减: 单显示器 + 任务栏在下方时
                # 凑巧等于工作区宽度, 多显示器(rcMonitor.left 可能为负)或任务栏在
                # 左侧时算出来的最大化尺寸就是错的。这里统一用工作区的宽高。
                monitor_w = monitor_info.rcWork.right - monitor_info.rcWork.left
                monitor_h = monitor_info.rcWork.bottom - monitor_info.rcWork.top
                minmax_info.ptMaxPosition.x = (
                    monitor_info.rcWork.left - monitor_info.rcMonitor.left
                )
                minmax_info.ptMaxPosition.y = (
                    monitor_info.rcWork.top - monitor_info.rcMonitor.top
                )
                minmax_info.ptMaxSize.x = monitor_w
                minmax_info.ptMaxSize.y = monitor_h

                def get_window_int_property(window, name, default):
                    val = getattr(window, name, default)
                    if callable(val):
                        val = val()  # 如果是方法就调用
                    if val is None:
                        val = default
                    return int(val)

                screen = window.screen()
                dp_ratio = screen.devicePixelRatio() if screen else 1.0

                min_w = int(
                    get_window_int_property(window, "minimumWidth", 0) * dp_ratio
                )
                min_h = int(
                    get_window_int_property(window, "minimumHeight", 0) * dp_ratio
                )
                # [RinUI FIX] maximumWidth/Height 的 Qt 默认值是 16777215(无限制)。
                # 原来连它一起乘 dp_ratio: 150% 缩放下 ptMaxTrackSize 会变成 25165822
                # —— 比虚拟屏幕大几十倍。Windows 的贴靠(snap)布局会把 ptMaxTrackSize
                # 带进几何计算, 这个数量级没有任何好处, 把"无限制"换成虚拟屏幕尺寸。
                virtual_w = GetSystemMetrics(SM_CXVIRTUALSCREEN) or monitor_w
                virtual_h = GetSystemMetrics(SM_CYVIRTUALSCREEN) or monitor_h

                def track_limit(property_name, fallback):
                    value = int(
                        get_window_int_property(window, property_name, 16777215)
                    )
                    if value >= 16777215:
                        return int(fallback)
                    return max(1, int(value * dp_ratio))

                max_w = track_limit("maximumWidth", virtual_w)
                max_h = track_limit("maximumHeight", virtual_h)

                minmax_info.ptMinTrackSize.x = min_w
                minmax_info.ptMinTrackSize.y = min_h
                minmax_info.ptMaxTrackSize.x = max_w
                minmax_info.ptMaxTrackSize.y = max_h

                return True, 0

        return False, 0
