import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../themes"
import "../../components"

ColumnLayout {
    id: root
    spacing: 20
    implicitWidth: 324

    /* ================= 基础状态 ================= */

    property color color: Qt.rgba(1, 0, 0, 1)
    property string colorName: getColorName(hue, saturation,
        value)

    property real hue: 0
    property real saturation: 1
    property real value: 1
    property real alpha: 1

    property bool ringMode: false
    property bool collapsed: true

    property bool moreVisible: false
    property bool colorSliderVisible: true
    property bool colorChannelInputVisible: true
    property bool hexInputVisible: true
    property bool alphaSliderVisible: true
    property bool alphaInputVisible: true
    property bool alphaEnabled: false

    readonly property int sliderHeight: 12
    readonly property int checkerboardCellSize: 4
    property int channelFieldWidth: 120

    function updateColor() {
        var newCol = Qt.hsva(root.hue / 360, root.saturation, root.value, root.alpha)
        if (!Qt.colorEqual(root.color, newCol)) {
            root.color = newCol
        }
    }

    // 当 color 从外部改变时（如拖动 Slider 或 Picker），同步 HSV 变量
    onColorChanged: {
        var h = root.color.hsvHue * 360
        var s = root.color.hsvSaturation
        var v = root.color.hsvValue
        var a = root.color.a
        // console.log("Converted HSV:", h, s, v)

        if (h >= 0 && Math.abs(root.hue - h) > 0.05) {
            root.hue = h
        }
        if (!isNaN(s) && Math.abs(root.saturation - s) > 0.005) {
            root.saturation = s
        }
        if (!isNaN(v) && Math.abs(root.value - v) > 0.005) {
            root.value = v
        }
        if (Math.abs(root.alpha - a) > 0.005) {
            root.alpha = a
        }
    }

    onRingModeChanged: pickerCanvas.requestPaint()

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Item {
            id: colorField
            Layout.preferredWidth: 256
            Layout.fillWidth: true
            Layout.preferredHeight: width

            Canvas {
                id: pickerCanvas
                anchors.fill: parent
                renderTarget: Canvas.Image
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    function hsvToRgb(h, s, v) {
                        h = h % 360; var c = v * s; var x = c * (1 - Math.abs((h / 60) % 2 - 1)); var m = v - c
                        var r1 = 0, g1 = 0, b1 = 0
                        if (0 <= h && h < 60) { r1 = c; g1 = x; b1 = 0 }
                        else if (60 <= h && h < 120) { r1 = x; g1 = c; b1 = 0 }
                        else if (120 <= h && h < 180) { r1 = 0; g1 = c; b1 = x }
                        else if (180 <= h && h < 240) { r1 = 0; g1 = x; b1 = c }
                        else if (240 <= h && h < 300) { r1 = x; g1 = 0; b1 = c }
                        else { r1 = c; g1 = 0; b1 = x }
                        return { r: Math.round((r1 + m) * 255), g: Math.round((g1 + m) * 255), b: Math.round((b1 + m) * 255) }
                    }

                    if (root.ringMode) {
                       // ===== Ring Picker =====
                        var cx = width / 2
                        var cy = height / 2
                        var radius = Math.min(width, height) / 2

                        ctx.clearRect(0, 0, width, height)

                        for (var a = 0; a < 360; a++) {
                            var ang0 = a * Math.PI / 180
                            var ang1 = (a + 1.5) * Math.PI / 180  //

                            ctx.beginPath()
                            ctx.moveTo(cx, cy)
                            ctx.arc(cx, cy, radius, ang0, ang1)
                            ctx.closePath()

                            ctx.fillStyle = Qt.hsla(a / 360, 1.0, 0.5, 1.0)
                            ctx.fill()
                        }

                        var gradient = ctx.createRadialGradient(cx, cy, 0, cx, cy, radius)
                        gradient.addColorStop(0, "white")
                        gradient.addColorStop(1, "transparent")

                        ctx.fillStyle = gradient
                        ctx.beginPath()
                        ctx.arc(cx, cy, radius, 0, Math.PI * 2)
                        ctx.fill()
                    } else {
                        // ===== Box Picker =====
                        var cols = 360
                        var cellSize = width / cols
                        var rows = Math.max(Math.ceil(height / cellSize),1)
                        var cellH = height / rows

                        for (var y = 0; y < rows; y++) {
                            var sat = 1 - (y + 0.5) / rows
                            for (var x = 0; x < cols; x++) {
                                var hue = x
                                var col = hsvToRgb(hue, Math.max(0,Math.min(1,sat)),1.0)
                                var px = Math.round(x*cellSize)
                                var py = Math.round(y*cellH)
                                var pw = Math.ceil(cellSize)+1
                                var ph = Math.ceil(cellH)+1
                                ctx.fillStyle = "rgb(" + col.r + "," + col.g + "," + col.b + ")"
                                ctx.fillRect(px, py, pw, ph)
                            }
                        }
                    }
                }
                onWidthChanged: requestPaint();
                onHeightChanged: requestPaint()
            }

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle { width: colorField.width; height: colorField.height; radius: Theme.currentTheme.appearance.buttonRadius }
            }

            Rectangle {
                id: pickerIndicator
                width: 14; height: 14; radius: 7; border.width: 2
                border.color: {
                    var c = Qt.hsva(root.hue/360, root.saturation, 1, 1)
                    var L = 0.2126*c.r + 0.7152*c.g + 0.0722*c.b
                    return (L < 0.75) ? "white" : "black"
                }
                color: "transparent"
                x: root.ringMode ? colorField.width/2 + root.saturation * Math.min(colorField.width,colorField.height)/2 * Math.cos(root.hue*Math.PI/180) - 7 : (root.hue/360) * colorField.width - 7
                y: root.ringMode ? colorField.height/2 + root.saturation * Math.min(colorField.width,colorField.height)/2 * Math.sin(root.hue*Math.PI/180) - 7 : (1 - root.saturation) * colorField.height - 7

                ToolTip {
                    text: root.colorName
                    timeout: -1
                    y: -22 - parent.height
                    closePolicy: Popup.NoAutoClose
                    visible: root.activeFocus
                }
            }

            MouseArea {
                id: pickerArea
                anchors.fill: parent
                preventStealing: true
                hoverEnabled: true

                onPressed: {
                    root.forceActiveFocus()  // 抢走聚焦
                    updateFromMouse(mouseX, mouseY)
                }
                onPositionChanged: if(mouse.buttons !== Qt.NoButton) updateFromMouse(mouseX, mouseY)
                function updateFromMouse(mx, my) {
                    var w = colorField.width; var h = colorField.height
                    if (root.ringMode) {
                        var dx = mx - w/2; var dy = my - h/2; var dist = Math.sqrt(dx*dx + dy*dy)
                        root.hue = (Math.atan2(dy,dx)*180/Math.PI + 360) % 360
                        root.saturation = Math.min(dist/(Math.min(w,h)/2), 1)
                    } else {
                        root.hue = Math.max(0, Math.min(360, (mx / w) * 360))
                        root.saturation = Math.max(0, Math.min(1, 1 - (my / h)))
                    }
                    root.updateColor()
                }
            }
        }

        //
        Item {
            id: preview
            Layout.preferredWidth: 44
            Layout.fillHeight: true
            Canvas {
                anchors.fill: parent
                property int cellSize: checkerboardCellSize // 固定格子大小

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var rows = Math.ceil(height / cellSize)
                    var cols = Math.ceil(width / cellSize)

                    for (var i = 0; i < rows; i++) {
                        for (var j = 0; j < cols; j++) {
                            ctx.fillStyle = ((i + j) % 2 === 0)
                                ? Qt.rgba(1, 1, 1, 0)
                                : Qt.rgba(0.5, 0.5, 0.5, 0.25)
                            ctx.fillRect(j * cellSize, i * cellSize, cellSize, cellSize)
                        }
                    }
                }
            }
            Rectangle { anchors.fill: parent; color: root.color; radius: Theme.currentTheme.appearance.buttonRadius }
            Rectangle { anchors.fill: parent; color: "transparent"; border.width: 2; border.color: Colors.proxy.dividerBorderColor; radius: Theme.currentTheme.appearance.buttonRadius }
            layer.enabled: true
            layer.effect: OpacityMask { maskSource: Rectangle { width: preview.width; height: preview.height; radius: Theme.currentTheme.appearance.buttonRadius } }
        }
    }

    /* ================= Slider ================= */

    ColumnLayout {
        Layout.fillWidth: true; spacing: 22

        Slider {
            id: valueSlider; visible: root.colorSliderVisible
            Layout.fillWidth: true
            from: 0
            to: 1
            value: root.value
            implicitHeight: sliderHeight
            onMoved: { root.value = visualPosition; root.updateColor() }
            background: Rectangle {
                anchors.fill: parent; radius: sliderHeight / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "black" }
                    GradientStop { position: 1; color: Qt.hsva(root.hue/360, root.saturation, 1, 1) }
                }
            }
            handle: Rectangle {
                implicitWidth: 18; implicitHeight: 18; radius: 9
                x: valueSlider.visualPosition * (valueSlider.width - 18)
                y: (valueSlider.height - 18) / 2
                color: Colors.proxy.textColor; border.width: 4; border.color: Colors.proxy.controlSolidColor
            }
        }

        Slider {
            id: alphaSlider; visible: root.alphaEnabled && root.alphaSliderVisible
            Layout.fillWidth: true
            from: 0
            to: 1
            value: root.alpha
            implicitHeight: sliderHeight
            onMoved: { root.alpha = visualPosition; root.updateColor() }
            background: Item {
                anchors.fill: parent

                // checkerboard
                Canvas {
                    anchors.fill: parent
                    property int cellSize: checkerboardCellSize

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        var rows = Math.ceil(height / cellSize)
                        var cols = Math.ceil(width / cellSize)

                        for (var i = 0; i < rows; i++) {
                            for (var j = 0; j < cols; j++) {
                                ctx.fillStyle = ((i + j) % 2 === 0)
                                    ? Qt.rgba(1, 1, 1, 0)
                                    : Qt.rgba(0.5, 0.5, 0.5, 0.25)
                                ctx.fillRect(j * cellSize, i * cellSize, cellSize, cellSize)
                            }
                        }
                    }

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                Rectangle {
                    id: alphaFill
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Qt.rgba(root.color.r, root.color.g, root.color.b, 0) }
                        GradientStop { position: 1; color: Qt.rgba(root.color.r, root.color.g, root.color.b, 1) }
                    }
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: alphaFill.width
                        height: alphaFill.height
                        radius: height / 2
                    }
                }
            }
            handle: Rectangle {
                implicitWidth: 18; implicitHeight: 18; radius: 9
                x: alphaSlider.visualPosition * (alphaSlider.width - 18)
                y: (alphaSlider.height - 18) / 2
                color: Colors.proxy.textColor; border.width: 4; border.color: Colors.proxy.controlSolidColor
            }
        }
    }

    /* ================= 通道输入 + HEX ================= */

    ColumnLayout {
        Layout.fillWidth: true; spacing: 12


        RowLayout {
            visible: moreVisible
            Item {
                Layout.fillWidth: true
            }
            Button {
                Layout.alignment: Qt.AlignRight
                flat: true
                text: collapsed ? qsTr("More") : qsTr("Less")
                suffixIconName: collapsed ? "ic_fluent_chevron_down_20_regular" : "ic_fluent_chevron_up_20_regular"

                onClicked: {
                    collapsed = !collapsed
                }
            }
        }

        // 上方：ComboBox + HEX
        RowLayout {
            visible: !moreVisible || !collapsed; Layout.fillWidth: true; spacing: 16
            ComboBox {
                id: channelMode
                visible: colorChannelInputVisible
                model: ["RGB", "HSV"]
                Layout.preferredWidth: channelFieldWidth
            }
            Item { Layout.fillWidth: true }
            TextField {
                id: hexInput; visible: root.hexInputVisible; Layout.preferredWidth: 132; leftPadding: 22
                // 仅在失去焦点时强制同步，输入时允许实时响应 onTextEdited
                text: activeFocus ? text : (function(){
                    var r = Math.round(root.color.r * 255).toString(16).padStart(2, '0')
                    var g = Math.round(root.color.g * 255).toString(16).padStart(2, '0')
                    var b = Math.round(root.color.b * 255).toString(16).padStart(2, '0')
                    var a = Math.round(root.color.a * 255).toString(16).padStart(2, '0')
                    return (root.alphaEnabled ? (r + g + b + a) : (r + g + b)).toUpperCase()
                })()

                onTextEdited: {
                    if (text.length === 6 || text.length === 8) {
                        var tempColor = Qt.color("#" + text)
                        if (tempColor.toString() !== "#000000" || text.startsWith("000000")) {
                            root.color = tempColor
                        }
                    }
                }
                Text { text: "#"; anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        ColumnLayout {
            visible: root.colorChannelInputVisible && (!moreVisible || !collapsed); Layout.fillWidth: true; spacing: 12
            Repeater {
                model: channelMode.currentText === "RGB"
                   ? [{ label: qsTr("Red"), m: "r" }, { label: qsTr("Green"), m: "g" }, { label: qsTr("Blue"), m: "b" }]
                   : [{ label: qsTr("Hue"), m: "h" }, { label: qsTr("Saturation"), m: "s" }, { label: qsTr("Value"), m: "v" }]

                RowLayout {
                    spacing: 8
                    TextField {
                        id: channelInput; Layout.preferredWidth: channelFieldWidth
                        text: activeFocus ? text : (channelMode.currentText === "RGB"
                                ? Math.round(root.color[modelData.m] * 255).toString()
                                : (modelData.m === "h" ? Math.round(root.hue).toString()
                                  : (modelData.m === "s" ? Math.round(root.saturation * 100).toString()
                                  : Math.round(root.value * 100).toString())))

                        onTextEdited: {
                            var val = parseFloat(text)
                            if (isNaN(val)) return
                            if (channelMode.currentText === "RGB") {
                                var r = (modelData.m === 'r' ? val/255 : root.color.r)
                                var g = (modelData.m === 'g' ? val/255 : root.color.g)
                                var b = (modelData.m === 'b' ? val/255 : root.color.b)
                                root.color = Qt.rgba(r, g, b, root.alpha)
                            } else {
                                if (modelData.m === "h") root.hue = Math.max(0, Math.min(360, val))
                                else if (modelData.m === "s") root.saturation = Math.max(0, Math.min(100, val)) / 100
                                else if (modelData.m === "v") root.value = Math.max(0, Math.min(100, val)) / 100
                                root.updateColor()
                            }
                        }
                    }
                    Text { text: modelData.label; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
                }
            }

            RowLayout {
                visible: root.alphaEnabled && root.alphaInputVisible
                spacing: 8
                TextField {
                    id: alphaInput; Layout.preferredWidth: channelFieldWidth
                    rightPadding: 28 + 22
                    text: activeFocus ? text : Math.round(root.alpha * 100).toString()
                    onTextEdited: {
                        var val = parseFloat(text)
                        if (!isNaN(val)) {
                            root.alpha = Math.max(0, Math.min(100, val)) / 100
                            root.updateColor()
                        }
                    }

                    Text { text: "%"; anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter }
                }
                Text { text: qsTr("Opacity"); Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            }
        }
    }

    /* ================= 颜色名字 ================= */
    function getColorName(h, s, v) {
        if (v < 0.1)
            return "Black"

        if (s < 0.08)
            return v > 0.9 ? "White" : "Gray"

        if (v > 0.8 && s < 0.45) {
            if (h < 35) return "Light orange"
            if (h < 65) return "Light yellow"
            if (h < 140) return "Light green"
            if (h < 205) return "Light turquoise"
            if (h < 230) return "Sky blue"
            if (h < 255) return "Light blue"
        }

        if (s < 0.45) {
            if (h >= 255 && h < 290) return "Lavender"
            if (h >= 290 && h < 345) return "Rose"
        }

        if (h < 15 || h >= 345) return "Red"
        if (h < 35) return "Orange"
        if (h < 50) return "Gold"
        if (h < 70) return "Lime"
        if (h < 140) return "Green"
        if (h < 165) return "Teal"
        if (h < 185) return "Aqua"
        if (h < 205) return "Turquoise"
        if (h < 255) return "Blue"
        if (h < 290) return "Purple"
        return "Pink"
    }
}
