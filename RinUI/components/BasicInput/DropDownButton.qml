import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"

Button {
    id: root
    default property alias contentData: menu.contentData
    suffixIconName: "ic_fluent_chevron_down_20_filled"

    Menu {
        id: menu
    }

    onClicked: {
        if (menu.count > 0) {
            menu.open()
        }
    }
}
