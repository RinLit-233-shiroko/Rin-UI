import QtQuick
import QtQuick.Controls
import "../../themes"
import "../../components"


VerticalHeaderViewDelegate {
    id: delegate
    // implicitWidth: contentItem.implicitWidth
    // implicitHeight: contentItem.implicitHeight

    // property int contentLeftPadding: 12
    // property int contentRightPadding: 12
    // property int contentTopPadding: 7
    // property int contentBottomPadding: 9


    leftPadding: 12
    rightPadding: 12
    topPadding: 7
    bottomPadding: 9

    background: Item {}

    contentItem: Text {
        id: label
        anchors.leftMargin: delegate.contentLeftPadding
        anchors.rightMargin: delegate.contentRightPadding
        anchors.topMargin: delegate.contentTopPadding
        anchors.bottomMargin: delegate.contentBottomPadding
        visible: text.length > 0
        typography: Typography.Body
        color: Theme.currentTheme.colors.textSecondaryColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: model.display !== undefined ? model.display : model.modelData
    }
}
