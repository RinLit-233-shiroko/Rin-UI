import QtQuick 2.15
import QtQuick.Controls 2.15
import "../../themes"
import "../../components"


// Menu
Menu {
    id: contextMenu
    position: -1
    Action {
        icon.name: "ic_fluent_cut_20_regular"
        text: qsTr("Cut")
        enabled: root.selectedText.length > 0 && root.editable  // 选中&可编辑
        shortcut: "Ctrl+X"
        onTriggered: root.cut()
    }
    Action {
        icon.name: "ic_fluent_copy_20_regular"
        text: qsTr("Copy")
        enabled: root.selectedText.length > 0  // 选中内容
        shortcut: "Ctrl+C"
        onTriggered: root.copy()
    }
    Action {
        icon.name: "ic_fluent_clipboard_paste_20_regular"
        text: qsTr("Paste")
        enabled: root.editable
        shortcut: "Ctrl+V"
        onTriggered: root.paste()
    }
    Action {
        icon.name: " "
        text: qsTr("Select All")
        shortcut: "Ctrl+A"
        onTriggered: root.selectAll()
    }
}
