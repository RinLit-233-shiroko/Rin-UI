"""Windows 原生窗口支持。

按职责拆分：

- :mod:`winapi`    Win32 结构体、常量、最小封装
- :mod:`frame`     边框样式 / 非客户区扩展 / 帧刷新
- :mod:`corners`   贴靠、最大化时的圆角切换
- :mod:`title_bar` 标题栏几何（按钮区、最大化按钮、可交互控件）
- :mod:`hit_test`  WM_NCHITTEST / WM_NCCALCSIZE / WM_GETMINMAXINFO
- :mod:`manager`   QML 侧 ``WinEventManager``
- :mod:`filter`    原生事件过滤器
"""

from .filter import WinEventFilter
from .manager import WinEventManager

__all__ = ["WinEventFilter", "WinEventManager"]
