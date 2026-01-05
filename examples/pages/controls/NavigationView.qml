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

    // intro
    Text {
        Layout.fillWidth: true
        text: qsTr(
            "The navigation view control provides a common vertical layout for top-level areas of your app "+
            "via a collapsible navigation menu."
        )
    }

    // 展示页面
    Component {
        id: page1

        SamplePage {
            title: qsTr("Sample Page 1")
        }
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
                    text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
                }
                Text {
                    typography: Typography.Body
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: "Abydos High School, the longest running school in Kivotos, formerly thriving and boasting incredible financial and military power, before the unnatural and unfortunate desertification struck. Nowadays, most of its buildings have been covered in sand and ruins, leaving behind only an annex which seems to be the very last remains of the school."
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

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("Basic Example")
        }
        Frame {
            id: frameBasic
            property string title: qsTr("Basic Example")
            property string icon: ""
            property bool appLayerEnabled: true
            width: parent.width
            topPadding: 50
            padding: 12
            height: 500

            NavigationView {
                id: navView
                window: frameBasic

                navigationItems: [
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
                        icon: "ic_fluent_arrow_sync_20_regular",
                        title: qsTr("Menu Item 3"),
                        page: page3
                    },
                    {
                        icon: "ic_fluent_settings_20_regular",
                        title: qsTr("Settings"),
                        page: page4
                    },
                ]
            }
        }
    }
    
    // Pinned Items Example
    Column {
        Layout.fillWidth: true
        spacing: 4
        
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Pinned Navigation Items Example")
        }
        
        Text {
            typography: Typography.Caption
            opacity: 0.7
            wrapMode: Text.WordWrap
            text: qsTr("Use position: \"top\" or \"bottom\" to pin navigation items to top or bottom")
        }
        
        Frame {
            id: framePinned
            property string title: qsTr("Pinned Items Example")
            property string icon: ""
            property bool appLayerEnabled: true
            width: parent.width
            topPadding: 50
            padding: 12
            height: 500
            
            NavigationView {
                id: navView2
                window: framePinned
                
                navigationItems: [
                    {
                        icon: "ic_fluent_star_20_regular",
                        title: qsTr("Pinned Top"),
                        page: page5,
                        position: "top"  // Pinned to top
                    },
                    {
                        icon: "ic_fluent_play_20_regular",
                        title: qsTr("Regular Item 1"),
                        page: page1
                    },
                    {
                        icon: "ic_fluent_save_20_regular",
                        title: qsTr("Regular Item 2"),
                        page: page2
                    },
                    {
                        icon: "ic_fluent_arrow_sync_20_regular",
                        title: qsTr("Regular Item 3"),
                        page: page3
                    },
                    {
                        icon: "ic_fluent_settings_20_regular",
                        title: qsTr("Pinned Bottom"),
                        page: page6,
                        position: "bottom"  // Pinned to bottom
                    }
                ]
            }
        }
    }
    
    // Dynamic Width Example
    Column {
        Layout.fillWidth: true
        spacing: 4
        
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Advanced: Dynamic Width")
        }
        
        Text {
            typography: Typography.Caption
            opacity: 0.7
            wrapMode: Text.WordWrap
            text: qsTr(
                "Enable dynamic width to make the navigation bar width adjust proportionally to window size. " +
                "Note: Do not enable together with drag resize as they conflict."
            )
        }
        
        Frame {
            id: frameDynamic
            property string title: qsTr("Dynamic Width Example")
            property string icon: ""
            property bool appLayerEnabled: true
            width: parent.width
            topPadding: 50
            padding: 12
            height: 500
            
            NavigationView {
                id: navView3
                window: frameDynamic
                
                // Enable dynamic width
                Component.onCompleted: {
                    navigationBar.enableDynamicWidth = true  // Enable dynamic width
                    navigationBar.expandRatio = 0.25          // 25% of window width
                    navigationBar.minNavbarWidth = 200        // Min 200px
                    navigationBar.maxNavbarWidth = 400        // Max 400px
                }
                
                navigationItems: [
                    {
                        icon: "ic_fluent_home_20_regular",
                        title: qsTr("Home"),
                        page: page1
                    },
                    {
                        icon: "ic_fluent_folder_20_regular",
                        title: qsTr("Click Me"),
                        page: page2,
                        subItems: [
                            {
                                title: qsTr("Extra Long Text to Show Dynamic Width")
                            }
                        ]
                    },
                    {
                        icon: "ic_fluent_image_20_regular",
                        title: qsTr("Gallery"),
                        page: page3
                    },
                    {
                        icon: "ic_fluent_settings_20_regular",
                        title: qsTr("Settings"),
                        page: page4
                    }
                ]
            }
        }
    }
    
    // Drag Resize Example
    Column {
        Layout.fillWidth: true
        spacing: 4
        
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Advanced: Drag Resize")
        }
        
        Text {
            typography: Typography.Caption
            opacity: 0.7
            wrapMode: Text.WordWrap
            text: qsTr(
                "Enable drag resize to manually adjust navigation bar width by dragging the right edge. " +
                "Hover over the right side to see the resize cursor. " +
                "Note: Do not enable together with dynamic width as they conflict."
            )
        }
        
        Frame {
            id: frameDrag
            property string title: qsTr("Drag Resize Example")
            property string icon: ""
            property bool appLayerEnabled: true
            width: parent.width
            topPadding: 50
            padding: 12
            height: 500
            
            NavigationView {
                id: navView4
                window: frameDrag
                
                // Enable drag resize
                Component.onCompleted: {
                    navigationBar.enableDragResize = true    // Enable drag resize
                    navigationBar.minNavbarWidth = 200        // Min 200px
                    navigationBar.maxNavbarWidth = 400        // Max 400px
                }
                
                navigationItems: [
                    {
                        icon: "ic_fluent_home_20_regular",
                        title: qsTr("Home"),
                        page: page1
                    },
                    {
                        icon: "ic_fluent_document_20_regular",
                        title: qsTr("Documents"),
                        page: page2
                    },
                    {
                        icon: "ic_fluent_image_20_regular",
                        title: qsTr("Gallery"),
                        page: page3
                    },
                    {
                        icon: "ic_fluent_settings_20_regular",
                        title: qsTr("Settings"),
                        page: page4
                    }
                ]
            }
        }
    }
}
