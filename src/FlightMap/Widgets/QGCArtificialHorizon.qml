/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/**
 * @file
 *   @brief QGC Artificial Horizon
 *   @author Gus Grubba <gus@auterion.com>
 */

import QtQuick 2.3
import QtGraphicalEffects 1.0

Item {
    id: root
    property real rollAngle :   0
    property real pitchAngle:   0
    clip:           true
    anchors.fill:   parent

    property real angularScale: pitchAngle * root.height / 45

    Item {
        id: artificialHorizon
        width:  root.width  * 4
        height: root.height * 8
        anchors.centerIn: parent
        Rectangle {
            id: sky
            anchors.fill: parent
            smooth: true
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.45; color: "#3180ff"}
                GradientStop { position: 0.5;  color: "#8cb8ff"}
            }
        }
        Rectangle {
            id: ground
            height: sky.height / 2
            anchors {
                left:   sky.left;
                right:  sky.right;
                bottom: sky.bottom
            }
            smooth: true
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0;  color: "#5dc42f" }
                GradientStop { position: 0.25; color: "#2a6901" }
            }
        }
        Image {
            id:                 laneMarkers
            source:             "/qmlimages/attitudeLaneMarkers.svg"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.fill:       parent
            sourceSize.height:  parent.height
        }
        OpacityMask {                                       // Doesn't seem to work, for some reason. Leaving it here for future attempts. - Vessesh
            anchors.fill: laneMarkers
            source: laneMarkers
            maskSource: mask
        }

        transform: [
            Translate {
                y:  angularScale
            },
            Rotation {
                origin.x: artificialHorizon.width  / 2
                origin.y: artificialHorizon.height / 2
                angle:    -rollAngle
            }]
    }
    Rectangle {
        id:             mask
        anchors.fill: parent
        anchors.margins: width * 0.1
        radius:         width / 2
        color:          "transparent"
        visible:        false
    }
}
