/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQml.Models 2.12

import QGroundControl           1.0
import QGroundControl.Controls  1.0
import QGroundControl.ScreenTools   1.0
import QtQuick.Layouts  1.2

ToolStripActionList {
    id: _root

    //signal displayPreFlightChecklist		// vyorius

    model: [
        ToolStripAction {
            text:         _activeVehicle.armed ?  qsTr("Disarm") : qsTr("Arm")
            iconSource:   _activeVehicle.armed ? "/qmlimages/disarm.svg" : "/qmlimages/arm.svg"
            enabled:      true
            visible:      _activeVehicle && QGroundControl.settingsManager.adminSettings.showArm.value
            onTriggered:  _activeVehicle.armed ?  mainWindow.disarmVehicleRequest() : mainWindow.armVehicleRequest()

            property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
        },

        PreFlightCheckListShowAction { },	// vyorius
        GuidedActionTakeoff { },
        GuidedActionLand { },
        GuidedActionRTL { },
        GuidedActionPause { },
        GuidedActionActionList { }
//        ,
//        ToolStripAction {
//            text:               qsTr("AIS")
//            iconSource:         "/qmlimages/shipIcon.svg"
//            enabled:      true
//            visible:      QGroundControl.settingsManager.adminSettings.showAIS.value
//            onTriggered:  aisDropPanel.open()
//        },
//        ToolStripAction{
//            text:       QGroundControl.settingsManager.adminSettings.autoUTM.value ?
//                ( QGroundControl.settingsManager.adminSettings.enableUTM.value ? qsTr("UTM Enabled") : qsTr("UTM Disabled") ) : qsTr("Update UTM")
//            iconSource:         "qrc:/qmlimages/utm.svg"
//            enabled:      true
//            visible:      QGroundControl.settingsManager.adminSettings.showUTM.value
//            onTriggered: {
//                if(QGroundControl.settingsManager.adminSettings.autoUTM.value)
//                    QGroundControl.settingsManager.adminSettings.enableUTM.value = !QGroundControl.settingsManager.adminSettings.enableUTM.value
//                else {
//                    clearUTMpolygons()
//                    requestUTM()
//                }
//            }
//        },
//        ToolStripAction{
//            text:  enable3DMap ?  qsTr("2D Map") : qsTr("3D Map")
//            iconSource:  enable3DMap ? "/qmlimages/2D.png" : "/qmlimages/3D.png"
//            onTriggered: enable3DMap = !enable3DMap
//        },
//        ToolStripAction {
//            text:               qsTr("Setting")
//            iconSource:  "qrc:/qmlimages/Gears.svg"
//            enabled:  enable3DMap
//            visible: enable3DMap
//            dropPanelComponent: ColumnLayout {
//                spacing:    ScreenTools.defaultFontPixelWidth * 0.5
//                QGCLabel { text: qsTr("3D Setting ::") }

//                QGCButton {
//                    text:  qsTr("Reset North")
//                    Layout.fillWidth:   true
//                    onClicked:resetNorth()
//                }
//                QGCButton {
//                    text:   followVehicleIn3DMap ? qsTr("Unfollow Vehicle") : qsTr("Follow Vehicle")
//                    Layout.fillWidth:   true
//                    enabled:_activeVehicle!=null
//                    onEnabledChanged:{
//                        if(!enabled)followVehicleIn3DMap = false;
//                    }
//                    onClicked:{
//                         followVehicleIn3DMap = !followVehicleIn3DMap
//                    }
//                }
//                QGCButton {
//                    text:   showFence ? qsTr("Hide fence wall") : qsTr("Show fence wall")
//                    Layout.fillWidth:   true
//                    onClicked:{
//                         showFence = !showFence
//                    }
//                }
//            }
//        }
    ]
}
