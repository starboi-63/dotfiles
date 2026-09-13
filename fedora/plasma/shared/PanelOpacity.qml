import QtQuick
import QtQml.Models

Item {
    id: root

    required property Item panelView
    required property var backgrounds
    property real strength: 1
    property bool active: true

    function updateBackgrounds() {
        const retained = [];

        // Preserves bindings when panel backgrounds are rediscovered.
        for (let index = targets.count - 1; index >= 0; --index) {
            const background = targets.get(index).background;
            if (!root.backgrounds.includes(background)) {
                bindings.objectAt(index).when = false;
                targets.remove(index);
            } else {
                retained.push(background);
            }
        }
        for (const background of root.backgrounds) {
            if (!retained.includes(background)) {
                targets.append({background});
            }
        }
    }

    ListModel { id: targets }

    Instantiator {
        id: bindings
        model: targets
        delegate: Binding {
            required property Item background
            target: background
            property: "opacity"
            value: root.strength * (background?.imagePath?.startsWith("solid/") ? root.panelView?.panelOpacity ?? 1 : 1)
            when: root.active
            restoreMode: Binding.RestoreBindingOrValue
        }
    }

    onBackgroundsChanged: Qt.callLater(updateBackgrounds)
    Component.onCompleted: Qt.callLater(updateBackgrounds)
    Component.onDestruction: active = false
}
