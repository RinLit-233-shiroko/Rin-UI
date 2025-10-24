
import QtQuick 2.15
import "../themes"

QtObject {
    property string name: "Dark"
    property bool isDark: true

    // Colors //
    property QtObject colors: QtObject {
        // Controls
        property color controlColor: Qt.alpha("#ffffff", 0.065)
        property color controlSecondaryColor: Qt.alpha("#ffffff", 0.1)
        property color controlTertiaryColor: Qt.alpha("#ffffff", 0.0419)
        property color controlQuaternaryColor: Qt.alpha("#ffffff", 0.0698)
        property color controlStrongColor: Qt.alpha("#ffffff", 0.5442)
        property color controlInputActiveColor: Qt.alpha("#1E1E1E", 0.7)

        property color controlAltSecondaryColor: Qt.alpha("#000000", 0.1)
        property color controlAltTertiaryColor: Qt.alpha("#ffffff", 0.0419)
        property color controlAltQuaternaryColor: Qt.alpha("#ffffff", 0.0698)

        property color controlFillColor: Qt.alpha("#ffffff", 0.0605)
        property color controlFillSecondaryColor: Qt.alpha("#ffffff", 0.0837)
        property color controlFillTertiaryColor: Qt.alpha("#ffffff", 0.0326)
        property color controlFillQuaternaryColor: Qt.alpha("#ffffff", 0.0605)

        property color controlBorderColor: Qt.alpha("#ffffff", 0.09)
        property color controlBottomBorderColor: Qt.alpha("#000000", 0.03)
        property color controlAccentBottomBorderColor: Qt.alpha("#000000", 0.14)
        property color controlBorderStrongColor: Qt.alpha("#ffffff", 0.6047)
        property color controlBorderAccentColor: Qt.alpha("#ffffff", 0.08)
        property color textControlBorderColor: Qt.alpha("#ffffff", 0.54)
        property color textControlBorderFocusedColor: Utils.primaryColor
        property color flyoutBorderColor: Qt.alpha("#000000", 0.2)

        property color controlSolidColor: "#454545"
        property color dividerBorderColor: Qt.alpha("#ffffff", 0.0837)
        // Accessibility
        property color focusBorderOuter: "#ffffff"
        property color focusBorderInner: Qt.alpha("#000000", 0.7)

        // Card
        property color cardColor: Qt.alpha("#ffffff", 0.0512)
        property color cardSecondaryColor: Qt.alpha("#ffffff", 0.0326)
        property color cardTertiaryColor: Qt.alpha("#ffffff", 0.0698)
        property color cardBorderColor: Qt.alpha("#000000", 0.1)

        // Background
        property color backgroundColor: "#202020"
        property color windowBorderColor: Qt.alpha("#757575", 0.0698)
        property color backgroundAcrylicColor: "#2c2c2c"
        property color backgroundSmokeColor: Qt.alpha("#000000", 0.3)

        property color subtleColor: "transparent"
        property color subtleSecondaryColor: Qt.alpha("#ffffff", 0.0605)
        property color subtleTertiaryColor: Qt.alpha("#ffffff", 0.0419)
        property color captionCloseColor: "#c42b1c"
        property color captionCloseTextColor: "#ffffff"

        // Layer
        property color layerColor: Qt.alpha("#3A3A3A", 0.3)

        // Text
        property color textColor: "#ffffff"
        property color textSecondaryColor: Qt.alpha("#ffffff", 0.6047)
        property color textAccentColor: primaryColor
        property color textOnAccentColor: "#000000"
        property color textSelectedColor: "#000000"

        property color primaryColor: Qt.color(Utils.primaryColor).lighter(1.6).darker(1.2)
        property color disabledColor: "#ffffff"

        // System Colors
        property color systemAttentionColor: primaryColor
        property color systemSuccessColor: "#6ccb5f"
        property color systemCautionColor: "#fce100"
        property color systemCriticalColor: "#ff99a4"
        property color systemNeutralColor: "#9f9f9f"

        property color systemAttentionBackgroundColor: "#2e2e2e"
        property color systemSuccessBackgroundColor: "#393d1b"
        property color systemCautionBackgroundColor: "#433519"
        property color systemCriticalBackgroundColor: "#442726"
        property color systemNeutralBackgroundColor: "#333333"
    }

    // Appearance //
    property QtObject appearance: QtObject {
        property int buttonRadius: 5
        property int borderWidth: 1
        property real borderFactor: 1.2
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
            "color": Qt.rgba(0, 0, 0, 0.37),  // 模糊颜色
            "blur": 64,  // 模糊度
            "offsetY": 32
        },
        "tooltip": {
            "color": Qt.alpha("#000000", 0.14),
            "blur": 8,
            "offsetY": 4
        },
        "cardRest": {
            "color": Qt.rgba(0, 0, 0, 0.04),
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
