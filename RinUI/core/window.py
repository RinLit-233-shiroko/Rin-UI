import ctypes
import platform
from ctypes import wintypes

import win32con
from PySide6.QtCore import QAbstractNativeEventFilter, QByteArray, QObject, QTimer, Slot
from PySide6.QtQuick import QQuickWindow
from win32api import SendMessage
from win32con import SW_MAXIMIZE, SW_RESTORE
from win32gui import GetWindowPlacement, ReleaseCapture, ShowWindow

from RinUI.core.config import is_windows
from RinUI.core.theme import ThemeManager

# 定义 Windows 类型
ULONG_PTR = ctypes.c_ulong if ctypes.sizeof(ctypes.c_void_p) == 4 else ctypes.c_ulonglong
LONG = ctypes.c_long


class MONITORINFO(ctypes.Structure):
    _fields_ = [
        ('cbSize', wintypes.DWORD),
        ('rcMonitor', wintypes.RECT),
        ('rcWork', wintypes.RECT),
        ('dwFlags', wintypes.DWORD)
    ]

class NCCALCSIZE_PARAMS(ctypes.Structure):
    _fields_ = [
        ("rgrc", wintypes.RECT * 3),
        ("lppos", ctypes.c_void_p)
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

SM_CXSIZEFRAME = 32  # 窗口边框宽度
SM_CYSIZEFRAME = 33  # 窗口边框高度
SM_CXPADDEDBORDER = 92  # 填充边框宽度

MONITOR_DEFAULTTONEAREST = 2  # 最近的显示器
DWMWA_WINDOW_CORNER_PREFERENCE = 33
DWMWCP_DO_NOT_ROUND = 1

DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = -4
DPI_AWARENESS_CONTEXT_SYSTEM_AWARE = -2

class MINMAXINFO(ctypes.Structure):
    _fields_ = [
        ("ptReserved", wintypes.POINT),
        ("ptMaxSize", wintypes.POINT),
        ("ptMaxPosition", wintypes.POINT),
        ("ptMinTrackSize", wintypes.POINT),
        ("ptMaxTrackSize", wintypes.POINT),
    ]


class WinEventManager(QObject):
    @Slot(QObject, result=int)
    def getWindowId(self, window):
        """获取窗口的句柄"""
        print(f"GetWindowId: {window.winId()}")
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
            placement = GetWindowPlacement(hwnd)
            current_state = placement[1]

            if current_state == SW_MAXIMIZE:
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
        self._is_maximized = {}
        self._init_dpi_awareness()

        for window in self.windows:
            # 使用lambda创建闭包来捕获特定的窗口对象
            window.visibleChanged.connect(lambda visible, w=window: self._on_visible_changed(visible, w))
            if window.isVisible():
                self._init_window_handle(window)

    def _get_resize_border(self, hwnd):
        """获取动态调整的边框大小"""
        try:
            dpi = self._get_dpi_for_window(hwnd)
            base_border = 8
            scale_factor = dpi / 96.0
            border_size = max(4, int(base_border * scale_factor))
            # print(f"[DEBUG] Border size: {border_size}, DPI: {dpi}, Scale: {scale_factor:.2f}")
            return border_size
        except Exception:
            # print(f"[DEBUG] Border calculation error: {e}, using default 8")
            return 8

    def _init_dpi_awareness(self):
        try:
            user32.SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)
        except Exception:
            try:
                user32.SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_SYSTEM_AWARE)
            except Exception:
                pass

    def _get_window_property(self, window: QQuickWindow, property_name: str, default_value: int = 0) -> int:
        """安全获取窗口属性值"""
        try:
            val = getattr(window, property_name, None)
            if val is not None:
                if callable(val):
                    try:
                        val = val()
                    except Exception:
                        val = None
                if val is not None:
                    return int(val)
        except Exception:
            pass
        try:
            prop = window.property(property_name)
            if prop is not None:
                return int(prop)
        except Exception:
            pass

        return default_value

    def _get_dpi_for_window(self, hwnd):
        """获取窗口的 DPI 值"""
        try:
            dpi = user32.GetDpiForWindow(hwnd)
            if dpi and dpi > 0:
                return dpi
        except Exception:
            pass
        try:
            hmon = user32.MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)
            if hmon:
                shcore = ctypes.windll.shcore
                dpi_x = ctypes.c_uint()
                dpi_y = ctypes.c_uint()
                if shcore.GetDpiForMonitor(hmon, 0, ctypes.byref(dpi_x), ctypes.byref(dpi_y)) == 0:
                    return dpi_x.value
        except Exception:
            pass
        try:
            hdc = user32.GetDC(0)
            if hdc:
                dpi = ctypes.windll.gdi32.GetDeviceCaps(hdc, 88)  # LOGPIXELSX
                user32.ReleaseDC(0, hdc)
                if dpi > 0:
                    return dpi
        except Exception:
            pass

        return 96

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
                border = self._get_resize_border(hwnd_window)
                # print(f"[DEBUG] NCHITTEST: pos=({x},{y}), rect=({left},{top},{right},{bottom}), border={border}")

                if left <= x < left + border:
                    if top <= y < top + border:
                        return True, 13  # HTTOPLEFT
                    elif bottom - border <= y < bottom:
                        return True, 16  # HTBOTTOMLEFT
                    else:
                        return True, 10  # HTLEFT
                elif right - border <= x < right:
                    if top <= y < top + border:
                        return True, 14  # HTTOPRIGHT
                    elif bottom - border <= y < bottom:
                        return True, 17  # HTBOTTOMRIGHT
                    else:
                        return True, 11  # HTRIGHT
                elif top <= y < top + border:
                    return True, 12  # HTTOP
                elif bottom - border <= y < bottom:
                    return True, 15  # HTBOTTOM

                # 其他区域不处理
                return False, 0

            # 移除标题栏
            if message_id == WM_NCCALCSIZE and wParam:
                nccsp = NCCALCSIZE_PARAMS.from_address(lParam)
                if user32.IsZoomed(hwnd_window):
                    hmon = user32.MonitorFromWindow(hwnd_window, MONITOR_DEFAULTTONEAREST)
                    if hmon:
                        mi = MONITORINFO()
                        mi.cbSize = ctypes.sizeof(MONITORINFO)
                        if user32.GetMonitorInfoW(hmon, ctypes.byref(mi)):
                            work_area = mi.rcWork
                            nccsp.rgrc[0].left = work_area.left
                            nccsp.rgrc[0].top = work_area.top
                            nccsp.rgrc[0].right = work_area.right
                            nccsp.rgrc[0].bottom = work_area.bottom
                return True, 0

            # 支持动画
            if message_id == WM_SYSCOMMAND:
                return False, 0

            # 处理 WM_GETMINMAXINFO 消息以支持 Snap 功能
            if message_id == WM_GETMINMAXINFO:
                minmax_info = MINMAXINFO.from_address(lParam)
                hmon = user32.MonitorFromWindow(hwnd_window, MONITOR_DEFAULTTONEAREST)
                if hmon == 0:
                    return True, 0
                mi = MONITORINFO()
                mi.cbSize = ctypes.sizeof(MONITORINFO)
                if not user32.GetMonitorInfoW(hmon, ctypes.byref(mi)):
                    return True, 0
                work_area = mi.rcWork
                window_rect = wintypes.RECT()
                window_rect.left = 0
                window_rect.top = 0
                window_rect.right = work_area.right - work_area.left
                window_rect.bottom = work_area.bottom - work_area.top
                window_style = user32.GetWindowLongW(hwnd_window, -16)  # GWL_STYLE
                window_ex_style = user32.GetWindowLongW(hwnd_window, -20)  # GWL_EXSTYLE
                if user32.AdjustWindowRectEx(
                    ctypes.byref(window_rect),
                    window_style,
                    False,  # 没有菜单
                    window_ex_style
                ):
                    border_width = -window_rect.left
                    border_height = -window_rect.top
                else:
                    frame_x = user32.GetSystemMetrics(SM_CXSIZEFRAME)
                    frame_y = user32.GetSystemMetrics(SM_CYSIZEFRAME)
                    padded_border = user32.GetSystemMetrics(SM_CXPADDEDBORDER)
                    dpi = self._get_dpi_for_window(hwnd_window)
                    dpi_scale = dpi / 96.0 if dpi > 0 else 1.0
                    border_width = int((frame_x + padded_border) * dpi_scale)
                    border_height = int((frame_y + padded_border) * dpi_scale)
                minmax_info.ptMaxPosition.x = work_area.left - border_width
                minmax_info.ptMaxPosition.y = work_area.top - border_height
                minmax_info.ptMaxSize.x = (work_area.right - work_area.left) + 2 * border_width
                minmax_info.ptMaxSize.y = (work_area.bottom - work_area.top) + 2 * border_height
                minmax_info.ptMinTrackSize.x = int(self._get_window_property(window, "minimumWidth", 100))
                minmax_info.ptMinTrackSize.y = int(self._get_window_property(window, "minimumHeight", 100))
                minmax_info.ptMaxTrackSize.x = int(self._get_window_property(window, "maximumWidth", 16777215))
                minmax_info.ptMaxTrackSize.y = int(self._get_window_property(window, "maximumHeight", 16777215))

                return True, 0

        return False, 0
