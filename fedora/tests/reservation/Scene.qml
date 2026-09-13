import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShell
import "../../plasma/bar/contents/ui" as Workspace

Window {
    id: root
    width: 600
    height: 62
    property int thickness: 46
    property int visibilityMode: 0
    property bool userConfiguring: false
    property bool styling: true
    property alias floating: panel.floating
    property alias padding: panel.fixedTopFloatingPadding
    readonly property int zone: LayerShell.Window.exclusionZone
    property int changes: 0
    LayerShell.Window.exclusionZone: 46

    Connections {
        target: root.LayerShell.Window
        function onExclusionZoneChanged() { root.changes++; }
    }

    Item {
        id: panel
        anchors.fill: parent
        property bool floating: true
        property int fixedTopFloatingPadding: 8
        Loader {
            active: root.styling
            sourceComponent: Workspace.PanelReservation { panelView: panel }
        }
    }

    function nativeZone(value: int) { root.LayerShell.Window.exclusionZone = value; }
}
