import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../themes"
import "../components"
import "../windows"

// 内容层 / Content Area
// HiDPI: 禁止对整页启用 layer + OpacityMask（会把文字重光栅化导致发糊）。
// 内容区圆角由 NavigationView.RoundedCornerOverlay 库层处理（默认仅左上圆角，
// 与历史 OpacityMask 形状一致）；业务页无需再写圆角 mask。
Page {
    id: fluentPage
    default property alias content: container.data
    property alias contentHeader: headerContainer.data
    // Backward compatibility for apps that still assign `pageFooter: Item { ... }`.
    property alias pageFooter: fluentPage.footer
    property alias customHeader: headerRow.data
    property alias extraHeaderItems: extraHeaderRow.data
    property int radius: Theme.currentTheme.appearance.windowRadius
    property int wrapperWidth: 1000
    horizontalPadding: 56
    // bottomPadding: 24
    // StackView.onRemoved: destroy()
    spacing: 14
    property alias contentSpacing: container.spacing

    // 头部 / Header //
    header: Item {
        height: fluentPage.title !== "" ? 36 + 44 : 0

        RowLayout {
            id: headerRow
            width: Math.min(fluentPage.width - fluentPage.horizontalPadding * 2, fluentPage.wrapperWidth)  // 限制最大宽度
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height

            Text {
                // anchors.left: parent.left
                // anchors.bottom: parent.bottom
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                typography: Typography.Title
                text: fluentPage.title
                visible: fluentPage.title !== ""  // 标题
            }

            Row {
                id: extraHeaderRow
                spacing: 4
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            }
        }
    }


    background: Item {}

    Flickable {
        anchors.fill: parent
        clip: true
        ScrollBar.vertical: ScrollBar {
            parent: fluentPage
            anchors.top: parent.top
            anchors.topMargin: fluentPage.header ? fluentPage.header.height : 0
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: fluentPage.footer ? fluentPage.footer.height : 0
        }
        ScrollBar.horizontal: ScrollBar {
            parent: fluentPage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: fluentPage.footer ? fluentPage.footer.height : 0
        }
        contentHeight: container.height + 18 + headerContainer.height + 24

        Row {
            id: headerContainer
            width: fluentPage.width
        }

        ColumnLayout {
            id: container
            anchors.top: headerContainer.bottom
            anchors.topMargin: 18
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(fluentPage.width - fluentPage.horizontalPadding * 2, fluentPage.wrapperWidth)  // 24 + 24 的边距
            spacing: fluentPage.spacing
        }
    }

    // anchors.fill: parent
}
