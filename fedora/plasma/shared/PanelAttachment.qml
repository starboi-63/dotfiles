import QtQuick

QtObject {
    required property Item host

    // Tracks every ancestor so Plasma can move containers between panel windows.
    readonly property Item panelView: {
        let item = host.parent;
        while (item && !(typeof item.floatingnessTarget === "number" && typeof item.floating === "boolean")) {
            item = item.parent;
        }
        return item;
    }
    readonly property var backgrounds: panelView?.children.filter(child => child.imagePath === "widgets/panel-background"
        || child.imagePath === "solid/widgets/panel-background") ?? []
    readonly property string errorMessage: !panelView ? "Panel appearance requires a compatible Plasma panel."
        : backgrounds.length !== 6 ? "Plasma panel backgrounds differ from the tested version." : ""
}
