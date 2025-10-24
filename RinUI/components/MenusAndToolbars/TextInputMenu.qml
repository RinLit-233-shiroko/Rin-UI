import QtQuick 2.15
import QtQuick.Controls 2.15
import "../../themes"
import "../../components"


// Menu
Menu {
    id: contextMenu
    position: -1

    property var target: parent

    onAboutToShow: {
        if (target) target.forceActiveFocus()
    }

    function canEdit() {
        if (target === null || target === undefined) return false
        if (target.editable !== undefined) return target.editable
        if (target.readOnly !== undefined) return !target.readOnly
        return true
    }

    Action {
        icon.name: "ic_fluent_cut_20_regular"
        text: qsTr("Cut")
        shortcut: "Ctrl+X"
        enabled: target && target.selectedText && target.selectedText.length > 0 && canEdit()
        onTriggered: {
            if (!target || !target.selectedText || target.selectedText.length === 0) return
            target.forceActiveFocus()
            target.cut()
        }
    }
    Action {
        icon.name: "ic_fluent_copy_20_regular"
        text: qsTr("Copy")
        shortcut: "Ctrl+C"
        enabled: target && target.selectedText && target.selectedText.length > 0
        onTriggered: {
            if (!target || !target.selectedText || target.selectedText.length === 0) return
            target.forceActiveFocus()
            target.copy()
        }
    }
    Action {
        icon.name: "ic_fluent_clipboard_paste_20_regular"
        text: qsTr("Paste")
        shortcut: "Ctrl+V"
        enabled: canEdit()
        onTriggered: {
            if (!target) return
            target.forceActiveFocus()
            target.paste()
        }
    }
    Action {
        icon.name: " "
        text: qsTr("Select All")
        shortcut: "Ctrl+A"
        onTriggered: {
            if (!target) return
            target.forceActiveFocus()
            target.selectAll()
        }
    }
}
