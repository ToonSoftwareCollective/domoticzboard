import QtQuick 2.1
import qb.components 1.0
import BasicUIControls 1.0

Screen {
	id: root
	screenTitle: qsTr("DomoticzBoard Instellingen")
	screenTitleIconUrl: "qrc:/tsc/DomoticzSystrayIcon.png"

	property bool messageShown : false
	
	onShown: {
		addCustomTopRightButton("Opslaan");
		showDummiesToggle.isSwitchedOn = app.showDummies;
		showDBIconToggle.isSwitchedOn = app.showDBIcon;
		showFavouritesToggle.isSwitchedOn = app.showFavourites;
		showScenesToggle.isSwitchedOn = app.showScenes;
		ipadresLabel.inputText = app.ipadres;
		poortnummerLabel.inputText = app.poortnummer;
		messageShown = false;
	}

	onCustomButtonClicked: {
		app.saveSettings();
		app.firstTimeShown = true; 
		app.domoticzDataRead = false;
		app.readDomoticzConfig();
		hide();
	}	

	function showMessage() {
		if (!messageShown) {
			if (!isNxt) {
				qdialog.showDialog(qdialog.SizeLarge, "Domoticzboard mededeling", "Als U op 'Opslaan' drukt zal de configuratie opnieuw worden ingeladen,\nde Toon heeft even wat tijd nodig om dit uit te voeren." , "Sluiten");
				messageShown = true;
			}
		}
	}	

	function saveIpadres(text) {
		if (text) {
			ipadresLabel.inputText = text;
			app.ipadres = text;
			showMessage();
		}
	}

	function savePoortnummer(text) {
		if (text) {
			poortnummerLabel.inputText = text;
			app.poortnummer = text;
			showMessage();
		}
	}
		
	Text {
		id: systrayText
		anchors {
			left: parent.left
			leftMargin: isNxt ? 62 : 50
            		top: parent.top
            		topMargin: isNxt ? 19 : 15
		}
		font {
			pixelSize: isNxt ? 25 : 20
			family: qfont.bold.name
		}
		wrapMode: Text.WordWrap
		text: "domoticzboard icoon zichtbaar op systray?"
	}
	
	OnOffToggle {
		id: showDBIconToggle
		height: 36
		anchors {
			right: parent.right
			rightMargin: isNxt ? 125 : 100
			top: systrayText.top
		}
		leftIsSwitchedOn: false
		onSelectedChangedByUser: {
			app.showDBIcon = isSwitchedOn
			showMessage();
		}
	}

	Text {
		id: favouritesText
		anchors {
			left: parent.left
			leftMargin: isNxt ? 62 : 50
			top: systrayText.bottom
			topMargin: isNxt ? 25 : 20
		}
		font {
			pixelSize: isNxt ? 25 : 20
			family: qfont.bold.name
		}
		wrapMode: Text.WordWrap
		text: "Toon alleen de domoticz favorieten?"
	}
	OnOffToggle {
		id: showFavouritesToggle
		height: 36
		anchors {
			right: parent.right
			rightMargin: isNxt ? 125 : 100
			top: systrayText.bottom
			topMargin: isNxt ? 25 : 20
		}
		leftIsSwitchedOn: false
		onSelectedChangedByUser: {
			app.showFavourites = isSwitchedOn
			showMessage();
		}
	}	

	Text {
		id: dummiesText
		anchors {
			left: parent.left
			leftMargin: isNxt ? 62 : 50
			top: favouritesText.bottom
			topMargin: isNxt ? 25 : 20
		}
		font {
			pixelSize: isNxt ? 25 : 20
			family: qfont.bold.name
		}
		wrapMode: Text.WordWrap
		text: "Toon ook de 'dummy'devices in Domoticz?"
	}
	OnOffToggle {
		id: showDummiesToggle
		height: 36
		anchors {
			right: parent.right
			rightMargin: isNxt ? 125 : 100
			top: favouritesText.bottom
			topMargin: isNxt ? 25 : 20
		}
		leftIsSwitchedOn: false
		onSelectedChangedByUser: {
			app.showDummies = isSwitchedOn
			showMessage();
		}
	}	

	Text {
		id: scenesText
		anchors {
			left: parent.left
			leftMargin: isNxt ? 62 : 50
			top: dummiesText.bottom
			topMargin: isNxt ? 25 : 20
		}
		font {
			pixelSize: isNxt ? 25 : 20
			family: qfont.bold.name
		}
		wrapMode: Text.WordWrap
		text: "Toon scenes/groep panel?"
	}
	OnOffToggle {
		id: showScenesToggle
		height: 36
		anchors {
			right: parent.right
			rightMargin: isNxt ? 125 : 100
			top: dummiesText.bottom
			topMargin: isNxt ? 25 : 20
		}
		leftIsSwitchedOn: false
		onSelectedChangedByUser: {
			app.showScenes = isSwitchedOn
			showMessage();
		}
	}	
	

	EditTextLabel4421 {
		id: ipadresLabel
		height: editipAdresButton.height
		width: isNxt ? 800 : 600
		leftText: qsTr("Hostname")
		leftTextAvailableWidth: isNxt ? 500 : 400
		anchors {
			left:parent.left
			leftMargin: isNxt ? 62 : 50
			top: scenesText.bottom
			topMargin: isNxt ? 25 : 20
		}
	}
			
	IconButton {
		id: editipAdresButton
		width: isNxt ? 50 : 40
		anchors {
			left:ipadresLabel.right
			leftMargin: isNxt ? 12 : 10
			top: ipadresLabel.top
		}
		iconSource: "qrc:/tsc/edit.png"
		onClicked: {
			qkeyboard.open("Voer hier uw hostname of ip-adres in", ipadresLabel.inputText, saveIpadres)
		}
	}
	// end ipadres
	// start portnumber
	
	EditTextLabel4421 {
		id: poortnummerLabel
		height: editportNumberButton.height
		width: isNxt ? 800 : 600
		leftTextAvailableWidth: isNxt ? 500 : 400
		leftText: qsTr("Port (default is 8080)")
		anchors {
			left:parent.left
			leftMargin: isNxt ? 62 : 50
			top: ipadresLabel.bottom
			topMargin: isNxt ? 25 : 20
		}
	}
	
	IconButton {
		id: editportNumberButton
		width: isNxt ? 50 : 40
		anchors {
			left:poortnummerLabel.right
			leftMargin: isNxt ? 12 : 10
			top: poortnummerLabel.top
		}
		iconSource: "qrc:/tsc/edit.png"
			onClicked: {
			qkeyboard.open("voer hier de poort in", poortnummerLabel.inputText, savePoortnummer);
		}
	}

	// end port number		
}
