import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import "../../themes"
import "../../components"


ToolSeparator {
    padding: vertical ? 2 : 2
    topPadding: vertical ? 2 : 2
    bottomPadding: vertical ? 2 : 2

    contentItem: Rectangle {
        implicitWidth: parent.vertical ? 1 : 16
        implicitHeight: parent.vertical ? 16 : 1
        color: Theme.currentTheme.colors.dividerBorderColor
    }
}
