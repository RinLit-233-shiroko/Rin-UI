import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../../components"

ControlPage {
    title: qsTr("DropDownButton")
    badgeText: qsTr("Extra")
    badgeSeverity: Severity.Success

    // intro
    Text {
        Layout.fillWidth: true
        text: qsTr("A DropDownButton opens a Menu or Flyout when clicked. " +
                 "Assign any Popup-derived control to its flyout property.")
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("A simple DropDownButton with a Menu flyout.")
        }
        ControlShowcase {
            width: parent.width
            DropDownButton {
                text: qsTr("Email")
                enabled: !buttonSwitch.checked

                flyout: Menu {
                    MenuItem {
                        text: qsTr("Send")
                    }
                    MenuItem {
                        text: qsTr("Reply")
                    }
                    MenuItem {
                        text: qsTr("Reply All")
                    }
                }
            }

            showcase: [
                CheckBox {
                    id: buttonSwitch
                    text: qsTr("Disable DropDownButton")
                }
            ]
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("DropDownButton with Icons")
        }
        Frame {
            width: parent.width
            DropDownButton {
                icon.name: "ic_fluent_mail_20_regular"
                text: qsTr("Email")

                flyout: Menu {
                    MenuItem {
                        icon.name: "ic_fluent_send_20_filled"
                        text: qsTr("Send")
                    }
                    MenuItem {
                        icon.name: "ic_fluent_mail_arrow_up_20_regular"
                        text: qsTr("Reply")
                    }
                    MenuItem {
                        icon.name: "ic_fluent_mail_arrow_double_back_20_regular"
                        text: qsTr("Reply All")
                    }
                }
            }
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("DropDownButton with a Flyout")
        }
        Frame {
            width: parent.width
            DropDownButton {
                text: qsTr("Delete file")

                flyout: Flyout {
                    id: deleteFlyout
                    width: 350
                    position: Position.Bottom
                    text: qsTr("This action cannot be undone. \nDo you want to delete this file?")
                    buttonBox: [
                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Delete")
                            onClicked: deleteFlyout.close()
                        },
                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Hide")
                            onClicked: deleteFlyout.close()
                        },
                        Button {
                            Layout.fillWidth: true
                            highlighted: true
                            text: qsTr("Cancel")
                            onClicked: deleteFlyout.close()
                        }
                    ]
                }
            }
        }
    }
}
