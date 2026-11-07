import ctypes
from ctypes import wintypes

from PySide6.QtCore import QAbstractNativeEventFilter, QByteArray, QTimer
from PySide6.QtQuick import QQuickWindow
from win32api import MonitorFromWindow
from win32com.shell.shellcon import ABS_AUTOHIDE, ABM_GETSTATE, ABM_GETTASKBARPOS
from win32con import MONITOR_DEFAULTTONEAREST, MONITOR_DEFAULTTOPRIMARY
from win32gui import FindWindow

from RinUI.core.config import is_win11
from RinUI.core.windows.winapi import (
    APPBARDATA,
    HTCAPTION,
    HTCLIENT,
    HTMAXBUTTON,
    MINMAXINFO,
    MONITORINFO,
    NCCALCSIZE_PARAMS,
    HTBOTTOM,
    HTBOTTOMLEFT,
    HTBOTTOMRIGHT,
    HTLEFT,
    HTRIGHT,
    HTTOP,
    HTTOPLEFT,
    HTTOPRIGHT,
    WM_ACTIVATE,
    WM_ACTIVATEAPP,
    WM_CANCELMODE,
    WM_DWMCOMPOSITIONCHANGED,
    WM_GETMINMAXINFO,
    WM_LBUTTONDOWN,
    WM_LBUTTONUP,
    WM_MOUSELEAVE,
    WM_NCACTIVATE,
    WM_NCCALCSIZE,
    WM_NCHITTEST,
    WM_NCLBUTTONDBLCLK,
    WM_NCLBUTTONDOWN,
    WM_NCLBUTTONUP,
    WM_NCMOUSEMOVE,
    WM_NCMOUSELEAVE,
    WM_ENTERSIZEMOVE,
    WM_EXITSIZEMOVE,
    WM_SHOWWINDOW,
    WM_SIZE,
    WM_SYSCOMMAND,
    WM_WINDOWPOSCHANGED,
    get_resize_border_thickness,
    is_maximized,
    user32,
)
from RinUI.core.windows.window_manager import (
    apply_fullscreen_opengl_border_workaround,
    extend_frame_into_client_area,
    set_window_styles,
)
from RinUI.core.windows.window_state import (
    RESIZE_BORDER,
    button_width_px,
    inside_rect,
    interactive_rects,
    invalidate_interactive_rects,
    max_button_rect,
    safe_width_px,
    set_window_property,
    title_bar_height_px,
)

_FRAME_MESSAGES = (
    WM_SIZE,
    WM_WINDOWPOSCHANGED,
    WM_SHOWWINDOW,
    WM_ACTIVATE,
    WM_NCACTIVATE,
    WM_ACTIVATEAPP,
    WM_DWMCOMPOSITIONCHANGED,
)

_FULLSCREEN_MESSAGES = (
    WM_SIZE,
    WM_WINDOWPOSCHANGED,
    WM_DWMCOMPOSITIONCHANGED,
)


def message_parts(message) -> tuple[int, int, int, int]:
    """从 MSG 内存地址解出 (hwnd, message_id, w_param, l_param)。"""
    try:
        message_addr = int(message)
    except Exception:
        buf = memoryview(message)
        message_addr = ctypes.addressof(ctypes.c_char.from_buffer(buf))

    pointer_size = ctypes.sizeof(ctypes.c_void_p)
    hwnd = ctypes.c_void_p.from_address(message_addr).value
    message_id = wintypes.UINT.from_address(message_addr + pointer_size).value
    w_param = wintypes.WPARAM.from_address(message_addr + 2 * pointer_size).value
    l_param = wintypes.LPARAM.from_address(message_addr + 3 * pointer_size).value
    return hwnd, message_id, w_param, l_param


def cursor_position(l_param: int) -> tuple[int, int]:
    x = ctypes.c_short(l_param & 0xFFFF).value
    y = ctypes.c_short((l_param >> 16) & 0xFFFF).value
    return x, y


