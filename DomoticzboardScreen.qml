import QtQuick 2.1
import SimpleXmlListModel 1.0
import qb.components 1.0
import qb.base 1.0

Screen {
	id: root
	
	screenTitleIconUrl: "qrc:/tsc/DomoticzSystrayIcon.png"
	screenTitle: "DomoticzBoard"
	property bool domoticzSwitchesLoaded : false
	property int currentIndex : -1
	property bool blockDimmerControls : false

	// Function (triggerd by a signal) updates the newsreader list model and the header text
	function updateDomoticzList() {
		if (app.domoticzSwitchesData.length > 0) {
			// Update the domoticz list model
			currentIndex = domoticzSimpleSwitchesList.dataIndex;
			switchesModel.clear();
			switchesModel.xml = app.domoticzSwitchesData;
			domoticzSimpleSwitchesList.initialView();
			if (!app.firstTimeShown) {
				domoticzSimpleSwitchesList.selectItem(currentIndex);
			}
		}
		if (app.domoticzScenesData.length > 0) {
			// Update the domoticz list model
			currentIndex = domoticzSimpleScenesList.dataIndex;
			scenesModel.clear();
			scenesModel.xml = app.domoticzScenesData;
			domoticzSimpleScenesList.initialView();
			domoticzSimpleScenesList.initialView();
			if (!app.firstTimeShown) {
				domoticzSimpleScenesList.selectItem(currentIndex);
			}
		}
		domoticzSwitchesLoaded = true;
		app.firstTimeShown = false;		
	}
	
	function newItemSelected(index) {
		currentIndex = index;
	}

	//settings screen
	onShown: {
		addCustomTopRightButton("Instellingen");
		if (app.connectionPath.length < 5) {
			 app.domoticzSettings.show();
		}
	}

	Component.onCompleted: {
		app.domoticzUpdated.connect(updateDomoticzList)
	}

	onCustomButtonClicked: {
		if (app.domoticzSettings) {
			 app.domoticzSettings.show();
		}
	}

	function simpleSynchronous(request) {
		var xmlhttp = new XMLHttpRequest();
		xmlhttp.open("GET", request, true);
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					app.refreshScreen();
				}
			}
		}
		xmlhttp.send();
	}

	Item {
		id: header
		height: isNxt ? 55 : 45
		width: parent.width

		Text {
			id: headerText
			text: "Schakelaars:"
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 25 : 20
			anchors {
				left: parent.left
				leftMargin: isNxt ? 25 : 20
				bottom: parent.bottom
			}
		}

		Text {
			id: headerText2
			text: "Groepen/Scenes:"
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 25 : 20
			visible: app.showScenes
			anchors {
				left: parent.left
				leftMargin: isNxt ? 555 : 444
				bottom: parent.bottom
			}
		}

		IconButton {
			id: refreshButton
			anchors.right: parent.right
			anchors.rightMargin: isNxt ? 15 : 12
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 5
			leftClickMargin: 3
			bottomClickMargin: 5
			iconSource: "qrc:/tsc/refresh.svg"
			onClicked: app.refreshScreen()
		}
	}
	Rectangle {
		id: content
		width: isNxt ? (app.showScenes ? 500 : 932) : (app.showScenes ? 400 : 732)
		height: isNxt ? 468 : 370
		anchors.top: header.bottom
		anchors.left: header.left
		anchors.leftMargin: isNxt ? 25 : 20

		DomoticzSimpleList { 
			id: domoticzSimpleSwitchesList
			columnsPerPage: app.showScenes ? 1 : 2
			delegate: Rectangle
			{
				width: isNxt ? 425 : 325
				height: isNxt ? 58 : 44

				Text {
					id: txtName
					text: name
					font.pixelSize: isNxt ? 20 : 16
					font.family: qfont.bold.name
					color: colors.clockTileColor
					anchors {
						top: parent.top
						topMargin: isNxt ? 15 : 12
						left: parent.left
						leftMargin: 5
					}
				}
			       MouseArea {
       					id: selectForTile
				       anchors.fill: parent
					onClicked: {
						app.switch2Name = app.switch1Name;
						app.switch1Name = name;
						app.switch2Idx = app.switch1Idx;
						app.switch1Idx = idx;
						app.switch2Status = app.switch1Status;
						app.switch1Status = status;
						app.switch2Type = app.switch1Type;
						app.switch1Type = "Light";
						app.saveSettings();
					}
				}
				OnOffToggle {
					id: showSwitchToggle
					height: 36
				        anchors {
						top: parent.top
						topMargin: isNxt ? 15 : 12
						right: parent.right
						rightMargin : 3
				        }
					isSwitchedOn: (status == "On")
					onSelectedChangedByUser: {
						if (status == "On") {
							status = "Off";
							simpleSynchronous("http://"+app.connectionPath+"/json.htm?type=command&param=switchlight&idx="+idx+"&switchcmd=Off");
						} else {
							status = "On";
							simpleSynchronous("http://"+app.connectionPath+"/json.htm?type=command&param=switchlight&idx="+idx+"&switchcmd=On");
						}
					}
				}

				StandardButton {
					id: plusDimmer
					width: isNxt ? 35 : 28
					height: isNxt ? 35 : 28
					text: "+"
					anchors.right: showSwitchToggle.left
					anchors.top: parent.top
					anchors.topMargin: isNxt ? 10 : 8
					anchors.rightMargin: 10
//					leftClickMargin: 3
//					bottomClickMargin: 5
					onClicked: {
						var newDimStep = parseInt(dimlevel) + (parseInt(maxdimlevel) / 10);
						if (newDimStep > parseInt(maxdimlevel)) {
							 newDimStep = parseInt(maxdimlevel);
						}
						blockDimmerControls = true;
						simpleSynchronous("http://"+app.connectionPath+"/json.htm?type=command&param=switchlight&idx=" + idx + "&switchcmd=Set%20Level&level=" + newDimStep);
						pause1Second.start();
					}
					visible: (switchtype == "Dimmer" && !blockDimmerControls)
				}

				Text {
					id: txtDimmerValue
					width: isNxt ? 35 : 28
					text: dimlevel
					font.pixelSize: isNxt ? 20 : 16
					font.family: qfont.bold.name
					color: colors.clockTileColor
					anchors {
						top: parent.top
						topMargin: isNxt ? 15 : 12
						right: plusDimmer.left
						rightMargin: 5
					}
					visible: (switchtype == "Dimmer")
				}

				StandardButton {
					id: minDimmer
					width: isNxt ? 35 : 28
					height: isNxt ? 35 : 28
					text: "-"
					anchors.right: txtDimmerValue.left
					anchors.top: parent.top
					anchors.topMargin: isNxt ? 10 : 8
					anchors.rightMargin: 10
//					leftClickMargin: 3
//					bottomClickMargin: 5
					onClicked: {
						var newDimStep = parseInt(dimlevel) - (parseInt(maxdimlevel) / 10);
						if (newDimStep < 0) {
							 newDimStep = 0;
						}
						blockDimmerControls = true;
						simpleSynchronous("http://"+app.connectionPath+"/json.htm?type=command&param=switchlight&idx=" + idx + "&switchcmd=Set%20Level&level=" + newDimStep);
						pause1Second.start();
					}
					visible: (switchtype == "Dimmer" && !blockDimmerControls)
				}

			}

			dataModel: switchesModel
			itemHeight: isNxt ? 60 : 46
			itemsPerPage: app.showScenes ? 7 : 14
			anchors.top: content.top
			downIcon: "qrc:/tsc/arrowScrolldown.png"
			buttonsHeight: isNxt ? 180 : 144
			buttonsVisible: true
			scrollbarVisible: true
		}

		Throbber {
			id: refreshThrobber
			anchors.centerIn: parent
			visible: !domoticzSwitchesLoaded
		}
	}

	SimpleXmlListModel {
		id: switchesModel
		query: "/domoticz/item"
		roles: ({
			idx: "string",
			name: "string",
			status: "string",
			switchtype: "string",
			maxdimlevel: "string",
			levelint: "string",
			dimlevel: "string"
		})
	}

	Rectangle {
		id: content2
		width: isNxt ? 453 : 360
		height: isNxt ? 468 : 370
		anchors.top: header.bottom
		anchors.right: header.right
		anchors.rightMargin: isNxt ? 15 : 12
		visible: app.showScenes

		DomoticzSimpleList {
			id: domoticzSimpleScenesList
			columnsPerPage: 1
			delegate: Rectangle
			{
				width: isNxt ? 375 : 282
				height: isNxt ? 58 : 44

				Text {
					id: txtName
					text: name
					font.pixelSize: isNxt ? 20 : 16
					font.family: qfont.bold.name
					color: colors.clockTileColor
					anchors {
						top: parent.top
						topMargin: isNxt ? 15 : 12
						left: parent.left
						leftMargin: 5
					}
				}
			       MouseArea {
       					id: selectForTile
				       anchors.fill: parent
					onClicked: {
						app.switch2Name = app.switch1Name;
						app.switch1Name = name;
						app.switch2Idx = app.switch1Idx;
						app.switch1Idx = idx;
						app.switch2Status = app.switch1Status;
						app.switch1Status = status;
						app.switch2Type = app.switch1Type;
						app.switch1Type = "Scene";
						app.saveSettings();
					}
				}

				OnOffToggle {
					id: showSceneToggle
					height: 36
				        anchors {
						top: parent.top
						topMargin: isNxt ? 15 : 12
						right: parent.right
						rightMargin : 3
				        }
					isSwitchedOn: (status == "On")
					onSelectedChangedByUser: {
						if (status == "On") {
							status = "Off";
						} else {
							status = "On";
						}
						simpleSynchronous("http://"+app.connectionPath+"/json.htm?type=command&param=switchscene&idx="+idx+"&switchcmd=Toggle");
					}
				}
			}

			dataModel: scenesModel
			itemHeight: isNxt ? 60 : 46
			itemsPerPage: 7
			anchors.top: content2.top
			downIcon: "qrc:/tsc/arrowScrolldown.png"
			buttonsHeight: isNxt ? 180 : 144
			buttonsVisible: true
			scrollbarVisible: true
		}

		Throbber {
			id: refreshThrobber2
			anchors.centerIn: parent
			visible: !domoticzSwitchesLoaded
		}
	}

	SimpleXmlListModel {
		id: scenesModel
		query: "/domoticz/item"
		roles: ({
			idx: "string",
			name: "string",
			status: "string"
		})
	}

	Timer {
		id: pause1Second
		interval: 1000
		running: false
		repeat: false
		onTriggered: blockDimmerControls = false
	}
}