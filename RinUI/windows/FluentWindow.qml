import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../themes"
import "../components"
import "../windows"

FluentWindowBase {
    id: window
    // visible: true
    width: 900
    height: 600
    minimumWidth: 400
    minimumHeight: 300
    titleEnabled: false
    titleBarHeight: Theme.currentTheme.appearance.windowTitleBarHeight

    property alias navigationView: navigationView  // 导航栏
    property alias navigationItems: navigationView.navigationItems  // 导航栏item
    property alias currentPage: navigationView.currentPage  // 当前索引项
    property alias defaultPage: navigationView.defaultPage  // 默认索引项
    property alias appLayerEnabled: navigationView.appLayerEnabled  // 应用层背景
    default property alias content: freeContainter.data

    NavigationView {
        id: navigationView
        window: window
    }
    Item {
        id: freeContainter
        anchors.fill: parent
    }
}