def hit_test(window, hwnd: int, l_param: int, resize_border=RESIZE_BORDER, moving=False):
    """命中测试；未命中返回 (False, 0) 交给 Qt。"""
    x, y = cursor_position(l_param)

    rect = wintypes.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    left, top, right, bottom = rect.left, rect.top, rect.right, rect.bottom

    if left <= x < left + resize_border:
        if top <= y < top + resize_border:
            return True, HTTOPLEFT
        if bottom - resize_border <= y < bottom:
            return True, HTBOTTOMLEFT
        return True, HTLEFT
    if right - resize_border <= x < right:
        if top <= y < top + resize_border:
            return True, HTTOPRIGHT
        if bottom - resize_border <= y < bottom:
            return True, HTBOTTOMRIGHT
        return True, HTRIGHT
    if top <= y < top + resize_border:
        return True, HTTOP
    if bottom - resize_border <= y < bottom:
        return True, HTBOTTOM

    screen = window.screen()
    dp_ratio = screen.devicePixelRatio() if screen else 1.0
    if not top <= y < top + title_bar_height_px(window, dp_ratio):
        return False, 0

    origin = wintypes.POINT(0, 0)
    user32.ClientToScreen(hwnd, ctypes.byref(origin))
    cx = x - origin.x
    cy = y - origin.y

    max_rect = max_button_rect(window, dp_ratio)
    if not moving and max_rect is not None and inside_rect(max_rect, cx, cy, 2):
        return True, HTMAXBUTTON

    button_px = button_width_px(window, dp_ratio)
    drag_limit = (right - left) - button_px - safe_width_px(window, dp_ratio)

    if not moving and cx < drag_limit:
        for rect_x, rect_y, rect_w, rect_h in interactive_rects(window, dp_ratio):
            if rect_x <= cx < min(rect_x + rect_w, drag_limit):
                if rect_y <= cy < rect_y + rect_h:
                    return True, HTCLIENT

    if cx < (right - left) - button_px:
        return True, HTCAPTION
    return True, HTCLIENT


def apply_nccalcsize(hwnd: int, l_param: int):
    """去掉整块非客户区；最大化时按边框与任务栏方向收边。"""
    params = ctypes.cast(l_param, ctypes.POINTER(NCCALCSIZE_PARAMS)).contents
    client_rect = params.rgrc[0]
    if is_maximized(hwnd):
        ty = get_resize_border_thickness(hwnd, False)
        client_rect.top += ty
        client_rect.bottom -= ty
        tx = get_resize_border_thickness(hwnd, True)
        client_rect.left += tx
        client_rect.right -= tx

        abd = _appbar_data()
        taskbar_state = ctypes.windll.shell32.SHAppBarMessage(
            ABM_GETSTATE, ctypes.byref(abd)
        )
        if taskbar_state & ABS_AUTOHIDE:
            edge = _taskbar_edge(hwnd)
            if edge == 1:
                client_rect.top += 1
            elif edge == 3:
                client_rect.bottom -= 1
            elif edge == 0:
                client_rect.left += 1
            elif edge == 2:
                client_rect.right -= 1
            else:
                client_rect.bottom -= 1
    return True, 0


