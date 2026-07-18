import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"

PageIndicator {
    id: control
    // count: 5
    // currentIndex: 2
    spacing: 0
    implicitHeight: 24

    property bool caret: false

    leftPadding: caret ? 24 : 0
    rightPadding: caret ? 24 : 0

    Item {
        width: caret ? 24 : 0
        height: 24
        visible: caret && control.currentIndex > 0
        anchors.left: parent.left
        enabled: control.enabled && control.interactive

        Icon {
            anchors.centerIn: parent
            icon: "ic_fluent_caret_left_20_filled"
            size: leftTapHandler.pressed? 14 : 16
            color: parent.enabled && leftHoverHandler.hovered
                ? Colors.proxy.textSecondaryColor
                : Colors.proxy.controlStrongColor
            opacity: parent.enabled ? 1 : 0.35
        }

        HoverHandler {
            id: leftHoverHandler
        }

        TapHandler {
            id: leftTapHandler
            enabled: parent.enabled
            onTapped: control.currentIndex = Math.max(0, control.currentIndex - 1)
        }
    }

    Item {
        width: 24
        height: 24
        visible: caret && control.currentIndex < control.count - 1
        anchors.right: parent.right
        enabled: control.enabled && control.interactive

        Icon {
            anchors.centerIn: parent
            icon: "ic_fluent_caret_right_20_filled"
            size: rightTapHandler.pressed? 14 : 16
            color: parent.enabled && rightHoverHandler.hovered
                ? Colors.proxy.textSecondaryColor
                : Colors.proxy.controlStrongColor
            opacity: parent.enabled ? 1 : 0.35
        }

        HoverHandler {
            id: rightHoverHandler
        }

        TapHandler {
            id: rightTapHandler
            enabled: parent.enabled
            onTapped: control.currentIndex = Math.min(control.count - 1, control.currentIndex + 1)
        }
    }

    delegate: Item {
        id: btn
        implicitWidth: 12
        implicitHeight: 12
        anchors.verticalCenter: parent.verticalCenter
        // color: "blue"

        Rectangle {
            anchors.centerIn: parent

            width: btn.size
            height: btn.size
            radius: width / 2
            color: {
                if (hoverHandler.hovered) {
                    return Colors.proxy.textSecondaryColor
                }
                return Colors.proxy.controlStrongColor
            }
        }

        property int size: {
            if (pressed) {
                return 4
            }
            if (hoverHandler.hovered) {
                return 6
            }
            if(index === control.currentIndex) {
                return 6
            }
            return 4
        }

        opacity: control.enabled ? 1 : 0.5
        // opacity: index === control.currentIndex ? 0.95 : pressed ? 0.7 : 0.45

        required property int index

        // Behavior on opacity {
        //     OpacityAnimator {
        //         duration: 100
        //     }
        // }

        HoverHandler {
            id: hoverHandler
        }

        TapHandler {
            enabled: control.interactive
            onTapped: control.currentIndex = index
        }
    }
}