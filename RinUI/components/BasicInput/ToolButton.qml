import QtQuick 2.15
import QtQuick.Controls 2.15
import "../../components"

Button {
    id: toolBtn
    // flat: true
    property alias size: iconWidget.size
    property alias color: iconWidget.color
    // width: height * 1

    contentItem: Item {
        width: parent.width
        height: parent.height
        Text {
            anchors.centerIn: parent
            id: btnText
            text: toolBtn.text
        }
        IconWidget {
            id: iconWidget
            width: parent.width
            height: parent.height
            size: 20
            icon: toolBtn.icon.name ? toolBtn.icon.name : toolBtn.text
            color: icon.color ? icon.color : highlighted ? flat ?
                enabled ? Theme.currentTheme.colors.textAccentColor : Theme.currentTheme.colors.textColor :
                Theme.currentTheme.colors.textOnAccentColor : Theme.currentTheme.colors.textColor
        }
    }
}
