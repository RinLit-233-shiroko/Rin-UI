import QtQuick 2.15
import QtQuick.Controls.Basic
import "../../themes"
import "../../components"

// thanks @JerryQAQ

Slider {
    id: root
    // 尺寸属性
    property real handleSize: Theme.currentTheme.appearance.sliderHandleSize  // 手柄基础尺寸
    property real borderWidth: 3   // 边框宽度
    property int ticksPadding: 4  // 刻度线间距
    property real trackHeight: 4
    property bool showTooltip: true
    readonly property SliderToolTip toolTip: SliderToolTip { }
    property bool tickmarks: false
    property real tickFrequency: 0  // 刻度线频率
    readonly property real effectiveTickInterval: tickFrequency !== 0 ? Math.abs(tickFrequency) : (stepSize > 0 ? Math.abs(stepSize) : 1)
    property color primaryColor: Theme.currentTheme.colors.primaryColor

    component SliderToolTip: QtObject {
        property bool visible: true
        property var text: root.value.toString()
    }

    // notification of showTooltip
    Component.onCompleted: {
        if (!showTooltip) {
            console.log(" DeprecationWarning: 'showTooltip' will be removed in the future. Use 'toolTip.visible' instead.")
        }
    }

    // accessibility
    FocusIndicator {
        control: parent
    }

    // 自动吸附
    snapMode: stepSize > 0 ? Slider.SnapAlways : Slider.NoSnap

    // 自适应高度和宽度
    implicitHeight: orientation === Qt.Horizontal ? 32 : 150
    implicitWidth: orientation === Qt.Horizontal ? 150 : 32


    // Background / 背景 //
    background: Rectangle {
        anchors.centerIn: parent
        width: root.orientation === Qt.Horizontal ? parent.width - handle.width : trackHeight
        height: root.orientation === Qt.Horizontal ? trackHeight : parent.height - handle.width
        radius: 99
        color: Theme.currentTheme.colors.controlStrongColor

        Behavior on color {
            ColorAnimation {
                duration: Utils.appearanceSpeed
                easing.type: Easing.OutQuart
            }
        }

        // 进度条
        Rectangle {
            width: root.orientation === Qt.Horizontal ? root.visualPosition * parent.width : trackHeight
            height: root.orientation === Qt.Horizontal ? trackHeight : (1 - root.visualPosition) * parent.height
            anchors.bottom: root.orientation === Qt.Vertical ? parent.bottom : undefined
            radius: 99
            color: Theme.currentTheme.colors.primaryColor

            Behavior on width {
                NumberAnimation {
                    duration: Utils.animationSpeedFaster
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: Utils.appearanceSpeed
                    easing.type: Easing.OutQuart
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: Utils.animationSpeedFaster
                    easing.type: Easing.OutCubic
                }
            }
        }

        // 刻度线 / Repeater //
         Repeater {
             model: Math.abs(to - from) / effectiveTickInterval

             delegate: Column {
                x: root.orientation === Qt.Horizontal ?
                    index * parent.width / Math.abs(to - from) * effectiveTickInterval - width / 2
                    : ticksPadding + trackHeight
                y: root.orientation === Qt.Vertical ?
                    index * parent.height / Math.abs(to - from) * effectiveTickInterval - height / 2
                    : ticksPadding + trackHeight
                spacing: 2
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.orientation === Qt.Horizontal ? 1 : 4
                    height: root.orientation === Qt.Horizontal ? 4 : 1
                    color: Theme.currentTheme.colors.controlStrongColor

                    visible: root.tickmarks && index !== 0 && index !== (Math.abs(to - from) / effectiveTickInterval)
                }
             }
        }
    }


    // 手柄 / Handle //
    handle: Item {
        id: handle
        property bool hovered: false
        width: handleSize + 2
        height: handleSize + 2

        // 动态调整手柄位置：根据 orientation 切换 x/y 轴逻辑
        x: root.orientation === Qt.Horizontal
           ? root.visualPosition * (root.width - width)  // 横向：x 受 visualPosition 控制
           : (parent.width - width) / 2  // 竖向
        y: root.orientation === Qt.Vertical
           ? (root.visualPosition) * (root.height - height)  // 竖向：y 受 visualPosition 控制
           : (parent.height - height) / 2  // 横向





        ToolTip {
            text: toolTip.text
            visible: toolTip.visible ? (handle.hovered || root.pressed)  : false
            delay: 50
        }

        // MouseArea
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: handle.hovered = true
            onExited: handle.hovered = false
        }

        // border
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.currentTheme.colors.controlQuaternaryColor
        }

        // border middle(?)
        Rectangle {
            anchors.centerIn: parent
            width: handleSize
            height: handleSize
            radius: width / 2
            color: Theme.currentTheme.colors.controlSolidColor

            Behavior on color {
                ColorAnimation {
                    duration: Utils.appearanceSpeed
                    easing.type: Easing.OutQuart
                }
            }
        }

        // dot 主题色圆点
        Rectangle {
            id: dot
            anchors.centerIn: parent
            // 取偶数
            width: Math.round(handleSize * 0.55) & ~1
            height: Math.round(handleSize * 0.55) & ~1
            radius: width / 2

            // 悬停
            scale: root.pressed ? 0.83 :
                handle.hovered ? 1.16 : 1.0
            color: root.pressed ? Qt.alpha(Theme.currentTheme.colors.primaryColor, 0.8) :
                handle.hovered ? Qt.alpha(Theme.currentTheme.colors.primaryColor, 0.9) : Theme.currentTheme.colors.primaryColor

            // 动画
            Behavior on color {
                ColorAnimation {
                    duration: Utils.appearanceSpeed
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: Utils.animationSpeed
                    easing.type: Easing.OutBack
                }
            }
        }

        Behavior on x {
            NumberAnimation {
                duration: Utils.animationSpeedFaster
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: Utils.animationSpeedFaster
                easing.type: Easing.OutCubic
            }
        }
    }


    // 状态管理
    states: [
        State {
            name: "disabled"
            when: !root.enabled
            PropertyChanges {
                target: handle
                color: Theme.currentTheme.colors.textDisabled
                opacity: 0.6
            }
        }
    ]
}
