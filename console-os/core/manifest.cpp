#include "manifest.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QRegularExpression>
#include <QSet>
#include <stdexcept>

namespace {
void require(bool condition, const char *message) {
    if (!condition) throw std::runtime_error(message);
}
bool inside(const QString &root, const QString &path) {
    return !root.isEmpty() && path.startsWith(root + '/');
}
}

Game loadGame(const QString &catalog, const QString &directory) {
    const auto root = QFileInfo(catalog).canonicalFilePath();
    const QFileInfo folder(directory);
    const auto base = folder.canonicalFilePath();
    require(folder.isDir() && !folder.isSymLink() && inside(root, base), "invalid_game_directory");
    require(QFileInfo(base).dir().canonicalPath() == root, "nested_game_directory");
    const QFileInfo mf(QDir(base).filePath("game.json"));
    require(mf.isFile() && !mf.isSymLink() && mf.size() <= 65536, "invalid_manifest_file");
    QFile file(mf.filePath());
    require(file.open(QIODevice::ReadOnly), "manifest_unreadable");
    auto bytes = file.read(65537);
    require(bytes.size() <= 65536, "manifest_too_large");
    QJsonParseError error;
    const auto doc = QJsonDocument::fromJson(bytes, &error);
    require(error.error == QJsonParseError::NoError && doc.isObject(), "invalid_json");
    const auto obj = doc.object();
    const QSet<QString> fields = {"schema_version", "id", "name", "version", "developer",
                                  "executable", "runtime", "permissions", "controller_support"};
    for (auto it = obj.begin(); it != obj.end(); ++it)
        require(fields.contains(it.key()), "unknown_field");
    require(obj.size() == fields.size(), "missing_field");
    require(obj["schema_version"].isDouble() && obj["schema_version"].toDouble() == 1, "unsupported_schema");
    for (const auto &key : {"id", "name", "version", "developer", "executable", "runtime"}) {
        require(obj[key].isString(), "invalid_string_type");
        const auto value = obj[key].toString();
        require(!value.trimmed().isEmpty() && value.size() <= 256, "invalid_string_length");
        require(!value.contains(QRegularExpression("[\\x00-\\x1f\\x7f]")), "control_character");
    }
    require(QRegularExpression("^[a-z][a-z0-9]*(?:\\.[a-z][a-z0-9_-]*)+$").match(obj["id"].toString()).hasMatch(), "invalid_id");
    require(obj["id"].toString() == folder.fileName(), "directory_id_mismatch");
    require(QRegularExpression("^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$").match(obj["version"].toString()).hasMatch(), "invalid_version");
    require(obj["runtime"] == "native", "unsupported_runtime");
    require(obj["permissions"].isArray() && obj["permissions"].toArray().isEmpty(), "unsupported_permissions");
    require(obj["controller_support"].isBool(), "invalid_controller_support");
    const auto relative = obj["executable"].toString();
    require(!QDir::isAbsolutePath(relative) && !relative.contains('\\'), "invalid_executable_path");
    auto cursor = base;
    for (const auto &part : relative.split('/')) {
        require(!part.isEmpty() && part != "." && part != "..", "invalid_path_component");
        cursor = QDir(cursor).filePath(part);
        require(!QFileInfo(cursor).isSymLink(), "symlink_forbidden");
    }
    const QFileInfo exe(cursor);
    require(exe.isFile() && exe.isExecutable() && inside(base, exe.canonicalFilePath()), "invalid_executable");
    return {obj, base, exe.canonicalFilePath()};
}
