import QtQuick 2.15
import QtQuick.Controls 2.15
import "../themes"


Rectangle {
    id: indicator

    property int currentItemHeight: 38
    property var orientation: Qt.Vertical

    implicitWidth: orientation === Qt.Horizontal? 14 : 1
    implicitHeight: orientation === Qt.Horizontal? 1 : currentItemHeight - 25
    radius: 10
    color: Theme.currentTheme.colors.primaryColor

    y: orientation === Qt.Horizontal? parent.height - height : (parent.height - height) / 2
    x: orientation === Qt.Horizontal? (parent.width - width) / 2 : 0

    onVisibleChanged: {
        if (visible) {
            enterAnimation.start()
        }
    }

    // 动画 / Animation //
    ParallelAnimation {
        id: enterAnimation
        PropertyAnimation {
            target: indicator
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: Utils.animationSpeed
            easing.type: Easing.OutQuad
        }
        ScriptAction {
            script: {
                if (indicator.orientation === Qt.Horizontal) {
                    enterAnimationHorizontal.start()
                } else {
                    enterAnimationVertical.start()
                }
            }
        }
    }
    // 垂直方向动画group // Vertical Animation
    ParallelAnimation {
        id: enterAnimationVertical
        PropertyAnimation {
            target: indicator
            property: "height"
            from: 0
            to: indicator.implicitHeight
            duration: Utils.animationSpeedMiddle
            easing.type: Easing.OutQuint
        }

        PropertyAnimation {
            target: indicator
            property: "y"
            from: parent.height / 2
            to: (parent.height - indicator.implicitHeight) / 2
            duration: Utils.animationSpeedMiddle
            easing.type: Easing.OutQuint
        }
    }

    // 垂直方向动画group // Vertical Animation
    ParallelAnimation {
        id: enterAnimationHorizontal
        PropertyAnimation {
            target: indicator
            property: "width"
            from: 0
            to: indicator.implicitWidth
            duration: Utils.animationSpeedMiddle
            easing.type: Easing.OutQuint
        }

        PropertyAnimation {
            target: indicator
            property: "x"
            from: parent.width / 2
            to: (parent.width - indicator.implicitWidth) / 2
            duration: Utils.animationSpeedMiddle
            easing.type: Easing.OutQuint
        }
    }
}