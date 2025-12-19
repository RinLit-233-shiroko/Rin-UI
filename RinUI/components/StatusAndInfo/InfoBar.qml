import QtQuick 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"


Frame {
    id: infoBar
    property string title: ""
    property string text: ""
    property int severity: Severity.Info
    default property alias customContent: custom.data
    property int timeout: -1
    property int position: 0
    property bool isDynamic: false  // 动态创建
    property bool closable: true  // 显示关闭按钮
    property bool iconVisible: true  // 显示图标
    property real startPosX: {
        switch (position) {
            case Position.TopLeft:
            case Position.BottomLeft:
                return -width / 2;
            case Position.TopRight:
            case Position.BottomRight:
                return width / 2;
            default:
                return 0;
        }
    }

    property real startPosY: 0
    readonly property real endPosX: x


    function _calculateStartPosY() {
        switch (position) {
            case Position.Top:
                return -height / 2 ;
            case Position.Bottom:
                return height / 2 ;
            default:
                return 0;
        }
    }

    function close() {
        exitAnimation.start()
    }

    color: {
        switch (severity) {
            case Severity.Info: return Theme.currentTheme.colors.systemAttentionBackgroundColor;
            case Severity.Success: return Theme.currentTheme.colors.systemSuccessBackgroundColor;
            case Severity.Warning: return Theme.currentTheme.colors.systemCautionBackgroundColor;
            case Severity.Error: return Theme.currentTheme.colors.systemCriticalBackgroundColor;
            default: return Theme.currentTheme.colors.systemNeutralBackgroundColor;
        }
    }

    // width: 200
    Layout.fillWidth: true
    padding: 5
    leftPadding: 15
    hoverable: false
    opacity: 0

    Timer {
        id: autoCloseTimer
        interval: timeout
        running: timeout >= 0
        repeat: false
        onTriggered: {
            // infoBar.visible = false
            // infoBar.destroy()
            exitAnimation.start()
        }
    }

    RowLayout {
        id: main
        anchors.fill: parent
        spacing: 13

        IconWidget {
            id: iconWidget
            Layout.preferredHeight: 38
            Layout.alignment: Qt.AlignTop
            size: 18
            icon: {
                switch (severity) {
                    case Severity.Info: return "ic_fluent_info_20_filled";
                    case Severity.Success: return "ic_fluent_checkmark_circle_20_filled";
                    case Severity.Warning: return "ic_fluent_error_circle_20_filled";
                    case Severity.Error: return "ic_fluent_dismiss_circle_20_filled";
                    default: return "ic_fluent_question_circle_20_filled";
                }
            }
            color: {
                switch (severity) {
                    case Severity.Info: return Theme.currentTheme.colors.systemAttentionColor;
                    case Severity.Success: return Theme.currentTheme.colors.systemSuccessColor;
                    case Severity.Warning: return Theme.currentTheme.colors.systemCautionColor;
                    case Severity.Error: return Theme.currentTheme.colors.systemCriticalColor;
                    default: return Theme.currentTheme.colors.systemNeutralColor;
                }
            }
            visible: iconVisible
        }

        Flow {
            id: flow
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.topMargin: 3
            // Layout.bottomMargin: 8
            spacing: bodyText.wrap ? 0 :12

            Text {
                id: titleText
                typography: Typography.BodyStrong
                text: infoBar.title
                topPadding: 6
            }
            Text {
                id: bodyText
                property bool wrap: (
                    (
                        infoBar.width - iconWidget.width - rights.width - custom.width
                        - main.spacing * 5 - infoBar.padding * 2
                    )
                    < implicitWidth
                )
                width: wrap ?
                    parent.width : implicitWidth
                typography: Typography.Body
                text: infoBar.text
                onLinkActivated: Qt.openUrlExternally(link)
                topPadding: wrap? 0 : 6
            }

            Item {
                width: parent.width
                height: bodyText.wrap && custom.children.length > 0 ? 16 : 0
            }
            Row {
                id: custom
                spacing: 6
            }
            Item {
                width: parent.width
                height: bodyText.wrap ? 9 : 0
            }
        }

        RowLayout {
            id: rights
            Layout.alignment: Qt.AlignTop

            ToolButton {
                Layout.alignment: Qt.AlignTop
                id: closeButton
                flat: true
                icon.name: "ic_fluent_dismiss_20_regular"
                size: 18
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                visible: closable
                onClicked: {
                    exitAnimation.start()
                    // if (infoBar.isDynamic) {
                    //     infoBar.destroy()
                    // } else {
                    //     infoBar.visible = false
                    // }
                }
                ToolTip {
                    text: qsTr("Close")
                    parent: parent
                    visible: parent.hovered
                }
            }
        }
    }


    // Animations
    Component.onCompleted: {
        startPosY = _calculateStartPosY();
        enterAnimation.start()
    }

    // Behavior on y { NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }
    transform: Translate {
        id: slideTransform
        y: 0
    }

    ParallelAnimation {
        id: enterAnimation

        NumberAnimation{
            target: infoBar
            property: "x"
            from: infoBar.startPosX
            to: infoBar.endPosX
            easing.type: Easing.OutQuart
            duration: Utils.animationSpeed
        }
        NumberAnimation {
            target: slideTransform
            property: "y"
            from: infoBar.startPosY
            to: 0
            easing.type: Easing.OutCubic
            duration: Utils.animationSpeed
        }
        NumberAnimation{
            target: infoBar
            property: "opacity"
            from: 0
            to: 1
            duration: Utils.appearanceSpeed
        }
    }

    SequentialAnimation{
        id: exitAnimation

        ParallelAnimation{
            NumberAnimation{
                target: infoBar
                property: "y"
                to: infoBar.startPosY
                easing.type: Easing.OutQuart
                duration: Utils.animationSpeed
                running: false
            }
            NumberAnimation{
                target: infoBar
                property: "opacity"
                from: 1
                to: 0
                duration: Utils.appearanceSpeed
            }
        }
        ScriptAction{
            script: {
                if (infoBar.isDynamic) {
                    infoBar.destroy()
                } else {
                    infoBar.visible = false
                    infoBar.opacity = 1
                    infoBar.y = 0
                }
            }
        }
    }
}
