import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import "../../themes"
import "../../components"


Switch {
    id: root

    // width: 40
    implicitHeight: 20

    property color backgroundColor: Theme.currentTheme.colors.controlSecondaryColor
    property color primaryColor: Theme.currentTheme.colors.primaryColor
    property string checkedText: qsTr("On")
    property string uncheckedText: qsTr("Off")

    // accessibility
    FocusIndicator {
        control: parent
        // radius: 999
    }

    // 背景 / Background
    background: Rectangle {
        id: background
        width: 40
        height: 20
        radius: height / 2
        color: checked ? primaryColor :
            hovered ? Theme.currentTheme.colors.controlTertiaryColor : backgroundColor

        // 边框 / Border
        border.color: checked ? "transparent" : Theme.currentTheme.colors.controlBorderStrongColor
        border.width: Theme.currentTheme.appearance.borderWidth

        Behavior on color { ColorAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuart } }
    }

    // 指示器 / Indicator //
    indicator: Rectangle {
        id: indicator
        width: pressed && enabled ? background.height - 3:
            hovered  && enabled ? background.height - 3 * 2 : background.height - 4 * 2
        height: (hovered || pressed) && enabled ? background.height - 3 * 2 : background.height - 4 * 2

        anchors.verticalCenter: background.verticalCenter
        radius: height / 2
        color: checked ? Theme.currentTheme.colors.textOnAccentColor : Theme.currentTheme.colors.controlBorderStrongColor

        Behavior on color { ColorAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuart } }

        Behavior on x { NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }
        Behavior on height { NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }

        x: (hovered || pressed) && enabled
            ? visualPosition * (background.width - 3 - width) + (checked ? 0 : 3)
            : visualPosition * (background.width - 8 - width) + 4
    }

    contentItem: Row {
        anchors.fill: parent
        spacing: 12
        Rectangle { width: 40; height: 20; color: "transparent" }  // 占位符

        Text {
            text: (root.text === '') ? root.checked ? checkedText : uncheckedText : root.text
        }
    }

    // 状态变化
    states: [
        State {
            name: "disabledSwitch"
            when: !root.enabled
            PropertyChanges {
                target: root
                opacity: 0.2169
                primaryColor: Theme.currentTheme.colors.disabledColor
            }
        },
        State {
            name: "pressedSwitch"
            when: pressed
            PropertyChanges {
                target: background
                opacity: 0.8
            }
        },
        State {
            name: "hoveredSwitch"
            when: hovered
            PropertyChanges {
                target: background
                opacity: 0.9
            }
        }
    ]

    // 动画
    Behavior on opacity { NumberAnimation { duration: Utils.appearanceSpeed; easing.type: Easing.OutQuart } }
}
