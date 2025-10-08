import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "./assets/"
import RinUI

FluentWindow {
    id: window
    visible: true
    // title: qsTr("Gallery")
    width: 1200
    height: 700
    minimumWidth: 550
    minimumHeight: 400

    // 从 ItemData 获取控件数据
    // navigationView.navigationBar.collapsed: true
    function generateSubItems(type) {
        return ItemData.getItemsByType(type).map(item => ({
            title: item.title,
            page: item.page,
        }));
    }

    Component {
        id: tips
        InfoBar {
            position: Position.BottomRight

            timeout: 5000
            severity: Severity.Warning
            closable: false
            title: qsTr("Tips")
            text: qsTr("This page is <b>not a bug</b>, but a demo of an error in the RinUI loading interface.")
            customContent: [
                Button {
                    text: "I got it."
                    onClicked: close()
                }
            ]
        }
    }

    onCurrentPageChanged: {
        if (currentPage == Qt.resolvedUrl("unexist/page")) {
            floatLayer.createCustom(tips)
        }
    }

    navigationItems: [
        {
            title: qsTr("Home"),
            page: Qt.resolvedUrl("pages/Home.qml"),
            icon: "ic_fluent_home_20_regular",
        },
        {
            title: qsTr("Design guidance"),
            icon: "ic_fluent_design_ideas_20_regular",  // 找了半天没找到和WinUIGallery一样的图标(?)
            subItems: [
                {
                    title: qsTr("Iconography"),
                    page: Qt.resolvedUrl("pages/Iconography.qml"),
                    icon: "ic_fluent_symbols_20_regular"
                }
            ]
        },

        // 控件示例 / Sample //
        {
            title: qsTr("All Samples"),
            page: Qt.resolvedUrl("pages/AllSamples.qml"),
            icon: "ic_fluent_apps_list_20_regular"

        },
        {
            title: qsTr("Basic Input"),
            page: Qt.resolvedUrl("pages/BasicInput.qml"),
            icon: "ic_fluent_checkbox_checked_20_regular",
            subItems: generateSubItems("basicInput")
        },
        {
            title: qsTr("Collections"),
            page: Qt.resolvedUrl("pages/Collections.qml"),
            icon: "ic_fluent_table_20_regular",
            subItems: generateSubItems("collections")
        },
        {
            title: qsTr("Date & Time"),
            page: Qt.resolvedUrl("pages/DateAndTime.qml"),
            icon: "ic_fluent_calendar_clock_20_regular",
            subItems: generateSubItems("date&time")
        },
        {
            title: qsTr("Dialogs & Flyouts"),
            page: Qt.resolvedUrl("pages/DialogsAndFlyouts.qml"),
            icon: "ic_fluent_chat_20_regular",
            subItems: generateSubItems("dialogs&flyouts")
        },
        {
            title: qsTr("Layout"),
            page: Qt.resolvedUrl("pages/Layout.qml"),
            icon: "ic_fluent_content_view_20_regular",
            subItems: generateSubItems("layout")
        },
        {
            title: qsTr("Media"),
            page: Qt.resolvedUrl("pages/Media.qml"),
            icon: "ic_fluent_video_clip_20_regular",
            subItems: generateSubItems("media")
        },
        {
            title: qsTr("Menus & Toolbars"),
            page: Qt.resolvedUrl("pages/MenusAndToolbars.qml"),
            icon: "ic_fluent_save_20_regular",
            subItems: generateSubItems("menus&toolbars")
        },
        {
            title: qsTr("Navigation"),
            page: Qt.resolvedUrl("pages/Navigation.qml"),
            icon: "ic_fluent_save_20_regular",
            subItems: generateSubItems("navigation")
        },
        {
            title: qsTr("Status & Info"),
            page: Qt.resolvedUrl("pages/StatusAndInfo.qml"),
            icon: "ic_fluent_chat_multiple_minus_20_regular",
            subItems: generateSubItems("status&info")
        },
        {
            title: qsTr("Text & Typography"),
            page: Qt.resolvedUrl("pages/Text.qml"),
            icon: "ic_fluent_text_font_20_regular",
            subItems: generateSubItems("text")
        },
        {
            title: qsTr("Error Interface Test"),
            page: Qt.resolvedUrl("unexist/page"),
            icon: "ic_fluent_document_error_20_regular"
        },
        {
            title: qsTr("Settings"),
            page: Qt.resolvedUrl("pages/Settings.qml"),
            icon: "ic_fluent_settings_20_regular"
        }
    ]


    // FluentPage {
    //     id: contentArea
    //     title: qsTr("Gallery")
    //     spacing: 10
    //
    //     TextLabel {
    //         labelType: "body"
    //         color:Theme.currentTheme.colors.primaryColor
    //         text: "测试测试"
    //     }
    //
    //     TextLabel {
    //         labelType: "bodyLarge"
    //         text: "Button 按钮"
    //     }
    //
    //     IconWidget {
    //         size: 48
    //         icon: "\ueb95"
    //     }
    //
    //     Flow {
    //         Layout.fillWidth: true
    //         spacing: 10
    //
    //         Button {
    //             id: btn_1
    //             buttonType: "primary"
    //             text: "切换主题"
    //             onClicked: {
    //                 if (Theme.currentTheme.name === "Light") {
    //                     Theme.setTheme("Dark")
    //                 } else {
    //                     Theme.setTheme("Light")
    //                 }
    //             }
    //         }
    //         Button {
    //             enabled: true
    //             buttonType: "standard"
    //             text: "Push Button"
    //         }
    //         Button {
    //             enabled: true
    //             buttonType: "standard"
    //             icon: "\uf103"
    //             text: "hello!"
    //         }
    //         ToolButton {
    //             enabled: true
    //             icon: "\uf103"
    //         }
    //         Button {
    //             id: btn_2
    //             enabled: true
    //             buttonType: "standard"
    //             text: "Hover to see Tooltip"
    //
    //             Tooltip {
    //                 parent: btn_2
    //                 delay: 500
    //                 visible: btn_2.hovered
    //                 text: "This is a tooltip"
    //             }
    //
    //         }
    //         Button {
    //             text: "Disabled"
    //             enabled: false
    //         }
    //         Button {
    //             enabled: true
    //             compact: true
    //             text: "Push Button"
    //         }
    //         Button {
    //             enabled: true
    //             buttonType: "transparent"
    //             compact: true
    //             text: "Transparent Button"
    //         }
    //         HyperlinkButton {
    //             text: "HyperLink Button"
    //             openUrl: "https://baidu.com"
    //         }
    //     }
    //
    //     TextLabel {
    //         labelType: "bodyLarge"
    //         text: "Switch 按钮"
    //     }
    //
    //     Row {
    //         spacing: 10
    //
    //         ToggleSwitch {
    //             checked: true
    //             onCheckedChanged: {
    //                 if (checked) {
    //                     btn_1.enabled = true
    //                     switch_1.enabled = true
    //                     console.log("Switch is on")
    //                 } else {
    //                     btn_1.enabled = false
    //                     switch_1.enabled = false
    //                     console.log("Switch is off")
    //                 }
    //             }
    //         }
    //         ToggleSwitch {
    //             id: switch_1
    //             checked: true
    //         }
    //     }
    //
    //     TextLabel {
    //         labelType: "bodyLarge"
    //         text: "ComboBox 下拉"
    //     }
    //
    //     Row {
    //         spacing: 10
    //
    //         ComboBox {
    //             property var data: ["mica", "acrylic", "tabbed", "none"]
    //             model: ["Mica", "Acrylic", "Tabbed", "None"]
    //             currentIndex: data.indexOf(Theme.getBackdropEffect())
    //             onCurrentIndexChanged: {
    //                 Theme.setBackdropEffect(data[currentIndex])
    //             }
    //         }
    //         // ComboBox {
    //         //     editable: true
    //         //     model: ["Editable", "Item 1", "Item 2", "Item 3"]
    //         // }
    //         ComboBox {
    //             headerText: "With header"
    //             model: ["Item 1", "Item 2", "Item 3", "Item 3", "Item 3", "Item 3", "Item 3"]
    //         }
    //     }
    //     TextLabel {
    //         labelType: "bodyLarge"
    //         text: "Slider 滑动条"
    //     }
    //     Frame {
    //         Layout.fillWidth: true
    //         ColumnLayout {
    //             Slider {
    //                 from: 0
    //                 to: 100
    //                 stepSize: 1
    //             }
    //             Slider {
    //                 orientation: Qt.Vertical  // vertical
    //                 from: 0
    //                 to: 100
    //                 stepSize: 10  // step size
    //                 snapMode: Slider.SnapAlways  // snap to tick
    //                 tickmarksEnabled: true // show tickmarks on qt6 ww
    //             }
    //         }
    //     }
    //     TextLabel {
    //         labelType: "bodyLarge"
    //         text: "TextField 输入框"
    //     }
    //     TextField {
    //         text: "Hello World"
    //     }
    // }
}
