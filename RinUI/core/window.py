import ctypes
import platform
from ctypes import wintypes

import win32con
from PySide6.QtCore import QAbstractNativeEventFilter, QByteArray, QObject, Slot
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
    SW_MAXIMIZE,
    SW_RESTORE
)
from win32gui import FindWindow, GetWindowPlacement, ReleaseCapture, ShowWindow

from RinUI.core.config import is_windows

# 定义 Windows 类型
ULONG_PTR = ctypes.c_ulong if ctypes.sizeof(ctypes.c_void_p) == 4 else ctypes.c_ulonglong
LONG = ctypes.c_long


# 自定义结构体 MONITORINFO
class MONITORINFO(ctypes.Structure):
    _fields_ = [
        ('cbSize', wintypes.DWORD),
        ('rcMonitor', wintypes.RECT),
        ('rcWork', wintypes.RECT),
        ('dwFlags', wintypes.DWORD)
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
        ("flags", wintypes.UINT)
    ]

class NCCALCSIZE_PARAMS(ctypes.Structure):
    _fields_ = [
        ("rgrc", wintypes.RECT * 3),
        ("lppos", ctypes.POINTER(PWINDOWPOS))
    ]

class APPBARDATA(ctypes.Structure):
    _fields_ = [
        ("cbSize", wintypes.UINT),
        ("hWnd", wintypes.HWND),
        ("uCallbackMessage", wintypes.UINT),
        ("uEdge", wintypes.UINT),
        ("rc", wintypes.RECT),
        ("lParam", wintypes.LPARAM)
    ]


user32 = ctypes.windll.user32

# 定义必要的 Windows 常量
WM_NCCALCSIZE = 0x0083
WM_NCHITTEST = 0x0084
WM_SYSCOMMAND = 0x0112
WM_GETMINMAXINFO = 0x0024

WS_CAPTION = 0x00C00000
WS_THICKFRAME = 0x00040000

SC_MINIMIZE = 0xF020
SC_MAXIMIZE = 0xF030
SC_RESTORE = 0xF120

HTMAXBUTTON = 0x9


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
        return

    windows = QGuiApplication.topLevelWindows()
    if not windows:
        return

    for window in windows:
        if window and int(window.winId()) == hwnd:
            return window

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


class WinEventManager(QObject):
    @Slot(QObject, result=int)
    def getWindowId(self, window):
        """获取窗口的句柄"""
        # print(f"GetWindowId: {window.winId()}")
        return int(window.winId())

    @Slot(int)
    def dragWindowEvent(self, hwnd: int):
        """ 在Windows 用原生方法拖动"""
        if not is_windows() or type(hwnd) is not int or hwnd == 0:
            print(
                f"Use Qt method to drag window on: {platform.system()}"
                if not is_windows() else f"Invalid window handle: {hwnd}"
            )
            return

        ReleaseCapture()
        SendMessage(
            hwnd,
            win32con.WM_SYSCOMMAND,
            win32con.SC_MOVE | win32con.HTCAPTION, 0
        )

    @Slot(int)
    def maximizeWindow(self, hwnd):
        """在Windows上最大化或还原窗口"""
        if not is_windows() or type(hwnd) is not int or hwnd == 0:
            print(
                f"Use Qt method to drag window on: {platform.system()}"
                if not is_windows() else f"Invalid window handle: {hwnd}"
            )
            return

        try:
            if is_maximized(hwnd):
                ShowWindow(hwnd, SW_RESTORE)
            else:
                ShowWindow(hwnd, SW_MAXIMIZE)

        except Exception as e:
            print(f"Error toggling window state: {e}")


