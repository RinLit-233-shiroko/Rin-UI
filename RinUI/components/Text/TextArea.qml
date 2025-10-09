import QtQuick 2.15
import Qt5Compat.GraphicalEffects
import QtQuick.Controls.Basic 2.15
import "../../themes"
import "../../components"

TextArea {
    id: root

    property bool frameless: false
    property bool editable: true
    property color primaryColor: Theme.currentTheme.colors.primaryColor

    selectByMouse: true
    enabled: editable

    // Menu
    TextInputMenu {
        id: contextMenu
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        propagateComposedEvents: false
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton)
                contextMenu.popup(mouse.scenePosition)
            mouse.accepted = true
        }

        // 鼠标
        cursorShape: Qt.IBeamCursor
    }

    // 背景 / Background //
    background: Rectangle {
        id: background
        anchors.fill: parent
        radius: Theme.currentTheme.appearance.buttonRadius
        color: frameless ? "transparent" : Theme.currentTheme.colors.controlColor
        clip: true
        border.width: Theme.currentTheme.appearance.borderWidth
        border.color: frameless ? root.activeFocus ? Theme.currentTheme.colors.controlBorderColor : "transparent" :
            Theme.currentTheme.colors.controlBorderColor

        layer.enabled: true
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        // 底部指示器 / indicator //
        Rectangle {
            id: indicator
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            radius: 999
            height: root.activeFocus ? Theme.currentTheme.appearance.borderWidth * 2 : Theme.currentTheme.appearance.borderWidth
            color: root.activeFocus ? primaryColor : frameless ? "transparent" : Theme.currentTheme.colors.textControlBorderColor

            Behavior on color { ColorAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }
            Behavior on height { NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }
        }
    }

    Behavior on opacity { NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }


    // 字体 / Font //
    font.pixelSize: Theme.currentTheme.typography.bodySize

    wrapMode: Text.WordWrap  // 自动换行
    selectionColor: Theme.currentTheme.colors.primaryColor
    color: Theme.currentTheme.colors.textColor
    placeholderTextColor: Theme.currentTheme.colors.textSecondaryColor

    leftPadding: 12
    rightPadding: 12
    topPadding: 5
    bottomPadding: 7

    // 动画 / Animation //
    Behavior on implicitHeight { NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }

    // 状态
    states: [
        State {
        name: "disabled"
            when: !enabled
            PropertyChanges {  // 禁用时禁止改变属性
                target: root;
                opacity: !editable ? 1 : 0.4
            }
        },
        State {
            name: "pressed&focused"
            when: activeFocus
            PropertyChanges {
                target: background;
                color: Theme.currentTheme.colors.controlInputActiveColor
            }
        },
        State {
            name: "hovered"
            when: hovered
            PropertyChanges {
                target: background;
                color: Theme.currentTheme.colors.controlSecondaryColor
            }
        }
    ]
}