import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import QtQuick.Layouts 2.15
import "../../themes"
import "../../components"
import "../../utils"

Item {
    id: calendar

    implicitWidth: 300
    implicitHeight: 348

    property int displayYear: new Date().getFullYear()
    property int displayMonth: new Date().getMonth() + 1

    property var selectedDate: null
    property var rangeStart: null
    property var rangeEnd: null

    property var highlightedDates: []
    property var disabledDates: []
    // 缓存加速：避免每个格子反复映射数组
    property var _disabledMap: ({})
    property var _highlightedMap: ({})

    property bool useISOWeek: true
    property bool fastMode: true
    property bool animateTransitions: !fastMode
    property bool hoverEffectEnabled: true
    property string selectionMode: "single"
    property bool awaitingRangeEnd: false
    property string viewMode: "day"
    property int yearRangeStart: Math.floor(displayYear / 16) * 16
    property bool suppressCellBehavior: false
    property var firstCellDate: new Date()
    property int gridDaysCount: 42

    function computeFirstCellDate() {
        return startOfWeek(new Date(displayYear, displayMonth-1, 1))
    }

    // 事件
    signal dateSelected(var date)
    signal rangeSelected(var startDate, var endDate)
    signal dateStatusChanged(var date, string status)

    // 工具函数
    function toKey(d) {
        if (!d) return "";
        let y = d.getFullYear();
        let m = d.getMonth() + 1; let mm = m < 10 ? ("0" + m) : ("" + m);
        let day = d.getDate(); let dd = day < 10 ? ("0" + day) : ("" + day);
        return y + "-" + mm + "-" + dd;
    }
    function normalizeDates(arr) {
        if (!arr) return [];
        return arr.map(function (x) {
            if (x instanceof Date) return toKey(x);
            if (typeof x === "string") return x;
            return "";
        })
    }
    function isToday(d) {
        let t = new Date();
        return d.getFullYear() === t.getFullYear() && d.getMonth() === t.getMonth() && d.getDate() === t.getDate();
    }
    function isDisabled(d) {
        // 使用缓存映射，O(1) 查找
        return _disabledMap[toKey(d)] === true;
    }
    function isHighlighted(d) {
        // 使用缓存映射，O(1) 查找
        return _highlightedMap[toKey(d)] === true;
    }
    function inRange(d) {
        if (!rangeStart || !rangeEnd) return false;
        let s = Math.min(rangeStart.getTime(), rangeEnd.getTime());
        let e = Math.max(rangeStart.getTime(), rangeEnd.getTime());
        let t = d.getTime();
        return t >= s && t <= e;
    }

    function daysInMonth(y, m) { return new Date(y, m, 0).getDate(); }
    function startOfWeek(date) {
        let d = new Date(date);
        let day = d.getDay(); // 0..6 (Sun..Sat)
        let diff = useISOWeek ? ((day === 0 ? -6 : 1) - day) : -day; // Monday-first vs Sunday-first
        d.setDate(d.getDate() + diff);
        d.setHours(0,0,0,0);
        return d;
    }

    function getMonthGrid(y, m) {
        // 返回 6 行，每行 7 天的数据
        let firstDay = new Date(y, m-1, 1);
        let firstCell = startOfWeek(firstDay); // 对齐到周起始
        let grid = [];
        for (let row = 0; row < 6; row++) {
            let week = [];
            for (let col = 0; col < 7; col++) {
                let d = new Date(firstCell);
                d.setDate(firstCell.getDate() + row*7 + col);
                week.push({
                    date: d,
                    inMonth: d.getMonth() === (m-1)
                });
            }
            grid.push({ days: week });
        }
        return grid;
    }

    property int pendingDelta: 0

    function updateMonth(delta) {
        let ym = displayYear * 12 + (displayMonth - 1) + delta;
        displayYear = Math.floor(ym / 12);
        displayMonth = ym % 12 + 1;
    }

    function navigateMonth(delta) {
        if (animateTransitions) {
            pendingDelta = delta
            suppressCellBehavior = true
            runMonthAnimation(delta)
        } else {
            suppressCellBehavior = true
            updateMonth(delta)
            firstCellDate = computeFirstCellDate()
            suppressCellBehavior = false
        }
    }
    function resetToToday() {
        let t = new Date();
        displayYear = t.getFullYear();
        displayMonth = t.getMonth() + 1;
        // 重置选择与范围，并清除点击范围等待状态
        selectedDate = new Date(t);
        rangeStart = null;
        rangeEnd = null;
        awaitingRangeEnd = false;
        dateSelected(selectedDate);
        dateStatusChanged(selectedDate, "today");
    }

    property real gridOffsetX: 0
    function runMonthAnimation(delta) {
        anim.stop();
        anim.from = 0;
        anim.to = delta > 0 ? -gridArea.width : gridArea.width;
        gridOffsetX = 0;
        anim.start();
    }

    NumberAnimation {
        id: anim
        target: gridContent
        property: "x"
        duration: Utils.animationSpeedMiddle
        easing.type: Easing.OutCubic
        onStopped: {
            // 更新月份后回到原位
            updateMonth(pendingDelta)
            firstCellDate = computeFirstCellDate()
            gridContent.x = 0
            suppressCellBehavior = false
        }
    }

    // 容器卡片背景（参考设计稿）
    Frame {
        id: container
        anchors.fill: parent
        color: Theme.currentTheme.colors.cardColor
        borderColor: Theme.currentTheme.colors.cardBorderColor
        radius: Theme.currentTheme.appearance.windowRadius
        hoverable: false
    }

    Rectangle {
        id: headerBackground
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 0
        height: 44
        color: Theme.currentTheme.colors.cardSecondaryColor

        // 底部分隔线
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Theme.currentTheme.appearance.borderWidth
            color: Theme.currentTheme.colors.dividerBorderColor
        }
    }

    RowLayout {
        id: header
        anchors.fill: headerBackground
        // 增加左右边距
        anchors.leftMargin: 16
        anchors.rightMargin: 8
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        spacing: 8

        Item {
            Layout.fillWidth: true
            height: headerBackground.height
            Text {
                id: headerTitle
                anchors.verticalCenter: parent.verticalCenter
                typography: Typography.Body
                color: Theme.currentTheme.colors.textColor
                text: {
                    const locale = Qt.locale()
                    const monthName = locale.monthName(displayMonth - 1)
                    return calendar.viewMode === "day" ? (monthName + " " + displayYear)
                         : calendar.viewMode === "months" ? ("" + displayYear)
                         : (calendar.yearRangeStart + " - " + (calendar.yearRangeStart + 15))
                }
                horizontalAlignment: Text.AlignLeft
            }
            Rectangle {
                id: titleHoverBg
                anchors.verticalCenter: headerTitle.verticalCenter
                anchors.horizontalCenter: headerTitle.horizontalCenter
                width: headerTitle.paintedWidth + 8
                height: 28
                radius: Theme.currentTheme.appearance.buttonRadius
                color: titleMa.enabled && titleMa.containsMouse ? Theme.currentTheme.colors.subtleSecondaryColor : "transparent"
                Behavior on color { ColorAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuad } }
            }
            MouseArea {
                id: titleMa
                anchors.fill: headerTitle
                enabled: calendar.viewMode !== "years"
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (calendar.viewMode === "day") {
                        calendar.viewMode = "months"
                    } else if (calendar.viewMode === "months") {
                        calendar.viewMode = "years"
                    }
                }
            }
        }
        ToolButton {
            visible: false
            enabled: false
            width: 0; height: 0
            flat: true
            text: qsTr("Today")
            onClicked: resetToToday()
        }
        Switch {
            visible: false
            enabled: false
            width: 0; height: 0
            Layout.alignment: Qt.AlignVCenter
            checkedText: qsTr("多选")
            uncheckedText: qsTr("单选")
            checked: calendar.selectionMode === "range"
            onToggled: {
                calendar.selectionMode = checked ? "range" : "single"
                if (!checked) {
                    calendar.rangeStart = null
                    calendar.rangeEnd = null
                    calendar.awaitingRangeEnd = false
                }
            }
        }
        ToolSeparator { visible: false }
        ToolButton { /* up */
            flat: true
            icon.name: "ic_fluent_caret_up_20_filled"
            onClicked: {
                if (calendar.viewMode === "day") {
                    navigateMonth(-1)
                } else if (calendar.viewMode === "months") {
                    calendar.displayYear -= 1
                } else if (calendar.viewMode === "years") {
                    calendar.yearRangeStart -= 16
                }
            }
        }
        ToolButton { /* down */
            flat: true
            icon.name: "ic_fluent_caret_down_20_filled"
            onClicked: {
                if (calendar.viewMode === "day") {
                    navigateMonth(1)
                } else if (calendar.viewMode === "months") {
                    calendar.displayYear += 1
                } else if (calendar.viewMode === "years") {
                    calendar.yearRangeStart += 16
                }
            }
        }
    }

    Row {
            id: weekdayHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.margins: 8
            spacing: 4
            height: calendar.viewMode === "day" ? 40 : 0
            visible: calendar.viewMode === "day"

        Repeater {
            model: 7
            delegate: Item {
                width: gridArea.cellSize
                height: parent.height
                Text {
                    anchors.centerIn: parent
                    typography: Typography.BodyStrong
                    color: Theme.currentTheme.colors.textColor
                    text: {
                        const isoNames = [qsTr("Mo"), qsTr("Tu"), qsTr("We"), qsTr("Th"), qsTr("Fr"), qsTr("Sa"), qsTr("Su")]
                        const sunFirstNames = [qsTr("Su"), qsTr("Mo"), qsTr("Tu"), qsTr("We"), qsTr("Th"), qsTr("Fr"), qsTr("Sa")]
                        return calendar.useISOWeek ? isoNames[index] : sunFirstNames[index]
                    }
                }
            }
        }
    }

    Item {
        id: gridArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: weekdayHeader.bottom
        anchors.margins: 8

        property int spacing: 2
        property real cellSize: Math.floor((width - spacing*(7-1)) / 7)

        // 容纳可动画的内容
        Item {
            id: gridContent
            anchors.fill: parent
            x: calendar.gridOffsetX

            Grid {
                id: dayGrid
                columns: 7
                rowSpacing: gridArea.spacing
                columnSpacing: gridArea.spacing
                opacity: calendar.viewMode === "day" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: (calendar.suppressCellBehavior || calendar.fastMode) ? 0 : 300; easing.type: Easing.OutCubic } }
                Repeater {
                    id: dayRepeater
                    model: calendar.gridDaysCount
                    delegate: dayCell
                }
            }

            Item {
                id: monthsView
                anchors.fill: parent
                opacity: calendar.viewMode === "months" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                property int cols: 4
                property int spacing: gridArea.spacing
                property real cellSize: Math.floor((width - spacing*(cols-1)) / cols)
                Grid {
                    anchors.fill: parent
                    columns: monthsView.cols
                    rowSpacing: monthsView.spacing
                    columnSpacing: monthsView.spacing
                    Repeater {
                        model: 16
                        delegate: Item {
                            width: monthsView.cellSize
                            height: monthsView.cellSize
                            property int monthNumber: index < 12 ? (index + 1) : (index - 12 + 1)
                            property int tileYear: index < 12 ? calendar.displayYear : (calendar.displayYear + 1)
                            property bool isSelected: (tileYear === calendar.displayYear) && (monthNumber === calendar.displayMonth)
                            property real bgScale: 0.8
                            Rectangle {
                                id: mBg
                                anchors.centerIn: parent
                                width: (Math.min(parent.width, parent.height) - 2) * bgScale
                                height: (Math.min(parent.width, parent.height) - 2) * bgScale
                                radius: (width + height) / 2
                                color: isSelected ? Theme.currentTheme.colors.primaryColor
                                      : (mMa.containsMouse ? Theme.currentTheme.colors.subtleSecondaryColor : "transparent")
                                border.color: "transparent"
                                border.width: 0
                                Behavior on color { ColorAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuad } }
                            }
                            Text {
                                anchors.centerIn: parent
                                typography: Typography.Body
                                color: isSelected ? Theme.currentTheme.colors.textOnAccentColor
                                      : (tileYear !== calendar.displayYear ? Theme.currentTheme.colors.textSecondaryColor
                                                                           : Theme.currentTheme.colors.textColor)
                                text: Qt.locale().monthName(monthNumber - 1)
                            }
                            MouseArea {
                                id: mMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    calendar.displayYear = tileYear
                                    calendar.displayMonth = monthNumber
                                    calendar.selectedDate = new Date(tileYear, monthNumber - 1, 1)
                                    calendar.viewMode = "day"
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: yearsView
                anchors.fill: parent
                opacity: calendar.viewMode === "years" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                property int cols: 4
                property int spacing: gridArea.spacing
                property real cellSize: Math.floor((width - spacing*(cols-1)) / cols)
                Grid {
                    anchors.fill: parent
                    columns: yearsView.cols
                    rowSpacing: yearsView.spacing
                    columnSpacing: yearsView.spacing
                    Repeater {
                        model: 16
                        delegate: Item {
                            property int year: calendar.yearRangeStart + index
                            width: yearsView.cellSize
                            height: yearsView.cellSize
                            property bool isSelected: year === calendar.displayYear
                            property real bgScale: 0.8
                            Rectangle {
                                id: yBg
                                anchors.centerIn: parent
                                width: (Math.min(parent.width, parent.height) - 2) * bgScale
                                height: (Math.min(parent.width, parent.height) - 2) * bgScale
                                radius: (width + height) / 2
                                color: isSelected ? Theme.currentTheme.colors.primaryColor
                                      : (yMa.containsMouse ? Theme.currentTheme.colors.subtleSecondaryColor : "transparent")
                                border.color: "transparent"
                                border.width: 0
                                Behavior on color { ColorAnimation { duration: Utils.animationSpeed; easing.type: Easing.OutQuad } }
                            }
                            Text {
                                anchors.centerIn: parent
                                typography: Typography.Body
                                color: isSelected ? Theme.currentTheme.colors.textOnAccentColor : Theme.currentTheme.colors.textColor
                                text: year
                            }
                            MouseArea {
                                id: yMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    calendar.displayYear = year
                                    calendar.viewMode = "months"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: dayCell
        Item {
            property var date: (function() { var d = new Date(calendar.firstCellDate); d.setDate(calendar.firstCellDate.getDate() + index); return d; })()
            property bool inMonth: date.getMonth() === (calendar.displayMonth - 1)
            property bool isSelected: calendar.selectedDate && calendar.toKey(calendar.selectedDate) === calendar.toKey(date)
            property bool disabled: calendar._disabledMap[calendar.toKey(date)] === true
            property bool highlighted: calendar._highlightedMap[calendar.toKey(date)] === true
            width: gridArea.cellSize
            height: gridArea.cellSize
            Rectangle {
                id: bg
                width: Math.min(parent.width, parent.height) - 2
                height: Math.min(parent.width, parent.height) - 2
                anchors.centerIn: parent
                radius: (width + height) / 2
                color: isSelected ? Theme.currentTheme.colors.primaryColor
                      : inRange(date) ? Qt.alpha(Theme.currentTheme.colors.primaryColor, Theme.isDark() ? 0.12 : 0.18)
                      : (ma.containsMouse ? Theme.currentTheme.colors.subtleSecondaryColor : "transparent")
                border.color: (!isSelected && isToday(date)) ? Theme.currentTheme.colors.primaryColor : "transparent"
                border.width: (!isSelected && isToday(date)) ? 1 : 0
                Behavior on color { ColorAnimation { duration: calendar.suppressCellBehavior ? 0 : Utils.animationSpeed; easing.type: Easing.OutQuad } }
            }
            Text {
                anchors.centerIn: parent
                typography: Typography.Body
                color: !inMonth ? Theme.currentTheme.colors.textSecondaryColor
                      : disabled ? Theme.currentTheme.colors.textSecondaryColor
                      : isSelected ? Theme.currentTheme.colors.textOnAccentColor
                      : Theme.currentTheme.colors.textColor
                text: date.getDate()
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: calendar.hoverEffectEnabled
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    if (disabled) return;
                    if (calendar.selectionMode === "single") {
                        calendar.selectedDate = date
                        calendar.rangeStart = null
                        calendar.rangeEnd = null
                        calendar.awaitingRangeEnd = false
                        calendar.dateSelected(date)
                        calendar.dateStatusChanged(date, "selected")
                    } else { // range
                        if (!calendar.awaitingRangeEnd) {
                            calendar.rangeStart = date
                            calendar.rangeEnd = date
                            calendar.awaitingRangeEnd = true
                            calendar.selectedDate = date
                            calendar.dateStatusChanged(date, "range_start")
                        } else {
                            var start = calendar.rangeStart ? calendar.rangeStart : date
                            var end = date
                            if (end.getTime() < start.getTime()) {
                                calendar.rangeEnd = start
                                calendar.rangeStart = end
                            } else {
                                calendar.rangeEnd = end
                            }
                            calendar.awaitingRangeEnd = false
                            calendar.selectedDate = calendar.rangeEnd
                            calendar.rangeSelected(calendar.rangeStart, calendar.rangeEnd)
                            calendar.dateStatusChanged(date, "range_end")
                        }
                    }
                }
                onEntered: {
                    if (calendar.isDraggingRange && !disabled) {
                        calendar.rangeEnd = date
                        calendar.dateStatusChanged(date, "range_update")
                    }
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height) - 2
                height: Math.min(parent.width, parent.height) - 2
                radius: (width + height) / 2
                color: disabled ? Qt.alpha(Theme.currentTheme.colors.disabledColor, Theme.isDark() ? 0.1 : 0.06) : "transparent"
            }
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height) - 2
                height: Math.min(parent.width, parent.height) - 2
                radius: (width + height) / 2
                color: "transparent"
                visible: !isSelected && highlighted
                border.width: highlighted ? 1 : 0
                border.color: Theme.currentTheme.colors.primaryColor
            }
        }
    }

    onDisabledDatesChanged: {
        var set = normalizeDates(disabledDates)
        var m = {}
        for (var i = 0; i < set.length; i++) { var k = set[i]; if (k) m[k] = true }
        _disabledMap = m
    }
    onHighlightedDatesChanged: {
        var set = normalizeDates(highlightedDates)
        var m = {}
        for (var i = 0; i < set.length; i++) { var k = set[i]; if (k) m[k] = true }
        _highlightedMap = m
    }
    Component.onCompleted: {
        // 初始化缓存
        var ds = normalizeDates(disabledDates)
        var dm = {}
        for (var i = 0; i < ds.length; i++) { var k = ds[i]; if (k) dm[k] = true }
        _disabledMap = dm
        var hs = normalizeDates(highlightedDates)
        var hm = {}
        for (var j = 0; j < hs.length; j++) { var kk = hs[j]; if (kk) hm[kk] = true }
        _highlightedMap = hm
        // 初始化首格日期
        firstCellDate = computeFirstCellDate()
    }

    onSelectedDateChanged: {
        if (selectedDate) dateStatusChanged(selectedDate, "selected")
    }
    onRangeStartChanged: {
        if (rangeStart) dateStatusChanged(rangeStart, "range_start")
    }
    onRangeEndChanged: {
        if (rangeEnd) dateStatusChanged(rangeEnd, "range_update")
    }
    onDisplayMonthChanged: {
        dateStatusChanged(new Date(displayYear, displayMonth-1, 1), "month_changed")
        firstCellDate = computeFirstCellDate()
    }
    onDisplayYearChanged: {
        dateStatusChanged(new Date(displayYear, displayMonth-1, 1), "month_changed")
        firstCellDate = computeFirstCellDate()
    }
    onUseISOWeekChanged: {
        firstCellDate = computeFirstCellDate()
    }

}