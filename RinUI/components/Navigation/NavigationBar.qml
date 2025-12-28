import QtQuick 2.15
import QtQuick.Controls 2.15
import "../../components"
import "../../themes"


Item {
    id: navigationBar
    // implicitWidth: collapsed ? 40 : expandWidth
    height: parent.height

    property bool collapsed: false
    property var topNavigationItems: []  // 置顶导航项
    property var navigationItems: [
        // {title: "Title", page: "path/to/page.qml", icon: undefined}
    ]
    property var bottomNavigationItems: []  // 底部导航项

    // property int currentSubIndex: -1
    property bool titleBarEnabled: true
    property int expandWidth: windowWidth * expandRatio
    property real expandRatio: 0.15 // Default ratio
    
    // Window width threshold for auto-collapse
    property int minimumWindowWidth: 900 
    
    // Dynamic Navbar Width Constraints
    property int minNavbarWidth: Math.max(150, windowWidth * 0.10)
    property int maxNavbarWidth: windowWidth * 0.20

    // 使用延迟执行确保所有属性绑定都更新完成后再调整
    onMinNavbarWidthChanged: {
        Qt.callLater(function() {
            if (expandWidth < minNavbarWidth) {
                expandRatio = minNavbarWidth / windowWidth;
            }
        });
    }

    onMaxNavbarWidthChanged: {
        Qt.callLater(function() {
            if (expandWidth > maxNavbarWidth) {
                expandRatio = maxNavbarWidth / windowWidth;
            }
        });
    }

    onWindowWidthChanged: {
        Qt.callLater(requestLayoutUpdate)
    }

    TextMetrics {
        id: titleMetrics
        font.family: "Microsoft YaHei"
        font.pixelSize: (typeof Theme !== "undefined" && Theme.currentTheme && Theme.currentTheme.typography) ? Theme.currentTheme.typography.bodySize : 14
    }

    function requestLayoutUpdate() {
        if (!collapsed) {
             expandRatio = calculateDynamicWidth();
        }
    }

    function calculateDynamicWidth() {
        var maxWidth = 0;

        // Traverse visual items to check expansion state
        function checkVisualItems(column) {
            if (!column) return;
            var children = column.children;
            for (var i = 0; i < children.length; i++) {
                var item = children[i];
                // Check if it's a NavigationItem (has itemData and collapsed property)
                if (item && item.itemData && item.itemData.title) {
                    titleMetrics.text = item.itemData.title;
                    // Base overhead: 50 (icon) + 16 (spacing) + 22 (left) + 20 (right) + ~20 (safe) = 128
                    var itemWidth = titleMetrics.width + 128;
                    if (itemWidth > maxWidth) maxWidth = itemWidth;

                    // Check sub-items ONLY if expanded (!collapsed)
                    if (!item.collapsed && item.itemData.subItems) {
                        var subItems = item.itemData.subItems;
                        for (var j = 0; j < subItems.length; j++) {
                             var sub = subItems[j];
                             if (sub && sub.title) {
                                 titleMetrics.text = sub.title;
                                 // Indentation: 1 level * 16 (assumed)
                                 var subWidth = titleMetrics.width + 128 + 16;
                                 if (subWidth > maxWidth) maxWidth = subWidth;
                             }
                        }
                    }
                }
            }
        }

        checkVisualItems(topNavigationColumn);
        checkVisualItems(navigationColumn);
        checkVisualItems(bottomNavigationColumn);
        
        // Ensure within bounds (in pixels)
        if (maxWidth < minNavbarWidth) maxWidth = minNavbarWidth;
        if (maxWidth > maxNavbarWidth) maxWidth = maxNavbarWidth;

        // Convert to ratio
        var initialRatio = maxWidth / windowWidth;
        
        return initialRatio;
    }

    Component.onCompleted: {
        if (windowWidth > 0) {
             expandRatio = calculateDynamicWidth()
        }
    }

    MouseArea {
        id: resizeHandle
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 10
        cursorShape: Qt.SizeHorCursor
        enabled: !collapsed
        visible: !collapsed
        z: 1000

        property int startX: 0
        property real startRatio: 0

        onPressed: {
            startX = mouseX
            startRatio = navigationBar.expandRatio
        }

        onPositionChanged: {
            if (pressed) {
                var delta = mouseX - startX
                var newRatio = startRatio + (delta / windowWidth)
                
                // Clamp ratio based on min/max width in pixels
                var minRatio = minNavbarWidth / windowWidth
                var maxRatio = maxNavbarWidth / windowWidth
                
                if (newRatio < minRatio) newRatio = minRatio
                if (newRatio > maxRatio) newRatio = maxRatio
                
                navigationBar.expandRatio = newRatio
            }
        }
    }

    property alias windowTitle: titleLabel.text
    property alias windowIcon: iconLabel.source
    property int windowWidth: 1000
    property var stackView: parent.stackView

    property string currentPage: ""  // 当前页面的URL
    property bool collapsedByAutoResize: false

    function isNotOverMinimumWidth() {  // 判断窗口是否小于最小宽度
        return windowWidth < minimumWindowWidth;
    }

    // 展开收缩动画 //
    width: collapsed ? 40 : expandWidth
    implicitWidth: isNotOverMinimumWidth() ? 40 : collapsed ? 40 : expandWidth

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
        anchors.topMargin: -title.height
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

        onClicked: {
            collapsed = !collapsed
        }

        ToolTip {
            parent: parent
            delay: 500
            visible: parent.hovered && !parent.pressed
            text: collapsed ? qsTr("Open Navigation") : qsTr("Close Navigation")
      }
    }

    // 置顶导航项（固定在顶部，支持滚动）
    Flickable {
        id: topFlickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: title.height + collapseButton.y
        // 置顶区域最大高度：导航栏可用高度的 20%
        height: Math.min(topNavigationColumn.implicitHeight, (parent.height - title.height) * 0.2)
        contentWidth: parent.width
        contentHeight: topNavigationColumn.implicitHeight
        clip: true

        Column {
            id: topNavigationColumn
            width: topFlickable.width
            spacing: 2

            Repeater {
                model: navigationBar.topNavigationItems
                delegate: NavigationItem {
                    id: topItem
                    itemData: modelData
                    currentPage: navigationBar.stackView
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }

    // Top Separator Container
    Item {
        id: topSeparatorContainer
        anchors.top: topFlickable.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: visible ? 6 : 0
        visible: navigationBar.topNavigationItems.length > 0
        z: 10

        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: 2
            color: Theme.currentTheme.colors.dividerBorderColor
        }
    }

    // 中间可滚动导航区域
    Flickable {
        id: flickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topSeparatorContainer.bottom
        anchors.bottom: bottomSeparatorContainer.top
        contentWidth: parent.width
        contentHeight: navigationColumn.implicitHeight
        clip: true

        Column {
            id: navigationColumn
            width: flickable.width
            spacing: 2

            Repeater {
                model: navigationBar.navigationItems
                delegate: NavigationItem {
                    id: item
                    itemData: modelData
                    currentPage: navigationBar.stackView
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }

    // Bottom Separator Container
    Item {
        id: bottomSeparatorContainer
        anchors.bottom: bottomFlickable.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: visible ? 6 : 0
        visible: navigationBar.bottomNavigationItems.length > 0
        z: 10

        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: 2
            color: Theme.currentTheme.colors.dividerBorderColor
        }
    }

    // 底部导航项（固定在底部，支持滚动）
    Flickable {
        id: bottomFlickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        // 底部区域最大高度：导航栏可用高度的 20%
        height: Math.min(bottomNavigationColumn.implicitHeight, (parent.height - title.height) * 0.2)
        contentWidth: parent.width
        contentHeight: bottomNavigationColumn.implicitHeight
        clip: true

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
            spacing: 2

            Repeater {
                model: navigationBar.bottomNavigationItems
                delegate: NavigationItem {
                    id: bottomItem
                    itemData: modelData
                    currentPage: navigationBar.stackView
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }
}
