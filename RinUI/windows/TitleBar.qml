import QtQuick 2.12
import QtQuick.Controls 2.3
import QtQuick.Layouts
import QtQuick.Window 2.3
import "../themes"
import "../components"
import "../windows"

Item {
    id: root
    property int titleBarHeight: Theme.currentTheme.appearance.dialogTitleBarHeight
    property alias title: titleLabel.text
    property alias icon: iconLabel.source
    property alias backgroundColor: rectBk.color

    // 自定义属性
    property bool titleEnabled: true
    property alias iconEnabled: iconLabel.visible
    property bool minimizeEnabled: true
    property bool maximizeEnabled: true
    property bool closeEnabled: true
    property bool isMacOS: Qt.platform.os === "osx"
    property int macControlSize: 12
    property int macControlSpacing: 8
    property int macControlLeftMargin: 12
    property int macDragGap: 12
    property int macVisibleControlCount: (closeVisible ? 1 : 0) + (minimizeVisible ? 1 : 0) + (maximizeVisible ? 1 : 0)
    property int macControlGroupWidth: macVisibleControlCount > 0
        ? (macVisibleControlCount * macControlSize) + ((macVisibleControlCount - 1) * macControlSpacing)
        : 0

    property bool minimizeVisible: true
    property bool maximizeVisible: true
    property bool closeVisible: true

    // area
    default property alias content: contentItem.data


    height: titleBarHeight
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    clip: true
    z: 999

    implicitWidth: 200

    property var window: null
    function toggleMaximized() {
        if (!maximizeEnabled) {
            return
        }
        WindowManager.maximizeWindow(window)
    }

    Rectangle{
        id:rectBk
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            anchors.leftMargin: root.isMacOS
                ? root.macControlLeftMargin + root.macControlGroupWidth + root.macDragGap
                : 48
            anchors.margins: Utils.windowDragArea
            propagateComposedEvents: true
            acceptedButtons: Qt.LeftButton
            property point clickPos: "0,0"

            onPressed: {
                clickPos = Qt.point(mouseX, mouseY)

                if (Qt.platform.os !== "windows" || !WindowManager._isWinMgrInitialized()) {
                    return
                }
                WindowManager.sendDragWindowEvent(window)
            }
            onDoubleClicked: toggleMaximized()
            onPositionChanged: (mouse) => {
                if (window.isMaximized || window.isFullScreen || window.visibility === Window.Maximized) {
                    return
                }

                if (Qt.platform.os !== "windows" && WindowManager._isWinMgrInitialized()) {
                    log("Windows only")
                    return  // 在win环境使用原生方法拖拽
                }

                //鼠标偏移量
                let delta = Qt.point(mouse.x-clickPos.x, mouse.y-clickPos.y)

                window.setX(window.x+delta.x)
                window.setY(window.y+delta.y)
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: root.isMacOS ? 12 : 48

        // macOS traffic-light controls stay on the left side of the title.
        Row {
            id: macWindowControls
            visible: root.isMacOS
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: root.macControlLeftMargin
            spacing: root.macControlSpacing

            CtrlBtn {
                id: macCloseBtn
                mode: 2
                width: root.macControlSize
                height: root.macControlSize
                enabled: root.closeEnabled
                visible: root.closeVisible
            }
            CtrlBtn {
                id: macMinimizeBtn
                mode: 1
                width: root.macControlSize
                height: root.macControlSize
                enabled: root.minimizeEnabled
                visible: root.minimizeVisible
            }
            CtrlBtn {
                id: macMaximizeBtn
                mode: 0
                width: root.macControlSize
                height: root.macControlSize
                enabled: root.maximizeEnabled
                visible: root.maximizeVisible

            }
        }
        // 窗口标题 / Window Title

        RowLayout {
            id: titleRow
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: root.isMacOS ? 0 : 16
            spacing: 16
            opacity: root.titleEnabled

            //图标
            IconWidget {
                id: iconLabel
                size: 16
                Layout.alignment: Qt.AlignVCenter
                // anchors.verticalCenter: parent.verticalCenter
                visible: icon || source
            }

            //标题
            Text {
                id: titleLabel
                Layout.alignment: Qt.AlignVCenter
                // anchors.verticalCenter:  parent.verticalCenter

                typography: Typography.Caption
                text: qsTr("Fluent TitleBar")
            }
        }

        Item {
            // custom
            id: contentItem
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
        }

        // 窗口按钮 / Window Controls
        Row {
            id: windowControls
            visible: !root.isMacOS
            width: implicitWidth
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignRight
            spacing: 0
            CtrlBtn {
                id: minimizeBtn
                mode: 1
                enabled: root.minimizeEnabled
                visible: root.minimizeVisible
            }
            CtrlBtn {
                id: maximizeBtn
                mode: 0
                enabled: root.maximizeEnabled
                visible: root.maximizeVisible

            }
            CtrlBtn {
                id: closeBtn
                mode: 2
                enabled: root.closeEnabled
                visible: root.closeVisible
            }
        }
    }
}
