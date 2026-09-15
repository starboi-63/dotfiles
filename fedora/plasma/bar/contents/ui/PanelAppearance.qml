import QtQuick
import org.kde.plasma.core as PlasmaCore

Item {
    id: root

    required property Item host
    property bool keepFloating: true
    property real backgroundOpacity: 1
    property bool active: true
    property Item floatingPanel: null
    readonly property Item panelView: attachment.panelView
    readonly property string errorMessage: attachment.errorMessage || reservation.errorMessage

    PanelAttachment {
        id: attachment
        host: root.host
    }

    PanelReservation {
        id: reservation
        panelView: root.panelView
        reserveFloating: root.keepFloating
    }

    PanelOpacity {
        panelView: root.panelView
        backgrounds: attachment.backgrounds
        strength: root.backgroundOpacity
    }

    function updateFloating() {
        if (floatingPanel !== panelView) {
            const previousPanel = floatingPanel;
            floatingPanel = panelView;
            previousPanel?.stateTriggersChanged();
        }
        if (!active || !panelView || !keepFloating) {
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
        enabled: root.active
        function onStateTriggersChanged() { Qt.callLater(root.updateFloating); }
    }

    onPanelViewChanged: Qt.callLater(updateFloating)
    onKeepFloatingChanged: {
        if (panelView) {
            panelView.stateTriggersChanged();
        }
    }
    Component.onCompleted: Qt.callLater(updateFloating)
    Component.onDestruction: {
        active = false;
        floatingPanel?.stateTriggersChanged();
    }
}
