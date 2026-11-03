"""非客户区消息：命中测试、非客户区尺寸、最大化尺寸。"""

import ctypes
from ctypes import wintypes

from win32api import MonitorFromWindow
from win32con import (
    HTMAXBUTTON,
    MONITOR_DEFAULTTOPRIMARY,
    MONITOR_DEFAULTTONEAREST,
    SM_CXVIRTUALSCREEN,
    SM_CYVIRTUALSCREEN,
)
from win32gui import FindWindow
from win32api import GetSystemMetrics
from win32com.shell.shellcon import ABM_GETSTATE, ABM_GETTASKBARPOS, ABS_AUTOHIDE

from .title_bar import (
    NATIVE_CAPTION_DRAG,
    dp_ratio,
    native_caption_drag_disabled,
    title_bar_button_width_px,
    title_bar_height_px,
    title_bar_interactive_rects,
    title_bar_max_button_rect,
    title_bar_safe_width_px,
)
from .winapi import (
    APPBARDATA,
    MINMAXINFO,
    NCCALCSIZE_PARAMS,
    client_origin,
    get_resize_border_thickness,
    is_maximized,
    monitor_info,
    shell32,
    user32,
    window_rect,
)

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

# 最大化按钮命中时外扩的容差像素：DPR 取整后按钮边缘可能差一两个像素
_MAX_BUTTON_SLOP = 2


def hit_test(window, hwnd: int, l_param: int, resize_border: int = 8):
    """处理 WM_NCHITTEST，返回 (是否处理, 命中码, 是否悬停在最大化按钮上)。"""
    x = ctypes.c_short(l_param & 0xFFFF).value
    y = ctypes.c_short((l_param >> 16) & 0xFFFF).value

    rect = window_rect(hwnd)
    if rect is None:
        return False, 0, False
    left, top, right, bottom = rect.left, rect.top, rect.right, rect.bottom
    border = resize_border

    if left <= x < left + border:
        if top <= y < top + border:
            return True, HTTOPLEFT, False
        if bottom - border <= y < bottom:
            return True, HTBOTTOMLEFT, False
        return True, HTLEFT, False
    if right - border <= x < right:
        if top <= y < top + border:
            return True, HTTOPRIGHT, False
        if bottom - border <= y < bottom:
            return True, HTBOTTOMRIGHT, False
        return True, HTRIGHT, False
    if top <= y < top + border:
        return True, HTTOP, False
    if bottom - border <= y < bottom:
        return True, HTBOTTOM, False

    ratio = dp_ratio(window)
    if top <= y < top + title_bar_height_px(window, ratio):
        if not NATIVE_CAPTION_DRAG or native_caption_drag_disabled(window):
            return True, HTCLIENT, False

        origin = client_origin(hwnd)
        cx, cy = x - origin.x, y - origin.y

        # 最大化按钮单独给 HTMAXBUTTON，Win11 的 Snap Layouts 只认这个命中码
        max_rect = title_bar_max_button_rect(window, ratio)
        if max_rect is not None:
            mx, my, mw, mh = max_rect
            if (
                mx - _MAX_BUTTON_SLOP <= cx < mx + mw + _MAX_BUTTON_SLOP
                and my - _MAX_BUTTON_SLOP <= cy < my + mh + _MAX_BUTTON_SLOP
            ):
                return True, HTMAXBUTTON, True

        button_px = title_bar_button_width_px(window, ratio)
        safe_px = title_bar_safe_width_px(window, ratio)
        # 按钮左侧永远留一条可拖动安全区，窗口再窄也不至于没地方按
        drag_limit = (right - left) - button_px - safe_px

        # 标题栏里应用自己的控件要留在客户区，否则会被当成拖动窗口吃掉
        if cx < drag_limit:
            for ix, iy, iw, ih in title_bar_interactive_rects(window, ratio):
                if ix <= cx < min(ix + iw, drag_limit) and iy <= cy < iy + ih:
                    return True, HTCLIENT, False

        if x < right - button_px:
            return True, HTCAPTION, False
        return True, HTCLIENT, False

    return False, 0, False


