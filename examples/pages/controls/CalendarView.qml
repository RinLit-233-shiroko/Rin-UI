import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import RinUI as RUI
import "../../components"

ControlPage {
    title: qsTr("CalendarView")
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
            "CalendarView shows a month grid with Mon-first toggle. " +
            "Supports selecting a single date, and clicking twice to select a range, " +
            "and marking dates as highlighted or disabled."
        )
    }

    // Simple CalendarView demo
    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("A simple CalendarView with Mon-first toggle.")
        }
        ControlShowcase {
            width: parent.width
            padding: 18

            RUI.CalendarView {
                id: cal1
                useISOWeek: isoSwitch.checked
                selectionMode: modeSwitch.checked ? "range" : "single"
                onDateSelected: (d) => { selText.text = qsTr("Selected: ") + d.toDateString(); dateInput.text = fmtDate(d) }
                onRangeSelected: (s, e) => selText.text = qsTr("Range: ") + s.toDateString() + " ~ " + e.toDateString()
            }

            // 日期选择弹出层
            Popup {
                id: datePopup
                x: 0; y: 0
                implicitWidth: 300
                implicitHeight: pickerCal.implicitHeight
                padding: 0
                closePolicy: Popup.CloseOnPressOutside

                RUI.CalendarView {
                    id: pickerCal
                    anchors.fill: parent
                    selectionMode: "single"
                    onDateSelected: (d) => {
                        dateInput.text = fmtDate(d)
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
                    text: qsTr("Use ISO Week (Mon-first)")
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
                // Date Field example moved to a dedicated panel below

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
            text: qsTr("Date Field with calendar popup")
        }
        Frame {
            width: parent.width
            padding: 18

            Row {
                spacing: 8
                Text { text: qsTr("Date Field") }
                Item {
                    id: dateFieldPanel
                    width: dateInput.implicitWidth
                    height: dateInput.implicitHeight

                    RUI.TextField {
                        id: dateInput
                        anchors.fill: parent
                        readOnly: true
                        clearEnabled: false
                        placeholderText: qsTr("YYYY-MM-DD")
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: datePicker.open()
                    }

                    // 在字段上弹出
                    Popup {
                        id: datePicker
                        implicitWidth: 300
                        implicitHeight: inlineCal.implicitHeight
                        padding: 0
                        closePolicy: Popup.CloseOnPressOutside
                        position: Position.Top

                        RUI.CalendarView {
                            id: inlineCal
                            anchors.fill: parent
                            selectionMode: "single"
                            onDateSelected: (d) => {
                                dateInput.text = fmtDate(d)
                                datePicker.close()
                            }
                        }
                    }
                }
            }
        }
    }
}