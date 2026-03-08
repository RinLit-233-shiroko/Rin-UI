import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../../windows"
import "../../themes"
import "../../utils"

Window {
    id: baseWindow
    property bool isMacOS: Qt.platform.os === "osx" || Qt.platform.os === "macos" || Qt.platform.os === "darwin"
    // Native traffic lights + single custom titlebar integration on macOS.
    property bool useNativeMacFrame: isMacOS
    // Fine-tune custom title content baseline to match native traffic lights.
    property int macNativeContentVerticalOffset: useNativeMacFrame ? -2 : 0
    property int expandedClientAreaHint: typeof Qt.ExpandedClientAreaHint !== "undefined"
        ? Qt.ExpandedClientAreaHint
        : 0
    flags: (useNativeMacFrame
        ? (Qt.Window
            | Qt.CustomizeWindowHint
            | Qt.WindowTitleHint
            | Qt.WindowSystemMenuHint
            | expandedClientAreaHint
            | Qt.NoTitleBarBackgroundHint)
        : (Qt.FramelessWindowHint | Qt.Window))
        | Qt.WindowMinimizeButtonHint
        | Qt.WindowMaximizeButtonHint
        | Qt.WindowCloseButtonHint

    color: useNativeMacFrame ? Theme.currentTheme.colors.backgroundColor : "transparent"
    default property alias content: contentArea.data
    property int titleBarHeight: Theme.currentTheme.appearance.dialogTitleBarHeight
    property alias titleBarArea: titleBar.content
    property alias titleBarHost: titleBar.contentHost
    property alias titleEnabled: titleBar.titleEnabled
    property alias minimizeEnabled: titleBar.minimizeEnabled
    // property alias maximizeEnabled: titleBar.maximizeEnabled
    property bool maximizeEnabled: maximumHeight === 16777215 && maximumWidth === 16777215
    property alias closeEnabled: titleBar.closeEnabled

    property alias minimizeVisible: titleBar.minimizeVisible
    property alias maximizeVisible: titleBar.maximizeVisible
    property alias closeVisible: titleBar.closeVisible
    property bool isRinUIWindow: true

    // 布局
    ColumnLayout {
        anchors.fill: parent
        anchors.bottomMargin: baseWindow.useNativeMacFrame ? 0 : Utils.windowDragArea
        anchors.leftMargin: baseWindow.useNativeMacFrame ? 0 : Utils.windowDragArea
        anchors.rightMargin: baseWindow.useNativeMacFrame ? 0 : Utils.windowDragArea
        spacing: 0

        // 顶部边距
        Item {
            Layout.preferredHeight: titleBar.height
            Layout.fillWidth: true
        }

        // 主体内容区域
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    FloatLayer {
        id: floatLayer
        anchors.topMargin: titleBarHeight
        z: 998
    }

    // 标题栏
    TitleBar {
        id: titleBar
        window: baseWindow
        icon: baseWindow.icon || ""
        title: baseWindow.title || ""
        useNativeMacControls: baseWindow.useNativeMacFrame
        Layout.fillWidth: true
        height: baseWindow.titleBarHeight

        maximizeEnabled: baseWindow.maximizeEnabled
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: Utils.backdropEnabled ? "transparent" : Theme.currentTheme.colors.backgroundColor
        border.color: Theme.currentTheme.colors.windowBorderColor
        border.width: baseWindow.useNativeMacFrame ? 0 : 1
        radius: baseWindow.useNativeMacFrame ? 0 : Theme.currentTheme.appearance.windowRadius
        z: -1
        clip: true

        Behavior on color {
            ColorAnimation {
                duration: Utils.backdropEnabled ? 0 : 150
            }
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Utils.appearanceSpeed
        }
    }

    //改变鼠标形状
    MouseArea {
        anchors.fill: parent
        hoverEnabled: !baseWindow.useNativeMacFrame && baseWindow.visibility !== Window.Maximized
        z: -1
        cursorShape: {
            if (baseWindow.useNativeMacFrame || baseWindow.visibility === Window.Maximized) {
                return Qt.ArrowCursor
            }
            const p = Qt.point(mouseX, mouseY)
            const b = Utils.windowDragArea
            if (p.x < b && p.y < b) return Qt.SizeFDiagCursor
            if (p.x >= width - b && p.y >= height - b) return Qt.SizeFDiagCursor
            if (p.x >= width - b && p.y < b) return Qt.SizeBDiagCursor
            if (p.x < b && p.y >= height - b) return Qt.SizeBDiagCursor
            if (p.x < b || p.x >= width - b) return Qt.SizeHorCursor
            if (p.y < b || p.y >= height - b) return Qt.SizeVerCursor
            return Qt.ArrowCursor
        }
        acceptedButtons: Qt.NoButton
    }

    DragHandler {
        id: resizeHandler
        enabled: false
        grabPermissions: TapHandler.TakeOverForbidden
        target: null
        onActiveChanged: if (active && baseWindow.visibility !== Window.Maximized) {
            const p = resizeHandler.centroid.position
            const b = Utils.windowDragArea + 10
            let e = 0;
            if (p.x < b) e |= Qt.LeftEdge
            if (p.x >= width - b) e |= Qt.RightEdge
            if (p.y < b) e |= Qt.TopEdge
            if (p.y >= height - b) e |= Qt.BottomEdge
            baseWindow.startSystemResize(e)
        }
    }
}
