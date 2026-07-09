import QtQuick 2.15
import QtQuick.Shapes 1.15
import "../../themes"

// 内容卡片圆角「外侧」遮罩：盖住直角溢出像素，不把文字送进 layer，避免 HiDPI 糊字。
// 用法：叠在 StackView / 页面之上，与 appLayer.radius 对齐。
Item {
    id: root

    property real radius: Theme.currentTheme.appearance.windowRadius
    property color fillColor: Theme.currentTheme.colors.backgroundColor
    property bool topLeft: true
    property bool topRight: true
    property bool bottomLeft: true
    property bool bottomRight: true

    // radius<=0 时不绘制（如最大化）
    visible: radius > 0.5 && (topLeft || topRight || bottomLeft || bottomRight)
    enabled: false  // 不拦截鼠标，点击穿透到下层页面
    clip: false

    readonly property real r: Math.max(0, radius)

    Component.onCompleted: {
        console.log(
            "[RinUI/RoundedCornerOverlay] radius=" + root.r
            + " fill=" + fillColor
            + " size=" + width + "x" + height
        )
    }

    // 左上：方块减四分之一圆（外侧）
    Shape {
        width: root.r
        height: root.r
        anchors.left: parent.left
        anchors.top: parent.top
        visible: root.topLeft && root.r > 0
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.fillColor
            strokeWidth: 0
            startX: 0
            startY: 0
            PathLine { x: root.r; y: 0 }
            PathArc {
                x: 0
                y: root.r
                radiusX: root.r
                radiusY: root.r
                useLargeArc: false
                direction: PathArc.Clockwise
            }
            PathLine { x: 0; y: 0 }
        }
    }

    // 右上
    Shape {
        width: root.r
        height: root.r
        anchors.right: parent.right
        anchors.top: parent.top
        visible: root.topRight && root.r > 0
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.fillColor
            strokeWidth: 0
            startX: root.r
            startY: 0
            PathLine { x: 0; y: 0 }
            PathArc {
                x: root.r
                y: root.r
                radiusX: root.r
                radiusY: root.r
                useLargeArc: false
                direction: PathArc.Clockwise
            }
            PathLine { x: root.r; y: 0 }
        }
    }

    // 左下
    Shape {
        width: root.r
        height: root.r
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        visible: root.bottomLeft && root.r > 0
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.fillColor
            strokeWidth: 0
            startX: 0
            startY: root.r
            PathLine { x: 0; y: 0 }
            PathArc {
                x: root.r
                y: root.r
                radiusX: root.r
                radiusY: root.r
                useLargeArc: false
                direction: PathArc.Clockwise
            }
            PathLine { x: 0; y: root.r }
        }
    }

    // 右下
    Shape {
        width: root.r
        height: root.r
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.bottomRight && root.r > 0
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.fillColor
            strokeWidth: 0
            startX: root.r
            startY: root.r
            PathLine { x: root.r; y: 0 }
            PathArc {
                x: 0
                y: root.r
                radiusX: root.r
                radiusY: root.r
                useLargeArc: false
                direction: PathArc.Clockwise
            }
            PathLine { x: root.r; y: root.r }
        }
    }
}
