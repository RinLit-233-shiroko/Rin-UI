
import QtQuick 2.15
import "../themes"

QtObject {
    property string name: "Light"
    property bool isDark: false

    // Colors //
    property QtObject colors: QtObject {
        // Controls
        property color controlColor: Qt.alpha("#ffffff", 0.7)
        property color controlSecondaryColor: Qt.alpha("#F9F9F9", 0.5)
        property color controlTertiaryColor: Qt.alpha("#F9F9F9", 0.3)
        property color controlQuaternaryColor: Qt.alpha("#F3F3F3", 0.76)
        property color controlStrongColor: Qt.alpha("#000000", 0.4458)
        property color controlInputActiveColor: "#ffffff"

        property color controlAltSecondaryColor: Qt.alpha("#000000", 0.0241)
        property color controlAltTertiaryColor: Qt.alpha("#000000", 0.0578)
        property color controlAltQuaternaryColor: Qt.alpha("#000000", 0.0924)

        property color controlFillColor: Qt.alpha("#ffffff", 0.7)
        property color controlFillSecondaryColor: Qt.alpha("#F9F9F9", 0.5)
        property color controlFillTertiaryColor: Qt.alpha("#F9F9F9", 0.3)
        property color controlFillQuaternaryColor: Qt.alpha("#F3F3F3", 0.76)

        property color controlBorderColor: Qt.alpha("#000000", 0.06)
        property color controlBottomBorderColor: Qt.alpha("#000000", 0.16)
        property color controlAccentBottomBorderColor: Qt.alpha("#000000", 0.4)
        property color controlBorderStrongColor: Qt.alpha("#000000", 0.6063)
        property color controlBorderAccentColor: Qt.alpha("#000000", 0.3)
        property color textControlBorderColor: Qt.alpha("#000000", 0.45)
        property color textControlBorderFocusedColor: Utils.primaryColor
        property color flyoutBorderColor: Qt.alpha("#000000", 0.0578)

        property color controlSolidColor: "#ffffff"
        property color dividerBorderColor: Qt.alpha("#000000", 0.0803)
        // Accessibility
        property color focusBorderOuter: Qt.alpha("#000000", 0.8956)
        property color focusBorderInner: "#ffffff"

        // Card
        property color cardColor: Qt.alpha("#ffffff", 0.7)
        property color cardSecondaryColor: Qt.alpha("#F6F6F6", 0.5)
        property color cardTertiaryColor: Qt.alpha("#ffffff", 1)
        property color cardBorderColor: Qt.alpha("#000000", 0.0578)

        // Background
        property color backgroundColor: "#F3F3F3"
        property color windowBorderColor: Qt.alpha("#757575", 0.0924)
        property color backgroundAcrylicColor: "#F9F9F9"
        property color backgroundSmokeColor: Qt.alpha("#000000", 0.3)

        property color subtleColor: Qt.alpha("#ffffff", 0)
        property color subtleSecondaryColor: Qt.alpha("#000000", 0.0373)
        property color subtleTertiaryColor: Qt.alpha("#000000", 0.0241)
        property color captionCloseColor: "#c42b1c"
        property color captionCloseTextColor: "#ffffff"

        // Layer
        property color layerColor: Qt.alpha("#ffffff", 0.5)

        // Text
        property color textColor: "#1b1b1b"
        property color textSecondaryColor: Qt.alpha("#000000", 0.6063)
        property color textAccentColor: primaryColor
        property color textOnAccentColor: "#ffffff"
        property color textSelectedColor: "#ffffff"

        property color primaryColor: Utils.primaryColor
        property color disabledColor: "#000000"

        // System Colors
        property color systemAttentionColor: primaryColor
        property color systemSuccessColor: "#0f7b0f"
        property color systemCautionColor: "#9d5d00"
        property color systemCriticalColor: "#c42b1c"
        property color systemNeutralColor: "#8d8d8d"

        property color systemAttentionBackgroundColor: "#fbfbfb"
        property color systemSuccessBackgroundColor: "#dff6dd"
        property color systemCautionBackgroundColor: "#fff4ce"
        property color systemCriticalBackgroundColor: "#fde7e9"
        property color systemNeutralBackgroundColor: "#f9f9f9"
    }

    // Appearance //
    property QtObject appearance: QtObject {
        property int buttonRadius: 5
        property int borderWidth: 1
        property real borderFactor: 0.9
        property real borderOnAccentFactor: 1.08
        property int smallRadius: 3

        property int dialogTitleBarHeight: 32
        property int windowTitleBarHeight: 48
        property int windowRadius: 7
        property int windowButtonWidth: 46

        property int scrollBarMinWidth: 2
        property int scrollBarWidth: 6
        property int scrollBarPadding: 3

        property int sliderHandleSize: 20
    }

    // Shadows //
    property var shadows: {
        "dialog": {
            "color": Qt.alpha("#000000", 0.19),  // 模糊颜色
            "blur": 64,  // 模糊度
            "offsetY": 32
        },
        "tooltip": {
            "color": Qt.alpha("#000000", 0.14),
            "blur": 8,
            "offsetY": 4
        },
        "cardRest": {
            "color": Qt.alpha("#000000", 0.04),
            "blur": 4,
            "offsetY": 2
        },
        "flyout": {
            "color": Qt.alpha("#000000", 0.14),
            "blur": 24,
            "offsetY": 8
        },
    }

    // Typography //
    property QtObject typography: QtObject {
        // property string fontFamily: "Segoe UI"
        // property string fontIcon: "FluentSystemIcons-Resizeable.ttf"  // 字体图标路径 / font icon (put it in the "assets/fonts" folder)
        // Font Sizes
        property int displaySize: 68
        property int titleLargeSize: 40
        property int titleSize: 28
        property int subtitleSize: 20
        property int bodyLargeSize: 18
        property int bodySize: 14
        property int bodyStrongSize: 14
        property int captionSize: 12
    }
}
