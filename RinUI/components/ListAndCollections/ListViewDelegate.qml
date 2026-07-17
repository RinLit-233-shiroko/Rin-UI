import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"


ItemDelegate {
    id: delegate
    width: ListView.view ? ListView.view.width : 200
    height: contentItem.implicitHeight + 20  // 自适应
    highlighted: ListView.isCurrentItem  // 当前项高亮
    // focusPolicy: Qt.StrongFocus

    leftPadding: 16
    rightPadding: 5
    topPadding: 3
    bottomPadding: 0

    // accessibility
    FocusIndicator {
        control: parent
    }

    contentItem: Text {
        visible: text.length > 0
        typography: Typography.Body
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        text: delegate.text
    }

    background: Rectangle {
        id: itemBg
        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        anchors.topMargin: 3
        radius: Theme.currentTheme.appearance.buttonRadius
        color: pressed
            ? Theme.currentTheme.colors.subtleTertiaryColor
            : (highlighted || hovered)
                ? Theme.currentTheme.colors.subtleSecondaryColor
                : Theme.currentTheme.colors.subtleColor

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 11
            anchors.topMargin: 6
            anchors.bottomMargin: 8
        }

        // 选择指示器
        Indicator {
            currentItemHeight: delegate.height
            visible: highlighted
        }

        Behavior on color { ColorAnimation { duration: Utils.appearanceSpeed; easing.type:Easing.InOutQuart } }
    }

    onClicked: {
        ListView.view.currentIndex = index
    }
}
