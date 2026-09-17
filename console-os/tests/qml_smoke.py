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
QTest.keyClick(window, Qt.Key_Return)
assert backend.launched == "org.consoleos.hello"
QTest.keyClick(window, Qt.Key_Escape)
assert navigation.property("page") == 0
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
del window, navigation, quick_menu
del engine
del hello
del backend
