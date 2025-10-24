import QtQuick 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"

Item {
    id: root
    implicitWidth: input.implicitWidth
    implicitHeight: input.implicitHeight

    // Public API
    property alias text: input.text
    property alias placeholderText: input.placeholderText
    property alias readOnly: input.readOnly
    // property alias enabled: input.enabled  // removed to avoid overriding Item.enabled
    property alias font: input.font
    property alias validator: input.validator
    property alias inputMethodHints: input.inputMethodHints
    property alias activeFocusOnPress: input.activeFocusOnPress
    // property alias focus: input.focus      // removed to avoid overriding Item.focus

    // Clear button control (default disabled for DateField)
    property bool clearEnabled: false

    // Icon settings
    property string iconName: "ic_fluent_calendar_20_regular"
    property int iconSize: 20
    property color iconColor: Theme.currentTheme.colors.textSecondaryColor
    property bool iconVisible: true

    // Base TextField
    TextField {
        id: input
        anchors.fill: parent
        readOnly: true
        clearEnabled: root.clearEnabled
        extraRightPadding: iconVisible ? (iconSize + 8) : 0
        placeholderText: qsTr("YYYY-MM-DD")
        enabled: root.enabled
    }

    // Calendar icon overlay (right side)
    Icon {
        id: calendarIcon
        anchors.right: input.right
        anchors.rightMargin: 6
        anchors.verticalCenter: input.verticalCenter
        visible: iconVisible
        name: iconName
        size: iconSize
        color: iconColor
    }
}