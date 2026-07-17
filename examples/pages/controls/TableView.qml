import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import Qt.labs.qmlmodels  // model
import RinUI
import "../../components"


ControlPage {
    id: page
    title: "TableView"
    badgeText: qsTr("Experimental")
    badgeSeverity: Severity.Warning

    Text {
        Layout.fillWidth: true
        typography: Typography.Body
        text: qsTr(
            "The TableView displays a collection of data in rows and columns."
        )
    }

    TableModel {
        id: studentsModel
        TableModelColumn { display: "name"; edit: "name" }
        TableModelColumn { display: "school"; edit: "school" }
        TableModelColumn { display: "club"; edit: "club" }
        TableModelColumn { display: "checked"; edit: "checked" }

        rows: [
            { name: qsTr("Aikiyo Fuuka"), school: qsTr("Gehenna"), club: qsTr("School Lunch Club"), checked: true },
            { name: qsTr("Hayase Yuuka"), school: qsTr("Millennium"), club: qsTr("Seminar"), checked: true },
            { name: qsTr("Hanaoka Yuzu"), school: qsTr("Millennium"), club: qsTr("Game Development Department"), checked: true },
            { name: qsTr("Kuromi Serika"), school: qsTr("Abydos"), club: qsTr("Foreclosure Task Force"), checked: true },
            { name: qsTr("Kurosaki Koyuki"), school: qsTr("Millennium"), club: qsTr("Seminar"), checked: true },
            { name: qsTr("Kuda Izuna"), school: qsTr("Hyakkiyako"), club: qsTr("Ninjutsu Research Club"), checked: true },
            { name: qsTr("Okusora Ayane"), school: qsTr("Abydos"), club: qsTr("Foreclosure Task Force"), checked: true },
            { name: qsTr("Saiba Midori"), school: qsTr("Millennium"), club: qsTr("Game Development Department"), checked: true },
            { name: qsTr("Saiba Momoi"), school: qsTr("Millennium"), club: qsTr("Game Development Department"), checked: true },
            { name: qsTr("Shiromi Iori"), school: qsTr("Gehenna"), club: qsTr("Prefect Team"), checked: true },
            { name: qsTr("Shishidou Nonomi"), school: qsTr("Abydos"), club: qsTr("Foreclosure Task Force"), checked: true },
            { name: qsTr("Sunaookami Shiroko"), school: qsTr("Abydos"), club: qsTr("Foreclosure Task Force"), checked: true },
            { name: qsTr("Tendou Aris"), school: qsTr("Millennium"), club: qsTr("Game Development Department"), checked: true },
            { name: qsTr("Ushio Noa"), school: qsTr("Millennium"), club: qsTr("Seminar"), checked: true },
            { name: qsTr("Yutori Natsu"), school: qsTr("Trinity"), club: qsTr("After-School Sweets Club"), checked: true }
        ]
    }

    Column {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: "A Basic TableView."
        }
        ControlShowcase {
            width: parent.width
            ColumnLayout {
                width: parent.width
                spacing: 4
                Text {
                    width: parent.width
                    text: "This is a basic TableView that shows complex data across multiple columns."
                }

                Item {
                    Layout.fillWidth: true
                    height: 500

                    HorizontalHeaderView {
                        id: horizontalHeader
                        anchors.left: tableView.left
                        anchors.top: parent.top
                        syncView: tableView

                        model: [
                            "Name",
                            "School",
                            "Club",
                            "Checked"
                        ]
                        visible: hrHeaderCheckBox.checked
                    }

                    VerticalHeaderView {
                        id: verticalHeader
                        anchors.top: tableView.top
                        anchors.left: parent.left
                        syncView: tableView
                        visible: vrHeaderCheckBox.checked
                    }

                    TableView {
                        id: tableView
                        anchors.left: verticalHeader.visible ? verticalHeader.right : parent.left
                        anchors.top: horizontalHeader.visible ? horizontalHeader.bottom : parent.top
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        // editTriggers: TableView.NoEditTriggers
                        // rowDividers: true
                        // columnDividers: true

                        model: studentsModel
                        selectionMode: selectionModeComboBox.model.get(selectionModeComboBox.currentIndex).value
                        selectionBehavior: selectionBehaviorComboBox.model.get(selectionBehaviorComboBox.currentIndex).value
                        editTriggers: editTriggerComboBox.model.get(editTriggerComboBox.currentIndex).value
                        enabled: !tableViewCheckBox.checked
                    }
                }
            }

            showcase: [
                CheckBox {
                    id: tableViewCheckBox
                    text: "Disable TableView"
                    checked: false
                },
                CheckBox {
                    id: hrHeaderCheckBox
                    text: "HorizontalHeaderView"
                    checked: true
                },
                CheckBox {
                    id: vrHeaderCheckBox
                    text: "VerticalHeaderView"
                    checked: true
                },
                Text {
                    text: "SelectionBehavior"
                },
                ComboBox {
                    id: selectionBehaviorComboBox
                    model: ListModel {
                        ListElement { text: "SelectionDisabled"; value: TableView.SelectionDisabled }
                        ListElement { text: "SelectCells"; value: TableView.SelectCells }
                        ListElement { text: "SelectRows"; value: TableView.SelectRows }
                        // ListElement { text: "SelectColumns"; value: TableView.SelectColumns }
                    }
                    textRole: "text"
                    currentIndex: 2
                },
                Text {
                    text: "SelectionMode"
                },
                ComboBox {
                    id: selectionModeComboBox
                    model: ListModel {
                        ListElement { text: "SingleSelection"; value: TableView.SingleSelection }
                        ListElement { text: "ContiguousSelection"; value: TableView.ContiguousSelection }
                        ListElement { text: "ExtendedSelection"; value: TableView.ExtendedSelection }
                    }
                    textRole: "text"
                    currentIndex: 2
                },
                Text {
                    text: "EditTriggers"
                },
                ComboBox {
                    id: editTriggerComboBox
                    model: ListModel {
                        ListElement { text: "NoEditTriggers"; value: TableView.NoEditTriggers }
                        ListElement { text: "SingleTapped"; value: TableView.SingleTapped }
                        ListElement { text: "DoubleTapped"; value: TableView.DoubleTapped }
                        ListElement { text: "EditKeyPressed"; value: TableView.EditKeyPressed }
                        ListElement { text: "AnyKeyPressed"; value: TableView.AnyKeyPressed }
                    }
                    textRole: "text"
                    currentIndex: 2
                }
            ]
        }
    }
}
