import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../../windows"
import "../../themes"
import "../../utils"

Window {
    id: baseWindow
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
    property int macNativeTitleBarFlags: Qt.Window
        | Qt.CustomizeWindowHint
        | Qt.WindowTitleHint
        | Qt.WindowSystemMenuHint
        | expandedClientAreaHint
        | noTitleBarBackgroundHint
    property int windowsNativeTitleBarFlags: Qt.Window

    flags: (useNativeMacFrame
        ? macNativeTitleBarFlags
        : (isWindows
            ? windowsNativeTitleBarFlags
            : (Qt.FramelessWindowHint | Qt.Window)))
        | Qt.WindowMinimizeButtonHint
        | Qt.WindowMaximizeButtonHint
        | Qt.WindowCloseButtonHint

    color: useNativeMacFrame ? Theme.currentTheme.colors.backgroundColor : "transparent"
    default property alias content: contentArea.data
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
    // [RinUI FIX] 当前系统有没有"原生窗口圆角"(Win11 有, Win10 没有)。
    // Windows 上的原生过滤器会在初始化时按 is_win11() 覆盖它; 其他平台保持 true。
    property bool windowCornersSupported: true
    // [RinUI FIX] 窗口处于贴靠 / 最大化状态时为 true: 这些状态下 Windows 11 的窗口
    // 是直角的, QML 自己画的圆角(背景、关闭按钮高亮)必须跟着关掉
    property bool windowCornersSquare: false

    // 内容层右下角应该用的圆角：窗口本身是直角时（最大化 / 贴靠 / Snap 布局，
    // 或者 Win10 本来就没有系统圆角）必须为 0，否则窗口方、内容圆，角上会凸出一小块。
    // 只影响右下角，左上角仍走它自己的逻辑。
    readonly property int windowContentRadius: (
        (windowCornersSquare || visibility === Window.Maximized
         || windowCornersSupported === false)
            ? 0
            : Theme.currentTheme.appearance.windowRadius
    )
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
        // 只有系统圆角为直角（最大化 / 贴靠）时才跟着变直角。
        // 非 Windows 平台没有原生过滤器写 windowCornersSquare，所以额外认 visibility。
        radius: (
            (baseWindow.useNativeMacFrame || baseWindow.windowCornersSquare
             || baseWindow.visibility === Window.Maximized)
                ? 0
                : Theme.currentTheme.appearance.windowRadius
        )
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
