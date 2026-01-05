import QtQuick 2.15
import QtQuick.Controls 2.15
import "../../components"
import "../../themes"


Item {
    id: navigationBar
    // implicitWidth: collapsed ? 40 : expandWidth
    height: parent.height

    property bool collapsed: false
    property var navigationItems: [
        // {title: "Title", page: "path/to/page.qml", icon: undefined}
    ]

    // property int currentSubIndex: -1
    property bool titleBarEnabled: true
    property int expandWidth: 280
    property int minimumExpandWidth: 900

    property alias windowTitle: titleLabel.text
    property alias windowIcon: iconLabel.source
    property int windowWidth: minimumExpandWidth
    property var stackView: parent.stackView

    property string currentPage: ""  // 当前页面的URL
    property bool collapsedByAutoResize: false

    function isNotOverMinimumWidth() {  // 判断窗口是否小于最小宽度
        return windowWidth < minimumExpandWidth;
    }

    // 展开收缩动画 //
    width: collapsed ? 40 : expandWidth
    implicitWidth: isNotOverMinimumWidth() ? 40 : collapsed ? 40 : expandWidth

    Behavior on width {
        NumberAnimation {
            duration: Utils.animationSpeed
            easing.type: Easing.OutQuint
        }
    }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: Utils.animationSpeed
            easing.type: Easing.OutQuint
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.margins: -5
        anchors.topMargin: 0
        radius: Theme.currentTheme.appearance.windowRadius
        color: Theme.currentTheme.colors.backgroundAcrylicColor
        border.color: Theme.currentTheme.colors.flyoutBorderColor
        z: -1
        visible: isNotOverMinimumWidth() && !collapsed

        Behavior on visible {
            NumberAnimation {
                duration: collapsed ? Utils.animationSpeed / 2 : 50
            }
        }

        layer.enabled: true
        layer.effect: Shadow {
            style: "flyout"
            source: background
        }
    }

    Row {
        id: title
        anchors.left: parent.left
        anchors.bottom: parent.top
        height: titleBarHeight
        spacing: 16
        visible: navigationBar.titleBarEnabled

        // 返回按钮
        ToolButton {
            flat: true
            anchors.verticalCenter: parent.verticalCenter
            icon.name: "ic_fluent_arrow_left_20_regular"
            onClicked: navigationView.safePop()
            width: 40
            height: 40
            size: 16
            enabled: navigationView.lastPages.length > 0

            ToolTip {
                parent: parent
                delay: 500
                visible: parent.hovered
                text: qsTr("Back")
            }
        }

        //图标
        IconWidget {
            id: iconLabel
            size: 16
            anchors.verticalCenter: parent.verticalCenter
        }

        //标题
        Text {
            id: titleLabel
            anchors.verticalCenter:  parent.verticalCenter

            typography: Typography.Caption
            // text: title
        }
    }

    // 收起切换按钮
    ToolButton {
        id: collapseButton
        flat: true
        width: 40
        height: 38
        // icon.name: collapsed ? "ic_fluent_chevron_right_20_regular" : "ic_fluent_chevron_left_20_regular"
        icon.name: "ic_fluent_navigation_20_regular"
        size: 19
        y: 5

        onClicked: {
            collapsed = !collapsed
            collapsedByAutoResize = false
        }

        ToolTip {
            parent: parent
            delay: 500
            visible: parent.hovered && !parent.pressed
            text: collapsed ? qsTr("Open Navigation") : qsTr("Close Navigation")
      }
    }

    // 数据过滤逻辑
    function getTopItems() {
        return navigationItems.filter(function(item) {
            return item.position === "top";
        });
    }
    
    function getMiddleItems() {
        return navigationItems.filter(function(item) {
            return !item.position || item.position === "normal" || item.position === "";
        });
    }
    
    function getBottomItems() {
        return navigationItems.filter(function(item) {
            return item.position === "bottom";
        });
    }


    // 置顶导航项（固定在顶部，支持滚动）
    Flickable {
        id: topFlickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 40 + collapseButton.y
        // 置顶区域最大高度：导航栏可用高度的 20%
        height: getTopItems().length > 0 ? Math.min(topNavigationColumn.implicitHeight, (parent.height - 40) * 0.2) : 0
        contentWidth: parent.width
        contentHeight: topNavigationColumn.implicitHeight
        clip: true
        visible: getTopItems().length > 0

        Column {
            id: topNavigationColumn
            width: topFlickable.width
            spacing: 4

            Repeater {
                model: navigationBar.getTopItems()
                delegate: NavigationItem {
                    id: topItem
                    itemData: modelData
                    currentPage: navigationBar.stackView

                    // 子菜单重置
                    Connections {
                        target: navigationBar
                        function onCollapsedChanged() {
                            if (!navigationBar.collapsed) {
                                return
                            }
                            topItem.collapsed = navigationBar.collapsed
                        }
                    }
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }

    // Top Separator
    Rectangle {
        id: topSeparator
        anchors.top: topFlickable.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        z: 10
        color: Theme.currentTheme.colors.dividerBorderColor
        visible: navigationBar.getTopItems().length > 0
    }

    // 中间可滚动导航区域
    Flickable {
        id: flickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topSeparator.visible ? topSeparator.bottom : topFlickable.bottom
        anchors.topMargin: topSeparator.visible ? 4 : 0
        anchors.bottom: bottomSeparator.visible ? bottomSeparator.top : bottomFlickable.top
        anchors.bottomMargin: bottomSeparator.visible ? 4 : 0
        contentWidth: parent.width
        contentHeight: navigationColumn.implicitHeight
        clip: true

        Column {
            id: navigationColumn
            width: flickable.width
            spacing: 4

            Repeater {
                model: navigationBar.getMiddleItems()
                delegate: NavigationItem {
                    id: item
                    itemData: modelData
                    currentPage: navigationBar.stackView

                    // 子菜单重置
                    Connections {
                        target: navigationBar
                        function onCollapsedChanged() {
                            if (!navigationBar.collapsed) {
                                return
                            }
                            item.collapsed = navigationBar.collapsed
                        }
                    }
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }

    // Bottom Separator
    Rectangle {
        id: bottomSeparator
        anchors.bottom: bottomFlickable.top
        anchors.bottomMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        z: 10
        color: Theme.currentTheme.colors.dividerBorderColor
        visible: navigationBar.getBottomItems().length > 0
    }

    // 底部导航项（固定在底部，支持滚动）
    Flickable {
        id: bottomFlickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        // 底部区域最大高度：导航栏可用高度的 20%
        height: getBottomItems().length > 0 ? Math.min(bottomNavigationColumn.implicitHeight, (parent.height - 40) * 0.2) : 0
        contentWidth: parent.width
        contentHeight: bottomNavigationColumn.implicitHeight
        clip: true
        visible: getBottomItems().length > 0

        // 默认滚动到底部
        Component.onCompleted: {
            if (contentHeight > height) {
                contentY = contentHeight - height;
            }
        }

        // 内容高度变化时保持在底部
        onContentHeightChanged: {
            if (contentHeight > height) {
                contentY = contentHeight - height;
            }
        }

        Column {
            id: bottomNavigationColumn
            width: bottomFlickable.width
            spacing: 4

            Repeater {
                model: navigationBar.getBottomItems()
                delegate: NavigationItem {
                    id: bottomItem
                    itemData: modelData
                    currentPage: navigationBar.stackView

                    // 子菜单重置
                    Connections {
                        target: navigationBar
                        function onCollapsedChanged() {
                            if (!navigationBar.collapsed) {
                                return
                            }
                            bottomItem.collapsed = navigationBar.collapsed
                        }
                    }
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }
}
