import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../themes"
import "../windows"
import "../components"

ApplicationWindow {
    id: baseWindow
    // visible: true
    // width: 800
    // height: 600
    // minimumWidth: 400
    // minimumHeight: 300
    property int hwnd: 0
    property bool isRinUIWindow: true
    property bool isMacOS: Qt.platform.os === "osx" || Qt.platform.os === "macos" || Qt.platform.os === "darwin"
    property bool isWindows: Qt.platform.os === "windows"
    // Native traffic lights + single custom titlebar integration on macOS.
    property bool useNativeMacFrame: isMacOS
    // Fine-tune custom title content baseline to match native traffic lights.
    property int macNativeContentVerticalOffset: useNativeMacFrame ? -2 : 0
    property int expandedClientAreaHint: typeof Qt.ExpandedClientAreaHint !== "undefined"
        ? Qt.ExpandedClientAreaHint
        : 0
    property int noTitleBarBackgroundHint: typeof Qt.NoTitleBarBackgroundHint !== "undefined"
        ? Qt.NoTitleBarBackgroundHint
        : 0

    flags: (useNativeMacFrame
        ? (Qt.Window
            | Qt.CustomizeWindowHint
            | Qt.WindowTitleHint
            | Qt.WindowSystemMenuHint
            | Qt.ExpandedClientAreaHint
            | Qt.NoTitleBarBackgroundHint)
        : (Qt.Window | Qt.FramelessWindowHint))
        | Qt.WindowMinimizeButtonHint
        | Qt.WindowMaximizeButtonHint
        | Qt.WindowCloseButtonHint
    color: useNativeMacFrame ? Theme.currentTheme.colors.backgroundColor : "transparent"
    topPadding: 0
    
    Component.onCompleted: {
        if (baseWindow.isWindows) {
            baseWindow.flags = baseWindow.flags & ~Qt.FramelessWindowHint
            WinEventManager.syncWindowFrame(baseWindow)
        }
    }

    // 自定义属性
    property var icon: ""  // 图标
    property alias titleEnabled: titleBar.titleEnabled
    property alias minimizeEnabled: titleBar.minimizeEnabled
    // property alias maximizeEnabled: titleBar.maximizeEnabled
    property bool maximizeEnabled: maximumHeight === 16777215 && maximumWidth === 16777215
    property alias closeEnabled: titleBar.closeEnabled

    property alias minimizeVisible: titleBar.minimizeVisible
    property alias maximizeVisible: titleBar.maximizeVisible
    property alias closeVisible: titleBar.closeVisible

    property int titleBarHeight: Theme.currentTheme.appearance.dialogTitleBarHeight
    property alias titleBarArea: titleBar.content
    property alias titleBarHost: titleBar.contentHost
    property alias titleBarLeadingArea: titleBar.leadingContent
    property alias titleBarLeadingHost: titleBar.leadingContentHost

    // [RinUI FIX] 标题栏右侧按钮区宽度, WM_NCHITTEST 用它把按钮排除在 HTCAPTION 之外
    property real titleBarButtonWidth: titleBar.windowControlsWidth
    // [RinUI FIX] 三个按钮左边那条"必定可拖动"安全区的宽度(逻辑像素)
    property real titleBarSafeWidth: 32
    // [RinUI FIX] 最大化按钮在内容区里的矩形, WM_NCHITTEST 用它返回 HTMAXBUTTON
    // 从而让 Windows 11 弹出 Snap Layouts 布局选择器
    property rect titleBarMaxButtonRect: Qt.rect(0, 0, 0, 0)
    // [RinUI FIX] 指针是否停在该按钮上(该区域是非客户区, QML 收不到 hover)
    property bool titleBarMaxButtonHovered: false
    // [RinUI FIX] 该按钮是否正被按下(同上, 客户的按下/松开事件也收不到)
    property bool titleBarMaxButtonPressed: false
    // [RinUI FIX] 标题栏里应用自定义控件的矩形, WM_NCHITTEST 命中时返回 HTCLIENT,
    // 免得标题栏上的搜索框/返回按钮被当成拖动区域、点不动
    property var titleBarInteractiveRects: []
    // [RinUI FIX] 标题栏里若放了自定义可交互内容, 置 true 可让整条标题栏保持在客户区
    property bool titleBarNativeDragDisabled: false
    // [RinUI FIX] 窗口处于贴靠 / 最大化状态时为 true: 这些状态下 Windows 11 的窗口
    // 是直角的, QML 自己画的圆角(背景、关闭按钮高亮)必须跟着关掉
    property bool windowCornersSquare: false


    // 直接添加子项
    property alias framelessMenuBar: menuBarArea.children  // 无边框模式时菜单栏
    default property alias content: contentArea.children
    property alias floatLayer: floatLayer

    // 最大化样式
    onVisibilityChanged: {
        if (baseWindow.useNativeMacFrame) {
            background.border.width = 0
            return
        }
        // 圆角交给下面的绑定(windowCornersSquare), 这里只处理边框
        background.border.width = 1
    }

    // 布局
    ColumnLayout {
        anchors.fill: parent
        // anchors.topMargin: Utils.windowDragArea
        anchors.bottomMargin: baseWindow.useNativeMacFrame ? 0 : Utils.windowDragArea
        anchors.leftMargin: baseWindow.useNativeMacFrame ? 0 : Utils.windowDragArea
        anchors.rightMargin: baseWindow.useNativeMacFrame ? 0 : Utils.windowDragArea
        spacing: 0

        // 顶部边距
        Item {
            Layout.preferredHeight: titleBar.height
            Layout.fillWidth: true
        }

        // menubar
        Item {
            id: menuBarArea
            Layout.fillWidth: true
        }

        // 主体内容区域
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
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


    // 背景样式
    background: Rectangle {
        id: background
        anchors.fill: parent
        color: Utils.backdropEnabled ? "transparent" : Theme.currentTheme.colors.backgroundColor
        border.color: Theme.currentTheme.colors.windowBorderColor
        border.width: baseWindow.useNativeMacFrame ? 0 : 1
        radius: (baseWindow.useNativeMacFrame || baseWindow.windowCornersSquare)
            ? 0
            : Theme.currentTheme.appearance.windowRadius
        z: -1
        clip: true

        // Shadow {}

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

    FloatLayer {
        id: floatLayer
        anchors.topMargin: titleBarHeight
        z: 998
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

    // 内容区域强制 ArrowCursor，防止边缘resize光标在被上层控件遮挡时残留
    MouseArea {
        anchors.fill: parent
        anchors.topMargin: 0
        anchors.bottomMargin: baseWindow.useNativeMacFrame ? 0 : Utils.windowDragArea
        anchors.leftMargin: baseWindow.useNativeMacFrame ? 0 : Utils.windowDragArea
        anchors.rightMargin: baseWindow.useNativeMacFrame ? 0 : Utils.windowDragArea
        z: -1
        acceptedButtons: Qt.NoButton
        hoverEnabled: false
        cursorShape: Qt.ArrowCursor
    }

    DragHandler {
        id: resizeHandler
        grabPermissions: TapHandler.TakeOverForbidden
        target: null
        enabled: !baseWindow.useNativeMacFrame && Qt.platform.os !== "windows"
        onActiveChanged: if (active && baseWindow.visibility !== Window.Maximized) {
            const p = resizeHandler.centroid.position
            const b = Utils.windowDragArea
            let e = 0;
            if (p.x < b) e |= Qt.LeftEdge
            if (p.x >= width - b) e |= Qt.RightEdge
            if (p.y < b) e |= Qt.TopEdge
            if (p.y >= height - b) e |= Qt.BottomEdge
            if (e !== 0) {
                baseWindow.startSystemResize(e)
            }
        }
    }
}
