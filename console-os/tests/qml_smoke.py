"""Test QML optionnel avec PySide6. Fixture UI, pas un test IPC ou GPU."""
from pathlib import Path
import sys
from PySide6.QtCore import QObject, Property, Signal, Slot, QUrl, Qt
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickWindow
from PySide6.QtTest import QTest


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
QTest.keyClick(window, Qt.Key_Home)
QTest.qWait(50)
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
