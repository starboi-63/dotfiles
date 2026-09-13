pragma ComponentBehavior: Bound

import QtQuick
import "Style.js" as Style
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

RowLayout {
    spacing: Style.config.metrics.spacing

    PanelToolTip {
        implicitWidth: cpuReading.implicitWidth
        implicitHeight: cpuReading.implicitHeight
        mainText: cpu.status === Sensors.Sensor.Ready ? cpu.name : "CPU sensor unavailable"

        Sensors.Sensor {
            id: cpu
            sensorId: "cpu/all/usage"
            updateRateLimit: 2000
        }

        RowLayout {
            id: cpuReading
            anchors.fill: parent
            spacing: Style.config.metrics.labelSpacing

            Controls.Label {
                text: "CPU"
                font.family: Style.config.metrics.fontFamily
                font.pixelSize: Style.config.metrics.labelSize
                font.letterSpacing: Style.config.metrics.labelTracking
                opacity: Style.config.metrics.labelOpacity
            }

            Controls.Label {
                Layout.preferredWidth: Style.config.metrics.cpuWidth
                text: cpu.status === Sensors.Sensor.Ready ? cpu.formattedValue : "—"
                font.family: Style.config.metrics.fontFamily
                font.pixelSize: Style.config.metrics.valueSize
                font.features: { "tnum": 1 }
                textFormat: Text.PlainText
            }
        }
    }

    ColumnLayout {
        spacing: 0

        Repeater {
            model: [
                { sensor: "network/all/upload", rotation: 0 },
                { sensor: "network/all/download", rotation: 180 }
            ]

            delegate: PanelToolTip {
                id: reading
                required property var modelData
                implicitWidth: networkReading.implicitWidth
                implicitHeight: networkReading.implicitHeight
                mainText: sensor.status === Sensors.Sensor.Ready ? sensor.name : "Network sensor unavailable"

                Sensors.Sensor {
                    id: sensor
                    sensorId: reading.modelData.sensor
                    updateRateLimit: 2000
                }

                RowLayout {
                    id: networkReading
                    anchors.fill: parent
                    spacing: Style.config.metrics.networkSpacing

                    Kirigami.Icon {
                        Layout.preferredWidth: Style.config.metrics.arrowSize
                        Layout.preferredHeight: Style.config.metrics.arrowSize
                        source: Qt.resolvedUrl("../icons/transfer.svg")
                        rotation: reading.modelData.rotation
                        isMask: true
                        color: Kirigami.Theme.textColor
                        opacity: Style.config.metrics.arrowOpacity
                    }

                    Controls.Label {
                        Layout.minimumWidth: Style.config.metrics.networkWidth
                        text: sensor.status === Sensors.Sensor.Ready ? sensor.formattedValue : "—"
                        font.family: Style.config.metrics.fontFamily
                        font.pixelSize: Style.config.metrics.networkSize
                        font.features: { "tnum": 1 }
                        textFormat: Text.PlainText
                    }
                }
            }
        }
    }
}
