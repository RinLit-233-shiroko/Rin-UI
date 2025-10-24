import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"

Button {
    id: timePickerButton

    property string amText: qsTr("AM")
    property string pmText: qsTr("PM")
    property string hourText: qsTr("hour")
    property string minuteText: qsTr("minute")

    // 是否使用24小时制
    property bool use24Hour: false

    property alias hour: pickerView.value1
    property alias minute: pickerView.value2
    property alias hourSystem: pickerView.value3

    implicitWidth: 250
    padding: 0

    // 获取 / 设置时间 // Get / Set time (hh:mm)
    // 获取 / 设置时间 (hh:mm)
    property string time: {
        if (!pickerView.gotData) return ""
        let h = parseInt(hour)
        if (!use24Hour) {
            if (hourSystem === pmText && h < 12) h += 12
            if (hourSystem === amText && h === 12) h = 0
        }
        let hh = h < 10 ? "0" + h : "" + h
        let mm = parseInt(minute)
        let mmStr = mm < 10 ? "0" + mm : "" + mm
        return hh + ":" + mmStr
    }

    function setTime(hhmm) {
        if (!hhmm || typeof hhmm !== "string" || !hhmm.match(/^\d{2}:\d{2}$/)) return

        let parts = hhmm.split(":")
        let h = parseInt(parts[0])
        let m = parseInt(parts[1])

        if (h >= 0 && h < 24 && m >= 0 && m < 60) {
            if (use24Hour) {
                pickerView.value1 = h.toString()
                pickerView.value2 = m.toString()
                pickerView.value3 = undefined
            } else {
                pickerView.value1 = ((h % 12 === 0) ? 12 : h % 12).toString()
                pickerView.value2 = m.toString()
                pickerView.value3 = h >= 12 ? pmText : amText
            }
            pickerView.gotData = true
        }
    }

    // 重写按钮结果
    contentItem: RowLayout {
        anchors.fill: parent
        spacing: 0

        Text {
            Layout.fillWidth: true
            Layout.maximumWidth: use24Hour ? timePickerButton.implicitWidth / 2 : timePickerButton.implicitWidth / 3
            color: pickerView.gotData ? Theme.currentTheme.colors.textColor
                : Theme.currentTheme.colors.textSecondaryColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: pickerView.gotData ? pickerView.value1 : hourText
        }
        ToolSeparator {
            implicitHeight: 32
        }
        Text {
            Layout.fillWidth: true
            Layout.maximumWidth: use24Hour ? timePickerButton.implicitWidth / 2 : timePickerButton.implicitWidth / 3
            color: pickerView.gotData ? Theme.currentTheme.colors.textColor
                : Theme.currentTheme.colors.textSecondaryColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: pickerView.gotData ? pickerView.value2 : minuteText
        }
        ToolSeparator {
            implicitHeight: 32
            visible: !use24Hour
        }
        Text {
            Layout.fillWidth: true
            Layout.maximumWidth: timePickerButton.implicitWidth / 3
            color: pickerView.gotData ? Theme.currentTheme.colors.textColor
                : Theme.currentTheme.colors.textSecondaryColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: pickerView.gotData ? (pickerView.value3 !== undefined ? pickerView.value3 : "") : amText
            visible: !use24Hour
        }
    }

    onClicked: pickerView.open()

    PickerView {
        id: pickerView
        width: parent.width

        model1: use24Hour ? 24 : 12
        model3: use24Hour ? undefined : [amText, pmText]
    }
}
