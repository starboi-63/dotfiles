pragma ComponentBehavior: Bound

import QtQuick
import "Style.js" as Style
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

Item {
    id: root

    required property var desktopIds
    required property var desktopNames
    required property rect screenGeometry
    required property int currentDesktop
    property int maximumIcons: Style.config.workspaces.maximumIcons
    property string errorMessage: ""

    signal desktopActivated(int position)
    signal desktopCreated()

    implicitWidth: desktopRow.implicitWidth
    implicitHeight: Style.config.workspaces.height

    function revealCurrent() {
        const button = desktopButtons.itemAt(currentDesktop);
        if (!button) {
            return;
        }

        const left = button.x;
        const right = left + button.width;
        if (left < viewport.contentX) {
            viewport.contentX = left;
        } else if (right > viewport.contentX + viewport.width) {
            viewport.contentX = Math.min(right - viewport.width, viewport.contentWidth - viewport.width);
        }
    }

    onCurrentDesktopChanged: Qt.callLater(revealCurrent)
    onWidthChanged: Qt.callLater(revealCurrent)

    Flickable {
        id: viewport

        anchors.fill: parent
        anchors.margins: Style.config.workspaces.inset
        contentWidth: desktopRow.implicitWidth
        contentHeight: height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        Controls.ScrollBar.horizontal: Controls.ScrollBar { policy: Controls.ScrollBar.AsNeeded }

        Row {
            id: desktopRow

            height: viewport.height
            spacing: Style.config.workspaces.spacing

            Repeater {
                id: desktopButtons
                model: root.desktopIds

                delegate: Controls.AbstractButton {
                    id: desktopButton

                    required property int index
                    required property string modelData
                    readonly property string desktopName: root.desktopNames[index] || "Desktop " + (index + 1)

                    TaskManager.TasksModel {
                        id: tasks
                        virtualDesktop: desktopButton.modelData
                        screenGeometry: root.screenGeometry
                        filterByVirtualDesktop: true
                        filterByScreen: true
                        groupMode: TaskManager.TasksModel.GroupDisabled
                    }

                    readonly property bool active: index === root.currentDesktop

                    objectName: "desktop-" + index
                    height: desktopRow.height
                    width: contentRow.implicitWidth + leftPadding + rightPadding
                    leftPadding: Style.config.workspaces.padding
                    rightPadding: Style.config.workspaces.padding
                    hoverEnabled: true
                    Accessible.name: desktopName
                    Accessible.description: "Switch to workspace " + (index + 1)

                    onClicked: root.desktopActivated(index)

                    background: Rectangle {
                        radius: Style.config.workspaces.cornerRadius
                        color: desktopButton.active
                            ? Qt.alpha(Kirigami.Theme.highlightColor, Style.config.workspaces.activeOpacity)
                            : Qt.alpha(Kirigami.Theme.textColor, desktopButton.hovered ? Style.config.workspaces.hoverOpacity : Style.config.workspaces.idleOpacity)
                        border.width: desktopButton.active || desktopButton.visualFocus ? 1 : 0
                        border.color: Qt.alpha(Kirigami.Theme.highlightColor, Style.config.workspaces.borderOpacity)
                    }

                    contentItem: Row {
                        id: contentRow
                        spacing: Style.config.workspaces.iconSpacing

                        Controls.Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: desktopButton.index + 1
                            font.weight: Font.DemiBold
                            color: Kirigami.Theme.textColor

                            PanelToolTip {
                                anchors.fill: parent
                                mainText: desktopButton.desktopName
                                subText: windows.count + (windows.count === 1 ? " window" : " windows")
                            }
                        }

                        Repeater {
                            id: windows
                            model: tasks

                            delegate: Item {
                                id: windowItem

                                required property int index
                                required property string display
                                required property var decoration
                                required property var model
                                readonly property string applicationName: model.AppName || ""

                                anchors.verticalCenter: parent.verticalCenter
                                visible: index < root.maximumIcons
                                width: visible ? Style.config.workspaces.iconWidth : 0
                                height: Style.config.workspaces.iconHeight

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: Style.config.workspaces.iconSize
                                    height: Style.config.workspaces.iconSize
                                    source: windowItem.decoration || "application-x-executable"
                                    animated: false
                                    opacity: windowItem.model.IsMinimized ? Style.config.workspaces.minimizedOpacity : 1
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: Style.config.workspaces.indicatorSize
                                    height: Style.config.workspaces.indicatorSize
                                    radius: Style.config.workspaces.indicatorRadius
                                    visible: windowItem.model.IsActive
                                    color: Kirigami.Theme.highlightColor
                                }

                                PanelToolTip {
                                    anchors.fill: parent
                                    mainText: windowItem.applicationName || windowItem.display
                                    subText: windowItem.applicationName ? windowItem.display : ""
                                }
                            }
                        }

                        Controls.Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: windows.count > root.maximumIcons
                            text: "+" + (windows.count - root.maximumIcons)
                            opacity: Style.config.workspaces.overflowOpacity
                        }

                        Controls.Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: windows.count === 0
                            text: "·"
                            opacity: Style.config.workspaces.emptyOpacity
                        }
                    }
                }
            }

            Controls.ToolButton {
                objectName: "create-desktop"
                anchors.verticalCenter: parent.verticalCenter
                width: Style.config.workspaces.createWidth
                height: desktopRow.height
                icon.name: "list-add"
                Accessible.name: "Create desktop"
                onClicked: root.desktopCreated()
                PanelToolTip {
                    anchors.fill: parent
                    mainText: "Create desktop (Alt+N)"
                }
            }

            Controls.Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.errorMessage.length > 0
                text: root.errorMessage
                color: Kirigami.Theme.negativeTextColor
            }
        }
    }
}
