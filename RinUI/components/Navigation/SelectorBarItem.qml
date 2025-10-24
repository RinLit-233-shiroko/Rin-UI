import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import Qt5Compat.GraphicalEffects
import "../../components"
import "../../themes"

TabButton {
    id: root

    implicitWidth: Math.max(row.implicitWidth + 26 , 40)
    implicitHeight: 32

    background: Item {}

    Behavior on opacity {
        NumberAnimation {
            duration: Utils.animationSpeed
            easing.type: Easing.InOutQuint
        }
    }

    contentItem: Item {
        clip: true
        anchors.fill: parent

        Row {
            id: row
            spacing: 8
            anchors.centerIn: parent
            IconWidget {
                id: iconWidget
                size: icon || source ? text.font.pixelSize * 1.3 : 0  // 图标大小 / Icon Size
                icon: root.icon.name
                source: root.icon.source
                y: 0.25
            }

            Text {
                id: text
                typography: Typography.Body
                text: root.text
                color: Theme.currentTheme.colors.textColor
            }
        }

        Indicator {
            anchors {
                bottom: parent.bottom
                bottomMargin: Theme.currentTheme.appearance.borderWidth
                horizontalCenter: parent.horizontalCenter
            }
            visible: root.checked
            orientation: Qt.Horizontal
        }
    }

    // 状态变化
    states: [
        State {
        name: "disabled"
            when: !enabled
            PropertyChanges {
                target: root
                opacity: 0.65
            }
        },
        State {
            name: "pressed"
            when: pressed
            PropertyChanges {
                target: root;
                opacity: 0.67
            }
            PropertyChanges {
                target: background;
                scale: 0.95
            }
        },
        State {
            name: "hovered"
            when: hovered
            PropertyChanges {
                target: root;
                opacity: 0.875
            }
        }
    ]
}
