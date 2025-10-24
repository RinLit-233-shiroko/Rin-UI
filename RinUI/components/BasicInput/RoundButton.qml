import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import Qt5Compat.GraphicalEffects
import "../../themes"
import "../../components"

Button {
    id: root
    property alias radius: background.radius
    backgroundColor: highlighted ? primaryColor : Theme.currentTheme.colors.controlQuaternaryColor

    background: Rectangle {
        id: background
        anchors.fill: parent
        color: hovered ? hoverColor : backgroundColor
        radius: height / 2

        border.width: Theme.currentTheme.appearance.borderWidth  // 边框宽度 / Border Width
        border.color: flat ? "transparent" :
            enabled ? highlighted ? primaryColor : Theme.currentTheme.colors.controlBorderColor :
            highlighted ? Theme.currentTheme.colors.disabledColor : Theme.currentTheme.colors.controlBorderColor

        Behavior on color { ColorAnimation { duration: Utils.appearanceSpeed; easing.type: Easing.OutQuart } }
        opacity: flat && !hovered || !hoverable ? 0 : 1
    }
}
