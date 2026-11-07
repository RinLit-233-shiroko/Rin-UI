import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../../themes"
import "../../components"

Item {
    id: root

    property var items: []
    property int currentIndex: items.length > 0 ? items.length - 1 : -1
    readonly property int activeIndex: items.length > 0 ? Math.max(0, Math.min(currentIndex, items.length - 1)) : -1
    property var flatEntries: []
    property var foldedEntries: []
    property real fullWidth: 0
    property real foldX: 0
    property real overlayWidth: 120
    property int focusIndex: -1
    property int popupIndex: -1
    property real _foldOpenY: 0
    property bool keyboardMode: false
    readonly property bool foldFocused: focusIndex >= 0 && isFoldedIndex(focusIndex)

    enum Size { Standard, Large }
    property var size: BreadcrumbBar.Standard
    readonly property bool large: size === BreadcrumbBar.Large

    readonly property int rowHeight: large ? 40 : 32
    readonly property int itemPadding: 16
    readonly property int separatorWidth: 12
    readonly property int foldIconSize: large ? 28 : 24
    readonly property int foldChipWidth: large ? 40 : 32

    signal itemClicked(int index, var item)

    implicitHeight: rowHeight
    implicitWidth: fullWidth
    activeFocusOnTab: true

    Accessible.role: Accessible.Pane
    Accessible.name: qsTr("Breadcrumb")

    onActiveFocusChanged: {
        keyboardMode = activeFocus
        if (!activeFocus || items.length === 0)
            return
        if (focusIndex < 0)
            focusIndex = activeIndex >= 0 ? activeIndex : 0
        focusIndex = focusStop(focusIndex)
    }

    TextMetrics {
        id: metrics
        font.family: Utils.fontFamily
        font.pixelSize: root.large ? Theme.currentTheme.typography.subtitleSize
                                   : Theme.currentTheme.typography.bodySize
    }

    function measure(text) {
        metrics.text = text === undefined || text === null ? "" : String(text)
        return Math.ceil(metrics.advanceWidth)
    }

    function titleOf(index) {
        var item = items[index]
        if (item === undefined || item === null)
            return ""
        return typeof item === "string" ? item : (item.title === undefined ? "" : String(item.title))
    }

    function itemWidth(index) {
        return measure(titleOf(index)) + itemPadding
    }

    function isFoldedIndex(index) {
        for (var i = 0; i < foldedEntries.length; i++) {
            if (foldedEntries[i].index === index)
                return true
        }
        return false
    }

    function focusStop(index) {
        if (index < 0)
            return 0
        return isFoldedIndex(index) ? foldedEntries[0].index : index
    }

    function focusStopBefore(index) {
        var previous = focusStop(index) - 1
        if (previous < 0)
            return 0
        return isFoldedIndex(previous) ? foldedEntries[0].index : previous
    }

    function focusStopAfter(index) {
        var current = focusStop(index)
        if (foldedEntries.length > 0 && current === foldedEntries[0].index)
            return Math.min(items.length - 1, foldedEntries[foldedEntries.length - 1].index + 1)
        return Math.min(items.length - 1, current + 1)
    }

    function placeFold() {
        var w = Math.max(overflowPopup.width, overflowPopup.implicitWidth)
        overflowPopup.x = Math.max(0, Math.min(foldX, width - w))
        if (!overflowPopup.enter.running)
            overflowPopup.y = _foldOpenY
    }

    function openFold(anchorX, anchorWidth, keyboard) {
        foldX = anchorX
        foldAnchor.width = anchorWidth
        _foldOpenY = rowHeight + 4
        overflowPopup.y = _foldOpenY
        placeFold()
        popupIndex = keyboard && foldedEntries.length > 0 ? 0 : -1
        overflowPopup.open()
        root.forceActiveFocus()
        root.keyboardMode = keyboard === true
    }

    function closeFold() {
        popupIndex = -1
        overflowPopup.close()
    }

    function openFolded(keyboard) {
        var x = 0
        for (var i = 0; i < flatEntries.length; i++) {
            var entry = flatEntries[i]
            if (entry.kind === "fold") {
                openFold(x, entry.width, keyboard === true)
                return
            }
            x += entry.width
        }
    }

    function activateIndex(index) {
        itemClicked(index, items[index])
        overflowPopup.close()
    }

    function foldWidth(head, tail) {
        var width = foldChipWidth
        for (var i = 0; i < head; i++)
            width += itemWidth(i) + separatorWidth
        for (var j = items.length - tail; j < items.length; j++)
            width += itemWidth(j) + separatorWidth
        return width
    }

    function measureAll() {
        var count = items ? items.length : 0
        var total = 0
        for (var i = 0; i < count; i++) {
            total += itemWidth(i)
            if (i > 0)
                total += separatorWidth
        }
        fullWidth = total
    }

    function rebuild() {
        var count = items ? items.length : 0
        var entries = []
        var folded = []
        var total = fullWidth

        if (count > 0 && width > 0 && total > width) {
            var head = 1
            var tail = Math.min(2, Math.max(1, count - 2))
            while (head + tail > count - 1) {
                if (tail > 1)
                    tail--
                else if (head > 0)
                    head--
                else
                    break
            }
            while (head + tail < count && foldWidth(head, tail) > width && (head > 0 || tail > 1)) {
                if (tail > 1)
                    tail--
                else
                    head--
            }
            var first = head
            var last = count - tail
            for (var h = 0; h < head; h++)
                entries.push({ kind: "item", index: h, width: itemWidth(h) })
            if (last > first) {
                entries.push({ kind: "fold", width: foldChipWidth })
                for (var f = first; f < last; f++)
                    folded.push({ index: f, item: items[f] })
            }
            for (var t = last; t < count; t++)
                entries.push({ kind: "item", index: t, width: itemWidth(t) })
        } else {
            for (var k = 0; k < count; k++)
                entries.push({ kind: "item", index: k, width: itemWidth(k) })
        }

        var flat = []
        var cursor = 0
        var foldStart = -1
        for (var e = 0; e < entries.length; e++) {
            if (e > 0) {
                flat.push({ kind: "separator", width: separatorWidth })
                cursor += separatorWidth
            }
            if (entries[e].kind === "fold")
                foldStart = cursor
            flat.push(entries[e])
            cursor += entries[e].width
        }
        if (foldStart >= 0)
            foldX = foldStart

        var widest = 0
        for (var d = 0; d < folded.length; d++)
            widest = Math.max(widest, itemWidth(folded[d].index))
        overlayWidth = Math.max(120, widest + 16)

        flatEntries = flat
        foldedEntries = folded
        if (folded.length === 0)
            overflowPopup.close()
        if (focusIndex >= count)
            focusIndex = count - 1
        if (focusIndex >= 0)
            focusIndex = focusStop(focusIndex)
    }

    onItemsChanged: {
        measureAll()
        rebuild()
    }
    onWidthChanged: rebuild()
    onSizeChanged: Qt.callLater(function () {
        measureAll()
        rebuild()
        if (overflowPopup.visible) {
            _foldOpenY = rowHeight + 4
            placeFold()
        }
    })

    onFoldXChanged: {
        if (overflowPopup.visible)
            placeFold()
    }
    onOverlayWidthChanged: {
        if (overflowPopup.visible)
            placeFold()
    }

    Component.onCompleted: {
        measureAll()
        rebuild()
    }

    Item {
        id: viewport
        anchors.fill: parent
        clip: true

        Row {
            id: row
            height: root.rowHeight

            Repeater {
                model: root.flatEntries

                delegate: Item {
                    readonly property bool isItem: modelData.kind === "item"
                    readonly property bool isFold: modelData.kind === "fold"
                    readonly property bool isSeparator: modelData.kind === "separator"
                    readonly property bool isCurrent: isItem && modelData.index === root.activeIndex
                    readonly property int itemIndex: modelData.index === undefined ? -1 : modelData.index

                    width: modelData.width
                    height: root.rowHeight

                    readonly property bool keyboardFocused: root.activeFocus && root.keyboardMode && !isSeparator
                                                            && !overflowPopup.visible
                                                            && (isFold ? root.foldFocused : root.focusIndex === itemIndex)

                    Accessible.role: Accessible.Button
                    Accessible.name: isFold ? qsTr("Show more") : root.titleOf(itemIndex)
                    Accessible.ignored: isSeparator
                    Accessible.focusable: !isSeparator
                    Accessible.focused: keyboardFocused
                    Accessible.pressed: mouseArea.pressed
                    Accessible.onPressAction: activate()

                    function activate() {
                        if (isFold) {
                            root.openFold(mapToItem(root, 0, 0).x, width)
                        } else if (isItem) {
                            root.itemClicked(itemIndex, root.items[itemIndex])
                        }
                    }

                    IconWidget {
                        anchors.centerIn: parent
                        visible: parent.isSeparator
                        icon: "ic_fluent_chevron_right_20_regular"
                        size: 18
                        color: Theme.currentTheme.colors.textSecondaryColor
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 4
                        color: mouseArea.pressed ? Theme.currentTheme.colors.subtleTertiaryColor
                                                 : Theme.currentTheme.colors.subtleSecondaryColor
                        opacity: !parent.isSeparator && !parent.isCurrent && mouseArea.containsMouse ? 1 : 0
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 4
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.currentTheme.colors.focusBorderInner
                        visible: parent.keyboardFocused
                    }

                    FocusIndicator {
                        control: root
                        anchors.margins: 2
                        radius: 6
                        keyboardFocus: parent.keyboardFocused
                        visible: parent.keyboardFocused
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: parent.isItem
                        text: root.titleOf(parent.itemIndex)
                        typography: root.large ? Typography.Subtitle : Typography.Body
                        color: root.large && !parent.isCurrent ? Theme.currentTheme.colors.textSecondaryColor
                                                               : Theme.currentTheme.colors.textColor
                    }

                    IconWidget {
                        anchors.centerIn: parent
                        visible: parent.isFold
                        icon: "ic_fluent_more_horizontal_20_regular"
                        size: root.foldIconSize
                        color: Theme.currentTheme.colors.textSecondaryColor
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        enabled: !parent.isSeparator && !parent.isCurrent
                        hoverEnabled: true
                        onPressed: root.keyboardMode = false
                        onClicked: parent.activate()
                    }
                }
            }
        }
    }

    Item {
        id: foldAnchor
        x: root.foldX
        y: 0
        width: 0
        height: root.rowHeight
        visible: false
    }

    Flyout {
        id: overflowPopup
        parent: root
        anchorItem: foldAnchor
        position: Position.None
        padding: 5
        background: Item {
            RectangularShadow {
                anchors.fill: surface
                radius: surface.radius
                blur: Theme.currentTheme.shadows.flyout.blur
                offset.y: Theme.currentTheme.shadows.flyout.offsetY
                color: Theme.currentTheme.shadows.flyout.color
            }

            Rectangle {
                id: surface
                anchors.fill: parent
                radius: Theme.currentTheme.appearance.windowRadius
                color: Theme.currentTheme.colors.backgroundAcrylicColor
                border.width: 1
                border.color: Theme.currentTheme.colors.flyoutBorderColor
            }
        }

        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    target: overflowPopup
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Utils.animationSpeed
                    easing.type: Easing.OutQuint
                }
                NumberAnimation {
                    target: overflowPopup
                    property: "y"
                    from: root._foldOpenY - 8
                    to: root._foldOpenY
                    duration: Utils.animationSpeed
                    easing.type: Easing.OutQuint
                }
            }
        }

        exit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    target: overflowPopup
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Utils.animationSpeedFaster
                    easing.type: Easing.OutQuint
                }
                NumberAnimation {
                    target: overflowPopup
                    property: "y"
                    from: root._foldOpenY
                    to: root._foldOpenY - 4
                    duration: Utils.animationSpeedFaster
                    easing.type: Easing.OutQuint
                }
            }
        }

        Column {
            spacing: 0

            Repeater {
                model: root.foldedEntries

                delegate: Rectangle {
                    width: Math.max(120, root.overlayWidth)
                    height: 34
                    radius: 4
                    color: rowMouse.containsMouse || root.popupIndex === index
                           ? Theme.currentTheme.colors.subtleSecondaryColor : "transparent"

                    Accessible.role: Accessible.ListItem
                    Accessible.name: root.titleOf(modelData.index)
                    Accessible.focusable: true
                    Accessible.focused: root.popupIndex === index
                    Accessible.onPressAction: root.activateIndex(modelData.index)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        text: root.titleOf(modelData.index)
                        typography: Typography.Body
                        color: Theme.currentTheme.colors.textColor
                    }

                    FocusIndicator {
                        control: root
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 4
                        keyboardFocus: root.keyboardMode && root.popupIndex === index && overflowPopup.visible
                        visible: keyboardFocus
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.activateIndex(modelData.index)
                    }
                }
            }
        }
    }

    Keys.onPressed: function (event) {
        keyboardMode = true
        if (overflowPopup.visible) {
            if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                popupIndex = Math.min(foldedEntries.length - 1, popupIndex + 1)
                event.accepted = true
            } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                popupIndex = Math.max(0, popupIndex - 1)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (popupIndex >= 0 && popupIndex < foldedEntries.length)
                    root.activateIndex(foldedEntries[popupIndex].index)
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                closeFold()
                event.accepted = true
            }
            return
        }

        if (items.length === 0)
            return

        if (focusIndex < 0)
            focusIndex = activeIndex >= 0 ? activeIndex : 0

        if (event.key === Qt.Key_Left) {
            focusIndex = focusStopBefore(focusIndex)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            focusIndex = focusStopAfter(focusIndex)
            event.accepted = true
        } else if (event.key === Qt.Key_Home) {
            focusIndex = 0
            event.accepted = true
        } else if (event.key === Qt.Key_End) {
            focusIndex = items.length - 1
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            if (foldFocused)
                root.openFolded(true)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (foldFocused)
                root.openFolded(true)
            else
                root.itemClicked(focusIndex, items[focusIndex])
            event.accepted = true
        }
    }
}
