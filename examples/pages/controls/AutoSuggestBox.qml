import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../../assets/"
import "../../components"

ControlPage {
    title: qsTr("AutoSuggestBox")
    badgeText: qsTr("Extra")
    badgeSeverity: Severity.Success

    // intro
    Text {
        Layout.fillWidth: true
        text: qsTr(
            "A text control that makes suggestions to users as they type. The app is notified " +
            "when text has been changed by the user and is responsible for providing relevant suggestions for " +
            "this control to display."
        )
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("A basic autosuggest TextField.")
        }
        Frame {
            width: parent.width

            RowLayout {

                AutoSuggestBox {
                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth: 200
                    model: ItemData.allControls
                    textRole: "title"

                    onAccepted: searchResult.text = text
                }

                Text {
                    id: searchResult
                    Layout.alignment: Qt.AlignLeft
                }
            }
        }
    }
}
