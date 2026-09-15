#include "manifest.h"
#include <QtTest>
#include <QTemporaryDir>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <functional>

class ManifestTests : public QObject {
    Q_OBJECT
    static QJsonObject valid() {
        return {{"schema_version", 1}, {"id", "org.test.game"}, {"name", "Test"},
                {"version", "1.0.0"}, {"developer", "Test"}, {"executable", "game"},
                {"runtime", "native"}, {"permissions", QJsonArray{}}, {"controller_support", false}};
    }
    static void write(const QString &path, const QByteArray &data, bool executable = false) {
        QFile file(path);
        if (!file.open(QIODevice::WriteOnly)) qFatal("fixture open failed");
        if (file.write(data) != data.size()) qFatal("fixture write failed");
        file.close();
        if (executable) file.setPermissions(QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner);
    }
    static QString fixture(const QString &root, const QJsonObject &manifest) {
        const auto dir = root + "/org.test.game";
        QDir().mkpath(dir);
        write(dir + "/game", "#!/bin/sh\nexit 0\n", true);
        write(dir + "/game.json", QJsonDocument(manifest).toJson());
        return dir;
    }
private slots:
    void acceptsValid() {
        QTemporaryDir root;
        const auto dir = fixture(root.path(), valid());
        QCOMPARE(loadGame(root.path(), dir).id(), "org.test.game");
    }
    void rejectsManifest_data() {
        QTest::addColumn<QString>("field");
        QTest::addColumn<QJsonValue>("value");
        QTest::newRow("absolute") << QString("executable") << QJsonValue("/bin/sh");
        QTest::newRow("traversal") << QString("executable") << QJsonValue("../game");
        QTest::newRow("dot") << QString("executable") << QJsonValue("./game");
        QTest::newRow("empty-path") << QString("executable") << QJsonValue("");
        QTest::newRow("nul") << QString("executable") << QJsonValue(QString("game") + QChar(0));
        QTest::newRow("id") << QString("id") << QJsonValue("../../tmp");
        QTest::newRow("id-mismatch") << QString("id") << QJsonValue("org.other.game");
        QTest::newRow("schema") << QString("schema_version") << QJsonValue(2);
        QTest::newRow("schema-fraction") << QString("schema_version") << QJsonValue(1.5);
        QTest::newRow("runtime") << QString("runtime") << QJsonValue("proton");
        QTest::newRow("permission") << QString("permissions") << QJsonValue(QJsonArray{"network"});
        QTest::newRow("type") << QString("controller_support") << QJsonValue("yes");
        QTest::newRow("version") << QString("version") << QJsonValue("latest");
        QTest::newRow("unknown") << QString("command") << QJsonValue("rm -rf /tmp");
    }
    void rejectsManifest() {
        QFETCH(QString, field);
        QFETCH(QJsonValue, value);
        QTemporaryDir root;
        auto manifest = valid(); manifest[field] = value;
        const auto dir = fixture(root.path(), manifest);
        QVERIFY_EXCEPTION_THROWN(loadGame(root.path(), dir), std::runtime_error);
    }
    void rejectsSymlink() {
        QTemporaryDir root;
        const auto dir = fixture(root.path(), valid());
        QFile::remove(dir + "/game");
        QVERIFY(QFile::link("/bin/true", dir + "/game"));
        QVERIFY_EXCEPTION_THROWN(loadGame(root.path(), dir), std::runtime_error);
    }
    void rejectsDirectorySymlink() {
        QTemporaryDir root;
        QTemporaryDir outside;
        const auto dir = fixture(outside.path(), valid());
        QVERIFY(QFile::link(dir, root.path() + "/org.test.game"));
        QVERIFY_EXCEPTION_THROWN(loadGame(root.path(), root.path() + "/org.test.game"), std::runtime_error);
    }
    void rejectsOversize() {
        QTemporaryDir root;
        const auto dir = fixture(root.path(), valid());
        write(dir + "/game.json", QByteArray(65537, ' '));
        QVERIFY_EXCEPTION_THROWN(loadGame(root.path(), dir), std::runtime_error);
    }
    void rejectsMalformed() {
        QTemporaryDir root;
        const auto dir = fixture(root.path(), valid());
        write(dir + "/game.json", "{broken");
        QVERIFY_EXCEPTION_THROWN(loadGame(root.path(), dir), std::runtime_error);
    }
    void rejectsMissingField() {
        QTemporaryDir root;
        auto manifest = valid(); manifest.remove("developer");
        const auto dir = fixture(root.path(), manifest);
        QVERIFY_EXCEPTION_THROWN(loadGame(root.path(), dir), std::runtime_error);
    }
};
QTEST_GUILESS_MAIN(ManifestTests)
#include "test_manifest.moc"
