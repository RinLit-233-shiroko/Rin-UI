import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../components"
import "../assets"

FluentPage {
    title: qsTr("Basic Input")
    wrapperWidth: parent.width - 42*2

    Grid {
        Layout.fillWidth: true
        columns: Math.floor((width-12) / (300 + 6)) // 自动算列数
        rowSpacing: 12
        columnSpacing: 12
        layoutDirection: GridLayout.LeftToRight

        Repeater {
            model: ItemData.getItemsByType("basicInput")
            delegate: ControlClip { }
        }
    }
}
