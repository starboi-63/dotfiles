import QtQuick
import "../../plasma/shared"

Window {
    id: root
    visible: true
    width: 200
    height: 100
    property real nativeStrength: 0.8
    property real panelStrength: 0.6
    property real strength: 0.33
    property bool matching: true
    property bool mounted: true
    property int selectedCount: 6
    property bool reverseOrder: false
    property int changes: 0
    readonly property var backgrounds: panel.children.filter(child => child.imagePath !== undefined)
    readonly property var selected: reverseOrder ? backgrounds.slice(0, selectedCount).reverse() : backgrounds.slice(0, selectedCount)
    readonly property var values: backgrounds.map(child => child.opacity)

    Item {
        id: panel
        property real panelOpacity: root.panelStrength
        Repeater {
            model: 6
            delegate: Rectangle {
                required property int index
                property string imagePath: index < 3 ? "widgets/panel-background" : "solid/widgets/panel-background"
                opacity: root.nativeStrength * (index < 3 ? 1 : panel.panelOpacity)
                onOpacityChanged: root.changes += 1
            }
        }
    }

    Loader {
        active: root.mounted
        sourceComponent: PanelOpacity {
            panelView: panel
            backgrounds: root.selected
            active: root.matching
            strength: root.strength
        }
    }
}
