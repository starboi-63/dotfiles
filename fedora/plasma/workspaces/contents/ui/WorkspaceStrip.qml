pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager

Item {
    id: root

    required property var desktopIds
    required property var desktopNames
    required property rect screenGeometry
    required property int currentDesktop
    property int maximumIcons: 6
    property string errorMessage: ""

    signal desktopActivated(int position)
    signal desktopCreated()

    implicitWidth: desktopRow.implicitWidth
    implicitHeight: 34

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
        anchors.margins: 2
        contentWidth: desktopRow.implicitWidth
        contentHeight: height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        Controls.ScrollBar.horizontal: Controls.ScrollBar { policy: Controls.ScrollBar.AsNeeded }

        Row {
            id: desktopRow

            height: viewport.height
            spacing: Kirigami.Units.smallSpacing

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
                    leftPadding: 12
                    rightPadding: 12
                    hoverEnabled: true
                    Accessible.name: desktopName
                    Accessible.description: "Switch to workspace " + (index + 1)

                    onClicked: root.desktopActivated(index)

                    background: Rectangle {
                        radius: Kirigami.Units.cornerRadius
                        color: desktopButton.active
                            ? Qt.alpha(Kirigami.Theme.highlightColor, 0.22)
                            : Qt.alpha(Kirigami.Theme.textColor, desktopButton.hovered ? 0.10 : 0.04)
                        border.width: desktopButton.active || desktopButton.visualFocus ? 1 : 0
                        border.color: Qt.alpha(Kirigami.Theme.highlightColor, 0.65)
                    }

                    contentItem: Row {
                        id: contentRow
                        spacing: 7

                        Controls.Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: desktopButton.index + 1
                            font.weight: Font.DemiBold
                            color: Kirigami.Theme.textColor

                            PlasmaCore.ToolTipArea {
                                anchors.fill: parent
                                mainText: desktopButton.desktopName
                                subText: windows.count + (windows.count === 1 ? " window" : " windows")
                                textFormat: Text.PlainText
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
                                width: visible ? 20 : 0
                                height: 22

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: 18
                                    height: 18
                                    source: windowItem.decoration || "application-x-executable"
                                    animated: false
                                    opacity: windowItem.model.IsMinimized ? 0.5 : 1
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 3
                                    height: 3
                                    radius: 2
                                    visible: windowItem.model.IsActive
                                    color: Kirigami.Theme.highlightColor
                                }

                                HoverHandler { id: iconHover }

                                Controls.ToolTip {
                                    id: windowTooltip

                                    visible: iconHover.hovered
                                    delay: 450
                                    contentItem: Item {
                                        implicitWidth: Math.min(360, Math.max(applicationLabel.implicitWidth, titleLabel.implicitWidth))
                                        implicitHeight: tooltipText.implicitHeight

                                        Column {
                                            id: tooltipText
                                            width: parent.width
                                            spacing: 2

                                            Controls.Label {
                                                id: applicationLabel
                                                width: parent.width
                                                text: windowItem.applicationName || windowItem.display
                                                font.pointSize: windowTooltip.font.pointSize
                                                font.weight: Font.DemiBold
                                                textFormat: Text.PlainText
                                                wrapMode: Text.Wrap
                                            }

                                            Controls.Label {
                                                id: titleLabel
                                                width: parent.width
                                                visible: windowItem.applicationName.length > 0 && windowItem.applicationName !== windowItem.display
                                                text: windowItem.display
                                                font: windowTooltip.font
                                                opacity: 0.75
                                                textFormat: Text.PlainText
                                                wrapMode: Text.Wrap
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Controls.Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: windows.count > root.maximumIcons
                            text: "+" + (windows.count - root.maximumIcons)
                            opacity: 0.7
                        }

                        Controls.Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: windows.count === 0
                            text: "·"
                            opacity: 0.4
                        }
                    }
                }
            }

            Controls.ToolButton {
                objectName: "create-desktop"
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: desktopRow.height
                icon.name: "list-add"
                Accessible.name: "Create desktop"
                onClicked: root.desktopCreated()
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: "Create desktop (Alt+N)"
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
