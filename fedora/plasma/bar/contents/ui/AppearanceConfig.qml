import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root

    property alias cfg_keepFloating: keepFloating.checked
    property int cfg_backgroundOpacity
    property alias cfg_maximumIcons: maximumIcons.value

    Controls.CheckBox {
        id: keepFloating
        text: "Keep floating margins when windows touch the panel"
    }

    RowLayout {
        Kirigami.FormData.label: "Background strength:"
        Controls.Slider {
            from: 0
            to: 100
            stepSize: 1
            value: root.cfg_backgroundOpacity
            onMoved: root.cfg_backgroundOpacity = Math.round(value)
        }
        Controls.Label { text: root.cfg_backgroundOpacity + "%" }
    }

    Controls.Label {
        text: "Scales Breeze's background opacity. Text and icons stay opaque."
        opacity: 0.7
    }

    Controls.SpinBox {
        id: maximumIcons
        Kirigami.FormData.label: "Icons per workspace:"
        from: 1
        to: 20
    }
}
