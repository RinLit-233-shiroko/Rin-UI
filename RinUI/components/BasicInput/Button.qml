import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import Qt5Compat.GraphicalEffects
import "../../themes"
import "../../components"

Button {
    id: root
    property color primaryColor: Theme.currentTheme.colors.primaryColor
    property color textColor: Theme.currentTheme.colors.textColor
    property alias color: root.backgroundColor
    property color backgroundColor: flat ? Theme.currentTheme.colors.subtleSecondaryColor :
        highlighted ? primaryColor : Theme.currentTheme.colors.controlColor
    // default property alias icon.source: icon.source
    property alias size: text.font.pixelSize
    property bool hoverable: true  // 是否可悬停
    property bool accessibliityIndicator: true  // 是否显示辅助提示
    property string suffixIconName: ""  // 后缀图标

    readonly property color hoverColor: !highlighted && !flat
        ? Theme.currentTheme.colors.controlSecondaryColor : backgroundColor
    icon.width: text.font.pixelSize * 1.3
    icon.height: text.font.pixelSize * 1.3

    // accessibility
    FocusIndicator {
        control: parent
        opacity: accessibliityIndicator
    }

    padding: 6
    topPadding: 5
    bottomPadding: 7

    background: Rectangle {
        id: background
        anchors.fill: parent
        color: hovered ? hoverColor : backgroundColor
        radius: Theme.currentTheme.appearance.buttonRadius

        border.width: Theme.currentTheme.appearance.borderWidth  // 边框宽度 / Border Width
        border.color: flat ? "transparent" :
            enabled ? highlighted ? primaryColor : Theme.currentTheme.colors.controlBorderColor :
            highlighted ? Theme.currentTheme.colors.disabledColor : Theme.currentTheme.colors.controlBorderColor

        // 裁切
        layer.enabled: true
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        // 底部border
        Rectangle {
            id: indicator
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            height: Theme.currentTheme.appearance.borderWidth

            color: flat ? "transparent" :
                enabled ? highlighted ? Theme.currentTheme.colors.controlAccentBottomBorderColor
                        : Theme.currentTheme.colors.controlBottomBorderColor
                    : "transparent"
        }

        Behavior on color { ColorAnimation { duration: Utils.appearanceSpeed; easing.type: Easing.OutQuart } }
        opacity: flat && !hovered || !hoverable ? 0 : 1
    }

    implicitWidth: Math.max(row.implicitWidth + 26, 40)
    implicitHeight: Math.max(text.height + 12, 32)

    contentItem: Item {
        clip: true
        anchors.fill: parent

        Row {
            id: row
            spacing: 8
            anchors.centerIn: parent
            IconWidget {
                id: iconWidget
                property bool isSetedIcon: icon || source.toString()
                // size: icon || source > 0 ? text.font.pixelSize * 1.3 : 0  // 图标大小 / Icon Size
                width: isSetedIcon ? root.icon.width : 0  // 图标大小 / Icon Size
                height: isSetedIcon ? root.icon.height : 0  // 图标大小 / Icon Size
                icon: root.icon.name
                source: root.icon.source
                y: 0.25
                color: {
                    if (icon.color) return icon.color
                    if (!enabled) {
                        return flat 
                            ? Theme.currentTheme.colors.disabledColor 
                            : (highlighted 
                                ? Theme.currentTheme.colors.textOnAccentColor 
                                : Theme.currentTheme.colors.textColor)
                    }
                    if (highlighted) {
                        return flat 
                            ? Theme.currentTheme.colors.textAccentColor 
                            : Theme.currentTheme.colors.textOnAccentColor
                    }
                    return Theme.currentTheme.colors.textColor
                }
            }
            Text {
                id: text
                typography: Typography.Body
                text: root.text
                color: highlighted ? flat ? Theme.currentTheme.colors.textAccentColor :
                    Theme.currentTheme.colors.textOnAccentColor : Theme.currentTheme.colors.textColor
            }
            // 后缀图标
            IconWidget {
                id: suffixIcon
                size: 12
                height: parent.height
                icon: root.suffixIconName
                color: Theme.currentTheme.colors.textSecondaryColor
                visible: root.suffixIconName !== ""
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
                opacity: 0.65
                backgroundColor: highlighted 
                    ? Theme.currentTheme.colors.disabledColor 
                    : Theme.currentTheme.colors.controlColor
            }
            PropertyChanges {
                target: text
                color: flat 
                    ? Theme.currentTheme.colors.disabledColor 
                    : (highlighted 
                        ? Theme.currentTheme.colors.textOnAccentColor
                        : Theme.currentTheme.colors.textColor)
            }
        },
        State {
            name: "pressed"
            when: pressed
            PropertyChanges {
                target: root;
                opacity: !highlighted && !flat ? 0.7 : 0.65
                backgroundColor:  !highlighted && !flat ? Theme.currentTheme.colors.controlTertiaryColor : backgroundColor
            }
        },
        State {
            name: "hovered"
            when: hovered && hoverable
            PropertyChanges {
                target: root;
                opacity: !highlighted && !flat ? 1 : 0.875
            }
        }
    ]
}
