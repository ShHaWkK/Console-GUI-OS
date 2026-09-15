#pragma once
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <cstdio>

inline void logEvent(const QString &event, QJsonObject fields = {}) {
    fields["event"] = event;
    fields["timestamp"] = QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs);
    const auto line = QJsonDocument(fields).toJson(QJsonDocument::Compact);
    std::fwrite(line.constData(), 1, static_cast<size_t>(line.size()), stderr);
    std::fputc('\n', stderr);
    std::fflush(stderr);
}
