/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.12
import QtQuick.Controls 2.4
import QtQuick.Layouts  1.11
import QtQuick.Dialogs  1.3
import QtGraphicalEffects 1.12

import QGroundControl                       1.0
import QGroundControl.FlightDisplay         1.0
import QGroundControl.Controls              1.0
import QGroundControl.Palette               1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Controllers           1.0



Rectangle {
    id:     _root
    color:  qgcPal.toolbarBackground

    property bool showBorder: qgcPal.globalTheme === QGCPalette.Light
    property real   _margins:           ScreenTools.defaultFontPixelWidth
    property real   _spacing:           ScreenTools.defaultFontPixelWidth / 2

    property bool customImage: false
    property bool customImage2: false
    property var vehicle1: null
    property var vehicle2: null
    property var vehicle3: null
    property var vehicle4: null
    property var vehicle5: null
    property var vehicle6: null
    property var vehicles: []
//    property bool preorpos: false


    //property alias drawervis: drawer.visible
    property alias userImagepic: _userImage
    /// Bottom single pixel divider
    property var cloud_api: QGroundControl.vyoriusCloudApi

    property int currentToolbar: flyViewToolbar

    readonly property int flyViewToolbar:   0
    readonly property int planViewToolbar:  1
    readonly property int simpleToolbar:    2

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: qgcPal.brandingPurple
    property bool   _armed:             _activeVehicle ? _activeVehicle.armed : false
    property var    _vehicleInAir:      _activeVehicle ? _activeVehicle.flying || _activeVehicle.landing : false

    QGCPalette { id: qgcPal }

    /// Bottom single pixel divider
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:          qgcPal.windowShade
        visible:        qgcPal.globalTheme === QGCPalette.Light
    }


    Rectangle {
        anchors.fill:   viewButtonRow
        color:          qgcPal.toolbarBackground
    }

    RowLayout {
        id:                     viewButtonRow
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        spacing:                ScreenTools.defaultFontPixelWidth / 2

        QGCToolBarButton {
            id:                     currentButton
            Layout.preferredHeight: viewButtonRow.height
            icon.source:            "/res/VyoriusLogo"
            _horizontalMargin: ScreenTools.defaultFontPixelWidth * 3.5
            logo:                   true
            onClicked:              {
                if (mainWindow.oddclickcheck()) {
                    drawer.visible = false
                    mainWindow.drawerclicked()
                }
                else if (!mainWindow.oddclickcheck()){
                    drawer.visible = true
                    mainWindow.drawerclicked()
                }
//                if (cloud_api.guestMode()) {
//                    _userImage.visible = false
//                    usernameLabel.visible = false
//                    _guestImageGIF.visible = true
//                } else {
//                    _userImage.visible = true
//                    _userImage.source = cloud_api.imageurl;
//                    if(cloud_api.imageurl == "")
//                        _userImage.source="/qmlimages/default_avatarGIF";
//                }
            }
        }

        Rectangle {
            Layout.margins: ScreenTools.defaultFontPixelHeight / 2
            Layout.fillHeight: true
            width: 1
            color: qgcPal.text
            visible: true
        }

        QGCColoredImage {
            id:     internetStatusImg
            Layout.alignment : Qt.AlignVCenter
            source: cloud_api.internetAvailable() ? "/qmlimages/connected.png" : "/qmlimages/disconnected.png"
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.8
            height:ScreenTools.defaultFontPixelHeight * 1.8
            width: height
            color: "transparent"
            fillMode: Image.PreserveAspectFit

//            Connections {
//                target: cloud_api;
////                function onInternetChanged() {
////                    internetStatusImg.source = cloud_api.internetAvailable() ? "/qmlimages/connected.png" : "/qmlimages/disconnected.png";
////                    if(cloud_api.internetAvailable()){
////                        uploadTimer.start()
////                    }
////                }
//            }
            Timer {
                id:  uploadTimer
                interval: 2000
                running: false
                onTriggered: {
                    QGroundControl.mavlinkLogManager.uploadLog()
                    QGroundControl.mavlinkLogManager.uploadTLog()
                }

            }
        }
    }

    QGCFlickable {
        id:                     toolsFlickable
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1
        anchors.left:           viewButtonRow.right
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.right:          parent.right
        contentWidth:           indicatorLoader.x + indicatorLoader.width
        flickableDirection:     Flickable.HorizontalFlick

        Loader {
            id:                 indicatorLoader
            anchors.left:       parent.left
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             "qrc:/toolbar/MainToolBarIndicators.qml"            // vyorius
        }

        MainStatusIndicator {
            anchors.left: indicatorLoader.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Timer{
    id: _reloadmission
    interval: 30000
    running: false
    onTriggered: {
    console.log("ready to start another mission");
    }
    Component.onCompleted: {
    globals.missiontimer = _reloadmission
    }
    }
    QGCLabel{
    id: savingmission
    text: "Saving"
    font.pointSize: ScreenTools.defaultFontPointSize
    color: qgcPal.text
    anchors.right: mainStatusLabel.left
    anchors.rightMargin: ScreenTools.defaultFontPointSize * 2
    anchors.verticalCenter:  parent.verticalCenter
    visible: _reloadmission.running
    }
    QGCLabel {
        id:             mainStatusLabel
        text:           mainStatusText()
        font.pointSize: _vehicleInAir ? ScreenTools.defaultFontPointSize : ScreenTools.largeFontPointSize
        color:          _mainStatusBGColor
        anchors.right:   disconnectButton.left
        anchors.verticalCenter: parent.verticalCenter

        property string _commLostText:      qsTr("Communication Lost")
        property string _readyToFlyText:    qsTr("Ready To Fly")
        property string _notReadyToFlyText: qsTr("Not Ready")
        property string _disconnectedText:  qsTr("Disconnected")
        property string _armedText:         qsTr("Armed")
        property string _flyingText:        qsTr("Flying")
        property string _landingText:       qsTr("Landing")

        function mainStatusText() {
            var statusText
            if (_activeVehicle) {
                if (_communicationLost) {
                    _mainStatusBGColor = qgcPal.colorRed
                    return mainStatusLabel._commLostText
                }
                if (_activeVehicle.armed) {
                    _mainStatusBGColor = qgcPal.colorGreen
                    if (_activeVehicle.flying) {
                        return mainStatusLabel._flyingText
                    } else if (_activeVehicle.landing) {
                        return mainStatusLabel._landingText
                    } else {
                        return mainStatusLabel._armedText
                    }
                } else {
                    if (_activeVehicle.readyToFlyAvailable) {
                        if (_activeVehicle.readyToFly) {
                            _mainStatusBGColor = qgcPal.colorGreen
                            return mainStatusLabel._readyToFlyText
                        } else {
                            _mainStatusBGColor = qgcPal.colorOrange
                            return mainStatusLabel._notReadyToFlyText
                        }
                    } else {
                        // Best we can do is determine readiness based on AutoPilot component setup and health indicators from SYS_STATUS
                        if (_activeVehicle.allSensorsHealthy && _activeVehicle.autopilot.setupComplete) {
                            _mainStatusBGColor = qgcPal.colorGreen
                            return mainStatusLabel._readyToFlyText
                        } else {
                            _mainStatusBGColor = qgcPal.colorOrange
                            return mainStatusLabel._notReadyToFlyText
                        }
                    }
                }
            } else {
                _mainStatusBGColor = qgcPal.brandingPurple
                return mainStatusLabel._disconnectedText
            }
        }

        MouseArea {
            anchors.left:           parent.left
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            height:                 parent.height
            enabled:                _activeVehicle
            onClicked:              mainWindow.showIndicatorPopup(mainStatusLabel, sensorStatusInfoComponent)
        }
    }

    Component {
        id: sensorStatusInfoComponent

        Rectangle {
            width:          flickable.width + (_margins * 2)
            height:         flickable.height + (_margins * 2)
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            color:          qgcPal.window
            border.color:   qgcPal.text

            QGCFlickable {
                id:                 flickable
                anchors.margins:    _margins
                anchors.top:        parent.top
                anchors.left:       parent.left
                width:              mainLayout.width
                height:             gLayout.height + ScreenTools.defaultFontPixelHeight * 5
                flickableDirection: Flickable.VerticalFlick
                contentHeight:      mainLayout.height
                contentWidth:       mainLayout.width

                ColumnLayout {
                    id:         mainLayout
                    spacing:    _spacing

                    QGCButton {
                        Layout.alignment:   Qt.AlignHCenter
                        text:               _armed ?  qsTr("Disarm") : (forceArm ? qsTr("Force Arm") : qsTr("Arm"))

                        property bool forceArm: false

                        onPressAndHold: forceArm = true

                        onClicked: {
                            if (_armed) {
                                mainWindow.disarmVehicleRequest()
                            } else {
                                if (forceArm) {
                                    mainWindow.forceArmVehicleRequest()
                                } else {
                                    mainWindow.armVehicleRequest()
                                }
                            }
                            forceArm = false
                            mainWindow.hideIndicatorPopup()
                        }
                    }

                    QGCLabel {
                        Layout.alignment:   Qt.AlignHCenter
                        text:               qsTr("Sensor Status")
                    }

                    GridLayout {
                        id: gLayout
                        rowSpacing:     _spacing
                        columnSpacing:  _spacing
                        rows:           _activeVehicle.sysStatusSensorInfo.sensorNames.length
                        flow:           GridLayout.TopToBottom

                        Repeater {
                            model: _activeVehicle.sysStatusSensorInfo.sensorNames

                            QGCLabel {
                                text: modelData
                            }
                        }

                        Repeater {
                            model: _activeVehicle.sysStatusSensorInfo.sensorStatus

                            QGCLabel {
                                text: modelData
                            }
                        }
                    }
                }
            }
        }
    }

    // Disconnect Button

    QGCButton {
        id:                 disconnectButton
        anchors.right: brandingLogoImage.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth
        anchors.rightMargin: ScreenTools.defaultFontPixelWidth
        text:               qsTr("Disconnect")
        onClicked:          _activeVehicle.closeVehicle()
        width:              visible ? implicitWidth : 1
        visible:            _activeVehicle && _communicationLost
        onVisibleChanged: {
//            if(visible && !doNotShow.checked){
//                disconnectPopup.open()
//            }
//            if(!dontSendToCloud.checked){
//                cloud_api._vehicleDisconnected(_activeVehicle)
//            }
        }
    }
    Popup {
        id:         disconnectPopup
        //parent:     Overlay.overlay
        anchors.centerIn: Overlay.overlay
        modal: true
        background: Rectangle {
            color: qgcPal.window
            radius: 10
            width: disconnectPopup.width
            height: disconnectPopup.height
        }
        ColumnLayout{
            QGCLabel {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Label.horizontalAlignment
                text: qsTr("<h3>Vehicle Disconnected</h3>")
            }
            QGCCheckBox {
                id:     doNotShow
                text: qsTr("Do not show this dialog next time")
            }
            QGCCheckBox {
                id:     dontSendToCloud
                text: qsTr("Do not send to cloud automatically")
            }
            QGCButton {
                id:     okay
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Ok")
                onClicked: disconnectPopup.close()
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Branding Logo
    Image {
        id: brandingLogoImage
        anchors.right:          logoutButton.left
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.margins:        ScreenTools.defaultFontPixelHeight * 0.66
        fillMode:               Image.PreserveAspectFit
        source:                 _outdoorPalette ? _brandImageOutdoor : _brandImageIndoor
        mipmap:                 true

        property bool   _outdoorPalette:        qgcPal.globalTheme === QGCPalette.Light
        property bool   _corePluginBranding:    QGroundControl.corePlugin.brandImageIndoor.length != 0
        property string _userBrandImageIndoor:  QGroundControl.settingsManager.brandImageSettings.userBrandImageIndoor.value
        property string _userBrandImageOutdoor: QGroundControl.settingsManager.brandImageSettings.userBrandImageOutdoor.value
        property bool   _userBrandingIndoor:    _userBrandImageIndoor.length != 0
        property bool   _userBrandingOutdoor:   _userBrandImageOutdoor.length != 0
        property string _brandImageIndoor:      brandImageIndoor()
        property string _brandImageOutdoor:     brandImageOutdoor()

        function brandImageIndoor() {
            if (_userBrandingIndoor) {
                return _userBrandImageIndoor
            } else {
                if (_userBrandingOutdoor) {
                    return _userBrandingOutdoor
                } else {
                    return ""
                }
            }
        }

        function brandImageOutdoor() {
            if (_userBrandingOutdoor) {
                return _userBrandingOutdoor
            } else {
                if (_userBrandingIndoor) {
                    return _userBrandingIndoor
                } else {
                    return ""
                }
            }
        }
    }
//done button for checklist


    // Logout Button
    QGCButton {
        id: logoutButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "Logout"

        onClicked: {

            //code altered by zannat from here
            prg.visible = false
            anim.visible = false
            if (drawer.visible == true) {
                drawer.visible = !drawer.visible
                mainWindow.drawerclicked()
            }
            logoutDialog.open()
        }

        MessageDialog {
            id: logoutDialog
            title: qsTr("Exit")
            text: qsTr("Do you really want to log out?    ")
            standardButtons: StandardButton.Yes | StandardButton.No
            onYes: {
                cloud_api.logOut()
                //mainrootwindowloader.source = "qrc:/qml/LoginPages/LoginPage.qml"
                /*
                 above property commented because it's useless and create self loop.
                 LoginPage is a ApplicationWindow and it contains mainrootwindowloader in it ,
                 and here ( above ) we assigning LoginPage inisde LoginPage . This will create another
                 application window , Till now above line was working because the qrc source address was wrong.
               */
                mainrootwindowloader.source = ""
            }
        }
    }
//    GuidedActionsController{
//          id: abcdef
//    }


//    QGCButton {
//        id: doneButtoncheck
//        anchors.right: logoutButton.left
//         text: "Done flying"

//       //  property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
//      //   property bool _useChecklist:    QGroundControl.settingsManager.appSettings.useChecklist.rawValue && QGroundControl.corePlugin.options.preFlightChecklistUrl.toString().length
////edited



//         onClicked: {
//        abcdef.preorpos= 1
//            abcdef.openCustomChecklist()



//         }
//}


    // Small parameter download progress bar
    Rectangle {
        anchors.bottom: parent.bottom
        height:         _root.height * 0.05
        width:          _activeVehicle ? _activeVehicle.parameterManager.loadProgress * parent.width : 0
        color:          qgcPal.colorGreen
        visible:        !largeProgressBar.visible
    }

    // Large parameter download progress bar
    Rectangle {
        id:             largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         parent.height
        color:          qgcPal.window
        visible:        _showLargeProgress

        property bool _initialDownloadComplete: _activeVehicle ? _activeVehicle.parameterManager.parametersReady : true
        property bool _userHide:                false
        property bool _showLargeProgress:       !_initialDownloadComplete && !_userHide && qgcPal.globalTheme === QGCPalette.Light

        Connections {
            target:                 QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(){  largeProgressBar._userHide = false }
        }

        Rectangle {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width:          _activeVehicle ? _activeVehicle.parameterManager.loadProgress * parent.width : 0
            color:          qgcPal.colorGreen
        }

        QGCLabel {
            anchors.centerIn:   parent
            text:               qsTr("Downloading Parameters")
            font.pointSize:     ScreenTools.largeFontPointSize
        }

        QGCLabel {
            anchors.margins:    _margin
            anchors.right:      parent.right
            anchors.bottom:     parent.bottom
            text:               qsTr("Click anywhere to hide")

            property real _margin: ScreenTools.defaultFontPixelWidth / 2
        }

        MouseArea {
            anchors.fill:   parent
            onClicked:      largeProgressBar._userHide = true
        }
    }

    //------------------------------------------------------------------------
    //-- Drawer
    function highlighSetting() {
        if (settingButton.checked) {
            flightButton.checked = false
            planningButton.checked = false
            analyzeButton.checked = false
            configurationButton.checked = false
            qrCodeButton.checked = false
        }
    }
    function highlightFlight() {
        if (flightButton.checked) {
            settingButton.checked = false
            planningButton.checked = false
            analyzeButton.checked = false
            configurationButton.checked = false
            qrCodeButton.checked = false
        }
    }
    function highlighPlanning() {
        if (planningButton.checked) {
            flightButton.checked = false
            settingButton.checked = false
            analyzeButton.checked = false
            configurationButton.checked = false
            qrCodeButton.checked = false
        }
    }
    function highlighAnalyze() {
        if (analyzeButton.checked) {
            flightButton.checked = false
            planningButton.checked = false
            settingButton.checked = false
            configurationButton.checked = false
            qrCodeButton.checked = false
        }
    }
    function highlightConfiguration() {
        if (configurationButton.checked) {
            flightButton.checked = false
            planningButton.checked = false
            analyzeButton.checked = false
            settingButton.checked = false
            qrCodeButton.checked = false
        }
    }
    function highlighQrCode() {
        if (qrCodeButton.checked) {
            flightButton.checked = false
            planningButton.checked = false
            analyzeButton.checked = false
            settingButton.checked = false
            configurationButton.checked = false
        }
    }
    function openappsett() {
        return QGroundControl.corePlugin.settingsPages
    }
    function opensetup() {
        return QGroundControl.corePlugin ? QGroundControl.corePlugin.settingsPages : []
    }
    function openanalyze() {
        return QGroundControl.corePlugin.analyzePages
    }







    function openpages() {
        if (settingButton.checked)
            openappsett()
        if (flightButton.checked) {
            settingButton.checked = false
            mainWindow.showFlyView()
        }
        if (planningButton.checked) {
            settingButton.checked = false
            mainWindow.showPlanView()
        }
        if (analyzeButton.checked) {
            settingButton.checked = false
        }
        if (configurationButton.checked) {
            settingButton.checked = false
            mainWindow.showSetupView()
        }
        if (qrCodeButton.checked) {
            settingButton.checked = false
            mainWindow.showQRView()
        }
    }

    Drawer {
        id: drawer
        y: header.height
        width: ScreenTools.defaultFontPixelWidth * 28
        height: (mainWindow.height - header.height)
        topMargin: ScreenTools.defaultFontPixelWidth * 1.5
        closePolicy: Popup.NoAutoClose
        modal: false
        visible: false
        dim: false
        background: Rectangle {
            anchors.fill: parent
            anchors.topMargin: ScreenTools.defaultFontPixelWidth * 1.5
            color: qgcPal.windowShade
            Rectangle {

                id: drawerrect
                anchors.fill: parent

                color: qgcPal.window
                scale: 0.95
            }
            DropShadow {
                source: drawerrect
                anchors.fill: drawerrect
                color: showBorder ? qgcPal.windowShade : qgcPal.card
                transparentBorder: true
                samples: 15
                spread: 0.3
            }
        }
        property var curMenu: null
        property var curSubMenu: null

        Column {
            id: drawermaincolumn
            width: drawer.width /*+ ScreenTools.defaultFontPixelWidth * 2*/
            leftPadding: 0
            rightPadding: 0
            Layout.margins: 0
            clip: true
            property real scrollcontentheight: (myorgList.height + configurationButton.height
                                               + flightButton.height + planningButton.height
                                               + analyzeButton.height
                                               + analyzeSubItemLoader.visualHeight
                                               + settingButton.height
                                               + settingSubItemLoader.visualHeight
                                               + 2*qrCodeButton.height) //* 1.1
            property real scrollframeheight: drawer.height - _userprofile.height

            Rectangle {
                id: _userprofile
                width: drawer.width
                height: width * 0.7

                color: qgcPal.window
                AnimatedImage {
                    id: _userImage
                    source: customImage ? imageFileDialog.fileUrl : cloud_api.imageurl
                    width: parent.width * 0.5
                    height: width
                    cache: false
                    visible: true
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: _circularMask
                    }
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth * 3

                    FileDialog {
                        id: imageFileDialog
                        title: "Select an Image"
                        folder: shortcuts.home
                        selectExisting: true
                        nameFilters: ["Image files (*.jpg *.png)"]
                        onAccepted: {
                            console.log("You chose " + imageFileDialog.fileUrls)
                            customImage = true
                            cloud_api.getImage(imageFileDialog.fileUrls)

                        }
                        onRejected: {
                            console.log("Didnt chose anything")
                        }
                    }
                }

                AnimatedImage {
                    id: _guestImageGIF
                    source: customImage2 ? imageFileDialog2.fileUrl : "qrc:/qmlimages/default_avatarGIF"
                    width: parent.width * 0.5
                    height: width
                    visible: false
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: _circularMask
                    }

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth * 3

                    FileDialog {
                        id: imageFileDialog2
                        title: "Select a Image"
                        folder: shortcuts.home
                        selectExisting: true
                        nameFilters: ["Image files (*.jpg *.png)"]
                        onAccepted: {
                            customImage2 = true
                            console.log("You chose " + imageFileDialog2.fileUrls)
                        }
                        onRejected: {
                            console.log("Didnt chose anything")
                        }
                    }
                }

                Rectangle {
                    id: _circularMask
                    width: _userImage.width
                    height: width
                    radius: width * 0.7
                    border.width: 1
                    visible: false
                }

                Rectangle {
                    id: editRect
                    anchors.fill: _userImage
                    color: "transparent"

                    Label {
                        id: editPic
                        anchors.fill: parent
                        visible: false

                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            fillMode: Image.PreserveAspectCrop
                            source: "/qmlimages/editPic"
                            width: editRect.width - 68
                            height: width
                        }
                        background: Rectangle {
                            color: "lightgrey"
                            opacity: 0.5
                            radius: _userImage.width
                        }
                    }

                    MouseArea {
                        anchors.fill: editPic
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            console.log("Clicked Dp")
                            imageFileDialog.open()
                        }
                        onEntered: editPic.visible = true
                        onExited: editPic.visible = false
                    }
                }

            }

            ScrollView {
                id: toolbarscroll
                width: drawer.width
                height: drawermaincolumn.scrollframeheight
                clip: true
                contentWidth: width
                contentHeight: drawermaincolumn.scrollcontentheight
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                leftPadding: 0
                rightPadding: 0

                QGCComboBox {
                    id: myorgList
                    model: _orgModes
                    width: drawer.width - 10
                    height: drawer.height / 13
                    font.pointSize: ScreenTools.defaultFontPointSize* 1.5
                    sizeToContents: false
                    anchors.top: parent.top
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth * 4
                    leftPadding: 25
//                    visible: false

                    property bool showIndicator: true
                    property var _orgModes: ""
                    alternateText: ""

                    background: Rectangle {
                        id: orgRect
                        color: "transparent"
                        Rectangle {
                            id: _orgbackg
                            anchors.centerIn: parent
                            height: parent.height * 0.5
                            width: parent.width * 0.95
                            visible: true
                            radius: 5
                            color: qgcPal.window
                        }
                    }


                    Component.onCompleted: {

                            myorgList.model = ["GuestMode"]
                            _orgModes = ""

                    }
                }

                Button {
                    id: configurationButton
                    width: drawer.width
                    height: _contents.height * 1.4
                    anchors.top: myorgList.bottom
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter: drawer.horizontalCenter
                    checkable: true
                    visible: false
                    property bool collapsedmain5: true
                    onCheckedChanged: {
                        openpages()
                        highlightConfiguration()
                        collapsedmain5 = !collapsedmain5
                    }
                    background: Rectangle {
                        id: drawerMenu5
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        property bool highlighted5: (configurationButton.checked)
                        property bool containsSubItem5: false
                        property string text5
                        property url isrc5

                        color: qgcPal.window
                        Rectangle {
                            id: _backg5
                            anchors.centerIn: parent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height
                            width: parent.width
                            visible: true
//                            radius: 20
                            color: !configurationButton.checked?  qgcPal.window : Qt.rgba(qgcPal.buttonHighlight.r,qgcPal.buttonHighlight.g,qgcPal.buttonHighlight.b, 0.05)
                        }
                        DropShadow {
                            source: _backg5
                            color: !showBorder ? "#000000" : qgcPal.card
                            anchors.fill: _backg5
                            radius: 8
                            transparentBorder: true
                            visible: (configurationButton.checked)
                            verticalOffset: 0
                            spread: 0.0
                        }

                        Row {
                            id: _contents5
                            spacing: ScreenTools.defaultFontPixelWidth
                            anchors.left: drawerMenu5.left
                            anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                            anchors.verticalCenter: drawerMenu5.verticalCenter
                            Item {
                                height: ScreenTools.defaultFontPixelHeight * 3
                                width: 1
                            }
                            QGCColoredImage {
                                id: _icon5
                                height: drawer.height / 30
                                width: height
                                       * 1.3
                                sourceSize.height: parent.height
                                fillMode: Image.PreserveAspectFit
                                color: !configurationButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                source: "/qmlimages/Configuration.svg"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Rectangle {
                                height: drawer.height / 25
                                width: drawer.width * 0.35
                                anchors.verticalCenter: parent.verticalCenter

                                color: Qt.rgba(0,0,0,0) // transparent
                                Label {
                                    id: _label5
                                    visible: true
                                    text: "Configuration"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 1.5
                                    font.bold:      configurationButton.checked
                                    color: !configurationButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            QGCColoredImage {
                                height: drawer.height / 70
                                width: height
                                sourceSize.height: parent.height
                                fillMode: Image.PreserveAspectFit
                                color: !configurationButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                source: "/qmlimages/MenuDown"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: ScreenTools.defaultFontPixelWidth
                                                              / 2.5
                                visible: false
                                rotation: configurationButton.checked ? 0 : -90
                            }
                        }

                    }
                }

                Button {
                    id: flightButton
                    width: drawer.width
                    height: _contents.height * 1.4
                    anchors.top: configurationButton.top
                    anchors.horizontalCenter: drawer.horizontalCenter
                    checkable: true
//                    onClicked:{
//                        flyview1.visible=true
//                    }

                    onCheckedChanged: {
                        openpages()
                        highlightFlight()



                    }
                    background: Rectangle {
                        id: drawerMenu2
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        property bool highlighted2: (flightButton.checked)
                        property bool containsSubItem2: false
                        property string text2
                        property url isrc2

                        color: qgcPal.window
                        Rectangle {
                            id: _backg2
                            anchors.centerIn: parent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height
                            width: parent.width
                            visible: true
//                            radius: 20

                            color: !flightButton.checked?  qgcPal.window : Qt.rgba(qgcPal.buttonHighlight.r,qgcPal.buttonHighlight.g,qgcPal.buttonHighlight.b, 0.05)
                        }
                        DropShadow {
                            source: _backg2
                            color: !showBorder ? "#000000" : qgcPal.card
                            anchors.fill: _backg2
                            radius: 8
                            transparentBorder: true
                            visible: (flightButton.checked)
                            verticalOffset: 0
                            spread: 0.0
                        }
                        Row {
                            id: _contents2
                            spacing: ScreenTools.defaultFontPixelWidth
                            anchors.left: drawerMenu2.left
                            anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                            anchors.verticalCenter: drawerMenu2.verticalCenter
                            Item {
                                height: ScreenTools.defaultFontPixelHeight * 3
                                width: 1
                            }
                            QGCColoredImage {
                                id: _icon2
                                height: drawer.height / 30
                                width: height
                                       * 1.3
                                sourceSize.height: parent.height
                                fillMode: Image.PreserveAspectFit
                                color: !flightButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                source: "/qmlimages/PaperPlane.svg"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Rectangle {
                                height: drawer.height / 25
                                width: drawer.width * 0.35
                                anchors.verticalCenter: parent.verticalCenter
                                color: Qt.rgba(0,0,0,0) // transparent
                                Label {
                                    id: _label2
                                    visible: true
                                    text: "Flight"
                                    font.pointSize: ScreenTools.defaultFontPointSize* 1.5
                                    font.bold:      flightButton.checked
                                    color: !flightButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            QGCColoredImage {
                                height: drawer.height / 70
                                width: height
                                sourceSize.height: parent.height
                                fillMode: Image.PreserveAspectFit
                                color: !flightButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                source: "/qmlimages/MenuDown"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: 2.5
                                visible: false
                            }
                        }
                    }
                }
//                AbcdefG{
//                    id:flyview1
//                }

                Button {
                    id: planningButton //Planning button
                    width: drawer.width
                    height: _contents.height * 1.4
                    anchors.top: flightButton.bottom
                    anchors.horizontalCenter: drawer.horizontalCenter
                    checkable: true
                    onCheckedChanged: {
                        openpages()
                        highlighPlanning()
                    }

                    background: Rectangle {
                        id: drawerMenu3
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        property bool highlighted3: (planningButton.checked)
                        property bool containsSubItem3: false
                        property string text3
                        property url isrc3

                        color: qgcPal.window
                        Rectangle {
                            id: _backg3
                            anchors.centerIn: parent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height
                            width: parent.width
                            visible: true
//                            radius: 20

                            color: !planningButton.checked?  qgcPal.window : Qt.rgba(qgcPal.buttonHighlight.r,qgcPal.buttonHighlight.g,qgcPal.buttonHighlight.b, 0.05)
                        }
                        DropShadow {
                            source: _backg3
                            color: !showBorder ? "#000000" : qgcPal.card
                            anchors.fill: _backg3
                            radius: 8
                            transparentBorder: true
                            visible: (planningButton.checked)
                            verticalOffset: 0
                            spread: 0.0
                        }
                        Row {
                            id: _contents3
                            spacing: ScreenTools.defaultFontPixelWidth
                            anchors.left: drawerMenu3.left
                            anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                            anchors.verticalCenter: drawerMenu3.verticalCenter
                            Item {
                                height: ScreenTools.defaultFontPixelHeight * 3
                                width: 1
                            }
                            QGCColoredImage {
                                id: _icon3
                                height: drawer.height / 30
                                width: height * 1.3
                                sourceSize.height: parent.height
                                fillMode: Image.PreserveAspectFit
                                color: !planningButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                source: "/qmlimages/Plan.svg"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Rectangle {

                                color: Qt.rgba(0,0,0,0) // transparent
                                height: drawer.height / 25
                                width: drawer.width * 0.35
                                anchors.verticalCenter: parent.verticalCenter
                                Label {
                                    id: _label3
                                    visible: true
                                    text: "Planning"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 1.5
                                    font.bold:      planningButton.checked
                                    color: !planningButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                    anchors.verticalCenter: parent.verticalCenter

                                }
                            }
                            QGCColoredImage {
                                height: drawer.height / 70
                                width: height
                                sourceSize.height: parent.height
                                fillMode: Image.PreserveAspectFit
                                color: !planningButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                source: "/qmlimages/MenuDown"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: ScreenTools.defaultFontPixelWidth / 2.5
                                visible: false

                            }
                        }
                    }
                }

                Button {
                    id: analyzeButton
                    width: drawer.width
                    height: _contents.height * 1.4
                    anchors.top: planningButton.bottom
                    anchors.horizontalCenter: drawer.horizontalCenter
                    checkable: true
                    visible: false
                    property bool collapsedmain4: true
                    onCheckedChanged: {
                        openpages()
                        highlighAnalyze()
                        collapsedmain4 = !collapsedmain4
                    }

                    background: Rectangle {
                        id: drawerMenu4
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        property bool highlighted4: (analyzeButton.checked)
                        property bool containsSubItem4: false
                        property string text4
                        property url isrc4

                        color: qgcPal.window
                        Rectangle {
                            id: _backg4
                            anchors.centerIn: parent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height
                            width: parent.width
                            visible: true
//                            radius: 20

                            color: !analyzeButton.checked?  qgcPal.window : Qt.rgba(qgcPal.buttonHighlight.r,qgcPal.buttonHighlight.g,qgcPal.buttonHighlight.b, 0.05)
                        }
                        DropShadow {
                            source: _backg4
                            color: !showBorder ? "#000000" : qgcPal.card
                            anchors.fill: _backg4
                            radius: 8
                            transparentBorder: true
                            visible: (analyzeButton.checked)
                            verticalOffset: 0
                            spread: 0.0
                        }
                        Row {
                            id: _contents4
                            spacing: ScreenTools.defaultFontPixelWidth
                            anchors.left: drawerMenu4.left
                            anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                            anchors.verticalCenter: drawerMenu4.verticalCenter
                            Item {
                                height: ScreenTools.defaultFontPixelHeight * 3
                                width: 1
                            }
                            QGCColoredImage {
                                id: _icon4
                                height: drawer.height / 30
                                width: height * 1.3
                                sourceSize.height: parent.height
                                fillMode: Image.PreserveAspectFit
                                color: !analyzeButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                source: "/qmlimages/Analyze.svg"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Rectangle {
                                height: drawer.height / 25
                                width: drawer.width * 0.3
                                anchors.verticalCenter: parent.verticalCenter

                                color: Qt.rgba(0,0,0,0) // transparent
                                Label {
                                    id: _label4
                                    visible: true
                                    text: "Analyze"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 1.5
                                    font.bold:      analyzeButton.checked
                                    color: !analyzeButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                            QGCColoredImage {
                                height: drawer.height
                                        / 70
                                width: height
                                sourceSize.height: parent.height
                                fillMode: Image.PreserveAspectFit
                                color: !analyzeButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                source: "/qmlimages/MenuDown"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: drawer.height
                                                              / 400
                                visible: true
                                rotation: analyzeButton.checked ? 0 : -90
                            }
                        }
                    }
                }

                Loader {
                    id: analyzeSubItemLoader
                    anchors.top: analyzeButton.bottom
                    anchors.topMargin: -ScreenTools.defaultFontPixelWidth
                    visible: analyzeButton.checked
                     property real visualHeight : visible ? height : 0
                    property variant analyzeColumnItemModel: openanalyze()
                    sourceComponent: !analyzeButton.checked ? null : analyzeColumnDelegate
                    onStatusChanged: if (status == Loader.Ready)
                                         item.model = analyzeColumnItemModel
                }

                Button {
                    id: settingButton
                    width: drawer.width
                    height: _contents.height * 1.4
                    anchors.top: planningButton.bottom
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth
//                    visible: false
                    checkable: true

                    property bool collapsedmain: true
                    onCheckedChanged: {
                        highlighSetting()
                        openpages()
                        collapsedmain = !collapsedmain
                    }
                    background: Rectangle {
                        id: drawerMenu
                        height: parent.height
                        property bool highlighted: (settingButton.checked)
                        property bool containsSubItem: false
                        property string text
                        property url isrc

                        color: qgcPal.window

                        Rectangle {
                            id: _backg
                            anchors.centerIn: parent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height
                            width: parent.width
                            visible: true
//                            radius: 20
                            color: !settingButton.checked?  qgcPal.window : Qt.rgba(qgcPal.buttonHighlight.r,qgcPal.buttonHighlight.g,qgcPal.buttonHighlight.b, 0.05)
                        }
                        DropShadow {
                            source: _backg
                            color: !showBorder ? "#000000" : qgcPal.card
                            anchors.fill: _backg
                            radius: 8
                            transparentBorder: true
                            visible: (settingButton.checked)
                            verticalOffset: 0
                            spread: 0.0
                        }
                        Row {
                            id: _contents
                            spacing: ScreenTools.defaultFontPixelWidth
                            anchors.left: drawerMenu.left
                            anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                            anchors.verticalCenter: drawerMenu.verticalCenter
                            Item {
                                height: ScreenTools.defaultFontPixelHeight * 3
                                width: 1
                            }
                            QGCColoredImage {
                                id: _icon
                                height: drawer.height / 30
                                width: height * 1.30
                                sourceSize.height: parent.height
                                fillMode: Image.PreserveAspectFit
                                color: !settingButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                source: "/qmlimages/Gears.svg"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Rectangle {
                                height: drawer.height / 25
                                width: drawer.width * 0.32
                                anchors.verticalCenter: parent.verticalCenter
                                color: Qt.rgba(0,0,0,0) // transparent

                                Label {
                                    id: _label
                                    visible: text !== ""
                                    text: "Settings"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 1.50
                                    font.bold:      settingButton.checked
                                    color: !settingButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                            QGCColoredImage {
                                height: drawer.height / 70
                                width: height
                                sourceSize.height: parent.height
                                fillMode: Image.PreserveAspectFit
                                color: !settingButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                source: "/qmlimages/MenuDown"
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: drawer.height / 400
                                visible: true
                                rotation: settingButton.checked ? 0 : -90
                            }
                        }
                    } //for button1 rectangle
                } //Setting Button

                Loader {
                    id: settingSubItemLoader
                    anchors.top: settingButton.bottom
                    anchors.topMargin: -ScreenTools.defaultFontPixelWidth * 1.5
                    visible: settingButton.checked
                    property real visualHeight : visible ? height : 0
                    property variant subItemModel: openappsett()
                    sourceComponent: !settingButton.checked ? null : subItemColumnDelegate
                    onStatusChanged: if (status == Loader.Ready)
                                         item.model = subItemModel
                }

                Button {
                    id: qrCodeButton
                    width: drawer.width
                    height: _contents.height * 1.4
                    anchors.top: settingButton.checked ? settingSubItemLoader.bottom : settingButton.bottom
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth
                    checkable: true
                    visible: false
                    property bool collapsedmain: true
                    onCheckedChanged: {
                        highlighQrCode()
                        openpages()
                        collapsedmain = !collapsedmain
                    }
                    background: Rectangle {
                        id: drawerMenu7
                        height: parent.height
                        property bool highlighted: (qrCodeButton.checked)
                        property bool containsSubItem: false
                        property string text
                        property url isrc

                        color: qgcPal.window

                        Rectangle {
                            id: _backg7
                            anchors.centerIn: parent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height
                            width: parent.width
                            visible: true
                            //radius: 20
                            color: !qrCodeButton.checked?  qgcPal.window : Qt.rgba(qgcPal.buttonHighlight.r,qgcPal.buttonHighlight.g,qgcPal.buttonHighlight.b, 0.05)
                        }
                        DropShadow {
                            source: _backg7
                            color: !showBorder ? "#000000" : qgcPal.card
                            anchors.fill: _backg7
                            radius: 8
                            transparentBorder: true
                            visible: (qrCodeButton.checked)
                            verticalOffset: 0
                            spread: 0.0
                        }
                        Row {
                            id: _contents7
                            spacing: ScreenTools.defaultFontPixelWidth
                            anchors.left: drawerMenu7.left
                            anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                            anchors.verticalCenter: drawerMenu7.verticalCenter
                            Item {
                                height: ScreenTools.defaultFontPixelHeight * 3
                                width: 1
                            }
                            QGCColoredImage {
                                id: _icon7
                                height: drawer.height / 32
                                width: height * 1.30
                                sourceSize.height: parent.height
                                fillMode: Image.PreserveAspectFit
                                color: !qrCodeButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                source: "/qmlimages/qr-icon.svg"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Rectangle {
                                height: drawer.height / 25
                                width: drawer.width * 0.32
                                anchors.verticalCenter: parent.verticalCenter
                                color: Qt.rgba(0,0,0,0) // transparent
                                Label {
                                    id: _label7
                                    visible: text !== ""
                                    text: "QR code"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 1.50
                                    font.bold:      qrCodeButton.checked
                                    color: !qrCodeButton.checked? qgcPal.buttonText : qgcPal.buttonHighlight
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    } //for button7 rectangle
                } //qr code Button

            } // main column of drawer
        } //scrollview ended
    } // drawer ended

    Component {
        id: listdelegate

        Column {
            width: drawer.width

            function getget(name) {
                if (name === qsTr("Application Settings"))
                    return QGroundControl.corePlugin.settingsPages
                return null
            }

            function getgetget(name) {
                //(name)
                if (name === qsTr("Fly"))
                    return mainWindow.showFlyView
                if (name === qsTr("Plan"))
                    return mainWindow.showPlanView
                if (name === qsTr("Settings"))
                    return mainWindow.showSetupView
                if (name === qsTr("Analyze"))
                    return mainWindow.showAnalyzeView
                if (name === qsTr("Weather"))
                    return mainWindow.showWeatherView
                return null
            }

            property var subItems: getget(name)
            property var clickAction: getgetget(name)
            property var collapsed: true
            property var prevDrawerSubMenu: null

            Loader {
                id: settingSubItemLoader

                visible: !collapsed
                property variant subItemModel: subItems
                sourceComponent: collapsed ? null : subItemColumnDelegate
                onStatusChanged: if (status == Loader.Ready)
                                     item.model = subItemModel
            }
        }
    }


    Component {
        id: analyzeColumnDelegate

        Column {
            property alias model: analyzeColumnRepeater.model
            width: drawer.width
            topPadding: ScreenTools.defaultFontPixelHeight
            Repeater {
                id: analyzeColumnRepeater
                delegate: Column {

                    property bool mouseHoveranalyze: false

                    Rectangle {
                        id: analyzeColumnItem
                        height: ScreenTools.defaultFontPixelHeight * 2.5
                        width: drawer.width
                        property bool highlightedanalyzeColumn: false
//                        color: !analyzeColumnItem.highlightedanalyzeColumn? qgcPal.window : Qt.rgba(qgcPal.buttonHighlight.r,qgcPal.buttonHighlight.g,qgcPal.buttonHighlight.b, 0.3)
                        color: Qt.rgba(0,0,0,0) // transparent
                        Rectangle {
                            id: _dummyanalyze
                            anchors.left: parent.left
                            width: ScreenTools.defaultFontPixelHeight * 1.5
                        }

                        QGCColoredImage {
                            id: _dummyArrowanalyze
                            height: ScreenTools.defaultFontPixelHeight * (mouseHoveranalyze ? 0.7 : 0.5)
                            width: height * 2
                            sourceSize.height: parent.height
                            fillMode: Image.PreserveAspectFit
                            color: !analyzeColumnItem.highlightedanalyzeColumn? qgcPal.text : qgcPal.buttonHighlight
                            source: "/qmlimages/MenuDown"
                            anchors.verticalCenter: _texttanalyze.verticalCenter
                            anchors.left: _dummyanalyze.right
                            rotation: -90
                        }

                        //Analyze Tab sub-menu text settings
                        Text {
                            // Subsettings text of AppSettings
                            id: _texttanalyze
                            anchors.verticalCenter: parent.verticalCenter
                            font.pointSize: mouseHoveranalyze ? ScreenTools.defaultFontPointSize * 1.5 : ScreenTools.defaultFontPointSize * 1.4
                            font.bold: analyzeColumnItem.highlightedanalyzeColumn
                            text: modelData.title
                            anchors.left: _dummyArrowanalyze.right
                            //anchors.leftMargin: ScreenTools.mediumSmallFontPointSize * 0.5
//                            color: qgcPal.text
                            color: !analyzeColumnItem.highlightedanalyzeColumn? qgcPal.text : qgcPal.buttonHighlight
                        }

                        MouseArea {
                            function analyzeMenu() {
                                for (var i = 0; i < analyzeColumnRepeater.count; i++) {
                                    analyzeColumnRepeater.itemAt(
                                                i).children[0].highlightedanalyzeColumn = false
                                }
                            }

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                analyzeMenu()
                                analyzeColumnItem.highlightedanalyzeColumn
                                        = !analyzeColumnItem.highlightedanalyzeColumn
                                mainWindow.showSubMenu(modelData.url)
                            }
                            onEntered: mouseHoveranalyze = true
                            onExited: mouseHoveranalyze = false
                        }
                    }

                    Rectangle {
                        //line under text
                        height: ScreenTools.defaultFontPixelHeight * 0.05
                        width: drawer.width * (mouseHoveranalyze ? 0.8 : 0.7)
                        color: !showBorder ? "black" : "#ebebeb"
                        anchors.horizontalCenter: analyzeColumnItem.horizontalCenter
                    }
                }
            }
        }
    }

    Component {
        id: subItemColumnDelegate

        Column {
            property alias model: subItemRepeater.model
            width: drawer.width
            topPadding: ScreenTools.defaultFontPixelHeight

            Repeater {
                id: subItemRepeater
                delegate: Column {

                    property bool mouseHover: false

                    Rectangle {
                        id: _subMenuItem
                        height: ScreenTools.defaultFontPixelHeight * 2.5 //Rectangles for each subsetting under AppSettings
                        width: drawer.width
                        property bool highlightedSubMenu: false
                        color: Qt.rgba(0,0,0,0) // transparent
//                        color: !_subMenuItem.highlightedSubMenu? qgcPal.window : Qt.rgba(qgcPal.buttonHighlight.r,qgcPal.buttonHighlight.g,qgcPal.buttonHighlight.b, 0.3)

                        Rectangle {
                            id: _dummy
                            width: ScreenTools.defaultFontPixelHeight * 1.55
                        }

                        QGCColoredImage {
                            id: _dummyArrow
                            height: ScreenTools.defaultFontPixelHeight * (mouseHover ? 0.7 : 0.5)
                            width: height * 2
                            sourceSize.height: parent.height
                            fillMode: Image.PreserveAspectFit
                            color: !_subMenuItem.highlightedSubMenu? qgcPal.text : qgcPal.buttonHighlight
                            source: "/qmlimages/MenuDown"
                            anchors.verticalCenter: _textt.verticalCenter
                            anchors.left: _dummy.right
                            rotation: -90
                        }

                        Text {
                            // Subsettings text of AppSettings
                            id: _textt
                            anchors.verticalCenter: parent.verticalCenter
                            font.pointSize: mouseHover ? ScreenTools.defaultFontPointSize * 1.5 : ScreenTools.defaultFontPointSize * 1.5
                            font.bold: _subMenuItem.highlightedSubMenu
                            text: modelData.title
                            anchors.left: _dummyArrow.right
                            //anchors.leftMargin: ScreenTools.mediumSmallFontPointSize * 0.5

                            color: !_subMenuItem.highlightedSubMenu? qgcPal.text : qgcPal.buttonHighlight
                        }

                        MouseArea {

                            function settingsMenu() {
                                for (var i = 0; i < subItemRepeater.count; i++) {
                                    subItemRepeater.itemAt(
                                                i).children[0].highlightedSubMenu = false
                                }
                            }

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                settingsMenu()
                                _subMenuItem.highlightedSubMenu = !_subMenuItem.highlightedSubMenu
                                mainWindow.showSubMenu(modelData.url)
                            }
                            onEntered: mouseHover = true
                            onExited: mouseHover = false
                        }
                    }

                    Rectangle {
                        //line under text
                        height: ScreenTools.defaultFontPixelHeight * 0.05
                        width: drawer.width * (mouseHover ? 0.8 : 0.7)

                        color: !showBorder ? "black" : "#ebebeb"
                        anchors.horizontalCenter: _subMenuItem.horizontalCenter
                    }
                }
            }
        }
    }

    Component {
        id: setupColumnDelegate //subItemColumnDelegate2
        Column {

            width: drawer.width

            Column {
                id: setupbutton1

                property bool mouseHoversetup1: false

                Rectangle {
                    id: setupColumnItem1
                    height: ScreenTools.defaultFontPixelHeight * 2.5
                    width: drawer.width
                    property bool highlightedsetupColumn1: false

                    color: highlightedsetupColumn1 ? "#f9f9fa" : "white"

                    Rectangle {
                        id: _dummysetup1
                        width: ScreenTools.defaultFontPixelHeight * 1.5
                    }

                    QGCColoredImage {
                        id: _dummyArrowsetup1
                        height: ScreenTools.defaultFontPixelHeight
                                * (setupbutton1.mouseHoversetup1 ? 0.7 : 0.5)
                        width: height * 2
                        sourceSize.height: parent.height
                        fillMode: Image.PreserveAspectFit

                        color: qgcPal.buttonText
                        source: "/qmlimages/MenuDown"
                        anchors.verticalCenter: _texttsetup1.verticalCenter
                        anchors.left: _dummysetup1.right
                        rotation: -90
                    }

                    Text {
                        id: _texttsetup1
                        anchors.verticalCenter: parent.verticalCenter
                        font.pointSize: setupbutton1.mouseHoversetup1 ? ScreenTools.defaultFontPointSize * 1.35 : ScreenTools.defaultFontPointSize * 1.35
                        font.bold: setupColumnItem1.highlightedsetupColumn1
                        text: "Summary"
                        anchors.left: _dummyArrowsetup1.right
                        //anchors.leftMargin: ScreenTools.mediumSmallFontPointSize * 0.5
                        color: "#1b1a1d"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            setupColumnItem1.highlightedsetupColumn1
                                    = !setupColumnItem1.highlightedsetupColumn1
                            setupViewmaintool.showSummaryPanelMain()
                        }
                        onEntered: setupbutton1.mouseHoversetup1
                        onExited: setupbutton1.mouseHoversetup1
                    }
                }

                Rectangle {
                    //line under text
                    height: ScreenTools.defaultFontPixelHeight * 0.05
                    width: drawer.width * (setupbutton1.mouseHoversetup1 ? 0.8 : 0.7)
                    color: "#ebebeb"
                    anchors.horizontalCenter: setupColumnItem1.horizontalCenter
                }
            } //button 1

            Column {
                id: setupbutton2

                property bool mouseHoversetup2: false
                visible: !ScreenTools.isMobile
                         && QGroundControl.corePlugin.options.showFirmwareUpgrade

                Rectangle {
                    id: setupColumnItem2
                    height: ScreenTools.defaultFontPixelHeight * 2.5
                    width: drawer.width
                    property bool highlightedsetupColumn2: false
                    color: highlightedsetupColumn2 ? "#f9f9fa" : "white"

                    Rectangle {
                        id: _dummysetup2
                        width: ScreenTools.defaultFontPixelHeight * 1.5
                    }

                    QGCColoredImage {
                        id: _dummyArrowsetup2
                        height: ScreenTools.defaultFontPixelHeight
                                * (setupbutton2.mouseHoversetup2 ? 0.7 : 0.5)
                        width: height * 2
                        sourceSize.height: parent.height
                        fillMode: Image.PreserveAspectFit

                        color: qgcPal.buttonText
                        source: "/qmlimages/MenuDown"
                        anchors.verticalCenter: _texttsetup2.verticalCenter
                        anchors.left: _dummysetup2.right
                        rotation: -90
                    }

                    Text {
                        // Subsettings text of AppSettings
                        id: _texttsetup2
                        anchors.verticalCenter: parent.verticalCenter
                        font.pointSize: setupbutton2.mouseHoversetup2 ? ScreenTools.defaultFontPointSize * 1.35 : ScreenTools.defaultFontPointSize * 1.35
                        font.bold: setupColumnItem2.highlightedsetupColumn2
                        text: "Firmware"
                        anchors.left: _dummyArrowsetup2.right
                       // anchors.leftMargin: ScreenTools.mediumSmallFontPointSize * 0.5
                        color: "#1b1a1d"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            setupColumnItem2.highlightedsetupColumn2
                                    = !setupColumnItem2.highlightedsetupColumn2
                            setupViewmaintool.showPanelMain(
                                        "FirmwareUpgrade.qml")
                        }
                        onEntered: setupbutton2.mouseHoversetup2 = true
                        onExited: setupbutton2.mouseHoversetup2 = false
                    }
                }

                Rectangle {
                    //line under text
                    height: ScreenTools.defaultFontPixelHeight * 0.05
                    width: drawer.width * (setupbutton2.mouseHoversetup2 ? 0.8 : 0.7)
                    color: "#ebebeb"
                    anchors.horizontalCenter: setupColumnItem2.horizontalCenter
                }
            } //button 2

            Column {
                id: setupbutton3
                visible: QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle.priorityLink.isPX4Flow : false

                property bool mouseHoversetup3: false

                Rectangle {
                    id: setupColumnItem3
                    height: ScreenTools.defaultFontPixelHeight * 2.5 //Rectangles for each subsetting under AppSettings
                    width: drawer.width
                    property bool highlightedsetupColumn3: false
                    color: highlightedsetupColumn3 ? "#f9f9fa" : "white"

                    Rectangle {
                        id: _dummysetup3
                        width: ScreenTools.defaultFontPixelHeight * 1.5
                    }

                    QGCColoredImage {
                        id: _dummyArrowsetup3
                        height: ScreenTools.defaultFontPixelHeight
                                * (setupbutton3.mouseHoversetup3 ? 0.7 : 0.5)
                        width: height * 2
                        sourceSize.height: parent.height
                        fillMode: Image.PreserveAspectFit

                        color: qgcPal.buttonText
                        source: "/qmlimages/MenuDown"
                        anchors.verticalCenter: _texttsetup3.verticalCenter
                        anchors.left: _dummysetup3.right
                        rotation: -90
                    }

                    Text {
                        // Subsettings text of AppSettings
                        id: _texttsetup3
                        anchors.verticalCenter: parent.verticalCenter
                        font.pointSize: setupbutton3.mouseHoversetup2 ? ScreenTools.defaultFontPointSize * 1.35 : ScreenTools.defaultFontPointSize * 1.35
                        font.bold: setupColumnItem3.highlightedsetupColumn3
                        text: "PX4Flow"
                        anchors.left: _dummyArrowsetup3.right
                       //anchors.leftMargin: ScreenTools.mediumSmallFontPointSize * 0.5
                        color: "#1b1a1d"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            setupColumnItem3.highlightedsetupColumn3
                                    = !setupColumnItem3.highlightedsetupColumn3
                            setupViewmaintool.showPanelMain("PX4FlowSensor.qml")
                        }
                        onEntered: setupbutton3.mouseHoversetup3 = true
                        onExited: setupbutton3.mouseHoversetup3 = false
                    }
                }

                Rectangle {
                    //line under text
                    height: ScreenTools.defaultFontPixelHeight * 0.05
                    width: drawer.width * (setupbutton3.mouseHoversetup3 ? 0.8 : 0.7)
                    color: "#ebebeb"
                    anchors.horizontalCenter: setupColumnItem3.horizontalCenter
                }
            } //button 3

            Column {
                id: setupbutton4
                visible: QGroundControl.multiVehicleManafger.parameterReadyVehicleAvailable
                         && !QGroundControl.multiVehicleManager.activeVehicle.parameterManager.missingParameters
                         && joystickManager.joysticks.length !== 0
                property bool mouseHoversetup4: false

                Rectangle {
                    id: setupColumnItem4
                    height: ScreenTools.defaultFontPixelHeight
                            * 2.5
                    width: drawer.width
                    property bool highlightedsetupColumn4: false
                    color: highlightedsetupColumn4 ? "#f9f9fa" : "white"

                    Rectangle {
                        id: _dummysetup4
                        width: ScreenTools.defaultFontPixelHeight * 1.5
                    }

                    QGCColoredImage {
                        id: _dummyArrowsetup4
                        height: ScreenTools.defaultFontPixelHeight
                                * (setupbutton4.mouseHoversetup4 ? 0.7 : 0.5)
                        width: height * 2
                        sourceSize.height: parent.height
                        fillMode: Image.PreserveAspectFit

                        color: qgcPal.buttonText
                        source: "/qmlimages/MenuDown"
                        anchors.verticalCenter: _texttsetup4.verticalCenter
                        anchors.left: _dummysetup4.right
                        rotation: -90
                    }

                    Text {
                        // Subsettings text of AppSettings
                        id: _texttsetup4
                        anchors.verticalCenter: parent.verticalCenter
                        font.pointSize: setupbutton4.mouseHoversetup4 ? ScreenTools.defaultFontPointSize * 1.35 : ScreenTools.defaultFontPointSize * 1.35 //changed from ScreenTools.mediumSmallFontPointSize *1.5 on both
                        font.bold: setupColumnItem4.highlightedsetupColumn4
                        text: "Joystick"
                        anchors.left: _dummyArrowsetup4.right
                       // anchors.leftMargin: ScreenTools.mediumSmallFontPointSize * 0.5
                        color: "#1b1a1d"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            setupColumnItem4.highlightedsetupColumn4
                                    = !setupColumnItem4.highlightedsetupColumn4
                            setupViewmaintool.showPanelMain(
                                        "JoystickConfig.qml")
                        }
                        onEntered: setupbutton4.mouseHoversetup4 = true
                        onExited: setupbutton4.mouseHoversetup4 = false
                    }
                }

                Rectangle {
                    //line under text
                    height: ScreenTools.defaultFontPixelHeight * 0.05
                    width: drawer.width * (setupbutton4.mouseHoversetup4 ? 0.8 : 0.7)
                    color: "#ebebeb"
                    anchors.horizontalCenter: setupColumnItem4.horizontalCenter
                }
            } //button 4

            Column {
                id: setupbutton5
                visible: QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable
                         && !QGroundControl.multiVehicleManager.activeVehicle.highLatencyLink
                         && QGroundControl.corePlugin.showAdvancedUI
                property bool mouseHoversetup5: false

                Rectangle {
                    id: setupColumnItem5
                    height: ScreenTools.defaultFontPixelHeight
                            * 2.5
                    width: drawer.width
                    property bool highlightedsetupColumn5: false
                    color: highlightedsetupColumn5 ? "#f9f9fa" : "white"

                    Rectangle {
                        id: _dummysetup5
                        width: ScreenTools.defaultFontPixelHeight * 1.5
                    }

                    QGCColoredImage {
                        id: _dummyArrowsetup5
                        height: ScreenTools.defaultFontPixelHeight
                                * (setupbutton5.mouseHoversetup5 ? 0.7 : 0.5)
                        width: height * 2
                        sourceSize.height: parent.height
                        fillMode: Image.PreserveAspectFit


                        color: qgcPal.buttonText
                        source: "/qmlimages/MenuDown"
                        anchors.verticalCenter: _texttsetup5.verticalCenter
                        anchors.left: _dummysetup5.right
                        rotation: -90
                    }

                    Text {

                        id: _texttsetup5
                        anchors.verticalCenter: parent.verticalCenter
                        font.pointSize: setupbutton5.mouseHoversetup5 ? ScreenTools.defaultFontPointSize * 1.35 : ScreenTools.defaultFontPointSize * 1.35
                        font.bold: setupColumnItem5.highlightedsetupColumn5
                        text: "Parameters"
                        anchors.left: _dummyArrowsetup5.right
                       // anchors.leftMargin: ScreenTools.mediumSmallFontPointSize * 0.5
                        color: "#1b1a1d"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            setupColumnItem5.highlightedsetupColumn5
                                    = !setupColumnItem5.highlightedsetupColumn5
                            setupViewmaintool.showPanelMain(
                                        "SetupParameterEditor.qml")
                        }
                        onEntered: setupbutton5.mouseHoversetup5 = true
                        onExited: setupbutton5.mouseHoversetup5 = false
                    }
                }

                Rectangle {
                    //line under text
                    height: ScreenTools.defaultFontPixelHeight * 0.05
                    width: drawer.width * (setupbutton5.mouseHoversetup5 ? 0.8 : 0.7)
                    color: "#ebebeb"
                    anchors.horizontalCenter: setupColumnItem5.horizontalCenter
                }
            } //button 5

            //}// repeater ends
        } //outer setup column
    } //setupColumnDelegate

    ListModel {
        id: listModel

        ListElement {
            name: qsTr("Application Settings")
            src: "/qmlimages/Gears.svg"
            listindex: 1
            ischeck: false
        }

        ListElement {
            name: qsTr("Fly")
            src: "/qmlimages/PaperPlane.svg"
            listindex: 2
            ischeck: false
        }

        ListElement {
            name: qsTr("Plan")
            src: "/qmlimages/Plan.svg"
            listindex: 3
            ischeck: false
        }

        ListElement {
            name: qsTr("Analyze")
            src: "/qmlimages/Analyze.svg"
            listindex: 4
            ischeck: false
        }

        ListElement {
            name: qsTr("Settings")
            src: "/qmlimages/Gears.svg"
            listindex: 5
            ischeck: false
        }

        ListElement {
            name: qsTr("Weather")
            src: "/qmlimages/Gears.svg"
            listindex: 6
            ischeck: false
        }
    }



}
