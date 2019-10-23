import QtQuick 1.1
import qb.components 1.0
import qb.base 1.0;
import FileIO 1.0

App {
	id: root

	property url trayUrl : "DomoticzboardTray.qml";
	property url thumbnailIcon: "./drawables/DomoticzSystrayIcon.png"
	property url menuScreenUrl : "DomoticzboardSettings.qml"
	property url domoticzScreenUrl : "DomoticzboardScreen.qml"
	property url domoticzTileUrl : "DomoticzboardTile.qml"
	property DomoticzboardSettings domoticzSettings
	property DomoticzboardScreen domoticzScreen

	property SystrayIcon domoticzTray
	property bool showDBIcon : true
	property bool showDummies : true
	property bool showFavourites : true
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
	property string switch2Name	
	property string switch2Idx : "*" 	
	property string switch2Status	
	property string switch2Type	

	property bool firstTimeShown : true

	property string tilebulb_offvar: "./drawables/TileLightBulbOff.png";
	property string tilebulb_onvar: "./drawables/TileLightBulbOn.png";
	property string dimtilebulb_offvar: "./drawables/DimTileLightBulbOff.png";
	property string dimtilebulb_onvar: "./drawables/DimTileLightBulbOn.png";
	property string bulb_offvar: "./drawables/LightBulbOff.png";
	property string bulb_onvar: "./drawables/LightBulbOn.png";
	property string group_offvar: "./drawables/LightBulbOff.png";
	property string group_onvar: "./drawables/LightBulbOn.png";

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
		} catch(e) {
		}

		datetimeTimer.start();
	}

	function refreshScreen() {
		domoticzDataRead = false;
		readDomoticzConfig();
	}

	function convertToXML() {

			// init XML output
		domoticzSwitchesData = "<domoticz>";
		domoticzScenesData = "<domoticz>";

			// get light switches from config
		for (var i = 0; i < domoticzConfigJSON["result"].length; i++) {	
				// [Type] = Group
			if ((domoticzConfigJSON["result"][i]["Type"] == "Group") || (domoticzConfigJSON["result"][i]["Type"] == "Scene")) {
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
						if ((domoticzConfigJSON["result"][i]["SwitchType"] == "On/Off") || (domoticzConfigJSON["result"][i]["SwitchType"] == "Dimmer")) {
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

									// filter dummies if needed
								if (showDummies || (domoticzConfigJSON["result"][i]["HardwareType"].substring(0,5) !== "Dummy")) {
									domoticzSwitchesData = domoticzSwitchesData + "<item><idx>" + domoticzConfigJSON["result"][i]["idx"] + "</idx><name>" + domoticzConfigJSON["result"][i]["Name"] + "</name><status>" + tmpStatus + "</status><switchtype>" + domoticzConfigJSON["result"][i]["SwitchType"] + "</switchtype><maxdimlevel>" + domoticzConfigJSON["result"][i]["MaxDimLevel"] + "</maxdimlevel><dimlevel>" + domoticzConfigJSON["result"][i]["Level"] + "</dimlevel></item>";
								}

									// file Tile values
								if ((domoticzConfigJSON["result"][i]["idx"] == switch1Idx) && (switch1Type == "Light")) {
									switch1Name = domoticzConfigJSON["result"][i]["Name"];
									switch1Status = tmpStatus;
								}
								if ((domoticzConfigJSON["result"][i]["idx"] == switch2Idx) && (switch2Type == "Light")) {
									switch2Name = domoticzConfigJSON["result"][i]["Name"];
									switch2Status = tmpStatus;
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