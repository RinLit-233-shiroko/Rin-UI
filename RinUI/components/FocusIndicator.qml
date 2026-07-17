import QtQuick 2.15
import "../themes"

Item {
    id: root
    anchors.fill: parent
    z: 9999

    required property Item control
    property real radius: Theme.currentTheme.appearance.buttonRadius

    visible: control.visualFocus &&
         (control.focusReason === Qt.TabFocusReason ||
          control.focusReason === Qt.BacktabFocusReason)

    Rectangle {
        anchors.fill: parent
        anchors.margins: -(2 + 1) + Theme.currentTheme.appearance.borderWidth
        color: "transparent"
        border.width: 2
        border.color: Theme.currentTheme.colors.focusBorderOuter
        radius: root.radius

        // inner
        Rectangle {
            anchors.fill: parent
            anchors.margins: parent.border.width
            radius: root.radius
            color: "transparent"
            border.color: Theme.currentTheme.colors.focusBorderInner
        }
    }
}
