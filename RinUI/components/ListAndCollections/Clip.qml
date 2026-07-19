import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI


Button {
    id: root
    property alias color: background.color
    property alias radius: background.radius
    property alias topLeftRadius: background.topLeftRadius
    property alias topRightRadius: background.topRightRadius
    property alias bottomLeftRadius: background.bottomLeftRadius
    property alias bottomRightRadius: background.bottomRightRadius
    property alias border: background.border
    // property alias flat: background.flat

    background: Frame {
        id: background
        anchors.fill: parent
        // color: root.backgroundColor
        opacity: 1
    }

    contentItem: Item {}
}
