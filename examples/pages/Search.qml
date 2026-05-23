import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import Qt5Compat.GraphicalEffects  // 图形库
import RinUI
import "../assets"
import "../components"

FluentPage {
    id: page
    // title: "test"
    horizontalPadding: 0
    wrapperWidth: width - 42*2

    property string query: ""
    property string selectedType: ""
    property var categories: [
        { title: qsTr("Basic Input"), type: "basicInput" },
        { title: qsTr("Collections"), type: "collections" },
        { title: qsTr("Date & Time"), type: "date&time" },
        { title: qsTr("Dialogs & Flyouts"), type: "dialogs&flyouts" },
        { title: qsTr("Layout"), type: "layout" },
        { title: qsTr("Media"), type: "media" },
        { title: qsTr("Menus & Toolbars"), type: "menus&toolbars" },
        { title: qsTr("Navigation"), type: "navigation" },
        { title: qsTr("Scrolling"), type: "scrolling" },
        { title: qsTr("Status & Info"), type: "status&info" },
        { title: qsTr("Text & Typography"), type: "text" }
    ]
    property int visibleCategoryCount: 5
    property var overflowCategory: null
    property var visibleCategoriesModel: getVisibleCategories()
    property var overflowCategoriesModel: getOverflowCategories()

    function getSearchItems() {
        return ItemData.getItemsByTitle(query).filter(item => selectedType === "" || item.type === selectedType)
    }

    function getTypeCount(type) {
        return ItemData.getItemsByTitle(query).filter(item => item.type === type).length
    }

    function getAvailableCategories() {
        return categories.filter(category => getTypeCount(category.type) > 0)
    }

    function getVisibleCategories() {
        const availableCategories = getAvailableCategories()
        const visibleCategories = availableCategories.slice(0, visibleCategoryCount)
        if (overflowCategory && getTypeCount(overflowCategory.type) > 0 && visibleCategories.every(category => category.type !== overflowCategory.type)) {
            visibleCategories[visibleCategories.length - 1] = overflowCategory
        }
        return visibleCategories
    }

    function getOverflowCategories() {
        const availableCategories = getAvailableCategories()
        const visibleCategories = getVisibleCategories()
        return availableCategories.filter(category => visibleCategories.every(visibleCategory => visibleCategory.type !== category.type))
    }

    function refreshCategoryModels() {
        if (selectedType !== "" && getTypeCount(selectedType) === 0) {
            selectedType = ""
            selectorBar.currentIndex = 0
        }
        visibleCategoriesModel = getVisibleCategories()
        overflowCategoriesModel = getOverflowCategories()
    }

    function selectCategory(category) {
        const availableCategories = getAvailableCategories()
        const categoryIndex = availableCategories.findIndex(item => item.type === category.type)
        selectedType = category.type
        if (categoryIndex >= visibleCategoryCount) {
            overflowCategory = availableCategories[categoryIndex]
        }
        refreshCategoryModels()
        selectorBar.currentIndex = visibleCategoriesModel.findIndex(visibleCategory => visibleCategory.type === selectedType) + 1
    }

    onQueryChanged: refreshCategoryModels()

    header: Frame {
        width: parent.width + 12
        height: 48
        radius: 0

        RowLayout {
            anchors.fill: parent
            spacing: 4

            SelectorBar {
                id: selectorBar
                Layout.fillHeight: true

                SelectorBarItem {
                    width: implicitWidth
                    text: qsTr("All") + " (" + ItemData.getItemsByTitle(query).length + ")"
                    checked: page.selectedType === ""
                    onClicked: {
                        page.selectedType = ""
                        selectorBar.currentIndex = 0
                    }
                }

                Repeater {
                    id: visibleCategoryRepeater
                    model: page.visibleCategoriesModel
                    delegate: SelectorBarItem {
                        width: implicitWidth
                        text: modelData.title + " (" + page.getTypeCount(modelData.type) + ")"
                        checked: page.selectedType === modelData.type
                        onClicked: page.selectCategory(modelData)
                    }
                }
            }

            Button {
                flat: true
                icon.name: "ic_fluent_more_horizontal_20_regular"
                visible: page.overflowCategoriesModel.length > 0
                onClicked: overflowMenu.open()

                Menu {
                    id: overflowMenu

                    Repeater {
                        id: overflowCategoryRepeater
                        model: page.overflowCategoriesModel
                        delegate: MenuItem {
                            text: modelData.title + " (" + page.getTypeCount(modelData.type) + ")"
                            onClicked: page.selectCategory(modelData)
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }

    // Content / 内容 //
    Grid {
        Layout.fillWidth: true
        columns: Math.floor((width-12) / (300 + 6)) // 自动算列数
        rowSpacing: 12
        columnSpacing: 12
        layoutDirection: GridLayout.LeftToRight

        Repeater {
            model: page.getSearchItems()
            delegate: ControlClip { }
        }
    }
}
