import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string errorMessage: attachment.errorMessage
    readonly property bool editMode: Plasmoid.containment.corona?.editMode ?? false

    Plasmoid.status: editMode || errorMessage ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    preferredRepresentation: fullRepresentation
    Layout.minimumWidth: Kirigami.Units.iconSizes.smallMedium
    Layout.maximumWidth: Layout.minimumWidth
    toolTipMainText: "Dock Appearance"
    toolTipSubText: errorMessage || "Matches the configured bar background strength."

    PanelAttachment {
        id: attachment
        host: root
    }

    PanelOpacity {
        panelView: attachment.panelView
        backgrounds: attachment.backgrounds
        active: Plasmoid.configuration.matchBarOpacity && attachment.backgrounds.length === 6
        strength: Plasmoid.configuration.backgroundOpacity / 100
    }

    fullRepresentation: Kirigami.Icon {
        source: root.errorMessage ? "dialog-error" : "preferences-desktop-theme"
    }
}
