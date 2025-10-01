import QtQuick 2.12
import QtQuick.Controls 2.3
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

    property alias minimizeVisible: minimizeBtn.visible
    property alias maximizeVisible: maximizeBtn.visible
    property alias closeVisible: closeBtn.visible


    height: titleBarHeight
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: (window !== null && window.visibility === Window.Maximized && Qt.platform.os === "windows") ? 5 : 0
    clip: true
    z: 999

    implicitWidth: 200

    property var window: null
    function toggleMaximized() {
        WindowManager.maximizeWindow(window)
    }

    Rectangle{
        id:rectBk
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            anchors.leftMargin: 48
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

    // 窗口按钮 / Window Controls
    Row{
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0
        CtrlBtn {
            id: minimizeBtn
            mode: 1
            enabled: root.minimizeEnabled
        }
        CtrlBtn {
            id: maximizeBtn
            mode: 0
            enabled: root.maximizeEnabled

        }
        CtrlBtn {
            id: closeBtn
            mode: 2
            enabled: root.closeEnabled
        }
    }

    // 窗口标题 / Window Title
    Row {
        id: titleRow
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        spacing: 16
        visible: root.titleEnabled

        //图标
        IconWidget {
            id: iconLabel
            size: 16
            anchors.verticalCenter: parent.verticalCenter
            visible: icon || source
        }

        //标题
        Text {
            id: titleLabel
            anchors.verticalCenter:  parent.verticalCenter

            typography: Typography.Caption
            text: qsTr("Fluent TitleBar")
        }
    }
}
