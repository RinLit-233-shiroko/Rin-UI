import platform
from typing import Optional

from PySide6.QtCore import QAbstractNativeEventFilter, QByteArray, QObject, Slot
import ctypes
from ctypes import wintypes

import win32con
from PySide6.QtQuick import QQuickWindow
from win32gui import ReleaseCapture, GetWindowPlacement, ShowWindow, SetWindowPlacement
from win32con import SW_MAXIMIZE, SW_RESTORE
from win32api import SendMessage

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
                # 获取当前窗口矩形
                current_rect = wintypes.RECT()
                user32.GetWindowRect(hwnd, ctypes.byref(current_rect))
                # 获取显示器工作区域
                monitor = user32.MonitorFromWindow(hwnd, 2)  # MONITOR_DEFAULTTONEAREST
                monitor_info = MONITORINFO()
                monitor_info.cbSize = ctypes.sizeof(MONITORINFO)
                user32.GetMonitorInfoW(monitor, ctypes.byref(monitor_info))
                work_area = monitor_info.rcWork
                # 计算目标位置和尺寸(工作区域)
                target_x = work_area.left
                target_y = work_area.top
                target_width = work_area.right - work_area.left
                target_height = work_area.bottom - work_area.top
                user32.SetWindowPos(
                    hwnd,
                    0,  # hWndInsertAfter
                    target_x, target_y,
                    target_width, target_height,
                    0x0040  # SWP_FRAMECHANGED
                )
                # 更新窗口状态
                placement[1] = SW_MAXIMIZE
                SetWindowPlacement(hwnd, placement)

        except Exception as e:
            print(f"Error toggling window state: {e}")


class WinEventFilter(QAbstractNativeEventFilter):
    def __init__(self, windows: list):
        super().__init__()
        self.windows = windows  # 接受多个窗口
        self.hwnds = {}  # 用于存储每个窗口的 hwnd
        self.resize_border = 8

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
            if hwnd_window == hwnd:
                if message_id == WM_NCHITTEST:
                    x = ctypes.c_short(lParam & 0xFFFF).value
                    y = ctypes.c_short((lParam >> 16) & 0xFFFF).value

                    rect = wintypes.RECT()
                    user32.GetWindowRect(hwnd_window, ctypes.byref(rect))
                    left, top, right, bottom = rect.left, rect.top, rect.right, rect.bottom
                    border = self.resize_border

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
                elif message_id == WM_NCCALCSIZE and wParam:
                    return True, 0

                # 支持动画
                elif message_id == WM_SYSCOMMAND:
                    return False, 0

                # 处理 WM_GETMINMAXINFO 消息以支持 Snap 功能
                elif message_id == WM_GETMINMAXINFO:
                    # 获取屏幕工作区大小
                    monitor = user32.MonitorFromWindow(hwnd_window, 2)  # MONITOR_DEFAULTTONEAREST

                    # 使用自定义的 MONITORINFO 结构
                    monitor_info = MONITORINFO()
                    monitor_info.cbSize = ctypes.sizeof(MONITORINFO)
                    monitor_info.dwFlags = 0
                    user32.GetMonitorInfoW(monitor, ctypes.byref(monitor_info))

                    # 获取 MINMAXINFO 结构
                    minmax_info = MINMAXINFO.from_address(lParam)

                    # 最大化位置和大小
                    minmax_info.ptMaxPosition.x = monitor_info.rcWork.left - monitor_info.rcMonitor.left
                    minmax_info.ptMaxPosition.y = monitor_info.rcWork.top - monitor_info.rcMonitor.top
                    minmax_info.ptMaxSize.x = monitor_info.rcWork.right - monitor_info.rcWork.left
                    minmax_info.ptMaxSize.y = monitor_info.rcWork.bottom - monitor_info.rcWork.top


                    def get_window_int_property(window, name, default):
                        val = getattr(window, name, default)
                        if callable(val):
                            val = val()  # 如果是方法就调用
                        if val is None:
                            val = default
                        return int(val)

                    min_w = get_window_int_property(window, "minimumWidth", 200)
                    min_h = get_window_int_property(window, "minimumHeight", 150)
                    max_w = get_window_int_property(window, "maximumWidth",
                                                    monitor_info.rcWork.right - monitor_info.rcWork.left)
                    max_h = get_window_int_property(window, "maximumHeight",
                                                    monitor_info.rcWork.bottom - monitor_info.rcWork.top)
                    minmax_info.ptMinTrackSize.x = int(min_w)
                    minmax_info.ptMinTrackSize.y = int(min_h)
                    minmax_info.ptMaxTrackSize.x = int(max_w)
                    minmax_info.ptMaxTrackSize.y = int(max_h)

                    return True, 0

        return False, 0
