import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../../windows"
import "../../themes"
import "../../utils"

Window {
    id: baseWindow
    flags: Qt.FramelessWindowHint | Qt.Window | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint | Qt.WindowCloseButtonHint

    color: "transparent"
    default property alias content: contentArea.data
    property int titleBarHeight: Theme.currentTheme.appearance.dialogTitleBarHeight
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
        anchors.bottomMargin: Utils.windowDragArea
        anchors.leftMargin: Utils.windowDragArea
        anchors.rightMargin: Utils.windowDragArea
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
        Layout.fillWidth: true
        height: baseWindow.titleBarHeight

        maximizeEnabled: baseWindow.maximizeEnabled
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: Utils.backdropEnabled ? "transparent" : Theme.currentTheme.colors.backgroundColor
        border.color: Theme.currentTheme.colors.windowBorderColor
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
        hoverEnabled: baseWindow.visibility !== Window.Maximized
        z: -1
        cursorShape: {
            const p = Qt.point(mouseX, mouseY)
            const b = Utils.windowDragArea
            if (p.x < b && p.y < b) return Qt.SizeFDiagCursor
            if (p.x >= width - b && p.y >= height - b) return Qt.SizeFDiagCursor
            if (p.x >= width - b && p.y < b) return Qt.SizeBDiagCursor
            if (p.x < b && p.y >= height - b) return Qt.SizeBDiagCursor
            if (p.x < b || p.x >= width - b) return Qt.SizeHorCursor
            if (p.y < b || p.y >= height - b) return Qt.SizeVerCursor
        }
        Component.onCompleted: {
            cursorShape = Qt.ArrowCursor
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
