import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects
import "../themes"

DropShadow {
    property string style: "cardRest" // shadow style

    anchors.fill: source
    horizontalOffset: 0
    verticalOffset: Theme.currentTheme.shadows[style].offsetY
    radius: Theme.currentTheme.shadows[style].blur
    color: Theme.currentTheme.shadows[style].color
    samples: 1 + radius * 2
    // source: sourceItem
    cached: true
}

// Repeater {
//     id: shadowRepeater
//     property string style: "cardRest"
//     property int blurRadius: Theme.currentTheme.shadows[style].blur
//     property int offsetY: Theme.currentTheme.shadows[style].offsetY
//     property real intensity: 1.5          // 阴影强度系数
//     property real spreadRatio: 1        // 阴影扩散系数
//     property real controlRadius: 8         // 控制半径
//     readonly property color shadowColor: Theme.currentTheme.shadows[style].color
//
//     model: Math.max(blurRadius, 16) // 保证最小8层渲染
//
//     Rectangle {
//         anchors {
//             fill: parent
//             margins: -index * spreadRatio  // 非线性扩散
//             topMargin: -index * spreadRatio + (offsetY) // 动态偏移分配
//         }
//
//         color: "transparent"
//         radius: controlRadius + (index * spreadRatio) // 优化半径增长曲线
//         border.width: 1
//         border.color: shadowColor
//
//         // 非线性透明度衰减
//         opacity: (0.011 * (count - index + 1)) * shadowRepeater.opacity
//
//         z: -1
//     }
// }
