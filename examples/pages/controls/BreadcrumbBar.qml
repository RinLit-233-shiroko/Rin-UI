import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../../components"

ControlPage {
    id: page
    title: qsTr("BreadcrumbBar")
    badgeText: qsTr("Extra")
    badgeSeverity: Severity.Success

    property var trail: [
        qsTr("Home"),
        qsTr("Documents"),
        qsTr("Design"),
        qsTr("Northwind"),
        qsTr("Images"),
        qsTr("Folder1"),
        qsTr("Folder2"),
        qsTr("Folder3")
    ]

    Text {
        Layout.fillWidth: true
        text: qsTr("The BreadcrumbBar control provides a common horizontal layout to display the trail " +
                   "of navigation taken to the current location. Resize to see the nodes crumble, " +
                   "starting at the root.")
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("A BreadcrumbBar control with a custom size.")
        }

        ControlShowcase {
            width: parent.width
            height: 72

            BreadcrumbBar {
                width: parent.width
                size: sizeComboBox.currentIndex === 1 ? BreadcrumbBar.Large : BreadcrumbBar.Standard
                items: page.trail
                onItemClicked: function (index) { currentIndex = index }
            }

            showcase: [
                Item {
                    width: parent.width
                    height: parent.height

                    RowLayout {
                        width: parent.width
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            text: qsTr("Size")
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ComboBox {
                            id: sizeComboBox
                            Layout.fillWidth: true
                            model: [qsTr("Standard"), qsTr("Large (Custom)")]
                        }
                    }
                }
            ]
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("A BreadcrumbBar control")
        }

        Frame {
            width: parent.width
            height: 72

            BreadcrumbBar {
                width: parent.width - 32
                anchors.centerIn: parent
                items: page.trail
                onItemClicked: function (index) { currentIndex = index }
            }
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("BreadCrumbBar Control with custom item data")
        }

        ControlShowcase {
            width: parent.width
            height: 72

            BreadcrumbBar {
                id: boundBar
                width: parent.width
                items: [
                    { title: qsTr("This PC") },
                    { title: qsTr("Local Disk (C:)") },
                    { title: qsTr("Users") },
                    { title: qsTr("Public") },
                    { title: qsTr("Documents") }
                ]
                onItemClicked: function (index) { currentIndex = index }
            }

            showcase: [
                Item {
                    width: parent.width
                    height: parent.height

                    Button {
                        anchors.centerIn: parent
                        text: qsTr("Reset sample")
                        onClicked: boundBar.currentIndex = boundBar.items.length - 1
                    }
                }
            ]
        }
    }
}
