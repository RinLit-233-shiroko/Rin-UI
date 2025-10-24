import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"

ProgressRing {
    property bool running: true  // 兼容BusyIndicator
    state: ProgressRing.Running
    indeterminate: running
}
