import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "Style.js" as Style

Item {
    id: root

    required property Item panelView
    property Item clock: null
    property Item content: null
    property Item nativeDate: null
    property Item nativeTime: null
    property bool stylingEnabled: true
    property string errorMessage: ""
    readonly property int fontSize: Math.round(100 * Style.config.status.size / reference.capitalHeight)

    FontMetrics {
        id: reference
        font.family: Style.config.status.fontFamily
        font.pixelSize: 100
        font.weight: Style.config.status.fontWeight
    }

    function findClock(item, depth) {
        if (!item || depth > 16) return null;
        if (item.objectName === "digital-clock-compactrepresentation") return item;
        for (const child of item.children) {
            const match = findClock(child, depth + 1);
            if (match) return match;
        }
        return null;
    }

    function attach() {
        clock = findClock(panelView?.containment, 0);
        content = clock?.children.find(child => child.children.some(item => item instanceof Grid)) ?? null;
        const grid = content?.children.find(child => child instanceof Grid);
        nativeTime = grid?.children[0] ?? null;
        nativeDate = content?.children.find(child => typeof child.text === "string") ?? null;
        if (clock && content && nativeDate && nativeTime && typeof nativeTime.text === "string") {
            discovery.stop();
            errorMessage = "";
        } else if (++discovery.attempts >= 20) {
            discovery.stop();
            errorMessage = "Clock appearance requires the tested Plasma clock layout.";
        }
    }

    Timer {
        id: discovery
        property int attempts: 0
        interval: 250
        repeat: true
        running: root.panelView !== null && root.nativeDate === null
        onTriggered: root.attach()
    }

    Binding {
        target: root.content
        property: "opacity"
        value: 0
        when: root.stylingEnabled && root.nativeDate !== null && root.nativeTime !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: root.clock
        property: "Layout.minimumWidth"
        value: labels.implicitWidth + 2 * Style.config.status.clockPadding
        when: root.stylingEnabled && root.nativeDate !== null && root.nativeTime !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: root.clock
        property: "Layout.maximumWidth"
        value: labels.implicitWidth + 2 * Style.config.status.clockPadding
        when: root.stylingEnabled && root.nativeDate !== null && root.nativeTime !== null
        restoreMode: Binding.RestoreBindingOrValue
    }

    Row {
        id: labels
        parent: root.clock
        anchors.centerIn: parent
        spacing: Style.config.status.dateTimeSpacing
        visible: root.stylingEnabled && root.nativeDate !== null && root.nativeTime !== null

        Controls.Label {
            text: root.nativeDate?.text ?? ""
            font.family: Style.config.status.fontFamily
            font.pixelSize: root.fontSize
            font.weight: Style.config.status.fontWeight
            color: Kirigami.Theme.textColor
            textFormat: Text.PlainText
        }

        Controls.Label {
            text: root.nativeTime?.text ?? ""
            font.family: Style.config.status.fontFamily
            font.pixelSize: root.fontSize
            font.weight: Style.config.status.fontWeight
            font.features: { "tnum": 1 }
            color: Kirigami.Theme.textColor
            textFormat: Text.PlainText
        }
    }

    Component.onDestruction: stylingEnabled = false
}
