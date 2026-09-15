import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShell

Item {
    id: root

    required property Item panelView
    property bool reserveFloating: true
    property string errorMessage: ""
    property int appliedZone: -1
    property QtObject reservedWindow: null
    property QtObject reservedLayerWindow: null
    property bool releasing: false
    readonly property var panelWindow: panelView?.Window.window ?? null
    readonly property var layerWindow: panelWindow?.LayerShell.Window ?? null

    // Matches PanelView::NormalPanel in Plasma's native window API.
    readonly property bool normalPanel: panelWindow?.visibilityMode === 0
    readonly property bool active: enabled && panelWindow !== null
        && normalPanel && !panelWindow.userConfiguring
    readonly property int reservedHeight: panelWindow === null ? 0 : panelWindow.thickness
        + (reserveFloating && panelView.floating ? panelView.fixedTopFloatingPadding : 0)

    function updateReservation() {
        if (releasing) return;
        if (reservedWindow !== panelWindow) releaseReservation();
        if (!active || !layerWindow || layerWindow !== panelWindow.LayerShell.Window || layerWindow.exclusionZone < 0) return;
        if (reservedHeight < panelWindow.thickness || typeof panelWindow.update !== "function") {
            errorMessage = "Panel reservation requires the tested Plasma window interface.";
            return;
        }
        if (layerWindow.exclusionZone !== reservedHeight) {
            layerWindow.exclusionZone = reservedHeight;
            panelWindow.update();
        }
        appliedZone = reservedHeight;
        reservedWindow = panelWindow;
        reservedLayerWindow = layerWindow;
        errorMessage = layerWindow.exclusionZone === reservedHeight
            ? "" : "Plasma did not retain the floating panel reservation.";
    }

    function releaseReservation() {
        if (appliedZone < 0 || !reservedWindow || !reservedLayerWindow || reservedWindow.userConfiguring) return;
        releasing = true;
        if (reservedLayerWindow.exclusionZone === appliedZone) {
            reservedLayerWindow.exclusionZone = reservedWindow.visibilityMode === 0 ? reservedWindow.thickness : -1;
            reservedWindow.update();
        }
        appliedZone = -1;
        reservedWindow = null;
        reservedLayerWindow = null;
        releasing = false;
    }

    Connections {
        target: root.layerWindow
        function onExclusionZoneChanged() { root.updateReservation(); }
    }

    onActiveChanged: {
        if (active) Qt.callLater(updateReservation);
        else releaseReservation();
    }
    onPanelWindowChanged: {
        if (reservedWindow !== panelWindow) releaseReservation();
        Qt.callLater(updateReservation);
    }
    onReservedHeightChanged: updateReservation()
    Component.onCompleted: Qt.callLater(updateReservation)
    Component.onDestruction: {
        enabled = false;
        releaseReservation();
    }
}
