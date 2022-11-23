/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.12
import QtQuick.Controls         2.4
import QtQuick.Dialogs          1.3
import QtQuick.Layouts          1.12
import QtQuick.Shapes           1.12

import QtLocation               5.3
import QtPositioning            5.3
import QtQuick.Window           2.2
import QtQml.Models             2.1

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Airspace      1.0
import QGroundControl.Airmap        1.0
import QGroundControl.Controllers   1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

// This is the ui overlay layer for the widgets/tools for Fly View
Item {
    id: _root

    property var  cloud_api: QGroundControl.vyoriusCloudApi
    property var    parentToolInsets
    property var    totalToolInsets:        _totalToolInsets
    property var    mapControl

    // 3d related
    property bool  enable3DMap : false
    property bool  followVehicleIn3DMap : false
    signal resetNorth
    property bool showFence : true
    // 3d end

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:  globals.planMasterControllerFlyView
    property var    _missionController:     _planMasterController.missionController
    property var    _geoFenceController:    _planMasterController.geoFenceController
    property var    _rallyPointController:  _planMasterController.rallyPointController
    property var    _guidedController:      globals.guidedControllerFlyView
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 100		// vyorius
    property var    _videopipmargin: null                                                  // vyorius

    property bool showSingleVehiclePanel: !visible ||singleVehicleRadio.checked

    property var searchResults: []

    //UTM Properties
    property var responseData
    property var geoCollection: []
    property bool colapsed: true
    property bool utmVisible: false
    property int maxArrayLen: 5000
    property var mapObjects: []
    property MapPolygon thisPolygon
    property MapPolyline thisPolyline
    property MapCircle thisCircle

    ListModel {
        id: collapsedModel
    }

    ListModel {
        id: expandedModel
    }

    onResponseDataChanged: {
        for(var feature of responseData.features) {
            var isPresent = false
            switch(feature.geometry.type) {

            case 'Polygon':
                for (var polygon of mapObjects) {
                    if (polygon.polyId === feature.id){
                        isPresent = true
                    }
                }
                break
            case 'MultiPolygon':
                for (polygon of mapObjects) {
                    if (polygon.polysId === feature.id){
                        isPresent = true
                    }
                }

                break
            case 'LineString':
                for(var line of mapObjects) {
                    if (line.polyId === feature.id){
                        isPresent = true
                    }
                }
                break
            case 'MultiLineString':
                for(var mline of mapObjects) {
                    if (mline.linesId === feature.id){
                        isPresent = true
                    }
                }

                break
            case 'Point':
                for(var point of mapObjects){
                    if (point.polyId === feature.id){
                        isPresent = true
                    }
                }
                break
            case 'MultiPoint':
                for(var mpoint of mapObjects) {
                    if (mpoint.polyId === feature.id){
                        isPresent = true
                    }
                }
                break
            case 'GeometryCollection':
                for(var gId of geoCollection) {
                    if (gId === feature.id) {
                        isPresent = true
                    }
                }
            }

            if (!isPresent) {
                displayData(feature)
            }

        }
    }

    function getUTMData(coordinateNorth, coordinateEast, coordinateSouth, coordinateWest) {
        var http = new XMLHttpRequest()

        var baseURL = 'https://api.altitudeangel.com/v2/mapdata/geojson'
        var params = `isCompact=false&n=${coordinateNorth}&e=${coordinateEast}&s=${coordinateSouth}&w=${coordinateWest}`                        // coordinate of the bound box
        var apiKey = 'X-AA-ApiKey ' + QGroundControl.settingsManager.adminSettings.utmKey.value                                                    // set string 'X-AA-ApiKey' before apikey

        http.open('GET', baseURL + '?' + params)
        http.setRequestHeader('Authorization', apiKey)  // set apikey

        http.onreadystatechange = function() {
            if (http.readyState === XMLHttpRequest.DONE) {
                if (http.status == 200) {
                    //                        console.log('request successful!')
                    responseData = JSON.parse(http.responseText)

                } else {
                    console.log('Error code: ' + http.status)
                }
            }
        }
        http.send()
    }
    function requestUTM() {

        var north = mapControl.visibleRegion.boundingGeoRectangle().topRight.latitude //south
        var east = mapControl.visibleRegion.boundingGeoRectangle().topRight.longitude //west
        var south = mapControl.visibleRegion.boundingGeoRectangle().bottomLeft.latitude //north
        var west = mapControl.visibleRegion.boundingGeoRectangle().bottomLeft.longitude//east

        //----------------------------------------------
        getUTMData(north, east, south, west)  // retun GeoJson which is saved in responseData variable
    }

    function clearAllBorders(){
        for(var i = 0; i < mapObjects.length; i++){
            if(mapObjects[i].border)
                mapObjects[i].border.width = 1
        }
    }
    function clearUTMpolygons(){
        while(mapObjects.length > 0){
            var tmp = mapObjects.pop()
            tmp.destroy()
        }
    }

    Connections {
        target: QGroundControl.settingsManager.adminSettings.enableUTM
        function onValueChanged() {
            if(!QGroundControl.settingsManager.adminSettings.enableUTM.value)
                clearUTMpolygons()
        }
    }

    function displayData(feature) {
        switch(feature.geometry.type) {
            //----------------------------Polygon---------------------
        case 'Polygon':
            var temp = []
            for(var polygonCoordinates of feature.geometry.coordinates) {
                for(var value of polygonCoordinates) {
                    temp.push(QtPositioning.coordinate(value[1], value[0]))
                }
            }

            if(mapObjects.length > maxArrayLen){
                mapObjects[0].destroy()
                mapObjects.splice(0,1)
            }

            var polygonString = "import QtLocation 5.3; import QtQuick 2.15; import QGroundControl.ScreenTools  1.0;
            MapPolygon {
                property string polyId;
                property string polyTitle;
                property string polyText;
                property string polyColor;
                property var polySections: []

                property bool hovered: true

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onClicked: {
                        if(clearFlag){
                            collapsedModel.clear()
                            clearFlag = false
                            clearAllBorders()
                        }
                        parent.border.width = ScreenTools.defaultFontPixelWidth * 0.5
                        collapsedModel.append({
                            'collapsedId': polyId,
                            'collapsedTitle': polyTitle,
                            'collapsedText': polyText,
                            'collapsedColor': polyColor

                        })

                        displayUTMinfo()
                        mouse.accepted = false
                    }
                }
            }"
            thisPolygon = Qt.createQmlObject( polygonString, mapControl )
            thisPolygon.polyId = feature.id
            thisPolygon.path =  temp
            thisPolygon.color = feature.properties.fillColor.toString()
            thisPolygon.border.color = feature.properties.strokeColor
            thisPolygon.border.width = feature.properties.strokeWidth

            thisPolygon.polyColor = feature.properties.fillColor.toString()
            thisPolygon.opacity = feature.properties.fillOpacity
            thisPolygon.polyTitle = feature.properties.display.title
            thisPolygon.polyText = feature.properties.display.category + " : " + feature.properties.display.detailedCategory
            for(var section of feature.properties.display.sections)
                thisPolygon.polySections.push(section)

            mapControl.addMapItem(thisPolygon)

            mapObjects.push(thisPolygon)

            break

            //--------------------------MultiPolygon------------------------
        case 'MultiPolygon':
            //                        var mtemp = []
            for(var polyCoordinates of feature.geometry.coordinates){
                var mtemp = []
                for (var polyCoordinate of polyCoordinates) {
                    for(var mvalue of polyCoordinate) {
                        if(mtemp.length <= maxArrayLen)
                            mtemp.push(QtPositioning.coordinate(mvalue[1], mvalue[0]))
                    }
                }
                if(mapObjects.length > maxArrayLen){
                    mapObjects.splice(0,1)
                }

                polygonString = "import QtLocation 5.3; import QtQuick 2.15; import QGroundControl.ScreenTools  1.0;
                MapPolygon {
                    property string polyId;
                    property string polyTitle;
                    property string polyText;
                    property string polyColor;
                    property var polySections: []

                    property bool hovered: true

                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: true
                        onClicked: {
                            if(clearFlag){
                                collapsedModel.clear()
                                clearFlag = false
                                clearAllBorders()
                            }
                            parent.border.width = ScreenTools.defaultFontPixelWidth * 0.5
                            collapsedModel.append({
                                'collapsedId': polyId,
                                'collapsedTitle': polyTitle,
                                'collapsedText': polyText,
                                'collapsedColor': polyColor

                            })
                            displayUTMinfo()
                            mouse.accepted = false
                        }
                    }
                }"
                thisPolygon = Qt.createQmlObject( polygonString, mapControl )
                thisPolygon.polyId = feature.id
                thisPolygon.path =  mtemp
                thisPolygon.color = feature.properties.fillColor.toString()
                thisPolygon.border.color = feature.properties.strokeColor
                thisPolygon.border.width = feature.properties.strokeWidth
                thisPolygon.polyColor = feature.properties.fillColor.toString()
                thisPolygon.opacity = feature.properties.fillOpacity
                thisPolygon.polyTitle = feature.properties.display.title
                thisPolygon.polyText = feature.properties.display.category + " : " + feature.properties.display.detailedCategory
                for(section of feature.properties.display.sections)
                    thisPolygon.polySections.push(section)
                mapControl.addMapItem(thisPolygon)

                mapObjects.push(thisPolygon)
            }

            break

            //-------------------Linestring---------------------------------------
        case 'LineString':
            var ltemp = []
            for (var lineCoordinate of feature.geometry.coordinates) {
                if(ltemp.length <= maxArrayLen)
                    ltemp.push(QtPositioning.coordinate(lineCoordinate[1], lineCoordinate[0]))
            }
            if (mapObjects.length > maxArrayLen) {
                mapObjects.splice(0, 1)
            }

            polygonString = "import QtLocation 5.3; MapPolyline { property string polyId}"
            thisPolyline = Qt.createQmlObject(polygonString, mapControl)
            thisPolyline.polyId = feature.id
            thisPolyline.path = ltemp
            thisPolyline.line.color = feature.properties.fillColor.toString()
            thisPolyline.line.width = feature.properties.strokeWidth
            mapControl.addMapItem(thisPolyline)
            mapObjects.push(thisPolyline)

            break

            //--------------------multistring---------------------------------
        case 'MultiLineString':
            for (var multiLineCoordinates of feature.geometry.coordinates) {
                var mltemp = []
                for(var multiLineCoordinate of multiLineCoordinates) {
                    if(mltemp.length <= maxArrayLen)
                        mltemp.push(QtPositioning.coordinate(multiLineCoordinate[1], multiLineCoordinate[0]))
                }
                if(mapObjects.length > maxArrayLen){
                    mapObjects.splice(0,1)
                }
                polygonString = "import QtLocation 5.3; MapPolyline { property string linesId}"
                thisPolyline = Qt.createQmlObject(polygonString, mapControl)
                thisPolyline.linesId = feature.id
                thisPolyline.path = mltemp
                thisPolyline.line.color = feature.properties.fillColor.toString()
                thisPolyline.line.width = feature.properties.strokeWidth
                mapControl.addMapItem(thisPolyline)
                mapObjects.push(thisPolyline)
            }

            break

            //-----------------------Point-----------------------------------
        case 'Pont':
            var center = QtPositioning.coordinate(feature.geometry.coordinates[1], feature.geometry.coordinates[0])
            var radius = feature.properties.radius
            if(mapObjects.length > maxArrayLen){
                mapObjects.splice(0,1)
            }
            polygonString = "import QtLocation 5.3; import QtQuick 2.15; import QGroundControl.ScreenTools  1.0;
            MapCircle {
                property string polyId;
                property string polyTitle;
                property string polyText;
                property string polyColor;
                property var polySections: []

                property bool hovered: true

                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onClicked: {
                        if(clearFlag){
                            collapsedModel.clear()
                            clearFlag = false
                            clearAllBorders()
                        }
                        parent.border.width = ScreenTools.defaultFontPixelWidth * 0.5
                        collapsedModel.append({
                            'collapsedId': polyId,
                            'collapsedTitle': polyTitle,
                            'collapsedText': polyText,
                            'collapsedColor': polyColor

                        })

                        displayUTMinfo()
                        mouse.accepted = false
                    }
                }
            }"
            thisCircle = Qt.createQmlObject(polygonString, mapControl)
            thisCircle.polyId = feature.id
            thisCircle.center = center
            thisCircle.radius = radius
            thisCircle.color = feature.properties.fillColor
            thisCircle.opacity = feature.properties.fillOpacity
            thisCircle.border.color = feature.properties.strokeColor
            thisCircle.border.width = feature.properties.strokeWidth
            thisCircle.polyColor = feature.properties.fillColor.toString()
            thisCircle.polyTitle = feature.properties.display.title
            thisCircle.polyText = feature.properties.display.category + " : " + feature.properties.display.detailedCategory
            for(section of feature.properties.display.sections)
                thisPolygon.polySections.push(section)
            mapControl.addMapItem(thisCircle)
            mapObjects.push(thisCircle)

            break

            //-------------------------MultiPoint----------------------------
        case 'MultPoint':
            console.log('mutlipoint')
            for(var point of feature.geometry.coordinates) {
                var Center = QtPositioning.coordinate(point[1], point[0])
                var Radius = feature.properties.radius
                if(mapObjects.length > maxArrayLen){
                    mapObjects.splice(0,1)
                }
                polygonString = "import QtLocation 5.3; import QtQuick 2.15; import QGroundControl.ScreenTools  1.0;
                MapCircle {
                    property string polyId;
                    property string polyTitle;
                    property string polyText;
                    property string polyColor;
                    property var polySections: []

                    property bool hovered: true

                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: true
                        onClicked: {
                            if(clearFlag){
                                collapsedModel.clear()
                                clearFlag = false
                                clearAllBorders()
                            }
                            parent.border.width = ScreenTools.defaultFontPixelWidth * 0.5
                            collapsedModel.append({
                                'collapsedId': polyId,
                                'collapsedTitle': polyTitle,
                                'collapsedText': polyText,
                                'collapsedColor': polyColor

                            })

                            displayUTMinfo()
                            mouse.accepted = false
                        }
                    }
                }"
                thisCircle = Qt.createQmlObject(polygonString, mapControl)
                thisCircle.polyId = feature.id
                thisCircle.center = center
                thisCircle.radius = radius
                thisCircle.color = feature.properties.fillColor
                thisCircle.opacity = feature.properties.fillOpacity
                thisCircle.border.color = feature.properties.strokeColor
                thisCircle.border.width = feature.properties.strokeWidth
                thisCircle.polyColor = feature.properties.fillColor.toString()
                thisCircle.polyTitle = feature.properties.display.title
                thisCircle.polyText = feature.properties.display.category + " : " + feature.properties.display.detailedCategory
                for(section of feature.properties.display.sections)
                    thisPolygon.polySections.push(section)
                mapControl.addMapItem(thisCircle)
                mapObjects.push(thisCircle)

            }

            break

            //-----------------------------------------------------------------
        case 'GeometryCollction':
            for(var subGeometry of feature.geometry.geometries) {
                getUTMData(subGeometry)
                for(var feat of responseData.features) {
                    var isPresent = false
                    switch(feat.geometry.type) {

                    case 'Polygon':
                        for (var polygon of mapObjects) {
                            if (polygon.polyId === feat.id){
                                isPresent = true
                            }
                        }
                        break
                    case 'MultiPolygon':
                        for (polygon of mapObjects) {
                            if (polygon.polysId === feat.id){
                                isPresent = true
                            }
                        }

                        break
                    case 'LineString':
                        for(var line of mapObjects) {
                            if (line.polyId === feat.id){
                                isPresent = true
                            }
                        }
                        break
                    case 'MultiLineString':
                        for(var mline of mapObjects) {
                            if (mline.linesId === feat.id){
                                isPresent = true
                            }
                        }

                        break
                    case 'Point':
                        for(var pt of mapObjects){
                            if (pt.polyId === feat.id){
                                isPresent = true
                            }
                        }
                        break
                    case 'MultiPoint':
                        for(var mpoint of mapObjects) {
                            if (mpoint.polyId === feat.id){
                                isPresent = true
                            }
                        }
                        break
                    case 'GeometryCollection':
                        for(var gId of geoCollection) {
                            if (gId === feat.id) {
                                isPresent = true
                            }
                        }
                    }

                    if (!isPresent) {
                        displayData(feat)
                    }

                }
            }
            geoCollection.push(feature.id)
            break

        default:

        }// switch

    } //function defn

    function displayUTMinfo(){
        mainWindow.showComponentDialog(utmInfoComponent, "UTM Information", mainWindow.showDialogDefaultWidth)
    }

    function fillExpandedList(polyId){
        for(var i = 0; i < mapObjects.length; i++){
            if(mapObjects[i].polyId === polyId){
                expandedModel.clear()
                for(var j = 0; j < mapObjects[j].polySections.length; j++){
                    expandedModel.append({
                                             expandedTitle: mapObjects[i].polySections[j].title,
                                             expandedText: mapObjects[i].polySections[j].text
                                         })
                }
                clearAllBorders()
                mapObjects[i].border.width = ScreenTools.defaultFontPixelWidth * 0.5
            }
        }
    }

    Timer {
        repeat: true
        interval: QGroundControl.settingsManager.adminSettings.utmUpdateTimer.value * 1000
        running: QGroundControl.settingsManager.adminSettings.enableUTM.value && QGroundControl.settingsManager.adminSettings.autoUTM.value
        triggeredOnStart: true
        onTriggered: requestUTM()
    }


    Component {
        id: utmInfoComponent
        Rectangle {
            anchors.fill: parent
            color: "transparent"

            ListView {
                id: collapsedList
                anchors.fill: parent
                anchors.margins: ScreenTools.defaultFontPixelWidth
                visible: true
                clip: true
                spacing: ScreenTools.defaultFontPixelWidth
                model: collapsedModel
                delegate:
                    Rectangle{
                    width: collapsedList.width
                    height: gl.implicitHeight
                    radius: 5
                    color: qgcPal.windowShade
                    border.width: 1
                    border.color: qgcPal.card

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            collapsedList.visible = false
                            expandedList.visible = true
                            fillExpandedList(parent.children[1].children[1].text) // clumsy  hack. look for better solutions
                        }

                    }
                    GridLayout {
                        id: gl
                        columns: 2
                        Rectangle {
                            width: ScreenTools.defaultFontPixelWidth * 3
                            //height: ScreenTools.defaultFontPixelWidth * 6
                            Layout.fillHeight: true
                            radius: 5
                            color: collapsedColor
                            Layout.rowSpan: 2
                            Layout.margins: 1

                        }
                        QGCLabel {
                            visible: false
                            text: collapsedId
                        }

                        QGCLabel{
                            padding: 5
                            text: collapsedTitle
                            width: parent.width - (2 * ScreenTools.defaultFontPixelWidth)
                            wrapMode: Text.WrapAnywhere
                        }
                        QGCLabel {
                            padding: 5
                            text: collapsedText
                            width: parent.width - (2 * ScreenTools.defaultFontPixelWidth)
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }

            }
            ListView {
                id: expandedList
                anchors.fill: parent
                anchors.margins:  ScreenTools.defaultFontPixelWidth
                clip: true
                spacing:  ScreenTools.defaultFontPixelWidth
                model: expandedModel
                visible: false
                header:
                    QGCButton {
                        text: "Back"
                        onClicked: {
                            collapsedList.visible = true
                            expandedList.visible = false
                        }
                    }
                delegate:
                    Rectangle {
                    width: parent.width
                    height: gl2.implicitHeight
                    radius: 5
                    color: qgcPal.windowShade
                    border.width: 1
                    border.color: qgcPal.card
                    Column {
                        id: gl2
                        width: expandedList.width
                        padding: ScreenTools.defaultFontPixelWidth
                        spacing: 5
                        QGCLabel {

                            text: expandedTitle
                            font.bold: true
                            width: parent.width - (2 * ScreenTools.defaultFontPixelWidth)
                            wrapMode: Text.WordWrap
                        }
                        QGCLabel {
                            text: expandedText
                            width: parent.width - (2 * ScreenTools.defaultFontPixelWidth)
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

        }
    }


    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       toolStrip.leftInset
        leftEdgeCenterInset:    toolStrip.leftInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeRightInset:   guidedConfirm.bottomInset
    }

    FlyViewMissionCompleteDialog {
        missionController:      _missionController
        geoFenceController:     _geoFenceController
        rallyPointController:   _rallyPointController
    }

    Rectangle {
        id: moveMultiVehicleWidget
        height: ScreenTools.defaultFontPixelWidth * 4
        width: ScreenTools.defaultFontPixelWidth * 4
        color: qgcPal.button
        radius: ScreenTools.defaultFontPixelWidth * 1
        anchors.right: multiVehiclePanelSelector.left
        anchors.bottom: multiVehiclePanelSelector.bottom
        anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 2
        visible: mainWindow._flyViewEditingLayer && QGroundControl.multiVehicleManager.vehicles.count > 1

        QGCColoredImage {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1
            source: "qrc:/qmlimages/drag.png"
            color:  qgcPal.text
        }

        MouseArea {
            id: moveMultiVehicleMouse
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.color = qgcPal.buttonHighlight
            onExited: parent.color = qgcPal.button
            drag{
                target:   multiVehiclePanelSelector
                minimumX: parent.width
                minimumY: 0
                maximumX: mainWindow.width - multiVehiclePanelSelector.width
                maximumY: mainWindow.height - multiVehiclePanelSelector.height  - ScreenTools.defaultFontPixelHeight * 4
            }
            onMouseXChanged: QGroundControl.settingsManager.flyViewEditSettings.multiX.value = multiVehiclePanelSelector.x;
            onMouseYChanged: QGroundControl.settingsManager.flyViewEditSettings.multiY.value = multiVehiclePanelSelector.y;
        }
    }


    Rectangle {
        id:                 multiVehiclePanelSelector
        x: calcX()
        y: calcY()
        z: 1
        width:ScreenTools.defaultFontPixelHeight * 2
//        anchors.right: parent.right
//        anchors.bottom:parent.bottom
//        anchors.bottomMargin:   ScreenTools.defaultFontPixelHeight * 1
        height:    ScreenTools.defaultFontPixelHeight * 2
        color:"transparent"

        radius: 5

        visible: QGroundControl.multiVehicleManager.vehicles.count > 1

        function calcX() {
            if(QGroundControl.settingsManager.flyViewEditSettings.multiX.value === -1){
                return parent.x + parent.width - ScreenTools.defaultFontPixelHeight * 2 - drawerSpace.width
            }
            else
                return QGroundControl.settingsManager.flyViewEditSettings.multiX.value
        }

        function calcY() {
            if(QGroundControl.settingsManager.flyViewEditSettings.multiY.value === -1)
                return parent.y + parent.height - ScreenTools.defaultFontPixelHeight * 2
            else
                return QGroundControl.settingsManager.flyViewEditSettings.multiY.value
        }

        MultiVehicleList {
            id: multiVehicleList
            anchors.bottom:          multiVehiclePanelSelector.top
            anchors.bottomMargin:   -multiVehiclePanelSelector.height/2
            anchors.right:          parent.right
            anchors.rightMargin:    multiVehiclePanelSelector.height/2
            width:                  calcWidth()
            height:                 calcHeight()
            visible:                !showSingleVehiclePanel

            function calcWidth() {
                 if(QGroundControl.settingsManager.flyViewEditSettings.multiWidth.value === -1) {
                    recalcWidthHeight()
                    return parent.width * 12
                 }
                 else
                     return QGroundControl.settingsManager.flyViewEditSettings.multiWidth.value
            }

            function calcHeight() {
                if(QGroundControl.settingsManager.flyViewEditSettings.multiHeight.value === -1) {
                    recalcWidthHeight()
                    return ScreenTools.defaultFontPixelHeight * 20
                }
                else
                    return QGroundControl.settingsManager.flyViewEditSettings.multiHeight.value
            }
            function recalcWidthHeight(){
                width =  parent.width * 12
                height = ScreenTools.defaultFontPixelHeight * 20
            }
        }

        Row {
            id:         selectorRow
//            anchors.right: parent.right
            anchors.rightMargin:    ScreenTools.defaultFontPixelHeight * 0.5
            anchors.topMargin:  ScreenTools.defaultFontPixelHeight * 0.5
            anchors.bottom:     parent.bottom
            anchors.right:      parent.right
//            anchors.horizontalCenter: parent.horizontalCenter


            QGCMapPalette { id: mapPal; lightColors: true }

            Image {
                id:                         btn1
                visible:                    showSingleVehiclePanel
//                width:                      ScreenTools.defaultFontPixelHeight * 2*0.75
//                height:                      ScreenTools.defaultFontPixelHeight * 2*0.75
                height:                     btn1.y - selectorScale.y
                width:                      height
                source:                     "/qmlimages/mutlidrone.png"
                mipmap:                     true
                fillMode:                   Image.PreserveAspectFit

                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        singleVehicleRadio.checked = !singleVehicleRadio.checked
                        moveMultiVehicleWidget.anchors.rightMargin = multiVehicleList.width
                        multiVehicleScale._enable = true

                    }
                }
            }

            Image {
                id:                         btn2
                visible:                    !showSingleVehiclePanel
//                width:                      ScreenTools.defaultFontPixelHeight * 2 *0.75
//                height:                     ScreenTools.defaultFontPixelHeight * 2 *0.75
                height:                     btn1.height
                width:                      height
                source:                     "/qmlimages/Pictudrone1.png"
                mipmap:                     true
                fillMode:                   Image.PreserveAspectFit

                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        singleVehicleRadio.checked = !singleVehicleRadio.checked
//                        moveMultiVehicleWidget.anchors.rightMargin = ScreenTools.defaultFontPixelWidth * 2
                        moveMultiVehicleWidget.anchors.rightMargin = btn1.width
                        multiVehicleScale._enable = false
                    }
                }
            }

            QGCRadioButton {
                id:             singleVehicleRadio
                text:           qsTr("Single")
                checked:        true
                textColor:      mapPal.text
                visible:        false
            }

            QGCRadioButton {
                text:           qsTr("Multi-Vehicle")
                textColor:      mapPal.text
                visible:        false
            }
        }


        Rectangle {
            id: selectorScale
            height: ScreenTools.defaultFontPixelWidth * 4
            width: ScreenTools.defaultFontPixelWidth * 4
            color: qgcPal.button
            radius: ScreenTools.defaultFontPixelWidth * 1

            property bool _enable: false

            x:  btn1.x
            y:  calcScale()
            visible: mainWindow._flyViewEditingLayer && showSingleVehiclePanel

            function calcScale(){
                if(QGroundControl.settingsManager.flyViewEditSettings.multiIconScale.value === -1)
                 return btn1.y - selectorScale.height
                else
                    return QGroundControl.settingsManager.flyViewEditSettings.multiIconScale.value
            }


            QGCColoredImage {
                anchors.fill: parent
                anchors.margins: ScreenTools.defaultFontPixelWidth * 1
                source: "qrc:/qmlimages/scale1.png"
                color:  qgcPal.text
            }

            MouseArea {
                id: scaleMouse
                anchors.fill: parent
                hoverEnabled: true
                drag{
                    target: selectorScale
                }
                drag.axis: "YAxis"
                onMouseYChanged:{
                    moveMultiVehicleWidget.anchors.rightMargin = btn1.width
                    QGroundControl.settingsManager.flyViewEditSettings.multiIconScale.value = multiIconScale.y
                    console.log("moving")
                }
                onEntered: parent.color = qgcPal.buttonHighlight
                onExited: parent.color = qgcPal.button
            }
        }





        Rectangle {
            id: multiVehicleScale
            height: ScreenTools.defaultFontPixelWidth * 4
            width: ScreenTools.defaultFontPixelWidth * 4
            color: qgcPal.button
            radius: ScreenTools.defaultFontPixelWidth * 1

            property bool _enable: false

            x:  multiVehicleList.x - width - multiVehiclePanelSelector.width/2
            y:  multiVehicleList.y
            visible: mainWindow._flyViewEditingLayer && _enable

            QGCColoredImage {
                anchors.fill: parent
                anchors.margins: ScreenTools.defaultFontPixelWidth * 1
                source: "qrc:/qmlimages/scale1.png"
                color:  qgcPal.text
            }

            MouseArea {
                id: scaleMouse2
                anchors.fill: parent
                hoverEnabled: true
                drag{
                    target: multiVehicleScale
                    maximumX: -multiVehiclePanelSelector.width * 12
                    maximumY: - multiVehiclePanelSelector.height * 10
                }

                onMouseXChanged: {
                    multiVehicleList.width = (multiVehicleList.x+multiVehicleList.width) - (multiVehicleScale.x + width + multiVehiclePanelSelector.width/2)
                    moveMultiVehicleWidget.anchors.rightMargin = multiVehicleList.width
                    QGroundControl.settingsManager.flyViewEditSettings.multiWidth.value = multiVehicleList.width
                }
                onMouseYChanged: {
                    multiVehicleList.height = (multiVehicleList.y+multiVehicleList.height) -  multiVehicleScale.y
                    QGroundControl.settingsManager.flyViewEditSettings.multiHeight.value = multiVehicleList.height
                }
                onEntered: parent.color = qgcPal.buttonHighlight
                onExited: parent.color = qgcPal.button
            }
        }


    }



    Rectangle {
        id: moveInstrumentWidget
        height: ScreenTools.defaultFontPixelWidth * 4
        width: ScreenTools.defaultFontPixelWidth * 4
        color: qgcPal.button
        radius: ScreenTools.defaultFontPixelWidth * 1
        anchors.right: instrumentPanel.left
        anchors.top: instrumentPanel.top
        visible: mainWindow._flyViewEditingLayer && !QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value

        QGCColoredImage {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1
            source: "qrc:/qmlimages/drag.png"
            color:  qgcPal.text
        }

        MouseArea {
            id: moveInstrumentMouse
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.color = qgcPal.buttonHighlight
            onExited: parent.color = qgcPal.button
            drag{
                target: instrumentPanel
                minimumX: parent.width
                minimumY: 0
                maximumX: mainWindow.width - drawerSpace.width - instrumentPanel.width - scaleWidget.width
                maximumY: mainWindow.height - ScreenTools.toolbarHeight - instrumentPanel.height - scaleWidget.height
            }
            onMouseXChanged: QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelX.value = instrumentPanel.x;
            onMouseYChanged: QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelY.value = instrumentPanel.y;
        }
    }

    FlyViewInstrumentPanel {
        id:                         instrumentPanel
        x:                          calcX()
        y:                          calcY()

        width:                      calcWidth()
        height:                     calcHeight()
        spacing:                    _toolsMargin
        visible:                    !QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value
        //availableHeight:            parent.height - y - _toolsMargin

        function calcX(){
            if(QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelX.value === -1){
                return (_root.width * 0.5) - (calcWidth() * 0.5)
            }
            else
                return QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelX.value
        }
        function calcY(){
            if(QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelY.value === -1)
                return _toolsMargin
            else
                return QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelY.value
        }
        function calcWidth(){
            if(QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelWidth.value === -1){
                recalcWidthHeight()
                return _rightPanelWidth * (QGroundControl.settingsManager.flyViewSettings.alternateInstrumentPanel.rawValue ? 0.2272 : 1)
            }
            else
                return QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelWidth.value
        }
        function calcHeight(){
            if(QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelHeight.value === -1){
                recalcWidthHeight()
                return _rightPanelWidth * (QGroundControl.settingsManager.flyViewSettings.alternateInstrumentPanel.rawValue ? 1 : 0.2272)
            }
            else
                return QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelHeight.value
        }

        function recalcWidthHeight(){
            width = _rightPanelWidth * (QGroundControl.settingsManager.flyViewSettings.alternateInstrumentPanel.rawValue ? 0.2272 : 1)
            height = _rightPanelWidth * (QGroundControl.settingsManager.flyViewSettings.alternateInstrumentPanel.rawValue ? 1 : 0.2272)
        }
    }

    Rectangle {
        id: scaleWidget
        height: ScreenTools.defaultFontPixelWidth * 4
        width: ScreenTools.defaultFontPixelWidth * 4
        color: qgcPal.button
        radius: ScreenTools.defaultFontPixelWidth * 1

        x:  instrumentPanel.x + instrumentPanel.width
        y:  instrumentPanel.y + instrumentPanel.height
        visible: mainWindow._flyViewEditingLayer && !QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value

        QGCColoredImage {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1
            source: "qrc:/qmlimages/scale1.png"
            color:  qgcPal.text
        }

        MouseArea {
            id: scaleMouse3
            anchors.fill: parent
            hoverEnabled: true
            drag{
                target: scaleWidget
                minimumX: instrumentPanel.x + ( (instrumentPanel.height * 2) *
                          (QGroundControl.settingsManager.flyViewSettings.alternateInstrumentPanel.rawValue ? 0 : 1 ) )

                minimumY: instrumentPanel.y  + ( (instrumentPanel.width * 2) *
                                                (QGroundControl.settingsManager.flyViewSettings.alternateInstrumentPanel.rawValue ? 1 : 0 ) )
                maximumX: mainWindow.width - drawerSpace.width - parent.width
                maximumY: mainWindow.height - ScreenTools.toolbarHeight - parent.height
            }
            onMouseXChanged: {
                instrumentPanel.width = scaleWidget.x - instrumentPanel.x;
                QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelWidth.value = instrumentPanel.width;
            }
            onMouseYChanged: {
                instrumentPanel.height = scaleWidget.y - instrumentPanel.y
                QGroundControl.settingsManager.flyViewEditSettings.instrumentPanelHeight.value = instrumentPanel.height;
            }
            onEntered: parent.color = qgcPal.buttonHighlight
            onExited: parent.color = qgcPal.button
        }
    }

    Rectangle {
        id: moveAttitudeWidget
        height: ScreenTools.defaultFontPixelWidth * 4
        width: ScreenTools.defaultFontPixelWidth * 4
        color: qgcPal.button
        radius: ScreenTools.defaultFontPixelWidth * 1
        anchors.right: attitudeRect.left
        anchors.top: attitudeRect.top
        visible: mainWindow._flyViewEditingLayer && QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value

        QGCColoredImage {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1
            source: "qrc:/qmlimages/drag.png"
            color:  qgcPal.text
        }

        MouseArea {
            id: moveAttitudeMouse
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.color = qgcPal.buttonHighlight
            onExited: parent.color = qgcPal.button
            drag{
                target: attitudeRect
                minimumX: parent.width
                minimumY: 0
                maximumX: mainWindow.width - drawerSpace.width - attitudeRect.width - attitudeScale.width
                maximumY: mainWindow.height - ScreenTools.toolbarHeight - attitudeRect.height - attitudeScale.height
            }
            onMouseXChanged: QGroundControl.settingsManager.flyViewEditSettings.attitudeX.value = attitudeRect.x;
            onMouseYChanged: QGroundControl.settingsManager.flyViewEditSettings.attitudeY.value = attitudeRect.y;
        }
    }
    Rectangle {
        id: attitudeRect

        x: calcX()
        y: calcY()
        width: calcHeight()
        height: calcHeight()
        radius: calcHeight() * 0.5
        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        visible: QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value

        property real _topBottomMargin: calcHeight() * 0.05

        QGCAttitudeWidget {
            id:                     attitude
            anchors.leftMargin:     parent._topBottomMargin
            anchors.left:           parent.left
            size:                   parent.width - parent._topBottomMargin * 2
            vehicle:                globals.activeVehicle
            anchors.verticalCenter: parent.verticalCenter
        }
        function calcX(){

            if(QGroundControl.settingsManager.flyViewEditSettings.attitudeX.value === -1){
                return (_root.width * 0.5) - ( (_rightPanelWidth )  * 0.5) - moveAttitudeWidget.width
            }
            else
                return QGroundControl.settingsManager.flyViewEditSettings.attitudeX.value
        }
        function calcY(){
            if(QGroundControl.settingsManager.flyViewEditSettings.attitudeY.value === -1)
                return _toolsMargin
            else
                return QGroundControl.settingsManager.flyViewEditSettings.attitudeY.value
        }
        function calcHeight(){
            if(QGroundControl.settingsManager.flyViewEditSettings.attitudeScale.value === -1){
                height = _rightPanelWidth * 0.2272
                return _rightPanelWidth * 0.2272
            }
            else
                return QGroundControl.settingsManager.flyViewEditSettings.attitudeScale.value
        }
    }
    Rectangle {
        id: attitudeScale
        height: ScreenTools.defaultFontPixelWidth * 4
        width: ScreenTools.defaultFontPixelWidth * 4
        color: qgcPal.button
        radius: ScreenTools.defaultFontPixelWidth * 1

        x:  attitudeRect.x + attitudeRect.width
        y:  attitudeRect.y + attitudeRect.height
        visible: mainWindow._flyViewEditingLayer && QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value

        QGCColoredImage {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1
            source: "qrc:/qmlimages/scale1.png"
            color:  qgcPal.text
        }

        MouseArea {
            id: attitudeScaleMouse
            anchors.fill: parent
            hoverEnabled: true
            drag{
                target: attitudeScale
                minimumX: attitudeRect.x

                minimumY: attitudeRect.y
                maximumX: mainWindow.width - drawerSpace.width - parent.width
                maximumY: mainWindow.height - ScreenTools.toolbarHeight - parent.height
            }
            onMouseYChanged: {
                attitudeRect.height = attitudeScale.y - attitudeRect.y
                QGroundControl.settingsManager.flyViewEditSettings.attitudeScale.value = attitudeRect.height;
            }
            onEntered: parent.color = qgcPal.buttonHighlight
            onExited: parent.color = qgcPal.button
        }
    }

    Rectangle {
        id: moveValuesWidget
        height: ScreenTools.defaultFontPixelWidth * 4
        width: ScreenTools.defaultFontPixelWidth * 4
        color: qgcPal.button
        radius: ScreenTools.defaultFontPixelWidth * 1
        anchors.right: valuesRect.left
        anchors.top: valuesRect.top
        visible: mainWindow._flyViewEditingLayer && QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value

        QGCColoredImage {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1
            source: "qrc:/qmlimages/drag.png"
            color:  qgcPal.text
        }

        MouseArea {
            id: moveValuesMouse
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.color = qgcPal.buttonHighlight
            onExited: parent.color = qgcPal.button
            drag{
                target: valuesRect
                minimumX: parent.width
                minimumY: 0
                maximumX: mainWindow.width - drawerSpace.width - valuesRect.width - valuesScale.width
                maximumY: mainWindow.height - ScreenTools.toolbarHeight - valuesRect.height - valuesScale.height
            }
            onMouseXChanged: QGroundControl.settingsManager.flyViewEditSettings.valuesX.value = valuesRect.x;
            onMouseYChanged: QGroundControl.settingsManager.flyViewEditSettings.valuesY.value = valuesRect.y;
        }
    }
    Rectangle {
        id: valuesRect

        x:calcX()
        y:calcY()
        width: calcWidth() //_rightPanelWidth * 0.5456
        height: calcHeight() // _rightPanelWidth * 0.2272
        radius: ScreenTools.defaultFontPixelWidth * 1
        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        visible: QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value

        property real _topBottomMargin: ScreenTools.defaultFontPixelWidth


        ColumnLayout {		// vyorius /*
            id: tabView
            anchors.fill: parent
            anchors.margins: parent._topBottomMargin
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
                    //enabled: QGroundControl.videoManager(0).videoReceiver
                    _bdrWidth: 1
                    _bdrColor: qgcPal.text
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
        function calcX(){
            if(QGroundControl.settingsManager.flyViewEditSettings.valuesX.value === -1){
                return (_root.width * 0.5) - (calcWidth() * 0.5)
            }
            else
                return QGroundControl.settingsManager.flyViewEditSettings.valuesX.value
        }
        function calcY(){
            if(QGroundControl.settingsManager.flyViewEditSettings.valuesY.value === -1)
                return _toolsMargin
            else
                return QGroundControl.settingsManager.flyViewEditSettings.valuesY.value
        }
        function calcWidth(){
            if(QGroundControl.settingsManager.flyViewEditSettings.valuesWidth.value === -1){
                recalcWidthHeight()
                return _rightPanelWidth * 0.5456
            }
            else
                return QGroundControl.settingsManager.flyViewEditSettings.valuesWidth.value
        }
        function calcHeight(){
            if(QGroundControl.settingsManager.flyViewEditSettings.valuesHeight.value === -1){
                recalcWidthHeight()
                return _rightPanelWidth * 0.2272
            }
            else
                return QGroundControl.settingsManager.flyViewEditSettings.valuesHeight.value
        }

        function recalcWidthHeight(){
            width = _rightPanelWidth * 0.5456
            height = _rightPanelWidth * 0.2272
        }

    }
    Rectangle {
        id: valuesScale
        height: ScreenTools.defaultFontPixelWidth * 4
        width: ScreenTools.defaultFontPixelWidth * 4
        color: qgcPal.button
        radius: ScreenTools.defaultFontPixelWidth * 1

        x:  valuesRect.x + valuesRect.width
        y:  valuesRect.y + valuesRect.height
        visible: mainWindow._flyViewEditingLayer && QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value

        QGCColoredImage {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1
            source: "qrc:/qmlimages/scale1.png"
            color:  qgcPal.text
        }

        MouseArea {
            id: valuesScaleMouse
            anchors.fill: parent
            hoverEnabled: true
            drag{
                target: valuesScale
                minimumX: valuesRect.x

                minimumY: valuesRect.y
                maximumX: mainWindow.width - drawerSpace.width - parent.width
                maximumY: mainWindow.height - ScreenTools.toolbarHeight - parent.height
            }
            onMouseXChanged: {
                valuesRect.width = valuesScale.x - valuesRect.x;
                QGroundControl.settingsManager.flyViewEditSettings.valuesWidth.value = valuesRect.width;
            }
            onMouseYChanged: {
                valuesRect.height = valuesScale.y - valuesRect.y
                QGroundControl.settingsManager.flyViewEditSettings.valuesHeight.value = valuesRect.height;
            }
            onEntered: parent.color = qgcPal.buttonHighlight
            onExited: parent.color = qgcPal.button
        }
    }

    Rectangle {
        id: moveCompassWidget
        height: ScreenTools.defaultFontPixelWidth * 4
        width: ScreenTools.defaultFontPixelWidth * 4
        color: qgcPal.button
        radius: ScreenTools.defaultFontPixelWidth * 1
        anchors.right: compassRect.left
        anchors.top: compassRect.top
        visible: mainWindow._flyViewEditingLayer && QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value

        QGCColoredImage {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1
            source: "qrc:/qmlimages/drag.png"
            color:  qgcPal.text
        }

        MouseArea {
            id: moveCompassMouse
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.color = qgcPal.buttonHighlight
            onExited: parent.color = qgcPal.button
            drag{
                target: compassRect
                minimumX: parent.width
                minimumY: 0
                maximumX: mainWindow.width - drawerSpace.width - compassRect.width - compassScale.width
                maximumY: mainWindow.height - ScreenTools.toolbarHeight - compassRect.height - compassScale.height
            }
            onMouseXChanged: QGroundControl.settingsManager.flyViewEditSettings.compassX.value = compassRect.x;
            onMouseYChanged: QGroundControl.settingsManager.flyViewEditSettings.compassY.value = compassRect.y;
        }
    }
    Rectangle {
        id: compassRect

        x:calcX()
        y:calcY()
        width: calcHeight()
        height: calcHeight()
        radius: width * 0.5
        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        visible: QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value

        property real _topBottomMargin: width * 0.05

        QGCCompassWidget {
            id:                     compass
            anchors.leftMargin:     parent._topBottomMargin
            anchors.left:           parent.left
            size:                   parent.width - parent._topBottomMargin * 2
            vehicle:                globals.activeVehicle
            anchors.verticalCenter: parent.verticalCenter
        }
        function calcX(){

            if(QGroundControl.settingsManager.flyViewEditSettings.compassX.value === -1){
                return (_root.width * 0.5) + ( (_rightPanelWidth * 0.5456 )  * 0.5) + moveCompassWidget.width
            }
            else
                return QGroundControl.settingsManager.flyViewEditSettings.compassX.value
        }
        function calcY(){
            if(QGroundControl.settingsManager.flyViewEditSettings.compassY.value === -1)
                return _toolsMargin
            else
                return QGroundControl.settingsManager.flyViewEditSettings.compassY.value
        }
        function calcHeight(){
            if(QGroundControl.settingsManager.flyViewEditSettings.compassScale.value === -1){
                height = _rightPanelWidth * 0.2272
                return _rightPanelWidth * 0.2272
            }
            else
                return QGroundControl.settingsManager.flyViewEditSettings.compassScale.value
        }
    }
    Rectangle {
        id: compassScale
        height: ScreenTools.defaultFontPixelWidth * 4
        width: ScreenTools.defaultFontPixelWidth * 4
        color: qgcPal.button
        radius: ScreenTools.defaultFontPixelWidth * 1

        x:  compassRect.x + compassRect.width
        y:  compassRect.y + compassRect.height
        visible: mainWindow._flyViewEditingLayer && QGroundControl.settingsManager.flyViewEditSettings.splitHUD.value

        QGCColoredImage {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1
            source: "qrc:/qmlimages/scale1.png"
            color:  qgcPal.text
        }

        MouseArea {
            id: compassScaleMouse
            anchors.fill: parent
            hoverEnabled: true
            drag{
                target: compassScale
                minimumX: compassRect.x

                minimumY: compassRect.y
                maximumX: mainWindow.width - drawerSpace.width - parent.width
                maximumY: mainWindow.height - ScreenTools.toolbarHeight - parent.height
            }
            onMouseYChanged: {
                compassRect.height = compassScale.y - compassRect.y
                QGroundControl.settingsManager.flyViewEditSettings.compassScale.value = compassRect.height;
            }
            onEntered: parent.color = qgcPal.buttonHighlight
            onExited: parent.color = qgcPal.button
        }
    }

    Rectangle {
        id: moveConfirmWidget
        height: ScreenTools.defaultFontPixelWidth * 4
        width: ScreenTools.defaultFontPixelWidth * 4
        color: qgcPal.button
        radius: ScreenTools.defaultFontPixelWidth * 1
        anchors.right: guidedConfirm.left
        anchors.top: guidedConfirm.top
        anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 1
        visible: mainWindow._flyViewEditingLayer && guidedConfirm.visible

        QGCColoredImage {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1
            source: "qrc:/qmlimages/drag.png"
            color:  qgcPal.text
        }

        MouseArea {
            id: moveConfirmMouse
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.color = qgcPal.buttonHighlight
            onExited: parent.color = qgcPal.button
            drag{
                target: guidedConfirm
                minimumX: parent.width
                minimumY: 0
                maximumX: mainWindow.width - drawerSpace.width - guidedConfirm.width
                maximumY: mainWindow.height - ScreenTools.toolbarHeight - guidedConfirm.height
            }
            onMouseXChanged: QGroundControl.settingsManager.flyViewEditSettings.confirmDialogX.value = guidedConfirm.x;
            onMouseYChanged: QGroundControl.settingsManager.flyViewEditSettings.confirmDialogY.value = guidedConfirm.y;
        }
    }

    GuidedActionConfirm {
        id:   guidedConfirm
        guidedController:   _guidedController
        altitudeSlider:     _guidedAltSlider

        x:                  calcX()
        y:                  calcY()
        anchors.margins:    _toolsMargin

        width: calcWidth()
        height: calcHeight()

        function calcX(){

            if(QGroundControl.settingsManager.flyViewEditSettings.confirmDialogX.value === -1){
                return (_root.width * 0.5) - (guidedConfirm.width * 0.5)
            }
            else
                return QGroundControl.settingsManager.flyViewEditSettings.confirmDialogX.value
        }
        function calcY(){
            if(QGroundControl.settingsManager.flyViewEditSettings.confirmDialogY.value === -1)
                return (_root.height - height - _toolsMargin)
            else
                return QGroundControl.settingsManager.flyViewEditSettings.confirmDialogY.value
        }
        property real bottomInset: height


        function calcWidth()  {
//            return mainLayout.width + (_margins * 4)
            if(QGroundControl.settingsManager.flyViewEditSettings.confirmDialogWidth.value === -1)
                return ScreenTools.defaultFontPixelWidth * 38
            else
                return QGroundControl.settingsManager.flyViewEditSettings.confirmDialogWidth.value

        }
        function calcHeight() {
//            return mainLayout.height + (_margins * 4)
            if(QGroundControl.settingsManager.flyViewEditSettings.confirmDialogHeight.value === -1)
                return ScreenTools.defaultFontPixelWidth * 26
            else
                return QGroundControl.settingsManager.flyViewEditSettings.confirmDialogHeight.value

        }
    }


    Rectangle {
        id: guidedConfirmScale
        height: ScreenTools.defaultFontPixelWidth * 4
        width: ScreenTools.defaultFontPixelWidth * 4
        color: qgcPal.button
        radius: ScreenTools.defaultFontPixelWidth * 1

        x:  guidedConfirm.x + guidedConfirm.width
        y:  guidedConfirm.y + guidedConfirm.height
        visible: mainWindow._flyViewEditingLayer && guidedConfirm.visible

        QGCColoredImage {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1
            source: "qrc:/qmlimages/scale1.png"
            color:  qgcPal.text
        }

        MouseArea {
            id: guidedConfirmScaleMouse
            anchors.fill: parent
            hoverEnabled: true
            drag{
                target:   guidedConfirmScale
                minimumX: guidedConfirm.x + ScreenTools.defaultFontPixelWidth * 38

//                minimumY: toolStrip.y
//                maximumX: mainWindow.width - drawerSpace.width - parent.width
//                maximumY: mainWindow.height - ScreenTools.toolbarHeight - parent.height
            }
            onMouseYChanged: {
                guidedConfirm.height =  guidedConfirmScale.y - guidedConfirm.y
                QGroundControl.settingsManager.flyViewEditSettings.confirmDialogHeight.value = guidedConfirm.height;
            }
            onMouseXChanged: {
                guidedConfirm.width = guidedConfirmScale.x - guidedConfirm.x
                QGroundControl.settingsManager.flyViewEditSettings.confirmDialogWidth.value = guidedConfirm.width;
            }

            onEntered: parent.color = qgcPal.buttonHighlight
            onExited: parent.color = qgcPal.button
        }
    }

    PhotoVideoControl {
            id:                     photoVideoControl
            anchors.margins:        _toolsMargin
            anchors.right:          parent.right
            width:                  _rightPanelWidth
            visible:                true//QGroundControl.settingsManager.adminSettings.showPhotoVideoControl.value
            state:                  _verticalCenter ? "verticalCenter" : "topAnchor"
            states: [
                State {
                    name: "verticalCenter"
                    AnchorChanges {
                        target:                 photoVideoControl
                        anchors.top:            undefined
                        anchors.verticalCenter: _root.verticalCenter
                    }
                },
                State {
                    name: "topAnchor"
                    AnchorChanges {
                        target:                 photoVideoControl
                        anchors.verticalCenter: undefined
                        anchors.top:            instrumentPanel.bottom
                    }
                }
            ]

            property bool _verticalCenter: !QGroundControl.settingsManager.flyViewSettings.alternateInstrumentPanel.rawValue
        }


    //-- Virtual Joystick
    Loader {
        id:                         virtualJoystickMultiTouch
        z:                          QGroundControl.zOrderTopMost + 1
        width:                      parent.width  - (_pipOverlay.width / 2)
        height:                     Math.min(parent.height * 0.25, ScreenTools.defaultFontPixelWidth * 16)
        visible:                    _virtualJoystickEnabled && !QGroundControl.videoManager(0).fullScreen && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       parentToolInsets.leftEdgeBottomInset + ScreenTools.defaultFontPixelHeight * 2
        anchors.horizontalCenter:   parent.horizontalCenter
        source:                     "qrc:/qml/VirtualJoystick.qml"
        active:                     _virtualJoystickEnabled && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)

        property bool autoCenterThrottle: QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue

        property bool _virtualJoystickEnabled: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue
    }

