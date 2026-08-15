import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import QtQuick.Window 2.15
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
    property real macNativeContentVerticalOffset: root.window && root.window.macNativeContentVerticalOffset !== undefined
        ? root.window.macNativeContentVerticalOffset
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
    property int macSafeLeft: root.window && root.window.macSafeLeft > 0
        ? root.window.macSafeLeft
        : root.macLeadingInset
    property int macContentLeftMargin: root.isMacOS && root.useNativeMacControls
        ? root.macSafeLeft
        : (root.isMacOS ? 0 : 4)
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
    property alias leadingContent: leadingContentItem.data
    property alias leadingContentHost: leadingContentItem


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
    }

    // Declared on the title bar itself so empty regions start a system move,
    // while child controls (back, search, window buttons) keep their handlers.
    DragHandler {
        id: titleDragHandler
        target: null
        x: root.isMacOS ? root.macSafeLeft : 0
        width: Math.max(0, root.width - x - (root.isMacOS ? 0 : 48))
        height: root.height
        acceptedButtons: Qt.LeftButton
        grabPermissions: PointerHandler.TakeOverForbidden
        onActiveChanged: {
            if (!active || !root.window)
                return
            if (root.window.visibility === Window.Maximized
                    || root.window.visibility === Window.FullScreen)
                return
            if (Qt.platform.os === "windows" && WindowManager._isWinMgrInitialized()) {
                WindowManager.sendDragWindowEvent(root.window)
                return
            }
            if (typeof root.window.startSystemMove === "function")
                root.window.startSystemMove()
        }
    }

    TapHandler {
        x: titleDragHandler.x
        width: titleDragHandler.width
        height: root.height
        acceptedButtons: Qt.LeftButton
        grabPermissions: PointerHandler.TakeOverForbidden
        onDoubleTapped: root.toggleMaximized()
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.macNativeContentVerticalOffset
        height: parent.height
        anchors.leftMargin: root.macContentLeftMargin
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
            Layout.preferredWidth: visible ? implicitWidth : 0
            Layout.leftMargin: root.isMacOS ? 0 : 16
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
            id: leadingContentItem
            Layout.fillHeight: true
            Layout.preferredWidth: childrenRect.width
            visible: children.length > 0
            clip: true
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
