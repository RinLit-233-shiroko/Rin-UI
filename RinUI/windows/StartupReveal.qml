import QtQuick 2.15

Item {
    id: root
    // continue fix e6a30e6 and #97 
    // qml你赢了
    property var window
    property bool enabled: false
    property bool completed: !enabled
    property int fallbackInterval: 1000

    visible: false

    function complete() {
        if (completed)
            return

        completed = true
    }

    Binding {
        target: root.window
        property: "opacity"
        value: 0
        when: root.enabled && root.window && root.window.visible && !root.completed
        restoreMode: Binding.RestoreBindingOrValue
    }

    Component.onCompleted: {
        if (root.enabled && root.window && root.window.visible)
            Qt.callLater(root.complete)
    }

    Connections {
        target: root.window
        ignoreUnknownSignals: true

        function onVisibleChanged() {
            if (root.enabled && root.window.visible)
                Qt.callLater(root.complete)
        }

        function onFrameSwapped() {
            root.complete()
        }
    }

    Timer {
        running: root.enabled && root.window && root.window.visible && !root.completed
        interval: root.fallbackInterval
        repeat: false
        onTriggered: root.complete()
    }
}
