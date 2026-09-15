import QtQuick
import QtQuick.Window

Window {
    width: 1280; height: 800
    visible: true; visibility: Window.FullScreen
    color: "#12282a"; title: "Hello Console"
    Item {
        anchors.fill: parent; focus: true
        Keys.onEscapePressed: Qt.quit()
        Keys.onReturnPressed: Qt.quit()
        Rectangle {
            width: 140; height: 140; radius: 42; color: "#bdedc7"
            anchors.horizontalCenter: parent.horizontalCenter; y: parent.height * 0.22
            SequentialAnimation on rotation {
                loops: Animation.Infinite
                NumberAnimation { to: 12; duration: 1600; easing.type: Easing.InOutSine }
                NumberAnimation { to: -12; duration: 1600; easing.type: Easing.InOutSine }
            }
        }
        Column {
            anchors.centerIn: parent; anchors.verticalCenterOffset: 95; spacing: 20
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Hello Console"; font.pixelSize: 52; font.bold: true; color: "#f2f4e9" }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Application native lancée par le Game Manager."; font.pixelSize: 20; color: "#b0c9c7" }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Entrée ou Échap pour revenir à la console"; font.pixelSize: 17; color: "#bdedc7" }
        }
    }
}
