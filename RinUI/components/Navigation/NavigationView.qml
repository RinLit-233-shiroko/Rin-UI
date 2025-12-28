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
    property alias navMinimumExpandWidth: navigationBar.minimumWindowWidth  // 导航栏保持展开时窗口的最小宽度

    property alias navigationBar: navigationBar  // 导航栏
    property alias topNavigationItems: navigationBar.topNavigationItems  // 置顶导航栏item
    property alias navigationItems: navigationBar.navigationItems  // 导航栏item
    property alias bottomNavigationItems: navigationBar.bottomNavigationItems  // 底部导航栏item
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
                navigationBar.collapsedByAutoResize = false
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
            if (defaultPage !== "") {
                safePush(defaultPage, false, true)
                return
            }

            if (topNavigationItems.length > 0) {
                safePush(topNavigationItems[0].page, false, true)
                return
            }

            if (navigationItems.length > 0) {
                safePush(navigationItems[0].page, false, true)
                return
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

    function push(page, properties) {
        if (properties === undefined) properties = {}
        safePush(page, false, false, properties)
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
            if (navigationBar.currentPage === pageKey && !reload) return
            if (loadingPages[pageKey] && !reload) return
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
                let poppedItem = stackView.pop(null, StackView.Immediate)
                if (poppedItem) poppedItem.destroy()
            } else {
                let itemsToRestore = []
                for (let i = stackView.depth - 1; i > targetIndex; i--) {
                    let item = stackView.get(i)
                    if (item) {
                        let pageInfo = {
                            component: componentCache[item.objectName] || null,
                            pageKey: item.objectName,
                            properties: {}
                        }
                        itemsToRestore.unshift(pageInfo)
                    }
                }
                while (stackView.depth > targetIndex + 1) stackView.pop(null, StackView.Immediate)
                let targetItem = stackView.pop(null, StackView.Immediate)
                if (targetItem) targetItem.destroy()
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
                let pageInstance = component.createObject(stackView, Object.assign({}, properties, {
                    objectName: currentObjectName
                }))
                if (!pageInstance) {
                    console.error("Failed to create page instance for reload:", pageKey)
                    setPushInProgress(false)
                    return
                }
                stackView.replace(stackView.currentItem, pageInstance)
                Qt.callLater(function() {
                    if (stackView.busy && stackView.currentItem === pageInstance) {
                        let animationHandler = function() {
                            if (stackView.currentItem === pageInstance && !stackView.busy) {
                                setPushInProgress(false)
                                stackView.busyChanged.disconnect(animationHandler)
                            }
                        }
                        if (!stackView.busy) setPushInProgress(false)
                        else stackView.busyChanged.connect(animationHandler)
                    } else setPushInProgress(false)
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

        let pageInstance = component.createObject(stackView, Object.assign({}, properties, {
            objectName: targetObjectName
        }))
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
