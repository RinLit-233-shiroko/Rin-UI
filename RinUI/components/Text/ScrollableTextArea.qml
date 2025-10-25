import QtQuick 2.15
import Qt5Compat.GraphicalEffects
import QtQuick.Controls.Basic 2.15
import "../../themes"
import "../../components"

ScrollView {
    id: view

    // 接口属性
    property alias text: textArea.text
    property alias placeholderText: textArea.placeholderText
    // removed to avoid overriding final Control.font property
    // property alias font: textArea.font
    property alias color: textArea.color
    property alias selectionColor: textArea.selectionColor
    property alias wrapMode: textArea.wrapMode
    property alias readOnly: textArea.readOnly

    property bool frameless: false
    property bool editable: true
    property bool richText: false
    property color primaryColor: Theme.currentTheme.colors.primaryColor
    // 未指定高度时，初始高度近似为单行输入框高度；超过 maxHeight 后启用滚动
    property int initialHeight: 32
    property int maxHeight: 300

    clip: true

    Behavior on opacity { NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }

    // 自动高度：在未指定高度时，按内容增长到 maxHeight
    implicitHeight: Math.min(Math.max(initialHeight, textArea.contentHeight + textArea.topPadding + textArea.bottomPadding), maxHeight)
    Behavior on implicitHeight { NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }

    // 背景 / Background //
    background: Rectangle {
        id: background
        radius: Theme.currentTheme.appearance.buttonRadius
        color: frameless ? "transparent" : Theme.currentTheme.colors.controlColor
        clip: true
        border.width: Theme.currentTheme.appearance.borderWidth
        border.color: frameless ? view.activeFocus ? Theme.currentTheme.colors.controlBorderColor : "transparent" :
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
            height: textArea.activeFocus ? Theme.currentTheme.appearance.borderWidth * 2 : Theme.currentTheme.appearance.borderWidth
            color: textArea.activeFocus ? primaryColor : frameless ? "transparent" : Theme.currentTheme.colors.textControlBorderColor

            Behavior on color { ColorAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }
            Behavior on height { NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }
        }
    }

    // 编辑区域
    TextArea {
        id: textArea
        // 作为 ScrollView 的内容，宽度跟随视图；高度由内容决定
        width: view.width

        // 兼容 TextInputMenu 的启用条件：同项目其他输入组件保持一致
        property bool editable: view.editable && !readOnly

        selectByMouse: true
        enabled: view.editable

        // 富文本支持：使用 TextArea 的 textFormat 直接切换
        textFormat: view.richText ? TextEdit.RichText : TextEdit.PlainText

        // 富文本链接点击处理
        onLinkActivated: (link) => { Qt.openUrlExternally(link) }

        // 字体 / Font //
        font.pixelSize: view.font.pixelSize > 0 ? view.font.pixelSize : Theme.currentTheme.typography.bodySize
        wrapMode: Text.WordWrap  // 自动换行
        selectionColor: Theme.currentTheme.colors.primaryColor
        color: Theme.currentTheme.colors.textColor
        placeholderTextColor: Theme.currentTheme.colors.textSecondaryColor

        leftPadding: 12
        rightPadding: 12
        topPadding: 5
        bottomPadding: 7

        // 关闭自身背景，由外层提供统一样式
        background: Item {}

        // 右键菜单 / Context Menu
        TextInputMenu { id: contextMenu }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.RightButton
            propagateComposedEvents: true
            onPressed: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    contextMenu.popup(mouse.scenePosition)
                    mouse.accepted = true
                } else {
                    mouse.accepted = false  // 让左键点击事件传播给TextArea处理
                }
            }
            cursorShape: Qt.IBeamCursor
        }

        // 将光标可见性交由 ScrollView/Controls 处理，无需手动滚动
    }

    // 状态
    states: [
        State {
            name: "disabled"
            when: !view.editable
            PropertyChanges { target: view; opacity: 0.4 }
        },
        State {
            name: "pressed&focused"
            when: textArea.activeFocus
            PropertyChanges { target: background; color: Theme.currentTheme.colors.controlInputActiveColor }
        },
        State {
            name: "hovered"
            when: textArea.hovered
            PropertyChanges { target: background; color: Theme.currentTheme.colors.controlSecondaryColor }
        }
    ]
}