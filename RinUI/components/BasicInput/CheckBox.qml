import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import "../../themes"
import "../../components"


CheckBox {
    id: root
    property color backgroundColor: Theme.currentTheme.colors.controlSecondaryColor
    property color primaryColor: Theme.currentTheme.colors.primaryColor

    spacing: 8

    // accessibility
    FocusIndicator {
        control: parent
    }

    contentItem: Text {
        leftPadding: root.indicator.width + root.spacing
        verticalAlignment: Text.AlignVCenter

        text: root.text
    }

    // 指示器 / indicator //
    indicator: Rectangle {
        id: background
        width: 20
        height: 20
        x: root.leftPadding
        y: parent.height / 2 - height / 2
        radius: Theme.currentTheme.appearance.buttonRadius
        color: checkState !== Qt.Unchecked ? primaryColor :
            hovered ? Theme.currentTheme.colors.controlTertiaryColor : backgroundColor
        // 边框 / Border
        border.color: checkState !== Qt.Unchecked ? "transparent" : Theme.currentTheme.colors.controlBorderStrongColor
        border.width: Theme.currentTheme.appearance.borderWidth

        Behavior on color { ColorAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: Utils.appearanceSpeed; easing.type: Easing.OutQuart } }

        // 指示器 / Indicator //
        Rectangle {
            id: mask
            anchors.verticalCenter: background.verticalCenter
            anchors.left: background.left
            anchors.leftMargin: 4
            width: checkState !== Qt.Unchecked ? 12 : 0
            height: 12
            clip: true
            color: "transparent"

            Behavior on width { NumberAnimation { duration: Utils.animationSpeedMiddle; easing.type: Easing.OutQuint } }

            IconWidget {
                id: indicator
                icon: checkState !== Qt.PartiallyChecked
                    ? "ic_fluent_checkmark_20_filled" :
                    "ic_fluent_subtract_20_regular"
                size: 12
                color: Theme.currentTheme.colors.textOnAccentColor

                Behavior on color { ColorAnimation { duration: Utils.appearanceSpeed; easing.type: Easing.OutQuart } }
            }
        }
    }

    Behavior on opacity { NumberAnimation { duration: Utils.appearanceSpeed; easing.type: Easing.OutQuart } }

    // 状态变化
    states: [
        State {
        name: "disabled"
            when: !enabled
            PropertyChanges {
                target: root
                opacity: 0.4
                primaryColor: Theme.currentTheme.colors.disabledColor
            }
        },
        State {
            name: "pressed"
            when: pressed
            PropertyChanges {
                target: background;
                opacity: 0.65
            }
        },
        State {
            name: "hovered"
            when: hovered
            PropertyChanges {
                target: background;
                opacity: 0.875
            }
        }
    ]
}
