import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI


Button {
    id: root
    property alias color: background.color
    property alias radius: background.radius
    property alias border: background.border
    // property alias flat: background.flat

    background: Frame {
        id: background
        anchors.fill: parent
        color: root.backgroundColor
        opacity: 1
        // flat:
    }

    contentItem: Item {}
}
