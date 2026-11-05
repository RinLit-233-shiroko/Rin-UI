import ctypes
from ctypes import wintypes

import win32con
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickWindow
from win32api import GetSystemMetrics
from win32con import MONITOR_DEFAULTTONEAREST, SW_MAXIMIZE
from win32gui import GetWindowPlacement

ULONG_PTR = (
    ctypes.c_ulong if ctypes.sizeof(ctypes.c_void_p) == 4 else ctypes.c_ulonglong
)
LONG = ctypes.c_long


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


user32 = ctypes.windll.user32

GWL_STYLE = -16

WM_NCCALCSIZE = 0x0083
WM_NCHITTEST = 0x0084
WM_SYSCOMMAND = 0x0112
WM_GETMINMAXINFO = 0x0024
WM_ENTERSIZEMOVE = 0x0231
WM_EXITSIZEMOVE = 0x0232
WM_SIZE = 0x0005
WM_PAINT = 0x000F
WM_ERASEBKGND = 0x0014
WM_WINDOWPOSCHANGED = 0x0047
WM_DWMCOMPOSITIONCHANGED = 0x031E
WM_ACTIVATE = 0x0006
WM_NCACTIVATE = 0x0086
WM_ACTIVATEAPP = 0x001C
WM_SHOWWINDOW = 0x0018

WS_CAPTION = 0x00C00000
WS_THICKFRAME = 0x00040000
WS_BORDER = 0x00800000

SC_MINIMIZE = 0xF020
SC_MAXIMIZE = 0xF030
SC_RESTORE = 0xF120

HTCLIENT = 1
HTCAPTION = 2
HTLEFT = 10
HTRIGHT = 11
HTTOP = 12
HTTOPLEFT = 13
HTTOPRIGHT = 14
HTBOTTOM = 15
HTBOTTOMLEFT = 16
HTBOTTOMRIGHT = 17

SWP_NOSIZE = 0x0001
SWP_NOMOVE = 0x0002
SWP_NOZORDER = 0x0004
SWP_NOACTIVATE = 0x0010
SWP_FRAMECHANGED = 0x0020

# SM_CXPADDEDBORDER
SM_CXPADDEDBORDER = 92


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
    result = GetSystemMetrics(frame) + GetSystemMetrics(SM_CXPADDEDBORDER)

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
