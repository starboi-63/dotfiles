import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../.build/plasma/bar/contents/ui" as Workspace

Item {
    id: root

    width: 600
    height: 46
    property alias containment: containment
    property bool loadIcons: true
    property alias styling: styling.active

    Item {
        id: containment
        anchors.fill: parent

        Item {
            anchors.fill: parent
            property QtObject systemTrayState: QtObject { property bool expanded: false }
            property alias visibleLayout: grid
            property QtObject hiddenLayout: QtObject {}

            RowLayout {
                anchors.fill: parent
                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    cellWidth: 30
                    cellHeight: 38
                    model: ListModel {
                        id: rows
                        ListElement { title: "first" }
                        ListElement { title: "second" }
                    }
                    delegate: Loader {
                        width: grid.cellWidth
                        height: grid.cellHeight
                        active: root.loadIcons
                        sourceComponent: Item {
                            property alias iconContainer: iconContainer
                            RowLayout {
                                anchors.fill: parent
                                Item {
                                    id: iconContainer
                                    property real nativeSize: 22
                                    implicitWidth: nativeSize
                                    implicitHeight: 38
                                    Layout.alignment: Qt.AlignCenter
                                }
                            }
                        }
                    }
                }
                Item {
                    id: expander
                    property int arrowAnimationDuration: 150
                    property int iconSize: 22
                    implicitWidth: iconSize
                    implicitHeight: iconSize
                    Kirigami.Icon { source: "arrow-down-symbolic"; anchors.fill: parent }
                    Kirigami.Icon { source: "arrow-up-symbolic"; anchors.fill: parent; opacity: 0 }
                }
            }
        }
    }

    Loader {
        id: styling
        sourceComponent: Workspace.TrayAppearance { panelView: root }
    }

    function snapshot(): string {
        return JSON.stringify(grid.contentItem.children.map(loader => loader.item?.iconContainer)
            .filter(icon => icon).map(icon => ({
                width: icon.width, height: icon.height,
                implicitWidth: icon.implicitWidth, implicitHeight: icon.implicitHeight
            })));
    }

    function appearance(): string {
        return JSON.stringify({
            cellWidth: grid.cellWidth, expanderWidth: expander.iconSize,
            visibleArrows: expander.children.filter(child => child instanceof Kirigami.Icon && child.visible).length
        });
    }

    function append() { rows.append({title: "late"}); }
    function remove() { rows.remove(0); }
    function reorder() { rows.move(0, rows.count - 1, 1); }
    function clear() { rows.clear(); }
    function resizeNativeIcons() {
        grid.contentItem.children.forEach(loader => {
            if (loader.item?.iconContainer) {
                loader.item.iconContainer.nativeSize = 24;
            }
        });
    }
}
