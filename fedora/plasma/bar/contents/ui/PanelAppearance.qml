import QtQuick
import org.kde.plasma.core as PlasmaCore

Item {
    id: root

    required property Item host
    property bool keepFloating: true
    property real backgroundOpacity: 1
    property Item panelView: null
    property var backgrounds: []
    property string structureError: ""
    readonly property string errorMessage: structureError || reservation.errorMessage

    PanelReservation {
        id: reservation
        panelView: root.panelView
        reserveFloating: root.keepFloating
    }

    function attach() {
        let item = host.parent;
        while (item && !(typeof item.floatingnessTarget === "number" && typeof item.floating === "boolean")) {
            item = item.parent;
        }
        panelView = item;
        if (!panelView) {
            structureError = "Panel appearance requires a compatible Plasma panel.";
            return;
        }

        // Adjusts theme backgrounds without changing text, icons, or panel masks.
        const matches = panelView.children.filter(child => child.imagePath === "widgets/panel-background"
            || child.imagePath === "solid/widgets/panel-background");
        if (matches.length !== 6) {
            structureError = "Plasma panel backgrounds differ from the tested version.";
            return;
        }
        backgrounds = matches;
        structureError = "";
        updateFloating();
    }

    PanelOpacity {
        panelView: root.panelView
        backgrounds: root.backgrounds
        strength: root.backgroundOpacity
    }

    function updateFloating() {
        if (!panelView || !keepFloating) {
            return;
        }
        panelView.floatingnessTarget = panelView.floating ? 1 : 0;
        const hint = PlasmaCore.Types.ContainmentPrefersFloatingApplets;
        const containment = panelView.containment?.plasmoid;
        if (containment) {
            containment.containmentDisplayHints = panelView.floating
                ? containment.containmentDisplayHints | hint : containment.containmentDisplayHints & ~hint;
        }
    }

    Connections {
        target: root.panelView
        function onStateTriggersChanged() { Qt.callLater(root.updateFloating); }
    }

    Connections {
        target: root.host
        function onParentChanged() { Qt.callLater(root.attach); }
    }

    onKeepFloatingChanged: {
        if (panelView) {
            panelView.stateTriggersChanged();
        }
    }
    Component.onCompleted: Qt.callLater(attach)
    Component.onDestruction: {
        if (panelView) {
            panelView.stateTriggersChanged();
        }
    }
}