def apply_getminmaxinfo(window, hwnd: int, l_param: int):
    """把最大化区域与最小/最大尺寸告诉系统。"""
    monitor = user32.MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)

    monitor_info = MONITORINFO()
    monitor_info.cbSize = ctypes.sizeof(MONITORINFO)
    monitor_info.dwFlags = 0
    user32.GetMonitorInfoW(monitor, ctypes.byref(monitor_info))

    minmax_info = MINMAXINFO.from_address(l_param)

    minmax_info.ptMaxPosition.x = monitor_info.rcWork.left - monitor_info.rcMonitor.left
    minmax_info.ptMaxPosition.y = monitor_info.rcWork.top - monitor_info.rcMonitor.top
    minmax_info.ptMaxSize.x = monitor_info.rcWork.right - monitor_info.rcMonitor.left
    minmax_info.ptMaxSize.y = monitor_info.rcWork.bottom - monitor_info.rcMonitor.top

    screen = window.screen()
    dp_ratio = screen.devicePixelRatio() if screen else 1.0

    min_w = int(_int_property(window, "minimumWidth", 0) * dp_ratio)
    min_h = int(_int_property(window, "minimumHeight", 0) * dp_ratio)
    max_w = int(
        _int_property(
            window,
            "maximumWidth",
            monitor_info.rcWork.right - monitor_info.rcWork.left,
        )
        * dp_ratio
    )
    max_h = int(
        _int_property(
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


def _int_property(window, name: str, default) -> int:
    value = getattr(window, name, default)
    if callable(value):
        value = value()
    if value is None:
        value = default
    return int(value)


def _appbar_data() -> APPBARDATA:
    abd = APPBARDATA()
    ctypes.memset(ctypes.byref(abd), 0, ctypes.sizeof(abd))
    abd.cbSize = ctypes.sizeof(APPBARDATA)
    return abd


def _taskbar_edge(hwnd: int) -> int:
    """自动隐藏任务栏所在边；找不到返回 -1。"""
    abd = _appbar_data()
    abd.hWnd = FindWindow("Shell_TrayWnd", None)
    if not abd.hWnd:
        return -1

    window_monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)
    taskbar_monitor = MonitorFromWindow(abd.hWnd, MONITOR_DEFAULTTOPRIMARY)
    if not window_monitor or taskbar_monitor != window_monitor:
        return -1

    ctypes.windll.shell32.SHAppBarMessage(ABM_GETTASKBARPOS, ctypes.byref(abd))
    return abd.uEdge


class WinEventFilter(QAbstractNativeEventFilter):
    def __init__(self, windows: list, on_window_visible=None):
        super().__init__()
        self.windows = windows
        self.hwnds = {}
        self.resize_border = RESIZE_BORDER
        self._in_move_loop = False
        self._max_button_pressed_hwnd = 0

        for window in self.windows:
            window.visibleChanged.connect(
                lambda visible, w=window: self._on_visible_changed(visible, w)
            )

    def initialize_windows(self):
        for window in self.windows:
            self._init_window_handle(window)

    def _on_visible_changed(self, visible: bool, window: QQuickWindow):
        if visible and self.hwnds.get(window) is None:
            self._init_window_handle(window)

    def _init_window_handle(self, window: QQuickWindow):
        hwnd = int(window.winId())
        self.hwnds[window] = hwnd
        set_window_property(window, "snapLayoutsSupported", bool(is_win11()))
        self.sync_window_backdrop(window)

    def sync_window_backdrop(self, window: QQuickWindow):
        hwnd = self.hwnds.get(window)
        if hwnd is None:
            return

        set_window_styles(window, hwnd)
        extend_frame_into_client_area(window, hwnd)
        apply_fullscreen_opengl_border_workaround(window, hwnd)

    def nativeEventFilter(self, event_type: QByteArray, message):
        if event_type not in (b"windows_generic_MSG", b"windows_dispatcher_MSG"):
            return False, 0

        hwnd, message_id, w_param, l_param = message_parts(message)

        for window in self.windows:
            if self.hwnds.get(window) != hwnd:
                continue
            return self._dispatch(window, hwnd, message_id, w_param, l_param)

        return False, 0

    def _dispatch(self, window, hwnd: int, message_id: int, w_param: int, l_param: int):
        if message_id == WM_ENTERSIZEMOVE:
            self._in_move_loop = True
        elif message_id == WM_EXITSIZEMOVE:
            self._in_move_loop = False
            invalidate_interactive_rects(window)
        elif message_id in (WM_SIZE, WM_SHOWWINDOW):
            invalidate_interactive_rects(window)

        if message_id in (WM_NCLBUTTONDOWN, WM_NCLBUTTONDBLCLK) and w_param == HTMAXBUTTON:
            self._max_button_pressed_hwnd = hwnd
            set_window_property(window, "titleBarMaxButtonPressed", True)
            user32.SetCapture(hwnd)
            return True, 0

        if message_id in (WM_NCLBUTTONUP, WM_LBUTTONUP):
            if self._max_button_pressed_hwnd == hwnd:
                self._max_button_pressed_hwnd = 0
                set_window_property(window, "titleBarMaxButtonPressed", False)
                user32.ReleaseCapture()
                if _pointer_over_max_button(window, hwnd):
                    QTimer.singleShot(0, lambda w=window: _toggle_maximize(w))
                return True, 0

        if message_id in (WM_LBUTTONDOWN, WM_CANCELMODE) and self._max_button_pressed_hwnd:
            self._max_button_pressed_hwnd = 0
            set_window_property(window, "titleBarMaxButtonPressed", False)
            user32.ReleaseCapture()

        if message_id == WM_NCMOUSEMOVE:
            _set_max_button_hover(window, _pointer_over_max_button(window, hwnd))
        elif message_id in (WM_NCMOUSELEAVE, WM_MOUSELEAVE):
            _set_max_button_hover(window, False)

        if message_id in _FRAME_MESSAGES:
            extend_frame_into_client_area(window, hwnd)
        if message_id in _FULLSCREEN_MESSAGES:
            apply_fullscreen_opengl_border_workaround(window, hwnd)
        if message_id == WM_NCHITTEST:
            handled, code = hit_test(
                window, hwnd, l_param, self.resize_border, self._in_move_loop
            )
            if handled:
                _set_max_button_hover(window, code == HTMAXBUTTON)
            return handled, code
        if message_id == WM_NCCALCSIZE and w_param:
            return apply_nccalcsize(hwnd, l_param)
        if message_id == WM_SYSCOMMAND:
            return False, 0
        if message_id == WM_GETMINMAXINFO:
            return apply_getminmaxinfo(window, hwnd, l_param)
        return False, 0


def _set_max_button_hover(window, hovered: bool) -> None:
    set_window_property(window, "titleBarMaxButtonHovered", hovered)


def _toggle_maximize(window) -> None:
    hwnd = int(window.winId())
    if is_maximized(hwnd):
        window.showNormal()
    else:
        window.showMaximized()


def _pointer_over_max_button(window, hwnd: int) -> bool:
    screen = window.screen()
    dp_ratio = screen.devicePixelRatio() if screen else 1.0
    rect = max_button_rect(window, dp_ratio)
    if rect is None:
        return False

    point = wintypes.POINT()
    if not user32.GetCursorPos(ctypes.byref(point)):
        return False

    origin = wintypes.POINT(0, 0)
    user32.ClientToScreen(hwnd, ctypes.byref(origin))
    return inside_rect(rect, point.x - origin.x, point.y - origin.y, 2)
