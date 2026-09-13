import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    preferredRepresentation: fullRepresentation
    Layout.minimumWidth: 440
    Layout.preferredWidth: 640
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 34

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
        spacing: 12

        Kirigami.Icon {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.leftMargin: 8
            source: Qt.resolvedUrl("../images/fedora.svg")
            isMask: true
            color: Kirigami.Theme.textColor
            Accessible.name: "Fedora"
        }

        WorkspaceStrip {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 100
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
            Layout.rightMargin: 4
        }
    }
}
