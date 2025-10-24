import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"


MenuSeparator {
    id: root
    Layout.fillWidth: true

    contentItem: Rectangle {
        implicitHeight: 1
        color: Theme.currentTheme.colors.dividerBorderColor
    }
}
