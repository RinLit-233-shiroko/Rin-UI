import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../../components"
import "../../themes"

TabBar {
    id: root
    implicitWidth: contentWidth

    background: Rectangle {
        border.width: Theme.currentTheme.appearance.borderWidth  // 边框宽度 / Border Width
        border.color: Theme.currentTheme.colors.controlBorderColor
        radius: Theme.currentTheme.appearance.buttonRadius
        color: Theme.currentTheme.colors.controlAltSecondaryColor
    }
}
