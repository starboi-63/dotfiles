pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property Item panelView
    property Item tray: null
    property Item expander: null
    property string errorMessage: ""

    function findTray(item, depth) {
        if (!item || depth > 16) {
            return null;
        }
        if (item.systemTrayState && item.visibleLayout && item.hiddenLayout) {
            return item;
        }
        for (const child of item.children) {
            const match = findTray(child, depth + 1);
            if (match) {
                return match;
            }
        }
        return null;
    }

    function attach() {
        tray = findTray(panelView?.containment, 0);
        expander = tray?.visibleLayout.parent.children.find(child => typeof child.arrowAnimationDuration === "number") ?? null;
        if (tray && expander) {
            discovery.stop();
            errorMessage = "";
        } else if (++discovery.attempts >= 20) {
            discovery.stop();
            errorMessage = "Tray appearance requires the tested Plasma tray layout.";
        }
    }

    Timer {
        id: discovery
        property int attempts: 0
        interval: 250
        repeat: true
        running: root.panelView !== null && root.tray === null
        onTriggered: root.attach()
    }

    Binding {
        target: root.tray?.visibleLayout ?? null
        property: "cellWidth"
        value: 28
        when: root.tray !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    Instantiator {
        model: root.tray?.visibleLayout.contentItem.children ?? []

        delegate: QtObject {
            required property var modelData
            readonly property Item icon: modelData.item?.iconContainer ?? null
            property Binding iconWidth: Binding {
                target: icon
                property: "implicitWidth"
                value: 18
                when: icon !== null
                restoreMode: Binding.RestoreBindingOrValue
            }
            property Binding iconHeight: Binding {
                target: icon
                property: "implicitHeight"
                value: 18
                when: icon !== null
                restoreMode: Binding.RestoreBindingOrValue
            }
        }
    }

    Binding {
        target: root.expander
        property: "iconSize"
        value: 24
        when: root.expander !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    Instantiator {
        model: root.expander?.children.filter(child => child instanceof Kirigami.Icon && child !== chevron) ?? []
        delegate: Binding {
            required property var modelData
            target: modelData
            property: "visible"
            value: false
            restoreMode: Binding.RestoreBindingOrValue
        }
    }

    Kirigami.Icon {
        id: chevron
        parent: root.expander
        anchors.centerIn: parent
        width: 18
        height: 18
        visible: root.expander !== null
        source: Qt.resolvedUrl("../images/chevron.svg")
        isMask: true
        color: Kirigami.Theme.textColor
        rotation: root.tray?.systemTrayState.expanded ? 180 : 0

        Behavior on rotation {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration > 0 ? 140 : 0
                easing.type: Easing.OutCubic
            }
        }
    }
}
