import QtQuick 2.15
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import "../../themes"

Item {
    id: root

    default property alias contentData: contentLayer.data
    property Item sourceItem
    property Item backdropItem
    property real radius: parent && parent.radius !== undefined ? parent.radius : Theme.currentTheme.appearance.windowRadius
    property int blur: 96
    property real blurMultiplier: 0
    property real downsample: 0.5
    property color tintColor: Theme.currentTheme.isDark ? "#CC1F1F1F" : "#CCFFFFFF"
    property real tintOpacity: 1
    property real tintLuminosityOpacity: 0
    property real noiseOpacity: 0.02
    property color backgroundColor: Theme.currentTheme.colors.backgroundAcrylicColor
    property color fallbackColor: Theme.currentTheme.colors.backgroundAcrylicColor
    property bool alwaysUseFallback: false
    property int tintTransitionDuration: 500
    // property color borderColor: Theme.currentTheme.colors.cardBorderColor
    // property real borderWidth: Theme.currentTheme.appearance.borderWidth
    property bool live: true
    property bool fallbackWhenUnavailable: true
    property bool clipToRadius: true
    property bool transparent: false
    property alias contentItem: contentLayer

    readonly property Item _effectiveSource: _resolveEffectiveSource()
    readonly property bool effectAvailable: _effectiveSource !== null && width > 0 && height > 0
    readonly property bool usingFallback: !root.enabled || root.alwaysUseFallback || !root.effectAvailable
    readonly property real effectiveDownsample: Math.max(0.1, Math.min(1, downsample))
    readonly property real effectiveTintOpacity: _effectiveTintOpacity()
    readonly property color effectiveLuminosityColor: _effectiveLuminosityColor()
    readonly property bool shouldLiveUpdate: root.enabled && root.live && !root.alwaysUseFallback && root.effectAvailable && root._renderable && root.inViewport

    property bool inViewport: true
    property bool _renderable: true
    property rect _captureRect: Qt.rect(0, 0, 0, 0)

    onXChanged: updateRuntimeState()
    onYChanged: updateRuntimeState()
    onWidthChanged: updateCaptureRect()
    onHeightChanged: updateCaptureRect()
    onVisibleChanged: updateRuntimeState()
    onEnabledChanged: updateRuntimeState()
    onOpacityChanged: updateRuntimeState()
    on_EffectiveSourceChanged: updateCaptureRect()

    Component.onCompleted: {
        updateRuntimeState()
        updateCaptureRect()
    }

    Timer {
        interval: 100
        running: root.live
        repeat: true
        onTriggered: root.updateRuntimeState()
    }

    Timer {
        id: liveRefreshTimer
        interval: 16
        running: root.shouldLiveUpdate
        repeat: true
        onTriggered: root.updateCaptureRect()
    }

    function _resolveEffectiveSource() {
        if (root.sourceItem) return root.sourceItem
        if (root.backdropItem) return root.backdropItem
        return null
    }

    function _computeInViewport() {
        var win = root.Window.window
        if (!win || !win.contentItem) return true
        var p = root.mapToItem(win.contentItem, 0, 0)
        return p.y + root.height >= 0
            && p.y <= win.height
            && p.x + root.width >= 0
            && p.x <= win.width
    }

    function _computeRenderable() {
        var current = root
        var opacityProduct = 1
        while (current !== null) {
            if (current.visible === false) return false
            opacityProduct *= current.opacity
            if (opacityProduct <= 0.01) return false
            current = current.parent
        }
        return true
    }

    function _clamp(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, value))
    }

    function _rgba(colorValue) {
        var c = Qt.color(colorValue)
        return {
            r: _clamp(c.r, 0, 1),
            g: _clamp(c.g, 0, 1),
            b: _clamp(c.b, 0, 1),
            a: _clamp(c.a, 0, 1)
        }
    }

    function _colorWithAlpha(colorValue, alphaValue) {
        var c = _rgba(colorValue)
        return Qt.rgba(c.r, c.g, c.b, _clamp(alphaValue, 0, 1))
    }

    function _hsvFromRgb(rgb) {
        var max = Math.max(rgb.r, rgb.g, rgb.b)
        var min = Math.min(rgb.r, rgb.g, rgb.b)
        var delta = max - min
        var h = 0
        if (delta !== 0) {
            if (max === rgb.r) {
                h = ((rgb.g - rgb.b) / delta) % 6
            } else if (max === rgb.g) {
                h = (rgb.b - rgb.r) / delta + 2
            } else {
                h = (rgb.r - rgb.g) / delta + 4
            }
            h /= 6
            if (h < 0) h += 1
        }
        return {
            h: h,
            s: max === 0 ? 0 : delta / max,
            v: max
        }
    }

    function _rgbFromHsv(hsv) {
        var h = ((hsv.h % 1) + 1) % 1
        var s = _clamp(hsv.s, 0, 1)
        var v = _clamp(hsv.v, 0, 1)
        var c = v * s
        var x = c * (1 - Math.abs((h * 6) % 2 - 1))
        var m = v - c
        var r = 0
        var g = 0
        var b = 0

        if (h < 1 / 6) {
            r = c; g = x; b = 0
        } else if (h < 2 / 6) {
            r = x; g = c; b = 0
        } else if (h < 3 / 6) {
            r = 0; g = c; b = x
        } else if (h < 4 / 6) {
            r = 0; g = x; b = c
        } else if (h < 5 / 6) {
            r = x; g = 0; b = c
        } else {
            r = c; g = 0; b = x
        }

        return {
            r: r + m,
            g: g + m,
            b: b + m
        }
    }

    function _tintOpacityModifier() {
        var hsv = _hsvFromRgb(_rgba(root.tintColor))
        var midPoint = 0.50
        var whiteMaxOpacity = 0.45
        var midPointMaxOpacity = 0.90
        var blackMaxOpacity = 0.85
        var opacityModifier = midPointMaxOpacity

        if (hsv.v !== midPoint) {
            var lowestMaxOpacity = midPointMaxOpacity
            var maxDeviation = midPoint

            if (hsv.v > midPoint) {
                lowestMaxOpacity = whiteMaxOpacity
                maxDeviation = 1 - maxDeviation
            } else if (hsv.v < midPoint) {
                lowestMaxOpacity = blackMaxOpacity
            }

            var maxOpacitySuppression = midPointMaxOpacity - lowestMaxOpacity
            var deviation = Math.abs(hsv.v - midPoint)
            var normalizedDeviation = deviation / maxDeviation

            if (hsv.s > 0) {
                maxOpacitySuppression *= Math.max(1 - (hsv.s * 2), 0)
            }

            var opacitySuppression = maxOpacitySuppression * normalizedDeviation
            opacityModifier = midPointMaxOpacity - opacitySuppression
        }

        return opacityModifier
    }

    function _effectiveTintOpacity() {
        var rgba = _rgba(root.tintColor)
        if (root.tintLuminosityOpacity >= 0) {
            return _clamp(rgba.a * root.tintOpacity, 0, 1)
        }
        return _clamp(rgba.a * root.tintOpacity * _tintOpacityModifier(), 0, 1)
    }

    function _effectiveLuminosityColor() {
        var rgba = _rgba(root.tintColor)
        var originalTintAlpha = _clamp(rgba.a * root.tintOpacity, 0, 1)
        var luminosityAlpha = root.tintLuminosityOpacity >= 0
            ? _clamp(root.tintLuminosityOpacity, 0, 1)
            : Math.min((originalTintAlpha * (1.03 - 0.15)) + 0.15, 1.0)

        if (root.tintLuminosityOpacity >= 0) {
            return Qt.rgba(rgba.r, rgba.g, rgba.b, luminosityAlpha)
        }

        var hsv = _hsvFromRgb(rgba)
        var rgb = _rgbFromHsv({ h: hsv.h, s: hsv.s, v: _clamp(hsv.v, 0.125, 0.965) })
        return Qt.rgba(rgb.r, rgb.g, rgb.b, luminosityAlpha)
    }

    function updateRuntimeState() {
        root.inViewport = _computeInViewport()
        root._renderable = _computeRenderable()
        if (root.shouldLiveUpdate) {
            updateCaptureRect()
        }
    }

    function updateCaptureRect() {
        var src = _effectiveSource
        if (src) {
            var pos = root.mapToItem(src, 0, 0)
            _captureRect = Qt.rect(pos.x, pos.y, root.width, root.height)
        } else {
            _captureRect = Qt.rect(0, 0, 0, 0)
        }
    }

    implicitWidth: 320
    implicitHeight: 180
    width: parent ? parent.width : implicitWidth
    height: parent ? parent.height : implicitHeight
    z: -1000
    clip: false

    Rectangle {
        anchors.fill: parent
        radius: root.clipToRadius ? root.radius : 0
        color: root.backgroundColor
        opacity: root.transparent || root.usingFallback ? 0 : 1
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: root.tintTransitionDuration; easing.type: Easing.OutCubic } }
    }

    ShaderEffectSource {
        id: sourceTexture
        sourceItem: root._effectiveSource
        sourceRect: root._captureRect
        textureSize: Qt.size(
            Math.max(1, Math.round(root.width * root.effectiveDownsample)),
            Math.max(1, Math.round(root.height * root.effectiveDownsample))
        )
        live: root.shouldLiveUpdate
        recursive: false
        hideSource: false
        visible: false
        smooth: true
        mipmap: true
    }

    Rectangle {
        id: maskShape
        width: root.width
        height: root.height
        radius: root.clipToRadius ? root.radius : 0
        color: "white"
        visible: false
        layer.enabled: true
        layer.smooth: true
    }

    MultiEffect {
        id: blurLayer
        anchors.fill: parent
        source: sourceTexture
        blurEnabled: !root.usingFallback
        blur: 1
        blurMax: root.blur
        blurMultiplier: root.blurMultiplier
        autoPaddingEnabled: false
        maskEnabled: root.clipToRadius
        maskSource: maskShape
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.02
        saturation: 1.25
        contrast: 0
        brightness: 0
        visible: !root.usingFallback
        layer.enabled: true
        layer.smooth: true
    }

    ShaderEffectSource {
        id: blurredTexture
        sourceItem: blurLayer
        hideSource: true
        live: root.shouldLiveUpdate
        recursive: false
        visible: false
        smooth: true
        mipmap: true
    }

    MultiEffect {
        id: desaturateLayer
        anchors.fill: parent
        source: blurredTexture
        saturation: 0
        brightness: root.tintLuminosityOpacity >= 0 ? root.tintLuminosityOpacity * 0.12 : 0
        visible: false
        layer.enabled: true
        layer.smooth: true
    }

    ShaderEffectSource {
        id: desaturatedTexture
        sourceItem: desaturateLayer
        hideSource: true
        live: root.shouldLiveUpdate
        recursive: false
        visible: false
        smooth: true
        mipmap: true
    }

    Blend {
        id: saturationBlend
        anchors.fill: parent
        source: blurredTexture
        foregroundSource: desaturatedTexture
        mode: "normal"
        opacity: root.tintLuminosityOpacity >= 0 ? root.tintLuminosityOpacity : 0
        visible: !root.usingFallback && root.tintLuminosityOpacity >= 0
    }

    Rectangle {
        id: grayOverlay
        anchors.fill: parent
        radius: root.clipToRadius ? root.radius : 0
        color: "#F2F2F2"
        opacity: root.tintLuminosityOpacity >= 0 ? root.tintLuminosityOpacity * 0.55 : 0
        visible: !root.usingFallback && root.tintLuminosityOpacity >= 0
        layer.enabled: true
        layer.smooth: true
    }

    Rectangle {
        anchors.fill: parent
        radius: root.clipToRadius ? root.radius : 0
        color: root.fallbackColor
        opacity: root.usingFallback && root.fallbackWhenUnavailable ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: root.tintTransitionDuration; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        id: luminosityColorLayer
        anchors.fill: parent
        radius: root.clipToRadius ? root.radius : 0
        color: _colorWithAlpha(root.effectiveLuminosityColor, 1)
        opacity: root.effectiveLuminosityColor.a
        visible: false
        layer.enabled: true
        layer.smooth: true
    }

    Rectangle {
        id: tintColorLayer
        anchors.fill: parent
        radius: root.clipToRadius ? root.radius : 0
        color: _colorWithAlpha(root.tintColor, 1)
        opacity: root.effectiveTintOpacity
        visible: !root.usingFallback
        layer.enabled: true
        layer.smooth: true
    }

    Image {
        id: noiseLayer
        anchors.fill: parent
        opacity: !root.usingFallback ? root.noiseOpacity : 0
        visible: opacity > 0 && status === Image.Ready
        source: "../../assets/img/noise.png"
        fillMode: Image.Tile
        // sourceSize.width: 128
        // sourceSize.height: 128

        Behavior on opacity { NumberAnimation { duration: root.tintTransitionDuration; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.clipToRadius ? root.radius : 0
        color: "transparent"
        // border.width: root.borderWidth
        // border.color: root.borderColor
        visible: false
    }

    Item {
        id: contentLayer
        anchors.fill: parent
        clip: root.clipToRadius
    }
}