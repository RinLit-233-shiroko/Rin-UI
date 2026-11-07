import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../../components"

ControlPage {
    title: qsTr("SplitButton")
    badgeText: qsTr("Extra")
    badgeSeverity: Severity.Success
    property int primaryClickCount: 0

    Text {
        Layout.fillWidth: true
        text: qsTr("The SplitButton is a dropdown button, but with an addition execution hit target.")
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("A simple SplitButton with a Menu flyout.")
        }
        ControlShowcase {
            width: parent.width
            SplitButton {
                text: qsTr("Email")
                enabled: !buttonSwitch.checked
                onClicked: primaryClickCount++

                flyout: Menu {
                    MenuItem {
                        text: qsTr("Send")
                        icon.name: "ic_fluent_send_20_filled"
                    }
                    MenuItem {
                        text: qsTr("Reply")
                        icon.name: "ic_fluent_mail_arrow_up_20_regular"
                    }
                    MenuItem {
                        text: qsTr("Reply All")
                        icon.name: "ic_fluent_mail_arrow_double_back_20_regular"
                    }
                }
            }

            showcase: [
                Text {
                    typography: Typography.Caption
                    text: qsTr("Primary clicks: %1").arg(primaryClickCount)
                },
                CheckBox {
                    id: buttonSwitch
                    text: qsTr("Disable SplitButton")
                }
            ]
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("SplitButton with an icon.")
        }
        Frame {
            width: parent.width
            SplitButton {
                icon.name: "ic_fluent_mail_20_regular"
                text: qsTr("Send mail")

                flyout: Menu {
                    MenuItem {
                        text: qsTr("Send now")
                    }
                    MenuItem {
                        text: qsTr("Schedule send")
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
            text: qsTr("Accent style applied to SplitButton.")
        }
        Frame {
            width: parent.width
            SplitButton {
                highlighted: true
                text: qsTr("Create")

                flyout: Menu {
                    MenuItem {
                        text: qsTr("New document")
                    }
                    MenuItem {
                        text: qsTr("New folder")
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
            text: qsTr("SplitButton with a Flyout.")
        }
        Frame {
            width: parent.width
            SplitButton {
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
                            text: qsTr("Cancel")
                            highlighted: true
                            onClicked: deleteFlyout.close()
                        }
                    ]
                }
            }
        }
    }
}
