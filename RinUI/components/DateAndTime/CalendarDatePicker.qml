import QtQuick 2.15
import QtQuick.Layouts 2.15
import QtQuick.Controls.Basic 2.15
import "../../themes"
import "../../components"

Button {
    id: root

    implicitHeight: 32
    implicitWidth: 120

    // Public API
    property alias selectedDate: cal.selectedDate
    property alias displayYear: cal.displayYear
    property alias displayMonth: cal.displayMonth
    property alias calendarLocale: cal.locale
    property bool useISOWeek: true
    property bool weekNumbersVisible: false
    property var minimumDate: undefined
    property var maximumDate: undefined
    property string placeholderText: qsTr("Select date")
    property string textFormat: "MM/dd/yyyy"

    leftPadding: 12
    rightPadding: 12
    topPadding: 5
    bottomPadding: 7

    property string iconName: "ic_fluent_calendar_20_regular"
    property int iconSize: 16
    property color iconColor: Theme.currentTheme.colors.textSecondaryColor
    property bool iconVisible: true

    signal dateSelected(date date)

    function fmt(d) {
        if (!d) return placeholderText
        try { return Qt.formatDate(d, textFormat) } catch (e) {}
        var y = d.getFullYear(); var m = ("0" + (d.getMonth()+1)).slice(-2); var day = ("0" + d.getDate()).slice(-2)
        return y + "-" + m + "-" + day
    }

    text: root.selectedDate ? root.fmt(root.selectedDate) : root.placeholderText
    onClicked: { pickerPopup.reposition(); pickerPopup.open() }


    contentItem: RowLayout {
        spacing: 6
        Text {
            id: label
            Layout.fillWidth: true

            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            text: root.selectedDate ? root.fmt(root.selectedDate) : root.placeholderText
        }
        Icon {
            visible: root.iconVisible
            name: root.iconName
            size: root.iconSize
            color: root.iconColor
        }
    }

    Popup {
        id: pickerPopup
        padding: 0
        parent: root
        width: cal.implicitWidth
        height: cal.implicitHeight
        closePolicy: Popup.CloseOnPressOutside

        property bool autoPlacement: true

        onVisibleChanged: if (visible && autoPlacement) Qt.callLater(reposition)

        function reposition() {
            var overlay = root.window ? root.window.contentItem : root
            var btnPos = root.mapToItem(overlay, 0, 0)
            var btnTop = btnPos.y
            var btnBottom = btnTop + root.height
            var spaceAbove = btnTop
            var spaceBelow = overlay.height - btnBottom
            var popupH = Math.max(height, implicitHeight || height)
            pickerPopup.position = (spaceBelow >= popupH) ? Position.Bottom : Position.Top
        }

        Calendar {
            id: cal
            anchors.fill: parent

            selectionMode: "single"
            useISOWeek: root.useISOWeek
            weekNumbersVisible: root.weekNumbersVisible
            minimumDate: root.minimumDate
            maximumDate: root.maximumDate
            onDateSelected: function(d) {
                root.dateSelected(d)
                pickerPopup.close()
            }
        }
    }

    function resetToToday() {
        cal.selectedDate = new Date()
        cal.displayYear = cal.selectedDate.getFullYear()
        cal.displayMonth = cal.selectedDate.getMonth() + 1
    }
}