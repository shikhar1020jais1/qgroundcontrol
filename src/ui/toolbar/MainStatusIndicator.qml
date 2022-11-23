/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0

RowLayout {
    id:         _root
    spacing:    0

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property var vehicleData
    property var    _vehicleInAir:      _activeVehicle ? _activeVehicle.flying || _activeVehicle.landing : false
    property bool   _vtolInFWDFlight:   _activeVehicle ? _activeVehicle.vtolInFwdFlight : false
    property bool   _armed:             _activeVehicle ? _activeVehicle.armed : false
    property real   _margins:           ScreenTools.defaultFontPixelWidth
    property real   _spacing:           ScreenTools.defaultFontPixelWidth / 2
    property string vName: "Test Drone"
    property int _maxFMCharLength:  10   ///< Maximum number of chars in a flight mode
    property string flightMode:     _activeVehicle ? _activeVehicle.flightMode : qsTr("N/A", "No data to display")

    Item {
        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
        height:                 1
    }

    QGCComboBox {
        id:                     armedMenu
        alternateText:          _armed ? qsTr("Armed") : qsTr("Disarmed")
        model:                  [ qsTr("Arm"), qsTr("Disarm"), qsTr("Force Arm") ]
        currentIndex:           -1
        sizeToContents:         true
        height: parent.height * 0.7
        visible:                _activeVehicle
        font.pointSize:         ScreenTools.mediumFontPointSize

        property bool showIndicator: true

        property bool   _armed:         _activeVehicle ? _activeVehicle.armed : false

        onActivated: {
            if (index == 0) {
                mainWindow.armVehicleRequest()
            } else if(index == 1) {
                mainWindow.disarmVehicleRequest()
            } else {
                mainWindow.forceArmVehicleRequest()
            }
            currentIndex = -1
        }
    }

    Item {
        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 1.5
        height:                 1
        visible:                flightModeCombo.visible
    }

//    QGCComboBox {
//        id:         flightModeCombo
//        //Layout.preferredWidth:      ScreenTools.defaultFontPixelWidth * 10 // (_maxFMCharLength + 4) * ScreenTools.defaultFontPixelWidth

//        sizeToContents:         true
//        model:      _activeVehicle ? _activeVehicle.flightModes : 0
//        visible:    _activeVehicle
//        font.pointSize:         ScreenTools.mediumFontPointSize


//        onModelChanged: {
//            if (_activeVehicle && visible) {
//                currentIndex = find(flightMode)
//            }
//        }

//        onActivated: _activeVehicle.flightMode = textAt(index)

//        Connections {
//            target: _activeVehicle
//            onFlightModeChanged: {
//                flightModeCombo.currentIndex = flightModeCombo.find(flightMode)
//            }
//        }
//    }

    // New definition for Combo box

    QGCComboBox {
        id:                     flightModeCombo
        anchors.verticalCenter: parent.verticalCenter
        alternateText:          _activeVehicle ? _activeVehicle.flightMode : ""
        model:                  _flightModes
        font.pointSize:         ScreenTools.mediumFontPointSize
        //currentIndex:           -1
         width :                80
        sizeToContents:         true
        visible:                _activeVehicle

        //height : parent.height * 0.7
        property bool showIndicator: true

        property var _activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
        property var _flightModes:      _activeVehicle ? _activeVehicle.flightModes : [ ]

        onActivated: {
            _activeVehicle.flightMode = _flightModes[index]
            currentIndex = -1
        }
    }

    Item {
        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
        height:                 1
        visible:                vtolModeLabel.visible
    }

    QGCLabel {
        id:                     vtolModeLabel
        Layout.preferredHeight: _root.height
        verticalAlignment:      Text.AlignVCenter
        text:                   _vtolInFWDFlight ? qsTr("FW(vtol)") : qsTr("MR(vtol)")
        font.pointSize:         ScreenTools.largeFontPointSize
        visible:                _activeVehicle ? _activeVehicle.vtol && _vehicleInAir : false

        QGCMouseArea {
            anchors.fill:   parent
            onClicked:      mainWindow.showIndicatorPopup(vtolModeLabel, vtolTransitionComponent)
        }
    }

    Component {
        id: vtolTransitionComponent

        Rectangle {
            width:          mainLayout.width   + (_margins * 2)
            height:         mainLayout.height  + (_margins * 2)
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            color:          qgcPal.window
            border.color:   qgcPal.text

            QGCButton {
                id:                 mainLayout
                anchors.margins:    _margins
                anchors.top:        parent.top
                anchors.left:       parent.left
                text:               _vtolInFWDFlight ? qsTr("Transition to Multi-Rotor") : qsTr("Transition to Fixed Wing")

                onClicked: {
                    if (_vtolInFWDFlight) {
                        mainWindow.vtolTransitionToMRFlightRequest()
                    } else {
                        mainWindow.vtolTransitionToFwdFlightRequest()
                    }
                    mainWindow.hideIndicatorPopup()
                }
            }
        }
    }
    Item {
        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 1.5
        height:                 1
        visible:                flightModeCombo.visible
    }


}

