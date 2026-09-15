#include "manager.h"
#include "log.h"
#include <QCoreApplication>
#include <QDBusConnection>
#include <QDir>
#include <QTimer>
#include <csignal>
#include <unistd.h>

namespace {
volatile std::sig_atomic_t stopping = 0;
void stopSignal(int) { stopping = 1; }
}

int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    if (geteuid() == 0) { logEvent("fatal", {{"error", "root_forbidden"}}); return 1; }
    const auto args = app.arguments();
    if (args.size() != 3 || args[1] != "--catalog" || !QDir::isAbsolutePath(args[2])) {
        logEvent("fatal", {{"error", "usage: game-manager --catalog /absolute/catalog"}}); return 2;
    }
    Manager manager(args[2]);
    auto bus = QDBusConnection::sessionBus();
    if (!bus.isConnected() || !bus.registerService("org.consoleos.GameManager1") ||
        !bus.registerObject("/org/consoleos/GameManager1", &manager,
                            QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllSignals)) {
        logEvent("fatal", {{"error", "dbus_registration_failed"}}); return 3;
    }
    std::signal(SIGTERM, stopSignal);
    std::signal(SIGINT, stopSignal);
    QTimer timer;
    QObject::connect(&timer, &QTimer::timeout, &app, [&app] { if (stopping) app.quit(); });
    timer.start(100);
    logEvent("manager_ready");
    return app.exec();
}
