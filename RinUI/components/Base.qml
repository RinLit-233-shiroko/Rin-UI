import QtQuick 2.15
import QtQuick.Controls 2.15
import "../themes"

Item {
    id: root
    implicitWidth: 100
    implicitHeight: 40

    // 公共属性 / Common Properties
    property color backgroundColor: Theme.currentTheme.colors.controlColor
    property color borderColor: Theme.currentTheme.colors.controlBorderColor
    property color textColor: Theme.currentTheme.colors.textColor

    property real borderTransparency: Theme.currentTheme.appearance.borderFactor
    property real controlRadius: Theme.currentTheme.appearance.buttonRadius

    property bool hovered: false  // 悬停
    property bool pressed: false  // 按下
    property bool enabled: true  // 是否启用

    // 启用 MouseArea / Enable MouseArea
    property bool interactive: true

    // Update
    // 禁用状态
    onEnabledChanged: updateStyle()

    // 主题切换 / Theme Switching
    Connections {
        target: Theme
        function onCurrentThemeChanged() {
            updateStyle()
        }
    }

    Component.onCompleted: updateStyle()

    function updateStyle() {
        backgroundColor = Theme.currentTheme.colors.controlColor
        borderColor = Theme.currentTheme.colors.controlBorderColor
        textColor = Theme.currentTheme.colors.textColor
        controlRadius = Theme.currentTheme.appearance.buttonRadius
        // borderTransparency = Theme.currentTheme.appearance.borderTransparency
    }

    // 颜色动画 / Color Animation
    Behavior on backgroundColor { ColorAnimation { duration: 200; easing.type: Easing.OutQuart } }
    Behavior on textColor { ColorAnimation { duration: 200; easing.type: Easing.OutQuart } }
    Behavior on borderColor { ColorAnimation { duration: 200; easing.type: Easing.OutQuart } }

    // 交互 / Interaction
    MouseArea {
        id: mouseArea
        visible: interactive
        anchors.fill: parent
        hoverEnabled: true

        // hover状态 / Hover State
        onEntered: root.hovered = true
        onExited: root.hovered = false

        // 按下状态 / Pressed State
        onPressed: root.pressed = true
        onReleased: root.pressed = false

        onClicked: {
            if (!root.enabled) {
                mouse.accepted = true  // 忽略鼠标点击事件
                return
            }
            root.clicked()
        }
    }



    signal clicked()
}
