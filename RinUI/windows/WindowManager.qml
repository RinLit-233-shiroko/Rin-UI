pragma Singleton
import QtQuick 2.15

Item {
    function _isWinMgrInitialized() {
        return typeof WinEventManager!== "undefined"
    }

    function sendDragWindowEvent(window) {
        if (!_isWinMgrInitialized()) {
            console.error("WindowManager is not defined.")
            return -1
        }
        WinEventManager.drag_window_event(WinEventManager.getWindowId(window))
    }

    function maximizeWindow(window) {
        if (!_isWinMgrInitialized()) {
            console.warn("WindowManager is not defined.")
        }
        if (Qt.platform.os === "windows") {
            WinEventManager.maximizeWindow(WinEventManager.getWindowId(window))
            return  // 在win环境使用原生方法拖拽
        }

        toggleMaximizeWindow(window)
    }

    function toggleMaximizeWindow(window) {
        if (!window) return;

        if (window.visibility === Window.Maximized || window.isMaximized) {
            window.showNormal();
        } else {
            window.showMaximized();
        }
    }
}
