DEFAULT_TITLE_BAR_HEIGHT = 32
RESIZE_BORDER = 8


def title_bar_height_px(window, dp_ratio: float) -> int:
    """标题栏高度（设备像素）。未设置 titleBarHeight 时按 32 DIP 处理。"""
    try:
        height = window.property("titleBarHeight")
    except Exception:
        height = None
    if not height:
        height = DEFAULT_TITLE_BAR_HEIGHT
    return int(height * dp_ratio)
