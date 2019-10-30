import QtQuick 2.1
import qb.components 1.0


Tile {
	id: domoticzTile
	property bool dimState: screenStateController.dimmedColors

	onClicked: {
		stage.openFullscreen(app.domoticzScreenUrl);
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
	
	function iconToShow(status) {

		if (status == "On") {
			return app.tilebulb_onvar;
		} else {
			return app.tilebulb_offvar;
		}
	}
	
	function iconToShowDim(status) {

		if (status == "On") {
			return app.dimtilebulb_onvar;
		} else {
			return app.dimtilebulb_offvar;
		}
	}

 	Image {
        	id: switch1Button
        	anchors {
         	   top: parent.top
         	   topMargin: isNxt ? 25 : 20
         	   left: parent.left
         	   leftMargin: isNxt ? 25 : 20
        	}
        	width: isNxt ? 100 : 75
        	height: isNxt ? 100 : 75
      		source: dimState ? iconToShowDim(app.switch1Status) : iconToShow(app.switch1Status)
		MouseArea {
			id: switch1Mouse
			anchors.fill: parent
			onClicked: {
				if (app.switch1Type == "Light") {
					simpleSynchronous("http://"+app.connectionPath+"/json.htm?type=command&param=switchlight&idx="+app.switch1Idx+"&switchcmd=Toggle");
				} else {
					simpleSynchronous("http://"+app.connectionPath+"/json.htm?type=command&param=switchscene&idx="+app.switch1Idx+"&switchcmd=Toggle");
				}
				if (app.switch1Status == "On") {
					app.switch1Status = "Off";
				} else {
					app.switch1Status = "On";
				}
			}
		}
		visible: (app.switch1Idx !== "*")

	}

    	Text {
        	id: switch1Title
         	width: -10 + parent.width / 2
       		anchors {
            		top: switch1Button.bottom
        		topMargin: isNxt ? 12 : 10
            		left: parent.left
			leftMargin: 5
        	}
		horizontalAlignment: Text.AlignHCenter
        	font {
            		family: qfont.semiBold.name
            		pixelSize: isNxt ? 25 : 20
        	}
        	color: colors.clockTileColor
        	text: app.switch1Name.substring(0,11)
    	}

 	Image {
        	id: switch2Button
        	anchors {
         	   top: parent.top
         	   topMargin: isNxt ? 25 : 20
         	   right: parent.right
         	   rightMargin: isNxt ? 25 : 20
        	}
        	width: isNxt ? 100 : 75
        	height: isNxt ? 100 : 75

      		source: dimState ? iconToShowDim(app.switch2Status) : iconToShow(app.switch2Status)

		MouseArea {
			id: switch2Mouse
			anchors.fill: parent
			onClicked: {
				if (app.switch2Type == "Light") {
					simpleSynchronous("http://"+app.connectionPath+"/json.htm?type=command&param=switchlight&idx="+app.switch2Idx+"&switchcmd=Toggle");
				} else {
					simpleSynchronous("http://"+app.connectionPath+"/json.htm?type=command&param=switchscene&idx="+app.switch2Idx+"&switchcmd=Toggle");
				}
				if (app.switch2Status == "On") {
					app.switch2Status = "Off";
				} else {
					app.switch2Status = "On";
				}
			}
		}
		visible: (app.switch2Idx !== "*")

	}

    	Text {
        	id: switch2Title
         	width: -10 + parent.width / 2
        	anchors {
            		top: switch2Button.bottom
        		topMargin: isNxt ? 12 : 10
            		right: parent.right
			rightMargin: 5
        	}
		horizontalAlignment: Text.AlignHCenter
        	font {
            		family: qfont.semiBold.name
            		pixelSize: isNxt ? 25 : 20
        	}
        	color: colors.clockTileColor
		text: app.switch2Name.substring(0,11)
    	}
}
