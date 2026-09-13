import QtQuick
import QtQml.Models
import org.kde.plasma.core as PlasmaCore

Item {
    id: root

    required property Item host
    property bool keepFloating: true
    property real backgroundOpacity: 1
    property Item panelView: null
    property var backgrounds: []
    property Item marginFrame: null
    property bool stylingEnabled: true
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
        const matches = panelView.children.filter(child => child === marginFrame || child.imagePath === "widgets/panel-background"
            || child.imagePath === "solid/widgets/panel-background");
        if (matches.length !== 6) {
            structureError = "Plasma panel backgrounds differ from the tested version.";
            return;
        }
        backgrounds = matches;
        marginFrame = matches.find(child => child.prefix?.[0] === "floating") ?? null;
        if (!marginFrame) {
            structureError = "Panel floating margin metadata is unavailable.";
            return;
        }
        structureError = "";
        updateFloating();
    }

    Binding {
        target: root.marginFrame
        property: "imagePath"
        value: Qt.resolvedUrl("../icons/panel-margins.svg")
        when: root.stylingEnabled && root.marginFrame !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    Instantiator {
        model: root.backgrounds
        delegate: Binding {
            required property var modelData
            target: modelData
            property: "opacity"
            value: root.backgroundOpacity * (modelData.imagePath?.startsWith("solid/") ? root.panelView?.panelOpacity ?? 1 : 1)
            when: root.stylingEnabled
            restoreMode: Binding.RestoreBindingOrValue
        }
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
        stylingEnabled = false;
        if (panelView) {
            panelView.stateTriggersChanged();
        }
    }
}
