import QtQuick
import QtQuick.Controls
import QtQuick.Window as QQW
import QtQuick.Layouts
import QtQuick.Window
import RinUI


Window {
    width: 800
    height: 600
    visible: true

    Text{
        text: "Hello World"
        anchors.centerIn: parent
        font.bold: true
    }

    SettingCard {
        width: 400
        icon.name: "ic_fluent_settings_20_regular"
        title: "Name"
        description: "Enter your name"

        // TextField {
        //
        //     id: textField
        // }
    }

    Button {
        text: "Open Window"
        Menu {
            id: menu
            MenuItem {
                text: "Sub Window"
                onClicked: {
                    subWindow.show()
                }
            }
            MenuItem {
                text: "Sub Window 2"
                onClicked: {
                    subWindow2.show()
                }
            }
            MenuItem {
                text: "Sub Window 3"
                onClicked: {
                    subWindow3.open()
                }
            }
        }
        onClicked: {
            menu.open()
        }
    }


    Item {
        QQW.Window {
            id: subWindow
            width: 400
            height: 400

            SettingCard {
        Layout.fillWidth: true
        icon.name: "ic_fluent_settings_20_regular"
        title: "Name"
        description: "Enter your name"

        // TextField {
        //
        //     id: textField
        // }
    }
        }

        Window {
            id: subWindow2
            width: 400
            height: 400
            title: "Sub Window 2"

            SettingCard {
        Layout.fillWidth: true
        icon.name: "ic_fluent_settings_20_regular"
        title: "Name"
        description: "Enter your name"

        // TextField {
        //
        //     id: textField
        // }
    }
        }
        Dialog {
            id: subWindow3
            width: 400
            height: 400
            standardButtons: Dialog.Ok | Dialog.Cancel
            SettingCard {
        Layout.fillWidth: true
        // icon.name: "ic_fluent_settings_20_regular"
        title: "Name"
        // description: "Enter your name"

        // TextField {
        //
        //     id: textField
        // }
    }
        }
    }
}
