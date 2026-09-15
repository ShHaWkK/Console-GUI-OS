#pragma once
#include <QObject>
#include <QVariantList>
#include <QJsonObject>
#include <QSet>

class Backend final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList games READ games NOTIFY changed)
    Q_PROPERTY(QString message READ message NOTIFY changed)
    Q_PROPERTY(bool gameRunning READ gameRunning NOTIFY changed)
    Q_PROPERTY(QString systemInfo READ systemInfo CONSTANT)
public:
    explicit Backend(QObject *parent = nullptr);
    QVariantList games() const { return games_; }
    QString message() const { return message_; }
    bool gameRunning() const { return running_; }
    QString systemInfo() const;
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void launch(const QString &id);
    Q_INVOKABLE void stop();
private slots:
    void stateChanged(const QString &status);
signals:
    void changed();
private:
    void call(const QString &method, const QString &id = {});
    void acceptStatus(const QJsonObject &status);
    QVariantList games_;
    QString message_ = "Connexion au service…";
    QString activeId_;
    bool running_ = false;
    bool connected_ = false;
    QSet<QString> pending_;
};
