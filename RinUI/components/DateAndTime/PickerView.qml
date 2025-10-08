import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"

Popup {
    id: root

    width: 300
    height: 330
    implicitHeight: 330
    y: -height / 2 + buttonRow.height
    position: Position.Center  // RinUI popup自定义属性

    property var value1: undefined
    property var value2: undefined
    property var value3: undefined

    property alias index1: hours.currentIndex
    property alias index2: minutes.currentIndex
    property alias index3: added.currentIndex

    property var model1: 12
    property var model2: 60
    property var model3: [qsTr("AM"), qsTr("PM")]

    property bool gotData: typeof value1!== "undefined" && typeof value2!== "undefined"

    signal valueChanged(var value1, var value2, var value3)

    function formatText(count, modelData) {
        let data = modelData;
        return data.toString().length < 2 && count === 60  ? "0" + data
            : data === 0 && count === 12 ? 12 : data
    }

    property int visibleItemCount: 7

    // 数字/文字 选择 //
    Component {
        id: delegateComponent

        Text {
            readonly property bool highlighted: Tumbler.displacement < 0.5 && Tumbler.displacement > -0.5
            text: formatText(Tumbler.tumbler.count, modelData)
            color: highlighted? Theme.currentTheme.colors.textOnAccentColor : Theme.currentTheme.colors.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            // 点击选择喵 看看啥时候把背景加上
            MouseArea {
                anchors.fill: parent
                onClicked: Tumbler.tumbler.currentIndex = index
            }
        }
    }
    padding: 0

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent
        spacing: -2

        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 0
            leftPadding: 4
            rightPadding: 4

            frameless: true
            background: Rectangle {
                id: highlightBackground
                anchors.centerIn: parent
                height: 40
                radius: Theme.currentTheme.appearance.buttonRadius
                color: Theme.currentTheme.colors.primaryColor
                width: parent.width - parent.leftPadding - parent.rightPadding
            }

            RowLayout {
                id: tumblerRow
                anchors.fill: parent

                Tumbler {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    id: hours
                    model: model1
                    visibleItemCount: root.visibleItemCount
                    delegate: delegateComponent
                }
                ToolSeparator {
                    Layout.fillHeight: true
                }
                Tumbler {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    id: minutes
                    model: model2
                    visibleItemCount: root.visibleItemCount
                    delegate: delegateComponent
                }
                ToolSeparator {
                    Layout.fillHeight: true
                    visible: added.visible
                }
                Tumbler {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    id: added
                    model: model3
                    visibleItemCount: root.visibleItemCount
                    delegate: delegateComponent
                    visible: typeof model3 !== "undefined"
                }
            }
        }

        Rectangle {  // 分割线
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.currentTheme.colors.dividerBorderColor
        }

        // 确认/取消 按钮区域
        RowLayout {
            id: buttonRow
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 0

            // confirm
            ToolButton {
                Layout.fillWidth: true
                flat: true
                icon.name: "ic_fluent_checkmark_20_regular"
                onClicked: {
                    value1 = hours.currentItem.text
                    value2 = minutes.currentItem.text
                    typeof model3 !== "undefined" ? value3 = added.currentItem.text : undefined
                    valueChanged(value1, value2, value3)
                    root.close()
                }
            }
            ToolSeparator {
                implicitHeight: 40
            }
            // cancel
            ToolButton {
                Layout.fillWidth: true
                flat: true
                icon.name: "ic_fluent_dismiss_20_regular"
                onClicked: {
                    root.close()
                }
            }
        }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                from: 0
                to: 1
                duration: Utils.appearanceSpeed
                easing.type: Easing.OutQuint
            }
            NumberAnimation {
                target: root
                property: "height"
                from: implicitHeight / 2
                to: implicitHeight
                duration: Utils.animationSpeedMiddle * 0.8
                easing.type: Easing.OutQuint
            }
            ScriptAction {
                script: {
                    hours.positionViewAtIndex(
                        typeof value1 === "undefined" ? 0
                        : typeof model1 === "number" ? value1 : model1.indexOf(value1), Tumbler.Center
                    )
                    minutes.positionViewAtIndex(
                        typeof value2 === "undefined" ? 0
                        : typeof model2 === "number" ? value2 : model2.indexOf(value2), Tumbler.Center
                    )
                    added.positionViewAtIndex(
                        typeof value3 === "undefined" ? 0
                        : typeof model3 === "number" ? value3 : model3.indexOf(parseInt(value3)), Tumbler.Center
                    )
                }
            }
        }
    }

    background: Rectangle {
        id: background
        anchors.fill: parent
        anchors.horizontalCenter: parent.horizontalCenter
        y: -6

        radius: Theme.currentTheme.appearance.windowRadius
        color: Theme.currentTheme.colors.backgroundAcrylicColor
        border.color: Theme.currentTheme.colors.flyoutBorderColor

        Behavior on color {
            ColorAnimation {
                duration: Utils.appearanceSpeed
                easing.type: Easing.OutQuart
            }
        }

        layer.enabled: true
        layer.effect: Shadow {
            style: "flyout"
            source: background
        }
    }
}
