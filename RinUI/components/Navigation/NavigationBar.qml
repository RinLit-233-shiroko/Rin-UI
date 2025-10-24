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

    function isNotOverMinimumWidth() {  // 判断窗口是否小于最小宽度
        return windowWidth < minimumExpandWidth;
    }

    // 展开收缩动画 //
    width: collapsed ? 40 : expandWidth
    implicitWidth: isNotOverMinimumWidth() ? 40 : collapsed ? 40 : expandWidth

    Behavior on width {
        NumberAnimation {
            duration: Utils.animationSpeedFast
            easing.type: Easing.OutQuint
        }
    }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: Utils.animationSpeedFast
            easing.type: Easing.OutQuint
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.margins: -5
        anchors.topMargin: -title.height
        radius: Theme.currentTheme.appearance.windowRadius
        color: Theme.currentTheme.colors.backgroundAcrylicColor
        border.color: Theme.currentTheme.colors.flyoutBorderColor
        z: -1
        visible: isNotOverMinimumWidth() && !collapsed ? 1 : 0

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

        onClicked: {
            collapsed = !collapsed
        }

        ToolTip {
            parent: parent
            delay: 500
            visible: parent.hovered && !parent.pressed
            text: collapsed ? qsTr("Open Navigation") : qsTr("Close Navigation")
      }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.topMargin: 40
        contentWidth: parent.width
        contentHeight: navigationColumn.implicitHeight
        clip: true

        Column {
            id: navigationColumn
            width: flickable.width
            spacing: 2

            Repeater {
                model: navigationBar.navigationItems
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
}
