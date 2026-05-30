from PySide6.QtCore import Qt
from PySide6.QtGui import QGuiApplication

# HiDPI 支持：在 QApplication 创建前设置缩放策略
# PassThrough 使用精确的小数缩放因子，避免字体模糊
if hasattr(Qt, "HighDpiScaleFactorRoundingPolicy"):
    QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )

from .core import *

__version__ = "0.4.0"
__author__ = "RinLit"
