import QtQuick
import "Style.js" as Style
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

PlasmaCore.ToolTipArea {
    id: root

    location: PlasmaCore.Types.TopEdge
    interactive: false
    textFormat: Text.PlainText

    mainItem: Item {
        implicitWidth: Math.ceil(Math.min(Style.config.tooltips.maximumWidth, Math.max(titleLabel.implicitWidth, detailLabel.implicitWidth)))
        implicitHeight: Math.ceil(content.implicitHeight)

        Column {
            id: content
            width: parent.width
            spacing: Style.config.tooltips.spacing

            Controls.Label {
                id: titleLabel
                width: parent.width
                text: root.mainText
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Style.config.tooltips.fontSize
                font.weight: Style.config.tooltips.titleWeight
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
            }

            Controls.Label {
                id: detailLabel
                width: parent.width
                visible: root.subText.length > 0 && root.subText !== root.mainText
                text: root.subText
                font.family: Kirigami.Theme.defaultFont.family
                font.pointSize: Style.config.tooltips.fontSize
                opacity: Style.config.tooltips.detailOpacity
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
            }
        }
    }
}
