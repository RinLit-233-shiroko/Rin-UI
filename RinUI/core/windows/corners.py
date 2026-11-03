"""贴靠 / 最大化时把窗口圆角切成直角。"""

import ctypes

from RinUI.core.config import is_win11

from .winapi import (
    DWMWA_WINDOW_CORNER_PREFERENCE,
    DWMWCP_DONOTROUND,
    DWMWCP_ROUND,
    dwmapi,
    is_maximized,
    monitor_info,
    window_rect,
)


def _snap_target_rects(work):
    """Win11 贴靠布局能产生的窗口矩形（相对工作区，物理像素）。"""
    left, top = work.left, work.top
    width = work.right - work.left
    height = work.bottom - work.top
    targets = []

    def add(fx, fy, fw, fh):
        targets.append(
            (
                left + int(fx * width),
                top + int(fy * height),
                left + int((fx + fw) * width),
                top + int((fy + fh) * height),
            )
        )

    add(0.0, 0.0, 0.5, 1.0)
    add(0.5, 0.0, 0.5, 1.0)
    add(0.0, 0.0, 1.0, 0.5)
    add(0.0, 0.5, 1.0, 0.5)
    for index in range(3):
        add(index / 3.0, 0.0, 1.0 / 3.0, 1.0)
    add(0.0, 0.0, 2.0 / 3.0, 1.0)
    add(1.0 / 3.0, 0.0, 2.0 / 3.0, 1.0)
    for fx in (0.0, 0.5):
        for fy in (0.0, 0.5):
            add(fx, fy, 0.5, 0.5)
    return targets


def is_window_snapped(hwnd: int, tolerance: int = 12) -> bool:
    """窗口是否处于贴靠状态。

    Windows 没有公开"已贴靠"的接口，这里用窗口矩形比对 Win11 贴靠能产生的
    那些矩形；留余量是因为相邻窗口之间有间隙、DPR 换算也会差一两像素。
    """
    try:
        rect = window_rect(hwnd)
        info = monitor_info(hwnd)
        if rect is None or info is None:
            return False
        work = info.rcWork
        if work.right - work.left <= 0 or work.bottom - work.top <= 0:
            return False
        for target in _snap_target_rects(work):
            if (
                abs(rect.left - target[0]) <= tolerance
                and abs(rect.top - target[1]) <= tolerance
                and abs(rect.right - target[2]) <= tolerance
                and abs(rect.bottom - target[3]) <= tolerance
            ):
                return True
        return False
    except Exception:
        return False


class CornerController:
    """按几何状态维护 DWMWA_WINDOW_CORNER_PREFERENCE。

    主题层启动时一律写成 ROUND，贴靠/最大化状态下会留下圆角，这里负责纠正，
    并把结果同步给 QML（windowCornersSquare），让卡片圆角跟着变。
    """

    def __init__(self):
        self._state = {}

    def update(self, window, hwnd: int):
        if not is_win11():
            return
        try:
            square = is_maximized(hwnd) or is_window_snapped(hwnd)
        except Exception:
            return

        value = DWMWCP_DONOTROUND if square else DWMWCP_ROUND
        if self._state.get(hwnd) != value:
            preference = ctypes.c_int(value)
            try:
                result = dwmapi.DwmSetWindowAttribute(
                    hwnd,
                    DWMWA_WINDOW_CORNER_PREFERENCE,
                    ctypes.byref(preference),
                    ctypes.sizeof(preference),
                )
            except Exception:
                result = -1
            if result == 0:
                self._state[hwnd] = value

        try:
            if bool(window.property("windowCornersSquare")) != square:
                window.setProperty("windowCornersSquare", square)
        except Exception:
            pass
