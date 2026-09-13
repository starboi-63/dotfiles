pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

RowLayout {
    spacing: 18

    RowLayout {
        spacing: 6

        Sensors.Sensor {
            id: cpu
            sensorId: "cpu/all/usage"
            updateRateLimit: 2000
        }

        Controls.Label {
            text: "CPU"
            font.family: "Adwaita Sans"
            font.pixelSize: 11
            font.letterSpacing: 0.4
            opacity: 0.7
        }

        Controls.Label {
            Layout.preferredWidth: 44
            text: cpu.status === Sensors.Sensor.Ready ? cpu.formattedValue : "—"
            font.family: "Adwaita Sans"
            font.pixelSize: 13
            font.features: { "tnum": 1 }
            textFormat: Text.PlainText
        }

        HoverHandler { id: cpuHover }
        Controls.ToolTip.visible: cpuHover.hovered
        Controls.ToolTip.delay: 450
        Controls.ToolTip.text: cpu.status === Sensors.Sensor.Ready ? cpu.name : "CPU sensor unavailable"
    }

    ColumnLayout {
        spacing: 0

        Repeater {
            model: [
                { sensor: "network/all/upload", rotation: 0 },
                { sensor: "network/all/download", rotation: 180 }
            ]

            delegate: RowLayout {
                id: reading
                required property var modelData
                spacing: 4

                Sensors.Sensor {
                    id: sensor
                    sensorId: reading.modelData.sensor
                    updateRateLimit: 2000
                }

                Kirigami.Icon {
                    Layout.preferredWidth: 10
                    Layout.preferredHeight: 10
                    source: Qt.resolvedUrl("../images/transfer.svg")
                    rotation: reading.modelData.rotation
                    isMask: true
                    color: Kirigami.Theme.textColor
                    opacity: 0.75
                }

                Controls.Label {
                    Layout.minimumWidth: 52
                    text: sensor.status === Sensors.Sensor.Ready ? sensor.formattedValue : "—"
                    font.family: "Adwaita Sans"
                    font.pixelSize: 11
                    font.features: { "tnum": 1 }
                    textFormat: Text.PlainText
                }

                HoverHandler { id: hover }
                Controls.ToolTip.visible: hover.hovered
                Controls.ToolTip.delay: 450
                Controls.ToolTip.text: sensor.status === Sensors.Sensor.Ready ? sensor.name : "Network sensor unavailable"
            }
        }
    }
}
