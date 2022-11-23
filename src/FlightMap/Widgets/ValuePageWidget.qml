

/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/
import QtQuick 2.12
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.5
import QtQml 2.12

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Controllers   1.0			// vyorius
import QGroundControl.ScreenTools   1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.Palette       1.0
import QGroundControl.Vehicle       1.0


Rectangle
{
    id: _root

    color: "transparent"

    property real pageWidth: 0
    property real pageHeight: 0

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle

    property string searchValue: ""

    TelemetryValuesBar {
        id: telem
        anchors.fill: parent
    }

    function showSettings() {
        mainWindow.showComponentDialog(propertyPicker,
                                       qsTr("Value Widget Setup"),
                                       mainWindow.showDialogDefaultWidth,
                                       StandardButton.Ok)
    }

    Component {
        id: propertyPicker

        QGCViewDialog {

            QGCFlickable {

                anchors.fill: parent
                contentHeight: columnLayout.height
                flickableDirection: Flickable.VerticalFlick
                clip: true

                Column {
                    id: columnLayout
                    spacing: 5

                    RowLayout {
                        height: ScreenTools.defaultFontPixelHeight * 5

                        QGCButton {
                            text: mainWindow._flyViewEditingLayer ? qsTr("Save") : qsTr("Edit")
                            onClicked:{
                                mainWindow._flyViewEditingLayer = !mainWindow._flyViewEditingLayer
                            }
                            switchable: true
                            switchedOn: mainWindow._flyViewEditingLayer
                        }

                        QGCButton {
                            text: "Reset All Edits"
                            onClicked: {
                                QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelHeight.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelWidth.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelX.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelY.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.confirmDialogX.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.confirmDialogY.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.toolX.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.toolY.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.compassX.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.compassY.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.compassScale.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.attitudeX.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.attitudeY.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.attitudeScale.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.valuesX.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.valuesY.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.valuesWidth.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.valuesHeight.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.weatherX.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.weatherY.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.weatherWidth.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.weatherHeight.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.multiX.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.multiY.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.multiWidth.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.multiHeight.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.videoX.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.videoY.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.multiIconScale.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.weatherIconScale.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.weatherIconScale.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.weatherIconScale.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.toolHeight.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.toolWidth.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.confirmDialogWidth.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.confirmDialogHeight.value = -1
                                console.log("reset")
                                rect.recalcWidthHeight()
                                multiVehicleList.recalcWidthHeight()
                                QGroundControl.settingsManager.flyViewEditSettings.videoX.value = -1
                                QGroundControl.settingsManager.flyViewEditSettings.videoY.value = -1

                            }
                        }
                        QGCCheckBox {
                            id:     splitHUDCheck
                            text:   qsTr("Split HUD")
                            Component.onCompleted: {
                                checked = QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value
                            }
                            onClicked: QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value = checked
                        }
                    }

                    RowLayout {

                        height: ScreenTools.defaultFontPixelHeight * 2

                        Timer {
                            id:         clearTimer
                            interval:   100;
                            running:    false;
                            repeat:     false
                            onTriggered: {
                                searchValue.text = ""

                            }
                        }

                        QGCLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Search:")
                        }

                        QGCTextField {
                            id:                 searchText
                            text:               searchValue
                            onDisplayTextChanged: searchValue = displayText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        QGCButton {
                            text: qsTr("Clear")
                            onClicked: {
                                if(ScreenTools.isMobile) {
                                    Qt.inputMethod.hide();
                                }
                                clearTimer.start()
                            }
                            anchors.verticalCenter: parent.verticalCenter
                        }

//                        QGCCheckBox {
//                            text:                   qsTr("Show modified only")
//                            anchors.verticalCenter: parent.verticalCenter
//                            checked:                controller.showModifiedOnly
//                            onClicked:              controller.showModifiedOnly = checked
//                            visible:                QGroundControl.multiVehicleManager.activeVehicle.px4Firmware
//                        }
                    }

                    RowLayout {
                        height: ScreenTools.defaultFontPixelHeight * 2
                        QGCLabel {
                            text: "Number of rows: "
                        }
                        SpinBox {
                            id: rowCount
                            value: QGroundControl.settingsManager.flyViewEditSettings.valuePageRows.value
                            editable: false
                            from: 1

                            onValueModified: telem.changeSpinNumber(value)

                            contentItem: QGCLabel { text: "    " + rowCount.value + "    "}
                            up.indicator: QGCButton {
                                x: rowCount.mirrored ? 0: parent.width - width
                                text: "+"
                                onClicked: { rowCount.increase() ; QGroundControl.settingsManager.flyViewEditSettings.valuePageRows.value = rowCount.value  }
                            }
                            down.indicator: QGCButton {
                                x: rowCount.mirrored ? parent.width - width : 0
                                text: "-"
                                onClicked: { rowCount.decrease() ; QGroundControl.settingsManager.flyViewEditSettings.valuePageRows.value  = rowCount.value  }
                            }
                            background: Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                            }
                        }
                    }

                    SectionHeader {
                        id: selectedHeader
                        anchors.left: parent.left
                        anchors.right: parent.right
                        text: qsTr("Selected Values")
                        checked: true
                    }

                    Column {
                        spacing: _margins
                        visible: selectedHeader.checked

                        Repeater {
                            id:     selectedRepeater
                            model: telem.listItems() ? telem.listItems() : 0

                            RowLayout {
                                spacing: _margins

                                QGCLabel {
                                    id: _addCheckBox
                                    text: object.text
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 20
                                }
                                QGCButton {
                                    id: editButton
                                    QGCColoredImage {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.verticalCenter: parent.verticalCenter
                                        width:                  ScreenTools.defaultFontPixelHeight
                                        height:                 width
                                        sourceSize.width:       width
                                        fillMode:               Image.PreserveAspectFit
                                        source: "qrc:/InstrumentValueIcons/edit-pencil.svg"
                                        color: qgcPal.text
                                    }

                                    onClicked: {
                                        valueEditDialog.createObject(mainWindow, { instrumentValueData: telem.returnFact(object.factGroupName, object.factName) }).open()
                                    }
                                }
                                QGCButton {
                                    id: upButton
                                    enabled: index !== 0
                                    QGCColoredImage {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.verticalCenter: parent.verticalCenter
                                        width:                  ScreenTools.defaultFontPixelHeight
                                        height:                 width
                                        sourceSize.width:       width
                                        fillMode:               Image.PreserveAspectFit
                                        source: "qrc:/InstrumentValueIcons/cheveron-outline-up.svg"
                                        color: qgcPal.text
                                    }
                                    onClicked: {
                                        telem.moveItemUp(index)
                                    }
                                }
                                QGCButton {
                                    id: downButton
                                    enabled:index !== (selectedRepeater.count-1)
                                    QGCColoredImage {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.verticalCenter: parent.verticalCenter
                                        width:                  ScreenTools.defaultFontPixelHeight
                                        height:                 width
                                        sourceSize.width:       width
                                        fillMode:               Image.PreserveAspectFit
                                        source: "qrc:/InstrumentValueIcons/cheveron-outline-down.svg"
                                        color: qgcPal.text
                                    }
                                    onClicked: {
                                        telem.moveItemDown(index)
                                    }
                                }
                            }
                        }

                    }

                    Loader {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        sourceComponent: factGroupList

                        property var factGroup: _activeVehicle
                        property string factGroupName: "Vehicle"
                    }

                    Repeater {
                        model: _activeVehicle.factGroupNames

                        Loader {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            sourceComponent: factGroupList

                            property var factGroup: _activeVehicle.getFactGroup(modelData)
                            property string factGroupName: modelData
                            property bool headerVisible: false

                        }
                    }
                }
            }
        }
    }

    Component {
        id: factGroupList

        // You must push in the following properties from the Loader
        // property var factGroup
        // property string factGroupName
        Column {
            spacing: _margins

            SectionHeader {
                id: header
                anchors.left: parent.left
                anchors.right: parent.right
                text: factGroupName.charAt(0).toUpperCase(
                          ) + factGroupName.slice(1)
                checked:    headerVisible
            }

            Column {
                spacing: _margins
                visible: header.checked

                Repeater {
                    model: factGroup ? factGroup.factNames : 0

                    RowLayout {
                        spacing: _margins
                        visible: checkVisibilty()

                        property string propertyName: factGroupName + "." + modelData

                        function checkVisibilty()
                        {
                            var name = factGroup.getFact(modelData).shortDescription
                            console.log(name)

                            if(searchValue === "")
                            {
                                if(name !== "")
                                {
                                    return true
                                }

                            } else {

                                if(QGroundControl.multiVehicleManager.activeVehicle.searchSubStrings(searchValue, name))
                                {
                                    headerVisible = true
                                    return true
                                } else {
                                    return false
                                }

                            }

                        }

                        function updateValues() {
                            if (_addCheckBox.checked) {
                                telem.addFact(factGroupName, modelData)
                            } else {
                                telem.removeFact(factGroupName, modelData)
                            }
                        }

                        QGCCheckBox {
                            id: _addCheckBox
                            text: factGroup.getFact(modelData).shortDescription
                            checked:  telem.listContains(factGroupName, modelData)
                            onClicked: updateValues()
                            Layout.fillWidth: true
                            Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 20

                            Component.onCompleted: {
                                if (checked) {
                                    header.checked = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: valueEditDialog

        InstrumentValueEditDialog { }
    }
}
