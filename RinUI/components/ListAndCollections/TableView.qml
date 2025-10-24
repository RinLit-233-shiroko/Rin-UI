import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"

TableView {
    id: root
    clip: true

    // 滚动条 / ScrollBar //
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }
    ScrollBar.horizontal: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    // 交换动画
    // move: Transition {
    //     NumberAnimation { property: "y"; duration: 200 }
    // }
    // moveDisplaced: Transition {
    //     NumberAnimation { property: "y"; duration: 200 }
    // }

    // displaced: Transition {
    //     NumberAnimation {
    //         property: "y"
    //         duration: Utils.animationSpeedMiddle
    //         easing.type: Easing.OutQuint
    //     }
    // }
    //
    // add: Transition {
    //     ParallelAnimation{
    //         NumberAnimation {
    //             property: "opacity"
    //             from: 0
    //             to: 1
    //             duration: Utils.animationSpeed
    //             easing.type: Easing.OutQuint
    //         }
    //         NumberAnimation {
    //             properties: "scale"
    //             from: 0.9
    //             to: 1
    //             duration: Utils.animationSpeed
    //             easing.type: Easing.OutQuint
    //         }
    //     }
    // }
    //
    // // 删除动画
    // remove: Transition {
    //     ParallelAnimation{
    //         NumberAnimation {
    //             property: "opacity"
    //             from: 1
    //             to: 0
    //             duration: Utils.animationSpeed
    //             easing.type: Easing.OutQuint
    //         }
    //         NumberAnimation {
    //             properties: "scale"
    //             from: 1
    //             to: 0.9
    //             duration: Utils.animationSpeed
    //             easing.type: Easing.OutQuint
    //         }
    //     }
    // }

    delegate: TableViewDelegate {
        middleArea: [
            Text {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                text: model.display
            }
        ]
    }
}
