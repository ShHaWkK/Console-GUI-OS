#include "backend.h"
#include "log.h"
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSysInfo>
#include <QTimer>

Backend::Backend(QObject *parent) : QObject(parent) {
    QDBusConnection::sessionBus().connect("org.consoleos.GameManager1", "/org/consoleos/GameManager1",
        "org.consoleos.GameManager1", "StateChanged", this, SLOT(stateChanged(QString)));
    auto *timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, [this] { call("Status"); });
    timer->start(500);
    QTimer::singleShot(0, this, &Backend::refresh);
}

QString Backend::systemInfo() const {
    return QSysInfo::prettyProductName() + " • " + QSysInfo::currentCpuArchitecture()
        + "\nNoyau " + QSysInfo::kernelVersion() + " • Qt " + qVersion();
}

void Backend::refresh() { call("ListGames"); }
void Backend::launch(const QString &id) { if (!id.isEmpty()) call("Launch", id); }
void Backend::stop() { if (!activeId_.isEmpty()) call("Stop", activeId_); }

void Backend::stateChanged(const QString &status) {
    const auto doc = QJsonDocument::fromJson(status.toUtf8());
    if (doc.isObject()) acceptStatus(doc.object());
}

void Backend::acceptStatus(const QJsonObject &obj) {
    const auto state = obj["state"].toString();
    activeId_ = obj["id"].toString();
    const bool next = state == "running";
    if (running_ != next || state == "failed") {
        running_ = next;
        message_ = next ? "Jeu en cours" : state == "failed" ? "Impossible de démarrer le jeu" : "De retour à l’accueil";
        if (!obj["error"].toString().isEmpty()) message_ += " : " + obj["error"].toString();
        emit changed();
    }
}

void Backend::call(const QString &method, const QString &id) {
    if (pending_.contains(method)) return;
    auto request = QDBusMessage::createMethodCall("org.consoleos.GameManager1",
        "/org/consoleos/GameManager1", "org.consoleos.GameManager1", method);
    if (!id.isEmpty()) request << id;
    pending_.insert(method);
    auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(request, 2000), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, method](QDBusPendingCallWatcher *w) {
        pending_.remove(method);
        const QDBusPendingReply<QString> reply = *w;
        w->deleteLater();
        if (reply.isError()) {
            const auto next = QStringLiteral("Service indisponible. R : réessayer.");
            if (message_ != next) logEvent("ipc_error", {{"method", method}, {"error", reply.error().name()}});
            message_ = next;
            connected_ = false;
            running_ = false;
            emit changed();
            return;
        }
        QJsonParseError error;
        const auto doc = QJsonDocument::fromJson(reply.value().toUtf8(), &error);
        if (error.error != QJsonParseError::NoError || !doc.isObject()) {
            message_ = "Réponse du service invalide"; emit changed(); return;
        }
        const auto obj = doc.object();
        if (!obj["ok"].toBool()) {
            message_ = "Erreur : " + obj["error"].toString(); emit changed(); return;
        }
        if (method == "ListGames") {
            games_ = obj["games"].toArray().toVariantList();
            const auto rejected = obj["errors"].toArray().size();
            message_ = QString::number(games_.size()) + " jeu(x) disponible(s)";
            if (rejected) message_ += " • " + QString::number(rejected) + " manifest(s) refusé(s)";
            emit changed();
        } else if (method == "Status") {
            if (!connected_) { connected_ = true; refresh(); }
            acceptStatus(obj);
        } else {
            message_ = method == "Launch" ? "Démarrage…" : "Arrêt demandé…";
            emit changed();
        }
    });
}
