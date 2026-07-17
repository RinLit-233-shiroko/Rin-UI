import QtQuick 2.15
import "../../themes"

// 内容卡片圆角「外侧」遮罩：盖住直角溢出，不把文字送进 layer（HiDPI 安全）。
// 算法：角矩形 clip → 填满 → destination-out 挖圆（圆心在内侧角）。
// 只动角 r×r 区域，避免整圆 evenodd 渗进内容区。
Item {
    id: root

    property real radius: Theme.currentTheme.appearance.windowRadius
    property color fillColor: Theme.currentTheme.colors.backgroundColor
    // 默认仅左上：对齐历史 FluentPage 内容裁切（右上补直角，底侧直角）
    property bool topLeft: true
    property bool topRight: false
    property bool bottomLeft: false
    property bool bottomRight: false

    readonly property real paintRadius: Math.max(0, Math.round(radius))

    visible: paintRadius > 0 && width > 1 && height > 1
        && (topLeft || topRight || bottomLeft || bottomRight)
    enabled: false
    clip: false

    onRadiusChanged: schedulePaint()
    onFillColorChanged: schedulePaint()
    onWidthChanged: schedulePaint()
    onHeightChanged: schedulePaint()
    onTopLeftChanged: schedulePaint()
    onTopRightChanged: schedulePaint()
    onBottomLeftChanged: schedulePaint()
    onBottomRightChanged: schedulePaint()
    onVisibleChanged: if (visible) schedulePaint()

    function schedulePaint() {
        paintTimer.restart()
    }

    Timer {
        id: paintTimer
        interval: 16
        repeat: false
        onTriggered: {
            if (cornerCanvas.available)
                cornerCanvas.requestPaint()
        }
    }

    Component.onCompleted: {
        // console.log(
        //     "[RinUI/RoundedCornerOverlay] clip+punch radius=" + paintRadius
        //     + " fill=" + fillColor
        //     + " size=" + Math.round(width) + "x" + Math.round(height)
        // )
        schedulePaint()
    }

    Canvas {
        id: cornerCanvas
        anchors.fill: parent
        antialiasing: true
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Immediate

        onWidthChanged: root.schedulePaint()
        onHeightChanged: root.schedulePaint()
        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            var r = root.paintRadius
            var fill = root.fillColor

            ctx.reset()
            ctx.clearRect(0, 0, w, h)

            if (r <= 0 || w <= 1 || h <= 1)
                return

            r = Math.min(r, Math.floor(w / 2), Math.floor(h / 2))
            if (r <= 0)
                return

            // 在角矩形内：填色后挖掉内侧圆，只留圆角外侧
            function stampOutside(x0, y0, cx, cy) {
                ctx.save()
                ctx.beginPath()
                ctx.rect(x0, y0, r, r)
                ctx.clip()

                ctx.globalCompositeOperation = "source-over"
                ctx.fillStyle = fill
                ctx.fillRect(x0, y0, r, r)

                ctx.globalCompositeOperation = "destination-out"
                ctx.beginPath()
                ctx.arc(cx, cy, r + 0.5, 0, Math.PI * 2, false)
                ctx.fill()

                ctx.restore()
                ctx.globalCompositeOperation = "source-over"
            }

            if (root.topLeft)
                stampOutside(0, 0, r, r)
            if (root.topRight)
                stampOutside(w - r, 0, w - r, r)
            if (root.bottomLeft)
                stampOutside(0, h - r, r, h - r)
            if (root.bottomRight)
                stampOutside(w - r, h - r, w - r, h - r)

            // console.log(
            //     "[RinUI/RoundedCornerOverlay] painted "
            //     + Math.round(w) + "x" + Math.round(h)
            //     + " r=" + r
            //     + " corners="
            //     + (root.topLeft ? "TL " : "")
            //     + (root.topRight ? "TR " : "")
            //     + (root.bottomLeft ? "BL " : "")
            //     + (root.bottomRight ? "BR" : "")
            // )
        }
    }
}
