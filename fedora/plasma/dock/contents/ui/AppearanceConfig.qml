import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_matchBarOpacity: matching.checked

    Controls.CheckBox {
        id: matching
        text: "Match configured bar opacity"
    }

    Controls.Label {
        text: "Disable to restore the native Breeze background."
    }
}
