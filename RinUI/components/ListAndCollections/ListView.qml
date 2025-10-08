import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"

ListView {
    id: root
    property string textRole: ""  // 文字role

    property bool keyboardNavigation: false
    // 自动检测模型类型
    readonly property string modelType: {
        if (!model) return "null";
        if (Array.isArray(model) && root.textRole) return "array-with-role";
        if (Array.isArray(model)) return "array";
        if (model instanceof ListModel) return "listmodel";
        if (typeof model === "object" && "count" in model) return "listmodel-like";
        return "unknown";
    }

    clip: true

    // 垂直滚动条 / Vertical ScrollBar //
    ScrollBar.vertical: ScrollBar {
        id: scrollBar
        policy: ScrollBar.AsNeeded
    }

    // 交换动画
    // move: Transition {
    //     NumberAnimation { property: "y"; duration: 200 }
    // }
    // moveDisplaced: Transition {
    //     NumberAnimation { property: "y"; duration: 200 }
    // }

    displaced: Transition {
        NumberAnimation {
            property: "y"
            duration: Utils.animationSpeedMiddle
            easing.type: Easing.OutQuint
        }
    }

    add: Transition {
        ParallelAnimation{
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Utils.animationSpeed
                easing.type: Easing.OutQuint
            }
            NumberAnimation {
                properties: "scale"
                from: 0.9
                to: 1
                duration: Utils.animationSpeed
                easing.type: Easing.OutQuint
            }
        }
    }

    // 删除动画
    remove: Transition {
        ParallelAnimation{
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Utils.animationSpeed
                easing.type: Easing.OutQuint
            }
            NumberAnimation {
                properties: "scale"
                from: 1
                to: 0.9
                duration: Utils.animationSpeed
                easing.type: Easing.OutQuint
            }
        }
    }

    delegate: ListViewDelegate {
        middleArea: [
            Text {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                id: text
                typography: Typography.Body
                wrapMode: Text.Wrap
                text: {
                    switch (root.modelType) {
                        case "array": return modelData;
                        case "array-with-role": return modelData[root.textRole] || modelData || "";
                        case "listmodel":
                        case "listmodel-like":
                            return model[root.textRole] || modelData || "";
                        default: return "";
                    }
                }
            }
        ]
    }
}
