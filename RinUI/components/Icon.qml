import QtQuick 2.15
import Qt5Compat.GraphicalEffects
import "../components"
import "../themes"
import "../utils"
// import "../assets/fonts/FluentSystemIcons-Index.js" as Icons


Item {
    id: root
    property string icon: ""  // 字体图标（如 "\uf103"）
    property alias name: root.icon  // 兼容
    property string source: ""  // 图片路径（如 "icons/image.png"）
    property alias color: text.color
    // property string fontSource: Qt.resolvedUrl("../assets/fonts/" + Theme.currentTheme.typography.fontIcon)
    // property string fontSource: Qt.resolvedUrl("../assets/fonts/FluentSystemIcons-Resizable.ttf")  // 字体图标路径

    property int size: navigation ? 20 : 16  // 导航图标默认 20px
    property bool navigation: false  // 是否为导航图标(启用主题色适配和固定尺寸)

    // 计算是否是字体图标
    property bool isUnicode: icon.length === 1  // 判断是否为单字符（字体图标通常是单个字符）
    property bool isFontIcon: source === ""  // 判断是否为字体图标
    property bool isSvg: source.toString().toLowerCase().endsWith(".svg")  // 判断是否为 SVG 图标

    // 匹配尺寸
    implicitWidth: size
    implicitHeight: size

    // 主题切换动画
    Behavior on color {
        ColorAnimation {
            duration: 250
            easing.type: Easing.OutQuart
        }
    }

    Text {
        id: text
        anchors.centerIn: parent
        // text: isFontIcon ? icon : ""  // 仅当 `icon` 是单字符时显示
        text: isUnicode ? icon : String.fromCharCode(Utils.fontIconIndex[icon])  // 显示 FluentSystemIcons 字体图标
        font.family: Utils.iconFontFamily
        font.pixelSize: size
    }

    Image {
        id: iconImage
        anchors.centerIn: parent
        source: root.source  // 仅当 `icon` 不是字体图标时加载图片
        width: isSvg && navigation ? size * 0.77 : size
        height: isSvg && navigation ? size * 0.77 : size
        mipmap: true
        fillMode: Image.PreserveAspectFit  // 适配图片大小
        visible: !isSvg || !navigation  // 导航图标使用 ColorOverlay 显示
    }

    // 导航图标颜色覆盖层,使 SVG 图标适配主题颜色
    ColorOverlay {
        anchors.fill: iconImage
        source: iconImage
        color: root.color
        visible: isSvg && navigation  // 仅导航图标启用颜色覆盖
    }
}