//    Rectangle {
//        id: moveToolStrip
//        height: ScreenTools.defaultFontPixelWidth * 4
//        width: ScreenTools.defaultFontPixelWidth * 4
//        color: qgcPal.button
//        radius: ScreenTools.defaultFontPixelWidth * 1
//        anchors.left: toolStrip.right
//        anchors.top: toolStrip.top
//        visible: mainWindow._flyViewEditingLayer

//        QGCColoredImage {
//            anchors.fill: parent
//            anchors.margins: ScreenTools.defaultFontPixelWidth * 1
//            source: "qrc:/qmlimages/drag.png"
//            color:  qgcPal.text
//        }

//        MouseArea {
//            id: moveToolMouse
//            anchors.fill: parent
//            hoverEnabled: true
//            onEntered: parent.color = qgcPal.buttonHighlight
//            onExited: parent.color = qgcPal.button
//            drag{
//                target: toolStrip
//                minimumX: width
//                minimumY: 0
//                maximumX: mainWindow.width - drawerSpace.width - moveToolStrip.width
//                maximumY: mainWindow.height - ScreenTools.toolbarHeight - toolStrip.height
//            }
//            onMouseXChanged: QGroundControl.settingsManager.flyViewEditSettings.toolX.value = toolStrip.x
//            onMouseYChanged: QGroundControl.settingsManager.flyViewEditSettings.toolY.value = toolStrip.y;
//        }
//    }

    FlyViewToolStrip {
        id:                     toolStrip
      //  anchors.leftMargin:     _toolsMargin + parentToolInsets.leftEdgeCenterInset
      //  anchors.topMargin:      _toolsMargin + parentToolInsets.topEdgeLeftInset

        x: calcX()
        y: calcY()
//        width: calcWidth()

        property real _idealWidth: (ScreenTools.isMobile ? ScreenTools.minTouchPixels : ScreenTools.defaultFontPixelWidth * 8.8)

        function calcX(){

            if(QGroundControl.settingsManager.flyViewEditSettings.toolX.value === -1){
                return _toolsMargin + parentToolInsets.leftEdgeCenterInset
            }
            else
                return QGroundControl.settingsManager.flyViewEditSettings.toolX.value
        }
        function calcY(){
            if(QGroundControl.settingsManager.flyViewEditSettings.toolY.value === -1)
                return _toolsMargin + parentToolInsets.topEdgeLeftInset
            else
                return QGroundControl.settingsManager.flyViewEditSettings.toolY.value
        }

        function calcWidth() {
            if(QGroundControl.settingsManager.flyViewEditSettings.toolHeight.value === -1)
                toolStrip.height = QGroundControl.settingsManager.flyViewEditSettings.toolHeight.value;

            if(QGroundControl.settingsManager.flyViewEditSettings.toolWidth.value === -1)
                return (ScreenTools.isMobile ? ScreenTools.minTouchPixels : ScreenTools.defaultFontPixelWidth * 8.8)
            else
                return QGroundControl.settingsManager.flyViewEditSettings.toolWidth.value
        }


        z:                      QGroundControl.zOrderWidgets
        maxHeight:              parent.height - y// - parentToolInsets.bottomEdgeLeftInset - _toolsMargin
        visible:                !QGroundControl.videoManager(0).fullScreen

        //onDisplayPreFlightChecklist: mainWindow.showPopupDialogFromComponent(preFlightChecklistPopup)  // vyorius

        property real leftInset: x + width
    }

