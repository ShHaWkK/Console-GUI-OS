#pragma once
#include <QJsonObject>
#include <QString>

struct Game {
    QJsonObject manifest;
    QString directory;
    QString executable;
    QString id() const { return manifest["id"].toString(); }
};

// Le catalogue doit être de confiance et stable pendant cette opération.
Game loadGame(const QString &catalog, const QString &directory);
