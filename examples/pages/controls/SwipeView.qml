import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../../components"

ControlPage {
    title: qsTr("SwipeView")

    // intro
    Text {
        Layout.fillWidth: true
        text: qsTr(
            "The SwipeView lets you swipe through a collection of items, one at a time. It's great for displaying images from a gallery, pages of a magazine, or similar items."
        )
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("A simple SwipeView with items.")
        }
        Frame {
            width: parent.width
            height: 300

            SwipeView {
                width: 400
                height: 270

                Image {
                    fillMode: Image.PreserveAspectCrop
                    source: "../../assets/images/cities2.png"
                }
                Image {
                    fillMode: Image.PreserveAspectCrop
                    source: "../../assets/images/nte.png"
                }
                Image {
                    fillMode: Image.PreserveAspectCrop
                    source: "../../assets/images/port.png"
                }
                Image {
                    fillMode: Image.PreserveAspectCrop
                    source: "../../assets/129201829_p0.png"
                }
            }
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("Vertical SwipeView")
        }
        Frame {
            width: parent.width
            height: 300

            SwipeView {
                orientation: Qt.Vertical
                width: 400
                height: 270

                Image {
                    fillMode: Image.PreserveAspectCrop
                    source: "../../assets/images/cities2.png"
                }
                Image {
                    fillMode: Image.PreserveAspectCrop
                    source: "../../assets/images/nte.png"
                }
                Image {
                    fillMode: Image.PreserveAspectCrop
                    source: "../../assets/images/port.png"
                }
                Image {
                    fillMode: Image.PreserveAspectCrop
                    source: "../../assets/129201829_p0.png"
                }
            }
        }
    }
}