//    Rectangle {
//        id: toolStripScale
//        height: ScreenTools.defaultFontPixelWidth * 4
//        width: ScreenTools.defaultFontPixelWidth * 4
//        color: qgcPal.button
//        radius: ScreenTools.defaultFontPixelWidth * 1

//        x:  toolStrip.x + toolStrip.width
//        y:  toolStrip.y + toolStrip.height
//        visible: mainWindow._flyViewEditingLayer

//        QGCColoredImage {
//            anchors.fill: parent
//            anchors.margins: ScreenTools.defaultFontPixelWidth * 1
//            source: "qrc:/qmlimages/scale1.png"
//            color:  qgcPal.text
//        }

//        MouseArea {
//            id: compassScaleMouse2
//            anchors.fill: parent
//            hoverEnabled: true
//            drag{
//                target:   toolStripScale
////                minimumX: compassRect.x

////                minimumY: toolStrip.y
////                maximumX: mainWindow.width - drawerSpace.width - parent.width
////                maximumY: mainWindow.height - ScreenTools.toolbarHeight - parent.height
//            }
//            onMouseYChanged: {
//                toolStrip.height = toolStripScale.y - toolStrip.y
//                QGroundControl.settingsManager.flyViewEditSettings.toolHeight.value = toolStrip.height;
//            }
//            onMouseXChanged: {
//                toolStrip.width = toolStripScale.x - toolStrip.x
//                QGroundControl.settingsManager.flyViewEditSettings.toolWidth.value = toolStrip.width;
//            }

