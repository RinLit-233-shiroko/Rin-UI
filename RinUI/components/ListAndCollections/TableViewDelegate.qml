import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"


ItemDelegate {
    id: delegate
    width: TableView.view ? TableView.view.width : 200
    height: contents.implicitHeight + 20  // 自适应
    highlighted: false
    focusPolicy: Qt.StrongFocus

    // accessibility
    FocusIndicator {
        control: parent
    }

    property alias leftArea: leftArea.data
    property alias middleArea: middleArea.data
    property alias rightArea: rightArea.data

    contentItem: RowLayout {
        id: contents
        anchors.fill: parent
        anchors.leftMargin: 5 + 11
        anchors.rightMargin: 5
        anchors.topMargin: 3
        spacing: 8

        Row {
            id: leftArea
            // CheckBox {
            //     id: checkBox
            //     implicitWidth: height * 1
            //     Layout.fillHeight: true
            //     checked: false
            //     visible: tableCell.column === 0
            // }
        }

        ColumnLayout {
            id: middleArea
            Layout.fillHeight: true
        }

        RowLayout {
            id: rightArea
            spacing: 16
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    background: Rectangle {
        id: itemBg
        anchors.fill: parent
        // anchors.leftMargin: 5
        // anchors.rightMargin: 5
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
        // TableView.selected = row
    }
}
