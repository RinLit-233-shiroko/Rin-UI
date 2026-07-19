import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI


Frame {
    id: frame
    default property alias action: rightContent.data
    property string title
    property string description
    property bool showDivider: true
    property alias actionIcon: actIcon

    readonly property bool _roundsContentEdge: parent
        && parent.roundContentEdgeItems
        && parent.children.filter(function(item) {
            return item && item._isSettingItem
        }).length > 0
    readonly property bool _roundTop: _roundsContentEdge
        && parent.directionUp
        && parent.children.filter(function(item) {
            return item && item._isSettingItem
        })[0] === frame
    readonly property bool _roundBottom: _roundsContentEdge
        && !parent.directionUp
        && parent.children.filter(function(item) {
            return item && item._isSettingItem
        }).slice(-1)[0] === frame
    property bool _isSettingItem: true

    signal clicked()
    property bool clickable: false  // 需要手动启用
    hoverable: clickable  // hover效果

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    radius: 0
    topLeftRadius: _roundTop ? Theme.currentTheme.appearance.smallRadius : 0
    topRightRadius: _roundTop ? Theme.currentTheme.appearance.smallRadius : 0
    bottomLeftRadius: _roundBottom ? Theme.currentTheme.appearance.smallRadius : 0
    bottomRightRadius: _roundBottom ? Theme.currentTheme.appearance.smallRadius : 0
    border.color: "transparent"
    // implicitHeight: 62
    Layout.fillWidth: true

    TapHandler {
        id: tapHandler
        enabled: clickable
        onTapped: clicked()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.minimumHeight: 32

            Layout.leftMargin: 58
            Layout.rightMargin: clickable ? 15 : 44
            Layout.topMargin: 9
            Layout.bottomMargin: 9
            Layout.fillWidth: true
            spacing: 16

            RowLayout {
                id: leftContent
                Layout.fillWidth: true
                Layout.maximumWidth: parent.width * 0.6
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        id: titleLabel
                        Layout.fillWidth: true
                        typography: Typography.Body
                        text: title
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        visible: title.length > 0
                    }

                    Text {
                        id: descriptionLabel
                        Layout.fillWidth: true
                        typography: Typography.Caption
                        text: description
                        color: Theme.currentTheme.colors.textSecondaryColor
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        visible: description.length > 0
                    }
                }
                visible: titleLabel.visible || descriptionLabel.visible
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                id: rightContent
                spacing: 16
            }

            Icon {
                id: actIcon
                name: "ic_fluent_chevron_right_20_regular"
                size: 16
                bold: true
                visible: clickable
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.currentTheme.isDark ? Qt.alpha("#000000", 0.25) : Theme.currentTheme.colors.controlBorderColor
            visible: frame.showDivider && !frame._roundBottom
        }
    }

    opacity: tapHandler.pressed ? 0.6 : 1
}
