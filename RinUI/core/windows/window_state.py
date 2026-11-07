import ctypes
import time
from ctypes import wintypes

from PySide6.QtCore import QPointF, Qt

from RinUI.core.windows.winapi import MONITORINFO, MONITOR_DEFAULTTONEAREST, user32

DEFAULT_TITLE_BAR_HEIGHT = 32
RESIZE_BORDER = 8

BUTTON_WIDTH_FALLBACK = 144.0
SAFE_WIDTH_FALLBACK = 32.0

LEADING_HOST = "rinuiTitleBarLeadingHost"
CONTENT_HOST = "rinuiTitleBarContentHost"

INTERACTIVE_CACHE_TTL = 0.2
_PLAIN_TEXT_TYPES = ("QQuickText", "QQuickPlaceholderText")

_cache = {}


def title_bar_height_px(window, dp_ratio: float) -> int:
    """标题栏高度（设备像素）。未设置 titleBarHeight 时按 32 DIP 处理。"""
    return int(_dip_property(window, "titleBarHeight", DEFAULT_TITLE_BAR_HEIGHT) * dp_ratio)


def button_width_px(window, dp_ratio: float) -> int:
    return int(_dip_property(window, "titleBarButtonWidth", BUTTON_WIDTH_FALLBACK) * dp_ratio)


def safe_width_px(window, dp_ratio: float) -> int:
    return int(_dip_property(window, "titleBarSafeWidth", SAFE_WIDTH_FALLBACK) * dp_ratio)


def max_button_rect(window, dp_ratio: float):
    """最大化按钮矩形（设备像素）；未提供时返回 None。"""
    try:
        rect = window.property("titleBarMaxButtonRect")
    except Exception:
        return None
    if rect is None:
        return None

    try:
        rect_x, rect_y = float(rect.x()), float(rect.y())
        rect_w, rect_h = float(rect.width()), float(rect.height())
    except (AttributeError, TypeError, RuntimeError):
        return None

    if rect_w <= 1 or rect_h <= 1:
        return None

    return (
        rect_x * dp_ratio,
        rect_y * dp_ratio,
        rect_w * dp_ratio,
        rect_h * dp_ratio,
    )


def inside_rect(rect, x: float, y: float, slack: float = 0.0) -> bool:
    rect_x, rect_y, rect_w, rect_h = rect
    return (
        rect_x - slack <= x < rect_x + rect_w + slack
        and rect_y - slack <= y < rect_y + rect_h + slack
    )


def set_window_property(window, name: str, value) -> None:
    try:
        if bool(window.property(name)) == bool(value):
            return
        window.setProperty(name, value)
    except (AttributeError, RuntimeError):
        pass


def interactive_rects(window, dp_ratio: float):
    key = (id(window), int(window.width()), int(window.height()), dp_ratio)
    cached = _cache.get(key)
    now = time.monotonic()
    if cached is not None and now - cached[0] < INTERACTIVE_CACHE_TTL:
        return cached[1]

    rects = _collect_rects(window, dp_ratio)
    _cache[key] = (now, rects)
    return rects


def invalidate_interactive_rects(window=None):
    if window is None:
        _cache.clear()
        return

    for key in [k for k in _cache if k[0] == id(window)]:
        _cache.pop(key, None)


def _dip_property(window, name: str, fallback: float) -> float:
    try:
        value = window.property(name)
    except Exception:
        value = None
    if not value or value <= 0:
        value = fallback
    return float(value)


def _collect_rects(window, dp_ratio: float):
    rects = []
    for host in _title_bar_hosts(window):
        _collect_from(host, window.contentItem(), rects, 0)

    return [
        (x * dp_ratio, y * dp_ratio, w * dp_ratio, h * dp_ratio)
        for x, y, w, h in rects
    ]


def _title_bar_hosts(window):
    hosts = []
    for name in ("titleBarLeadingHost", "titleBarHost"):
        try:
            host = window.property(name)
        except Exception:
            host = None
        if host is not None:
            hosts.append(host)
    return hosts


def _collect_from(item, root, out, depth: int):
    if depth > 24:
        return

    try:
        if not item.isVisible() or not item.isEnabled():
            return
        width = item.width()
        height = item.height()
    except (AttributeError, RuntimeError):
        return

    if width <= 1 or height <= 1:
        return

    if _accepts_left_button(item) and not _is_plain_text(item):
        pos = item.mapToItem(root, QPointF(0.0, 0.0))
        out.append((pos.x(), pos.y(), width, height))
        return

    for child in item.childItems():
        _collect_from(child, root, out, depth + 1)


def _accepts_left_button(item) -> bool:
    try:
        return bool(item.acceptedMouseButtons() & Qt.MouseButton.LeftButton)
    except (AttributeError, RuntimeError):
        return False


def _is_plain_text(item) -> bool:
    try:
        name = item.metaObject().className()
    except (AttributeError, RuntimeError):
        return False
    return name in _PLAIN_TEXT_TYPES or name.startswith(("Text_QMLTYPE", "Label_QMLTYPE"))


def _work_area(hwnd: int):
    monitor = user32.MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST)
    if not monitor:
        return None
    info = MONITORINFO()
    info.cbSize = ctypes.sizeof(MONITORINFO)
    if not user32.GetMonitorInfoW(monitor, ctypes.byref(info)):
        return None
    return info.rcWork


def _snap_targets(work):
    left, top, right, bottom = work.left, work.top, work.right, work.bottom
    width = right - left
    height = bottom - top
    half_w = width / 2.0
    half_h = height / 2.0
    third = height / 3.0
    targets = [
        (left, top, left + half_w, bottom),
        (left + half_w, top, right, bottom),
        (left, top, right, top + half_h),
        (left, top + half_h, right, bottom),
        (left, top, right, top + third),
        (left, top + third, right, top + 2 * third),
        (left, top + 2 * third, right, bottom),
        (left, top, left + width / 3.0, bottom),
        (left + width / 3.0, top, left + 2 * width / 3.0, bottom),
        (left + 2 * width / 3.0, top, right, bottom),
        (left, top, left + half_w, top + half_h),
        (left + half_w, top, right, top + half_h),
        (left, top + half_h, left + half_w, bottom),
        (left + half_w, top + half_h, right, bottom),
    ]
    return targets


def is_window_snapped(hwnd: int, tolerance: int = 12) -> bool:
    rect = wintypes.RECT()
    if not user32.GetWindowRect(hwnd, ctypes.byref(rect)):
        return False
    work = _work_area(hwnd)
    if work is None:
        return False
    current = (rect.left, rect.top, rect.right, rect.bottom)
    for target in _snap_targets(work):
        if all(abs(a - b) <= tolerance for a, b in zip(current, target)):
            return True
    return False
