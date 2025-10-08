import QtQuick 2.15
import QtQuick.Templates 2.15
import "../themes"
import "../components"

ScrollView {
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }
    ScrollBar.horizontal: ScrollBar {
        policy: ScrollBar.AsNeeded
    }
}
