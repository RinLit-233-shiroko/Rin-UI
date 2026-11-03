"""标题栏几何：按钮区、最大化按钮、可交互控件与原生拖动开关。"""

import os

from PySide6.QtCore import QPointF, Qt

from .winapi import client_origin, cursor_pos

# 标题栏是否交给系统原生拖动（HTCAPTION）。设为 0 退回旧行为，便于回滚。
NATIVE_CAPTION_DRAG = os.environ.get("RINUI_NATIVE_CAPTION_DRAG", "1").strip().lower() not in (
    "0",
    "false",
    "no",
    "off",
)

# TitleBar.qml 里两块内容插槽的 objectName
TITLE_BAR_LEADING_HOST = "rinuiTitleBarLeadingHost"
TITLE_BAR_CONTENT_HOST = "rinuiTitleBarContentHost"

# Text/占位符本身会接左键，但标题栏里它们只是图标和标题，要留给系统拖动
_PLAIN_TEXT_CLASSES = ("QQuickText", "QQuickPlaceholderText")


def _prop(window, name, default=None):
    try:
        return window.property(name)
    except Exception:
        return default


def native_caption_drag_disabled(window) -> bool:
    return bool(_prop(window, "titleBarNativeDragDisabled"))


def title_bar_button_width_px(window, dp_ratio: float) -> int:
    """右侧窗口控制按钮区宽度（物理像素）；取不到按三个 48px 按钮兜底。"""
    try:
        width = float(_prop(window, "titleBarButtonWidth") or 0)
    except Exception:
        width = 0.0
    if width <= 0:
        width = 144.0
    return int(width * dp_ratio)


def title_bar_safe_width_px(window, dp_ratio: float) -> int:
    """按钮左侧那条"必定可拖动"的安全区宽度（物理像素）。"""
    try:
        width = float(_prop(window, "titleBarSafeWidth"))
    except Exception:
        width = 0.0
    if width <= 0:
        width = 32.0
    return int(width * dp_ratio)


def title_bar_max_button_rect(window, dp_ratio: float):
    """最大化按钮的矩形（物理像素），取不到返回 None。"""
    rect = _prop(window, "titleBarMaxButtonRect")
    if rect is None:
        return None
    try:
        x = float(rect.x())
        y = float(rect.y())
        w = float(rect.width())
        h = float(rect.height())
    except Exception:
        return None
    if w <= 1 or h <= 1:
        return None
    return (int(x * dp_ratio), int(y * dp_ratio), int(w * dp_ratio), int(h * dp_ratio))


def title_bar_height_px(window, dp_ratio: float) -> int:
    try:
        height = float(_prop(window, "titleBarHeight") or 32)
    except Exception:
        height = 32.0
    return int(height * dp_ratio)


def _walk_hosts(root_item):
    hosts = []
    stack = [root_item]
    while stack:
        item = stack.pop()
        if item is None:
            continue
        try:
            if item.objectName() in (TITLE_BAR_LEADING_HOST, TITLE_BAR_CONTENT_HOST):
                hosts.append(item)
                continue
            stack.extend(item.childItems())
        except Exception:
            continue
    return hosts


def _accepts_left_button(item) -> bool:
    try:
        return bool(item.acceptedMouseButtons() & Qt.MouseButton.LeftButton)
    except Exception:
        return False


def _is_plain_text(item) -> bool:
    try:
        name = item.metaObject().className()
    except Exception:
        return False
    return name in _PLAIN_TEXT_CLASSES or name.startswith(
        ("Text_QMLTYPE", "Label_QMLTYPE")
    )


def _collect_rects(item, target, out, depth=0):
    if item is None or depth > 24:
        return
    try:
        if not item.isVisible() or not item.isEnabled():
            return
        width, height = item.width(), item.height()
    except Exception:
        return
    if width <= 1 or height <= 1:
        return

    if _accepts_left_button(item) and not _is_plain_text(item):
        try:
            origin = item.mapToItem(target, QPointF(0.0, 0.0))
        except Exception:
            return
        # 命中一个控件就不再往里钻，避免把内部零件也算成热区
        out.append((origin.x(), origin.y(), width, height))
        return

    try:
        children = item.childItems()
    except Exception:
        return
    for child in children:
        _collect_rects(child, target, out, depth + 1)


def title_bar_interactive_rects(window, dp_ratio: float):
    """标题栏里应用自己放进去的控件矩形（物理像素）。

    标题栏整体交给 HTCAPTION 之后，titleBarArea / titleBarLeadingArea 里的控件
    会落进非客户区，点不动；这里把它们挑出来，命中时返回 HTCLIENT 还给 QML。
    """
    try:
        root_item = window.contentItem()
    except Exception:
        return []
    if root_item is None:
        return []

    rects = []
    for host in _walk_hosts(root_item):
        try:
            if not host.isVisible():
                continue
        except Exception:
            continue
        found = []
        _collect_rects(host, root_item, found)
        for x, y, w, h in found:
            rects.append(
                (
                    int(x * dp_ratio),
                    int(y * dp_ratio),
                    int(w * dp_ratio),
                    int(h * dp_ratio),
                )
            )
    return rects


def dp_ratio(window) -> float:
    screen = window.screen()
    return screen.devicePixelRatio() if screen else 1.0


def pointer_over_max_button(window) -> bool:
    """光标是否停在最大化按钮上（与命中测试同一口径）。"""
    try:
        hwnd = int(window.winId())
        rect = title_bar_max_button_rect(window, dp_ratio(window))
        if rect is None:
            return False
        point = cursor_pos()
        origin = client_origin(hwnd)
        cx, cy = point.x - origin.x, point.y - origin.y
        mx, my, mw, mh = rect
        return mx <= cx < mx + mw and my <= cy < my + mh
    except Exception:
        return False
