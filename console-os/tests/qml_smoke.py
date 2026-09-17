"""Test QML optionnel avec PySide6. Fixture UI, pas un test IPC ou GPU."""
from pathlib import Path
import sys

try:
    from PySide6.QtCore import QObject, Property, Signal, Slot, QUrl, Qt
    from PySide6.QtGui import QGuiApplication
    from PySide6.QtQml import QQmlApplicationEngine
    from PySide6.QtQuick import QQuickWindow
    from PySide6.QtTest import QTest
except ImportError:
    print("SKIP: PySide6 non installé (test QML optionnel, voir docs/build.md)")
    sys.exit(0)


class Fixture(QObject):
    changed = Signal()
    games = Property("QVariantList", lambda self: [dict(id="org.consoleos.hello", name="Hello Console", developer="Console OS Project", version="0.1.0")], notify=changed)
    message = Property(str, lambda self: "1 jeu(x) disponible(s)", notify=changed)
    gameRunning = Property(bool, lambda self: False, notify=changed)
    systemInfo = Property(str, lambda self: "Environnement de test QML", constant=True)
    launched = None

    @Slot()
    def refresh(self):
        pass

    @Slot(str)
    def launch(self, game_id):
        self.launched = game_id


app = QGuiApplication([])
root = Path(__file__).resolve().parents[1]
backend = Fixture()
engine = QQmlApplicationEngine()
warnings = []
engine.warnings.connect(lambda errors: warnings.extend(str(e) for e in errors))
engine.rootContext().setContextProperty("backend", backend)
engine.rootContext().setContextProperty("windowed", True)
engine.load(QUrl.fromLocalFile(str(root / "shell/Main.qml")))
assert engine.rootObjects(), "Échec chargement QML"
window = engine.rootObjects()[0]
QTest.qWait(150)
navigation = window.findChild(QObject, "navigation")
assert navigation is not None
QTest.keyClick(window, Qt.Key_Right)
assert navigation.property("page") == 1
QTest.keyClick(window, Qt.Key_Down)
assert navigation.property("inContent")

# Game Detail minimal (CLAUDE.md section 26) : en Bibliothèque, le premier
# Entrée ouvre une confirmation au lieu de lancer directement (contrairement
# à Home). Le jeu ne doit pas démarrer avant le second Entrée.
QTest.keyClick(window, Qt.Key_Return)
assert navigation.property("showDetail") is True, "premier Entrée en Bibliothèque doit ouvrir le détail, pas lancer"
assert backend.launched is None, "le jeu ne doit pas être lancé avant confirmation"
QTest.keyClick(window, Qt.Key_Return)
assert backend.launched == "org.consoleos.hello", "second Entrée doit confirmer le lancement"

# Back est à deux niveaux depuis le détail : un premier Échap ferme la
# confirmation sans quitter la Bibliothèque, un second ramène à Home.
QTest.keyClick(window, Qt.Key_Escape)
assert navigation.property("showDetail") is False
assert navigation.property("page") == 1, "premier Échap doit fermer le détail sans quitter la Bibliothèque"
QTest.keyClick(window, Qt.Key_Escape)
assert navigation.property("page") == 0
QTest.keyClick(window, Qt.Key_Right)
QTest.keyClick(window, Qt.Key_Right)
assert navigation.property("page") == 2

# Sous-navigation Settings : ←/→ doit réellement cycler les 5 catégories
# (General/Account/System/Devices/Preferences), pas juste afficher un texte
# statique. Vérifié via la propriété `selected`, réutilisée pour indexer
# settingsCategories quand page === 2 (voir Main.qml).
QTest.keyClick(window, Qt.Key_Down)
assert navigation.property("inContent")
assert navigation.property("selected") == 0
QTest.keyClick(window, Qt.Key_Right)
assert navigation.property("selected") == 1
QTest.keyClick(window, Qt.Key_Left)
QTest.keyClick(window, Qt.Key_Left)
assert navigation.property("selected") == 4, "← doit boucler vers la dernière catégorie (Preferences)"

