import QtQuick 2.15
import QtQuick.Controls 2.15
import "../../themes"
import "../../components"

ScrollView {
    id: root

    // 基本属性
    property alias text: area.text
    property alias placeholderText: area.placeholderText
    property alias textFormat: area.textFormat
    property alias wrapMode: area.wrapMode
    property alias readOnly: area.readOnly
    property alias selectionColor: area.selectionColor
    property alias textArea: area
    property alias color: area.color

    clip: true
    implicitHeight: defaultHeight
    implicitWidth: 200

    TextArea {
        id: area
        width: root.width
        placeholderText: ""
        wrapMode: Text.Wrap
        textFormat: TextEdit.PlainText

        leftPadding: 8
        rightPadding: 8
        topPadding: 6
        bottomPadding: 6
    }
}
