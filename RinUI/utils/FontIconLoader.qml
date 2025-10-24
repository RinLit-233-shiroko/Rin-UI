pragma Singleton
import QtQuick 2.15
import "../themes"


Item {
    property string name: fontLoader.name
    FontLoader {
        id: fontLoader
        source: Utils.fontIconSource
    }

    Component.onCompleted: console.log("Font Source:", fontLoader.name, "Status:", fontLoader.status)
}
