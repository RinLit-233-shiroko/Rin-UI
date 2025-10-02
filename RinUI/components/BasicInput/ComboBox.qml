import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import Qt5Compat.GraphicalEffects
import "../../themes"
import "../../components"


ComboBox {
    id: root

    // 属性 / Properties
    property real controlRadius: Theme.currentTheme.appearance.buttonRadius
    property string placeholderText: ""
    property alias maxHeight: menu.maxHeight
    property string headerText: ""

    implicitWidth: Math.max(contentItem.implicitWidth + 50, 60)
    // implicitHeight: contentItem.implicitHeight + 12

    padding: 0

    // accessibility
    FocusIndicator {
        Indicator {
            id: focusIndicator
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
        }
        anchors.margins: -1
        control: parent
    }


    // 背景 / Background //
    background: Rectangle {
        id: background
        anchors.fill: parent
        color: Theme.currentTheme.colors.controlColor
        radius: Theme.currentTheme.appearance.buttonRadius

        border.width: Theme.currentTheme.appearance.borderWidth  // 边框宽度 / Border Width
        border.color: Theme.currentTheme.colors.controlBorderColor

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

            color: Theme.currentTheme.colors.controlBottomBorderColor
        }

        Behavior on color { ColorAnimation { duration: Utils.appearanceSpeed; easing.type: Easing.OutQuart } }
        opacity: flat && !hovered ? 0 : 1
    }

    // 指示器 / Indicator //
    indicator: ToolButton {
        id: dropIndicator
        flat: true
        width: 32
        height: 24
        focusPolicy: editable ? Qt.StrongFocus : Qt.NoFocus
        anchors.right: parent.right
        anchors.margins: 4
        anchors.verticalCenter: parent.verticalCenter
        icon.name: "ic_fluent_chevron_down_20_regular"
        size: 14
        color: Theme.currentTheme.colors.textSecondaryColor
        hoverable: editable

        onClicked: menu.open()
    }

    // 清空按钮（仅可编辑时显示，位于下拉图标左侧）
    ToolButton {
        id: clearButton
        flat: true
        width: 24
        height: 24
        focusPolicy: root.editable ? Qt.StrongFocus : Qt.NoFocus
        anchors.right: dropIndicator.left
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        icon.name: "ic_fluent_dismiss_20_regular"
        size: 14
        color: Theme.currentTheme.colors.textSecondaryColor
        hoverable: root.editable
        visible: root.editable && root.displayText.length > 0

        onClicked: {
            root.editText = ""
            root.currentIndex = -1
        }
    }


    contentItem: TextField {
        id: text
        anchors.fill: parent
        text: root.displayText
        editable: root.editable
        frameless: true
        placeholderText: root.placeholderText
        showClearButton: false
    }

    // 弹出菜单 / Menu //
    popup: ContextMenu {
        id: menu
        width: root.width
        model: root.model
        currentIndex: root.currentIndex

        function handleItemSelected(index) {
            root.currentIndex = index
            return true
        }
        onItemSelected: (index) => handleItemSelected(index)
    }

    // 动画
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
    Behavior on implicitWidth { NumberAnimation { duration: 100; easing.type: Easing.InOutQuart } }


    // 状态变化
    states: [
        State {
        name: "disabled"
            when: !enabled
            PropertyChanges {  // 禁用时禁止改变属性
                target: root;
                opacity: 0.4
            }
        },
        State {
            name: "pressed"
            when: pressed
            PropertyChanges {
                target: root;
                opacity: 0.7
            }
            PropertyChanges {
                target: background;
                color: Theme.currentTheme.colors.controlTertiaryColor
            }
        },
        State {
            name: "hovered"
            when: hovered
            PropertyChanges {
                target: background;
                opacity: 1
                color: Theme.currentTheme.colors.controlSecondaryColor
            }
        }
    ]
}