import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property Item panelView: null
    property var backgrounds: []
    property string errorMessage: ""
    readonly property bool editMode: Plasmoid.containment.corona?.editMode ?? false

    Plasmoid.status: editMode || errorMessage ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    preferredRepresentation: fullRepresentation
    Layout.minimumWidth: Kirigami.Units.iconSizes.smallMedium
    Layout.maximumWidth: Layout.minimumWidth
    toolTipMainText: "Dock Appearance"
    toolTipSubText: errorMessage || "Matches the configured bar background strength."

    PanelOpacity {
        panelView: root.panelView
        backgrounds: root.backgrounds
        active: Plasmoid.configuration.matchBarOpacity && root.backgrounds.length === 6
        strength: Plasmoid.configuration.backgroundOpacity / 100
    }

    fullRepresentation: Kirigami.Icon {
        source: root.errorMessage ? "dialog-error" : "preferences-desktop-theme"
    }

    function attach() {
        let item = root.parent;
        while (item && !(typeof item.floatingnessTarget === "number" && typeof item.floating === "boolean")) {
            item = item.parent;
        }
        panelView = item;
        backgrounds = panelView?.children.filter(child => child.imagePath === "widgets/panel-background"
            || child.imagePath === "solid/widgets/panel-background") ?? [];
        errorMessage = backgrounds.length === 6 ? "" : "Dock appearance requires a compatible Plasma panel.";
    }

    onParentChanged: Qt.callLater(attach)
    Component.onCompleted: Qt.callLater(attach)
}
