import QtQuick
import QtQuick.Window

Window {
    id: window
    width: 1280; height: 800
    minimumWidth: 800; minimumHeight: 600
    title: "Console OS"
    visible: !backend.gameRunning
    visibility: backend.gameRunning ? Window.Hidden : (windowed ? Window.Windowed : Window.FullScreen)
    color: "#0d1519"
    onVisibleChanged: if (visible) { requestActivate(); navigation.forceActiveFocus() }

    Item {
        id: navigation
        objectName: "navigation"
        anchors.fill: parent
        focus: true
        property int page: 0
        property bool inContent: false
        property int selected: 0
        property var currentGame: backend.games.length > selected ? backend.games[selected] : null

        // Point d'entrée commun : le futur backend SDL appellera ces mêmes actions.
        function dispatch(action) {
            if (action === "home" || action === "back") { page = 0; inContent = false; selected = 0 }
            else if (action === "refresh") backend.refresh()
            else if (action === "up") inContent = false
            else if (action === "down" || action === "tab") inContent = !inContent
            else if (action === "left" || action === "right") {
                let delta = action === "left" ? -1 : 1
                if (!inContent) { page = (page + delta + 3) % 3; selected = 0 }
                else if (page < 2 && backend.games.length) selected = (selected + delta + backend.games.length) % backend.games.length
            } else if (action === "accept") {
                if (!inContent) inContent = true
                else if (page < 2 && currentGame) backend.launch(currentGame.id)
            }
        }
        Keys.onPressed: function(event) {
            let action = ""
            switch (event.key) {
            case Qt.Key_Left: action = "left"; break
            case Qt.Key_Right: action = "right"; break
            case Qt.Key_Up: action = "up"; break
            case Qt.Key_Down: action = "down"; break
            case Qt.Key_Tab: action = "tab"; break
            case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: action = "accept"; break
            case Qt.Key_Escape: action = "back"; break
            case Qt.Key_Home: action = "home"; break
            case Qt.Key_R: action = "refresh"; break
            }
            if (action !== "") { dispatch(action); event.accepted = true }
        }
        Connections {
            target: backend
            function onChanged() {
                if (navigation.selected >= backend.games.length) navigation.selected = 0
            }
        }

        Rectangle {
            width: parent.width * 0.65; height: width; radius: width / 2
            anchors.right: parent.right; anchors.rightMargin: -width * 0.45
            anchors.top: parent.top; anchors.topMargin: -height * 0.5
            color: "#14292b"
        }
        Column {
            anchors.fill: parent; anchors.margins: 52; spacing: 30
            Row {
                width: parent.width; height: 48; spacing: 16
                Rectangle {
                    width: 38; height: 38; radius: 12; color: "#bdedc7"; rotation: -12
                    Text { anchors.centerIn: parent; text: "C"; color: "#10241b"; font.pixelSize: 25; font.bold: true }
                }
                Text { text: "CONSOLE OS"; color: "#f1f3e9"; font.pixelSize: 22; font.letterSpacing: 3; anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                spacing: 12
                Repeater {
                    model: ["Home", "Library", "Settings"]
                    Rectangle {
                        required property string modelData
                        required property int index
                        width: 140; height: 46; radius: 23
                        color: navigation.page === index ? "#bdedc7" : "#19252b"
                        border.width: navigation.page === index && !navigation.inContent ? 2 : 0
                        border.color: "#ffffff"
                        Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 17; color: navigation.page === index ? "#12241a" : "#bac6c8" }
                        MouseArea { anchors.fill: parent; onClicked: { navigation.page = index; navigation.inContent = false; navigation.forceActiveFocus() } }
                    }
                }
            }
            Column {
                width: parent.width; spacing: 10
                Text { text: navigation.page === 0 ? "Votre prochaine partie." : navigation.page === 1 ? "Vos jeux, ici." : "Votre console."; color: "#f1f3e9"; font.pixelSize: 42; font.bold: true }
                Text { text: navigation.page === 2 ? "Informations de cette session" : "Bibliothèque locale • " + backend.games.length + " jeu(x)"; color: "#91a7ac"; font.pixelSize: 17 }
            }
            Rectangle {
                width: parent.width; height: Math.max(220, window.height - 455); radius: 26
                color: navigation.page === 2 ? "#19262d" : "#233c3c"
                border.width: navigation.inContent && navigation.page < 2 ? 3 : 1
                border.color: navigation.inContent && navigation.page < 2 ? "#bdedc7" : "#344a4b"
                Behavior on border.color { ColorAnimation { duration: 120 } }
                Column {
                    anchors.fill: parent; anchors.margins: 32; spacing: 14
                    Text {
                        text: navigation.page === 2 ? "SYSTÈME" : "NATIVE  /  " + (navigation.selected + 1).toString().padStart(2, "0")
                        color: "#bdedc7"; font.pixelSize: 13; font.letterSpacing: 3
                    }
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: navigation.page === 2 ? "Console OS · Prototype 0.1" : navigation.currentGame ? navigation.currentGame.name : "Aucun jeu disponible"
                        color: "#f1f3e9"; font.pixelSize: 34; font.bold: true
                    }
                    Text {
                        width: parent.width; wrapMode: Text.Wrap
                        text: navigation.page === 2 ? backend.systemInfo : navigation.currentGame ? navigation.currentGame.developer + "  •  v" + navigation.currentGame.version : "Ajoutez un jeu de confiance au catalogue, puis appuyez sur R."
                        color: "#b3c8c8"; font.pixelSize: 17
                    }
                    Text {
                        width: parent.width; wrapMode: Text.Wrap
                        text: navigation.page === 2 ? "Réseau, audio, vidéo et profils : à venir.\nManette : intégration matérielle à venir." : "←  →  Parcourir      Entrée  Jouer"
                        color: "#b3c8c8"; font.pixelSize: 16
                    }
                }
                MouseArea {
                    anchors.fill: parent; enabled: navigation.page < 2 && navigation.currentGame !== null
                    onClicked: { navigation.inContent = true; navigation.dispatch("accept") }
                }
            }
            Text { width: parent.width; text: backend.message; color: "#bdedc7"; font.pixelSize: 15; elide: Text.ElideRight }
        }
        Text {
            anchors.bottom: parent.bottom; anchors.left: parent.left
            anchors.margins: 24; anchors.leftMargin: 52
            text: "↑ ↓  Navigation     ← →  Choisir     Entrée  Valider     Échap  Accueil     R  Actualiser"
            color: "#82999f"; font.pixelSize: 14
        }
    }
}
