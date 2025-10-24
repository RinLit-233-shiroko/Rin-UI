import QtQuick 2.15
import Qt5Compat.GraphicalEffects
import QtQuick.Controls.Basic 2.15
import "../../themes"
import "../../components"


TextInput {
    id: root
    property int typography: Typography.Body
    selectByMouse: true

    color: Theme.currentTheme.colors.textColor
    selectionColor: Theme.currentTheme.colors.primaryColor

    // Menu
    TextInputMenu {
        id: contextMenu
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        propagateComposedEvents: true
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton)
                contextMenu.popup(mouse.scenePosition)
            mouse.accepted = false
        }

        // 鼠标
        cursorShape: Qt.IBeamCursor
    }

    font.pixelSize: {
        switch (typography) {
            case Typography.Display: return Theme.currentTheme.typography.displaySize;
            case Typography.TitleLarge: return Theme.currentTheme.typography.titleLargeSize;
            case Typography.Title: return Theme.currentTheme.typography.titleSize;
            case Typography.Subtitle: return Theme.currentTheme.typography.subtitleSize;
            case Typography.Body: return Theme.currentTheme.typography.bodySize;
            case Typography.BodyStrong: return Theme.currentTheme.typography.bodyStrongSize;
            case Typography.BodyLarge: return Theme.currentTheme.typography.bodyLargeSize;
            case Typography.Caption: return Theme.currentTheme.typography.captionSize;
            default: return Theme.currentTheme.typography.bodySize;
        }
    }
}
