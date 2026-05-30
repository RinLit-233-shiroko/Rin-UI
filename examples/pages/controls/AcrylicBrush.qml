import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import "../../components"

ControlPage {
    id: root
    title: qsTr("AcrylicBrush")
    badgeText: qsTr("Extra")
    badgeSeverity: Severity.Success

    // intro
    Text {
        Layout.fillWidth: true
        text: qsTr("A translucent material recommended for panel backgrounds.")
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("Default in-app acrylic brush")
        }
        Frame {
            width: parent.width
            height: 280

            Item {
                width: 400
                height: 252

                Item {
                    id: background
                    anchors.fill: parent
                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                        }
                        width: 100
                        height: 200
                        color: "cyan"
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 152
                        height: 152
                        radius: height / 2
                        color: "Magenta"
                    }
                    Rectangle {
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                        }
                        width: 80
                        height: 100
                        color: "yellow"
                    }
                }

                Rectangle {  // acrylic
                    anchors.fill: parent
                    anchors.margins: 12
                    color: "transparent"
                    AcrylicBrush {
                        sourceItem: background
                    }
                }
            }
        }
    }

     Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("Custom in-app acrylic brush")
        }
        ControlShowcase {
            width: parent.width
            // height: 280

            Item {
                width: 400
                height: 252

                Item {
                    id: background2
                    anchors.fill: parent
                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                        }
                        width: 100
                        height: 200
                        color: "cyan"
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 152
                        height: 152
                        radius: height / 2
                        color: "Magenta"
                    }
                    Rectangle {
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                        }
                        width: 80
                        height: 100
                        color: "yellow"
                    }
                }

                Rectangle {  // acrylic
                    anchors.fill: parent
                    anchors.margins: 12
                    color: "transparent"
                    AcrylicBrush {
                        sourceItem: background2
                        blur: blurSlider.value
                        tintOpacity: tintOpacitySlider.value
                        fallbackColor: fallbackColorPicker.color
                        tintColor: tintColorPicker.color
                        enabled: enabledSwitch.checked
                    }
                }
            }

            showcase: [
                Text {
                    text: qsTr("Enabled: ")
                },
                Switch{
                    id: enabledSwitch
                    checked: true
                },
                Text {
                    text: qsTr("Blur: ")
                },
                Slider {
                    id: blurSlider
                    from: 0
                    to: 128
                    stepSize: 1
                    value: 72
                },
                Text {
                    text: qsTr("Tint Opactiy: ")
                },
                Slider {
                    id: tintOpacitySlider
                    from: 0
                    to: 1
                    stepSize: 0.001
                    value: 0.85
                },
                Text {
                    text: qsTr("Tint Color: ")
                },
                DropDownColorPicker {
                    id: tintColorPicker
                    textVisible: true
                    hexText: true
                    color: "black"
                },
                Text {
                    text: qsTr("Fallback Color: ")
                },
                DropDownColorPicker {
                    id: fallbackColorPicker
                    textVisible: true
                    hexText: true
                    color: "darkgreen"
                }
            ]
        }
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("Luminosity with in-app acrylic brush")
        }
        ControlShowcase {
            width: parent.width
            height: 280

            Item {
                width: 400
                height: 252

                Item {
                    id: background3
                    anchors.fill: parent
                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                        }
                        width: 100
                        height: 200
                        color: "cyan"
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 152
                        height: 152
                        radius: height / 2
                        color: "Magenta"
                    }
                    Rectangle {
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                        }
                        width: 80
                        height: 100
                        color: "yellow"
                    }
                }

                Rectangle {  // acrylic
                    anchors.fill: parent
                    anchors.margins: 12
                    color: "transparent"
                    AcrylicBrush {
                        sourceItem: background3
                        tintColor: "#86cce8"
                        tintLuminosityOpacity: tintLuminosityOpacitySlider.value
                        tintOpacity: tintOpacitySlider2.value
                    }
                }
            }

            showcase: [
                Text {
                    text: qsTr("Tint Opactiy: ")
                },
                Slider {
                    id: tintOpacitySlider2
                    from: 0
                    to: 1
                    stepSize: 0.001
                    value: 0.85
                },
                Text {
                    text: qsTr("Tint Luminosity Opactiy: ")
                },
                Slider {
                    id: tintLuminosityOpacitySlider
                    from: 0
                    to: 1
                    stepSize: 0.001
                    value: 0.85
                }
            ]
        }
    }
}
