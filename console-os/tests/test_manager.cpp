#include "manager.h"
#include <QtTest>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QTemporaryDir>

// Unités du moteur de cycle de vie, sans bus ni point d'entrée du daemon.
class ManagerTests : public QObject {
    Q_OBJECT
    static QJsonObject object(const QString &s) { return QJsonDocument::fromJson(s.toUtf8()).object(); }
    static void write(const QString &path, const QByteArray &bytes) {
        QFile f(path);
        if (!f.open(QIODevice::WriteOnly) || f.write(bytes) != bytes.size()) qFatal("fixture write failed");
        f.close();
        f.setPermissions(QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner);
    }
private slots:
    void lifecycle() {
        QTemporaryDir temp;
        qputenv("XDG_DATA_HOME", (temp.path() + "/data").toUtf8());
        qputenv("XDG_CONFIG_HOME", (temp.path() + "/config").toUtf8());
        qputenv("XDG_CACHE_HOME", (temp.path() + "/cache").toUtf8());
        const auto catalog = temp.path() + "/catalog";
        const auto game = catalog + "/org.test.game";
        QDir().mkpath(game);
        const QJsonObject manifest{{"schema_version", 1}, {"id", "org.test.game"}, {"name", "Test"},
            {"version", "1.0.0"}, {"developer", "Test"}, {"executable", "game"}, {"runtime", "native"},
            {"permissions", QJsonArray{}}, {"controller_support", false}};
        write(game + "/game.json", QJsonDocument(manifest).toJson());
        write(game + "/game", "#!/bin/sh\nexec /bin/sleep 10\n");
        Manager manager(catalog);
        QCOMPARE(object(manager.ListGames())["games"].toArray().size(), 1);
        QVERIFY(!object(manager.Launch("org.missing.game"))["ok"].toBool());
        QVERIFY(object(manager.Launch("org.test.game"))["ok"].toBool());
        QTRY_COMPARE(object(manager.Status())["state"].toString(), "running");
        QCOMPARE(object(manager.Launch("org.test.game"))["error"].toString(), "game_already_active");
        QVERIFY(!object(manager.Stop("org.other.game"))["ok"].toBool());
        QVERIFY(object(manager.Stop("org.test.game"))["ok"].toBool());
        QTRY_COMPARE(object(manager.Status())["state"].toString(), "stopped");
        QVERIFY(QDir(temp.path() + "/data/console-os/games/org.test.game/saves").exists());
        write(game + "/game", "#!/bin/sh\nexit 0\n");
        QVERIFY(object(manager.Launch("org.test.game"))["ok"].toBool());
        QTRY_COMPARE(object(manager.Status())["state"].toString(), "stopped");
        write(game + "/game", "#!/nonexistent/interpreter\n");
        QVERIFY(object(manager.Launch("org.test.game"))["ok"].toBool());
        QTRY_COMPARE(object(manager.Status())["state"].toString(), "failed");
        QFile::remove(game + "/game");
        QVERIFY(!object(manager.Launch("org.test.game"))["ok"].toBool());
    }
};
QTEST_GUILESS_MAIN(ManagerTests)
#include "test_manager.moc"
