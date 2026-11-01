import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import "../components"


Item {
    id: floatLayer
    anchors.fill: parent
    anchors.margins: margins
    property int margins: 32
    property int spacing: 12

    // Position
    ColumnLayout {
        id: topLeft
        anchors.top: parent.top
        anchors.left: parent.left
        spacing: floatLayer.spacing
        width: floatLayer.width / 2
    }

    ColumnLayout {
        id: topCenter
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: floatLayer.spacing
        width: floatLayer.width / 2
    }

    ColumnLayout {
        id: topRight
        anchors.top: parent.top
        anchors.right: parent.right
        spacing: floatLayer.spacing
        width: floatLayer.width / 2
    }

    ColumnLayout {
        id: bottomLeft
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        spacing: floatLayer.spacing
        width: floatLayer.width / 2
    }

    ColumnLayout {
        id: bottomCenter
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: floatLayer.spacing
        width: floatLayer.width / 2
    }

    ColumnLayout {
        id: bottomRight
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        spacing: floatLayer.spacing
        width: floatLayer.width / 2
    }

    Component {
        id: infoBarComponent
        InfoBar {
            // title: "Title"
            // text: "Text"
            Layout.fillWidth: true
        }
    }


    // Functions / 方法 //
    function createInfoBar( options = {} ){
        try{
            const { title, text, severity, timeout, position, closable } = options;
            var infoContainer = infoBarComponent.createObject(determinePosition(position), {
                title: title || "",
                text: text || "",
                severity: severity ?? Severity.Info,
                position: position || Position.Top,
                timeout: timeout ?? 1500,
                closable: closable ?? true
            });

            // return infoContainer;
        }
        catch(err){
            console.error("Error: error creating InfoBar" || err)
        }
    }

    function createCustom(component) {
    try {
        // 用 floatLayer 作为临时父对象
        var infoContainer = component.createObject(floatLayer);
        if (!infoContainer) throw "Failed to create component instance.";

        var pos = infoContainer.position;

        var realParent = determinePosition(pos);
        if (realParent && realParent !== floatLayer) {
            infoContainer.parent = realParent;
        }
    } catch(err) {
        console.error("Error: error creating component: ", component.objectName || err);
    }
}


    function determinePosition(position){
        switch(position){
        case Position.TopLeft:
            return topLeft;
        case Position.Top:
            return topCenter;
        case Position.TopRight:
            return topRight;
        case Position.BottomLeft:
            return bottomLeft;
        case Position.Bottom:
            return bottomCenter;
        case Position.BottomRight:
            return bottomRight;
        case undefined:
            return topCenter;
        default:
            console.error("Invalid position")
            return topCenter;
        }
    }
}
