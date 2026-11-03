"""QML 里的 ``WinEventManager``：窗口句柄、拖动、最大化、帧同步。"""

import platform

from PySide6.QtCore import QObject, QPoint, Slot
from PySide6.QtGui import QCursor
from win32api import SendMessage
from win32gui import ReleaseCapture
import win32con

from RinUI.core.config import is_windows
from RinUI.core.logger import logger

from .frame import sync_window_frame
from .winapi import is_maximized


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
        pending = self.pending_frame_sync_windows
        self.pending_frame_sync_windows = []
        for window in pending:
            self.syncWindowFrame(window)

    @Slot(QObject, result=int)
    def getWindowId(self, window):
        logger.debug("GetWindowId: %s", window.winId())
        return int(window.winId())

    @Slot(result=QPoint)
    def cursorPos(self):
        """光标的全局坐标（与 window.x/y 同一坐标系）。

        QML 的 mouse.x 是窗口内相对坐标，窗口一移动坐标系就跟着动，用它算位移
        会形成正反馈（拖动时抖动、甚至飞出屏幕）。
        """
        return QCursor.pos()

    @Slot(int)
    def drag_window_event(self, hwnd: int):
        """旧行为：QML 按下时同步进入系统移动循环。默认已由原生 HTCAPTION 接管。"""
        if not is_windows() or type(hwnd) is not int or hwnd == 0:
            logger.debug(
                "Use Qt method to drag window on: %s"
                if not is_windows()
                else "Invalid window handle: %s",
                platform.system() if not is_windows() else hwnd,
            )
            return

        ReleaseCapture()
        SendMessage(
            hwnd, win32con.WM_SYSCOMMAND, win32con.SC_MOVE | win32con.HTCAPTION, 0
        )

    @Slot(QObject)
    def syncWindowFrame(self, window):
        if not is_windows() or window is None:
            return

        try:
            hwnd = int(window.winId())
        except Exception:
            self._queue(window)
            return

        if not self.windows:
            self._queue(window)
            return

        sync_window_frame(window, self.on_window_frame_changed)

    def _queue(self, window):
        if window not in self.pending_frame_sync_windows:
            self.pending_frame_sync_windows.append(window)

    @Slot(QObject)
    def maximizeWindow(self, window):
        if not is_windows() or window is None:
            logger.debug(
                "Use Qt method to toggle window state on: %s"
                if not is_windows()
                else "Invalid window object",
                platform.system(),
            )
            return

        try:
            if is_maximized(int(window.winId())):
                window.showNormal()
            else:
                window.showMaximized()
        except Exception as err:
            logger.error("Error toggling window state: %s", err)
