import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../../components"

ControlPage {
    title: qsTr("PageIndicator")

    // intro
    Text {
        Layout.fillWidth: true
        text: qsTr(
            "A PageIndicator allows the user to navigate through a paginated collection and is independent " +
            "of the content shown. Use this control when content in the layout is not explicitly ordered by " +
            "relevancy or you desire a glyph-based representation of numbered pages. PageIndicator are commonly" +
            "used in photo viewers, app list, carousels, and when display space is limited."
        )
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("PageIndicator integrated with a SwipeView")
        }
        Frame {
            width: parent.width
            ColumnLayout {
                SwipeView {
                    id: view
                    clip: true
                    currentIndex: 0
                    Layout.preferredWidth: 400
                    Layout.preferredHeight: 270
                    onCurrentIndexChanged: pageIndicator.currentIndex = currentIndex

                    Rectangle {
                        color: "red"
                    }
                    Rectangle {
                        color: "blue"
                    }
                    Rectangle {
                        color: "purple"
                    }
                    Rectangle {
                        color: "green"
                    }
                    Rectangle {
                        color: "cyan"
                    }
                }

                PageIndicator {
                    id: pageIndicator
                    interactive: true
                    count: view.count
                    currentIndex: view.currentIndex
                    caret: true
                    onCurrentIndexChanged: view.currentIndex = currentIndex

                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("PageIndicator with switch to change its button visibility")
        }
        ControlShowcase {
            width: parent.width

            PageIndicator {
                count: 8
                interactive: true
                caret: caretSwitch.checked
            }
            showcase: [
                Text {
                    text: qsTr("Caret")
                },
                Row {
                    spacing: 32
                    Switch {
                        id: caretSwitch
                        checked: true
                    }
                }
            ]
        }
    }
}