//            onEntered: parent.color = qgcPal.buttonHighlight
//            onExited: parent.color = qgcPal.button
//        }
//    }


    FlyViewAirspaceIndicator {
        anchors.top:                parent.top
        anchors.topMargin:          ScreenTools.defaultFontPixelHeight * 0.25
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderWidgets
        show:                       mapControl.pipState.state !== mapControl.pipState.pipState
    }

    VehicleWarnings {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    Component {
        id: preFlightChecklistPopup
        FlyViewPreFlightChecklistPopup {
        }
    }

    Popup {
        id: aisDropPanel
        background: Rectangle { color: qgcPal.window; border.width: 1; border.color: "#f38355"; radius:10 }
        anchors.centerIn: parent
        dim:true
        modal: true
        ColumnLayout{
            id: vesselFilterColumn
            spacing: ScreenTools.defaultFontPixelWidth * 0.5

            RowLayout {
                id: aisToggle
         //       height: 40
                Layout.fillWidth: true
                QGCLabel {
                    id: aisEnabledLabel
                    text: "AIS Enabled"
                    Layout.fillWidth: true
                    padding: 10
                }
//                QGCSwitch {
//                    id: aisVisibleSwitch
//                    checked: QGroundControl.settingsManager.adminSettings.enableAIS.value
//                    onClicked: {
//                        QGroundControl.settingsManager.adminSettings.enableAIS.value = checked
//                            mapControl.callAisApi()

//                    }
//                }
            }
            RowLayout {
                id: searchBox
            //    height: 40
                Layout.fillWidth: true
                visible: QGroundControl.settingsManager.adminSettings.enableAIS.value
                QGCTextField {
                    id: searchBoxTextField
                    placeholderText: qsTr("Search")
                    Layout.fillWidth: true
                }
                QGCButton {
                    id: searchButton
                    enabled: QGroundControl.settingsManager.adminSettings.enableAIS.value
                    onClicked: {
                        var i
                        while (searchResults.length!==0)
                            searchResults.pop()
                        for(i = 0; i < mapControl.aisJSON.length; i++) {
                            if(mapControl.aisJSON[i].vesselParticulars.vesselName.includes(searchBoxTextField.text.toUpperCase() )){
                                searchResults.push(mapControl.aisJSON[i])
                            }
                        }
                        listView.model = searchResults
                        listView.visible = true
                        searchHistoryLabel.visible = true
                        clearButton.visible = true

                    }

                    QGCColoredImage {
                        id: searchImage
                        height: parent.height * 0.7
                        width: height
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/InstrumentValueIcons/search.svg"
                        color: qgcPal.text
                    }
                }

            }
            RowLayout {
                QGCLabel {
                    id: searchHistoryLabel
                    text: "Search History"
                    padding: 5
                    visible: false
                    Layout.fillWidth: true

                }
                Button {
                    id: clearButton
                    enabled: QGroundControl.settingsManager.adminSettings.enableAIS.value
                    visible: false
                    contentItem: clearLabel
                    text: "clear"
                    QGCLabel {
                        id: clearLabel
                        font.underline: true
                        text: "Clear"
                    }

                    background: Rectangle {
                        opacity: 0
                    }

                    onClicked: {
                        var i
                        while (searchResults.length!==0)
                            searchResults.pop()

                        listView.model = searchResults
                        listView.visible = false
                        searchHistoryLabel.visible = false
                        clearButton.visible = false
                    }
                }
            }

            RowLayout {
                    QGCListView {
                        id: listView
                        height: ScreenTools.defaultFontPixelHeight * 10
                        Layout.fillWidth: true
                        focus: true
                        visible: false
                        keyNavigationWraps: true
                        ScrollBar.vertical: ScrollBar {
                            id: scrollControl
                            active: true
                        }
                        clip: true
                        highlight: Rectangle { color: "#f38355"; radius: 5 }
                        model: searchResults
                        delegate: Item {
                            width: listView.width
                            height: listItem.implicitHeight
                            Column {
                                id: listItem
                                QGCLabel {text: "Name : " + modelData.vesselParticulars.vesselName; leftPadding: 5; rightPadding: 5}
                                QGCLabel {text: "Type : " + modelData.vesselParticulars.vesselType; leftPadding: 5; rightPadding: 5}
                                QGCLabel {text: "Dimensions : " + modelData.vesselParticulars.vesselLength + ", " + modelData.vesselParticulars.vesselBreadth; leftPadding: 5; rightPadding: 5}
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked:{
                                    listView.currentIndex = index
                                    mapControl.selectedVessel = modelData
                                    mapControl.vesselDetailPopUp.open()
                                }
                            }
                        }
                    }
                }
           // }
            QGCLabel {
                id: filterHeading
                text: qsTr("Filters")
                Layout.fillWidth: true
            }
            RowLayout{
//                QGCCheckBox {
//                    id: cargoVesselsCheckBox
//                    checked: mapControl.filterMatrix["CS"]
//                    enabled: QGroundControl.settingsManager.adminSettings.enableAIS.value
//                    MouseArea {
//                        anchors.fill: parent
//                        onClicked: {
//                            cargoVesselsCheckBox.checked = !cargoVesselsCheckBox.checked
//                            mapControl.callAisApi()
//                            mapControl.filterMatrix["CS"] = cargoVesselsCheckBox.checked
//                        }
//                    }
//                }
             //   Rectangle {
                    Shape {
                        id: cargoVesselsIcon

                        width: ScreenTools.defaultFontPixelHeight
                        height: ScreenTools.defaultFontPixelHeight
                        ShapePath {
                            strokeWidth: 1
                            strokeColor: "black"
                            fillColor: mapControl.colorMatrix["CS"]
                            strokeStyle: ShapePath.SolidLine
                            startX: 0; startY: ScreenTools.defaultFontPixelHeight*0.5
                            PathLine { x: 0; y: ScreenTools.defaultFontPixelHeight * 0.5 }
                            PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.8 }
                            PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.8}
                            PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                            PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                        }
                    }
            //    }
                QGCLabel {
                    text: qsTr("Cargo Vessels")
                    Layout.fillWidth:true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            RowLayout{
//                QGCCheckBox {
//                    id: tankersCheckBox
//                    checked: mapControl.filterMatrix["TA"]
//                    enabled: QGroundControl.settingsManager.adminSettings.enableAIS.value
//                    MouseArea {
//                        anchors.fill: parent
//                        onClicked: {
//                            tankersCheckBox.checked = !tankersCheckBox.checked
//                            mapControl.callAisApi()
//                            mapControl.filterMatrix["TA"] = tankersCheckBox.checked
//                        }
//                    }
//                }
                Shape {
                    id: tankersIcon
                    width: ScreenTools.defaultFontPixelHeight
                    height: ScreenTools.defaultFontPixelHeight
                    ShapePath {
                        strokeWidth: 1
                        strokeColor: "black"
                        fillColor: mapControl.colorMatrix["TA"]
                        strokeStyle: ShapePath.SolidLine
                        startX: 0; startY: ScreenTools.defaultFontPixelHeight*0.5
                        PathLine { x: 0; y: ScreenTools.defaultFontPixelHeight * 0.5 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.8 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.8}
                        PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                    }
                }
                QGCLabel {
                    text: qsTr("Tankers")
                    Layout.fillWidth: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            RowLayout{
                QGCCheckBox {
                    id: passengerVesselsCheckBox
                    checked: mapControl.filterMatrix["PV"]
                    enabled: QGroundControl.settingsManager.adminSettings.enableAIS.value
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            passengerVesselsCheckBox.checked = !passengerVesselsCheckBox.checked
                            mapControl.callAisApi()
                            mapControl.filterMatrix["PV"] = passengerVesselsCheckBox.checked
                        }
                    }
                }
                Shape {
                    id: passengerVesselsIcon
                    width: ScreenTools.defaultFontPixelHeight
                    height: ScreenTools.defaultFontPixelHeight
                    ShapePath {
                        strokeWidth: 1
                        strokeColor: "black"
                        fillColor: mapControl.colorMatrix["PV"]
                        strokeStyle: ShapePath.SolidLine
                        startX: 0; startY: ScreenTools.defaultFontPixelHeight*0.5
                        PathLine { x: 0; y: ScreenTools.defaultFontPixelHeight * 0.5 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.8 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.8}
                        PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                    }
                }
                QGCLabel {
                    text: qsTr("Passenger Vessels")
                    Layout.fillWidth: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            RowLayout{
                QGCCheckBox {
                    id: chemicalTankerCheckBox
                    checked: mapControl.filterMatrix["CH"]
                    enabled: QGroundControl.settingsManager.adminSettings.enableAIS.value
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            chemicalTankerCheckBox.checked = !chemicalTankerCheckBox.checked
                            mapControl.callAisApi()
                            mapControl.filterMatrix["CH"] = chemicalTankerCheckBox.checked
                        }
                    }
                }
                Shape {
                    id: chemicalTankerIcon

                    width: ScreenTools.defaultFontPixelHeight
                    height: ScreenTools.defaultFontPixelHeight
                    ShapePath {
                        strokeWidth: 1
                        strokeColor: "black"
                        fillColor: mapControl.colorMatrix["CH"]
                        strokeStyle: ShapePath.SolidLine
                        startX: 0; startY: ScreenTools.defaultFontPixelHeight*0.5
                        PathLine { x: 0; y: ScreenTools.defaultFontPixelHeight * 0.5 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.8 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.8}
                        PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                    }
                }
                QGCLabel {
                    text: qsTr("Chemical Tanker")
                    Layout.fillWidth: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            RowLayout{
                QGCCheckBox {
                    id: liquidCargoCheckBox
                    checked: mapControl.filterMatrix["LC"]
                    enabled: QGroundControl.settingsManager.adminSettings.enableAIS.value
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            liquidCargoCheckBox.checked = !liquidCargoCheckBox.checked
                            mapControl.callAisApi()
                            mapControl.filterMatrix["LC"] = liquidCargoCheckBox.checked
                        }
                    }
                }
                Shape {
                    id: liquidCargoIcon

                    width: ScreenTools.defaultFontPixelHeight
                    height: ScreenTools.defaultFontPixelHeight
                    ShapePath {
                        strokeWidth: 1
                        strokeColor: "black"
                        fillColor: mapControl.colorMatrix["LC"]
                        strokeStyle: ShapePath.SolidLine
                        startX: 0; startY: ScreenTools.defaultFontPixelHeight*0.5
                        PathLine { x: 0; y: ScreenTools.defaultFontPixelHeight * 0.5 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.8 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.8}
                        PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                    }
                }
                QGCLabel {
                    text: qsTr("Liquid Cargo")
                    Layout.fillWidth: true
                    anchors.verticalCenter: parent.verticalCenter
                }

            }
            RowLayout{
                QGCCheckBox {
                    id: ferryCheckBox
                    checked: mapControl.filterMatrix["FR"]
                    enabled: QGroundControl.settingsManager.adminSettings.enableAIS.value
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            ferryCheckBox.checked = !ferryCheckBox.checked
                            mapControl.callAisApi()
                            mapControl.filterMatrix["FR"] = ferryCheckBox.checked
                        }
                    }
                }
                Shape {
                    id: ferryIcon
                    width: ScreenTools.defaultFontPixelHeight
                    height: ScreenTools.defaultFontPixelHeight
                    ShapePath {
                        strokeWidth: 1
                        strokeColor: "black"
                        fillColor: mapControl.colorMatrix["FR"]
                        strokeStyle: ShapePath.SolidLine
                        startX: 0; startY: ScreenTools.defaultFontPixelHeight*0.5
                        PathLine { x: 0; y: ScreenTools.defaultFontPixelHeight * 0.5 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.8 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.8}
                        PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                    }
                }
                QGCLabel {
                    text: qsTr("Ferry")
                    Layout.fillWidth: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            RowLayout{
                QGCCheckBox {
                    id: otherCheckBox
                    checked: mapControl.others
                    enabled: QGroundControl.settingsManager.adminSettings.enableAIS.value
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            otherCheckBox.checked = !otherCheckBox.checked
                            mapControl.callAisApi()
                            mapControl.others = otherCheckBox.checked
                        }
                    }
                }
                Shape {
                    id: otherIcon

                    width: ScreenTools.defaultFontPixelHeight
                    height: ScreenTools.defaultFontPixelHeight
                    ShapePath {
                        strokeWidth: 1
                        strokeColor: "black"
                        fillColor: "black"
                        strokeStyle: ShapePath.SolidLine
                        startX: 0; startY: ScreenTools.defaultFontPixelHeight*0.5
                        PathLine { x: 0; y: ScreenTools.defaultFontPixelHeight * 0.5 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.8 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.8}
                        PathLine { x: ScreenTools.defaultFontPixelHeight; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                        PathLine { x: ScreenTools.defaultFontPixelHeight*0.5; y: ScreenTools.defaultFontPixelHeight * 0.2 }
                    }
                }
                QGCLabel {
                    text: qsTr("Others")
                    Layout.fillWidth: true
                }
            }
        }
    }
}
