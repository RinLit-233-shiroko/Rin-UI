import QtQuick
import QtQuick.Controls
import "../../themes"
import "../../utils"

Text {
    id: label
    property int typography: -1

    color: Theme.currentTheme.colors.textColor
    linkColor: Theme.currentTheme.colors.primaryColor
    wrapMode: Text.WordWrap

    // 主题切换动画

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

    font.family: Utils.fontFamily

    font.weight: {
        switch (typography) {
            case Typography.Display:
            case Typography.TitleLarge:
            case Typography.Title:
            case Typography.Subtitle:
            case Typography.BodyLarge:
            case Typography.BodyStrong:
                return Font.DemiBold;
            case Typography.Body:
            case Typography.Caption:
                return Font.Normal;
            default:
                return font.weight;
        }
    }

    lineHeightMode: Text.FixedHeight
    lineHeight: {
        switch (typography) {
            case Typography.Display: return Theme.currentTheme.typography.displayLineHeight;
            case Typography.TitleLarge: return Theme.currentTheme.typography.titleLargeLineHeight;
            case Typography.Title: return Theme.currentTheme.typography.titleLineHeight;
            case Typography.Subtitle: return Theme.currentTheme.typography.subtitleLineHeight;
            case Typography.BodyLarge: return Theme.currentTheme.typography.bodyLargeLineHeight;
            case Typography.Body: return Theme.currentTheme.typography.bodyLineHeight;
            case Typography.BodyStrong: return Theme.currentTheme.typography.bodyStrongLineHeight;
            case Typography.Caption: return Theme.currentTheme.typography.captionLineHeight;
            default: return Theme.currentTheme.typography.bodyLineHeight;
        }
    }
}
