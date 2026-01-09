import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../components"

ControlPage {
    title: "Iconography"

    property var allIcons: Object.keys(Utils.fontIconIndex)
    property string searchText: ""

    // 过滤后的图标 / Filtered Icons //
    property var filteredIcons: allIcons.filter(function(name) {
        return name.toLowerCase().indexOf(searchText.toLowerCase()) !== -1
    })

    // 复制函数
    function copyToClipboard(copyText) {
        if (!filteredIcons.length > 0) {
            floatLayer.createInfoBar({
                severity: Severity.Warning,
                text: qsTr("No icon selected"),
            })
            return 0
        }

        if (typeof Backend === "undefined") {
            floatLayer.createInfoBar({
                severity: Severity.Error,
                text: qsTr("Backend is not defined"),
            })
            return 0
        }

        Backend.copyToClipboard(
            copyText
        )
        floatLayer.createInfoBar({
            severity: Severity.Success,
            text: qsTr("Copied to clipboard"),
        })
    }


    Column {
        Layout.fillWidth: true
        spacing: 8

        SelectorBar {
            id: viewSegmented
            SelectorBarItem {
                icon.name: "ic_fluent_symbols_20_regular"
                text: qsTr("Fluent Icon")
            }
            SelectorBarItem {
                icon.name: "ic_fluent_image_20_regular"
                text: qsTr("SVG Icon")
            }
        }

        // Iconography View
        Column {
            width: parent.width
            visible: viewSegmented.currentIndex === 0
            spacing: 8

            Text {
                typography: Typography.BodyStrong
                text: qsTr("Fluent Icon Library")
            }

            TextField {
                width: 300
                id: searchField
                placeholderText: qsTr("Search")
                onTextChanged: searchText = text
            }

            // 图标 / Icon //
            Frame {
                width: parent.width
                color: Theme.currentTheme.colors.backgroundColor
                hoverable: false
                height: 600
                padding: 0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8


                    // 图标列表  / Icon Grid //
                    GridView {
                        id: iconGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        model: filteredIcons  // 过滤后的图标
                        cellWidth: 100
                        cellHeight: 100

                        ScrollBar.vertical: ScrollBar {  // 滚动条
                            policy: ScrollBar.AsNeeded
                        }

                        currentIndex: 0

                        delegate: Clip {
                            id: iconFrame
                            property bool isSelected: index === iconGrid.currentIndex

                            radius: Theme.currentTheme.appearance.windowRadius
                            borderColor: isSelected ? Theme.currentTheme.colors.primaryColor : "transparent"
                            borderWidth: isSelected ? 3 : 0
                            width: 92
                            height: 92

                            onClicked: iconGrid.currentIndex = index

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                IconWidget {
                                    Layout.fillHeight: true
                                    Layout.alignment: Text.AlignHCenter
                                    size: 36
                                    opacity: 0.9
                                    icon: modelData
                                }

                                Text {
                                    Layout.fillWidth: true
                                    typography: Typography.Caption
                                    horizontalAlignment: Text.AlignHCenter
                                    color: Theme.currentTheme.colors.textSecondaryColor
                                    text: modelData.replace("ic_fluent_", "");
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // icon信息
                    Rectangle {
                        width: 300
                        Layout.fillHeight: true
                        radius: Theme.currentTheme.appearance.smallRadius
                        color: Theme.currentTheme.colors.systemAttentionBackgroundColor
                        border.width: Theme.currentTheme.appearance.borderWidth
                        border.color: Theme.currentTheme.colors.cardBorderColor

                        ColumnLayout {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 16
                            spacing: 16

                            Column {
                                Layout.fillWidth: true
                                Text {
                                    id: iconTitle
                                    width: parent.width
                                    text: filteredIcons.length > 0 ?
                                        filteredIcons[iconGrid.currentIndex].replace("ic_fluent_", "")
                                        : qsTr("No icon selected")
                                    typography: Typography.BodyLarge
                                }
                                IconWidget {
                                    icon: filteredIcons.length > 0 ? filteredIcons[iconGrid.currentIndex] : ""
                                    size: 64
                                }
                            }

                            Item {
                                height: 16
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: qsTr("Icon name")
                                }
                                RowLayout {
                                    width: parent.width

                                    Text {
                                        id: iconName
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        color: Theme.currentTheme.colors.textSecondaryColor
                                        font.family: "Cascadia Mono"
                                        text: filteredIcons.length > 0 ?
                                            filteredIcons[iconGrid.currentIndex]
                                            : qsTr("No icon selected")
                                    }

                                    // 复制按钮
                                    ToolButton {
                                        icon.name: "ic_fluent_copy_20_regular"
                                        onClicked: copyToClipboard(iconName.text)
                                    }
                                }
                            }

                            // qml
                            Column {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: qsTr("QML code")
                                }
                                RowLayout {
                                    width: parent.width

                                    Text {
                                        id: qmlCode
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        color: Theme.currentTheme.colors.textSecondaryColor
                                        font.family: "Cascadia Mono"

                                        text: filteredIcons.length > 0 ?
                                            "icon.name: \""+filteredIcons[iconGrid.currentIndex]+"\""
                                            : qsTr("No icon selected")
                                    }

                                    // 复制按钮
                                    ToolButton {
                                        icon.name: "ic_fluent_copy_20_regular"
                                        onClicked: copyToClipboard(qmlCode.text)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // SVG Icon View
        Column {
            width: parent.width
            visible: viewSegmented.currentIndex === 1
            spacing: 8

            Text {
                width: parent.width
                text: qsTr("Toggle the checkbox and switch the theme to see how the SVG icons adapt to the text color.")
                wrapMode: Text.Wrap
                color: Theme.currentTheme.colors.textSecondaryColor
            }

            ControlShowcase {
                width: parent.width

                RowLayout {
                    width: parent.width
                    spacing: 30

                    Icon {
                        Layout.fillWidth: true
                        source: Qt.resolvedUrl("../assets/山海经 B.svg")
                        size: width
                        enableColorOverlay: svgNavSwitch.checked
                        color: Theme.currentTheme.colors.textColor
                    }
                    Icon {
                        source: Qt.resolvedUrl("../assets/SCHALELogo_B.svg")
                        Layout.fillWidth: true
                        size: width
                        enableColorOverlay: svgNavSwitch.checked
                        color: Theme.currentTheme.colors.textColor
                    }
                    Icon {
                        source: Qt.resolvedUrl("../assets/SRT B.svg")
                        Layout.fillWidth: true
                        size: width
                        enableColorOverlay: svgNavSwitch.checked
                        color: Theme.currentTheme.colors.textColor
                    }
                }

                showcase: [
                    CheckBox {
                        id: svgNavSwitch
                        text: qsTr("Color Overlay")
                        checked: true
                    }
                ]
            }
        }
    }
}
