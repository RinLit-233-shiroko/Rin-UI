import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import Qt5Compat.GraphicalEffects
import "../../themes"
import "../../components"


// expander
Item {
    id: root
    property bool enabled: true
    property bool expanded: false
    property alias headerHeight: header.height
    property alias contentHeight: content.height
    property alias contentPadding: content.padding
    property alias contentSpacing: contentLayout.spacing
    enum ExpandDirection { Up, Down }
    property var expandDirection: Expander.Down
    readonly property bool directionUp: root.expandDirection === Expander.Up
    property real radius: Theme.currentTheme.appearance.windowRadius

    property alias header: headerCustom.data
    property string text
    default property alias contentData: contentLayout.data  //折叠内容

    implicitWidth: Math.max(
        headerLayout.implicitWidth + 5 * 2,
        contentLayout.implicitWidth + contentPadding * 2,
        headerCustom.implicitWidth + 20 + expandBtn.width
    )
    implicitHeight: headerHeight + (content.height - 2) * expanded

    // 拦截交互
    MouseArea {
        z: 999
        anchors.fill: parent
        enabled: !root.enabled
        hoverEnabled: false
        preventStealing: true
        onClicked: {}  // 防止穿透
    }

    // 主体
    Clip {
        id: header
        enabled: root.enabled
        y: directionUp ? content.height * expanded : 0
        width: parent.width
        height: Math.max(
            headerCustom.implicitHeight + 5 * 2,
            headerLayout.implicitHeight + 5 * 2,
            48
        )
        radius: 0

        RowLayout {
            id: headerCustom
            anchors.fill: parent
            anchors.margins: 5
            anchors.leftMargin: 15
            anchors.rightMargin: 5 + expandBtn.width
        }

        RowLayout {
            id: headerLayout
            anchors.fill: parent
            anchors.margins: 5
            anchors.leftMargin: 15
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: root.text
                opacity: headerCustom.children.length === 0
            }
            // 展开按钮
            ToolButton {
                id: expandBtn
                focusPolicy: Qt.NoFocus
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                hoverable: false
                size: 14
                icon.name: directionUp ? "ic_fluent_chevron_up_20_filled" : "ic_fluent_chevron_down_20_filled"

                // 展开动画
                transform: Rotation {
                    angle: !expanded ? 0 : 180 ; origin.x: 40/2; origin.y: 40/2
                    Behavior on angle { NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint } }
                }
                opacity: 0.7

                onClicked: expanded =!expanded
            }
        }

        onClicked: expanded =!expanded

        Behavior on y {
            NumberAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuint }
        }
    }

    // content
    Item {
        id: contentContainer
        width: parent.width
        height: directionUp
            ? expanded ? content.height : 0
            : content.height
        clip: true
        y: directionUp ? 0 : header.height
        z: -1  // 置底

        Frame {
            id: content
            padding: 7
            width: parent.width
            y: expanded
                ? directionUp ? 2 : - 2
                : directionUp ? height : - height
            radius: 0
            opacity: root.enabled ? 1 : 0.65

            color: Theme.currentTheme.colors.cardSecondaryColor
            // 内容区域 - 布局
            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
            }

            Behavior on y {
                NumberAnimation { duration: Utils.animationSpeedExpander; easing.type: expanded ? Easing.InQuint : Easing.OutQuint }
            }

            Behavior on opacity {
                NumberAnimation { duration: Utils.appearanceSpeed; easing.type: expanded ? Easing.InQuint : Easing.OutQuint }
            }
        }

        Behavior on height {
            NumberAnimation { duration: Utils.animationSpeedExpander; easing.type: expanded ? Easing.InQuint : Easing.OutQuint }
        }
    }

    // 动画
    Behavior on implicitHeight {
        NumberAnimation { duration: Utils.animationSpeedExpander; easing.type: expanded ? Easing.InQuint : Easing.OutQuint }
    }

    // 圆角裁切
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
        }
    }
}
