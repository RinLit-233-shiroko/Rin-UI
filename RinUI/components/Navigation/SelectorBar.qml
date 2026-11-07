import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../../components"
import "../../themes"


TabBar {
    id: root
    implicitWidth: contentWidth
    activeFocusOnTab: true
    focusPolicy: Qt.StrongFocus

    function updateKeyboardFocus() {
        for (let i = 0; i < root.count; ++i) {
            const item = root.itemAt(i)
            if (item) {
                item.keyboardFocus = root.activeFocus && i === root.currentIndex
            }
        }
    }

    onActiveFocusChanged: updateKeyboardFocus()
    onCurrentIndexChanged: updateKeyboardFocus()

    Component.onCompleted: Qt.callLater(updateKeyboardFocus)

    Keys.onLeftPressed: function(event) {
        if (root.currentIndex > 0) {
            root.currentIndex -= 1
        }
        event.accepted = true
    }

    Keys.onRightPressed: function(event) {
        if (root.currentIndex < root.count - 1) {
            root.currentIndex += 1
        }
        event.accepted = true
    }

    background: Item {}
}
