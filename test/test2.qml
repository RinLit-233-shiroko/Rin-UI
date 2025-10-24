import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import RinUI


ApplicationWindow {
    width: 640
    height: 480
    visible: true
    title: qsTr("Example")

    Row {
        Component.onCompleted: {
            console.log(Colors.light.controlBorderStrongColor)
            console.log(Colors.dark.controlBorderStrongColor)
            console.log(Colors.proxy.controlBorderStrongColor)
        }
        Rectangle {
            width: 50
            height: 50
            color: Colors.get("captionCloseColor")
        }
        Rectangle {
            width: 50
            height: 50
            color: Theme.currentTheme.colors.captionCloseColor
        }
    }

    // 题1
    // RowLayout {
    //     anchors.centerIn: parent
    //     spacing: 10
    //
    //     RoundButton {
    //         width: 100
    //         height: 100
    //         text: "Take action"
    //     }
    //     RoundButton {
    //         width: 100
    //         height: 100
    //         text: "Cancel action"
    //     }
    // }
    Row {
        anchors.centerIn: parent

        ListView {
    width: 350
    height: 300
    model: ListModel {
        ListElement { titleText: "Meeting Notes"; dateText: "Yesterday"; iconSymbol: "ic_fluent_document_20_regular" }
        ListElement { titleText: "Project Alpha"; dateText: "2023-10-26"; iconSymbol: "ic_fluent_folder_20_regular" }
        ListElement { titleText: "Quick Reminder"; dateText: "10:30 AM"; iconSymbol: "ic_fluent_alert_20_regular" }
    }

    delegate: ListViewDelegate {
        // width is typically bound to ListView.view.width by the delegate itself
        // height is adaptive by default (contents.implicitHeight + 20)

        leftArea: IconWidget {
            icon: model.iconSymbol // Access model data for the icon
            size: 22
            Layout.alignment: Qt.AlignVCenter // Aligns icon within the Row of leftArea
        }

        middleArea: [ // middleArea takes a list of items for its ColumnLayout
            Text {
                text: model.titleText // Main text from model
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            },
            Text {
                text: model.dateText // Secondary text from model
                font.pixelSize: 12
                color: Theme.currentTheme.colors.textSecondaryColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        ]

        rightArea: ToolButton { // Example: a ToolButton on the right
            icon.name: "ic_fluent_chevron_right_20_regular"
            flat: true
            size: 16
            Layout.alignment: Qt.AlignVCenter // Aligns button within the RowLayout of rightArea
            onClicked: {
                console.log("More options for:", model.titleText);
            }
        }

        onClicked: {
            console.log("Clicked on item:", model.titleText);
            // ListView.view.currentIndex is automatically updated by the delegate's default onClicked handler
        }
    }
}
    }

    property var subjects: ["Chinese", "Math", "English"]

    // 题2
    // Column {
    //     anchors.centerIn: parent
    //     ListView {
    //         id: subjectMgr
    //         width: 300
    //         height: 200
    //         model: subjects
    //     }
    //     Row {
    //         spacing: 10
    //         TextField {
    //             id: subjectName
    //             placeholderText: "Subject Name"
    //         }
    //
    //         Button {
    //             highlighted: true
    //             text: "Add"
    //             onClicked: {
    //                 subjects.push(subjectName.text)
    //                 console.log(subjects)
    //             }
    //         }
    //         Button {
    //             text: "Remove"
    //             onClicked: subjects.splice(subjectMgr.currentIndex, 1)
    //         }
    //     }
    // }

    // 题3
    // Item {
    //     signal clicked()
    //     property string text: "Button"
    //
    //     width: 100
    //     height: 32
    //     Rectangle {
    //         anchors.fill: parent
    //         color: "lightgray"
    //     }
    //     Text {
    //         anchors.centerIn: parent
    //         text: parent.text
    //     }
    //     MouseArea {
    //         anchors.fill: parent
    //         onClicked: clicked
    //     }
    // }
}
