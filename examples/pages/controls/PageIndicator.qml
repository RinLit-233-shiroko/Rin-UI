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
                    currentIndex: pageIndicator.currentIndex
                    Layout.preferredWidth: 400
                    Layout.preferredHeight: 270
                    clip: true

                    Page {
                        title: qsTr("Home")
                    }
                    Page {
                        title: qsTr("Discover")
                    }
                    Page {
                        title: qsTr("Activity")
                    }
                }

                PageIndicator {
                    id: pageIndicator
                    interactive: true
                    count: view.count
                    currentIndex: view.currentIndex
                    carel: true

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
                carel: carelSwitch.checked
            }
            showcase: [
                Text {
                    text: qsTr("Carel")
                },
                Row {
                    spacing: 32
                    Switch {
                        id: carelSwitch
                        checked: true
                    }
                }
            ]
        }
    }
}
