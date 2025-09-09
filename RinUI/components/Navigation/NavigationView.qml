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
    property string defaultPage: ""  // 默认索引项
    property var lastPages: []  // 上个页面索引
    property int pushEnterFromY: height
    property var window: parent  // 窗口对象
    
    // 页面实例缓存
    property var pageCache: ({})

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
                    duration: Utils.animationSpeed
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
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Utils.animationSpeed
                    easing.type: Easing.InOutQuad
                }

                PropertyAnimation {
                    property: "y"
                    from: 0
                    to: pushEnterFromY
                    duration: Utils.animationSpeedMiddle
                    easing.type: Easing.InOutQuint
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
                        duration: Utils.appearanceSpeed
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            initialItem: Item {}

        }

        // 导航切换逻辑
        // Connections {
        //     target: navigationBar
        //     function onCurrentIndexChanged() {
        //         let index = navigationBar.currentIndex
        //         let page = navigationItems[index].page
        //         console.log("Pushing Page:", page, "Index:", index)
        //         if (stackView.depth === 0 || stackView.currentItem.objectName !== page) {
        //             checkPage(page)
        //         }
        //     }
        // }


        Component.onCompleted: {
            if (navigationItems.length > 0) {
                if (defaultPage !== "") {
                    safePush(defaultPage, false)
                } else {
                    safePush(navigationItems[0].page, false)  // 推送默认页面
                }  // 推送页面
            }
        }
    }

    function safePop() {
        // console.log("Popping Page; Depth:", stackView.depth)
        if (navigationBar.lastPages.length > 1) {
            navigationBar.currentPage = navigationBar.lastPages.pop()  // Retrieve and remove the last page
            navigationBar.lastPages = navigationBar.lastPages  // refresh
            stackView.pop()
        } else {
            console.log("Can't pop: only root page left")
        }
    }

    function pop() {
        safePop()
    }

    function push(page, reload) {
        safePush(page, reload)
    }

    function safePush(page, reload, fromNavigation) {
        // 无效检测
        if (!(typeof page === "object" || typeof page === "string" || page instanceof Component)) {
            console.error("Invalid page:", page)
            return
        }

        // 重复检测
        if (navigationBar.currentPage === page && !reload) {
            console.log("Page already loaded:", page)
            return
        }

        if (page instanceof Component) {
            // 对于Component类型，直接使用
            navigationBar.lastPages.push(navigationBar.currentPage)  // 记录当前页面
            navigationBar.lastPages = navigationBar.lastPages  // refresh
            navigationBar.currentPage = page.toString()
            pageChanged()
            stackView.push(page)

        } else if (typeof page === "object" || typeof page === "string" ) {
            let pageKey = page.toString()
            
            // 检查缓存中是否已有该页面实例
            if (!pageCache[pageKey] || reload) {
                let component = Qt.createComponent(page)  // 页面转控件

                if (component.status === Component.Ready) {
                    // 创建页面实例并缓存
                    let pageInstance = component.createObject(null)
                    pageCache[pageKey] = pageInstance
                    console.log("Created and cached page:", pageKey)
                } else if (component.status === Component.Error) {
                    console.error("Failed to load:", page, component.errorString())
                    navigationBar.lastPages.push(navigationBar.currentPage)  // 记录当前页面
                    navigationBar.lastPages = navigationBar.lastPages  // refresh
                    navigationBar.currentPage = page.toString()
                    pageChanged()
                    stackView.push("ErrorPage.qml", {
                        errorMessage: component.errorString(),  // 传参
                        page: page,
                    })
                    return
                }
            }
            
            // 使用缓存的页面实例
            if (pageCache[pageKey]) {
                console.log("Using cached page:", pageKey, "Depth:", stackView.depth)
                
                // 对于侧边栏导航，始终推送页面以保持一致的动画效果
                // 如果页面已在栈中，创建一个新的实例来避免StackView限制
                let pageInstance = pageCache[pageKey]
                let isInStack = false
                for (let i = 0; i < stackView.depth; i++) {
                    if (stackView.get(i) === pageInstance) {
                        isInStack = true
                        break
                    }
                }
                
                if (isInStack && fromNavigation) {
                    // 如果是侧边栏导航且页面已在栈中，先从栈中移除该实例，然后重新推送
                    console.log("Removing and re-pushing cached page:", pageKey)
                    
                    // 找到页面在栈中的位置并移除
                    let targetIndex = -1
                    for (let i = 0; i < stackView.depth; i++) {
                        if (stackView.get(i) === pageInstance) {
                            targetIndex = i
                            break
                        }
                    }
                    
                    if (targetIndex >= 0) {
                        // 移除该页面实例（但不销毁，因为它在缓存中）
                        let tempItems = []
                        for (let i = targetIndex + 1; i < stackView.depth; i++) {
                            tempItems.push(stackView.get(i))
                        }
                        
                        // 弹出到目标页面之前
                        while (stackView.depth > targetIndex) {
                            stackView.pop(null, StackView.Immediate)
                        }
                        
                        // 现在可以安全推送页面
                        navigationBar.lastPages.push(navigationBar.currentPage)
                        navigationBar.lastPages = navigationBar.lastPages
                        navigationBar.currentPage = pageKey
                        pageChanged()
                        stackView.push(pageInstance)
                    }
                } else if (!isInStack) {
                    // 页面不在栈中，使用缓存实例
                    navigationBar.lastPages.push(navigationBar.currentPage)
                    navigationBar.lastPages = navigationBar.lastPages
                    navigationBar.currentPage = pageKey
                    pageChanged()
                    stackView.push(pageInstance)
                } else {
                    // 页面已在栈中且不是侧边栏导航，只更新状态
                    console.log("Page instance already in stack, updating state only:", pageKey)
                    navigationBar.currentPage = pageKey
                    pageChanged()
                }
            }
        }
    }

    function findPageByKey(key) {
        const item = menuItems.find(i => i.key === key);
        return item ? item.page : null;
    }
}
