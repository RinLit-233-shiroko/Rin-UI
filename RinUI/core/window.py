import ctypes
import json
import os
import platform
import time
import urllib.request
from ctypes import wintypes

import win32con
from PySide6.QtCore import QAbstractNativeEventFilter, QByteArray, QObject, QTimer, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickWindow
from win32api import GetSystemMetrics, MonitorFromWindow, SendMessage
from win32com.shell.shellcon import (
    ABM_GETSTATE,
    ABM_GETTASKBARPOS,
    ABS_AUTOHIDE,
)
from win32con import (
    MONITOR_DEFAULTTONEAREST,
    MONITOR_DEFAULTTOPRIMARY,
    SW_MAXIMIZE,
)
from win32gui import FindWindow, GetWindowPlacement, ReleaseCapture

from RinUI.core.config import is_windows


#region debug-point rhi-white-backdrop-window
_DEBUG_SESSION_ID = os.environ.get("DEBUG_SESSION_ID", "rhi-white-backdrop")
_DEBUG_SERVER_URL = os.environ.get("DEBUG_SERVER_URL", "http://127.0.0.1:7777/event")
_DEBUG_MESSAGE_COUNTS = {}


def _debug_enabled() -> bool:
    return os.environ.get("RINUI_DEBUG_WINDOWS_WHITE_BACKDROP", "1") == "1"


