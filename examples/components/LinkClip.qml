import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI

Clip {
    width: 220
    height: 216
    radius: Appearance.proxy.windowRadius

    // corner sign
    IconWidget {
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 12
        }
        size: 18
        icon: "ic_fluent_open_20_regular"

        smooth: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

        Image {
            Layout.alignment: Qt.AlignVCenter
            source: modelData.icon
            fillMode: Image.PreserveAspectFit
            // layout内部宽高
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
        }

        Column {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            Text {
                width: parent.width
                typography: Typography.BodyLarge
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
        // url jump
        Qt.openUrlExternally(modelData.url)
    }
}
