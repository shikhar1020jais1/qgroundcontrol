/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.12
import QtQuick.Layouts  1.12

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Controllers   1.0			// vyorius
import QGroundControl.ScreenTools   1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.Palette       1.0

ColumnLayout {
    id:         root
    spacing:    0

    QGCPalette { id: qgcPal }

    Rectangle {
        id:                 visualInstrument
        radius:             _outerRadius
        color:              qgcPal.window
        opacity:            0.8
        Layout.fillWidth:   true
        Layout.fillHeight:  true

        TerrainProgress {
            id:         terrainProgress
            width:      tabView.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
        }

        property real   _innerRadius:           _outerRadius - _topBottomMargin
        property real   _outerRadius:           visualInstrument.height * 0.5
        property real   _spacing:               ScreenTools.defaultFontPixelHeight * 0.33
        property real   _topBottomMargin:       (width * 0.01)

        QGCAttitudeWidget {
            id:                     attitude
            anchors.leftMargin:     parent._topBottomMargin
            anchors.left:           parent.left
            size:                   parent._innerRadius * 2
            vehicle:                globals.activeVehicle
            anchors.verticalCenter: parent.verticalCenter
        }

        ColumnLayout {		// vyorius /*
            id: tabView
            anchors.left: attitude.right
            anchors.top: attitude.top
            anchors.right: compass.left
            anchors.bottom: attitude.bottom
            spacing: 0

            QGCTabBar {
                id: tabBar
                Layout.fillWidth: true
                spacing:3

                QGCTabButton {
                    text: "Values"
                    implicitHeight: ScreenTools.defaultFontPixelHeight * 1.5
                    _bdrWidth: 1
                    _bdrColor: qgcPal.text
                }
                QGCTabButton {
                    text: "Camera"
                    implicitHeight: ScreenTools.defaultFontPixelHeight * 1.5
                    _bdrWidth: 1
                    _bdrColor: qgcPal.text
                }
                QGCTabButton {
                    text: "Video"
                    implicitHeight: ScreenTools.defaultFontPixelHeight * 1.5
                    _bdrWidth: 1
                    _bdrColor: qgcPal.text
                    enabled: QGroundControl.videoManager(0).videoReceiver
                }
                QGCTabButton {
                    text: "Health"
                    implicitHeight: ScreenTools.defaultFontPixelHeight * 1.5
                    _bdrWidth: 1
                    _bdrColor: qgcPal.text
                }
                QGCTabButton {
                    text: "Vibration"
                    implicitHeight: ScreenTools.defaultFontPixelHeight * 1.5
                    _bdrWidth: 1
                    _bdrColor: qgcPal.text
                }
                QGCTabButton {
                    text: "EKF"
                    implicitHeight: ScreenTools.defaultFontPixelHeight * 1.5
                    _bdrWidth: 1
                    _bdrColor: qgcPal.text
                }
                QGCTabButton {

                    implicitHeight: ScreenTools.defaultFontPixelHeight * 1.5
                    width: implicitHeight * 2

                    _bdrWidth: 1
                    _bdrColor: qgcPal.text

                    onClicked: {
                        tabBar.currentIndex = 0
                        valuePageWidget.showSettings()
                    }

                    QGCColoredImage {
                        anchors.margins: _margins
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        source: "/res/gear-black.svg"
                        mipmap: true
                        height: parent.height * 0.6
                        width: height
                        sourceSize.height: height
                        color: qgcPal.text
                        fillMode: Image.PreserveAspectFit
                    }
                }
            }

            StackLayout {
                id:  stack
                Layout.fillHeight: true
                Layout.fillWidth: true
                currentIndex: tabBar.currentIndex

                ValuePageWidget{
                    id: valuePageWidget
                    pageWidth: stack.width
                    pageHeight: stack.height
                }

                CameraPageWidget{

                }

                VideoPageWidget{

                }

                HealthPageWidget{
                    pageWidth: stack.width
                    pageHeight: stack.height

                }

                VibrationPageWidget{
                    pageWidth:  stack.width
                    pageHeight: stack.height
                }

                EKFStatusPageWidget {
                    pageWidth:  stack.width
                    pageHeight: stack.height
                }
            }
        }

        QGCCompassWidget {
            id:                     compass
            anchors.rightMargin:    parent._topBottomMargin
            anchors.right:          parent.right		// vyorius /*
            size:                   parent._innerRadius * 2
            vehicle:                globals.activeVehicle
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