def _debug_report(event: str, payload: dict) -> None:
    if not _debug_enabled():
        return
    data = json.dumps(
        {
            "session": _DEBUG_SESSION_ID,
            "source": "window",
            "event": event,
            "timestamp": time.time(),
            "payload": payload,
        },
        default=str,
    ).encode("utf-8")
    try:
        request = urllib.request.Request(
            _DEBUG_SERVER_URL,
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        urllib.request.urlopen(request, timeout=0.15).close()
    except Exception:
        pass


def _debug_rect(rect) -> list:
    return [rect.left, rect.top, rect.right, rect.bottom]


def _debug_value(value):
    return getattr(value, "value", str(value))


def _debug_window_native_snapshot(hwnd: int) -> dict:
    rect = wintypes.RECT()
    client_rect = wintypes.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    user32.GetClientRect(hwnd, ctypes.byref(client_rect))
    return {
        "hwnd": hwnd,
        "style": user32.GetWindowLongPtrW(hwnd, -16),
        "exStyle": user32.GetWindowLongPtrW(hwnd, -20),
        "windowRect": _debug_rect(rect),
        "clientRect": _debug_rect(client_rect),
        "compositionEnabled": is_composition_enabled(),
        "isMaximized": is_maximized(hwnd),
    }
#endregion


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
_DEBUG_MESSAGE_NAMES = {
    WM_NCCALCSIZE: "WM_NCCALCSIZE",
    WM_SIZE: "WM_SIZE",
    WM_PAINT: "WM_PAINT",
    WM_ERASEBKGND: "WM_ERASEBKGND",
    WM_WINDOWPOSCHANGED: "WM_WINDOWPOSCHANGED",
    WM_DWMCOMPOSITIONCHANGED: "WM_DWMCOMPOSITIONCHANGED",
    WM_ACTIVATE: "WM_ACTIVATE",
    WM_NCACTIVATE: "WM_NCACTIVATE",
    WM_ACTIVATEAPP: "WM_ACTIVATEAPP",
    WM_SHOWWINDOW: "WM_SHOWWINDOW",
    WM_GETMINMAXINFO: "WM_GETMINMAXINFO",
}

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
        print(f"GetWindowId: {window.winId()}")
        return int(window.winId())

    @Slot(int)
    def drag_window_event(self, hwnd: int):
        """在Windows 用原生方法拖动"""
        if not is_windows() or type(hwnd) is not int or hwnd == 0:
            print(
                f"Use Qt method to drag window on: {platform.system()}"
                if not is_windows()
                else f"Invalid window handle: {hwnd}"
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
        _debug_report(
            "qml-sync-window-frame",
            {"native": _debug_window_native_snapshot(hwnd)},
        )
        window.requestActivate()
        if self.on_window_frame_changed is not None:
            QTimer.singleShot(0, self.on_window_frame_changed)

    @Slot(QObject)
    def maximizeWindow(self, window):
        """在Windows上最大化或还原窗口"""
        if not is_windows() or window is None:
            print(
                f"Use Qt method to drag window on: {platform.system()}"
                if not is_windows()
                else "Invalid window object"
            )
            return

        try:
            hwnd = int(window.winId())
            if is_maximized(hwnd):
                window.showNormal()
            else:
                window.showMaximized()

        except Exception as err:
            msg = f"Error toggling window state: {err}"
            print(msg)


class WinEventFilter(QAbstractNativeEventFilter):
    def __init__(self, windows: list, on_window_visible=None):
        super().__init__()
        self.windows = windows  # 接受多个窗口
        self.hwnds = {}  # 用于存储每个窗口的 hwnd
        self.resize_border = 8
        self.on_window_visible = on_window_visible

        for window in self.windows:
            # 使用lambda创建闭包来捕获特定的窗口对象
            window.visibleChanged.connect(
                lambda visible, w=window: self._on_visible_changed(visible, w)
            )

    def initialize_windows(self):
        for window in self.windows:
            self._init_window_handle(window)

    def _on_visible_changed(self, visible: bool, window: QQuickWindow):
        _debug_report(
            "visible-changed",
            {
                "visible": visible,
                "knownHandle": self.hwnds.get(window),
                "winId": int(window.winId()) if window else None,
                "geometry": [window.x(), window.y(), window.width(), window.height()] if window else None,
                "color": window.color().name() if window else None,
                "opacity": window.opacity() if window else None,
            },
        )
        if visible and self.hwnds.get(window) is None:
            self._init_window_handle(window)
        if visible and self.on_window_visible is not None:
            self.on_window_visible(window)

    def _init_window_handle(self, window: QQuickWindow):
        hwnd = int(window.winId())
        self.hwnds[window] = hwnd
        _debug_report(
            "init-window-handle",
            {
                "qt": {
                    "visible": window.isVisible(),
                    "visibility": _debug_value(window.visibility()),
                    "flags": _debug_value(window.flags()),
                    "color": window.color().name(),
                    "opacity": window.opacity(),
                    "geometry": [window.x(), window.y(), window.width(), window.height()],
                    "formatAlpha": window.format().alphaBufferSize(),
                },
                "native": _debug_window_native_snapshot(hwnd),
            },
        )
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
        _debug_report(
            "before-set-window-styles",
            {"native": _debug_window_native_snapshot(hwnd), "styleToSet": style | WS_CAPTION | WS_THICKFRAME},
        )
        style |= WS_CAPTION | WS_THICKFRAME
        user32.SetWindowLongPtrW(hwnd, -16, style)  # GWL_STYLE
        self.refresh_window_frame(window)
        _debug_report(
            "after-set-window-styles",
            {"native": _debug_window_native_snapshot(hwnd)},
        )

    def refresh_window_frame(self, window: QQuickWindow):
        hwnd = self.hwnds.get(window)
        if hwnd is None:
            return

        user32.SetWindowPos(
            hwnd, 0, 0, 0, 0, 0, 0x0002 | 0x0001 | 0x0004 | 0x0010 | 0x0020
        )  # SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED
        _debug_report(
            "refresh-window-frame",
            {"native": _debug_window_native_snapshot(hwnd)},
        )

    def extend_frame_into_client_area(self, window: QQuickWindow):
        if not window.property("backdropEnabled"):
            return

        hwnd = self.hwnds.get(window)
        if hwnd is None or not is_composition_enabled():
            return

        margins = MARGINS(-1, -1, -1, -1)
        result = ctypes.windll.dwmapi.DwmExtendFrameIntoClientArea(
            hwnd, ctypes.byref(margins)
        )
        _debug_report(
            "extend-frame-into-client-area",
            {"result": int(result), "native": _debug_window_native_snapshot(hwnd)},
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
        _debug_report(
            "fullscreen-opengl-border-workaround-applied",
            {"native": _debug_window_native_snapshot(hwnd)},
        )

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

            if _debug_enabled() and message_id in _DEBUG_MESSAGE_NAMES:
                key = (hwnd_window, message_id)
                count = _DEBUG_MESSAGE_COUNTS.get(key, 0) + 1
                _DEBUG_MESSAGE_COUNTS[key] = count
                if count <= 8 or message_id in (WM_SIZE, WM_WINDOWPOSCHANGED):
                    payload = {
                        "message": _DEBUG_MESSAGE_NAMES[message_id],
                        "count": count,
                        "wParam": int(w_param),
                        "lParam": int(l_param),
                        "native": _debug_window_native_snapshot(hwnd_window),
                        "qt": {
                            "visible": window.isVisible(),
                            "visibility": _debug_value(window.visibility()),
                            "geometry": [window.x(), window.y(), window.width(), window.height()],
                            "color": window.color().name(),
                            "opacity": window.opacity(),
                            "formatAlpha": window.format().alphaBufferSize(),
                        },
                    }
                    if message_id == WM_WINDOWPOSCHANGED and l_param:
                        pos = PWINDOWPOS.from_address(l_param)
                        payload["windowPos"] = {
                            "x": pos.x,
                            "y": pos.y,
                            "cx": pos.cx,
                            "cy": pos.cy,
                            "flags": int(pos.flags),
                        }
                    _debug_report("native-message", payload)

            if message_id in (WM_SIZE, WM_WINDOWPOSCHANGED, WM_SHOWWINDOW, WM_ACTIVATE, WM_NCACTIVATE, WM_ACTIVATEAPP, WM_DWMCOMPOSITIONCHANGED):
                self.extend_frame_into_client_area(window)

            if message_id in (WM_SIZE, WM_WINDOWPOSCHANGED):
                self.apply_fullscreen_opengl_border_workaround(window)

            if message_id == WM_NCHITTEST:
                x = ctypes.c_short(l_param & 0xFFFF).value
                y = ctypes.c_short((l_param >> 16) & 0xFFFF).value

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

                # 其他区域不处理
                return False, 0

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
                minmax_info.ptMaxPosition.x = (
                    monitor_info.rcWork.left - monitor_info.rcMonitor.left
                )
                minmax_info.ptMaxPosition.y = (
                    monitor_info.rcWork.top - monitor_info.rcMonitor.top
                )
                minmax_info.ptMaxSize.x = (
                    monitor_info.rcWork.right - monitor_info.rcMonitor.left
                )
                minmax_info.ptMaxSize.y = (
                    monitor_info.rcWork.bottom - monitor_info.rcMonitor.top
                )

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
                max_w = int(
                    get_window_int_property(
                        window,
                        "maximumWidth",
                        monitor_info.rcWork.right - monitor_info.rcWork.left,
                    )
                    * dp_ratio
                )
                max_h = int(
                    get_window_int_property(
                        window,
                        "maximumHeight",
                        monitor_info.rcWork.bottom - monitor_info.rcWork.top,
                    )
                    * dp_ratio
                )

                minmax_info.ptMinTrackSize.x = min_w
                minmax_info.ptMinTrackSize.y = min_h
                minmax_info.ptMaxTrackSize.x = max_w
                minmax_info.ptMaxTrackSize.y = max_h

                return True, 0

        return False, 0
