import QtQuick 2.15
import QtQuick.Controls 2.15
import "../../components"
import "../../themes"


Item {
    id: navigationBar
    // implicitWidth: collapsed ? 40 : expandWidth
    height: parent.height

    property bool collapsed: false
    property var navigationItems: [
        // {title: "Title", page: "path/to/page.qml", icon: undefined}
    ]

    // property int currentSubIndex: -1
    property bool titleBarEnabled: true
    property int expandWidth: 0  // 0 或负值=动态宽度，正值=固定宽度
    property int minimumExpandWidth: 900
    
    // 动态宽度系统配置
    property int minNavbarWidth: 200  // 最小导航栏宽度
    property int maxNavbarWidth: 400  // 最大导航栏宽度
    property bool enableDragResize: false  // 是否启用拖拽调整(可与动态/固定模式共存)
    
    property int userResizedWidth: 0  // 用户拖拽后的宽度(内部使用，拖拽后自动设置)

    property alias windowTitle: titleLabel.text
    property alias windowIcon: iconLabel.source
    property int windowWidth: minimumExpandWidth
    property var stackView: parent.stackView

    property string currentPage: ""  // 当前页面的URL
    property bool collapsedByAutoResize: false
    property int cachedOptimalWidth: 280  // 缓存的最优宽度

    function isNotOverMinimumWidth() {  // 判断窗口是否小于最小宽度
        return windowWidth < minimumExpandWidth;
    }
    
    // 获取有效宽度(综合考虑拖拽、固定、动态三种模式)
    function getEffectiveWidth() {
        // 优先级 1: 用户拖拽的宽度(如果启用拖拽调整且用户已拖拽)
        if (enableDragResize && userResizedWidth > 0) {
            return userResizedWidth
        }
        
        // 优先级 2: 固定宽度(如果 expandWidth > 0)
        if (expandWidth > 0) {
            return expandWidth
        }
        
        // 优先级 3: 动态宽度(基于内容智能计算)
        return cachedOptimalWidth
    }
    
    // 计算所有导航项的最优宽度
    function calculateOptimalWidth() {
        let maxWidth = minNavbarWidth
        
        // 遍历顶部导航项
        for (let i = 0; i < topRepeater.count; i++) {
            let item = topRepeater.itemAt(i)
            if (item && item.itemData) {
                navigationTextMetrics.text = item.itemData.title || ""
                // icon(19) + spacing(16) + leftMargin(11) + padding(20) = 66
                // 如果有子项，额外加上展开按钮宽度
                let expandBtnWidth = (item.itemData.subItems && item.itemData.subItems.length > 0) ? 28 : 0
                let requiredWidth = navigationTextMetrics.width + 66 + expandBtnWidth
                maxWidth = Math.max(maxWidth, requiredWidth)
                
                // 如果有子项且当前项未折叠，计算子项宽度
                if (item.itemData.subItems && !item.collapsed) {
                    for (let j = 0; j < item.itemData.subItems.length; j++) {
                        navigationTextMetrics.text = item.itemData.subItems[j].title || ""
                        let subWidth = navigationTextMetrics.width + 82  // 66 + 16 (额外缩进)
                        maxWidth = Math.max(maxWidth, subWidth)
                    }
                }
            }
        }
        
        // 遍历中间导航项
        for (let i = 0; i < mainRepeater.count; i++) {
            let item = mainRepeater.itemAt(i)
            if (item && item.itemData) {
                navigationTextMetrics.text = item.itemData.title || ""
                let expandBtnWidth = (item.itemData.subItems && item.itemData.subItems.length > 0) ? 28 : 0
                let requiredWidth = navigationTextMetrics.width + 66 + expandBtnWidth
                maxWidth = Math.max(maxWidth, requiredWidth)
                
                if (item.itemData.subItems && !item.collapsed) {
                    for (let j = 0; j < item.itemData.subItems.length; j++) {
                        navigationTextMetrics.text = item.itemData.subItems[j].title || ""
                        let subWidth = navigationTextMetrics.width + 82
                        maxWidth = Math.max(maxWidth, subWidth)
                    }
                }
            }
        }
        
        // 遍历底部导航项
        for (let i = 0; i < bottomRepeater.count; i++) {
            let item = bottomRepeater.itemAt(i)
            if (item && item.itemData) {
                navigationTextMetrics.text = item.itemData.title || ""
                let expandBtnWidth = (item.itemData.subItems && item.itemData.subItems.length > 0) ? 28 : 0
                let requiredWidth = navigationTextMetrics.width + 66 + expandBtnWidth
                maxWidth = Math.max(maxWidth, requiredWidth)
                
                if (item.itemData.subItems && !item.collapsed) {
                    for (let j = 0; j < item.itemData.subItems.length; j++) {
                        navigationTextMetrics.text = item.itemData.subItems[j].title || ""
                        let subWidth = navigationTextMetrics.width + 82
                        maxWidth = Math.max(maxWidth, subWidth)
                    }
                }
            }
        }
        
        // 限制在最小/最大宽度之间，并对齐到 4px
        return Math.min(Math.ceil(Math.max(maxWidth, minNavbarWidth) / 4) * 4, maxNavbarWidth)
    }
    
    // 请求重新计算布局
    function requestLayoutUpdate() {
        if (expandWidth <= 0 && !collapsed) {  // 仅在动态宽度模式下计算
            Qt.callLater(function() {
                // 异步计算并更新缓存的最优宽度
                cachedOptimalWidth = calculateOptimalWidth()
            })
        }
    }
    
    // 组件完成时初始化缓存宽度
    Component.onCompleted: {
        if (expandWidth <= 0) {  // 仅在动态宽度模式下初始化
            Qt.callLater(function() {
                cachedOptimalWidth = calculateOptimalWidth()
            })
        }
    }
    
    // TextMetrics 用于计算文本宽度
    TextMetrics {
        id: navigationTextMetrics
        font.pixelSize: 14  // Typography.Body
        font.family: "Microsoft YaHei"
    }

    // 展开收缩动画 //
    width: collapsed ? 40 : getEffectiveWidth()
    implicitWidth: isNotOverMinimumWidth() ? 40 : collapsed ? 40 : getEffectiveWidth()

    Behavior on width {
        NumberAnimation {
            duration: Utils.animationSpeed
            easing.type: Easing.OutQuint
        }
    }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: Utils.animationSpeed
            easing.type: Easing.OutQuint
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.margins: -5
        anchors.topMargin: 0
        radius: Theme.currentTheme.appearance.windowRadius
        color: Theme.currentTheme.colors.backgroundAcrylicColor
        border.color: Theme.currentTheme.colors.flyoutBorderColor
        z: -1
        visible: isNotOverMinimumWidth() && !collapsed

        Behavior on visible {
            NumberAnimation {
                duration: collapsed ? Utils.animationSpeed / 2 : 50
            }
        }

        layer.enabled: true
        layer.effect: Shadow {
            style: "flyout"
            source: background
        }
    }

    Row {
        id: title
        anchors.left: parent.left
        anchors.bottom: parent.top
        height: titleBarHeight
        spacing: 16
        visible: navigationBar.titleBarEnabled

        // 返回按钮
        ToolButton {
            flat: true
            anchors.verticalCenter: parent.verticalCenter
            icon.name: "ic_fluent_arrow_left_20_regular"
            onClicked: navigationView.safePop()
            width: 40
            height: 40
            size: 16
            enabled: navigationView.lastPages.length > 0

            ToolTip {
                parent: parent
                delay: 500
                visible: parent.hovered
                text: qsTr("Back")
            }
        }

        //图标
        IconWidget {
            id: iconLabel
            size: 16
            anchors.verticalCenter: parent.verticalCenter
        }

        //标题
        Text {
            id: titleLabel
            anchors.verticalCenter:  parent.verticalCenter

            typography: Typography.Caption
            // text: title
        }
    }

    // 收起切换按钮
    ToolButton {
        id: collapseButton
        flat: true
        width: 40
        height: 38
        // icon.name: collapsed ? "ic_fluent_chevron_right_20_regular" : "ic_fluent_chevron_left_20_regular"
        icon.name: "ic_fluent_navigation_20_regular"
        size: 19
        y: 5

        onClicked: {
            collapsed = !collapsed
            collapsedByAutoResize = false
        }

        ToolTip {
            parent: parent
            delay: 500
            visible: parent.hovered && !parent.pressed
            text: collapsed ? qsTr("Open Navigation") : qsTr("Close Navigation")
      }
    }

    // 数据过滤逻辑
    function getTopItems() {
        return navigationItems.filter(function(item) {
            return item.position === "top";
        });
    }
    
    function getMiddleItems() {
        return navigationItems.filter(function(item) {
            return !item.position || item.position === "normal" || item.position === "";
        });
    }
    
    function getBottomItems() {
        return navigationItems.filter(function(item) {
            return item.position === "bottom";
        });
    }


    // 置顶导航项（固定在顶部，支持滚动）
    Flickable {
        id: topFlickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 40 + collapseButton.y
        // 置顶区域最大高度：导航栏可用高度的 20%
        height: getTopItems().length > 0 ? Math.min(topNavigationColumn.implicitHeight, (parent.height - 40) * 0.2) : 0
        contentWidth: parent.width
        contentHeight: topNavigationColumn.implicitHeight
        clip: true
        visible: getTopItems().length > 0

        Column {
            id: topNavigationColumn
            width: topFlickable.width
            spacing: 4

            Repeater {
                id: topRepeater
                model: navigationBar.getTopItems()
                delegate: NavigationItem {
                    id: topItem
                    itemData: modelData
                    currentPage: navigationBar.stackView

                    // 子菜单重置
                    Connections {
                        target: navigationBar
                        function onCollapsedChanged() {
                            if (!navigationBar.collapsed) {
                                return
                            }
                            topItem.collapsed = navigationBar.collapsed
                        }
                    }
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }

    // Top Separator
    Rectangle {
        id: topSeparator
        anchors.top: topFlickable.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        z: 10
        color: Theme.currentTheme.colors.dividerBorderColor
        visible: navigationBar.getTopItems().length > 0
    }

    // 中间可滚动导航区域
    Flickable {
        id: flickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topSeparator.visible ? topSeparator.bottom : topFlickable.bottom
        anchors.topMargin: topSeparator.visible ? 4 : 0
        anchors.bottom: bottomSeparator.visible ? bottomSeparator.top : bottomFlickable.top
        anchors.bottomMargin: bottomSeparator.visible ? 4 : 0
        contentWidth: parent.width
        contentHeight: navigationColumn.implicitHeight
        clip: true

        Column {
            id: navigationColumn
            width: flickable.width
            spacing: 4

            Repeater {
                id: mainRepeater
                model: navigationBar.getMiddleItems()
                delegate: NavigationItem {
                    id: item
                    itemData: modelData
                    currentPage: navigationBar.stackView

                    // 子菜单重置
                    Connections {
                        target: navigationBar
                        function onCollapsedChanged() {
                            if (!navigationBar.collapsed) {
                                return
                            }
                            item.collapsed = navigationBar.collapsed
                        }
                    }
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }

    // Bottom Separator
    Rectangle {
        id: bottomSeparator
        anchors.bottom: bottomFlickable.top
        anchors.bottomMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        z: 10
        color: Theme.currentTheme.colors.dividerBorderColor
        visible: navigationBar.getBottomItems().length > 0
    }

    // 底部导航项（固定在底部，支持滚动）
    Flickable {
        id: bottomFlickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        // 底部区域最大高度：导航栏可用高度的 20%
        height: getBottomItems().length > 0 ? Math.min(bottomNavigationColumn.implicitHeight, (parent.height - 40) * 0.2) : 0
        contentWidth: parent.width
        contentHeight: bottomNavigationColumn.implicitHeight
        clip: true
        visible: getBottomItems().length > 0

        // 默认滚动到底部
        Component.onCompleted: {
            if (contentHeight > height) {
                contentY = contentHeight - height;
            }
        }

        // 内容高度变化时保持在底部
        onContentHeightChanged: {
            if (contentHeight > height) {
                contentY = contentHeight - height;
            }
        }

        Column {
            id: bottomNavigationColumn
            width: bottomFlickable.width
            spacing: 4

            Repeater {
                id: bottomRepeater
                model: navigationBar.getBottomItems()
                delegate: NavigationItem {
                    id: bottomItem
                    itemData: modelData
                    currentPage: navigationBar.stackView

                    // 子菜单重置
                    Connections {
                        target: navigationBar
                        function onCollapsedChanged() {
                            if (!navigationBar.collapsed) {
                                return
                            }
                            bottomItem.collapsed = navigationBar.collapsed
                        }
                    }
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }
    
    // 拖拽调整区域
    MouseArea {
        id: resizeHandle
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4
        cursorShape: Qt.SizeHorCursor
        enabled: enableDragResize && !collapsed
        visible: enabled
        z: 1000
        
        property int startX: 0
        property int startWidth: 0
        
        onPressed: function(mouse) {
            startX = mouse.x
            startWidth = getEffectiveWidth()  // 从当前有效宽度开始拖拽
        }
        
        onPositionChanged: function(mouse) {
            if (pressed) {
                let delta = mouse.x - startX
                let newWidth = startWidth + delta
                
                // 限制在最小/最大宽度之间
                newWidth = Math.max(minNavbarWidth, Math.min(maxNavbarWidth, newWidth))
                
                // 确保是 4 的倍数
                newWidth = Math.round(newWidth / 4) * 4
                
                navigationBar.userResizedWidth = newWidth  // 存储到拖拽宽度
            }
        }
    }
}
