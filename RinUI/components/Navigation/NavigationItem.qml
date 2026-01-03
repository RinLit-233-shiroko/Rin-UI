import QtQuick 2.15
import QtQuick.Controls 2.15
import "../../themes"
import "../../components"

Item {
    id: navigationItems
    property var itemData
    readonly property bool subItem: itemData.subItems ? true : false  // clean console warning
    property var currentPage
    property bool highlighted: String(navigationBar.currentPage) === String(itemData.page) || (collapsed && subItemHighlighted)

    property bool subItemHighlighted: {
        if (!subItem) return false;
        for (let i = 0; i < itemData.subItems.length; i++) {
            if (String(itemData.subItems[i].page) === String(navigationBar.currentPage)) {
                return true;
            }
        }
        return false;
    }
    property bool collapsed: true  // 是否折叠

    // 子菜单重置
    Connections {
        target: navigationBar
        function onCollapsedChanged() {
            if (!navigationBar.collapsed) {
                return
            }
            // 当导航栏折叠时，子菜单也应折叠
            collapsed = true
        }
    }

    height: 40 + (!collapsed && subItem ? subItemsColumn.height : 0)
    width: parent ? parent.width : 200

    Button {
        id: itemBtn
        // anchors.fill: parent
        width: parent.width
        height: 37
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        clip: true
        flat: true
        accessibliityIndicator: false
        background.opacity: navigationItems.highlighted ? 1 : hovered ? 1 : 0

        // accessibility
        FocusIndicator {
            control: parent
            anchors.margins: 2
        }

        Row {
            id: left
            spacing: 16
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 11
            anchors.topMargin: 6
            anchors.bottomMargin: 8

            IconWidget {
                id: icon
                anchors.verticalCenter: parent.verticalCenter
                size: itemData.icon || itemData.source ? 19 : 0
                icon: itemData.icon || ""
                source: itemData.source || ""
            }

            Text {
                id: text
                anchors.verticalCenter: parent.verticalCenter
                typography: Typography.Body
                text: itemData.title
                clip: true
                opacity: navigationBar.collapsed ? 0 : 1
                wrapMode: Text.NoWrap
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                width: itemBtn.width - parent.anchors.leftMargin - x - (expandBtn.visible ? expandBtn.width : 0) - 10

                Behavior on x {
                    NumberAnimation {
                        duration: Utils.appearanceSpeed
                        easing.type: Easing.InOutQuint
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Utils.appearanceSpeed
                    }
                }
            }
        }

        // 提示
        ToolTip {
            visible: navigationBar.collapsed && itemBtn.hovered
            delay: 500
            text: itemData.title
        }

        Indicator {
            id: indicator
            x: left.x - 11
            y: (itemBtn.height + 3) / 2 - indicator.height / 2 - 2
            currentItemHeight: itemBtn.height + 3
            visible: highlighted ? 1 : 0
            width: 3
        }

        // 展开按钮
        ToolButton {
            id: expandBtn
            focusPolicy: Qt.NoFocus
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height
            height: parent.height
            hoverable: false
            size: 14
            icon.name: "ic_fluent_chevron_down_20_filled"
            accessibliityIndicator: false

            FocusIndicator {
                control: parent
                anchors.margins: 2
            }

            transform: Rotation {
                angle: collapsed ? 0 : 180 ; origin.x: 37/2; origin.y: 37/2
                Behavior on angle { NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }
            }

            visible: subItem && !navigationBar.collapsed
            opacity: 0.7

            onClicked: { 
                collapsed = !collapsed
                // Notify NavigationBar to recalculate width
                if (navigationBar && typeof navigationBar.requestLayoutUpdate === "function") {
                    Qt.callLater(navigationBar.requestLayoutUpdate)
                }
            }
        }

        onClicked: {
            if (subItem) {
                if (!navigationBar.collapsed) {
                    collapsed = !collapsed
                    if (navigationBar && typeof navigationBar.requestLayoutUpdate === "function") {
                        Qt.callLater(navigationBar.requestLayoutUpdate)
                    }
                } else {
                    subMenu.open()
                }
            }
            if (itemData.page && currentPage && String(navigationBar.currentPage) !== String(itemData.page)) {
                // 记录上一次的索引
                navigationView.safePush(itemData.page, false, false)
            }
        }
    }

    // 动画 / Animation //
    Behavior on height { NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }

    // 折叠菜单
    Menu {
        id: subMenu
        position: Position.Right
        Repeater {
            id: subMenuRepeater
            model: itemData.subItems
            delegate: MenuItem {
                text: modelData.title
                onClicked: {
                    if (modelData.page && navigationItems.currentPage) {
                        navigationView.safePush(modelData.page)
                    }
                }
            }
        }
    }

    // 递归处理子项
    Column {
        id: subItemsColumn
        opacity: !collapsed && subItem
        spacing: 2
        anchors.top: itemBtn.bottom
        width: parent.width
        anchors.topMargin: 1
        anchors.leftMargin: 16
        Behavior on opacity { NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }

        Repeater {
            id: subItemsRepeater
            model: itemData.subItems
            delegate: NavigationSubItem {
                id: subItems
                itemData: modelData
                currentPage: navigationItems.currentPage
            }
        }

        Item {
            width: parent.width
            height: 1
        }
    }
}
