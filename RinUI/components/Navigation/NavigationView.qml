import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"
import "../../windows"


RowLayout {
    // 外观 / Appearance //
    property bool appLayerEnabled: true  // 应用层背景
    property alias navExpandWidth: navigationBar.expandWidth  // 导航栏宽度
    property alias navMinimumExpandWidth: navigationBar.minimumExpandWidth  // 导航栏保持展开时窗口的最小宽度

    property alias navigationBar: navigationBar  // 导航栏
    property alias navigationItems: navigationBar.navigationItems  // 导航栏item
    property alias currentPage: navigationBar.currentPage  // 当前页面索引
    property var lastPages: []  // 历史页面栈, 最多保存两个页面
    property string defaultPage: ""  // 默认索引项
    property int pushEnterFromY: height
    property var window: parent  // 窗口对象

    // 页面组件缓存(Component)
    property var componentCache: ({})
    property bool pushInProgress: false
    property var loadingPages: ({})
    property var itemsToRestoreAfterReload: []

    signal pageChanged()  // 页面切换信号

    id: navigationView
    anchors.fill: parent

    Connections {
        target: window
        function onWidthChanged() {
            navigationBar.collapsed = navigationBar.isNotOverMinimumWidth()  // 判断窗口是否小于最小宽度
        }
    }

    NavigationBar {
        id: navigationBar
        windowTitle: window.title
        windowIcon: window.icon
        windowWidth: window.width
        stackView: stackView
        z: 999
        Layout.fillHeight: true
    }

    // 主体内容区域
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

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
            }
        }

        Rectangle {
            id: appLayer
            width: parent.width + Utils.windowDragArea + radius
            height: parent.height + Utils.windowDragArea + radius
            color: Theme.currentTheme.colors.layerColor
            border.color: Theme.currentTheme.colors.cardBorderColor
            border.width: 1
            opacity: window.appLayerEnabled
            radius: Theme.currentTheme.appearance.windowRadius
        }


        StackView {
            id: stackView
            anchors.fill: parent
            anchors.leftMargin: 1
            anchors.topMargin: 1


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
                    easing.type: Easing.OutQuint
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

            initialItem: Item {}

        }


        Component.onCompleted: {
            if (navigationItems.length > 0) {
                if (defaultPage !== "") {
                    safePush(defaultPage, false, true)
                } else {
                    safePush(navigationItems[0].page, false, true)  // 推送默认页面
                }  // 推送页面
            }
        }
    }

    function safePop() {
        // console.log("safePop调用 - 当前lastPages长度:", lastPages.length, "内容:", JSON.stringify(lastPages))
        // console.log("Popping Page; Depth:", stackView.depth)
        if (lastPages.length > 0) {
            let previousPage = lastPages[lastPages.length - 1]  // 获取最近的页面
            if (lastPages.length === 1) {
                lastPages = []
            } else {
                lastPages = lastPages.slice(0, -1)  // 移除最后一个元素
            }
            if (stackView.depth > 1) {
                currentPage = previousPage
                // console.log("执行pop操作 - 返回到页面:", currentPage, "剩余lastPages长度:", lastPages.length)
                stackView.pop()
                pageChanged()
            } else {
                currentPage = previousPage
                safePush(previousPage, false, true)  // 重新加载页面
            }
        } else {
            console.log("Can't pop: no pages in history")
        }
    }

    function pop() {
        safePop()
    }

    function push(page, reload, fromNavigation) {
        if (reload === undefined) reload = false
        if (fromNavigation === undefined) fromNavigation = false
        safePush(page, reload, fromNavigation)
    }

    function safePush(page, reload, fromNavigation) {
        // 防止动画冲突
        if (pushInProgress) {
            // console.log("Push already in progress, queuing...")
            Qt.callLater(function() { safePush(page, reload, fromNavigation) })
            return
        }

        // 无效检测
        if (!(typeof page === "object" || typeof page === "string" || page instanceof Component)) {
            console.error("Invalid page type:", typeof page)
            return
        }

        let pageKey = normalizeKeyFromPage(page)  //缓存键
        if (!fromNavigation) {
            if (navigationBar.currentPage === pageKey && !reload) {
                console.log("Page already current, skipping:", pageKey)
                return
            }
            if (loadingPages[pageKey] && !reload) {
                console.log("Page is loading, skipping:", pageKey)
                return
            }
        }
        setPushInProgress(true)

        if (page instanceof Component) {
            // 对于Component类型, 直接使用
            asyncPush(page, pageKey, reload, fromNavigation)
        } else if (typeof page === "object" || typeof page === "string") {
            // 检查缓存
            if (!componentCache[pageKey] || reload) {
                loadingPages[pageKey] = true  // 正在加载
                let component = Qt.createComponent(page)

                if (component.status === Component.Ready) {
                    componentCache[pageKey] = component
                    loadingPages[pageKey] = false
                    // console.log("Created and cached component:", pageKey)
                    asyncPush(component, pageKey, reload, fromNavigation)
                } else if (component.status === Component.Error) {
                    console.error("Failed to load:", page, component.errorString())
                    cleanupLoading(pageKey, true)
                    if (currentPage !== "") {
                        lastPages.push(currentPage)
                    }
                    currentPage = pageKey
                    pageChanged()
                    stackView.push("ErrorPage.qml", {
                        errorMessage: component.errorString(),
                        page: page,
                    })
                    return
                } else {
                    // 组件还在加载中
                    let handler = function() {
                        component.statusChanged.disconnect(handler)
                        if (component.status === Component.Ready) {
                            componentCache[pageKey] = component
                            loadingPages[pageKey] = false
                            // console.log("Async loaded and cached component:", pageKey)
                            asyncPush(component, pageKey, reload, fromNavigation)
                        } else if (component.status === Component.Error) {
                            console.error("Failed to async load:", page, component.errorString())
                            cleanupLoading(pageKey, true)
                            // 失败时推送错误页面
                            if (currentPage !== "") {
                                lastPages.push(currentPage)
                            }
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
                        console.warn("Handler connection failed, component may already be connected:", e)
                        if (component.status === Component.Ready) {
                            componentCache[pageKey] = component
                            loadingPages[pageKey] = false
                            asyncPush(component, pageKey, reload, fromNavigation)
                        } else if (component.status === Component.Error) {
                            cleanupLoading(pageKey, true)
                        }
                    }
                    return
                }
            } else {
                // console.log("Using cached component:", pageKey)
                asyncPush(componentCache[pageKey], pageKey, reload, fromNavigation)
            }
        }
    }

    function cleanupPageForReload(pageKey) {
        if (!pageKey) return false
        let foundAndCleaned = false
        // 查找匹配页面实例
        let targetIndex = -1
        let targetObjectName = pageKey.includes("/") ? pageKey.split("/").pop().replace(".qml", "") : pageKey
        for (let i = stackView.depth - 1; i >= 0; i--) {
            let item = stackView.get(i)
            if (item && item.objectName === targetObjectName) {
                targetIndex = i
                console.log("Found instance for reload:", pageKey, "at index:", i)
                break // 只处理第一个匹配项
            }
        }
        if (targetIndex >= 0) {
            foundAndCleaned = true
            if (targetIndex === stackView.depth - 1) {
                let poppedItem = stackView.pop(null, StackView.Immediate)
                if (poppedItem) {
                    // console.log("Destroyed top-level instance for reload:", pageKey)
                    poppedItem.destroy()
                }
            } else {
                // 非顶层特殊处理
                let itemsToRestore = []
                for (let i = stackView.depth - 1; i > targetIndex; i--) {
                    let item = stackView.get(i)
                    if (item) {
                        let pageInfo = {
                            component: componentCache[item.objectName] || null,
                            pageKey: item.objectName,
                            properties: {} // 扩展保存页面状态
                        }
                        itemsToRestore.unshift(pageInfo)
                    }
                }
                while (stackView.depth > targetIndex + 1) {
                    stackView.pop(null, StackView.Immediate)
                }
                // 销毁目标页面
                let targetItem = stackView.pop(null, StackView.Immediate)
                if (targetItem) {
                    console.log("Destroyed middle-level instance for reload:", pageKey)
                    targetItem.destroy()
                }
                navigationView.itemsToRestoreAfterReload = itemsToRestore
            }
        }

        return foundAndCleaned
    }

    function asyncPush(component, pageKey, reload, fromNavigation) {
        // console.log("asyncPush调用 - pageKey:", pageKey, "reload:", reload, "fromNavigation:", fromNavigation, "当前lastPages长度:", lastPages.length)
        if (reload) {
            let currentObjectName = normalizeKeyFromPage(pageKey).includes("/") ?
                normalizeKeyFromPage(pageKey).split("/").pop().replace(".qml", "") :
                normalizeKeyFromPage(pageKey)
            if (stackView.currentItem && stackView.currentItem.objectName === currentObjectName) {
                let newPageInstance = component.createObject(stackView, {
                    objectName: normalizeKeyFromPage(pageKey).includes("/") ?
                        normalizeKeyFromPage(pageKey).split("/").pop().replace(".qml", "") :
                        normalizeKeyFromPage(pageKey)
                })
                if (!newPageInstance) {
                    console.error("Failed to create page instance for reload:", pageKey)
                    setPushInProgress(false)
                    return
                }
                stackView.replace(stackView.currentItem, newPageInstance)
                Qt.callLater(function() {
                    if (stackView.busy && stackView.currentItem === newPageInstance) {
                        let animationHandler = function() {
                            if (stackView.currentItem === newPageInstance && !stackView.busy) {
                                setPushInProgress(false)
                                stackView.busyChanged.disconnect(animationHandler)
                                // console.log("Current page reload animation completed for:", pageKey)
                            }
                        }
                        if (!stackView.busy) {
                            setPushInProgress(false)
                        } else {
                            stackView.busyChanged.connect(animationHandler)
                        }
                    } else {
                        setPushInProgress(false)
                        // console.log("Current page reload completed immediately for:", pageKey)
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
                // console.log("添加到历史记录 - 当前页面:", currentPage)
                if (lastPages.length === 0) {
                    lastPages = [currentPage]
                } else if (lastPages.length === 1) {
                    lastPages = [lastPages[0], currentPage]
                } else {
                    // 保持最多两个页面, 移除最旧的
                    lastPages = [lastPages[1], currentPage]
                }
            }
        }
        let currentObjectName = stackView.currentItem ? stackView.currentItem.objectName : ""
        let targetObjectName = normalizeKeyFromPage(pageKey).includes("/") ?
            normalizeKeyFromPage(pageKey).split("/").pop().replace(".qml", "") :
            normalizeKeyFromPage(pageKey)

        if (!reload || (reload && currentObjectName !== targetObjectName)) {
            currentPage = pageKey
        }
        // console.log("更新后 - currentPage:", currentPage, "lastPages长度:", lastPages.length, "内容:", JSON.stringify(lastPages))
        pageChanged()
        // 创建新的页面实例
        let pageInstance = component.createObject(stackView, {
            objectName: normalizeKeyFromPage(pageKey).includes("/") ?
                normalizeKeyFromPage(pageKey).split("/").pop().replace(".qml", "") :
                normalizeKeyFromPage(pageKey)
        })
        if (!pageInstance) {
            console.error("Failed to create page instance for:", pageKey)
            setPushInProgress(false)
            return
        }
        stackView.push(pageInstance)
        if (loadingPages[pageKey]) {
            loadingPages[pageKey] = false
            delete loadingPages[pageKey]
        }

        Qt.callLater(function() {
            if (stackView.busy && stackView.currentItem === pageInstance) {
                let animationHandler = function() {
                    if (stackView.currentItem === pageInstance && !stackView.busy) {
                        setPushInProgress(false)
                        stackView.busyChanged.disconnect(animationHandler)
                        // console.log("Navigation animation completed for:", pageKey)
                        restoreItemsAfterReload()
                    }
                }
                if (!stackView.busy) {
                    setPushInProgress(false)
                    restoreItemsAfterReload()
                } else {
                    stackView.busyChanged.connect(animationHandler)
                }
            } else {
                setPushInProgress(false)
                // console.log("Navigation completed immediately for:", pageKey)
                restoreItemsAfterReload()
            }
        })
    }

    function restoreItemsAfterReload() {
        if (itemsToRestoreAfterReload.length > 0) {
            // console.log("Restoring", itemsToRestoreAfterReload.length, "pages after reload")
            let itemsToRestore = itemsToRestoreAfterReload
            itemsToRestoreAfterReload = []
            for (let i = 0; i < itemsToRestore.length; i++) {
                    let pageInfo = itemsToRestore[i]
                    if (pageInfo.component && pageInfo.pageKey) {
                        let pageInstance = pageInfo.component.createObject(stackView, {
                            objectName: normalizeKeyFromPage(pageInfo.pageKey).includes("/") ?
                                normalizeKeyFromPage(pageInfo.pageKey).split("/").pop().replace(".qml", "") :
                                normalizeKeyFromPage(pageInfo.pageKey)
                        })
                        if (pageInstance) {
                            stackView.push(pageInstance, {}, StackView.Immediate)
                            // console.log("Restored page:", pageInfo.pageKey)
                        } else {
                            console.error("Failed to restore page instance for:", pageInfo.pageKey)
                        }
                    }
                }
        }
    }

    function cleanupLoading(pageKey, resetPush) {  // 重置状态
        if (resetPush === undefined) resetPush = true
        if (pageKey && loadingPages[pageKey]) {
            loadingPages[pageKey] = false
            delete loadingPages[pageKey]
            // console.log("Cleaned up loadingPages for:", pageKey)
        }
        if (resetPush) {
            setPushInProgress(false)
        }
    }

    function setPushInProgress(inProgress) {
        pushInProgress = inProgress
        if (!inProgress) {
            // console.log("Push operation completed, ready for next navigation")
        }
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
