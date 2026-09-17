import QtQuick

// Clavier virtuel manette-first (maquette/virtual keyboard/). Overlay
// autonome, même patron que QuickMenu.qml : focus transféré à l'ouverture,
// restauré à la fermeture, état de la page derrière préservé. Grille
// QWERTY navigable, une seule touche "presse" la lettre en surbrillance —
// pas de saisie clavier physique directe ici (le texte est vraiment tapé
// via la grille, pour que ce composant reste utilisable à la manette).
Item {
    id: keyboard
    anchors.fill: parent
    visible: opacity > 0
    opacity: active ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: theme.motionOverlay } }

    required property var theme
    property bool active: false
    property string text: ""
    property int selectedRow: 0
    property int selectedCol: 0

    signal closed()

    readonly property var rows: [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m", "⌫"],
        ["␣ Espace", "OK"]
    ]

    function pressKey(row, col) {
        const key = rows[row][col]
        if (key === "⌫") text = text.slice(0, -1)
        else if (key === "␣ Espace") text += " "
        else if (key === "OK") closed()
        else text += key
    }

    onActiveChanged: if (active) { selectedRow = 0; selectedCol = 0; forceActiveFocus() }

    Rectangle { anchors.fill: parent; color: theme.colorScrim; opacity: 0.6 }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: theme.spacingXxl
        width: 720; height: 360; radius: theme.radiusCard
        color: theme.colorSurfaceAlt
        border.width: 1; border.color: theme.colorBorder

        Column {
            anchors.fill: parent; anchors.margins: theme.spacingLg; spacing: theme.spacingMd

            Rectangle {
                width: parent.width; height: 56; radius: theme.radiusControl
                color: theme.colorBackground; border.width: 1; border.color: theme.colorBorder
                Text {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: theme.spacingMd
                    text: keyboard.text.length ? keyboard.text : "Tapez avec ←↑↓→ et Entrée…"
                    color: keyboard.text.length ? theme.colorTextPrimary : theme.colorTextMuted
                    font.pixelSize: theme.typeLabel
                }
            }

            Repeater {
                model: keyboard.rows
                Row {
                    required property var modelData
                    required property int index
                    property int rowIndex: index
                    spacing: theme.spacingSm
                    Repeater {
                        model: parent.modelData
                        Rectangle {
                            required property string modelData
                            required property int index
                            property bool isWide: modelData === "␣ Espace"
                            width: isWide ? 140 : 56; height: 46; radius: theme.radiusControl
                            color: keyboard.selectedRow === rowIndex && keyboard.selectedCol === index
                                ? theme.colorAccent : theme.colorSurfaceMuted
                            Behavior on color { ColorAnimation { duration: theme.motionFast } }
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: theme.typeLabel
                                color: keyboard.selectedRow === rowIndex && keyboard.selectedCol === index
                                    ? theme.colorAccentText : theme.colorTextSecondary
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { keyboard.selectedRow = rowIndex; keyboard.selectedCol = index; keyboard.pressKey(rowIndex, index) }
                            }
                        }
                    }
                }
            }

            Text {
                text: "↑ ↓ ← →  Déplacer      Entrée  Taper      Échap  Fermer"
                color: theme.colorTextMuted; font.pixelSize: theme.typeFooter
            }
        }
    }

    Keys.onPressed: function(event) {
        if (!active) return
        const rowLen = rows[selectedRow].length
        switch (event.key) {
        case Qt.Key_Left: selectedCol = (selectedCol - 1 + rowLen) % rowLen; break
        case Qt.Key_Right: selectedCol = (selectedCol + 1) % rowLen; break
        case Qt.Key_Up:
            selectedRow = (selectedRow - 1 + rows.length) % rows.length
            selectedCol = Math.min(selectedCol, rows[selectedRow].length - 1)
            break
        case Qt.Key_Down:
            selectedRow = (selectedRow + 1) % rows.length
            selectedCol = Math.min(selectedCol, rows[selectedRow].length - 1)
            break
        case Qt.Key_Return: case Qt.Key_Enter: pressKey(selectedRow, selectedCol); break
        case Qt.Key_Escape: case Qt.Key_Backspace: closed(); break
        default: return
        }
        event.accepted = true
    }
}
