import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI


ApplicationWindow {
    width: 800
    height: 600
    visible: true

    SettingCard {
        id: cd
        width: 200
        title: "我要ccb"
        Icon {
            name: "ic_fluent_accessibility_error_20_regular"
        }

        TapHandler {
            parent: cd  // 要手动指定parnet，因为settingcard的默认alias到了rightcontent
            onTapped: {
                tstdialog.open()
            }
        }

        Dialog {
            id: tstdialog
            title: "ccb?"
            Text {
                text: sbb.value
            }
            SpinBox {
                id: sbb
                value:1
                to: 222222222
            }
            standardButtons: Dialog.Ok | Dialog.Cancel
        }
    }
    SettingCard {
        anchors.centerIn: parent
            title: qsTr("App Theme")
            description: qsTr("Select which app theme to display")
            icon.name: "ic_fluent_paint_brush_20_regular"

            ComboBox {
                property var data: [Theme.mode.Light, Theme.mode.Dark, Theme.mode.Auto]
                model: ListModel {
                    ListElement { text: qsTr("Light") }
                    ListElement { text: qsTr("Dark") }
                    ListElement { text: qsTr("Use system setting") }
                }
                currentIndex: data.indexOf(Theme.getTheme())
                onCurrentIndexChanged: {
                    Theme.setTheme(data[currentIndex])
                }
            }
        }



//     Item {
//         anchors.centerIn: parent
//         width: 300
//         height: 300
//
// //         Calendar {
// //     id: calendar
// //     selectionMode: "range"
// //     rangeStart: new Date(2025, 0, 1)  // January 1, 2025
// //     rangeEnd: new Date(2025, 0, 15)   // January 15, 2025
// // }  //TODO: Page Bug
//
// //         Calendar {
// //     id: calendar
// //     selectedDate: new Date()
// //
// //     highlightedDates: [
// //         new Date(2025, 0, 10),
// //         new Date(2025, 0, 15),
// //         new Date(2025, 0, 20)
// //     ]
// //
// //     disabledDates: [
// //         new Date(2025, 0, 5),
// //         new Date(2025, 0, 25)
// //     ]
// // }
//         CalendarDatePicker {
//             id: datePicker
//             selectedDate: new Date("2027-01-01")
//         }
//     }
}