def apply_nccalcsize(hwnd: int, l_param: int):
    """WM_NCCALCSIZE：去掉整个非客户区；最大化时按边框/任务栏收边。"""
    client_rect = ctypes.cast(l_param, ctypes.POINTER(NCCALCSIZE_PARAMS)).contents.rgrc[0]

    if is_maximized(hwnd):
        thickness_y = get_resize_border_thickness(hwnd, False)
        client_rect.top += thickness_y
        client_rect.bottom -= thickness_y
        thickness_x = get_resize_border_thickness(hwnd, True)
        client_rect.left += thickness_x
        client_rect.right -= thickness_x

        # 自动隐藏的任务栏贴在窗口外沿时，再收 1px，避免把任务栏挤走
        edge = _taskbar_autohide_edge(hwnd)
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


def _taskbar_autohide_edge(hwnd: int) -> int:
    appbar = APPBARDATA()
    appbar.cbSize = ctypes.sizeof(APPBARDATA)
    state = shell32.SHAppBarMessage(ABM_GETSTATE, ctypes.byref(appbar))
    if not state & ABS_AUTOHIDE:
        return -1

    tray = APPBARDATA()
    tray.cbSize = ctypes.sizeof(APPBARDATA)
    tray.hWnd = FindWindow("Shell_TrayWnd", None)
    if not tray.hWnd:
        return -1

    window_monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)
    taskbar_monitor = MonitorFromWindow(tray.hWnd, MONITOR_DEFAULTTOPRIMARY)
    if not window_monitor or window_monitor != taskbar_monitor:
        return -1

    shell32.SHAppBarMessage(ABM_GETTASKBARPOS, ctypes.byref(tray))
    return tray.uEdge


def apply_getminmaxinfo(window, hwnd: int, l_param: int):
    """WM_GETMINMAXINFO：最大化尺寸取工作区，尺寸限制不再乘 Qt 的哨兵值。"""
    info = monitor_info(hwnd)
    if info is None:
        info = monitor_info(int(window.winId()))
    if info is None:
        return True, 0

    minmax = MINMAXINFO.from_address(l_param)
    work = info.rcWork
    monitor = info.rcMonitor
    work_w = work.right - work.left
    work_h = work.bottom - work.top

    # 用工作区宽高；原来混用 rcWork 的右/下边界和 rcMonitor 的左/上边界，
    # 多显示器或任务栏在左侧时会算错
    minmax.ptMaxPosition.x = work.left - monitor.left
    minmax.ptMaxPosition.y = work.top - monitor.top
    minmax.ptMaxSize.x = work_w
    minmax.ptMaxSize.y = work_h

    ratio = dp_ratio(window)
    min_w = int(_int_property(window, "minimumWidth", 0) * ratio)
    min_h = int(_int_property(window, "minimumHeight", 0) * ratio)

    # Qt 用 16777215 表示"无上限"；乘上 DPR 会变成两千万级的荒谬数值，
    # 直接换成虚拟屏幕尺寸
    virtual_w = GetSystemMetrics(SM_CXVIRTUALSCREEN) or work_w
    virtual_h = GetSystemMetrics(SM_CYVIRTUALSCREEN) or work_h

    minmax.ptMinTrackSize.x = min_w
    minmax.ptMinTrackSize.y = min_h
    minmax.ptMaxTrackSize.x = _track_limit(window, "maximumWidth", virtual_w, ratio)
    minmax.ptMaxTrackSize.y = _track_limit(window, "maximumHeight", virtual_h, ratio)
    return True, 0


def _int_property(window, name: str, default: int) -> int:
    value = getattr(window, name, default)
    if callable(value):
        value = value()
    if value is None:
        value = default
    return int(value)


def _track_limit(window, name: str, fallback: int, ratio: float) -> int:
    value = _int_property(window, name, 16777215)
    if value >= 16777215:
        return int(fallback)
    return max(1, int(value * ratio))
