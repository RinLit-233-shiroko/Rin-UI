import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../components"
import "../assets"

FluentPage {
    title: qsTr("Text")
    wrapperWidth: parent.width - 42*2

    Grid {
        Layout.fillWidth: true
        columns: Math.floor((width-12) / (300 + 6))// 自动算列数
        rowSpacing: 12
        columnSpacing: 12
        layoutDirection: GridLayout.LeftToRight

        Repeater {
            model: ItemData.getItemsByType("text")
            delegate: ControlClip { }
        }
    }
}

// import QtQuick 2.15
// import QtQuick.Controls 2.15
// import QtQuick.Layouts 2.15
// import RinUI
// import "../components"
//
// FluentPage {
//     title: "Text & Typography"
//
//     // text field example
//     Column {
//         Layout.fillWidth: true
//         spacing: 4
//
//         Text {
//             typography: Typography.Subtitle
//             text: qsTr("TextField")
//         }
//         Text {
//             width: parent.width
//             typography: Typography.Body
//             text: qsTr("Use a TextField to let a user enter simple text input in your app.")
//         }
//
//         Frame {
//             width: parent.width
//
//             Row {
//                 width: parent.width
//                 spacing: 4
//                 TextField {
//                     placeholderText: "A simple TextField."
//                 }
//                 TextField {
//                     placeholderText: "A simple TextField."
//                 }
//             }
//         }
//     }
//
//     // typo
//     Column {
//         Layout.fillWidth: true
//         spacing: 4
//
//         Text {
//             typography: Typography.Subtitle
//             text: qsTr("Typography")
//         }
//         Text {
//             width: parent.width
//             typography: Typography.Body
//             text: qsTr("Use a TextField to let a user enter simple text input in your app.")
//         }
//
//         Frame {
//             width: parent.width
//
//             Column {
//                 Text {
//                     typography: Typography.Caption
//                     text: qsTr("Caption")
//                 }
//                 Text {
//                     typography: Typography.Body
//                     text: qsTr("Body")
//                 }
//                 Text {
//                     typography: Typography.BodyLarge
//                     text: qsTr("Body Large")
//                 }
//                 Text {
//                     typography: Typography.Subtitle
//                     text: qsTr("Subtitle")
//                 }
//                 Text {
//                     typography: Typography.Title
//                     text: qsTr("Title")
//                 }
//                 Text {
//                     typography: Typography.TitleLarge
//                     text: qsTr("Title Large")
//                 }
//                 Text {
//                     typography: Typography.Display
//                     text: qsTr("Display")
//                 }
//             }
//         }
//     }
// }
