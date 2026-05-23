import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI

FluentPage {
    id: fluentPage

    property url docsUrl: "https://ui.rinlit.cn/"
    property url repoUrl: "https://github.com/RinLit-233-shiroko/Rin-UI"
    property string badgeText: ""
    property string pageName: title
    property var badgeSeverity: Severity.Info

    function getSourceCodeUrl(pageName) {
        return `${repoUrl}/tree/master/examples/pages/controls/${pageName}.qml`
    }

    contentSpacing: 32

    Component.onCompleted: {
        Backend.addRecentlyViewed(fluentPage.pageName)
    }

    header: Item {
        id: container
        height: headerRow.height + 44

        ColumnLayout {
            id: headerRow
            width: Math.min(fluentPage.width - fluentPage.horizontalPadding * 2, fluentPage.wrapperWidth)  // 限制最大宽度
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 12
            anchors.bottom: parent.bottom

            RowLayout {
                spacing: 16
                Text {
                    height: parent.height
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                    typography: Typography.Title
                    text: fluentPage.title
                    visible: fluentPage.title !== ""  // 标题
                }
                InfoBadge {
                    severity: badgeSeverity
                    solid: false
                    text: badgeText
                    visible: badgeText !== ""  // 徽章
                }
            }

            // 拓展区域 //
            RowLayout {
                DropDownButton {
                    icon.name: "ic_fluent_document_20_regular"
                    text: qsTr("Documentation")
                    MenuItem {
                        text: fluentPage.title + " - " + qsTr("Rin UI Documentation")
                        onClicked: Qt.openUrlExternally(docsUrl)
                    }

                    ToolTip {
                        delay: 500
                        text: qsTr("Documentation")
                        visible: parent.hovered
                    }
                }
                DropDownButton {
                    icon.name: "ic_fluent_code_20_regular"
                    text: qsTr("Source")
                    onClicked: Qt.openUrlExternally(getSourceCodeUrl(pageName))

                    ToolTip {
                        delay: 500
                        text: qsTr("Source code of this sample page")
                        visible: parent.hovered
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                spacing: 4
                ToolButton {
                    icon.name: "ic_fluent_brightness_high_20_filled"
                    ToolTip {
                        delay: 500
                        text: qsTr("Toggle theme")
                        visible: parent.hovered
                    }
                    onClicked: {
                        console.log(Theme.currentTheme.isDark)
                        if (Theme.currentTheme.isDark) {
                            Theme.setTheme("Light")
                        } else {
                            Theme.setTheme("Dark")
                        }
                    }
                }

                ToolSeparator { }

                ToolButton {
                    icon.name: "ic_fluent_person_feedback_20_regular"
                    onClicked: Qt.openUrlExternally("https://github.com/RinLit-233-shiroko/Rin-UI/issues/new/choose")

                    ToolTip {
                        delay: 500
                        text: qsTr("Send feedback")
                        visible: parent.hovered
                    }
                }

                ToolButton {  // favorite
                    id: favoriteButton
                    icon.name: highlighted ? "ic_fluent_star_20_filled" : "ic_fluent_star_20_regular"
                    onClicked: {
                        highlighted = Backend.toggleFavorite(fluentPage.pageName)
                    }
                    highlighted: Backend.isFavorite(fluentPage.pageName)

                    Connections {
                        target: Backend
                        function onFavoritesChanged() {
                            favoriteButton.highlighted = Backend.isFavorite(fluentPage.pageName)
                        }
                    }

                    ToolTip {
                        delay: 500
                        text: parent.highlighted ? qsTr("Remove from favorite") : qsTr("Add to favorite")
                        visible: parent.hovered
                    }
                }
            }
        }
    }
}
