#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QTextStream>

int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    const auto args = app.arguments();
    if (args.size() < 2 || args.size() > 3) return 2;
    auto request = QDBusMessage::createMethodCall("org.consoleos.GameManager1",
        "/org/consoleos/GameManager1", "org.consoleos.GameManager1", args[1]);
    if (args.size() == 3) request << args[2];
    const auto reply = QDBusConnection::sessionBus().call(request, QDBus::Block, 2000);
    if (reply.type() == QDBusMessage::ErrorMessage || reply.arguments().size() != 1) return 1;
    QTextStream(stdout) << reply.arguments()[0].toString() << '\n';
    return 0;
}
