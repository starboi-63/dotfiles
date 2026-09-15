import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShell
import org.kde.plasma.core as PlasmaCore
import "../../plasma/bar/contents/ui" as Workspace

Window {
    id: root
    width: 600
    height: 62
    property int thickness: 46
    property int visibilityMode: 0
    property bool userConfiguring: false
    property bool attached: false
    property bool styling: true
    property bool keepFloating: true
    property int backgroundCount: 6
    property alias floating: panel.floating
    property alias touchingWindow: panel.touchingWindow
    readonly property real target: panel.floatingnessTarget
    readonly property bool floatingApplets: (containment.plasmoid.containmentDisplayHints
        & PlasmaCore.Types.ContainmentPrefersFloatingApplets) !== 0
    readonly property int zone: LayerShell.Window.exclusionZone
    readonly property var opacities: panel.children.filter(child => child.imagePath !== undefined).map(child => child.opacity)
    LayerShell.Window.exclusionZone: 46

    Item {
        id: panel
        property bool floating: true
        property bool touchingWindow: true
        property real floatingnessTarget: 0
        property real panelOpacity: 0
        property int fixedTopFloatingPadding: 8
        property Item containment: Item {
            id: containment
            property QtObject plasmoid: QtObject { property int containmentDisplayHints: 0 }
        }
        property var stateTriggers: [floating, touchingWindow]
        onStateTriggersChanged: {
            floatingnessTarget = floating && !touchingWindow ? 1 : 0;
            const hint = PlasmaCore.Types.ContainmentPrefersFloatingApplets;
            containment.plasmoid.containmentDisplayHints = floatingnessTarget
                ? containment.plasmoid.containmentDisplayHints | hint
                : containment.plasmoid.containmentDisplayHints & ~hint;
        }

        Repeater {
            model: root.backgroundCount
            delegate: Item {
                required property int index
                property string imagePath: index < 4 ? "widgets/panel-background" : "solid/widgets/panel-background"
                opacity: index < 4 ? 1 : panel.panelOpacity
            }
        }
    }

    Item {
        id: container
        parent: root.attached ? panel : root.contentItem
        Item {
            id: widgetHost
            Loader {
                active: root.styling
                sourceComponent: Workspace.PanelAppearance {
                    host: widgetHost
                    keepFloating: root.keepFloating
                    backgroundOpacity: 0.33
                }
            }
        }
    }
}
