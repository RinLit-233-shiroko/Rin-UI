import QtQuick
import "../../components"
import QtQuick.Controls
import "../../themes"


TableView {
    id: root
    clip: true

    // 外观属性（保留）
    property bool rowDividers: true
    property bool columnDividers: false

    // 交互状态属性（保留，用于 hover/press 视觉反馈）
    property int hoveredRow: -1
    property int pressedRow: -1

    // 使用 Qt 标准 selectionModel
    selectionModel: ItemSelectionModel {}
    acceptedButtons: Qt.NoButton  // 禁用鼠标左键滑动，以修复选择逻辑被覆盖的问题

    // interactive: true

    columnSpacing: 4
    rowSpacing: 4

    // 滚动条 / ScrollBar //
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }
    ScrollBar.horizontal: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    // Helper: compute column divider x position in content coordinates
    function getDividerX(dividerIndex) {
        if (!root.columnWidthProvider) return 0
        var x = 0
        for (var i = 0; i <= dividerIndex; i++) {
            x += root.columnWidthProvider(i)
        }
        x += (dividerIndex + 1) * root.columnSpacing
        return x
    }

    // Column dividers drawn at table level (continuous vertical lines)
    Repeater {
        model: root.columnDividers && root.columns > 1 ? root.columns - 1 : 0

        Rectangle {
            x: root.getDividerX(index) - root.contentX
            y: 0
            width: 1
            height: root.height
            color: Theme.currentTheme.colors.dividerBorderColor
        }
    }
    // pointerNavigationEnabled: false

    delegate: TableViewDelegate {
        tableView: root
        text: model.display
        // hoveredRow: row === root.hoveredRow
        // pressedRow: row === root.pressedRow
        rowDividers: root.rowDividers
    }
    // delegate: Rectangle {
    //             implicitWidth: 100
    //             implicitHeight: 50
    //             required property bool selected
    //             required property bool current
    //             border.width: current ? 2 : 0
    //             color: selected ? "lightblue" : palette.base
    //             Text{
    //                 text: model.display
    //                 padding: 12
    //             }
    //         }


    // 更新动画
    property Animation updateAnimation: ParallelAnimation {
        NumberAnimation {
            target: root
            property: "contentY"
            from: -12
            to: 0
            duration: Utils.animationSpeedMiddle
            easing.type: Easing.OutQuint
        }

        NumberAnimation {
            target: root
            property: "opacity"
            from: 0
            to: 1
            duration: Utils.animationSpeed
            easing.type: Easing.OutQuart
        }
    }


    onModelChanged: {
        updateAnimation.restart()
        _connectModelSignals()
    }

    SelectionRectangle {
        target: root
    }


    function _connectModelSignals() {
        if (!model) return
        if (model.rowsInserted !== undefined) model.rowsInserted.connect(updateAnimation.restart)
        if (model.rowsRemoved !== undefined) model.rowsRemoved.connect(updateAnimation.restart)
        if (model.rowsMoved !== undefined) model.rowsMoved.connect(updateAnimation.restart)
        if (model.modelReset !== undefined) model.modelReset.connect(updateAnimation.restart)
    }
}
