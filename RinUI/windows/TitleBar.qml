import QtQuick 2.12
import QtQuick.Controls 2.3
import QtQuick.Layouts
import QtQuick.Window 2.3
import "../themes"
import "../components"
import "../windows"

Item {
    id: root
    // [RinUI FIX] 给原生过滤器定位用: WM_NCHITTEST 需要沿着项树找出标题栏里
    // 真正会接收鼠标事件的控件(搜索框、返回按钮……), 让它们留在客户区。
    objectName: "rinuiTitleBar"
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
    // [RinUI FIX] 右侧窗口控制按钮区的宽度, 由宿主窗口 alias 出去,
    // 供 WinEventManager 的 WM_NCHITTEST 把按钮那块留在客户区。
    readonly property real windowControlsWidth: windowControls ? windowControls.width : 0
    // [RinUI FIX] 最大化按钮在窗口内容区里的矩形(逻辑像素), 推给宿主窗口的
    // titleBarMaxButtonRect —— WM_NCHITTEST 靠它在那一小块返回 HTMAXBUTTON,
    // Windows 11 才会在鼠标悬停时弹出 Snap Layouts 布局选择器。
    readonly property rect maxButtonRect: {
        // mapToItem() 不会替这个绑定建立依赖, 布局变化时不会重新求值。
        // 这里先显式读一遍位置/尺寸, 保证窗口缩放后矩形跟着更新。
        var _dep = root.width + root.height + windowControls.x + windowControls.y
                + windowControls.width + maximizeBtn.x + maximizeBtn.y
                + maximizeBtn.width + maximizeBtn.height
        if (!maximizeBtn || !maximizeBtn.visible || !windowControls.visible)
            return Qt.rect(0, 0, 0, 0)
        var p = maximizeBtn.mapToItem(null, 0, 0)
        return Qt.rect(Math.round(p.x), Math.round(p.y),
                       Math.round(maximizeBtn.width), Math.round(maximizeBtn.height))
    }
    Binding {
        target: root.window
        property: "titleBarMaxButtonRect"
        value: root.maxButtonRect
        when: root.window !== null
    }
    // [RinUI FIX] 三个窗口按钮左边留一条"必定可拖动"的安全区。无论窗口多窄、
    // 标题栏里的控件多长, 这条带子始终保持 HTCAPTION, 窗口永远拖得动。
    // (修复标题栏拖动之前, 整条标题栏都是客户区, 自然处处能拖; 现在交给系统后
    //  需要显式留出这条带子, 否则控件一挤满就没地方按了)
    readonly property int titleBarSafeWidth: 32
    Binding {
        target: root.window
        property: "titleBarSafeWidth"
        value: root.titleBarSafeWidth
        when: root.window !== null
    }
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
            // 仅在 titleBarNativeDragDisabled 为 true 时使用: 按下瞬间光标相对窗口的偏移
            property point grabOffset: "0,0"

            readonly property bool nativeDrag: window
                && Qt.platform.os === "windows"
                && window.titleBarNativeDragDisabled !== true

            onPressed: {
                clickPos = Qt.point(mouseX, mouseY)
                if (Qt.platform.os === "windows" && !nativeDrag
                        && window && WindowManager._isWinMgrInitialized()) {
                    var c0 = WinEventManager.cursorPos()

                    grabOffset = Qt.point(c0.x - window.x, c0.y - window.y)
                }
            }
            onDoubleClicked: toggleMaximized()
            onPositionChanged: (mouse) => {
                if (!window)
                    return

                if (window.isMaximized || window.isFullScreen || window.visibility === Window.Maximized) {
                    return
                }

                // [RinUI FIX] Windows 上标题栏已经是真正的非客户区(HTCAPTION),
                // 拖动 / 双击最大化 / Aero Snap 全部由系统接管, QML 这边不要再插手:
                //  - 之前在这里同步 SendMessage(SC_MOVE) 会进入模态移动循环, 吞掉
                //    WM_LBUTTONUP, 让 MouseArea.pressed 永久停在 true, 标题栏再也拖不动;
                //  - 改成手动 setX/setY 之后, 又和原生拖动路径打架、还会抖动。
                //
                // 只有应用显式设了 titleBarNativeDragDisabled: true(标题栏里放了自定义
                // 可交互内容)时, 才走下面这条手动拖动兜底路径。
                if (Qt.platform.os === "windows") {
                    if (nativeDrag || !WindowManager._isWinMgrInitialized()) {
                        return
                    }

                    var c = WinEventManager.cursorPos()

                    window.setX(c.x - grabOffset.x)
                    window.setY(c.y - grabOffset.y)
                    return
                }

                //其他平台: 保持原有算法
                let delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)

                window.setX(window.x + delta.x)
                window.setY(window.y + delta.y)
            }
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.macNativeContentVerticalOffset
        height: parent.height
        anchors.leftMargin: root.isMacOS ? 0 : 4
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
            id: leadingContentItem
            objectName: "rinuiTitleBarLeadingHost"
            Layout.fillHeight: true
            Layout.preferredWidth: childrenRect.width
            visible: children.length > 0
            clip: true
        }

        Item {
            // custom
            id: contentItem
            objectName: "rinuiTitleBarContentHost"
            Layout.fillWidth: true
            Layout.fillHeight: true
            // [RinUI FIX] 窗口变窄时先把内容区压小(控件跟着缩), 而不是让控件
            // 一路盖到右上角三个按钮和它们左边的安全区上。
            // macOS 上右侧没有这排按钮（用原生红绿灯），不需要限制；
            // Windows / Linux 都有自绘的最小化/最大化/关闭，都要让位。
            Layout.maximumWidth: root.isMacOS
                                 ? Number.POSITIVE_INFINITY
                                 : Math.max(0, root.width - windowControls.width
                                            - root.titleBarSafeWidth - 48)
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
                objectName: "rinuiMaximizeBtn"
                mode: 0
                enabled: root.maximizeEnabled
                visible: root.maximizeVisible
                // 这块区域交给系统做 HTMAXBUTTON 之后收不到客户区 hover,
                // 悬停高亮由原生过滤器回填到窗口的 titleBarMaxButtonHovered 上
                externalHovered: root.window ? root.window.titleBarMaxButtonHovered === true : false
                externalPressed: root.window ? root.window.titleBarMaxButtonPressed === true : false

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
