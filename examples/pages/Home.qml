import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import QtQuick.Window 2.15
import Qt5Compat.GraphicalEffects  // 图形库
import RinUI
import "../assets"
import "../components"

FluentPage {
    // title: "test"
    horizontalPadding: 0
    wrapperWidth: width - 42*2
    spacing: 18
    id: root

    // Banner / 横幅 //
    contentHeader: Item {
        width: parent.width
        height: 350
        // height: Math.max(window.height * 0.45, 200)

        Image {
            id: bannerSource
            anchors.fill: parent
            source: "../assets/banner.png"
            fillMode: Image.PreserveAspectCrop
            verticalAlignment: Image.AlignTop
        }

        ShaderEffectSource {
            id: bannerTexture
            sourceItem: bannerSource
            hideSource: true
            live: true
            visible: false
        }

        Item {
            id: bannerBackdrop
            anchors.fill: parent

            // Rectangle {
            //     anchors.fill: parent
            //     color: Theme.currentTheme.colors.backgroundColor
            // }

            OpacityMask {
                id: bannerContent
                anchors.fill: parent
                source: bannerTexture
                maskSource: Rectangle {
                    width: bannerContent.width
                    height: bannerContent.height

                    gradient: Gradient {
                        GradientStop { position: 0.75; color: "white" }
                        GradientStop { position: 0.97; color: "transparent" }
                    }
                }
            }
        }

        Column {
            anchors {
                top: parent.top
                left: parent.left
                leftMargin: 56
                topMargin: 38
            }
            spacing: 8

            Text {
                color: "#fff"
                font.pixelSize: 18
                font.weight: 600
                text: qsTr("A Fluent Design-like UI library for Qt Quick")
            }

            Text {
                color: "#fff"
                typography: Typography.TitleLarge
                text: qsTr("RinUI Gallery")
            }
        }
    }

    // link card
    Flickable {
        Layout.fillWidth: true
        // width: parent.width
        implicitWidth: parent.width
        height: linkRow.height
        contentWidth: linkRow.width

        Layout.topMargin: -164

        clip: true

        // horz scrollbar

        Row {
            id: linkRow
            spacing: 12

            Repeater {
                model: [
                    {
                        title: qsTr("Getting Started"),
                        desc: qsTr("Get started with RinUI and explore detailed documentation."),
                        icon: Qt.resolvedUrl("../assets/gallery.png"),
                        url: qsTr("https://ui.rinlit.cn/guide/getting-started.html")
                    },
                    {
                        title: qsTr("Documentation"),
                        desc: qsTr("Explore the comprehensive documentation for RinUI components."),
                        icon: Qt.resolvedUrl("../assets/controls/RichTextBlock.png"),
                        url: qsTr("https://ui.rinlit.cn/")
                    },
                    {
                        title: qsTr("RinUI on GitHub"),
                        desc: qsTr("Explore the RinUI source code and repository."),
                        icon: Theme.isDark() ? Qt.resolvedUrl("../assets/github_light.svg")
                                            : Qt.resolvedUrl("../assets/github.svg"),
                        url: "https://github.com/RinLit-233-shiroko/Rin-UI"
                    },
                ]
                delegate: LinkClip {
                    AcrylicBrush {
                        sourceItem: bannerBackdrop
                    }
                }
            }
        }
    }

    // Special Warning
    // InfoBar {
    //     Layout.fillWidth: true
    //     severity: Severity.Success
    //     closable: false
    //     title: qsTr("🎉 Congratulations!")
    //     text: qsTr(
    //         "Congratulations! The refactoring of RinUI Gallery is now <b>complete</b>."
    //     )
    // }


    // page
    property int pageState: 0
    property var favoriteItems: []
    property var recentlyViewedItems: []
    // 0 -> Recent
    // 1 -> Favorite

    Component.onCompleted: {
        favoriteItems = ItemData.getFavoriteItems(Backend.getFavorites())
        recentlyViewedItems = ItemData.getRecentlyViewedItems(Backend.getRecentlyViewed())
    }

    Row {
        spacing: 8
        Layout.topMargin: 32
        Layout.alignment: Qt.AlignHCenter

        PillButton {
            width: 114
            icon.name: "ic_fluent_clock_20_regular"
            text: qsTr("Recent")
            highlighted: pageState === 0
            onClicked: {
                if (pageState !== 0) {
                    pageState = 0
                    contentStack.replace(recentPageComponent)
                }
            }
        }
        PillButton {
            width: 114
            icon.name: "ic_fluent_star_20_regular"
            text: qsTr("Favorite")
            highlighted: pageState === 1
            onClicked: {
                if (pageState !== 1) {
                    pageState = 1
                    contentStack.replace(favoritePageComponent)
                }
            }
        }
    }

    // Content / 内容 //
    StackView {
        id: contentStack
        Layout.fillWidth: true
        implicitWidth: parent.width
        implicitHeight: currentItem ? currentItem.implicitHeight : 0
        clip: true

        onCurrentItemChanged: {
            if (currentItem) {
                pageState = currentItem.pageIndex
            }
        }

        replaceEnter : Transition {
            SequentialAnimation  {
                PropertyAction {
                    property: "opacity"
                    value: 0
                }

                PauseAnimation {
                    duration: 50
                }

                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Utils.appearanceSpeed / 2
                    easing.type: Easing.InOutQuad
                }
            }

            PropertyAnimation {
                property: "y"
                from: 50
                to: 0
                duration: Utils.animationSpeedMiddle
                easing.type: Easing.OutQuint
            }
        }

        replaceExit : Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 100
            }
            PropertyAnimation {
                property: "y"
                from: 0
                to: 50
                duration: 100
                easing.type: Easing.InQuint
            }
        }

        initialItem: recentPageComponent

        Component {
            id: recentPageComponent

            Item {
                property int pageIndex: 0
                width: contentStack.width
                implicitHeight: recentContent.implicitHeight

                Column {
                    id: recentContent
                    width: parent.width
                    spacing: 32

                    Column {
                        width: parent.width
                        spacing: 12
                        Text {
                            typography: Typography.BodyStrong
                            font.pixelSize: 15
                            text: qsTr("Recently visited")
                        }
                        visible: recentlyViewedItems.length !== 0

                        Flickable {
                            id: vsFlickable
                            width: parent.width
                            contentWidth: visitedSamples.width
                            height: 100
                            visible: recentlyViewedItems.length > 0
                            clip: true
                            Row {
                                id: visitedSamples
                                spacing: 12
                                Repeater {
                                    model: recentlyViewedItems
                                    delegate: ControlClip { }
                                }
                            }

                            Behavior on contentX {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutQuad
                                }
                            }

                            WheelHandler {
                                target: null
                                onWheel: (wheel) => {
                                    let delta = wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : wheel.angleDelta.y;
                                    vsFlickable.contentX = Math.max(0, Math.min(vsFlickable.contentX - delta*2, vsFlickable.contentWidth - vsFlickable.width));
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 12
                        Text {
                            typography: Typography.BodyStrong
                            font.pixelSize: 15
                            text: qsTr("Recently added")
                        }

                        Grid {
                            width: parent.width
                            columns: Math.floor((width-12) / (300 + 6))
                            rowSpacing: 12
                            columnSpacing: 12
                            layoutDirection: GridLayout.LeftToRight

                            Repeater {
                                model: ItemData.recentlyAddedItems
                                delegate: ControlClip { }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 12
                        Text {
                            typography: Typography.BodyStrong
                            text: qsTr("Recently updated")
                        }

                        Grid {
                            width: parent.width
                            columns: Math.floor(width / (360 + 6))
                            rowSpacing: 12
                            columnSpacing: 12
                            layoutDirection: GridLayout.LeftToRight

                            Repeater {
                                model: ItemData.recentlyUpdatedItems
                                delegate: ControlClip { }
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: favoritePageComponent

            Item {
                property int pageIndex: 1
                width: contentStack.width
                implicitHeight: favoriteItems.length > 0 ? favoriteGrid.implicitHeight : 200

                Grid {
                    id: favoriteGrid
                    width: parent.width
                    columns: Math.floor(width / (360 + 6))
                    rowSpacing: 12
                    columnSpacing: 12
                    layoutDirection: GridLayout.LeftToRight
                    visible: favoriteItems.length > 0

                    Repeater {
                        model: favoriteItems
                        delegate: ControlClip { }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    id: emptyFavorite
                    visible: favoriteItems.length === 0
                    spacing: 8

                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        size: 36
                        source: Qt.resolvedUrl("../assets/controls/RatingControl.png")
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        typography: Typography.BodyStrong
                        text: qsTr("No favorites yet")
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        typography: Typography.Body
                        color: Theme.currentTheme.colors.textSecondaryColor
                        text: qsTr("Favorite samples by clicking the star icon on the sample page.")
                    }
                }
            }
        }
    }
}
