import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import QtQuick.Window 2.15
import Qt5Compat.GraphicalEffects  // 图形库
import RinUI
import "../assets"
import "../components"

FluentPage {
    // title: "test"
    horizontalPadding: 0
    wrapperWidth: width - 42*2
    padding: 0

    // Banner / 横幅 //
    // 仅遮罩图片（顶圆角 + 底渐变）；标题在 mask 外直接绘制，保持 HiDPI 清晰
    header: Item {
        width: parent.width
        height: 200

        Image {
            id: banner
            anchors.fill: parent
            source: "../assets/banner.png"
            fillMode: Image.PreserveAspectCrop
            verticalAlignment: Image.AlignTop
            horizontalAlignment: Image.AlignLeft

            layer.enabled: true
            layer.smooth: false
            layer.mipmap: false
            layer.textureSize: Qt.size(
                Math.max(1, Math.ceil(width * Screen.devicePixelRatio)),
                Math.max(1, Math.ceil(height * Screen.devicePixelRatio))
            )
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: banner.width
                    height: banner.height
                    radius: 0
                    topLeftRadius: Theme.currentTheme.appearance.windowRadius
                    topRightRadius: Theme.currentTheme.appearance.windowRadius
                    bottomLeftRadius: 0
                    bottomRightRadius: 0

                    // 渐变效果
                    gradient: Gradient {
                        GradientStop { position: 0.25; color: "white" }  // 不透明
                        GradientStop { position: 1; color: "transparent" }  // 完全透明
                    }
                }
            }
        }

        Column {
            anchors {
                top: parent.top
                left: parent.left
                leftMargin: 40
                topMargin: 90
            }
            spacing: 8

            Text {
                color: "#fff"
                typography: Typography.Title
                text: qsTr("All samples")
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
            model: ItemData.allControls
            delegate: ControlClip { }
        }
    }
}
