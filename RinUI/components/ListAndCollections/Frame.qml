import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import "../../themes"
import "../../components"


Frame {
    id: root
    property bool frameless: false
    property bool hoverable: true  // 悬浮特效
    property bool hover: false
    property color color: Theme.currentTheme.colors.cardColor
    property alias radius: background.radius
    property color borderColor: Theme.currentTheme.colors.cardBorderColor
    property int borderWidth: Theme.currentTheme.appearance.borderWidth

    clip: true
    // leftPadding: 0
    // rightPadding: 0
    // topPadding: 0
    // bottomPadding: 0

    background: Rectangle {
        id: background
        anchors.fill: parent
        radius: Theme.currentTheme.appearance.smallRadius
        color: root.color
        border.width: borderWidth
        border.color: borderColor
        opacity: root.hover? 0.7 : 1
        visible: !root.frameless

        // mouse area / hover区域
        MouseArea {
            anchors.fill: parent
            hoverEnabled: root.hoverable
            onEntered: root.hover = true
            onExited: root.hover = false
        }

        Behavior on opacity { NumberAnimation { duration: Utils.animationSpeedFaster; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: Utils.appearanceSpeed; easing.type: Easing.OutQuad } }
    }
}
