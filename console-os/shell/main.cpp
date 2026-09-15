#include "backend.h"
#include "log.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>
#include <unistd.h>

int main(int argc, char **argv) {
    QGuiApplication app(argc, argv);
    if (geteuid() == 0) { logEvent("fatal", {{"error", "root_forbidden"}}); return 1; }
    app.setApplicationName("Console OS");
    Backend backend;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("backend", &backend);
    engine.rootContext()->setContextProperty("windowed", app.arguments().contains("--windowed"));
    engine.load(QUrl("qrc:/shell/Main.qml"));
    if (engine.rootObjects().isEmpty()) return 2;
    logEvent("shell_ready");
    if (app.arguments().contains("--smoke-test")) QTimer::singleShot(1000, &app, &QCoreApplication::quit);
    return app.exec();
}
