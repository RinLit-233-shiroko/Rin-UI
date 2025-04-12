import QtQuick 2.15
import QtQuick.Controls 2.15
import "../components"
import "../themes"


Item {
    id: navigationBar
    implicitWidth: collapsed ? 50 : 250
    height: parent.height

    property bool collapsed: false
    property var navModel: ListModel {
        // ListElement { title: "Home"; icon: null; page: "Home.qml"; key: "home" }
    }
    property alias currentIndex: listView.currentIndex
    property bool titleBarEnabled: true
    property alias windowTitle: titleLabel.text
    property alias windowIcon: iconLabel.source
    property var stackView: parent.stackView
    property ListModel lastIndex: ListModel {}  // 记录的索引

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Utils.animationSpeedMiddle
            easing.type: Easing.InOutQuint
        }
    }

    Row {
        id: title
        anchors.left: parent.left
        anchors.bottom: parent.top
        height: titleBarHeight
        spacing: 16
        visible: navigationBar.titleBarEnabled

        Component.onCompleted: {
            console.log(titleBarHeight)
        }

        // 返回按钮
        ToolButton {
            anchors.verticalCenter: parent.verticalCenter
            icon.name: "ic_fluent_arrow_left_20_regular"
            onClicked: stackView.safePop()
            width: 40
            height: 40
            enabled: navigationBar.lastIndex.count > 0

            Tooltip {
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
            icon: "\uf12a"
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
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        anchors.rightMargin: 10
        width: 30
        height: 30
        icon.name: collapsed ? "ic_fluent_chevron_right_20_regular" : "ic_fluent_chevron_left_20_regular"
        
        onClicked: {
            collapsed = !collapsed
        }
        
        Tooltip {
            parent: parent
            delay: 500
            visible: parent.hovered
            text: collapsed ? qsTr("Expand") : qsTr("Collapse")
      }
    }

    ListView {
        id: listView
        clip: true
        spacing: 4  // 增加项目间距
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 60  // 为收起按钮留出空间
        model: navModel
        currentIndex: -1

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        delegate: ItemDelegate {
            id: delegateItem
            width: listView.width
            height: 40
            highlighted: ListView.isCurrentItem

            background: Rectangle {
                id: itemBg
                anchors.fill: parent
                anchors.topMargin: 2
                anchors.bottomMargin: 2
                clip: true
                radius: Theme.currentTheme.appearance.buttonRadius / 2
                color: pressed
                    ? Theme.currentTheme.colors.subtleTertiaryColor
                    : (highlighted || hovered)
                        ? Theme.currentTheme.colors.subtleSecondaryColor
                        : Theme.currentTheme.colors.subtleColor

                Row {
                    id: left
                    spacing: 16
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 16
                    anchors.topMargin: 6
                    anchors.bottomMargin: 8

                    IconWidget {
                        id: icon
                        anchors.verticalCenter: parent.verticalCenter
                        size: 18
                        icon: !model.icon ? "ic_fluent_circle_20_regular" : model.icon
                    }

                    Text {
                        id: text
                        anchors.verticalCenter: parent.verticalCenter
                        typography: Typography.Body
                        text: model.title
                        width: navigationBar.collapsed ? 0 : implicitWidth
                        clip: true
                        opacity: navigationBar.collapsed ? 0 : 1
                        wrapMode: Text.NoWrap
                        horizontalAlignment: Text.AlignLeft
                        
                        Behavior on width {
                            NumberAnimation {
                                duration: Utils.animationSpeedMiddle
                                easing.type: Easing.InOutQuint
                            }
                        }
                        
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Utils.animationSpeedMiddle
                                easing.type: Easing.InOutQuint
                            }
                        }
                    }
                }

                // 收起状态下添加提示工具
                Tooltip {
                    visible: navigationBar.collapsed && delegateItem.hovered
                    delay: 500
                    text: model.title
                }

                // 指示器
                Indicator {
                    id: indicator
                    y: listView.currentIndex >= 0
                        ? listView.currentItem.y - delegateItem.y + height / 2
                        : 0
                    currentItemHeight: listView.currentItem.height
                    opacity: highlighted
                    width: 3

                    Behavior on y {
                        NumberAnimation {
                            duration: Utils.animationSpeedMiddle / 1.2
                            easing.type: Easing.InOutQuint
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Utils.animationSpeed
                            easing.type: Easing.InQuint
                        }
                    }
                }

                Behavior on color { ColorAnimation { duration: Utils.appearanceSpeed; easing.type:Easing.InOutQuart } }
            }

            onClicked: {
                if (currentIndex === index) {
                    return
                }

                navigationBar.lastIndex.append({ index: listView.currentIndex })
                listView.currentIndex = index
                navigationBar.currentIndex = index
                console.log(navigationBar.lastIndex)
            }
        }
    }
}
