import QtQuick
import QtQuick.Window

Window {
    id: window
    width: 1280; height: 800
    minimumWidth: 800; minimumHeight: 600
    title: "Console OS"
    visible: !backend.gameRunning
    visibility: backend.gameRunning ? Window.Hidden : (windowed ? Window.Windowed : Window.FullScreen)
    color: theme.colorBackground
    onVisibleChanged: if (visible) { requestActivate(); navigation.forceActiveFocus() }

    property bool quickMenuOpen: false
    property bool keyboardOpen: false

    Theme { id: theme }

    Item {
        id: navigation
        objectName: "navigation"
        anchors.fill: parent
        focus: true
        property int page: 0
        property bool inContent: false
        property int selected: 0
        // Game Detail minimal (CLAUDE.md section 26, docs/ui-navigation.md
        // section 4) : en Bibliothèque, Entrée ouvre d'abord un état de
        // confirmation avant de lancer réellement le jeu, comme le menu
        // contextuel des maquettes (library 1-5 menu.png). Sur Home, Entrée
        // lance directement — cohérent avec le hint "A Start" des maquettes
        // Home (home 1.jpg). Non utilisé sur Settings (page 2).
        property bool showDetail: false
        property var currentGame: backend.games.length > selected ? backend.games[selected] : null

        // Contenu Settings honnête : pas de réglage qui prétend fonctionner
        // alors qu'aucun service ne le porte encore (CLAUDE.md section 60).
        // Chaque catégorie décrit l'état réel, y compris quand cet état est
        // "non implémenté" — jamais un contrôle interactif simulé.
        readonly property var settingsCategories: [
            { name: "General", detail: "Aucun réglage d'affichage n'est encore configurable depuis ce prototype.\nThèmes et contrôle parental : non implémentés." },
            { name: "Account", detail: "Aucun compte utilisateur n'est configuré.\nGestion des profils : non implémentée (voir roadmap, Phase 2 et au-delà)." },
            { name: "System", detail: backend.systemInfo + "\nRéseau, audio et vidéo : non implémentés." },
            { name: "Devices", detail: "Aucune manette détectée : le backend d'entrée manette physique n'est pas encore branché.\nSouris et clavier physiques : gérés par le système d'exploitation.\n\nClavier virtuel (réel, testez-le) : \"" + virtualKeyboard.text + "\"\nEntrée pour ouvrir le clavier virtuel." },
            { name: "Preferences", detail: "Notifications, capture et partage : non implémentés." }
        ]

        // Point d'entrée commun : le futur backend SDL appellera ces mêmes actions.
        function dispatch(action) {
            if (action === "menu") { window.quickMenuOpen = true }
            else if (action === "back") {
                if (showDetail) showDetail = false
                else { page = 0; inContent = false; selected = 0 }
            }
            else if (action === "refresh") backend.refresh()
            else if (action === "up") { inContent = false; showDetail = false }
            else if (action === "down" || action === "tab") {
                inContent = !inContent
                if (!inContent) showDetail = false
            }
            else if (action === "left" || action === "right") {
                let delta = action === "left" ? -1 : 1
                if (!inContent) { page = (page + delta + 3) % 3; selected = 0 }
                else if (page < 2 && !showDetail && backend.games.length) selected = (selected + delta + backend.games.length) % backend.games.length
                else if (page === 2) selected = (selected + delta + settingsCategories.length) % settingsCategories.length
            } else if (action === "accept") {
                if (!inContent) inContent = true
                else if (page === 0 && currentGame) backend.launch(currentGame.id)
                else if (page === 1 && currentGame) {
                    if (showDetail) backend.launch(currentGame.id)
                    else showDetail = true
                }
                // Devices (index 3) : Entrée ouvre le clavier virtuel réel,
                // seule action câblée sur Settings pour l'instant (les autres
                // catégories n'ont rien de réel à faire à part naviguer).
                else if (page === 2 && selected === 3) window.keyboardOpen = true
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
            case Qt.Key_Home: action = "menu"; break
            case Qt.Key_R: action = "refresh"; break
            }
            if (action !== "") { dispatch(action); event.accepted = true }
        }
        Connections {
            target: backend
            function onChanged() {
                // Ne s'applique qu'à la navigation des jeux (Home/Library) : sur
                // Settings, `selected` indexe settingsCategories, pas backend.games,
                // et ne doit pas être réinitialisé par un changement côté backend.
                if (navigation.page < 2 && navigation.selected >= backend.games.length) navigation.selected = 0
            }
        }
        // Petit "pulse" de contenu à chaque changement de page/onglet : rend la
        // navigation plus lisible sans dépendre d'une transition de layout
        // complète (qui exigerait un vrai NavigationStack, hors périmètre ici).
        Connections {
            target: navigation
            function onPageChanged() { cardFade.restart() }
        }
        SequentialAnimation {
            id: cardFade
            NumberAnimation { target: cardContent; property: "opacity"; to: 0.35; duration: theme.motionFast }
            NumberAnimation { target: cardContent; property: "opacity"; to: 1; duration: theme.motionFast }
        }

        Rectangle {
            width: parent.width * 0.65; height: width; radius: width / 2
            anchors.right: parent.right; anchors.rightMargin: -width * 0.45
            anchors.top: parent.top; anchors.topMargin: -height * 0.5
            color: theme.colorBackgroundAccent
        }
        Column {
            anchors.fill: parent; anchors.margins: theme.spacingPageGutter; spacing: theme.spacingSectionGap
            Row {
                width: parent.width; height: 48; spacing: theme.spacingMd
                Rectangle {
                    width: 38; height: 38; radius: 12; color: theme.colorAccent; rotation: -12
                    Text { anchors.centerIn: parent; text: "C"; color: theme.colorAccentTextAlt; font.pixelSize: theme.typeBrandMark; font.bold: true }
                }
                Text { text: "CONSOLE OS"; color: theme.colorTextPrimary; font.pixelSize: theme.typeBrand; font.letterSpacing: 3; anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                spacing: theme.spacingTabsGap
                Repeater {
                    model: ["Home", "Library", "Settings"]
                    Rectangle {
                        required property string modelData
                        required property int index
                        width: 140; height: 46; radius: theme.radiusPill
                        color: navigation.page === index ? theme.colorAccent : theme.colorSurfaceMuted
                        border.width: navigation.page === index && !navigation.inContent ? 2 : 0
                        border.color: theme.colorTextPrimary
                        Behavior on color { ColorAnimation { duration: theme.motionFast } }
                        Behavior on border.width { NumberAnimation { duration: theme.motionFast } }
                        Text { anchors.centerIn: parent; text: modelData; font.pixelSize: theme.typeLabel; color: navigation.page === index ? theme.colorAccentText : theme.colorTextSecondary }
                        MouseArea { anchors.fill: parent; onClicked: { navigation.page = index; navigation.inContent = false; navigation.forceActiveFocus() } }
                    }
                }
            }
            Row {
                visible: navigation.page === 2
                height: visible ? 34 : 0
                spacing: theme.spacingSm
                Repeater {
                    model: navigation.settingsCategories
                    Rectangle {
                        required property var modelData
                        required property int index
                        width: 96; height: 30; radius: theme.radiusControl
                        color: navigation.inContent && navigation.selected === index ? theme.colorAccent : "transparent"
                        border.width: 1
                        border.color: navigation.selected === index ? theme.colorAccent : theme.colorBorder
                        Behavior on color { ColorAnimation { duration: theme.motionFast } }
                        Text {
                            anchors.centerIn: parent; text: modelData.name; font.pixelSize: theme.typeBadge
                            color: navigation.inContent && navigation.selected === index ? theme.colorAccentText : theme.colorTextSecondary
                        }
                        MouseArea { anchors.fill: parent; onClicked: { navigation.selected = index; navigation.inContent = true; navigation.forceActiveFocus() } }
                    }
                }
            }
            Column {
                width: parent.width; spacing: theme.spacingTitleGap
                Text { text: navigation.page === 0 ? "Votre prochaine partie." : navigation.page === 1 ? "Vos jeux, ici." : "Votre console."; color: theme.colorTextPrimary; font.pixelSize: theme.typeDisplay; font.bold: true }
                Text { text: navigation.page === 2 ? navigation.settingsCategories.length + " catégories" : "Bibliothèque locale • " + backend.games.length + " jeu(x)"; color: theme.colorTextSecondary; font.pixelSize: theme.typeLabel }
            }
            Rectangle {
                // -64 sur Settings : compense la rangée de catégories (34px de
                // hauteur + 30px de spacing) insérée au-dessus, pour que le
                // message de statut et le bandeau d'aide ne se chevauchent pas.
                width: parent.width
                height: Math.max(220, window.height - 455 - (navigation.page === 2 ? 64 : 0))
                radius: theme.radiusCard
                color: navigation.page === 2 ? theme.colorSurfaceAlt : theme.colorSurface
                border.width: navigation.inContent ? 3 : 1
                border.color: navigation.inContent ? theme.colorAccent : theme.colorBorder
                Behavior on color { ColorAnimation { duration: theme.motionFast } }
                Behavior on border.color { ColorAnimation { duration: theme.motionFast } }
                Behavior on border.width { NumberAnimation { duration: theme.motionFast } }
                Column {
                    id: cardContent
                    anchors.fill: parent; anchors.margins: theme.spacingXl; spacing: theme.spacingCardContent
                    Behavior on opacity { NumberAnimation { duration: theme.motionFast } }
                    Text {
                        text: navigation.page === 2 ? "RÉGLAGES  /  " + (navigation.selected + 1).toString().padStart(2, "0")
                            : (navigation.page === 1 && navigation.showDetail) ? "CONFIRMER  /  " + (navigation.selected + 1).toString().padStart(2, "0")
                            : "NATIVE  /  " + (navigation.selected + 1).toString().padStart(2, "0")
                        color: theme.colorAccent; font.pixelSize: theme.typeBadge; font.letterSpacing: 3
                    }
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: navigation.page === 2 ? navigation.settingsCategories[navigation.selected].name : navigation.currentGame ? navigation.currentGame.name : "Aucun jeu disponible"
                        color: theme.colorTextPrimary; font.pixelSize: theme.typeHeading; font.bold: true
                    }
                    Text {
                        width: parent.width; wrapMode: Text.Wrap
                        text: navigation.page === 2 ? "Console OS · Prototype 0.1" : navigation.currentGame ? navigation.currentGame.developer + "  •  v" + navigation.currentGame.version : "Ajoutez un jeu de confiance au catalogue, puis appuyez sur R."
                        color: theme.colorTextBody; font.pixelSize: theme.typeLabel
                    }
                    Text {
                        width: parent.width; wrapMode: Text.Wrap
                        text: navigation.page === 2 ? navigation.settingsCategories[navigation.selected].detail
                            : (navigation.page === 1 && navigation.showDetail) ? "Entrée  Lancer      Échap  Retour à la bibliothèque"
                            : navigation.page === 1 ? "←  →  Parcourir      Entrée  Voir / lancer"
                            : "←  →  Parcourir      Entrée  Jouer"
                        color: theme.colorTextBody; font.pixelSize: theme.typeBody
                    }
                }
                MouseArea {
                    anchors.fill: parent; enabled: navigation.page < 2 && navigation.currentGame !== null
                    onClicked: { navigation.inContent = true; navigation.dispatch("accept") }
                }
            }
            Text { width: parent.width; text: backend.message; color: theme.colorAccent; font.pixelSize: theme.typeMessage; elide: Text.ElideRight }
        }
        Text {
            anchors.bottom: parent.bottom; anchors.left: parent.left
            anchors.margins: theme.spacingLg; anchors.leftMargin: theme.spacingPageGutter
            text: "↑ ↓  Navigation     ← →  Choisir     Entrée  Valider     Échap  Accueil     Début  Menu rapide     R  Actualiser"
            color: theme.colorTextMuted; font.pixelSize: theme.typeFooter
        }
    }

    QuickMenu {
        id: quickMenu
        objectName: "quickMenu"
        theme: theme
        active: window.quickMenuOpen
        onClosed: { window.quickMenuOpen = false; navigation.forceActiveFocus() }
        onNavigateTo: function(page) { navigation.page = page; navigation.inContent = false; navigation.selected = 0 }
    }

    VirtualKeyboard {
        id: virtualKeyboard
        objectName: "virtualKeyboard"
        theme: theme
        active: window.keyboardOpen
        onClosed: { window.keyboardOpen = false; navigation.forceActiveFocus() }
    }
}
