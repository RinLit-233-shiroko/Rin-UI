import QtQuick 2.15
import QtQuick.Controls 2.15
import "../themes"
import "../components"
Button {
    id: root
    buttonType: "transparent"
    property string openUrl: root.openUrl
    textColor: Theme.currentTheme.colors.primaryColor
    underline: true
    function updateStyle() {
        // 禁用状态
        console.log("updateStyle")
        root.opacity = 1.0
        backgroundColor = "transparent"
        textColor = Theme.currentTheme.colors.primaryColor
        borderColor = "transparent"
    }
    onClicked: {
        Qt.openUrlExternally(openUrl)
    }
}