import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../../components"

ControlPage {
    title: qsTr("NavigationView")
    wrapperWidth: 1920
    badgeText: qsTr("Extra")
    badgeSeverity: Severity.Success

    // Page components
    Component {
        id: page1
        SamplePage { title: qsTr("Sample Page 1") }
    }

    Component {
        id: page2
        FluentPage {
            title: qsTr("Sample Page 2")
            GridLayout {
                Layout.fillWidth: true
                height: 400
                columns: 2
                rowSpacing: 12
                columnSpacing: 12

                Rectangle {
                    color: Theme.currentTheme.colors.primaryColor
                    width: 150
                    height: 200
                    Layout.rowSpan: 2
                }

                Text {
                    typography: Typography.Title
                    Layout.fillWidth: true
                    text: "Lorem ipsum dolor sit amet"
                }
                Text {
                    typography: Typography.Body
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "Abydos High School, the longest running school in Kivotos."
                }
            }
        }
    }

    Component {
        id: page3
        SamplePage {
            title: qsTr("Sample Page 3")
            primaryColor: "#e9967a"
            gridColor: "#f08080"
            gridSecondaryColor: "#cd5c5c"
        }
    }

    Component {
        id: page4
        FluentPage {
            title: qsTr("Settings")
            Text {
                Layout.fillWidth: true
                typography: Typography.Body
                text: qsTr("Settings page")
            }
        }
    }

    Component {
        id: page5
        FluentPage {
            title: qsTr("Pinned Top")
            Text {
                Layout.fillWidth: true
                typography: Typography.Body
                text: qsTr("This page is pinned to the top of the navigation bar")
            }
        }
    }

    Component {
        id: page6
        FluentPage {
            title: qsTr("Pinned Bottom")
            Text {
                Layout.fillWidth: true
                typography: Typography.Body
                text: qsTr("This page is pinned to the bottom of the navigation bar")
            }
        }
    }

    // Intro
    Text {
        Layout.fillWidth: true
        text: qsTr(
            "The NavigationView control provides a collapsible navigation menu for top-level navigation. " +
            "It implements the navigation pane pattern and automatically adapts to different window sizes."
        )
    }

    // Main Example
    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("NavigationView with configurable width")
        }

        Text {
            typography: Typography.Caption
            opacity: 0.7
            wrapMode: Text.WordWrap
            text: qsTr(
                "Configure navigation bar width using expandWidth (0 = dynamic, >0 = fixed). " +
                "Enable drag resize to manually adjust width by dragging the right edge."
            )
        }

        Frame {
            width: parent.width
            height: 500
            leftPadding: 0
            rightPadding: 0
            topPadding: 0
            bottomPadding: 0

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Left: Demo content
                Column {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 20
                    spacing: 4

                    Frame {
                        id: demoFrame
                        property string title: qsTr("NavigationView Demo")
                        property string icon: ""
                        property bool appLayerEnabled: true
                        width: parent.width
                        height: parent.height
                        topPadding: 50
                        padding: 12

                        NavigationView {
                            id: navView
                            window: demoFrame

                            property var baseItems: [
                                {
                                    icon: "ic_fluent_play_20_regular",
                                    title: qsTr("Menu Item 1"),
                                    page: page1
                                },
                                {
                                    icon: "ic_fluent_save_20_regular",
                                    title: qsTr("Menu Item 2"),
                                    page: page2
                                },
                                {
                                    icon: "ic_fluent_folder_20_regular",
                                    title: qsTr("Long Title for Testing"),
                                    page: page3,
                                    subItems: [
                                        {
                                            title: qsTr("Click to expand and see this extra long text")
                                        }
                                    ]
                                }
                            ]

                            property var topItem: ({
                                icon: "ic_fluent_star_20_regular",
                                title: qsTr("Pinned Top"),
                                page: page5,
                                position: Position.Top
                            })

                            property var bottomItem: ({
                                icon: "ic_fluent_settings_20_regular",
                                title: qsTr("Pinned Bottom"),
                                page: page6,
                                position: Position.Bottom
                            })

                            function updateNavigationItems() {
                                var items = []
                                
                                if (showTopCheckbox.checked) {
                                    items.push(topItem)
                                }
                                
                                for (var i = 0; i < baseItems.length; i++) {
                                    items.push(baseItems[i])
                                }
                                
                                if (showBottomCheckbox.checked) {
                                    items.push(bottomItem)
                                }
                                
                                navigationItems = items
                            }

                            Component.onCompleted: {
                                updateNavigationItems()
                            }
                        }
                    }
                }

                // Right: Control panel
                Rectangle {
                    width: 280
                    Layout.fillHeight: true
                    radius: Theme.currentTheme.appearance.smallRadius
                    color: Theme.currentTheme.colors.backgroundAcrylicColor
                    border.width: Theme.currentTheme.appearance.borderWidth
                    border.color: Theme.currentTheme.colors.cardBorderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        CheckBox {
                            id: showTopCheckbox
                            text: qsTr("Show Pinned Top Item")
                            checked: true
                            onCheckedChanged: navView.updateNavigationItems()
                        }
                        
                        CheckBox {
                            id: showBottomCheckbox
                            text: qsTr("Show Pinned Bottom Item")
                            checked: true
                            onCheckedChanged: navView.updateNavigationItems()
                        }
                        
                        CheckBox {
                            id: dragResizeCheckbox
                            text: qsTr("Enable Drag Resize")
                            checked: false
                            onCheckedChanged: {
                                navView.navigationBar.enableDragResize = checked
                                navView.navigationBar.userResizedWidth = 0
                            }
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.currentTheme.colors.dividerBorderColor
                        }
                        
                        Column {
                            spacing: 4
                            width: parent.width
                            
                            Text {
                                typography: Typography.Caption
                                text: qsTr("Width (px):")
                            }
                            
                            TextField {
                                id: expandWidthInput
                                width: parent.width
                                placeholderText: "0 = dynamic"
                                text: "0"
                                validator: IntValidator {
                                    bottom: 0
                                    top: 800
                                }
                                onTextChanged: {
                                    var value = parseInt(text) || 0
                                    navView.navigationBar.expandWidth = value
                                    navView.navigationBar.userResizedWidth = 0
                                    
                                    widthModeSwitch.checked = (value <= 0)
                                }
                            }
                            
                            Text {
                                width: parent.width
                                typography: Typography.Caption
                                opacity: 0.7
                                wrapMode: Text.WordWrap
                                text: {
                                    var width = parseInt(expandWidthInput.text) || 0
                                    if (width <= 0) {
                                        return qsTr("Dynamic width mode")
                                    } else {
                                        return qsTr("Fixed: %1px").arg(width)
                                    }
                                }
                            }
                            
                            Switch {
                                id: widthModeSwitch
                                text: checked ? qsTr("Dynamic Width") : qsTr("Fixed Width")
                                checked: true
                                
                                onCheckedChanged: {
                                    if (checked) {
                                        // 动态宽度
                                        expandWidthInput.text = "0"
                                    } else {
                                        // 固定宽度
                                        expandWidthInput.text = "200"
                                    }
                                }
                            }
                            
                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Theme.currentTheme.colors.dividerBorderColor
                            }
                            
                            Text {
                                typography: Typography.Caption
                                text: qsTr("Min Width (px):")
                            }
                            
                            TextField {
                                id: minWidthInput
                                width: parent.width
                                placeholderText: "200"
                                text: "200"
                                validator: IntValidator {
                                    bottom: 100
                                    top: 500
                                }
                                onTextChanged: {
                                    var value = parseInt(text) || 200
                                    navView.navigationBar.minNavbarWidth = value
                                }
                            }
                            
                            Text {
                                typography: Typography.Caption
                                text: qsTr("Max Width (px):")
                            }
                            
                            TextField {
                                id: maxWidthInput
                                width: parent.width
                                placeholderText: "400"
                                text: "400"
                                validator: IntValidator {
                                    bottom: 200
                                    top: 800
                                }
                                onTextChanged: {
                                    var value = parseInt(text) || 400
                                    navView.navigationBar.maxNavbarWidth = value
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
