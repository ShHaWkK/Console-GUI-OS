import QtQuick

// Overlay Quick Menu (CLAUDE.md section 27) : se superpose à la page
// courante sans la reconstruire. La page derrière garde tout son état
// (Main.qml ne détruit ni ne recrée `navigation` à l'ouverture/fermeture).
// Le focus clavier est explicitement transféré à cet overlay à l'ouverture
// (onActiveChanged -> forceActiveFocus) puis restauré par l'appelant sur
// `closed()` (voir Main.qml : navigation.forceActiveFocus()).
//
// Seules des actions réellement câblées sont proposées : Reprendre (fermer),
// Accueil, Bibliothèque, Réglages. Pas d'entrée décorative qui ne ferait
// rien (CLAUDE.md section 60 : pas de faux succès / simulation).
Item {
    id: quickMenu
    anchors.fill: parent
    visible: opacity > 0
    opacity: active ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: theme.motionOverlay } }

    required property var theme
    property bool active: false
    property int selected: 0
    readonly property var entries: ["Reprendre", "Accueil", "Bibliothèque", "Réglages"]

    signal closed()
    signal navigateTo(int page)

    onActiveChanged: if (active) { selected = 0; forceActiveFocus() }

    Rectangle { anchors.fill: parent; color: theme.colorScrim; opacity: 0.55 }

    Rectangle {
        id: panel
        width: 320; height: parent.height
        anchors.left: parent.left
        anchors.leftMargin: quickMenu.active ? 0 : -width
        Behavior on anchors.leftMargin { NumberAnimation { duration: theme.motionOverlay; easing.type: Easing.OutCubic } }
        color: theme.colorSurfaceAlt

        Column {
            anchors.fill: parent; anchors.margins: theme.spacingXl; spacing: 18
            Text {
                text: "MENU RAPIDE"
                color: theme.colorAccent; font.pixelSize: theme.typeFooter; font.letterSpacing: 3
            }
            Repeater {
                model: quickMenu.entries
                Rectangle {
                    required property string modelData
                    required property int index
                    width: 256; height: 52; radius: theme.radiusControl
                    color: quickMenu.selected === index ? theme.colorAccent : "transparent"
                    Behavior on color { ColorAnimation { duration: theme.motionFast } }
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: theme.spacingMd
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        color: quickMenu.selected === index ? theme.colorAccentText : theme.colorTextPrimary
                        font.pixelSize: theme.typeMenuEntry
                    }
                }
            }
        }
        Text {
            anchors.bottom: parent.bottom; anchors.margins: theme.spacingLg; anchors.left: parent.left
            text: "↑ ↓  Naviguer     Entrée  Valider     Échap  Fermer"
            color: theme.colorTextMuted; font.pixelSize: theme.typeBadge
        }
    }

    Keys.onPressed: function(event) {
        if (!active) return
        switch (event.key) {
        case Qt.Key_Up: selected = (selected + entries.length - 1) % entries.length; break
        case Qt.Key_Down: selected = (selected + 1) % entries.length; break
        case Qt.Key_Escape: case Qt.Key_Backspace: closed(); break
        case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space:
            if (selected === 0) closed()
            else { navigateTo(selected - 1); closed() }
            break
        default: return
        }
        event.accepted = true
    }
}
