import QtQuick
import QtQuick.Controls
import "../../themes"
import "../../components"

VerticalHeaderView {
    id: root
    acceptedButtons: Qt.NoButton

    clip: true

    delegate: VerticalHeaderViewDelegate {
    }
}
