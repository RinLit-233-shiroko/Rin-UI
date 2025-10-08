import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI

Clip {
    width: 360
    height: 88

    InfoBadge {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 12
        width: 8
        height: 8
        text: "·"
        visible: (modelData.added !== undefined && modelData.added)
            || (modelData.updated !== undefined && modelData.updated)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        spacing: 16

        Image {
            Layout.alignment: Qt.AlignVCenter
            source: modelData.icon
            fillMode: Image.PreserveAspectFit
            // layout内部宽高
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
        }
        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Text {
                width: parent.width
                typography: Typography.BodyStrong
                font.pixelSize: 13
                text: modelData.title
            }
            Text {
                width: parent.width
                typography: Typography.Caption
                // font.pixelSize: 11
                color: Theme.currentTheme.colors.textSecondaryColor
                text: modelData.desc
            }
        }
    }

    onClicked: {
        navigationView.safePush(modelData.page)
    }
}
