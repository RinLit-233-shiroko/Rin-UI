    import QtQuick 2.15
    import QtQuick.Controls 2.15
    import QtQuick.Controls.Basic 2.15 as QQC
    import Qt5Compat.GraphicalEffects
    import "../../themes"
    import "../../components"

    QQC.ProgressBar {
        id: root

        property int state: ProgressRing.Running
        enum State {
            Running,
            Paused,
            Error
        }

        implicitWidth: size
        implicitHeight: size

        property int strokeWidth: 6  // 圆环宽度
        property int size: 56  // 尺寸
        property real radius: (Math.min(width, height) - strokeWidth) / 2

        property color backgroundColor: "transparent"
        property color primaryColor: Theme.currentTheme.colors.primaryColor


        // 颜色根据状态变化
        property color _ringColor: state === ProgressRing.Paused
            ? Theme.currentTheme.colors.systemCautionColor
            : state === ProgressRing.Error
            ? Theme.currentTheme.colors.systemCriticalColor
            : primaryColor
        property real _progress: (to - from) === 0
            ? 0
            : Math.max(0, Math.min(1, (value - from) / (to - from)))


        background: Item {}

        contentItem: Canvas {
            id: canvas
            anchors.fill: parent
            antialiasing: true
            renderTarget: Canvas.Image

            property real startAngle: 0
            property real sweepAngle: 270

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.lineWidth = root.strokeWidth
                ctx.lineCap = "round"

                var centerX = width / 2
                var centerY = height / 2

                // 背景圆环
                ctx.strokeStyle = root.backgroundColor
                ctx.beginPath()
                ctx.arc(centerX, centerY, root.radius, 0, 2 * Math.PI)
                ctx.stroke()

                // 前景圆环
                ctx.strokeStyle = root._ringColor
                ctx.beginPath()
                if (root.indeterminate) {
                    ctx.arc(centerX, centerY, root.radius,
                        Math.PI * (startAngle - 90) / 180,
                        Math.PI * (startAngle - 90 + sweepAngle) / 180)
                } else {
                    ctx.arc(centerX, centerY, root.radius,
                        -Math.PI / 2,
                        -Math.PI / 2 + root._progress * 2 * Math.PI)
                }
                ctx.stroke()
            }

            onStartAngleChanged: requestPaint()
            onSweepAngleChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            Component.onCompleted: requestPaint()

            // 旋转动画
            SequentialAnimation on startAngle {
                running: root.indeterminate && root.state === ProgressRing.Running
                loops: Animation.Infinite
                PropertyAnimation { from: 0; to: 450; duration: Utils.progressBarAnimationSpeed / 1.5 }
                PropertyAnimation { from: 450; to: 1080; duration: Utils.progressBarAnimationSpeed / 1.5 }
            }
            SequentialAnimation on sweepAngle {
                running: root.indeterminate && root.state === ProgressRing.Running
                loops: Animation.Infinite
                PropertyAnimation { from: 0; to: 180; duration: Utils.progressBarAnimationSpeed / 1.5 }
                PropertyAnimation { from: 180; to: 0; duration: Utils.progressBarAnimationSpeed / 1.5 }
            }

            // 填充
            SequentialAnimation on startAngle {
                running: root.indeterminate && root.state !== ProgressRing.Running
                PropertyAnimation {
                    from: 0;  to: 0; duration: Utils.animationSpeedMiddle; easing.type: Easing.InOutCubic
                }
            }
            SequentialAnimation on sweepAngle {
                running: root.indeterminate && root.state !== ProgressRing.Running
                PropertyAnimation {
                    from: 0; to: 360; duration: Utils.animationSpeedMiddle; easing.type: Easing.InOutCubic
                }
            }
        }

        // 动画
        Behavior on _progress {
            NumberAnimation {
                duration: Utils.animationSpeed
                easing.type: Easing.InOutQuad
            }
        }

        // 动画
        Behavior on _ringColor {
            ColorAnimation {
                duration: Utils.animationSpeed
                easing.type: Easing.OutCubic
            }
        }

        onStateChanged: {
            if (!indeterminate)
                canvas.requestPaint()
        }
        on_ProgressChanged: {
            if (!indeterminate)
                canvas.requestPaint()
        }
        on_RingColorChanged: {
            canvas.requestPaint()
        }
        onBackgroundColorChanged: {
            if (state === ProgressRing.Running) {
                canvas.requestPaint()
            }
        }
    }
