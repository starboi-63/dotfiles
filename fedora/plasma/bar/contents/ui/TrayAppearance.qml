pragma ComponentBehavior: Bound

import QtQuick
import "Style.js" as Style
import QtQml.Models
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property Item panelView
    property Item tray: null
    property Item expander: null
    property string errorMessage: ""
    property bool stylingEnabled: true

    Component.onDestruction: stylingEnabled = false

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
            updateLoaders();
        } else if (++discovery.attempts >= 20) {
            discovery.stop();
            errorMessage = "Tray appearance requires the tested Plasma tray layout.";
        }
    }

    function updateLoaders() {
        const currentLoaders = tray?.visibleLayout.contentItem.children.filter(child => child instanceof Loader) ?? [];
        const retainedLoaders = [];

        // Preserves existing bindings when native tray delegates change.
        for (let index = iconLoaders.count - 1; index >= 0; --index) {
            const loader = iconLoaders.get(index).loader;
            if (!currentLoaders.includes(loader)) {
                iconLoaders.remove(index);
            } else {
                retainedLoaders.push(loader);
            }
        }
        for (const loader of currentLoaders) {
            if (!retainedLoaders.includes(loader)) {
                iconLoaders.append({loader});
            }
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
        value: Style.config.status.size + Style.config.status.spacing
        when: root.stylingEnabled && root.tray !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    ListModel { id: iconLoaders }

    Connections {
        target: root.tray?.visibleLayout.contentItem ?? null
        function onChildrenChanged() { Qt.callLater(root.updateLoaders); }
    }

    Instantiator {
        model: iconLoaders

        delegate: QtObject {
            required property Item loader
            readonly property Item icon: loader?.item?.iconContainer ?? null
            property Binding iconWidth: Binding {
                target: icon
                property: "implicitWidth"
                value: Style.config.status.size
                when: root.stylingEnabled && icon !== null
                restoreMode: Binding.RestoreBindingOrValue
            }
            property Binding iconHeight: Binding {
                target: icon
                property: "implicitHeight"
                value: Style.config.status.size
                when: root.stylingEnabled && icon !== null
                restoreMode: Binding.RestoreBindingOrValue
            }
        }
    }

    Binding {
        target: root.expander
        property: "iconSize"
        value: Style.config.status.expanderWidth
        when: root.stylingEnabled && root.expander !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    Instantiator {
        model: root.expander?.children.filter(child => child instanceof Kirigami.Icon && child !== chevron) ?? []
        delegate: Binding {
            required property var modelData
            target: modelData
            property: "visible"
            value: false
            when: root.stylingEnabled
            restoreMode: Binding.RestoreBindingOrValue
        }
    }

    Kirigami.Icon {
        id: chevron
        parent: root.expander
        anchors.centerIn: parent
        width: Style.config.status.size
        height: Style.config.status.size
        visible: root.expander !== null
        source: Qt.resolvedUrl("../icons/chevron.svg")
        isMask: true
        color: Kirigami.Theme.textColor
        rotation: root.tray?.systemTrayState.expanded ? 180 : 0

        Behavior on rotation {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration > 0 ? Style.config.status.chevronDuration : 0
                easing.type: Easing.OutCubic
            }
        }
    }
}
