import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"


Menu {
    id: root

    property int position: Position.Bottom  // 位置

    property real posX: {
        switch (position) {
            case Position.Top:
            case Position.Bottom:
                return (parent.width - root.width) / 2
            case Position.Left:
                return - root.width - 5
            case Position.Right:
                return parent.width + 5
            default:
                // return (parent.width - root.width) / 2
                return root.x
        }
    }

    property real posY: {
        switch (position) {
            case Position.Top:
                return -root.height - 5
            case Position.Bottom:
                return parent.height + 5
            case Position.Left:
            case Position.Right:
                return (parent.height - root.height) / 2
            default:
                return root.y
        }
    }

    width: Math.max(contentItem.implicitWidth, 80)

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                from: 0
                to: 1
                duration: Utils.animationSpeed
                easing.type: Easing.InOutQuart
            }
            NumberAnimation {
                target: root
                property: "height"
                from: (position === Position.Top || position === Position.Bottom ? 0 : root.implicitHeight)
                to: root.implicitHeight
                duration: Utils.animationSpeed
                easing.type: Easing.OutQuart
            }
            NumberAnimation {
                target: root
                property: "x"
                from: posX + (position === Position.Left ? 5 : position === Position.Right ? -5 : 0)
                to: posX
                duration: Utils.animationSpeedMiddle
                easing.type: Easing.OutQuint
                onRunningChanged: {
                    scrollBar.visible = true;
                }
            }
            NumberAnimation {
                target: root
                property: "y"
                from: posY + (position === Position.Top || position === Position.Bottom
                    ? (position === Position.Top ? implicitHeight / 2 : position === Position.Bottom ? -implicitHeight / 2 : implicitHeight / 2)
                    : 0)
                to: posY
                duration: Utils.animationSpeedMiddle
                easing.type: Easing.OutQuint
                onRunningChanged: {
                    scrollBar.visible = true;
                }
            }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                from: 1
                to: 0
                duration: 150
                easing.type: Easing.InOutQuart
            }
        }
    }

    topPadding: 5
    bottomPadding: 5

    background: Rectangle {
        anchors.fill: parent
        radius: Theme.currentTheme.appearance.windowRadius
        color: Theme.currentTheme.colors.backgroundAcrylicColor
        border.color: Theme.currentTheme.colors.flyoutBorderColor

        layer.enabled: true
        layer.effect: Shadow {
            id: shadow
            style: "flyout"
            source: background
        }
    }

    delegate: MenuItem { }

    contentItem: Flickable {
        id: flickable
        clip: true
        anchors.centerIn: parent
        implicitWidth: column.implicitWidth
        implicitHeight: column.implicitHeight

        ColumnLayout {
            id: column
            x: -5
            spacing: 0
            Repeater {
                model: root.contentModel
            }
        }

        ScrollBar.vertical: ScrollBar {
            id: scrollBar
            policy: ScrollBar.AsNeeded
            visible: false  // 初始隐藏，在 enter 动画中显现
        }
    }
}