class WinEventFilter(QAbstractNativeEventFilter):
    def __init__(self, windows: list):
        super().__init__()
        self.windows = windows  # 接受多个窗口
        self.hwnds = {}  # 用于存储每个窗口的 hwnd
        self.resize_border = 8  # 仅兜底

        for window in self.windows:
            # 使用lambda创建闭包来捕获特定的窗口对象
            window.visibleChanged.connect(lambda visible, w=window: self._on_visible_changed(visible, w))
            if window.isVisible():
                self._init_window_handle(window)

    def _on_visible_changed(self, visible: bool, window: QQuickWindow):
        # 直接使用传入的窗口对象
        if visible and self.hwnds.get(window) is None:
            self._init_window_handle(window)

    def _init_window_handle(self, window: QQuickWindow):
        hwnd = int(window.winId())
        self.hwnds[window] = hwnd
        self.set_window_styles(window)

    def set_window_styles(self, window: QQuickWindow):
        hwnd = self.hwnds.get(window)
        if hwnd is None:
            return

        style = user32.GetWindowLongPtrW(hwnd, -16)  # GWL_STYLE
        style |= WS_CAPTION | WS_THICKFRAME
        user32.SetWindowLongPtrW(hwnd, -16, style)  # GWL_STYLE

        # 重绘
        user32.SetWindowPos(hwnd, 0, 0, 0, 0, 0,
                            0x0002 | 0x0001 | 0x0040)  # SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED

    def nativeEventFilter(self, eventType: QByteArray, message):
        if eventType != b"windows_generic_MSG":
            return False, 0

        try:
            message_addr = int(message)
        except:
            buf = memoryview(message)
            message_addr = ctypes.addressof(ctypes.c_char.from_buffer(buf))

        # 直接使用内存地址访问 MSG 字段
        hwnd = ctypes.c_void_p.from_address(message_addr).value
        message_id = wintypes.UINT.from_address(message_addr + ctypes.sizeof(ctypes.c_void_p)).value
        wParam = wintypes.WPARAM.from_address(message_addr + 2 * ctypes.sizeof(ctypes.c_void_p)).value
        lParam = wintypes.LPARAM.from_address(message_addr + 3 * ctypes.sizeof(ctypes.c_void_p)).value

        # 遍历每个窗口，检查哪个窗口收到了消息
        for window in self.windows:
            hwnd_window = self.hwnds.get(window)
            if hwnd_window != hwnd:
                continue

            if message_id == WM_NCHITTEST:
                x = ctypes.c_short(lParam & 0xFFFF).value
                y = ctypes.c_short((lParam >> 16) & 0xFFFF).value

                rect = wintypes.RECT()
                user32.GetWindowRect(hwnd_window, ctypes.byref(rect))
                left, top, right, bottom = rect.left, rect.top, rect.right, rect.bottom
                border = get_resize_border_thickness(hwnd_window, horizontal=True)
                border_v = get_resize_border_thickness(hwnd_window, horizontal=False)
                border = max(1, int(border))
                border_v = max(1, int(border_v))
                btn_rects = self._get_button_rect(hwnd_window)
                max_left, max_top, max_right, max_bottom = btn_rects["maximize"]
                is_l_down = (user32.GetAsyncKeyState(0x01) & 0x8000) != 0  # VK_LBUTTON
                is_r_down = (user32.GetAsyncKeyState(0x02) & 0x8000) != 0  # VK_RBUTTON

                if max_left <= x <= max_right and max_top <= y <= max_bottom:
                    if not (is_l_down or is_r_down):
                        return True, HTMAXBUTTON
                    else:
                        return True, 1  # HTCLIENT

                if left <= x < left + border:
                    if top <= y < top + border_v:
                        return True, 13  # HTTOPLEFT
                    elif bottom - border_v <= y < bottom:
                        return True, 16  # HTBOTTOMLEFT
                    else:
                        return True, 10  # HTLEFT
                elif right - border <= x < right:
                    if top <= y < top + border_v:
                        return True, 14  # HTTOPRIGHT
                    elif bottom - border_v <= y < bottom:
                        return True, 17  # HTBOTTOMRIGHT
                    else:
                        return True, 11  # HTRIGHT
                elif top <= y < top + border_v:
                    return True, 12  # HTTOP
                elif bottom - border_v <= y < bottom:
                    return True, 15  # HTBOTTOM

                # 其他区域不处理
                return False, 0

            # 移除标题栏
            if message_id == WM_NCCALCSIZE and wParam:
                ncc_ptr = ctypes.cast(lParam, ctypes.POINTER(NCCALCSIZE_PARAMS))
                rgrc = ncc_ptr.contents.rgrc

                if is_maximized(hwnd):
                    ty = get_resize_border_thickness(hwnd, horizontal=False)
                    tx = get_resize_border_thickness(hwnd, horizontal=True)
                    rgrc[0].top += ty
                    rgrc[0].bottom -= ty
                    rgrc[0].left += tx
                    rgrc[0].right -= tx
                    abd = APPBARDATA()
                    ctypes.memset(ctypes.byref(abd), 0, ctypes.sizeof(abd))
                    abd.cbSize = ctypes.sizeof(APPBARDATA)
                    taskbar_state = ctypes.windll.shell32.SHAppBarMessage(ABM_GETSTATE, ctypes.byref(abd))
                    if taskbar_state & ABS_AUTOHIDE:
                        edge = -1
                        abd2 = APPBARDATA()
                        ctypes.memset(ctypes.byref(abd2), 0, ctypes.sizeof(abd2))
                        abd2.cbSize = ctypes.sizeof(APPBARDATA)
                        abd2.hWnd = FindWindow("Shell_TrayWnd", None)
                        if abd2.hWnd:
                            window_monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)
                            taskbar_monitor = MonitorFromWindow(abd2.hWnd, MONITOR_DEFAULTTONEAREST)
                            if window_monitor and taskbar_monitor and window_monitor == taskbar_monitor:
                                res = ctypes.windll.shell32.SHAppBarMessage(ABM_GETTASKBARPOS, ctypes.byref(abd2))
                                if res:
                                    edge = abd2.uEdge
                        is_top_edge = (edge == 1)
                        is_bottom_edge = (edge == 3)
                        is_left_edge = (edge == 0)
                        is_right_edge = (edge == 2)
                        if is_top_edge:
                            rgrc[0].top += 1
                        elif is_bottom_edge:
                            rgrc[0].bottom -= 1
                        elif is_left_edge:
                            rgrc[0].left += 1
                        elif is_right_edge:
                            rgrc[0].right -= 1
                        else:
                            # 未识别, 默认把底部收1
                            rgrc[0].bottom -= 1
                return True, 0

            # 支持动画
            if message_id == WM_SYSCOMMAND:
                return False, 0

            # 处理 WM_GETMINMAXINFO 消息以支持 Snap 功能
            if message_id == WM_GETMINMAXINFO:
                # 获取屏幕工作区大小
                monitor = user32.MonitorFromWindow(hwnd_window, 2)  # MONITOR_DEFAULTTONEAREST
                if not monitor:
                    return False, 0

                # 使用自定义的 MONITORINFO 结构
                monitor_info = MONITORINFO()
                monitor_info.cbSize = ctypes.sizeof(MONITORINFO)
                monitor_info.dwFlags = 0
                if not user32.GetMonitorInfoW(monitor, ctypes.byref(monitor_info)):
                    return False, 0
                # 获取 MINMAXINFO 结构
                minmax_info = MINMAXINFO.from_address(lParam)

                tx = get_resize_border_thickness(hwnd_window, horizontal=True)
                ty = get_resize_border_thickness(hwnd_window, horizontal=False)
                rel_x = monitor_info.rcWork.left - monitor_info.rcMonitor.left
                rel_y = monitor_info.rcWork.top - monitor_info.rcMonitor.top
                work_width = monitor_info.rcWork.right - monitor_info.rcWork.left
                work_height = monitor_info.rcWork.bottom - monitor_info.rcWork.top
                if work_width <= 0 or work_height <= 0:
                    return False, 0
                # WM_NCCALCSIZE 中 top += ty, left += tx, right -= tx, bottom -= ty
                # 位置偏移 -tx/-ty, 大小 +2*tx / +2*ty
                minmax_info.ptMaxPosition.x = rel_x - tx
                minmax_info.ptMaxPosition.y = rel_y - ty
                minmax_info.ptMaxSize.x = work_width + 2 * tx
                minmax_info.ptMaxSize.y = work_height + 2 * ty

                def get_window_int_property(window, name, default):
                    try:
                        val = getattr(window, name, default)
                        if callable(val):
                            val = val()  # 如果是方法就调用
                        if val is None:
                            val = default
                        return max(int(val), 0)
                    except (AttributeError, ValueError, TypeError):
                        return default


                min_w = max(get_window_int_property(window, "minimumWidth", 330), 330)
                min_h = max(get_window_int_property(window, "minimumHeight", 150), 150)
                max_w = get_window_int_property(window, "maximumWidth", work_width + 2 * tx)
                max_h = get_window_int_property(window, "maximumHeight", work_height + 2 * ty)
                max_w = max(max_w, min_w)
                max_h = max(max_h, min_h)
                minmax_info.ptMinTrackSize.x = int(min_w)
                minmax_info.ptMinTrackSize.y = int(min_h)
                minmax_info.ptMaxTrackSize.x = int(max_w)
                minmax_info.ptMaxTrackSize.y = int(max_h)

                return True, 0

        return False, 0

    def _get_button_rect(self, hwnd_window):
        """获取标题栏按钮的屏幕坐标矩形
        Note: 这是对原生标题栏按钮位置的近似
        """
        rect = wintypes.RECT()
        user32.GetWindowRect(hwnd_window, ctypes.byref(rect))
        btn_w = user32.GetSystemMetrics(30) or 46        # SM_CXSIZE
        btn_h = user32.GetSystemMetrics(31) or 32        # SM_CYSIZE
        cx_frame = user32.GetSystemMetrics(32) or 8      # SM_CXFRAME
        cy_frame = user32.GetSystemMetrics(33) or 8      # SM_CYFRAME
        cx_pad = user32.GetSystemMetrics(92) or 0        # SM_CXPADDEDBORDER
        top_y = rect.top + cy_frame + cx_pad
        right_x = rect.right - cx_frame
        close_rect = (right_x - btn_w, top_y, right_x, top_y + btn_h)
        max_rect = (right_x - btn_w * 2, top_y, right_x - btn_w, top_y + btn_h)
        min_rect = (right_x - btn_w * 3, top_y, right_x - btn_w * 2, top_y + btn_h)
        return {
            "minimize": min_rect,
            "maximize": max_rect,
            "close": close_rect
        }

