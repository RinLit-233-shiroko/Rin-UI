import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../../components"

ControlPage {
    title: qsTr("SettingCard")
    badgeText: qsTr("Extra+")
    badgeSeverity: Severity.Success

    // intro
    Text {
        Layout.fillWidth: true
        text: qsTr(
            "SettingsCard is a control that can be used to display settings in your experience. "
        )
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("SettingCards with actions in the ColumnLayout")
        }
        ControlShowcase {
            width: parent.width

            ColumnLayout {
                enabled: !cardsSwitch.checked
                width: parent.width
                spacing: 4

                SettingCard {
                    title: qsTr("A SettingCard within an SettingExpander")
                    Layout.fillWidth: true

                    Button {
                        text: qsTr("Button")
                    }
                }

                SettingCard {
                    Layout.fillWidth: true
                    icon.name: "ic_fluent_launcher_settings_20_regular"
                    title: "This is Title"
                    description: "This is default card, with the Title, Icon, Description, and Action property."

                    ComboBox {
                        model: [
                            "Option 1",
                            "Option 2",
                            "Option 3"
                        ]
                    }
                }

                SettingCard {
                    Layout.fillWidth: true
                    icon.source: Qt.resolvedUrl("../../assets/gallery.png")
                    title: "Icon Options"
                    description: "You can use \"icon.name\" or \"icon.source\" to set the card\'s Icon"

                    Switch {}
                }

                SettingCard {
                    Layout.fillWidth: true
                    icon.name: "ic_fluent_globe_20_regular"
                    title: "A clickable SettingCard"
                    description: "A SettingCard can be clickable if you set \"clickable\" property is true."

                    clickable: true
                    onClicked: {
                        Qt.openUrlExternally("https://ui.rinlit.cn")
                    }

                    Text {
                        color: Colors.proxy.textSecondaryColor
                        text: "Addition content"
                    }
                }

                SettingCard {
                    Layout.fillWidth: true
                    icon.name: "ic_fluent_globe_20_regular"
                    title: "Customizing the ActionIcon"

                    actionIcon.name: "ic_fluent_open_20_regular"
                    clickable: true
                    onClicked: {
                        Qt.openUrlExternally("https://ui.rinlit.cn")
                    }

                }
            }

            showcase: [
                Switch {
                    id: cardsSwitch
                    text: qsTr("Disable SettingCards")
                },
            ]
        }
    }
}
