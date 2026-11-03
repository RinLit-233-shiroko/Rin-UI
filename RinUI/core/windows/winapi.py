"""Win32 结构体、常量与最小封装。"""

import ctypes
from ctypes import wintypes

import win32con
from PySide6.QtGui import QGuiApplication
from win32api import GetSystemMetrics
from win32con import MONITOR_DEFAULTTONEAREST, SW_MAXIMIZE
from win32gui import GetWindowPlacement

user32 = ctypes.windll.user32
dwmapi = ctypes.windll.dwmapi
shell32 = ctypes.windll.shell32

GWL_STYLE = -16

SWP_FRAMECHANGED = 0x0020
SWP_NOACTIVATE = 0x0010
SWP_NOZORDER = 0x0004
SWP_NOSIZE = 0x0001
SWP_NOMOVE = 0x0002

SWP_FLAGS_FRAME_REFRESH = (
    SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED
)

WS_CAPTION = 0x00C00000
WS_THICKFRAME = 0x00040000
WS_BORDER = 0x00800000

WM_NCCALCSIZE = 0x0083
WM_NCHITTEST = 0x0084
WM_SYSCOMMAND = 0x0112
WM_GETMINMAXINFO = 0x0024
WM_SIZE = 0x0005
WM_WINDOWPOSCHANGED = 0x0047
WM_DWMCOMPOSITIONCHANGED = 0x031E
WM_ACTIVATE = 0x0006
WM_NCACTIVATE = 0x0086
WM_ACTIVATEAPP = 0x001C
WM_SHOWWINDOW = 0x0018
WM_ENTERSIZEMOVE = 0x0231
WM_EXITSIZEMOVE = 0x0232
WM_NCLBUTTONDOWN = 0x00A1
WM_NCLBUTTONUP = 0x00A2
WM_NCLBUTTONDBLCLK = 0x00A3
WM_NCMOUSEMOVE = 0x00A0
WM_NCMOUSELEAVE = 0x02A2
WM_MOUSEMOVE = 0x0200
WM_MOUSELEAVE = 0x02A3
WM_LBUTTONDOWN = 0x0201
WM_LBUTTONUP = 0x0202
WM_CANCELMODE = 0x001F

# DWM 窗口圆角偏好
DWMWA_WINDOW_CORNER_PREFERENCE = 33
DWMWCP_DONOTROUND = 1
DWMWCP_ROUND = 2


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


class MINMAXINFO(ctypes.Structure):
    _fields_ = [
        ("ptReserved", wintypes.POINT),
        ("ptMaxSize", wintypes.POINT),
        ("ptMaxPosition", wintypes.POINT),
        ("ptMinTrackSize", wintypes.POINT),
        ("ptMaxTrackSize", wintypes.POINT),
    ]


def is_maximized(hwnd: int) -> bool:
    return GetWindowPlacement(hwnd)[1] == SW_MAXIMIZE


def is_composition_enabled() -> bool:
    enabled = ctypes.c_int(0)
    dwmapi.DwmIsCompositionEnabled(ctypes.byref(enabled))
    return bool(enabled.value)


def find_window(hwnd: int):
    """把 HWND 换回 Qt 的顶层窗口。"""
    if not hwnd:
        return None
    for window in QGuiApplication.topLevelWindows():
        if window and int(window.winId()) == hwnd:
            return window
    return None


def get_resize_border_thickness(hwnd, horizontal: bool = True) -> int:
    window = find_window(int(hwnd))
    if not window:
        return 0
    frame = win32con.SM_CXSIZEFRAME if horizontal else win32con.SM_CYSIZEFRAME
    thickness = GetSystemMetrics(frame) + GetSystemMetrics(92)
    if thickness > 0:
        return thickness
    fallback = 8 if is_composition_enabled() else 4
    return round(fallback * window.devicePixelRatio())


def monitor_info(hwnd: int):
    monitor = user32.MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)
    if not monitor:
        return None
    info = MONITORINFO()
    info.cbSize = ctypes.sizeof(MONITORINFO)
    if not user32.GetMonitorInfoW(monitor, ctypes.byref(info)):
        return None
    return info


def window_rect(hwnd: int):
    rect = wintypes.RECT()
    if not user32.GetWindowRect(hwnd, ctypes.byref(rect)):
        return None
    return rect


def client_origin(hwnd: int):
    """客户区左上角的屏幕坐标。"""
    point = wintypes.POINT(0, 0)
    user32.ClientToScreen(hwnd, ctypes.byref(point))
    return point


def cursor_pos():
    point = wintypes.POINT()
    user32.GetCursorPos(ctypes.byref(point))
    return point


def is_exact_monitor_sized_window(window, hwnd: int) -> bool:
    """窗口是否正好铺满整个显示器(无边框全屏)。"""
    if not window:
        return False
    info = monitor_info(hwnd)
    if info is None:
        return False
    rect = window_rect(hwnd)
    if rect is None:
        return False
    monitor = info.rcMonitor
    if (
        rect.left == monitor.left
        and rect.top == monitor.top
        and rect.right == monitor.right
        and rect.bottom == monitor.bottom
    ):
        return True
    screen = window.screen()
    ratio = screen.devicePixelRatio() if screen else window.devicePixelRatio()
    return (
        round(window.width() * ratio) == monitor.right - monitor.left
        and round(window.height() * ratio) == monitor.bottom - monitor.top
    )
