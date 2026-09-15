#include "log.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>

int main(int argc, char **argv) {
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("savePath", qEnvironmentVariable("CONSOLE_SAVE_PATH"));
    engine.load(QUrl("qrc:/examples/hello-console/Main.qml"));
    if (engine.rootObjects().isEmpty()) return 1;
    logEvent("hello_started");
    QObject::connect(&app, &QCoreApplication::aboutToQuit, [] { logEvent("hello_finished"); });
    if (app.arguments().contains("--smoke-test")) QTimer::singleShot(700, &app, &QCoreApplication::quit);
    return app.exec();
}
