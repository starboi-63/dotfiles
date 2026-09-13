"""Checks sustained hover and dismissal against native Plasma tooltips."""

from pathlib import Path
import os

from PySide6.QtCore import QPoint, QUrl, Qt
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickItem, QQuickView
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtTest import QTest


def main():
    """Verifies stable tooltips without intercepting workspace clicks."""
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    QQuickStyle.setStyle("org.kde.desktop")
    application = QGuiApplication([])
    view = QQuickView()
    view.setSource(QUrl.fromLocalFile(str(Path(__file__).with_name("tooltip") / "Scene.qml")))
    assert view.status() == QQuickView.Ready, [error.toString() for error in view.errors()]
    view.show()
    QTest.qWait(300)
    scene = view.rootObject()

    try:
        for name, position in (("first", 60), ("second", 110)):
            tooltip = scene.property(name)
            QTest.mouseMove(view, QPoint(position, 22), 0)
            QTest.qWait(1000)
            for index in range(60):
                if index >= 20:
                    QTest.mouseMove(view, QPoint(position + index % 2, 22), 0)
                QTest.qWait(100)
                assert tooltip.property("containsMouse"), (name, index, "lost hover")
                assert scene.property("showing"), (name, index, "hidden tooltip")

            popup_windows = [window for window in application.allWindows() if window.isVisible() and window != view]
            assert len(popup_windows) == 1 and popup_windows[0].metaObject().className() == "ToolTipDialog"
            content = tooltip.property("mainItem")
            assert content.implicitWidth() <= 360
            if name == "first":
                title = next(item for item in content.findChildren(QQuickItem)
                             if item.property("text") == "ChatGPT" and item.isVisible())
                assert title.property("lineCount") == 1
            print(f"Passed sustained hover and separate popup for {name} icon", flush=True)

        QTest.mouseMove(view, QPoint(300, 22), 0)
        QTest.qWait(600)
        assert not scene.property("showing")
        QTest.mouseClick(view, Qt.LeftButton, Qt.NoModifier, QPoint(60, 22))
        assert scene.property("clicks") == 1
        print("Passed hover dismissal and parent button click", flush=True)
    finally:
        view.close()
        application.processEvents()


if __name__ == "__main__":
    main()
