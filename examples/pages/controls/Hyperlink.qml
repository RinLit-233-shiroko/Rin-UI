import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../../components"

ControlPage {
    title: qsTr("Hyperlink")
    badgeText: qsTr("Extra")
    badgeSeverity: Severity.Success

    // intro
    Text {
        Layout.fillWidth: true
        text: qsTr("A Hyperlink appears as a text hyperlink. When a user clicks it, it opens the page " +
                 "you specify in the NavigateUri property in the default browser. Or you can " +
                 "handle its Click event, typically to navigate within your app.")
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("A hyperlink that navigates to a URL")
        }
        ControlShowcase {
            width: parent.width
            Hyperlink {
                // anchors.verticalCenter: parent.verticalCenter
                text: qsTr("RinUI home page")
                openUrl: "https://ui.rinlit.cn/"
                enabled: !buttonSwitch.checked
            }

            showcase: [
                CheckBox {
                    id: buttonSwitch
                    text: qsTr("Disable Hyperlink")
                }
            ]
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("A hyperlink that handles a Click event")
        }
        Frame {
            width: parent.width
            // height: 100
            Hyperlink {
                // anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Back to gallery home page")
                onClicked: { 
                    window.navigationView.safePush(Qt.resolvedUrl("../Home.qml"), true)
                }
            }
        }
    }
}
