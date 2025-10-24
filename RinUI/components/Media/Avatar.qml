import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import Qt5Compat.GraphicalEffects
import "../../themes"
import "../../components"

Item {
    id: root
    property int size: 96
    property string source: ""
    property string text
    property alias icon: icon.icon

    implicitWidth: size
    implicitHeight: size
    opacity: enabled ? 1 : 0.4

    Rectangle {
        id: background
        anchors.fill: parent
        color: Theme.currentTheme.colors.controlQuaternaryColor
        border.color: Theme.currentTheme.colors.cardBorderColor
        radius: size / 2

        // 图标
        IconWidget {
            id: icon
            anchors.centerIn: parent
            icon:  "ic_fluent_person_20_regular"
            size: root.size * 0.5
            source: root.source

            visible: root.source === "" && root.text === ""
        }

        // 文本
        Text {
            id: textLabel
            anchors.centerIn: parent
            font.pixelSize: size * 0.41
            font.bold: true
            text: {
                let text_list = root.text.split(" ")
                let result = ""
                for (let i = 0; i < text_list.length; i++) {
                    if (text_list[i] !== "" && (i === 0 || i === text_list.length - 1)) {
                        result += text_list[i][0]
                    }
                }
                return result
            }
            visible: root.source === "" && root.text !== ""
        }
    }

    Image {
        id: image
        source: root.source
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        clip: true
    }

    // 遮罩
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: background.radius
        }
    }

    // 动画
    Behavior on opacity {
        NumberAnimation {
            duration: Utils.appearanceSpeed
            easing.type: Easing.InOutQuint
        }
    }
}
