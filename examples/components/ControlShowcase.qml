import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI


// 自定义控件演示 / Custom control demonstration //
Frame {
    id: frame
    default property alias content: controlContainer.data
    property alias showcase: showcaseContainer.data

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    spacing: 4

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Column {
            id: controlContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 20
            spacing: frame.spacing
        }

        Rectangle {
            id: right
            width: 200
            Layout.fillHeight: true
            implicitHeight: showcaseContainer.implicitHeight + 2 * 16
            radius: Theme.currentTheme.appearance.smallRadius
            color: Theme.currentTheme.colors.backgroundAcrylicColor
            border.width: Theme.currentTheme.appearance.borderWidth
            border.color: Theme.currentTheme.colors.cardBorderColor

            Column {
                id: showcaseContainer
                anchors.fill: parent
                anchors.margins: 16
                spacing: 4
            }
        }
    }
}
