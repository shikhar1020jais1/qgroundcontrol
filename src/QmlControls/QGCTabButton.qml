/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.12
import QtQuick.Controls         2.12
import QtQuick.Controls.impl    2.12
import QtQuick.Templates        2.12 as T

import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0

T.TabButton {
    id: control

    property real  _bckgOpacity:  1
    property color   _bckgColor:    qgcPal.button
    property real  _bdrWidth:     0             //vyorius
    property color   _bdrColor:     qgcPal.text   //vyorius


    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    font.pointSize: ScreenTools.defaultFontPointSize
    font.family:    ScreenTools.normalFontFamily

    padding: 6
    spacing: 6

    //icon.width: 24
    icon.height: ScreenTools.defaultFontPixelHeight
    icon.color: checked || hovered ? qgcPal.buttonHighlightText : qgcPal.buttonText


    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon: control.icon
        text: control.text
        font: control.font
        color: checked || hovered ? qgcPal.buttonHighlightText : qgcPal.buttonText
    }

    background: Rectangle {
        implicitHeight: 40
        color: checked || hovered ? qgcPal.buttonHighlight : qgcPal.button
        radius: 10				// vyorius
        border.color: _bdrColor //vyorius
        border.width: _bdrWidth //vyorius
        /*color: Color.blend(control.checked ? control.palette.window : control.palette.dark,
                                             control.palette.mid, control.down ? 0.5 : 0.0)*/
    }
}
