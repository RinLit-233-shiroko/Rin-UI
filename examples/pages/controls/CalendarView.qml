import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 2.15
import QtQml 2.15
import RinUI
import "../../components"

ControlPage {
    title: qsTr("Calendar")
    badgeText: qsTr("New")
    badgeSeverity: Severity.Success

    // 辅助函数：格式化日期为 YYYY-MM-DD
    function fmtDate(d) {
        if (!d) return "";
        var y = d.getFullYear();
        var m = ("0" + (d.getMonth() + 1)).slice(-2);
        var day = ("0" + d.getDate()).slice(-2);
        return y + "-" + m + "-" + day;
    }

    // Intro
    Text {
        Layout.fillWidth: true
        text: qsTr(
            "Calendar shows a month grid with Mon-first toggle. " +
            "Supports selecting a single date, and clicking twice to select a range, " +
            "and marking dates as highlighted or disabled."
        )
    }

    // Simple Calendar demo
    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("A simple Calendar with Mon-first toggle.")
        }
        ControlShowcase {
            width: parent.width
            padding: 18

            Calendar {
                id: cal1
                useISOWeek: isoSwitch.checked
                selectionMode: modeSwitch.checked ? "range" : "single"
                onDateSelected: (d) => { selText.text = qsTr("Selected: ") + d.toDateString() }
            }

            // 日期选择弹出层
            Popup {
                id: datePopup
                x: 0; y: 0
                implicitWidth: 300
                implicitHeight: pickerCal.implicitHeight
                padding: 0
                closePolicy: Popup.CloseOnPressOutside

                Calendar {
                    id: pickerCal
                    anchors.fill: parent
                    selectionMode: "single"
                    onDateSelected: (d) => {
                        cal1.selectedDate = d
                        cal1.displayYear = d.getFullYear()
                        cal1.displayMonth = d.getMonth() + 1
                        datePopup.close()
                    }
                }
            }

            showcase: [
                CheckBox {
                    id: isoSwitch
                    text: qsTr("Use ISO Week")
                    checked: true
                },
                Switch {
                    id: modeSwitch
                    checkedText: qsTr("Range")
                    uncheckedText: qsTr("Single")
                    onToggled: {
                        cal1.selectionMode = checked ? "range" : "single"
                        if (!checked) { // 切回单选清理范围
                            cal1.rangeStart = null
                            cal1.rangeEnd = null
                        }
                    }
                },
                Button {
                    text: qsTr("Today")
                    onClicked: cal1.resetToToday()
                },
                Button {
                    text: qsTr("Highlight Today")
                    onClicked: cal1.highlightedDates = [new Date()]
                },
                Button {
                    text: qsTr("Disable 1st and 15th")
                    onClicked: {
                        const y = cal1.displayYear, m = cal1.displayMonth - 1
                        cal1.disabledDates = [new Date(y, m, 1), new Date(y, m, 15)]
                    }
                },
                Text {
                    id: selText
                    typography: Typography.Body
                    text: qsTr("Selected: none")
                },

             
                Text { text: qsTr("Minimum Date") },
                CalendarDatePicker {
                    onDateSelected: function(d) { cal1.minimumDate = d }
                },
                Text { text: qsTr("Maximum Date") },
                CalendarDatePicker {
                    onDateSelected: function(d) { cal1.maximumDate = d }
                }
            ]
        }
    }

    // Date Field panel: 点击字段弹出日历并填写
    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("CalendarDatePicker (Button popup)")
        }
        Frame {
            width: parent.width
            padding: 18

            RowLayout {
                spacing: 8
                Text { text: qsTr("CalendarDatePicker") }
                CalendarDatePicker {
                    id: datePicker
                    useISOWeek: isoSwitch.checked
                    weekNumbersVisible: true
                    onDateSelected: (d) => selText.text = qsTr("Selected: ") + d.toDateString()
                }
                CheckBox {
                    text: qsTr("Show week numbers")
                    checked: datePicker.weekNumbersVisible
                    onToggled: datePicker.weekNumbersVisible = checked
                }
                Button {
                    text: qsTr("Today")
                    onClicked: datePicker.resetToToday()
                }
            }
        }
    }
}