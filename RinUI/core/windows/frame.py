"""窗口边框 / 背景：样式位、非客户区扩展、帧刷新。"""

import ctypes

from PySide6.QtCore import QTimer

from .winapi import (
    GWL_STYLE,
    MARGINS,
    SWP_FLAGS_FRAME_REFRESH,
    WM_ACTIVATE,
    WM_ACTIVATEAPP,
    WM_NCACTIVATE,
    WS_BORDER,
    WS_CAPTION,
    WS_THICKFRAME,
    dwmapi,
    is_composition_enabled,
    is_exact_monitor_sized_window,
    user32,
)


def refresh_frame(hwnd: int):
    """让系统按新样式重算非客户区。"""
    user32.SetWindowPos(hwnd, 0, 0, 0, 0, 0, SWP_FLAGS_FRAME_REFRESH)


def ensure_frame_styles(hwnd: int) -> bool:
    """补上 WS_CAPTION / WS_THICKFRAME，返回是否发生变化。"""
    style = user32.GetWindowLongPtrW(hwnd, GWL_STYLE)
    new_style = style | WS_CAPTION | WS_THICKFRAME
    if new_style == style:
        return False
    user32.SetWindowLongPtrW(hwnd, GWL_STYLE, new_style)
    return True


def extend_frame_into_client_area(window, hwnd: int):
    """把 DWM 帧扩展进客户区，让亚克力/云母背景透出来。"""
    if not window.property("backdropEnabled"):
        return
    if not is_composition_enabled():
        return
    margins = MARGINS(-1, -1, -1, -1)
    dwmapi.DwmExtendFrameIntoClientArea(hwnd, ctypes.byref(margins))


def apply_fullscreen_border_workaround(window, hwnd: int):
    """全屏时补一条 WS_BORDER，避免 OpenGL 边框残影。"""
    if not window.property("enableFullscreenOpenGLBorderWorkaround"):
        return
    if not is_exact_monitor_sized_window(window, hwnd):
        return
    style = user32.GetWindowLongPtrW(hwnd, GWL_STYLE)
    if style & WS_BORDER:
        return
    user32.SetWindowLongPtrW(hwnd, GWL_STYLE, style | WS_BORDER)
    refresh_frame(hwnd)


def sync_window_frame(window, on_frame_changed=None):
    """重建窗口边框并请求一次激活（启动时、以及 flags 变化后调用）。"""
    try:
        hwnd = int(window.winId())
    except Exception:
        return

    ensure_frame_styles(hwnd)
    extend_frame_into_client_area(window, hwnd)

    # 伪造激活消息，让系统按"活动窗口"重画标题栏与边框
    user32.SendMessageW(hwnd, WM_ACTIVATEAPP, 1, 0)
    user32.SendMessageW(hwnd, WM_NCACTIVATE, 1, 0)
    user32.SendMessageW(hwnd, WM_ACTIVATE, 1, 0)
    refresh_frame(hwnd)
    window.requestActivate()

    if on_frame_changed is not None:
        QTimer.singleShot(0, on_frame_changed)
