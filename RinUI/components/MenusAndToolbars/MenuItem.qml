import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"


MenuItem {
    id: root

    Layout.fillWidth: true

    implicitWidth: {
        const leftMargin = 16;
        const arrowWidth = arrow.visible ? arrow.width + 16 : root.checked ? indicator.width + 16 : 0;
        const rightMargin = 16;
        return leftMargin + contentItem.implicitWidth + arrowWidth + rightMargin;
    }
    implicitHeight: Math.max(implicitContentHeight + topPadding + bottomPadding,
                             34)

    property MenuItemGroup group  // 组

    checkable: group
    checked: group ? group.checkedButton === root : false

    onGroupChanged: {
        if (group)
            group.register(root)
    }

    Component.onDestruction: {
        if (group)
            group.unregister(root)
    }

    onTriggered: {
        if (group)
            group.updateCheck(root)
    }

    property var parentMenu: undefined

    // accessibility
    FocusIndicator {
        control: parent
        anchors.margins: 5
        anchors.topMargin: 0
        anchors.bottomMargin: 0
    }

    arrow: IconWidget {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.margins: 16
        color: Theme.currentTheme.colors.textSecondaryColor
        visible: root.subMenu
        icon: "ic_fluent_chevron_right_20_regular"
        size: 12
    }

    indicator: IconWidget {
        id: indicator
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.margins: 18
        icon: group ? group.exclusive ? "ic_fluent_circle_20_filled" : "ic_fluent_checkmark_20_filled"
            : "ic_fluent_checkmark_20_filled"
        width: 16
        size: group ? group.exclusive ? 7 : 16 : 16
        visible: root.checked
    }

    // 内容 / Content //
    contentItem: RowLayout {
        id: row
        spacing: 16
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: (iconWidget.size ? 16 : 0) + (checkable ? indicator.width + 16 : 0)
        anchors.margins: 16

        IconWidget {
            id: iconWidget
            size: icon || source ? menuText.font.pixelSize * 1.25 : 0  // 图标大小 / Icon Size
            icon: root.icon.name
            source: root.icon.source
        }
        Text {
            id: menuText
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            typography: Typography.Body
            text: root.text
            wrapMode: Text.NoWrap
        }
        Text {
            id: shortcutText
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            typography: Typography.Caption
            text: root.action ? root.action.shortcut : ""
            color: Theme.currentTheme.colors.textSecondaryColor
            visible: text
        }
    }

    // 背景 / Background //
    background: Rectangle {
        anchors.fill: parent
        anchors.margins: 5
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        radius: Theme.currentTheme.appearance.buttonRadius
        color: enabled ? pressed ? Theme.currentTheme.colors.subtleTertiaryColor
            : hovered
            ? Theme.currentTheme.colors.subtleSecondaryColor
            : "transparent" : "transparent"

        Behavior on color { ColorAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuart } }
    }

    // States //
    // 状态变化
    states: [
        State {
        name: "disabled"
            when: !enabled
            PropertyChanges {
                target: root
                opacity: 0.3628
            }
        }
    ]
}
