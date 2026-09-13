import QtQuick
import QtQuick.Controls as Controls
import "../../.build/plasma/bar/contents/ui" as Workspace

Item {
    id: root
    width: 400
    height: 46
    property int clicks: 0
    property bool showing: false
    property QtObject first: firstTooltip
    property QtObject second: secondTooltip

    Controls.AbstractButton {
        x: 50
        y: 12
        width: 20
        height: 22
        onClicked: root.clicks++
        Workspace.PanelToolTip {
            id: firstTooltip
            anchors.fill: parent
            mainText: "ChatGPT"
            subText: "ChatGPT"
            onToolTipVisibleChanged: visible => root.showing = visible
        }
    }
    Controls.AbstractButton {
        x: 100
        y: 12
        width: 20
        height: 22
        onClicked: root.clicks++
        Workspace.PanelToolTip {
            id: secondTooltip
            anchors.fill: parent
            mainText: "Zed"
            subText: "A very long project title that must wrap inside the compact tooltip without covering either icon. ".repeat(5)
            onToolTipVisibleChanged: visible => root.showing = visible
        }
    }
}
