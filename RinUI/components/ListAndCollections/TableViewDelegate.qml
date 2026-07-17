import QtQuick
import QtQuick.Controls
import "../../themes"
import "../../components"


TableViewDelegate {
    id: delegate
    implicitWidth: Math.max(80, contentItem.implicitWidth)
    implicitHeight: contentItem.implicitHeight

    // required property bool selected
    // required property bool current

    property bool rowDividers: true

    property int contentLeftPadding: 12
    property int contentRightPadding: 12
    property int contentTopPadding: 7
    property int contentBottomPadding: 9


    // 行选中状态（isSelected查询selectionModel支持多选）
    property int selectionRevision: 0

    highlighted: {
        selectionRevision

        let tv = delegate.tableView
        if (!tv)
            return false

        if (tv.currentRow === row) // qml 神人设计！搞个current状态干啥啊？ 琢磨了一晚上才想通
            return true

        if (!tv.selectionModel)
            return false

        for (let c = 0; c < tv.columns; c++) {
            if (tv.selectionModel.isSelected(tv.index(row,c)))
                return true
        }

        return false
    }

    Connections {
        target: delegate.tableView ? delegate.tableView.selectionModel : null

        function onSelectionChanged() {
            delegate.selectionRevision++
        }
    }

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    // accessibility (SingleSelection)
    FocusIndicator {
        control: parent
    }

    contentItem: Item {
        implicitWidth: {
            if (typeof model.display === "boolean")
                return boolDisplay.implicitWidth + delegate.contentLeftPadding + delegate.contentRightPadding
            return label.implicitWidth + delegate.contentLeftPadding + delegate.contentRightPadding
        }
        implicitHeight: {
            if (typeof model.display === "boolean")
                return boolDisplay.implicitHeight + delegate.contentTopPadding + delegate.contentBottomPadding
            return label.implicitHeight + delegate.contentTopPadding + delegate.contentBottomPadding
        }

        Text {
            id: label
            anchors.fill: parent
            anchors.leftMargin: delegate.contentLeftPadding
            anchors.rightMargin: delegate.contentRightPadding
            anchors.topMargin: delegate.contentTopPadding
            anchors.bottomMargin: delegate.contentBottomPadding
            visible: typeof model.display !== "boolean" && text.length > 0
            typography: Typography.Body
            color: delegate.enabled ? Theme.currentTheme.colors.textColor :Theme.currentTheme.colors.textDisabledColor
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            text: model.display
        }

        CheckBox {
            id: boolDisplay
            focusPolicy: Qt.TabFocus
            anchors.verticalCenter: parent.verticalCenter
            x: delegate.contentLeftPadding
            visible: typeof model.display === "boolean"
            checked: model.display !== undefined ? model.display : false
            enabled: {
                let tv = delegate.tableView
                if (!tv) return false
                return tv.editTriggers !== TableView.NoEditTriggers
            }
            implicitHeight: 20
            onToggled: model.display = checked
        }

        visible: typeof model.display === "boolean" ? true : !editing
    }

    background: Item {
        visible: delegate.column === 0
        anchors.fill: parent

        // 背景宽度：至少覆盖视口，超出的内容也能覆盖
        property real bgWidth: {
            var tv = delegate.tableView
            if (!tv) return delegate.width
            return Math.max(tv.width, tv.contentWidth)
        }

        Rectangle {
            id: backgroundRect
            width: parent.bgWidth
            height: parent.height
            radius: 3
            visible: delegate.highlighted || (delegate.rowDividers && delegate.row % 2 === 0)
            color: Theme.currentTheme.colors.subtleTertiaryColor

            Indicator {
                currentItemHeight: parent.height
                visible: delegate.highlighted
            }

            Behavior on color { ColorAnimation { duration: Utils.appearanceSpeed; easing.type:Easing.InOutQuart } }
        }

        Rectangle {
            id: actionBackground
            width: parent.bgWidth
            height: parent.height
            radius: 3
            // color: delegate.pressedRow ?
            //     Theme.currentTheme.colors.subtleTertiaryColor
            //     : Theme.currentTheme.colors.subtleSecondaryColor
            color: Theme.currentTheme.colors.subtleSecondaryColor
            opacity: delegate.highlighted

            Behavior on color { ColorAnimation { duration: Utils.appearanceSpeed; easing.type:Easing.InOutQuart } }
            Behavior on opacity { NumberAnimation { duration: Utils.appearanceSpeed; easing.type:Easing.InOutQuart } }
        }
    }


    // 编辑控件 / Edit Delegate

    TableView.editDelegate: Loader {
        id: editorLoader

        property var value: model.display
        sourceComponent: {
            if (typeof value === "boolean")
                return;

            return textEditor
        }

        TableView.onCommit: {
            var item = editorLoader.item
            if (!item || !item.enabled)
                return

            model.display = item.text
        }
    }

    Component {
        id: textEditor

        TextField {
            x: contentItem.x
            y: contentItem.y
            width: contentItem.width
            height: contentItem.height
            text: model.display
            focus: true

            Component.onCompleted: {
                selectAll()
                forceActiveFocus()
            }
        }
    }
}
