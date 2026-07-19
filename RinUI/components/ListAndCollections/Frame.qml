import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import "../../themes"
import "../../components"


Frame {
    id: root
    property bool frameless: false
    property bool hoverable: true  // 悬浮特效
    // hovered: false
    property color color: root.hovered && root.enabled ? Theme.currentTheme.colors.controlSecondaryColor: Theme.currentTheme.colors.cardColor
    property alias radius: background.radius
    // Qt 6.7+ 分角圆角，避免整控件 layer+OpacityMask 导致 HiDPI 文字模糊
    property real topLeftRadius: -1
    property real topRightRadius: -1
    property real bottomLeftRadius: -1
    property real bottomRightRadius: -1
    property alias border: background.border

    clip: true
    hoverEnabled: hoverable
    // leftPadding: 0
    // rightPadding: 0
    // topPadding: 0
    // bottomPadding: 0

    background: Rectangle {
        id: background
        anchors.fill: parent
        radius: Theme.currentTheme.appearance.smallRadius
        // -1 表示跟随统一 radius；显式 0/正数用于分角圆角（HiDPI 友好，无需 OpacityMask）
        topLeftRadius: root.topLeftRadius < 0 ? radius : root.topLeftRadius
        topRightRadius: root.topRightRadius < 0 ? radius : root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius < 0 ? radius : root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius < 0 ? radius : root.bottomRightRadius
        color: root.color
        border.width: Theme.currentTheme.appearance.borderWidth
        border.color: Theme.currentTheme.colors.cardBorderColor
        // opacity: root.hover? 0.7 : 1
        visible: !root.frameless

        // mouse area / hover区域
        // MouseArea {
        //     anchors.fill: parent
        //     hoverEnabled: root.hoverable
        //     onEntered: root.hovered = true
        //     onExited: root.hovered = false
        // }

        Behavior on opacity { NumberAnimation { duration: Utils.animationSpeedFaster; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: Utils.appearanceSpeed; easing.type: Easing.OutQuad } }
    }
}
