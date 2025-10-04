pragma Singleton
import QtQuick 2.15
import "../assets/fonts/FluentSystemIcons-Index.js" as Icons
import "../themes"
import "../utils"

QtObject {
    property string fontFamily: Qt.platform.os === "windows"
        ? "Microsoft YaHei" : Qt.application.font.family   // 默认字体
    property string iconFontFamily: FontIconLoader.name
    property string fontIconSource: Qt.resolvedUrl("../assets/fonts/FluentSystemIcons-Resizable.ttf")  // 字体图标路径
    property string fontIconIndexSource: Qt.resolvedUrl("../assets/fonts/FluentSystemIcons-Index.js")  // 字体图标索引路径
    property var fontIconIndex: Icons.FluentIcons // 字体图标索引

    property color primaryColor: "#605ed2" // 默认主题色
    property QtObject colors: Theme.currentTheme.colors // 主题颜色
    property QtObject appearance: Theme.currentTheme.appearance // 界面外观
    property QtObject typography: Theme.currentTheme.typography // 字体

    property int windowDragArea: 5 // 窗口可拖动范围 (px)
    property int dialogMaximumWidth: 600 // 对话框最大宽度 (px)
    property int dialogMinimumWidth: 320 // 对话框最小宽度 (px)

    property bool backdropEnabled: false // 是否启用背景特效
    property int animationSpeed: 250 // 动画速度 (ms)
    property int animationSpeedExpander: 375 // 动画速度 (ms)
    property int animationSpeedFaster: 120 // 动画速度 (ms)
    property int appearanceSpeed: 175 // 界面切换速度 (ms)
    property int animationSpeedMiddle: 450 // 动画速度 (ms)
    property int progressBarAnimationSpeed: 1550 // 进度条动画速度 (ms)

    function loadFontIconIndex() {
        Qt.include(fontIconIndexSource);
    }

    Component.onCompleted: {
        console.log("Font Family: " + fontFamily)
    }
}
