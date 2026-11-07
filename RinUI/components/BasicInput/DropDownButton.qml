import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"

Button {
    id: root
    property var flyout: null // 可赋值为 Menu、Flyout 或任意 Popup
    default property alias contentData: menu.contentData
    suffixIconName: "ic_fluent_chevron_down_20_filled"

    Menu {
        id: menu
    }

    Component.onCompleted: {
        if (!flyout && menu.count > 0) {
            console.warn("DeprecationWarning: Direct MenuItem children on DropDownButton are deprecated. " +
                         "Assign a Menu or Flyout to the 'flyout' property instead.")
        }
    }

    onClicked: {
        if (!flyout && menu.count === 0)
            return
        (flyout || menu).open()
    }
}
