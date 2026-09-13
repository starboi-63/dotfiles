import QtQuick
import "Style.js" as Style
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    preferredRepresentation: fullRepresentation
    Layout.minimumWidth: Style.config.bar.minimumWidth
    Layout.preferredWidth: Style.config.bar.preferredWidth
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: Style.config.workspaces.height

    DesktopModel {
        id: desktops
        screenName: root.Screen.name
    }

    PanelAppearance {
        id: appearance
        host: root
        keepFloating: Plasmoid.configuration.keepFloating
        backgroundOpacity: Plasmoid.configuration.backgroundOpacity / 100
    }

    TrayAppearance {
        id: trayAppearance
        panelView: appearance.panelView
    }

    fullRepresentation: RowLayout {
        spacing: Style.config.bar.sectionSpacing

        Kirigami.Icon {
            Layout.preferredWidth: Style.config.bar.logoSize
            Layout.preferredHeight: Style.config.bar.logoSize
            Layout.leftMargin: Style.config.bar.padding
            source: Qt.resolvedUrl("../icons/fedora.svg")
            isMask: true
            color: Kirigami.Theme.textColor
            Accessible.name: "Fedora"
        }

        WorkspaceStrip {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: Style.config.workspaces.minimumWidth
            desktopIds: desktops.desktopIds
            desktopNames: desktops.desktopNames
            currentDesktop: desktops.desktopIds.indexOf(desktops.currentDesktop)
            screenGeometry: Plasmoid.containment.screenGeometry
            maximumIcons: Plasmoid.configuration.maximumIcons
            errorMessage: desktops.errorMessage || appearance.errorMessage || trayAppearance.errorMessage

            onDesktopActivated: position => desktops.changeDesktop(position)
            onDesktopCreated: desktops.createDesktop()
        }

        SystemStats {
            Layout.rightMargin: Style.config.metrics.rightPadding
        }
    }
}
