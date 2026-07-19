import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI

FluentPage {
    title: qsTr("Settings")

    property int recentlyViewedCount: Backend.getRecentlyViewed().length
    property int favoritesCount: Backend.getFavorites().length

    Connections {
        target: Backend
        function onRecentlyViewedChanged() {
            recentlyViewedCount = Backend.getRecentlyViewed().length
        }
        function onFavoritesChanged() {
            favoritesCount = Backend.getFavorites().length
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 3
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Appearance & behavior")
        }

        SettingCard {
            width: parent.width
            title: qsTr("App Theme")
            description: qsTr("Select which app theme to display")
            icon.name: "ic_fluent_color_20_regular"

            ComboBox {
                property var data: [Theme.mode.Light, Theme.mode.Dark, Theme.mode.Auto]
                model: ListModel {
                    ListElement { text: qsTr("Light") }
                    ListElement { text: qsTr("Dark") }
                    ListElement { text: qsTr("Use system setting") }
                }
                currentIndex: data.indexOf(Theme.getTheme())
                onCurrentIndexChanged: {
                    Theme.setTheme(data[currentIndex])
                }
            }
        }

        SettingCard {
            width: parent.width
            title: qsTr("Window Backdrop Effect")
            description: qsTr("Adjust the appearance of the window background (Only available on Windows platform, some styles may only support on Windows 11)")
            icon.name: "ic_fluent_square_hint_sparkles_20_regular"

            ComboBox {
                property var data: ["mica", "acrylic", "tabbed", "none"]
                model: ListModel {
                    ListElement { text: qsTr("Mica") }
                    ListElement { text: qsTr("Acrylic") }
                    ListElement { text: qsTr("Tabbed") }
                    ListElement { text: qsTr("None") }
                }
                currentIndex: data.indexOf(Theme.getBackdropEffect())
                onCurrentIndexChanged: {
                    Theme.setBackdropEffect(data[currentIndex])
                }
            }
        }

        SettingCard {
            width: parent.width
            title: qsTr("Accent Color")
            description: qsTr("Pick the color which app highlighted color")
            icon.name: "ic_fluent_paint_brush_20_regular"

            ToolButton {
                icon.name:"ic_fluent_arrow_reset_20_regular"
                ToolTip {
                    text: qsTr("Reset")
                    visible: parent.hovered
                }
                onClicked: {
                    accentColorPicker.color ="#605ed2"
                }
            }

            DropDownColorPicker {
                id: accentColorPicker
                position: Position.Left

                color: Theme.getThemeColor()
                onColorChanged: {
                    Theme.setThemeColor(color)
                }
            }
        }

        SettingCard {
            width: parent.width
            title: qsTr("Manage samples")
            description: qsTr("Clear your recent or favorite samples")
            icon.name: "ic_fluent_grid_20_regular"

            Button {
                enabled: recentlyViewedCount > 0
                text: qsTr("Clear recents")
                onClicked: Backend.clearRecentlyViewed()
            }
            Button {
                enabled: favoritesCount > 0
                text: qsTr("Remove favorites")
                onClicked: Backend.clearFavorites()
            }
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 3
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Language")
        }

        SettingCard {
            width: parent.width
            title: qsTr("Display Language")
            description: qsTr("Set your preferred language for the gallery")
            icon.name: "ic_fluent_translate_20_regular"

            ComboBox {
                property var data: [Backend.getSystemLanguage(), "en_US", "zh_CN"]
                property bool initialized: false
                model: ListModel {
                    ListElement { text: qsTr("Use System Language") }
                    ListElement { text: "English (US)" }
                    ListElement { text: "简体中文" }
                }
                Component.onCompleted: {
                    currentIndex = data.indexOf(Backend.getLanguage())
                    initialized = true
                }

                onCurrentIndexChanged: {
                    if (initialized) {
                        Backend.setLanguage(data[currentIndex])
                    }
                }
            }
        }
    }


    Column {
        Layout.fillWidth: true
        spacing: 3
        Text {
            typography: Typography.BodyStrong
            text: qsTr("About")
        }

        SettingExpander {
            width: parent.width
            title: qsTr("RinUI Gallery")
            description: qsTr("© 2026 RinLit. All rights reserved.")
            icon.source: Qt.resolvedUrl("../assets/BA_Pic_Shiroko-chibi.png")
            icon.size: 28

            content: Text {
                color: Theme.currentTheme.colors.textSecondaryColor
                text: Backend.getVersion()
            }

            SettingItem {
                id: repo
                title: qsTr("To clone this repository")
                actionIcon.name: "ic_fluent_copy_20_regular"
                clickable: true

                TextInput {
                    id: repoUrl
                    font.family: "Consolas"
                    readOnly: true
                    text: "git clone https://github.com/RinLit-233-shiroko/Rin-UI.git"
                    wrapMode: TextInput.Wrap
                    opacity: 0.8
                }

                onClicked: {
                    Backend.copyToClipboard(repoUrl.text)
                }
            }
            SettingItem {
                title: qsTr("File a bug or request new sample")
                clickable: true
                onClicked: Qt.openUrlExternally("https://github.com/RinLit-233-shiroko/Rin-UI/issues/new/choose")

                actionIcon.name: "ic_fluent_open_20_regular"
            }
            SettingItem {
                Column {
                    Layout.fillWidth: true
                    Text {
                        text: qsTr("Dependencies & references")
                    }
                    Item {
                        width: parent.width
                        height: 6
                    }
                    Hyperlink {
                        text: qsTr("Qt & Qt Quick")
                        openUrl: "https://www.qt.io/"
                    }
                    Hyperlink {
                        text: qsTr("Fluent Design System")
                        openUrl: "https://fluent2.microsoft.design/"
                    }
                    Hyperlink {
                        text: qsTr("Fluent UI System Icons")
                        openUrl: "https://github.com/microsoft/fluentui-system-icons/"
                    }
                    Hyperlink {
                        text: qsTr("WinUI 3 Gallery")
                        openUrl: "https://github.com/microsoft/WinUI-Gallery"
                    }
                }
            }
            SettingItem {
                title: qsTr("License")
                description: qsTr("This project is licensed under the MIT license")

                Hyperlink {
                    text: qsTr("MIT License")
                    openUrl: "https://github.com/RinLit-233-shiroko/Rin-UI/blob/master/LICENSE"
                }
            }
        }
    }
}
