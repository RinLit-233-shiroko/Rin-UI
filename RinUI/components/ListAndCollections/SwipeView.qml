import QtQuick
import QtQuick.Controls
import "../../components"
import "../../themes"


Item {
    id: root
    default property alias content: view.contentChildren

    // SwipeView alias
    property alias currentIndex: view.currentIndex
    property alias count: view.count
    property alias interactive: view.interactive
    property alias orientation: view.orientation
    property alias horizontal: view.horizontal
    property alias vertical: view.vertical

    property bool carel: true  //carel显示


    // === 方法转发 ===

    // accessibility
    FocusIndicator {
        control: view
    }

    SwipeView {
        id: view
        anchors.fill: parent
        clip: true
    }

    Item {
        id: horizontalBtn
        anchors.fill: parent
        anchors.margins: 1
        visible: parent.hovered

        ToolButton {
            anchors {
                top: vertical ? parent.top : undefined
                left: horizontal ? parent.left : undefined
                horizontalCenter: vertical ? parent.horizontalCenter : undefined
                verticalCenter: horizontal ? parent.verticalCenter : undefined
            }
            background: AcrylicBrush {
                sourceItem: view
            } // 无背景

            width: orientation === Qt.Horizontal ? 16 : 38
            height: orientation === Qt.Horizontal ? 38 : 16
            size: pressed ? 6 : 8
            color: hovered ? Theme.currentTheme.colors.textSecondaryColor : Theme.currentTheme.colors.controlStrongColor
            icon.name: orientation === Qt.Horizontal ? "ic_fluent_triangle_left_20_filled" : "ic_fluent_triangle_up_20_filled"
            opacity: 1
            focusPolicy: Qt.NoFocus
            visible: carel && root.currentIndex > 0

            onClicked: root.currentIndex = Math.max(0, root.currentIndex - 1)
        }

        ToolButton {
            anchors {
                bottom: vertical ? parent.bottom : undefined
                right: horizontal ? parent.right : undefined
                horizontalCenter: vertical ? parent.horizontalCenter : undefined
                verticalCenter: horizontal ? parent.verticalCenter : undefined
            }
            background: AcrylicBrush {
                sourceItem: view
            } // 无背景

            width: orientation === Qt.Horizontal ? 16 : 38
            height: orientation === Qt.Horizontal ? 38 : 16
            size: pressed ? 6 : 8
            color: hovered ? Theme.currentTheme.colors.textSecondaryColor : Theme.currentTheme.colors.controlStrongColor
            icon.name: orientation === Qt.Horizontal ? "ic_fluent_triangle_right_20_filled" : "ic_fluent_triangle_down_20_filled"
            opacity: 1
            focusPolicy: Qt.NoFocus
            visible: carel && root.currentIndex < root.count - 1

            onClicked: root.currentIndex = Math.min(root.count - 1, root.currentIndex + 1)
        }
    }

    WheelHandler {
        id: wheelHandler
        target: root
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                root.currentIndex = Math.min(root.count - 1, root.currentIndex + 1);
            } else if (event.angleDelta.y < 0) {
                root.currentIndex = Math.max(0, root.currentIndex - 1);
            }
            event.accepted = true; // 阻止事件继续冒泡
        }
    }
}
