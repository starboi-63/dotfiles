import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShell

Item {
    id: root

    required property Item panelView
    property bool reserveFloating: true
    property string errorMessage: ""
    property int appliedZone: -1
    readonly property var panelWindow: panelView?.Window.window ?? null
    readonly property var layerWindow: panelWindow?.LayerShell.Window ?? null
    // Matches PanelView::NormalPanel in Plasma's native window API.
    readonly property bool normalPanel: panelWindow?.visibilityMode === 0
    readonly property bool active: enabled && panelWindow !== null
        && normalPanel && !panelWindow.userConfiguring
    readonly property int reservedHeight: panelWindow === null ? 0 : panelWindow.thickness
        + (reserveFloating && panelView.floating ? panelView.fixedTopFloatingPadding : 0)

    function updateReservation() {
        if (!active || !layerWindow || layerWindow.exclusionZone < 0) return;
        if (reservedHeight < panelWindow.thickness || typeof panelWindow.update !== "function") {
            errorMessage = "Panel reservation requires the tested Plasma window interface.";
            return;
        }
        if (layerWindow.exclusionZone !== reservedHeight) {
            layerWindow.exclusionZone = reservedHeight;
            panelWindow.update();
        }
        appliedZone = reservedHeight;
        errorMessage = layerWindow.exclusionZone === reservedHeight
            ? "" : "Plasma did not retain the floating panel reservation.";
    }

    function releaseReservation() {
        if (appliedZone < 0 || !panelWindow || !layerWindow || panelWindow.userConfiguring) return;
        if (layerWindow.exclusionZone === appliedZone) {
            layerWindow.exclusionZone = normalPanel ? panelWindow.thickness : -1;
            panelWindow.update();
        }
        appliedZone = -1;
    }

    Connections {
        target: root.layerWindow
        function onExclusionZoneChanged() { root.updateReservation(); }
    }

    onActiveChanged: {
        if (active) Qt.callLater(updateReservation);
        else releaseReservation();
    }
    onReservedHeightChanged: updateReservation()
    Component.onCompleted: Qt.callLater(updateReservation)
    Component.onDestruction: {
        enabled = false;
        releaseReservation();
    }
}
