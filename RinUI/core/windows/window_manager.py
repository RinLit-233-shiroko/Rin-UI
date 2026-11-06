import ctypes
import platform

import win32con
from PySide6.QtCore import QObject, QTimer, Slot
from PySide6.QtQuick import QQuickWindow
from win32gui import ReleaseCapture

from RinUI.core.config import is_windows
from RinUI.core.logger import logger
from RinUI.core.windows.winapi import (
    GWL_STYLE,
    MARGINS,
    SWP_FRAMECHANGED,
    SWP_NOACTIVATE,
    SWP_NOMOVE,
    SWP_NOSIZE,
    SWP_NOZORDER,
    WS_BORDER,
    WM_ACTIVATE,
    WM_ACTIVATEAPP,
    WM_NCACTIVATE,
    WS_CAPTION,
    WS_THICKFRAME,
    is_composition_enabled,
    is_exact_monitor_sized_window,
    is_maximized,
    user32,
)


def refresh_window_frame(hwnd: int) -> None:
    user32.SetWindowPos(
        hwnd,
        0,
        0,
        0,
        0,
        0,
        SWP_NOSIZE | SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED,
    )


def set_window_styles(window: QQuickWindow, hwnd: int) -> None:
    """补上 WS_CAPTION / WS_THICKFRAME。"""
    style = user32.GetWindowLongPtrW(hwnd, GWL_STYLE)
    new_style = style | WS_CAPTION | WS_THICKFRAME
    if new_style == style:
        return

    user32.SetWindowLongPtrW(hwnd, GWL_STYLE, new_style)
    window.setProperty("_rinuiWindowStyleChanged", True)
    refresh_window_frame(hwnd)


def refresh_window_frame_if_needed(window: QQuickWindow, hwnd: int) -> None:
    if not window.property("_rinuiWindowStyleChanged"):
        return

    window.setProperty("_rinuiWindowStyleChanged", False)
    refresh_window_frame(hwnd)


def extend_frame_into_client_area(window: QQuickWindow, hwnd: int) -> None:
    if not window.property("backdropEnabled"):
        return
    if not is_composition_enabled():
        return

    margins = MARGINS(-1, -1, -1, -1)
    ctypes.windll.dwmapi.DwmExtendFrameIntoClientArea(hwnd, ctypes.byref(margins))


def apply_fullscreen_opengl_border_workaround(window: QQuickWindow, hwnd: int) -> None:
    if not window.property("enableFullscreenOpenGLBorderWorkaround"):
        return
    if not is_exact_monitor_sized_window(window, hwnd):
        return

    style = user32.GetWindowLongPtrW(hwnd, GWL_STYLE)
    if style & WS_BORDER:
        return

    user32.SetWindowLongPtrW(hwnd, GWL_STYLE, style | WS_BORDER)
    refresh_window_frame(hwnd)


def _make_margins(value: int):
    from RinUI.core.windows.winapi import MARGINS

    return MARGINS(value, value, value, value)


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
        user32.SendMessageW(
            hwnd,
            win32con.WM_SYSCOMMAND,
            win32con.SC_MOVE | win32con.HTCAPTION,
            0,
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

        style = user32.GetWindowLongPtrW(hwnd, GWL_STYLE)
        user32.SetWindowLongPtrW(hwnd, GWL_STYLE, style | WS_CAPTION | WS_THICKFRAME)
        if window.property("backdropEnabled") and is_composition_enabled():
            margins = MARGINS(-1, -1, -1, -1)
            ctypes.windll.dwmapi.DwmExtendFrameIntoClientArea(
                hwnd, ctypes.byref(margins)
            )
        user32.SendMessageW(hwnd, WM_ACTIVATEAPP, 1, 0)
        user32.SendMessageW(hwnd, WM_NCACTIVATE, 1, 0)
        user32.SendMessageW(hwnd, WM_ACTIVATE, 1, 0)
        user32.SetWindowPos(
            hwnd,
            0,
            0,
            0,
            0,
            0,
            SWP_NOSIZE | SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED,
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
