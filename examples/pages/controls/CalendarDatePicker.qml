import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 2.15
import QtQml 2.15
import RinUI
import "../../components"

ControlPage {
    title: qsTr("CalendarDatePicker")
    badgeText: qsTr("Extra")
    badgeSeverity: Severity.Success


    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("CalendarDatePicker with placeholder text")
        }
        Frame {
            width: parent.width
            padding: 18

            ColumnLayout {
                spacing: 8
                Text { text: qsTr("Calendar") }

                CalendarDatePicker {
                    id: datePicker
                    // useISOWeek: isoSwitch.checked
                    // weekNumbersVisible: true
                    // onDateSelected: (d) => selText.text = qsTr("Selected: ") + d.toDateString()
                }
            }
        }
    }
}
