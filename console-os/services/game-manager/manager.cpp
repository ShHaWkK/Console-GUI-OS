#include "manager.h"
#include "log.h"
#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <utility>

namespace {
QString json(const QJsonObject &value) { return QString::fromUtf8(QJsonDocument(value).toJson(QJsonDocument::Compact)); }
QString result(bool ok, const QString &error = {}) { return json({{"ok", ok}, {"error", error}}); }
}

Manager::Manager(QString catalog) : catalog_(std::move(catalog)) {
    process_.setProcessChannelMode(QProcess::MergedChannels);
    killTimer_.setSingleShot(true);
    connect(&killTimer_, &QTimer::timeout, &process_, &QProcess::kill);
    logTimer_.setInterval(1000);
    connect(&logTimer_, &QTimer::timeout, this, [this] { logBudget_ = 16384; });
    logTimer_.start();
    connect(&process_, &QProcess::readyReadStandardOutput, this, &Manager::drainOutput);
    connect(&process_, &QProcess::started, this, [this] { setState("running"); });
    connect(&process_, &QProcess::errorOccurred, this, [this](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) { killTimer_.stop(); setState("failed", "launch_failed"); }
    });
    connect(&process_, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this](int code, QProcess::ExitStatus status) {
        killTimer_.stop();
        drainOutput();
        logEvent("game_exit", {{"game_id", activeId_}, {"exit_code", code}, {"crashed", status == QProcess::CrashExit}});
        setState("stopped", code == 0 ? QString() : QStringLiteral("game_exited_unsuccessfully"));
    });
}

Manager::~Manager() {
    if (process_.state() != QProcess::NotRunning) {
        process_.terminate();
        if (!process_.waitForFinished(1500)) { process_.kill(); process_.waitForFinished(1500); }
    }
}

void Manager::drainOutput() {
    while (process_.bytesAvailable() > 0) {
        const auto bytes = process_.read(4096);
        if (bytes.isEmpty()) break;
        if (logBudget_ > 0) {
            const auto kept = bytes.left(logBudget_);
            logBudget_ -= kept.size();
            logEvent("game_output", {{"game_id", activeId_}, {"text", QString::fromUtf8(kept)}});
            if (logBudget_ == 0) logEvent("game_output_rate_limited", {{"game_id", activeId_}});
        }
    }
}

void Manager::setState(const QString &state, const QString &error) {
    state_ = state;
    error_ = error;
    logEvent("game_state", {{"game_id", activeId_}, {"state", state}, {"error", error}});
    emit StateChanged(Status());
}

QString Manager::Status() {
    return json({{"ok", true}, {"state", state_}, {"id", activeId_}, {"error", error_}});
}

QString Manager::ListGames() {
    games_.clear();
    QJsonArray entries, errors;
    if (!QFileInfo(catalog_).isDir()) return result(false, "catalog_unavailable");
    const auto folders = QDir(catalog_).entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    if (folders.size() > 1000) return result(false, "catalog_limit_exceeded");
    for (const auto &folder : folders) {
        try {
            auto game = loadGame(catalog_, folder.filePath());
            entries.append(game.manifest);
            games_.insert(game.id(), game);
        } catch (const std::exception &e) {
            errors.append(QJsonObject{{"directory", folder.fileName()}, {"error", QString::fromUtf8(e.what())}});
            logEvent("manifest_rejected", {{"directory", folder.fileName()}, {"error", QString::fromUtf8(e.what())}});
        }
    }
    return json({{"ok", true}, {"games", entries}, {"errors", errors}});
}

QString Manager::Launch(const QString &id) {
    if (process_.state() != QProcess::NotRunning) return result(false, "game_already_active");
    ListGames();
    if (!games_.contains(id)) return result(false, "game_not_found");
    try {
        const auto game = loadGame(catalog_, games_[id].directory);
        const auto data = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/console-os/games/" + id;
        const auto config = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/console-os/games/" + id;
        const auto cache = QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation) + "/console-os/games/" + id;
        for (const auto &path : {data, config, cache, data + "/saves"}) {
            if (!QDir().mkpath(path)) return result(false, "data_directory_failed");
        }
        QProcessEnvironment env;
        const auto parent = QProcessEnvironment::systemEnvironment();
        for (const auto &key : {"HOME", "USER", "LANG", "LC_ALL", "XDG_RUNTIME_DIR", "WAYLAND_DISPLAY",
                                "DISPLAY", "XAUTHORITY", "PULSE_SERVER"}) {
            if (parent.contains(key)) env.insert(key, parent.value(key));
        }
        env.insert("PATH", "/usr/bin:/bin");
        env.insert("XDG_DATA_HOME", data);
        env.insert("XDG_CONFIG_HOME", config);
        env.insert("XDG_CACHE_HOME", cache);
        env.insert("CONSOLE_SAVE_PATH", data + "/saves");
        env.insert("CONSOLE_GAME_ID", id);
        process_.setProcessEnvironment(env);
        process_.setWorkingDirectory(game.directory);
        process_.setProgram(game.executable);
        process_.setArguments({});
        process_.setStandardInputFile(QProcess::nullDevice());
        activeId_ = id;
        logBudget_ = 16384;
        setState("starting");
        process_.start();
        return result(true);
    } catch (const std::exception &e) { return result(false, QString::fromUtf8(e.what())); }
}

QString Manager::Stop(const QString &id) {
    if (id != activeId_ || process_.state() == QProcess::NotRunning)
        return result(false, "game_not_running");
    process_.terminate();
    killTimer_.start(3000);
    return result(true);
}
