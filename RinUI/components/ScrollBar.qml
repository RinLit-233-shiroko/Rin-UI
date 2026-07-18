import QtQuick 2.15
import QtQuick.Templates 2.15  // 从Templates导入ScrollBar，否则qt6强制用原生样式……byd我看了大半天
import "../themes"
import "../components"

ScrollBar {
    id: scrollBar

    property int minimumWidth: Theme.currentTheme.appearance.scrollBarMinWidth
    property int expandWidth: Theme.currentTheme.appearance.scrollBarWidth

    // 检测同时显示
    property bool biDirectional: {
        if (!parent)
            return false

        let other = horizontal
            ? parent.ScrollBar.vertical
            : parent.ScrollBar.horizontal

        return other && other.visible && other.size < 1.0
    }

    property int cornerSize: 14

    // 宽高
    width: horizontal && parent
        ? parent.width - (biDirectional ? cornerSize : 0)
        : undefined
    height: vertical && parent
        ? parent.height - (biDirectional ? cornerSize : 0)
        : undefined

    implicitWidth: horizontal
        ? availableWidth
        : implicitContentWidth + leftPadding + rightPadding

    implicitHeight: vertical
        ? availableHeight
        : implicitContentHeight + topPadding + bottomPadding

    // 锚点 //
    anchors.verticalCenter: vertical && parent ? parent.verticalCenter : undefined
    anchors.horizontalCenter: horizontal && parent ? parent.horizontalCenter : undefined
    anchors.right: vertical && parent ? parent.right : undefined
    anchors.bottom: horizontal && parent ? parent.bottom : undefined

    verticalPadding : vertical ? 16 : 3
    horizontalPadding : horizontal ? 15 : 3
    enabled: size < 1.0

    // 控制按钮 / Control Button //
    ToolButton {
        background: Item {}  // 无背景

        width: 16
        height: 16
        size: 8
        color: Theme.currentTheme.colors.textSecondaryColor
        icon.name: vertical ? "ic_fluent_triangle_up_20_filled" : "ic_fluent_triangle_left_20_filled"
        focusPolicy: Qt.NoFocus
        anchors {
            top: vertical ? parent.top : undefined
            left: horizontal ? parent.left : undefined
            horizontalCenter: vertical ? parent.horizontalCenter : undefined
            verticalCenter: horizontal ? parent.verticalCenter : undefined
        }
        onClicked: scrollBar.decrease()

        visible: scrollBar.size < 1.0
        opacity: background.opacity
    }

    ToolButton {
        background: Item {}  // 无背景

        width: 15
        height: 15
        size: 8
        color: Theme.currentTheme.colors.textSecondaryColor
        icon.name: vertical ? "ic_fluent_triangle_down_20_filled" : "ic_fluent_triangle_right_20_filled"
        focusPolicy: Qt.NoFocus
        anchors {
            bottom: vertical ? parent.bottom : undefined
            right: horizontal ? parent.right : undefined
            horizontalCenter: vertical ? parent.horizontalCenter : undefined
            verticalCenter: horizontal ? parent.verticalCenter : undefined
        }
        onClicked: scrollBar.increase()

        visible: scrollBar.size < 1.0
        opacity: background.opacity
    }


    // 内容 / Content //
    contentItem: Item {
        id: item
        // collapsed / 收缩状态 //
        property bool collapsed: (
            scrollBar.policy === ScrollBar.AlwaysOn || (scrollBar.active)
        )  // 当滚动条处于AlwaysOn状态或处于激活状态且尺寸小于1.0时，则为收缩状态

        // 最小尺寸 / Minimum Size //
        implicitWidth: scrollBar.interactive ? scrollBar.expandWidth : scrollBar.minimumWidth
        implicitHeight: scrollBar.interactive ? scrollBar.expandWidth : scrollBar.minimumWidth

        Rectangle{
            id: bar
            width:  vertical ? scrollBar.minimumWidth : parent.width
            height: horizontal ? scrollBar.minimumWidth : parent.height
            color: Theme.currentTheme.colors.controlStrongColor
            anchors{
                right: vertical ? parent.right : undefined
                bottom: horizontal ? parent.bottom : undefined
            }
            radius: 9999
            visible: scrollBar.size < 1.0

            Behavior on color {
                ColorAnimation {
                    duration: Utils.appearanceSpeed
                    easing.type: Easing.OutCubic
                }
            }
        }

        states: [
            State{
                name: "collapsed"
                when: contentItem.collapsed
                PropertyChanges {
                    target: bar
                    width:  vertical ? scrollBar.expandWidth : parent.width
                    height: horizontal ? scrollBar.expandWidth : parent.height
                }
            },
            State{
                name: "minimum"
                when: !contentItem.collapsed
                PropertyChanges {
                    target: bar
                    width:  vertical ? scrollBar.minimumWidth : parent.width
                    height: horizontal ? scrollBar.minimumWidth : parent.height
                }
            }
        ]
        transitions:[
            Transition {
                to: "minimum"
                SequentialAnimation {
                    PauseAnimation { duration: 450 }  // 等待时长
                    NumberAnimation {
                        target: bar
                        properties: vertical ? "width"  : "height"
                        duration: 167
                        easing.type: Easing.OutCubic
                    }
                }
            },
            Transition {
                to: "collapsed"
                SequentialAnimation {
                    PauseAnimation { duration: 150 }
                    NumberAnimation {
                        target: bar
                        properties: vertical ? "width"  : "height"
                        duration: 167
                        easing.type: Easing.OutCubic
                    }
                }
            }
        ]
    }
    // 背景 / Background //
    background: Rectangle{
        id: background
        radius: 5
        color: Theme.currentTheme.colors.backgroundAcrylicColor
        opacity: 0
        visible: scrollBar.size < 1.0

        states: [
            State{
                name: "show"
                when: contentItem.collapsed
                PropertyChanges {
                    target: background
                    opacity: 1
                }
            },
            State{
                name: "hide"
                when: !contentItem.collapsed
                PropertyChanges {
                    target: background
                    opacity: 0
                }
            }
        ]

        // 动画
        transitions:[
            Transition {
                to: "hide"
                SequentialAnimation {
                    PauseAnimation { duration: 450 }  // 等待时长
                    NumberAnimation {
                        target: background
                        properties: "opacity"
                        duration: 167
                        easing.type: Easing.OutCubic
                    }
                }
            },
            Transition {
                to: "show"
                SequentialAnimation {
                    PauseAnimation { duration: 150 }
                    NumberAnimation {
                        target: background
                        properties: "opacity"
                        duration: 167
                        easing.type: Easing.OutCubic
                    }
                }
            }
        ]
    }
}
