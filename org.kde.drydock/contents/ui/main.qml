/*
 * Copyright 2017  Tjaart Blignaut <tjaartblig@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
//import QtQuick 2.2
//import QtQuick.Layouts 1.3
//import org.kde.plasma.plasmoid 2.0
//import QtQml 2.0


import QtQuick 2.2
import QtQuick.Layouts 1.3
import org.kde.plasma.plasmoid 2.0
import QtQml 2.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
    id: root
    
   
    
   // property variant dockerServices: []
    
     property var waitingCommands: ({})
    
    ListModel {
        id: dockerServices
    }
   
     PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        connectedSources: ["curl --unix-socket /var/run/docker.sock http://foo/containers/json?all=true"]
       
        onNewData: {
            var stdout = data["stdout"]
            dockerServices.clear()
            var list = JSON.parse(stdout)
            for(var i=0;i<list.length;i++) {
                dockerServices.append(list[i] )
            }
        }
       
       
        interval: 1000
    }
    PlasmaCore.DataSource {
        id: dockerCommandExecutable
        engine: "executable"
        connectedSources: []
      
        onNewData: {
            var stdout = data["stdout"].replace(/(\r\n|\n|\r)/gm, "");
            waitingCommands[stdout] = false
            exited(sourceName, stdout)
            disconnectSource(sourceName) // cmd finished
        }

        function execDockerCommand(dockerCommand, containerId) {
            var cmd = 'docker ' + dockerCommand + ' ' + containerId
            waitingCommands[containerId] = true
            connectSource(cmd)
        }
        signal exited(string sourceName, string stdout)
    }
    function isBusy(containerId) {
        if (waitingCommands[containerId] === undefined) {
            return false;
        }
       return waitingCommands[containerId]
    }
    
    ColumnLayout {
        id: columns
        width: 1000
        spacing: 0;
         anchors.fill: parent;
          Layout.fillWidth: true
            Layout.fillHeight: true
         
        ListView {
            id: view
            width: parent.width
            height: parent.height
            model: dockerServices
            spacing: 7
            interactive: false
            clip: true
            delegate: RowLayout {
                width: parent.width
              
                PlasmaComponents.Label {
                    id: containerImage
                    text: model.Image
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    
                }
                 PlasmaComponents.Label {
                    id: containerState
                    text: model.Status
                   
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    
                }
                PlasmaComponents.BusyIndicator {
                    id: connectingIndicator
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    Layout.fillHeight: true
                    Layout.preferredHeight: units.iconSizes.small
                    Layout.preferredWidth: units.iconSizes.small
                    running: true
                    visible: isBusy(model.Id)
                }
                PlasmaComponents.Button {
                     enabled: !isBusy(model.Id)
                     //text: (model.State == "exited") ? i18n("Start") : i18n("Stop")
                     iconSource: (model.State == "exited") ? "media-playback-start" : "media-playback-stop"
                     onClicked: function () {
                         dockerCommandExecutable.execDockerCommand((model.State == "exited") ? "start" : "stop", model.Id);
                       
                     }
                }
            }
        }
    
        
    }
     
}