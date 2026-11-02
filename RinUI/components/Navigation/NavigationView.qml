import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import QtQuick.Window 2.15
import QtQuick.Shapes 1.15
import "../../themes"
import "../../animations"
import "../../components"
import "../../windows"


RowLayout {
    // 外观 / Appearance //
    property bool appLayerEnabled: true  // 应用层背景
    // 内容卡片圆角：用上层角遮罩裁切（不 layer 文字），与 appLayer.radius 对齐
    property bool contentCornerClipEnabled: true
    property alias navExpandWidth: navigationBar.expandWidth  // 导航栏宽度
    property alias navMinimumExpandWidth: navigationBar.minimumExpandWidth  // 导航栏保持展开时窗口的最小宽度

    property alias navigationBar: navigationBar  // 导航栏
    property alias navigationItems: navigationBar.navigationItems  // 导航栏item
    property alias currentPage: navigationBar.currentPage  // 当前页面索引
    property var lastPages: []  // 历史页面栈, 最多保存两个页面
    property string defaultPage: ""  // 默认索引项
    property int pushEnterFromY: height / 2
    property var window: parent  // 窗口对象

    // 页面组件缓存(Component)
    property var componentCache: ({})
    property bool pushInProgress: false
    property bool replaceBackInProgress: false
    property var loadingPages: ({})
    property var itemsToRestoreAfterReload: []

    signal pageChanged()  // 页面切换信号

    id: navigationView
    anchors.fill: parent

    Connections {
        target: window
        function onWidthChanged() {
            if (navigationBar.isNotOverMinimumWidth()) {
                if (!navigationBar.collapsed) {
                    navigationBar.collapsed = true
                    navigationBar.collapsedByAutoResize = true
                }
            } else {
                if (navigationBar.collapsed && navigationBar.collapsedByAutoResize) {
                    navigationBar.collapsed = false
                    navigationBar.collapsedByAutoResize = false
                }
            }
        }
    }

    Component.onCompleted: {
        if (navigationBar.isNotOverMinimumWidth()) {
            if (!navigationBar.collapsed) {
                navigationBar.collapsed = true
                navigationBar.collapsedByAutoResize = true
            }
        }
    }

    NavigationBar {
        id: navigationBar
        window: navigationView.window
        windowTitle: window.title
        windowIcon: window.icon
        windowWidth: window.width
        closeButtonVisible: window && window.closeVisible !== undefined ? window.closeVisible : true
        minimizeButtonVisible: window && window.minimizeVisible !== undefined ? window.minimizeVisible : true
        maximizeButtonVisible: window && window.maximizeVisible !== undefined ? window.maximizeVisible : true
        useNativeMacControls: window && window.useNativeMacFrame !== undefined ? window.useNativeMacFrame : false
        stackView: stackView
        z: 999
        Layout.fillHeight: true
    }

    // 主体内容区域
    // 圆角底：appLayer（带 1px 描边），只有右下角是圆角 —— 内容贴着窗口边缘，
    // 方角会从窗口右下角戳出去，所以用一个卡片色的楔形把它削圆。
    // 左上角保持直角（要圆就必须给整页加 layer/遮罩，实测会把页面渲糊 18%）。
    Item {
        id: contentArea
        Layout.fillWidth: true
        Layout.fillHeight: true
        // 不能 clip：内容区要向右/下各溢出 Utils.windowDragArea，
        // 才能真正贴住窗口边缘（外层 ColumnLayout 留了 5px 拖动边距）
        clip: false

        readonly property real contentRadius: {
            if (window && window.visibility === Window.Maximized)
                return 0
            return Theme.currentTheme.appearance.windowRadius
        }

        // 右下角共用半径：卡片底(appLayer)与楔形必须一致，否则卡片描边会落在
        // 楔形圆弧内侧露出浅色弧线。比窗口圆角稍大，角才看得出来是圆的。
        readonly property real contentCornerRadius: contentRadius > 0
                                                    ? Math.ceil(contentRadius) + 3.5 : 0

        // 右下角楔形的填色：跟随窗口边框。
        // windowBorderColor 是半透明的（light #757575 @ 0.0924 / dark @ 0.0698），
        // 不能直接当填充（会把内容盖成半透明），所以先和背景色合成为不透明色，
        // 这样楔形和窗口描边是同一块材质。
        readonly property color cornerFillColor: {
            var fg = Theme.currentTheme.colors.windowBorderColor
            var bg = Theme.currentTheme.colors.backgroundColor
            var a = fg.a
            return Qt.rgba(fg.r * a + bg.r * (1 - a),
                           fg.g * a + bg.g * (1 - a),
                           fg.b * a + bg.b * (1 - a), 1)
        }

        // 右下角：内容贴着窗口边缘，方角会从窗口右下戳出来。
        // 这里用 Shape 画一个"角以外"的楔形（正方形减去四分之一圆），填窗口边框色盖住它，
        // 于是角看起来是圆的，且完全不经 layer，页面保持 1:1 像素不糊。
        Shape {
            id: brCornerShape
            // 贴到窗口客户区的真实右下角：内容区因为 ColumnLayout 的 5px 拖拽边距
            // 比窗口小一圈，用 contentArea + 负 margin 才能把楔形的圆心放正，
            // 否则楔形整体内缩，窗口角上会漏出一条直角边。
            anchors.right: contentArea.right
            anchors.bottom: contentArea.bottom
            anchors.rightMargin: -Utils.windowDragArea
            anchors.bottomMargin: -Utils.windowDragArea
            width: r
            height: r
            z: 2
            visible: r > 0 && navigationView.contentCornerClipEnabled
            // 与 appLayer 的右下圆角必须用同一个半径：两个图形半径不一致时，
            // 卡片那条 1px 描边会落在楔形圆弧内侧，露出一条浅色弧线。
            readonly property real r: contentArea.contentCornerRadius

            ShapePath {
                // layerColor 是半透明的（light 0.5 / dark 0.3），直接盖上去只会给内容"调亮"，
                // 看起来是一块方形半透明。这里把它和自己下面的背景色先合成成不透明色。
                fillColor: contentArea.cornerFillColor
                strokeColor: "transparent"
                startX: 0
                startY: brCornerShape.r
                PathAngleArc {
                    centerX: 0
                    centerY: 0
                    radiusX: brCornerShape.r
                    radiusY: brCornerShape.r
                    startAngle: 90
                    sweepAngle: -90
                    moveToStart: false
                }
                PathLine { x: brCornerShape.r; y: brCornerShape.r }
                PathLine { x: 0; y: brCornerShape.r }
            }
        }

        // 导航栏展开自动收起
        MouseArea {
            id: collapseCatcher
            anchors.fill: parent
            z: 1
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons

            visible: !navigationBar.collapsed && navigationBar.isNotOverMinimumWidth()

            onClicked: {
                navigationBar.collapsed = true
                navigationBar.collapsedByAutoResize = false
            }
        }

        Rectangle {
            id: appLayer
            // 卡片底色：右侧/底部贴到窗口边框内侧 1px（留出窗口自己的描边），
            // 左上角是直角，右下角是圆角（和窗口右下角对齐）
            width: parent.width + Utils.windowDragArea - 1
            height: parent.height + Utils.windowDragArea - 1
            color: Theme.currentTheme.colors.layerColor
            border.color: Theme.currentTheme.colors.cardBorderColor
            border.width: 1
            opacity: (window && window.appLayerEnabled !== undefined) ? window.appLayerEnabled : navigationView.appLayerEnabled
            radius: 0
            bottomRightRadius: contentArea.contentCornerRadius
        }

        StackView {
            id: stackView
            anchors.fill: parent
            anchors.leftMargin: 1
            anchors.topMargin: 1
            // 右/下各外扩 windowDragArea，抵消 ColumnLayout 的拖动边距，使内容贴住窗口边缘
            anchors.rightMargin: 1 - Utils.windowDragArea
            anchors.bottomMargin: 1 - Utils.windowDragArea
            clip: true

            // 内容区不再做 layer + 遮罩：那是为了裁左上圆角，代价是整页走一层
            // 按逻辑像素分配的纹理，1.5x 屏上锐度会掉约 18%（实测边缘能量 0.954 → 0.784）。
            // 现在左上角是直角，不需要裁；右下角由下面的 Shape 楔形盖色处理。

            // 切换动画 / Page Transition //
            pushEnter : Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Utils.appearanceSpeed
                    easing.type: Easing.InOutQuad
                }

                PropertyAnimation {
                    property: "y"
                    from: pushEnterFromY
                    to: 0
                    duration: Utils.animationSpeedMiddle
                    easing.type: Easing.Bezier
                    easing.bezierCurve: BezierCurve.pointToPoint
                }
            }

            pushExit : Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Utils.animationSpeed
                    easing.type: Easing.InOutQuad
                }
            }

            popExit : Transition {
                SequentialAnimation {
                    PauseAnimation {  // 延时 200ms
                        duration: Utils.animationSpeedFast * 0.6
                    }
                    PropertyAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: Utils.appearanceSpeed
                        easing.type: Easing.InOutQuad
                    }
                }

                PropertyAnimation {
                    property: "y"
                    from: 0
                    to: pushEnterFromY
                    duration: Utils.animationSpeed
                    easing.type: Easing.InQuint
                }
            }

            popEnter : Transition {
                SequentialAnimation {
                    PauseAnimation {  // 延时 200ms
                        duration: Utils.animationSpeed
                    }
                    PropertyAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 100
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            replaceEnter: Transition {
                SequentialAnimation {
                    PropertyAction {
                        property: "opacity"
                        value: 0
                    }
                    PauseAnimation {
                        duration: replaceBackInProgress ? Utils.animationSpeed : 87
                    }
                    PropertyAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: replaceBackInProgress ? 100 : Utils.appearanceSpeed
                        easing.type: Easing.InOutQuad
                    }
                }

                SequentialAnimation {
                    PropertyAction {
                        property: "y"
                        value: replaceBackInProgress ? 0 : pushEnterFromY
                    }
                    PauseAnimation {
                        duration: replaceBackInProgress ? 0 : 87
                    }
                    PropertyAnimation {
                        property: "y"
                        from: replaceBackInProgress ? 0 : pushEnterFromY
                        to: 0
                        duration: replaceBackInProgress ? 0 : 333
                        easing.type: Easing.Bezier
                        easing.bezierCurve: BezierCurve.pointToPoint
                    }
                }
            }

            replaceExit: Transition {
                SequentialAnimation {
                    PropertyAction {
                        property: "opacity"
                        value: 1
                    }
                    PauseAnimation {
                        duration: replaceBackInProgress ? 100 : 0
                    }
                    PropertyAnimation {
                        property: "opacity"
                        from: 1
                        to: replaceBackInProgress ? 0 : 0
                        duration: replaceBackInProgress ? 83 : 167
                    }
                }

                PropertyAnimation {
                    property: "y"
                    from: 0
                    to: replaceBackInProgress ? pushEnterFromY : 0
                    duration: replaceBackInProgress ? Utils.appearanceSpeed : 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: BezierCurve.softDismiss
                }
            }

            initialItem: Item {}

        }

        // 旧做法（左上/右下遮罩真裁切）已删除：遮罩要求 layer 整块内容，
        // 1.5x 屏上会让整页发糊，且纹理分辨率无法强制到物理像素。

        // 左上角：恢复原有方案 —— 用 RoundedCornerOverlay 在角上盖一层背景色，
        // 视觉上和窗口圆角一致（不做裁切、不加 layer，所以内容不会被渲糊）。
        RoundedCornerOverlay {
            anchors.fill: parent
            z: 2
            visible: contentArea.contentRadius > 0 && navigationView.contentCornerClipEnabled
            radius: contentArea.contentRadius
            topLeft: true
            bottomRight: false
            fillColor: Theme.currentTheme.colors.backgroundColor
        }

        Component.onCompleted: {
            if (navigationItems.length > 0) {
                if (defaultPage !== "") {
                    safePush(defaultPage, false, true)
                } else {
                    safePush(navigationItems[0].page, false, true)  // 推送默认页面
                }
            }
        }
    }

    function safePop() {
        if (lastPages.length > 0) {
            let previousPage = lastPages[lastPages.length - 1]  // 获取最近的页面
            if (lastPages.length === 1) {
                lastPages = []
            } else {
                lastPages = lastPages.slice(0, -1)  // 移除最后一个元素
            }
            if (stackView.depth > 1) {
                currentPage = previousPage
                stackView.pop()
                pageChanged()
            } else {
                replaceBackInProgress = true
                currentPage = previousPage
                safePush(previousPage, false, true)  // 重新加载页面
            }
        }
    }

    function pop() {
        safePop()
    }

    function push(page, properties) {
        if (properties === undefined) properties = {}
        safePush(page, false, false, properties)
    }

    function pushStack(page, properties) {
        if (properties === undefined) properties = {}
        safePush(page, false, true, properties)
    }

    function safePush(page, reload, fromNavigation, properties) {
        if (pushInProgress) {
            Qt.callLater(function() { safePush(page, reload, fromNavigation, properties) })
            return
        }

        if (!(typeof page === "object" || typeof page === "string" || page instanceof Component)) {
            console.error("Invalid page type:", typeof page)
            return
        }

        if (reload === undefined) reload = false
        if (fromNavigation === undefined) fromNavigation = false
        if (properties === undefined) properties = {}

        let pageKey = normalizeKeyFromPage(page)
        if (!fromNavigation) {
            if (navigationBar.currentPage === pageKey && !reload) {
                return
            }
            if (loadingPages[pageKey] && !reload) {
                return
            }
        }
        setPushInProgress(true)

        if (page instanceof Component) {
            asyncPush(page, pageKey, reload, fromNavigation, properties)
        } else if (typeof page === "object" || typeof page === "string") {
            if (!componentCache[pageKey] || reload) {
                loadingPages[pageKey] = true
                let component = Qt.createComponent(page)

                if (component.status === Component.Ready) {
                    componentCache[pageKey] = component
                    loadingPages[pageKey] = false
                    asyncPush(component, pageKey, reload, fromNavigation, properties)
                } else if (component.status === Component.Error) {
                    console.error("Failed to load:", page, component.errorString())
                    cleanupLoading(pageKey, true)
                    if (currentPage !== "") lastPages.push(currentPage)
                    currentPage = pageKey
                    pageChanged()
                    stackView.push("ErrorPage.qml", {
                        errorMessage: component.errorString(),
                        page: page,
                    })
                    return
                } else {
                    let handler = function() {
                        component.statusChanged.disconnect(handler)
                        if (component.status === Component.Ready) {
                            componentCache[pageKey] = component
                            loadingPages[pageKey] = false
                            asyncPush(component, pageKey, reload, fromNavigation, properties)
                        } else if (component.status === Component.Error) {
                            console.error("Failed to async load:", page, component.errorString())
                            cleanupLoading(pageKey, true)
                            if (currentPage !== "") lastPages.push(currentPage)
                            currentPage = pageKey
                            pageChanged()
                            stackView.push("ErrorPage.qml", {
                                errorMessage: component.errorString(),
                                page: page,
                            })
                        }
                    }
                    try {
                        component.statusChanged.connect(handler)
                    } catch (e) {
                        if (component.status === Component.Ready) {
                            componentCache[pageKey] = component
                            loadingPages[pageKey] = false
                            asyncPush(component, pageKey, reload, fromNavigation, properties)
                        } else if (component.status === Component.Error) {
                            cleanupLoading(pageKey, true)
                        }
                    }
                    return
                }
            } else {
                asyncPush(componentCache[pageKey], pageKey, reload, fromNavigation, properties)
            }
        }
    }

    function cleanupPageForReload(pageKey) {
        if (!pageKey) return false
        let foundAndCleaned = false
        let targetIndex = -1
        let targetObjectName = pageKey.includes("/") ? pageKey.split("/").pop().replace(".qml", "") : pageKey
        for (let i = stackView.depth - 1; i >= 0; i--) {
            let item = stackView.get(i)
            if (item && item.objectName === targetObjectName) {
                targetIndex = i
                break
            }
        }
        if (targetIndex >= 0) {
            foundAndCleaned = true
            if (targetIndex === stackView.depth - 1) {
                stackView.pop(null, StackView.Immediate)
            } else {
                let itemsToRestore = []
                for (let i = stackView.depth - 1; i > targetIndex; i--) {
                    let item = stackView.get(i)
                    if (item) {
                        let itemPageKey = item.__navPageKey || item.objectName
                        let pageInfo = {
                            component: componentCache[itemPageKey] || null,
                            pageKey: itemPageKey,
                            properties: {}
                        }
                        itemsToRestore.unshift(pageInfo)
                    }
                }
                while (stackView.depth > targetIndex + 1) stackView.pop(null, StackView.Immediate)
                stackView.pop(null, StackView.Immediate)
                navigationView.itemsToRestoreAfterReload = itemsToRestore
            }
        }
        return foundAndCleaned
    }

    function asyncPush(component, pageKey, reload, fromNavigation, properties) {
        if (properties === undefined) properties = {}

        if (reload) {
            let currentObjectName = normalizeKeyFromPage(pageKey).includes("/") ?
                normalizeKeyFromPage(pageKey).split("/").pop().replace(".qml", "") :
                normalizeKeyFromPage(pageKey)
            if (stackView.currentItem && stackView.currentItem.objectName === currentObjectName) {
                stackView.replace(stackView.currentItem, component, Object.assign({}, properties, {
                    objectName: currentObjectName
                }))
                Qt.callLater(function() {
                    if (stackView.busy) {
                        let busyHandler = function() {
                            if (!stackView.busy) {
                                setPushInProgress(false)
                                replaceBackInProgress = false
                                stackView.busyChanged.disconnect(busyHandler)
                            }
                        }
                        stackView.busyChanged.connect(busyHandler)
                    } else {
                        setPushInProgress(false)
                        replaceBackInProgress = false
                    }
                })
                return
            } else {
                cleanupPageForReload(pageKey)
            }
        }

        if (currentPage !== "" && !fromNavigation) {
            let currentObjectName = stackView.currentItem ? stackView.currentItem.objectName : ""
            let targetObjectName = normalizeKeyFromPage(pageKey).includes("/") ?
                normalizeKeyFromPage(pageKey).split("/").pop().replace(".qml", "") :
                normalizeKeyFromPage(pageKey)
            if (!reload || (reload && currentObjectName !== targetObjectName)) {
                if (lastPages.length === 0) lastPages = [currentPage]
                else if (lastPages.length === 1) lastPages = [lastPages[0], currentPage]
                else lastPages = [lastPages[1], currentPage]
            }
        }

        let targetObjectName = normalizeKeyFromPage(pageKey).includes("/") ?
            normalizeKeyFromPage(pageKey).split("/").pop().replace(".qml", "") :
            normalizeKeyFromPage(pageKey)

        if (!reload || (reload && (stackView.currentItem ? stackView.currentItem.objectName : "") !== targetObjectName))
            currentPage = pageKey

        pageChanged()

        let pageInstance = stackView.replace(stackView.currentItem, component, Object.assign({}, properties, {
            objectName: targetObjectName
        }))
        if (!pageInstance) {
            console.error("Failed to replace page:", pageKey)
            setPushInProgress(false)
            replaceBackInProgress = false
            return
        }

        if (loadingPages[pageKey]) {
            loadingPages[pageKey] = false
            delete loadingPages[pageKey]
        }

        Qt.callLater(function() {
            if (stackView.busy && stackView.currentItem === pageInstance) {
                let animationHandler = function() {
                    if (stackView.currentItem === pageInstance && !stackView.busy) {
                        setPushInProgress(false)
                        replaceBackInProgress = false
                        stackView.busyChanged.disconnect(animationHandler)
                        restoreItemsAfterReload()
                    }
                }
                if (!stackView.busy) {
                    setPushInProgress(false)
                    replaceBackInProgress = false
                    restoreItemsAfterReload()
                } else {
                    stackView.busyChanged.connect(animationHandler)
                }
            } else {
                setPushInProgress(false)
                replaceBackInProgress = false
                restoreItemsAfterReload()
            }
        })
    }

    function restoreItemsAfterReload() {
        if (itemsToRestoreAfterReload.length > 0) {
            let itemsToRestore = itemsToRestoreAfterReload
            itemsToRestoreAfterReload = []
            for (let i = 0; i < itemsToRestore.length; i++) {
                let pageInfo = itemsToRestore[i]
                if (pageInfo.component && pageInfo.pageKey) {
                    let objName = normalizeKeyFromPage(pageInfo.pageKey).includes("/") ?
                        normalizeKeyFromPage(pageInfo.pageKey).split("/").pop().replace(".qml", "") :
                        normalizeKeyFromPage(pageInfo.pageKey)
                    stackView.push(pageInfo.component, { objectName: objName }, StackView.Immediate)
                }
            }
        }
    }

    function cleanupLoading(pageKey, resetPush) {  // 重置状态
        if (resetPush === undefined) resetPush = true
        if (pageKey && loadingPages[pageKey]) {
            loadingPages[pageKey] = false
            delete loadingPages[pageKey]
        }
        if (resetPush) {
            setPushInProgress(false)
        }
    }

    function setPushInProgress(inProgress) {
        pushInProgress = inProgress
    }

    function normalizeKeyFromPage(page) {
        if (page instanceof Component) {
            return page.objectName || page.toString()
        } else if (typeof page === "string") {
            return page
        } else {
            return page.toString()
        }
    }

    function findPageByKey(key) {
        const item = menuItems.find(i => i.key === key);
        return item ? item.page : null;
    }
}
