

/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/
import QtQuick 2.11
import QtPositioning 5.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 2.4
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0

import QGroundControl 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Controls 1.0
import QGroundControl.Palette 1.0
import QGroundControl.Vehicle 1.0
import QGroundControl.Controllers 1.0
import QGroundControl.FactSystem 1.0
import QGroundControl.FactControls 1.0

/// Video streaming page for Instrument Panel PageView
Item {
    Layout.fillHeight: true
    Layout.fillWidth: true
    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var cloud_api: QGroundControl.vyoriusCloudApi
    property bool _communicationLost: activeVehicle ? activeVehicle.connectionLost : false
    property var _dynamicCameras: activeVehicle ? activeVehicle.cameraManager : null
    property int _curCameraIndex: _dynamicCameras ? _dynamicCameras.currentCamera : 0
    property bool _isCamera: _dynamicCameras ? _dynamicCameras.cameras.count > 0 : false
    property var _camera: _isCamera ? (_dynamicCameras.cameras.get(
                                           _curCameraIndex)
                                       && _dynamicCameras.cameras.get(
                                           _curCameraIndex).paramComplete ? _dynamicCameras.cameras.get(_curCameraIndex) : null) : null

    QGCPalette {
        id: qgcPal
        colorGroupEnabled: true
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: ScreenTools.defaultFontPixelHeight
        contentWidth: hLayout.width
        flickableDirection: Flickable.HorizontalFlick
        clip: true
        ScrollBar.horizontal: ScrollBar {}

        RowLayout {
            id: hLayout
            spacing:  ScreenTools.defaultFontPixelWidth
            Repeater {
                id: videoRepeater
                model: QGroundControl.settingsManager.appSettings.videoCount.value
                delegate:
                GridLayout {
                    id: videoGrid
                    columns: 4
                    columnSpacing: ScreenTools.defaultFontPixelWidth * 2
                    rowSpacing: ScreenTools.defaultFontPixelHeight * 0.2

                    QGCLabel {
                        id: videoNumLabel
                        text: qsTr("Video " + (index+1))
                        font.bold: true
                        Layout.columnSpan: 4
                        font.pointSize: ScreenTools.defaultFontPointSize
                        visible: QGroundControl.videoManager(index).isGStreamer
                                                                    && QGroundControl.settingsManager.videoSettings(index).gridLines.visible
                    }

                    // Grid Lines
                    QGCLabel {
                        id: gridLinesLabel
                        text: qsTr("Grid Lines")
                        font.pointSize: ScreenTools.smallFontPointSize
                        visible: QGroundControl.videoManager(index).isGStreamer
                                                                    && QGroundControl.settingsManager.videoSettings(index).gridLines.visible
                    }
                    QGCSwitch {
                        id: gridLinesSwitch
                        enabled: QGroundControl.settingsManager.videoSettings(index).streamConfigured && activeVehicle
                        checked: QGroundControl.settingsManager.videoSettings(index).gridLines.rawValue
                        visible: QGroundControl.videoManager(index).isGStreamer
                                 && QGroundControl.settingsManager.videoSettings(index).gridLines.visible
                        onClicked: {
                            if (checked) {
                                QGroundControl.settingsManager.videoSettings(index).gridLines.rawValue = 1
                            } else {
                                QGroundControl.settingsManager.videoSettings(index).gridLines.rawValue = 0
                            }
                        }
                    }
                    //-- Video Fit
                    QGCLabel {
                        id: videoScreenFitLabel
                        text: qsTr("Video Screen Fit")
                        visible: QGroundControl.videoManager(index).isGStreamer
                        font.pointSize: ScreenTools.smallFontPointSize
                    }
                    FactComboBox {
                        id: videoScreenFitComboBox
                        fact: QGroundControl.settingsManager.videoSettings(index).videoFit
                        visible: QGroundControl.videoManager(index).isGStreamer
                        indexModel: false
                    }
                    QGCLabel {
                        id: videoFileNameLabel
                        text: qsTr("File Name")

                        font.pointSize: ScreenTools.smallFontPointSize
                        visible: QGroundControl.videoManager(index).isGStreamer
                    }
                    Rectangle {
                        id: videoFileNameRect

                        Layout.fillWidth: true
                        visible: QGroundControl.videoManager(index).isGStreamer
                        height: 30
                        width: 120
                        radius: 5
                        border.color: "black"
                        TextField {
                            id: videoFileName
                            height: 30
                            width: 120
                            Layout.fillWidth: true
                            background: Item {}
                            validator: RegExpValidator { regExp: /[A-Za-z0-9_-]+/ }
                        }
                    }

                    //-- Video Recording
                    QGCLabel {
                        id: videoRecording
                        property int count: 0

                        function pad(num, size) {
                            var s = "0000" + num;
                            return s.substr(s.length-size);
                        }

                        text: QGroundControl.videoManager(index).recording ? pad( new Date(count).getUTCHours(), 2 ) + " : " + pad( new Date(count).getUTCMinutes(), 2 ) + " : "  + pad( new Date(count).getUTCSeconds(), 2 ) + " : "  + (new Date(count).getUTCMilliseconds()*0.01) : qsTr("Record Stream")
                        font.pointSize:  !QGroundControl.videoManager(index).recording ? ScreenTools.smallFontPointSize : ScreenTools.defaultFontPointSize
                        visible: QGroundControl.videoManager(index).isGStreamer
                    }

                    Timer {
                        id: recordingTimer
                        interval: 100
                        running: false
                        repeat: true
                        onTriggered: videoRecording.count += 100
                    }

                    // Button to start/stop video recording
                    Item {
                        height: ScreenTools.defaultFontPixelHeight * 2
                        width: height
                        visible: QGroundControl.videoManager(index).isGStreamer
                        Rectangle {
                            id: recordBtnBackground
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: height
                            radius: QGroundControl.videoManager(index).recording ? 0 : height
                            color: (QGroundControl.videoManager(index).decoding && QGroundControl.settingsManager.videoSettings(index).streamConfigured) ? "red" : "gray"
                            SequentialAnimation on opacity {
                                running: QGroundControl.videoManager(index).recording
                                loops: Animation.Infinite
                                PropertyAnimation {
                                    to: 0.5
                                    duration: 500
                                }
                                PropertyAnimation {
                                    to: 1.0
                                    duration: 500
                                }
                            }
                        }
                        QGCColoredImage {
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: height * 0.625
                            sourceSize.width: width
                            source: "/qmlimages/CameraIcon.svg"
                            visible: recordBtnBackground.visible
                            fillMode: Image.PreserveAspectFit
                            color: "white"
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: QGroundControl.videoManager(index).decoding && QGroundControl.settingsManager.videoSettings(index).streamConfigured
                            onClicked: {
                                if (QGroundControl.videoManager(index).recording) {
                                    QGroundControl.videoManager(index).stopRecording()
                                    // reset blinking animation
                                    recordBtnBackground.opacity = 1
                                    recordingTimer.stop()
                                    if(activeVehicle)
                                       activeVehicle.stopSimpleVideo()
                                } else {
                                    QGroundControl.videoManager(index).startRecording(
                                                videoFileName.text + (new Date().toLocaleString(Qt.locale(), "_yyyy-MM-dd_hh.mm.ss")))
                                    videoRecording.count = 0
                                    recordingTimer.start()
                                    if(activeVehicle)
                                      activeVehicle.startSimpleVideo()
                                }
                            }
                        }
                    }
                    QGCLabel {
                        text: qsTr("Video Streaming Not Configured")
                        font.pointSize: ScreenTools.smallFontPointSize
                        visible: !QGroundControl.settingsManager.videoSettings(index).streamConfigured
                        Layout.columnSpan: 2
                    }
                }
            }
        }
    }
}
