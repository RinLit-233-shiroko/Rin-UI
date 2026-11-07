import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import "../../themes"
import "../../components"

Button {
    id: root
    property var flyout: null // 可赋值为 Menu、Flyout 或任意 Popup
    property int dropdownWidth: 34
    property int dividerWidth: 1
    default property alias contentData: menu.contentData
    suffixIconName: "ic_fluent_chevron_down_20_regular"

    padding: 0
    hoverable: false
    focusPolicy: Qt.StrongFocus

    Menu {
        id: menu
    }

    function openFlyout() {
        if (!flyout && menu.count === 0)
            return
        (flyout || menu).open()
    }

    Component.onCompleted: {
        if (!flyout && menu.count > 0) {
            console.warn("DeprecationWarning: Direct MenuItem children on SplitButton are deprecated. " +
                         "Assign a Menu or Flyout to the 'flyout' property instead.")
        }
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_F4 ||
                (event.key === Qt.Key_Down && event.modifiers & Qt.AltModifier)) {
            openFlyout()
            event.accepted = true
        }
    }

    implicitWidth: Math.max(primaryButton.implicitWidth + dropdownWidth, 60)
    implicitHeight: Math.max(primaryButton.implicitHeight, 32)

    background: Rectangle {
        visible: false
        color: "transparent"
    }

    contentItem: Item {
        anchors.fill: parent

        Button {
            id: primaryButton
            x: 0
            width: Math.max(0, root.width - root.dropdownWidth)
            height: root.height

            text: root.text
            icon.name: root.icon.name
            icon.source: root.icon.source
            icon.width: root.icon.width
            icon.height: root.icon.height
            highlighted: root.highlighted
            flat: root.flat
            primaryColor: root.primaryColor
            focusPolicy: Qt.NoFocus
            hoverable: root.enabled
            padding: 0

            implicitWidth: Math.max(primaryRow.implicitWidth + 24, 40)
            implicitHeight: Math.max(primaryRow.implicitHeight + 12, 32)

            onClicked: {
                if (root.enabled) {
                    root.forceActiveFocus()
                    root.clicked()
                }
            }

            background: Rectangle {
                anchors.fill: parent
                color: primaryButton.hovered ? primaryButton.hoverColor
                                             : primaryButton.backgroundColor
                topLeftRadius: Theme.currentTheme.appearance.buttonRadius
                bottomLeftRadius: Theme.currentTheme.appearance.buttonRadius

                opacity: primaryButton.flat && !primaryButton.hovered
                    || !primaryButton.hoverable ? 0 : 1
                Behavior on color { ColorAnimation { duration: Utils.appearanceSpeed; easing.type: Easing.OutQuart } }
            }

            contentItem: Item {
                anchors.fill: parent

                Row {
                    id: primaryRow
                    anchors.left: parent.left
                    anchors.leftMargin: 11
                    anchors.rightMargin: 13
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Icon {
                        property bool hasIcon: primaryButton.icon.name
                            || primaryButton.icon.source.toString()
                        width: hasIcon ? primaryButton.icon.width : 0
                        height: hasIcon ? primaryButton.icon.height : 0
                        icon: primaryButton.icon.name
                        source: primaryButton.icon.source
                        color: primaryButton.highlighted ? primaryButton.flat
                            ? Theme.currentTheme.colors.textAccentColor
                            : Theme.currentTheme.colors.textOnAccentColor
                            : Theme.currentTheme.colors.textColor
                        visible: hasIcon
                    }

                    Text {
                        id: label
                        typography: Typography.Body
                        text: root.text
                        color: primaryButton.highlighted ? primaryButton.flat
                            ? Theme.currentTheme.colors.textAccentColor
                            : Theme.currentTheme.colors.textOnAccentColor
                            : Theme.currentTheme.colors.textColor
                    }
                }
            }
        }

        Button {
            id: dropdownButton
            x: root.width - root.dropdownWidth
            width: root.dropdownWidth
            height: root.height

            highlighted: root.highlighted
            flat: root.flat
            primaryColor: root.primaryColor
            focusPolicy: Qt.NoFocus
            hoverable: root.enabled
            padding: 0

            implicitWidth: root.dropdownWidth
            implicitHeight: 32

            Accessible.name: qsTr("Open menu")

            onClicked: {
                if (!root.enabled)
                    return
                root.forceActiveFocus()
                root.openFlyout()
            }

            background: Rectangle {
                anchors.fill: parent
                color: dropdownButton.hovered ? dropdownButton.hoverColor
                                              : dropdownButton.backgroundColor
                topRightRadius: Theme.currentTheme.appearance.buttonRadius
                bottomRightRadius: Theme.currentTheme.appearance.buttonRadius

                opacity: dropdownButton.flat && !dropdownButton.hovered
                    || !dropdownButton.hoverable ? 0 : 1
                Behavior on color { ColorAnimation { duration: Utils.appearanceSpeed; easing.type: Easing.OutQuart } }
            }

            contentItem: Item {
                anchors.fill: parent

                Icon {
                    anchors.centerIn: parent
                    size: 12
                    icon: root.suffixIconName
                    color: dropdownButton.highlighted
                        ? Theme.currentTheme.colors.textOnAccentColor
                        : Theme.currentTheme.colors.textSecondaryColor
                }
            }
        }

        Rectangle {
            x: root.width - root.dropdownWidth
            y: 1
            width: root.dividerWidth
            height: Math.max(0, root.height - 2)
            color: root.highlighted
                ? Theme.currentTheme.colors.controlBorderAccentTertiaryColor
                : Theme.currentTheme.colors.controlBorderColor
            opacity: root.flat ? 0 : 1
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.currentTheme.appearance.buttonRadius
            color: "transparent"
            border.width: Theme.currentTheme.appearance.borderWidth
            border.color: root.flat ? "transparent"
                : root.enabled ? root.highlighted
                    ? Theme.currentTheme.colors.controlBorderAccentColor
                    : Theme.currentTheme.colors.controlBorderColor
                : Theme.currentTheme.colors.controlBorderColor
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: Math.max(0, root.width - 2 * Theme.currentTheme.appearance.buttonRadius)
            height: root.flat ? 0 : Theme.currentTheme.appearance.borderWidth
            color: root.highlighted
                ? Theme.currentTheme.colors.controlBorderAccentSecondaryColor
                : Theme.currentTheme.colors.controlBottomBorderColor
        }
    }

    font: label.font
}
