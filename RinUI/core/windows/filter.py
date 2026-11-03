"""原生事件过滤器：把窗口消息分发给各个职责模块。"""

import ctypes
from ctypes import wintypes

from PySide6.QtCore import QAbstractNativeEventFilter, QByteArray, QTimer
from win32con import HTMAXBUTTON

from RinUI.core.logger import logger

from . import frame
from .corners import CornerController
from .hit_test import apply_getminmaxinfo, apply_nccalcsize, hit_test
from .title_bar import pointer_over_max_button
from .winapi import (
    WM_ACTIVATE,
    WM_ACTIVATEAPP,
    WM_CANCELMODE,
    WM_DWMCOMPOSITIONCHANGED,
    WM_EXITSIZEMOVE,
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
    WM_NCMOUSELEAVE,
    WM_SHOWWINDOW,
    WM_SIZE,
    WM_SYSCOMMAND,
    WM_WINDOWPOSCHANGED,
    is_maximized,
    user32,
)


class WinEventFilter(QAbstractNativeEventFilter):
    def __init__(self, windows: list, on_window_visible=None):
        super().__init__()
        self.windows = windows
        self.hwnds = {}
        self.resize_border = 8
        # 最大化按钮"按下中"的窗口：按下只点亮，松开才切换状态
        self.max_button_pressed_hwnd = 0
        self._corners = CornerController()

        for window in self.windows:
            window.visibleChanged.connect(
                lambda visible, w=window: self._on_visible_changed(visible, w)
            )

    # --- 生命周期 -----------------------------------------------------
    def initialize_windows(self):
        for window in self.windows:
            self._init_window_handle(window)

    def _on_visible_changed(self, visible: bool, window):
        if visible and self.hwnds.get(window) is None:
            self._init_window_handle(window)

    def _init_window_handle(self, window):
        hwnd = int(window.winId())
        self.hwnds[window] = hwnd
        # Win10 的窗口本身是直角，QML 侧据此决定要不要画圆角
        try:
            window.setProperty("windowCornersSupported", bool(is_win11()))
        except Exception:
            pass
        self.sync_window_backdrop(window)

    # --- 边框 / 背景（保留为方法，供外部复用） -------------------------
    def sync_window_backdrop(self, window):
        hwnd = self.hwnds.get(window)
        if hwnd is None:
            return
        self.set_window_styles(window)
        frame.extend_frame_into_client_area(window, hwnd)
        frame.apply_fullscreen_border_workaround(window, hwnd)

    def set_window_styles(self, window):
        hwnd = self.hwnds.get(window)
        if hwnd is None:
            return
        if frame.ensure_frame_styles(hwnd):
            window.setProperty("_rinuiWindowStyleChanged", True)
            frame.refresh_frame(hwnd)

    def refresh_window_frame(self, window):
        hwnd = self.hwnds.get(window)
        if hwnd is not None:
            frame.refresh_frame(hwnd)

    def refresh_window_frame_if_needed(self, window):
        hwnd = self.hwnds.get(window)
        if hwnd is None:
            return
        if not window.property("_rinuiWindowStyleChanged"):
            return
        window.setProperty("_rinuiWindowStyleChanged", False)
        frame.refresh_frame(hwnd)

    def extend_frame_into_client_area(self, window):
        hwnd = self.hwnds.get(window)
        if hwnd is not None:
            frame.extend_frame_into_client_area(window, hwnd)

    def apply_fullscreen_opengl_border_workaround(self, window):
        hwnd = self.hwnds.get(window)
        if hwnd is not None:
            frame.apply_fullscreen_border_workaround(window, hwnd)

    # --- 最大化按钮状态回填 QML ---------------------------------------
    def _toggle_maximize(self, window):
        try:
            hwnd = int(window.winId())
            if is_maximized(hwnd):
                window.showNormal()
            else:
                window.showMaximized()
        except Exception as exc:
            logger.debug("[RinUI] toggle maximize failed: %s", exc)

    def _pointer_over_max_button(self, window) -> bool:
        return pointer_over_max_button(window)

    def _set_max_button_pressed(self, window, pressed: bool):
        try:
            if bool(window.property("titleBarMaxButtonPressed")) != pressed:
                window.setProperty("titleBarMaxButtonPressed", pressed)
        except Exception:
            pass

    def _set_max_button_hover(self, window, hovered: bool):
        # 这块被判成 HTMAXBUTTON 后不再产生客户区鼠标事件，HoverHandler 收不到，
        # 高亮和 ToolTip 得由这里回填
        try:
            if bool(window.property("titleBarMaxButtonHovered")) != hovered:
                window.setProperty("titleBarMaxButtonHovered", hovered)
        except Exception:
            pass

    # --- 消息分发 -----------------------------------------------------
    def nativeEventFilter(self, event_type: QByteArray, message):
        if event_type not in (b"windows_generic_MSG", b"windows_dispatcher_MSG"):
            return False, 0

        message_addr = self._message_address(message)
        if message_addr is None:
            return False, 0

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

        for window in self.windows:
            hwnd_window = self.hwnds.get(window)
            if hwnd_window != hwnd:
                continue
            return self._dispatch(window, hwnd_window, message_id, w_param, l_param)

        return False, 0

    @staticmethod
    def _message_address(message):
        try:
            return int(message)
        except Exception:
            pass
        try:
            buffer = memoryview(message)
            return ctypes.addressof(ctypes.c_char.from_buffer(buffer))
        except Exception:
            return None

    def _dispatch(self, window, hwnd: int, message_id, w_param, l_param):
        if message_id in (
            WM_SIZE,
            WM_WINDOWPOSCHANGED,
            WM_SHOWWINDOW,
            WM_ACTIVATE,
            WM_NCACTIVATE,
            WM_ACTIVATEAPP,
            WM_DWMCOMPOSITIONCHANGED,
        ):
            frame.extend_frame_into_client_area(window, hwnd)

        if message_id in (WM_SIZE, WM_WINDOWPOSCHANGED, WM_DWMCOMPOSITIONCHANGED):
            frame.apply_fullscreen_border_workaround(window, hwnd)

        if message_id in (
            WM_SIZE,
            WM_WINDOWPOSCHANGED,
            WM_DWMCOMPOSITIONCHANGED,
            WM_EXITSIZEMOVE,
        ):
            self._corners.update(window, hwnd)

        handled = self._handle_max_button(window, hwnd, message_id, w_param, l_param)
        if handled is not None:
            return handled

        if message_id == WM_NCMOUSELEAVE or message_id == WM_MOUSELEAVE:
            # 光标离开时复位悬停；按下态不在这里清，和另外两个按钮的手感一致
            self._set_max_button_hover(window, False)

        if message_id == WM_NCHITTEST:
            # 每次命中测试先清悬停，命中最大化按钮时再置回
            self._set_max_button_hover(window, False)
            handled, code, hover = hit_test(window, hwnd, l_param, self.resize_border)
            if hover:
                self._set_max_button_hover(window, True)
            return handled, code

        if message_id == WM_NCCALCSIZE and w_param:
            return apply_nccalcsize(hwnd, l_param)

        if message_id == WM_SYSCOMMAND:
            return False, 0

        if message_id == WM_GETMINMAXINFO:
            return apply_getminmaxinfo(window, hwnd, l_param)

        return False, 0

    def _handle_max_button(self, window, hwnd: int, message_id, w_param, l_param):
        """最大化按钮的非客户区点击：DefWindowProc 的状态机在无边框窗口里失效。"""
        if message_id in (WM_NCLBUTTONDOWN, WM_NCLBUTTONDBLCLK) and w_param == HTMAXBUTTON:
            self.max_button_pressed_hwnd = hwnd
            self._set_max_button_pressed(window, True)
            # 抓住鼠标，否则指针移出窗口就收不到松开，按下态会一直亮着
            user32.SetCapture(hwnd)
            return True, 0

        if message_id in (WM_NCLBUTTONUP, WM_LBUTTONUP) and (
            self.max_button_pressed_hwnd == hwnd
        ):
            self.max_button_pressed_hwnd = 0
            self._set_max_button_pressed(window, False)
            user32.ReleaseCapture()
            # 松开时指针还在按钮上才算点击；按住在外面松开只是取消
            if self._pointer_over_max_button(window):
                QTimer.singleShot(0, lambda w=window: self._toggle_maximize(w))
            return True, 0

        if self.max_button_pressed_hwnd and message_id in (WM_LBUTTONDOWN, WM_CANCELMODE):
            self.max_button_pressed_hwnd = 0
            self._set_max_button_pressed(window, False)
            user32.ReleaseCapture()

        return None
