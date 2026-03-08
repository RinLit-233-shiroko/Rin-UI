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
    // Keep macOS detection resilient across Qt variants.
    property bool isMacOS: Qt.platform.os === "osx" || Qt.platform.os === "macos" || Qt.platform.os === "darwin"
    property bool useNativeMacControls: false
    property bool showMacCustomControls: root.isMacOS && !root.useNativeMacControls
    property int macControlSize: 12
    property int macControlSpacing: 8
    property int macControlLeftMargin: 20
    property int macDragGap: 12
    // Reserve a small leading no-drag zone for overlay actions (e.g. NavigationView back button).
    property int macLeadingInteractiveWidth: 40
    // Align custom title content with native traffic lights on macOS.
    property real macNativeContentVerticalOffset: root.isMacOS && root.useNativeMacControls
        ? ((root.window && root.window.macNativeContentVerticalOffset !== undefined)
            ? root.window.macNativeContentVerticalOffset
            : -2)
        : 0
    property int macNativeControlCount: root.isMacOS && root.useNativeMacControls ? 3 : 0
    property int macVisibleControlCount: root.showMacCustomControls
        ? (closeVisible ? 1 : 0) + (minimizeVisible ? 1 : 0) + (maximizeVisible ? 1 : 0)
        : 0
    property int macControlOccupyCount: macVisibleControlCount > 0 ? macVisibleControlCount : macNativeControlCount
    property int macControlGroupWidth: macVisibleControlCount > 0
        ? (macVisibleControlCount * macControlSize) + ((macVisibleControlCount - 1) * macControlSpacing)
        : 0
    property int macLeadingInset: root.isMacOS && macControlOccupyCount > 0
        ? root.macControlLeftMargin + (macControlOccupyCount * root.macControlSize) + ((macControlOccupyCount - 1) * root.macControlSpacing) + root.macDragGap
        : 0
    property bool macControlsHovered: root.showMacCustomControls && (
        (macCloseBtn.visible && (macCloseBtn.localHovered || macCloseBtn.localPressed)) ||
        (macMinimizeBtn.visible && (macMinimizeBtn.localHovered || macMinimizeBtn.localPressed)) ||
        (macMaximizeBtn.visible && (macMaximizeBtn.localHovered || macMaximizeBtn.localPressed))
    )

    property bool minimizeVisible: true
    property bool maximizeVisible: true
    property bool closeVisible: true

    // area
    default property alias content: contentItem.data
    property alias contentHost: contentItem


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
            enabled: !root.useNativeMacControls
            anchors.fill: parent
            anchors.leftMargin: root.isMacOS
                ? root.macLeadingInset + root.macLeadingInteractiveWidth
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
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.macNativeContentVerticalOffset
        height: parent.height
        anchors.margins: 0
        spacing: root.isMacOS ? (root.showMacCustomControls ? 12 : 0) : 48

        // macOS traffic-light controls stay on the left side of the title.
        Row {
            id: macWindowControls
            visible: root.showMacCustomControls
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
                macGroupHovered: root.macControlsHovered
            }
            CtrlBtn {
                id: macMinimizeBtn
                mode: 1
                width: root.macControlSize
                height: root.macControlSize
                enabled: root.minimizeEnabled
                visible: root.minimizeVisible
                macGroupHovered: root.macControlsHovered
            }
            CtrlBtn {
                id: macMaximizeBtn
                mode: 0
                width: root.macControlSize
                height: root.macControlSize
                enabled: root.maximizeEnabled
                visible: root.maximizeVisible
                macGroupHovered: root.macControlsHovered

            }
        }
        // 窗口标题 / Window Title

        RowLayout {
            id: titleRow
            visible: root.titleEnabled
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: root.isMacOS ? (root.useNativeMacControls ? root.macLeadingInset : 0) : 16
            spacing: 16

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
