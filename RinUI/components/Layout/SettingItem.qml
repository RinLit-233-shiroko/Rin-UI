import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI


Frame {
    id: frame
    default property alias action: rightContent.data
    property string title
    property string description

    leftPadding: 15 + 35
    rightPadding: 15
    topPadding: 13
    bottomPadding: 13
    // implicitHeight: 62
    Layout.fillWidth: true

    background: Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.currentTheme.colors.dividerBorderColor
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        RowLayout {
            id: leftContent
            Layout.maximumWidth: parent.width * 0.6
            Layout.fillHeight: true
            spacing: 16

            Column {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    id: titleLabel
                    width: parent.width
                    typography: Typography.Body
                    text: title
                    maximumLineCount: 2  // 限制最多两行
                    elide: Text.ElideRight  // 超过限制时用省略号
                    visible: title.length > 0
                }

                Text {
                    id: descriptionLabel
                    width: parent.width
                    typography: Typography.Caption
                    text: description
                    color: Theme.currentTheme.colors.textSecondaryColor
                    wrapMode: Text.Wrap  // 启用换行
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    visible: description.length > 0
                }
            }
            visible: titleLabel.visible || descriptionLabel.visible
        }
        RowLayout {
            id: rightContent
            Layout.alignment: Qt.AlignRight
            spacing: 16
        }
    }
}
