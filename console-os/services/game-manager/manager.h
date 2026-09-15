#pragma once
#include "manifest.h"
#include <QObject>
#include <QMap>
#include <QProcess>
#include <QTimer>

class Manager final : public QObject {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.consoleos.GameManager1")
public:
    explicit Manager(QString catalog);
    ~Manager() override;
public slots:
    QString ListGames();
    QString Launch(const QString &id);
    QString Stop(const QString &id);
    QString Status();
signals:
    void StateChanged(const QString &state);
private:
    void setState(const QString &state, const QString &error = {});
    void drainOutput();
    QString catalog_;
    QMap<QString, Game> games_;
    QProcess process_;
    QTimer killTimer_;
    QTimer logTimer_;
    QString activeId_;
    QString state_ = "stopped";
    QString error_;
    int logBudget_ = 16384;
};
