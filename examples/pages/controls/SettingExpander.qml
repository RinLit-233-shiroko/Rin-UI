import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../../components"

ControlPage {
    title: qsTr("SettingExpander")
    badgeText: qsTr("Extra+")
    badgeSeverity: Severity.Success

    // intro
    Text {
        Layout.fillWidth: true
        text: qsTr(
            "The SettingExpander has a header like SettingCard and can expand to show a body with content. " +
            "Use the SettingItem to add items to the body."
        )
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("An Expander with ComboBox in the header and SettingItems")
        }
        ControlShowcase {
            width: parent.width

            SettingExpander {
                id: expander1
                width: parent.width

                expanded: expandStateSwitch.checked
                enabled: !expanderSwitch.checked
                expandDirection: expandDirectionCombobox.currentIndex === 0
                    ? Expander.Up : Expander.Down

                icon.name: "ic_fluent_box_20_regular"
                title: qsTr("SettingExpander")
                description: qsTr(
                    "The SettingExpander has the same properties as SettingCard, " +
                    "and you can set SettingItem as part of the Items collection."
                )

                // header 中的按钮
                content: ComboBox {
                    model: ["Option 1", "Option 2", "Option 3"]
                }

                // 折叠内容
                SettingItem {
                    title: qsTr("A SettingItem within an SettingExpander")


                    Button {
                        text: qsTr("Button")
                    }
                }
                SettingItem {
                    title: qsTr("This SettingItem can be clicked")
                    description: qsTr("SettingCard control can be clicked too!")
                    clickable: true
                }
                SettingItem {
                    Column {
                        Layout.fillWidth: true
                        CheckBox {
                            width: parent.width
                            text: qsTr("A CheckBox within an SettingExpander")
                        }
                        CheckBox {
                            width: parent.width
                            text: qsTr("A CheckBox within an SettingExpander")
                        }
                    }
                }
                SettingItem {
                    title: qsTr("SettingItem")
                    description: qsTr("ItemType: Switch")

                    Switch {}
                }
                SettingItem {
                    title: qsTr("Test")
                    description: qsTr("ItemType: Hyperlink")

                    Hyperlink {
                        text: qsTr("What is BlueArchive?")
                        openUrl: "https://bluearchive.nexon.com/"
                    }
                }
            }

            showcase: [
                Switch {
                    id: expanderSwitch
                    text: qsTr("Disable Expander")
                },
                Switch {
                    id: expandStateSwitch
                    text: qsTr("Expanded")
                    checked: expander1.expanded
                    onCheckedChanged: expander1.expanded = checked
                },
                Text {
                    text: qsTr("ExpandDirection")
                },
                ComboBox {
                    id: expandDirectionCombobox
                    model: ["Up", "Down"]
                    currentIndex: 1
                }
            ]
        }
    }
}
