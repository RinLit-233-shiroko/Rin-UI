import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"


Rectangle {
    id: root
    property int count: -1
    property string text: {
        if (root.count < 0)
            return ""
        else if (root.count > maxCount)
            return maxCount + "+"
        else
            return count.toString()
    }
    property int maxCount: 99
    property string icon: {
        switch (severity) {
            case Severity.Info: return "ic_fluent_text_asterisk_20_filled";
            case Severity.Success: return "ic_fluent_checkmark_20_filled";
            case Severity.Warning: return "!";
            case Severity.Error: return "ic_fluent_dismiss_20_filled";
            default: return "";
        }
    }
    property bool dot: false
    property int severity: Severity.Info

    property bool solid: true
    property color primaryColor: {
        switch (severity) {
            case Severity.Info: return Theme.currentTheme.colors.systemAttentionColor;
            case Severity.Success: return Theme.currentTheme.colors.systemSuccessColor;
            case Severity.Warning: return Theme.currentTheme.colors.systemCautionColor;
            case Severity.Error: return Theme.currentTheme.colors.systemCriticalColor;
            default: return Theme.currentTheme.colors.systemNeutralColor;
        }
    }

    width: dot ? 4 : Math.max(contents.width + 6, 16) + !solid * 2
    height: dot ? 4 : 16 + !solid * 2
    radius: height / 2

    RowLayout {
        id: contents
        anchors.centerIn: parent
        spacing: 4
        visible: !root.dot

        IconWidget {
            icon: root.icon
            size: 10
            color: solid ? Theme.currentTheme.colors.textOnAccentColor : primaryColor
            visible: !root.text
        }

        Text {
            typography: Typography.Caption
            text: root.text
            color: solid ? Theme.currentTheme.colors.textOnAccentColor : primaryColor
            visible: root.text
        }
    }

    color: solid ? primaryColor : "transparent"
    border.width: Theme.currentTheme.appearance.borderWidth
    border.color: solid ? "transparent" : primaryColor

    Behavior on color {
        ColorAnimation {
            duration: Utils.appearanceSpeed
            easing.type: Easing.OutQuint
        }
    }
}
