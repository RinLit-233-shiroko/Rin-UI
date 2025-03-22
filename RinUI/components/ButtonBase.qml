import QtQuick 2.15
import QtQuick.Controls 2.15
import "../themes"
import "../components"

Base {
    id: buttonBase
    property int borderWidth: Theme.currentTheme.appearance.borderWidth
    property alias text: buttonText.text  // 文本内容
    property alias icon: iconWidget.icon  // 图标 eg."\u1145"
    property bool compact: false  // 紧凑模式
    property bool underline: root.underline // 下划线

    // Size //
    implicitWidth: {
        let totalWidth = 0;
        if (buttonText.visible) totalWidth += buttonText.width;
        if (iconWidget.visible) totalWidth += iconWidget.width;
        if (buttonText.visible && iconWidget.visible) totalWidth += 8; // 图标和文本的间距
        return compact ? totalWidth + 12 : totalWidth + 96;
    }

    implicitHeight: {
        let totalHeight = 0;
        if (buttonText.visible) totalHeight = Math.max(totalHeight, buttonText.height);
        if (iconWidget.visible) totalHeight = Math.max(totalHeight, iconWidget.height);
        return totalHeight + 12;
    }

    // Border //
    // 背景 / Background
    Rectangle {
        id: border
        anchors.fill: parent
        radius: controlRadius
        layer.enabled: true  // 单独渲染
        gradient: Gradient {
            GradientStop { position: 0.91; color: backgroundColor.lighter(borderTransparency) }
            GradientStop { position: 1; color: backgroundColor.darker(1.4) }
        }

        Rectangle {
            id: background
            anchors.fill: parent
            anchors.margins: Theme.currentTheme.appearance.borderWidth  // 边框宽度 / Border Width
            color: backgroundColor
            radius: border.radius
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8  // 图标和文本的间距 / spacing between icon and text

        // Icon //
        IconWidget {
            id: iconWidget
            size: Theme.currentTheme.typography.bodyLargeSize
        }

        // Text //
        TextLabel {
            id: buttonText
            labelType: "body"
            color: root.textColor
            font.underline: underline
        }
    }
}