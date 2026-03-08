import QtQuick 2.12
import QtQuick.Controls 2.3
import QtQuick.Window 2.3
import "../themes"
import "../components"


Base {
    id: root
    // Use only the local handlers in this control to avoid duplicated hover regions.
    interactive: false
    property int mode: 0  //0:max 1:min 2:close
    property alias icon: icon.icon
    property alias localHovered: hoverHandler.hovered
    property alias localPressed: mouseArea.pressed
    // Keep macOS detection resilient across Qt variants.
    property bool macStyle: Qt.platform.os === "osx" || Qt.platform.os === "macos" || Qt.platform.os === "darwin"
    property bool macGroupHovered: false
    property bool macWindowActive: !macStyle || !window || window.active
    property bool macGlyphVisible: macStyle && root.enabled && macWindowActive && (macGroupHovered || hoverHandler.hovered || mouseArea.pressed)
    property bool macUnsavedChanges: false
    property color macGlyphColor: "#1f1f1f"

    // tooltip
    ToolTip {
        parent: parent
        delay: 500
        visible: !macStyle && hoverHandler.hovered
        text: mode === 0 ? qsTr("Maximize") : mode === 1 ? qsTr("Minimize") : mode === 2 ? qsTr("Close") : qsTr("Unknown")
    }

    //关闭 最大化 最小化按钮
    function toggleControl(mode, modifiers) {
        if (mode === 0) {
            if (macStyle) {
                if ((modifiers & Qt.AltModifier) !== 0) {
                    // Option + click maps to zoom behavior on macOS.
                    WindowManager.maximizeWindow(window);
                } else if (window.visibility === Window.FullScreen || window.visibility === Window.Maximized) {
                    window.showNormal();
                } else {
                    window.showFullScreen();
                }
            } else {
                WindowManager.maximizeWindow(window);
            }
        } else if (mode===1) {
            window.showMinimized();
        } else if (mode===2) {
            if (window.transientParent) {
                window.visible = false;
            } else {
                window.close();
            }
        }
    }

    function macButtonColor(buttonMode) {
        if (!macWindowActive) {
            return "#D0D0D0"
        }
        if (buttonMode === 2) {
            return "#FF5F56"  // close
        }
        if (buttonMode === 1) {
            return "#FFBD2E"  // minimize
        }
        return "#27C93F"  // maximize
    }

    implicitWidth: macStyle ? 12 : 48
    implicitHeight: macStyle ? 12 : 40
    width: implicitWidth
    height: macStyle ? implicitHeight : (parent ? parent.height : implicitHeight)


    // 背景 / Background
    Rectangle {
        id: background
        anchors.fill: parent
        color: macStyle
            ? macButtonColor(mode)
            : mode === 2
                ? Theme.currentTheme.colors.captionCloseColor
                : Theme.currentTheme.colors.subtleSecondaryColor
        radius: macStyle ? width / 2 : 0
        border.width: macStyle ? 1 : 0
        border.color: macStyle ? Qt.darker(background.color, 1.15) : "transparent"
        opacity: macStyle ? (root.enabled ? 1 : 0.28) : 0
        scale: 1

        Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.InOutQuad } }
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.InOutQuad } }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 3.2
        height: 3.2
        radius: 1.6
        color: "#3A3A3A"
        visible: macStyle && root.mode === 2 && root.macUnsavedChanges && root.enabled && root.macWindowActive && !root.macGlyphVisible
    }


    // 按钮图标
    IconWidget {
        id: icon
        icon: mode === 0 ?
                window.visibility === Window.Maximized ?
                    "ic_fluent_square_multiple_20_regular" :
                    "ic_fluent_square_20_regular" :
            mode === 1 ?
                "ic_fluent_subtract_20_regular" :
            mode === 2 ?
                "ic_fluent_dismiss_20_regular"
            :
                "ic_fluent_circle_20_regular"  // unknown style
        size: mode === 0 ? 14 : 16
        visible: !macStyle
        anchors.centerIn: parent
    }

    Item {
        id: macGlyph
        anchors.centerIn: parent
        width: 7
        height: 7
        visible: macGlyphVisible

        // close: x
        Rectangle {
            visible: root.mode === 2
            width: 7
            height: 1.4
            radius: height / 2
            color: root.macGlyphColor
            anchors.centerIn: parent
            rotation: 45
            antialiasing: true
        }
        Rectangle {
            visible: root.mode === 2
            width: 7
            height: 1.4
            radius: height / 2
            color: root.macGlyphColor
            anchors.centerIn: parent
            rotation: -45
            antialiasing: true
        }

        // minimize: -
        Rectangle {
            visible: root.mode === 1
            width: 7
            height: 1.4
            radius: height / 2
            color: root.macGlyphColor
            anchors.centerIn: parent
            antialiasing: true
        }

        // maximize: +
        Rectangle {
            visible: root.mode === 0
            width: 7
            height: 1.4
            radius: height / 2
            color: root.macGlyphColor
            anchors.centerIn: parent
            antialiasing: true
        }
        Rectangle {
            visible: root.mode === 0
            width: 1.4
            height: 7
            radius: width / 2
            color: root.macGlyphColor
            anchors.centerIn: parent
            antialiasing: true
        }
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.enabled
        acceptedDevices: PointerDevice.Mouse
    }

    // 鼠标区域 / MouseArea
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: function(mouse) {
            toggleControl(mode, mouse.modifiers)
        }
    }

    states: [
        State {
        name: "disabledCtrl"
            when: !enabled && !macStyle
            PropertyChanges {  // 禁用时禁止改变属性
                target: icon;
                opacity: 0.3614
            }
            PropertyChanges {  // 禁用时禁止改变属性
                target: root;
            }
        },
        State {
            name: "pressedCtrl"
            when: !macStyle && mouseArea.pressed
            PropertyChanges {
                target: background;
                opacity: 0.8
            }
            PropertyChanges {
                target: icon;
                opacity: 0.6063
                color: root.mode === 2 ? Theme.currentTheme.colors.captionCloseTextColor : textColor
            }
        },
        State {
            name: "hoveredCtrl"
            when: !macStyle && hoverHandler.hovered
            PropertyChanges {
                target: background;
                opacity: 1
            }
            PropertyChanges {
                target: icon;
                opacity: root.mode === 2 ? 1 : 0.6063
                color: root.mode === 2 ? Theme.currentTheme.colors.captionCloseTextColor : textColor
            }
        },
        State {
            name: "macPressedCtrl"
            when: macStyle && root.enabled && mouseArea.pressed
            PropertyChanges {
                target: background;
                opacity: 0.75
                scale: 0.95
            }
            PropertyChanges {
                target: macGlyph;
                opacity: 0.95
            }
        },
        State {
            name: "macHoveredCtrl"
            when: macStyle && root.enabled && hoverHandler.hovered
            PropertyChanges {
                target: background;
                opacity: 0.9
                scale: 1.05
            }
            PropertyChanges {
                target: macGlyph;
                opacity: 1
            }
        }
    ]
}
