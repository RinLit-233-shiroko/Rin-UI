import QtQuick 2.15
import "../../themes"

// 内容卡片圆角「外侧」遮罩：盖住直角溢出像素，不把文字送进 layer，避免 HiDPI 糊字。
// 用 Canvas 画准几何（避免 Shape PathArc 圆心/方向推断错误）。
Item {
    id: root

    property real radius: Theme.currentTheme.appearance.windowRadius
    property color fillColor: Theme.currentTheme.colors.backgroundColor
    property bool topLeft: true
    property bool topRight: true
    property bool bottomLeft: true
    property bool bottomRight: true

    // 略放大以盖住抗锯齿缝
    readonly property real paintRadius: Math.max(0, radius)
    readonly property real cornerSize: paintRadius > 0 ? paintRadius + 1 : 0

    visible: paintRadius > 0.5 && (topLeft || topRight || bottomLeft || bottomRight)
    enabled: false
    clip: false

    onRadiusChanged: repaintAll()
    onFillColorChanged: repaintAll()
    onWidthChanged: repaintAll()
    onHeightChanged: repaintAll()
    onTopLeftChanged: repaintAll()
    onTopRightChanged: repaintAll()
    onBottomLeftChanged: repaintAll()
    onBottomRightChanged: repaintAll()
    onVisibleChanged: if (visible) repaintAll()

    function repaintAll() {
        if (tlCanvas.available) tlCanvas.requestPaint()
        if (trCanvas.available) trCanvas.requestPaint()
        if (blCanvas.available) blCanvas.requestPaint()
        if (brCanvas.available) brCanvas.requestPaint()
    }

    Component.onCompleted: {
        console.log(
            "[RinUI/RoundedCornerOverlay] canvas corners radius=" + paintRadius
            + " fill=" + fillColor
            + " size=" + width + "x" + height
        )
        repaintAll()
    }

    // 左上：角点 (0,0)，圆心 (r,r)，外侧扇形
    Canvas {
        id: tlCanvas
        width: root.cornerSize
        height: root.cornerSize
        anchors.left: parent.left
        anchors.top: parent.top
        visible: root.topLeft && root.paintRadius > 0
        antialiasing: true
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            var r = root.paintRadius
            var s = root.cornerSize
            ctx.reset()
            if (r <= 0) return
            ctx.clearRect(0, 0, s, s)
            ctx.fillStyle = root.fillColor
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(r, 0)
            // 圆心 (r,r)：从顶部 (r,0) 逆时针到左侧 (0,r) —— 圆角内侧边界
            ctx.arc(r, r, r, -Math.PI / 2, Math.PI, true)
            ctx.closePath()
            ctx.fill()
        }
    }

    // 右上：角点 (w,0) 局部 (s,0)，圆心 (s-r, r)
    Canvas {
        id: trCanvas
        width: root.cornerSize
        height: root.cornerSize
        anchors.right: parent.right
        anchors.top: parent.top
        visible: root.topRight && root.paintRadius > 0
        antialiasing: true
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            var r = root.paintRadius
            var s = root.cornerSize
            ctx.reset()
            if (r <= 0) return
            ctx.clearRect(0, 0, s, s)
            ctx.fillStyle = root.fillColor
            var cx = s - r
            ctx.beginPath()
            ctx.moveTo(s, 0)
            ctx.lineTo(cx, 0)
            // 从 (cx,0) 顺时针到 (s,r) —— 相对圆心 (cx,r) 从 -π/2 到 0
            ctx.arc(cx, r, r, -Math.PI / 2, 0, false)
            ctx.lineTo(s, 0)
            ctx.closePath()
            ctx.fill()
        }
    }

    // 左下：角点 (0,h) 局部 (0,s)，圆心 (r, s-r)
    Canvas {
        id: blCanvas
        width: root.cornerSize
        height: root.cornerSize
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        visible: root.bottomLeft && root.paintRadius > 0
        antialiasing: true
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            var r = root.paintRadius
            var s = root.cornerSize
            ctx.reset()
            if (r <= 0) return
            ctx.clearRect(0, 0, s, s)
            ctx.fillStyle = root.fillColor
            var cy = s - r
            ctx.beginPath()
            ctx.moveTo(0, s)
            ctx.lineTo(0, cy)
            // 从 (0,cy) 顺时针到 (r,s) —— 圆心 (r,cy) 从 π 到 π/2
            ctx.arc(r, cy, r, Math.PI, Math.PI / 2, true)
            ctx.lineTo(0, s)
            ctx.closePath()
            ctx.fill()
        }
    }

    // 右下：角点 (w,h) 局部 (s,s)，圆心 (s-r, s-r)
    Canvas {
        id: brCanvas
        width: root.cornerSize
        height: root.cornerSize
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.bottomRight && root.paintRadius > 0
        antialiasing: true
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            var r = root.paintRadius
            var s = root.cornerSize
            ctx.reset()
            if (r <= 0) return
            ctx.clearRect(0, 0, s, s)
            ctx.fillStyle = root.fillColor
            var cx = s - r
            var cy = s - r
            ctx.beginPath()
            ctx.moveTo(s, s)
            ctx.lineTo(s, cy)
            // 从 (s,cy) 逆时针到 (cx,s) —— 圆心 (cx,cy) 从 0 到 π/2
            ctx.arc(cx, cy, r, 0, Math.PI / 2, false)
            ctx.lineTo(s, s)
            ctx.closePath()
            ctx.fill()
        }
    }
}
