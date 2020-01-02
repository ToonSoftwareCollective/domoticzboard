import QtQuick 2.1
import qb.components 1.0
import qb.base 1.0;
import FileIO 1.0

App {
	id: root

	property url trayUrl : "DomoticzboardTray.qml";
	property url thumbnailIcon: "qrc:/tsc/DomoticzSystrayIcon.png"
	property url menuScreenUrl : "DomoticzboardSettings.qml"
	property url domoticzScreenUrl : "DomoticzboardScreen.qml"
	property url domoticzTileUrl : "DomoticzboardTile.qml"
	property DomoticzboardSettings domoticzSettings
	property DomoticzboardScreen domoticzScreen

	property SystrayIcon domoticzTray
	property bool showDBIcon : true
	property bool showDummies : true
	property bool showFavourites : true
	property bool showScenes : true
	property variant domoticzConfigJSON

	// Domoticz data in XML string format
	property string domoticzSwitchesData			// input for xml model
	property string domoticzScenesData
	property bool domoticzDataRead: false
	
	property string timeStr
	property string dateStr
	property string connectionPath
	property string ipadres
	property string poortnummer : "8080"

	property string switch1Name	
	property string switch1Idx : "*" 	
	property string switch1Status	
	property string switch1Type	
	property string switch1Option	
	property string switch2Name	
	property string switch2Idx : "*" 	
	property string switch2Status	
	property string switch2Type	
	property string switch2Option	

	property bool firstTimeShown : true

	property string tilebulb_offvar: "qrc:/tsc/TileLightBulbOff.png";
	property string tilebulb_onvar: "qrc:/tsc/TileLightBulbOn.png";
	property string dimtilebulb_offvar: "qrc:/tsc/DimTileLightBulbOff.png";
	property string dimtilebulb_onvar: "qrc:/tsc/DimTileLightBulbOn.png";
	property string bulb_offvar: "qrc:/tsc/LightBulbOff.png";
	property string bulb_onvar: "qrc:/tsc/LightBulbOn.png";
	property string group_offvar: "qrc:/tsc/LightBulbOff.png";
	property string group_onvar: "qrc:/tsc/LightBulbOn.png";

	// user settings from config file
	property variant userSettingsJSON : {
		'connectionPath': [],
		'ShowTrayIcon': "",
		'ShowFavourites': "",
		'ShowDummies': ""
	}

	FileIO {
		id: userSettingsFile
		source: "file:///mnt/data/tsc/domoticzboard.userSettings.json"
 	}

	// Domoticz signals, used to update the listview and filter enabled button
	signal domoticzUpdated()

	function init() {
		registry.registerWidget("systrayIcon", trayUrl, this, "domoticzTray");
		registry.registerWidget("screen", domoticzScreenUrl, this, "domoticzScreen");
		registry.registerWidget("screen", menuScreenUrl, this, "domoticzSettings");
		registry.registerWidget("menuItem", null, this, null, {objectName: "DBMenuItem", label: qsTr("DB-settings"), image: thumbnailIcon, screenUrl: menuScreenUrl, weight: 120});
		registry.registerWidget("tile", domoticzTileUrl, this, null, {thumbLabel: "Domoticz", thumbIcon: thumbnailIcon, thumbCategory: "general", thumbWeight: 30, baseTileWeight: 10, thumbIconVAlignment: "center"});
	}

	//this function needs to be started after the app is booted.
	Component.onCompleted: {

		// read user settings

		try {
			userSettingsJSON = JSON.parse(userSettingsFile.read());
			showDBIcon  = (userSettingsJSON['ShowTrayIcon'] == "yes") ? true : false
			showFavourites = (userSettingsJSON['ShowFavourites'] == "yes") ? true : false
			showDummies = (userSettingsJSON['ShowDummies'] == "yes") ? true : false
			switch1Idx = (userSettingsJSON['TileIdx1']) ? userSettingsJSON['TileIdx1'] : "*"
			switch2Idx = (userSettingsJSON['TileIdx2']) ? userSettingsJSON['TileIdx2'] : "*"
			switch1Type = (userSettingsJSON['TileType1']) ? userSettingsJSON['TileType1'] : "*"
			switch2Type = (userSettingsJSON['TileType2']) ? userSettingsJSON['TileType2'] : "*"
			connectionPath = userSettingsJSON['connectionPath'];
			var splitVar = connectionPath.split(":")
			ipadres = splitVar[0];
			poortnummer = splitVar[1];
			if (poortnummer.length < 2) poortnummer = "8080";		
			showScenes = (userSettingsJSON['ShowScenes']) ? userSettingsJSON['ShowScenes'] : true
		} catch(e) {
		}

		datetimeTimer.start();
	}

	function refreshScreen() {
		domoticzDataRead = false;
		readDomoticzConfig();
	}

	function a2b(a) {
  		var b, c, d, e = {}, f = 0, g = 0, h = "", i = String.fromCharCode, j = a.length;
  		for (b = 0; 64 > b; b++) e["ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".charAt(b)] = b;
  		for (c = 0; j > c; c++) for (b = e[a.charAt(c)], f = (f << 6) + b, g += 6; g >= 8; ) ((d = 255 & f >>> (g -= 8)) || j - 2 > c) && (h += i(d));
  		return h;
	}

	function convertToXML() {

			// init XML output
		domoticzSwitchesData = "<domoticz>";
		domoticzScenesData = "<domoticz>";

			// get light switches from config
		for (var i = 0; i < domoticzConfigJSON["result"].length; i++) {	
				// [Type] = Group
			if (((domoticzConfigJSON["result"][i]["Type"] == "Group") || (domoticzConfigJSON["result"][i]["Type"] == "Scene")) && showScenes) {
				if (!(showFavourites) || (domoticzConfigJSON["result"][i]["Favorite"] == 1)) {
					domoticzScenesData = domoticzScenesData + "<item><idx>" + domoticzConfigJSON["result"][i]["idx"] + "</idx><name>" + domoticzConfigJSON["result"][i]["Name"] + "</name><status>" + domoticzConfigJSON["result"][i]["Status"] + "</status></item>";

						// file Tile values
					if ((domoticzConfigJSON["result"][i]["idx"] == switch1Idx) && (switch1Type == "Scene")) {
						switch1Name = domoticzConfigJSON["result"][i]["Name"];
						switch1Status = domoticzConfigJSON["result"][i]["Status"];
					}
					if ((domoticzConfigJSON["result"][i]["idx"] == switch2Idx) && (switch2Type == "Scene")) {
						switch2Name = domoticzConfigJSON["result"][i]["Name"];
						switch2Status = domoticzConfigJSON["result"][i]["Status"];
					}
				}
			}
				// [Type] starting with "Light"
			if (domoticzConfigJSON["result"][i]["Type"].substring(0,5) == "Light") {
					// [Type] ignore slave devices
				if (domoticzConfigJSON["result"][i]["IsSubDevice"] !== true) {
						// [Type] filter only "On/off" devices
					if (domoticzConfigJSON["result"][i]["SwitchType"]) {
						if ((domoticzConfigJSON["result"][i]["SwitchType"] == "On/Off") || (domoticzConfigJSON["result"][i]["SwitchType"] == "Dimmer") || (domoticzConfigJSON["result"][i]["SwitchType"] == "Selector")) {
								// filter favourites if needed
							if (!(showFavourites) || (domoticzConfigJSON["result"][i]["Favorite"] == 1)) {

									// determine status for dimmers
								
								var tmpStatus = domoticzConfigJSON["result"][i]["Status"];
								if (domoticzConfigJSON["result"][i]["SwitchType"] == "Dimmer") {
									if (domoticzConfigJSON["result"][i]["Status"] == "Off") {
										tmpStatus = "Off"
									} else {
										tmpStatus = "On"
									}
								}

									// determine status for selectors
								
								var tmpLevelNames = [];
								var tmpOption = "";
								if (domoticzConfigJSON["result"][i]["SwitchType"] == "Selector") {
									var tmpNames = a2b(domoticzConfigJSON["result"][i]["LevelNames"]);
									tmpLevelNames = tmpNames.split("|");
									if (domoticzConfigJSON["result"][i]["Status"] == "Off") {
										tmpStatus = "Off"
									} else {
										tmpStatus = "On";
									}
									tmpOption = tmpLevelNames[domoticzConfigJSON["result"][i]["Level"] / 10];
								}

									// filter dummies if needed
								if (showDummies || (domoticzConfigJSON["result"][i]["HardwareType"].substring(0,5) !== "Dummy")) {
									domoticzSwitchesData = domoticzSwitchesData + "<item><idx>" + domoticzConfigJSON["result"][i]["idx"] + "</idx><name>" + domoticzConfigJSON["result"][i]["Name"] + "</name><status>" + tmpStatus + "</status><switchtype>" + domoticzConfigJSON["result"][i]["SwitchType"] + "</switchtype><maxdimlevel>" + domoticzConfigJSON["result"][i]["MaxDimLevel"] + "</maxdimlevel><dimlevelint>" + domoticzConfigJSON["result"][i]["LevelInt"] + "</dimlevelint><dimlevel>" + domoticzConfigJSON["result"][i]["Level"] + "</dimlevel><levelnames>" + tmpLevelNames.toString() + "</levelnames></item>";
								}

									// file Tile values
								if ((domoticzConfigJSON["result"][i]["idx"] == switch1Idx) && (switch1Type == "Light")) {
									switch1Name = domoticzConfigJSON["result"][i]["Name"];
									switch1Status = tmpStatus;
									switch1Option = tmpOption;
								}
								if ((domoticzConfigJSON["result"][i]["idx"] == switch2Idx) && (switch2Type == "Light")) {
									switch2Name = domoticzConfigJSON["result"][i]["Name"];
									switch2Status = tmpStatus;
									switch2Option = tmpOption;
								}
							}
						}
					}
				}
			}

		}
		domoticzSwitchesData = domoticzSwitchesData + "</domoticz>";
		domoticzScenesData = domoticzScenesData + "</domoticz>";
		domoticzDataRead = true;
		domoticzUpdated();
		domoticzConfigJSON = JSON.parse("{}"); 
	}


	function saveSettings(){

		// save user settings
		connectionPath = ipadres + ":" + poortnummer;

 		var tmpUserSettingsJSON = {
			"connectionPath" : ipadres + ":" + poortnummer,
			"ShowTrayIcon" : (showDBIcon) ? "yes" : "no",
			"ShowFavourites" : (showFavourites) ? "yes" : "no",
			"ShowDummies" : (showDummies) ? "yes" : "no",
			"ShowScenes" : (showScenes) ? "yes" : "no",
			"TileIdx1" : switch1Idx,
			"TileIdx2" : switch2Idx,
			"TileType1" : switch1Type,
			"TileType2" : switch2Type
		}

  		var doc3 = new XMLHttpRequest();
   		doc3.open("PUT", "file:///mnt/data/tsc/domoticzboard.userSettings.json");
   		doc3.send(JSON.stringify(tmpUserSettingsJSON));
	}

	function readDomoticzConfig() {

		var xmlhttp = new XMLHttpRequest();
		xmlhttp.onreadystatechange=function() {
			if (xmlhttp.readyState == 4) {
				if (xmlhttp.status == 200) {
					domoticzConfigJSON = JSON.parse(xmlhttp.responseText); 
					convertToXML();
				}
			}
		}
		xmlhttp.open("GET", "http://"+connectionPath+"/json.htm?type=devices&filter=all&used=true&order=Name", true);
//		xmlhttp.open("GET", "http://127.0.0.1/hdrv_zwave/domoticzconfig.txt", true);
		xmlhttp.send();
	}
	
	Timer {
		id: datetimeTimer
		interval: isNxt ? 15000 : 60000
		running: false
		repeat: true
		onTriggered: refreshScreen()
	}
}