# Clavier virtuel (Settings ▸ Devices, index 3) : vérifie une vraie saisie,
# pas seulement que l'overlay s'affiche. Couvre lettre, touche ⌫ de la
# grille et fermeture via la touche "OK" de la grille.
QTest.keyClick(window, Qt.Key_Right)  # 4 -> 0 (General, boucle)
QTest.keyClick(window, Qt.Key_Right)  # -> 1 (Account)
QTest.keyClick(window, Qt.Key_Right)  # -> 2 (System)
QTest.keyClick(window, Qt.Key_Right)  # -> 3 (Devices)
assert navigation.property("selected") == 3
virtual_keyboard = window.findChild(QObject, "virtualKeyboard")
assert virtual_keyboard is not None
QTest.keyClick(window, Qt.Key_Return)
QTest.qWait(150)
assert virtual_keyboard.property("active") is True, "Entrée sur Devices doit ouvrir le clavier virtuel"
QTest.keyClick(window, Qt.Key_Return)  # presse 'q' (sélection par défaut)
assert virtual_keyboard.property("text") == "q"
QTest.keyClick(window, Qt.Key_Right)   # -> 'w'
QTest.keyClick(window, Qt.Key_Return)
assert virtual_keyboard.property("text") == "qw"
QTest.keyClick(window, Qt.Key_Down)    # ligne "a s d f g h j k l" (colonne clampée à 1 -> 's')
QTest.keyClick(window, Qt.Key_Down)    # ligne "z x c v b n m ⌫" (colonne clampée à 1 -> 'x')
for _ in range(6):
    QTest.keyClick(window, Qt.Key_Right)  # colonne 1 -> 7 : rejoint la touche ⌫
QTest.keyClick(window, Qt.Key_Return)
assert virtual_keyboard.property("text") == "q", "la touche ⌫ de la grille doit supprimer le dernier caractère"
QTest.keyClick(window, Qt.Key_Down)    # ligne "␣ Espace" / "OK"
QTest.keyClick(window, Qt.Key_Return)  # presse "OK" -> ferme l'overlay
QTest.qWait(150)
assert virtual_keyboard.property("active") is False, "la touche OK de la grille doit fermer le clavier"
assert navigation.property("page") == 2, "la fermeture du clavier ne doit pas changer la page Settings"

QTest.keyClick(window, Qt.Key_Escape)
assert navigation.property("page") == 0, "Échap doit toujours ramener à Home, y compris depuis Settings"

QTest.keyClick(window, Qt.Key_Right)
QTest.keyClick(window, Qt.Key_Right)
assert navigation.property("page") == 2

# Quick Menu overlay (CLAUDE.md section 27) : la page reste inchangée derrière
# l'overlay, le focus est transféré à l'overlay puis restauré à la fermeture.
quick_menu = window.findChild(QObject, "quickMenu")
assert quick_menu is not None
QTest.keyClick(window, Qt.Key_Home)
QTest.qWait(200)
assert quick_menu.property("active") is True
assert navigation.property("page") == 2, "la page derrière l'overlay ne doit pas changer"
QTest.keyClick(window, Qt.Key_Down)
QTest.keyClick(window, Qt.Key_Return)
QTest.qWait(200)
assert quick_menu.property("active") is False
assert navigation.property("page") == 0, "sélection 'Accueil' dans le Quick Menu"
QTest.keyClick(window, Qt.Key_Right)
assert navigation.property("page") == 1, "le focus clavier doit être restauré à navigation après fermeture"

if len(sys.argv) > 1:
    assert window.grabWindow().save(sys.argv[1])
hello = QQmlApplicationEngine()
hello.rootContext().setContextProperty("savePath", "/tmp/test")
hello.warnings.connect(lambda errors: warnings.extend(str(e) for e in errors))
hello.load(QUrl.fromLocalFile(str(root / "examples/hello-console/Main.qml")))
assert hello.rootObjects(), "Échec chargement Hello Console"
QTest.qWait(50)
assert not warnings, warnings
print("PASS: deux scènes QML, navigation Home/Library/Settings et demande de lancement (fixture)")

# Destruction explicite et ordonnée avant la sortie de l'interprète : à la
# fin normale d'un script Python, l'ordre de finalisation des objets de
# module (via le GC de l'interpréteur) n'est pas garanti. Si `backend`
# (wrapper Python du contexte QML) est libéré avant `engine`, les bindings
# QML encore vivants peuvent se ré-évaluer contre un contexte détruit et
# lever des TypeError bruyantes (observé de façon non déterministe, environ
# une exécution sur deux). Le vrai binaire n'a pas ce problème : dans
# shell/main.cpp, `Backend` est déclaré avant `QQmlApplicationEngine`, donc
# le C++ détruit toujours le moteur QML avant le backend (ordre inverse de
# construction). On reproduit ce même ordre ici, explicitement.
del window, navigation, quick_menu, virtual_keyboard
del engine
del hello
del backend
