import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI

Clip {
    width: 300
    height: 96
    radius: 8

    InfoBadge {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 12
        width: 8
        height: 8
        text: " "
        visible: (modelData.added !== undefined && modelData.added)
            || (modelData.updated !== undefined && modelData.updated)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 8
        // anchors.bottomMargin: 12
        spacing: 16

        Image {
            Layout.topMargin: 12
            Layout.alignment: Qt.AlignTop
            source: modelData.icon
            fillMode: Image.PreserveAspectFit
            // layout内部宽高
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
        }
        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            //标题
            Text {
                width: parent.width
                typography: Typography.BodyStrong
                font.pixelSize: 13
                text: modelData.title
            }
            // 描述
            Text {
                width: parent.width
                height: 52
                typography: Typography.Caption
                // font.pixelSize: 11
                color: Theme.currentTheme.colors.textSecondaryColor
                text: modelData.desc
                elide: Text.ElideRight
            }
        }
    }

    onClicked: {
        navigationView.safePush(modelData.page)
    }
}
