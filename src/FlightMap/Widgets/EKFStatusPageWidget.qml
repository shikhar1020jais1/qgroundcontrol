import QtQuick                      2.11
import QtQuick.Controls             2.4
import QtQuick.Dialogs              1.3
import QtQuick.Layouts              1.11

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controllers   1.0

Rectangle {

    id:                                         ekfStatus
    height:                                     pageHeight
    width:                                      pageWidth
    color:                                      "transparent"

    property real   pageWidth:                  0
    property real   pageHeight:                 0
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property bool   _available:                 !isNaN(_activeVehicle.ekfStatus.velocityVariance.rawValue)
    property real   _margins:                   ScreenTools.defaultFontPixelWidth / 2
    property real   _barWidth:                  pageHeight * 0.1 //ScreenTools.defaultFontPixelWidth * 3
    property real   _barHeight:                 pageHeight * 0.8 //ScreenTools.defaultFontPixelHeight * 10


    property bool   _goodEKFAttitude:             _activeVehicle.ekfStatus.goodEKFAttitude.rawValue
    property bool   _goodEKFHorizVel:             _activeVehicle.ekfStatus.goodEKFHorizVel .rawValue
    property bool   _goodEKFVertVel:              _activeVehicle.ekfStatus.goodEKFVertVel.rawValue
    property bool   _goodEKFhorizPosRel:          _activeVehicle.ekfStatus.goodEKFhorizPosRel.rawValue
    property bool   _goodEKFVertPosAbs:           _activeVehicle.ekfStatus.goodEKFhorizPosAbs.rawValue
    property bool   _goodEKFVertPosAgl:           _activeVehicle.ekfStatus.goodEKFVertPosAbs.rawValue
    property bool   _goodEKFhorizPosAbs:          _activeVehicle.ekfStatus.goodEKFVertPosAgl.rawValue
    property bool   _goodEKFConstPoseMode:        _activeVehicle.ekfStatus.goodEKFConstPoseMode.rawValue
    property bool   _goodEKFPredPosHorizRel:      _activeVehicle.ekfStatus.goodEKFPredPosHorizRel.rawValue
    property bool   _goodEKFPredPosHorizAbs:      _activeVehicle.ekfStatus.goodEKFPredPosHorizAbs.rawValue
    property real   _velVariance:                 _activeVehicle.ekfStatus.velocityVariance.rawValue
    property real   _posHorizVariance:            _activeVehicle.ekfStatus.posHorizVariance.rawValue
    property real   _posVertVariance:             _activeVehicle.ekfStatus.posVertVariance.rawValue
    property real   _compassVariance:             _activeVehicle.ekfStatus.compassVariance.rawValue
    property real   _terrainVariance:             _activeVehicle.ekfStatus.terrainVariance.rawValue
    property real   _airspeedVariance:            _activeVehicle.ekfStatus.airspeedVariance.rawValue

    readonly property real _barMinimum:     0.0
    readonly property real _barMaximum:     90.0
    readonly property real _barLevel1:      50.0
    readonly property real _barLevel2:      80.0
    readonly property real _fontSize:       pageHeight * 0.055
    readonly property real _scale:          20

    QGCPalette { id:qgcPal; colorGroupEnabled: true }


    Item {
        id:                            ekfitem
        width:                          pageWidth
        height:                         pageHeight
        anchors.horizontalCenter:       parent.horizontalCenter
        anchors.verticalCenter:         parent.verticalCenter

        QGCFlickable{
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            anchors.top: parent.top
            anchors.left: parent.left
            contentWidth: parent.width * 2
            clip: true

        RowLayout {

            id:                         barRow
            spacing:                    ScreenTools.defaultFontPixelWidth
            anchors.verticalCenter:     parent.verticalCenter
            anchors.margins:            ScreenTools.defaultFontPixelWidth


            ColumnLayout {
                Rectangle {
                    height:                 _barHeight
                    width:                  _barWidth
                    Layout.alignment:       Qt.AlignHCenter
                    color:                  qgcPal.window
                }


            }

            Column {

                Rectangle {
                    id:                 velVarBar
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _velVariance) / (_barMaximum - _barMinimum)) * _scale
                        color:          qgcPal.text
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Velocity")
                    font.pointSize:      _fontSize

                }

            }

            Column {

                Rectangle {
                    id:                 posHorizVarBar
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _posHorizVariance) / (_barMaximum - _barMinimum)) * _scale
                        color:          qgcPal.text
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Pos-H")
                    font.pointSize:      _fontSize
                }

            }

            Column {

                Rectangle {
                    id:                 posVertVarBar
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _posVertVariance) / (_barMaximum - _barMinimum)) * _scale
                        color:          qgcPal.text
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Pos-V")
                    font.pointSize:      _fontSize
                }

            }

            Column {

                Rectangle {
                    id:                 compVarBar
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _compassVariance) / (_barMaximum - _barMinimum)) * _scale
                        color:          qgcPal.text
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Compass")
                    font.pointSize:      _fontSize
                }

            }

            Column {

                Rectangle {
                    id:                 terrVarBar
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _terrainVariance) / (_barMaximum - _barMinimum)) * _scale
                        color:          qgcPal.text
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Terrain")
                    font.pointSize:      _fontSize
                }

            }

            Column {

                Rectangle {
                    id:                 airspeedVarBar
                    height:             _barHeight
                    width:              _barWidth
                    Layout.alignment:   Qt.AlignHCenter
                    border.width:       1
                    border.color:       qgcPal.text

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         parent.height * (Math.min(_barMaximum, _airspeedVariance) / (_barMaximum - _barMinimum)) * _scale
                        color:          qgcPal.text
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Air Speed")
                    font.pointSize:      _fontSize
                }

            }

        }

         Grid {
            id: columnlayout1
             padding:                    ScreenTools.defaultFontPixelWidth
             anchors.left: barRow.right
             columns: 2
             columnSpacing:  ScreenTools.defaultFontPixelWidth
//             anchors.right:              parent.right
             //anchors.verticalCenter:     parent.verticalCenter

             QGCLabel {
                 text: qsTr("Flags")
                 font.pointSize:     _fontSize*1.2
                 font.bold:          true

             }
             Item{
             height: 10
             width: 10
             }


             QGCLabel {
                 text: qsTr("attitude: ") + (_goodEKFAttitude ? "on" : "off")
                 color: _goodEKFAttitude ? qgcPal.text : "red"
                 font.pointSize:     _fontSize*1.2
             }

             QGCLabel {
                 text: qsTr("velocity_horiz: ") + (_goodEKFHorizVel ? "on" : "off")
                 color: _goodEKFHorizVel ? qgcPal.text : "red"
                 font.pointSize:      _fontSize*1.2
             }

             QGCLabel {
                 text: qsTr("velocity_vert: ") + (_goodEKFVertVel ? "on" : "off")
                 color: _goodEKFVertVel ? qgcPal.text : "red"
                 font.pointSize:      _fontSize*1.2
             }

             QGCLabel {
                 text: qsTr("pos_horiz_rel: ") + (_goodEKFhorizPosRel ? "on" : "off")
                 color: _goodEKFhorizPosRel ? qgcPal.text : "red"
                 font.pointSize:      _fontSize*1.2
             }

             QGCLabel {
                 text: qsTr("pos_horiz_abs: ") + (_goodEKFhorizPosAbs ? "on" : "off")
                 color: _goodEKFhorizPosAbs ? qgcPal.text : "red"
                 font.pointSize:      _fontSize*1.2
             }
             QGCLabel {
                 text: qsTr("pos_vert_abs: ") + (_goodEKFVertPosAbs ? "on" : "off")
                 color: _goodEKFVertPosAbs ? qgcPal.text : "red"
                 font.pointSize:      _fontSize*1.2
             }

             QGCLabel {
                 text: qsTr("pos_vert_agl: ") + (_goodEKFVertPosAgl ? "on" : "off")
                 color: _goodEKFVertPosAgl ? qgcPal.text : "red"
                 font.pointSize:      _fontSize*1.2
             }

             QGCLabel {
                 text: qsTr("const_pose_mode: ") + (_goodEKFConstPoseMod ? "on" : "off")
                 color: _goodEKFConstPoseMode ? qgcPal.text : "red"
                 font.pointSize:      _fontSize*1.2
             }

             QGCLabel {
                 text: qsTr("pred_pos_horiz_rel: ") + (_goodEKFPredPosHorizRel ? "on" : "off")
                 color: _goodEKFPredPosHorizRel ? qgcPal.text : "red"
                 font.pointSize:      _fontSize*1.2
             }

             QGCLabel {
                 text: qsTr("pred_pos_horiz_abs: ") + (_goodEKFPredPosHorizAbs ? "on" : "off")
                 color: _goodEKFPredPosHorizAbs ? qgcPal.text : "red"
                 font.pointSize:      _fontSize*1.2
             }

         }





        // Max vibe indication line at 50
        Rectangle {
            anchors.topMargin:      velVarBar.height * (1.0 - ((_barLevel1 - _barMinimum) / (_barMaximum - _barMinimum)))
            anchors.top:            barRow.top
            anchors.left:           barRow.left
            anchors.right:          barRow.right
            width:                  barRow.width
            height:                 1
            color:                  "red"
        }

        // Max vibe indication line at 80
        Rectangle {
            anchors.topMargin:      velVarBar.height * (1.0 - ((_barLevel2 - _barMinimum) / (_barMaximum - _barMinimum)))
            anchors.top:            barRow.top
            anchors.left:           barRow.left
            anchors.right:          barRow.right
            width:                  barRow.width
            height:                 1
            color:                  "red"
        }

        Rectangle {
            anchors.fill:   parent
            color:          qgcPal.window
            opacity:        0.75
            radius:         5
            visible:        !_available

            QGCLabel {
                anchors.fill:           parent
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
                text:                   qsTr("Not Available")
            }
        }




    }
}
}
