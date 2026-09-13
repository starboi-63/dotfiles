"""Checks tray styling through real Qt models, loaders, layouts, and bindings."""

from pathlib import Path
import json
import os

from PySide6.QtCore import QMetaObject, Q_RETURN_ARG, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView
from PySide6.QtTest import QTest


def main():
    """Verifies icon dimensions across delegate and adapter lifecycle changes."""
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    application = QGuiApplication([])
    view = QQuickView()
    view.setSource(QUrl.fromLocalFile(str(Path(__file__).with_name("tray") / "Scene.qml")))
    assert view.status() == QQuickView.Ready, [error.toString() for error in view.errors()]
    view.show()
    scene = view.rootObject()

    def invoke(method):
        """Invokes scene mutation through Qt metaobject."""
        assert QMetaObject.invokeMethod(scene, method), method

    style = json.loads((Path(__file__).resolve().parents[1] / "style.json").read_text())["status"]

    def check(name, count, width=None, height=None):
        """Checks settled icon geometry and reports failed state."""
        width = style["size"] if width is None else width
        height = style["size"] if height is None else height
        expected = [{"width": width, "height": height, "implicitWidth": width, "implicitHeight": height}] * count
        for _ in range(100):
            QTest.qWait(20)
            actual = json.loads(QMetaObject.invokeMethod(scene, "snapshot", Q_RETURN_ARG(str)))
            if actual == expected:
                break
        assert actual == expected, (name, actual, expected)

        # Detects deferred restoration after initial geometry appears correct.
        QTest.qWait(100)
        actual = json.loads(QMetaObject.invokeMethod(scene, "snapshot", Q_RETURN_ARG(str)))
        assert actual == expected, (name, actual, expected)
        appearance = json.loads(QMetaObject.invokeMethod(scene, "appearance", Q_RETURN_ARG(str)))
        expected_appearance = {"cellWidth": style["size"] + style["spacing"], "expanderWidth": style["size"] + style["spacing"], "visibleArrows": 1} if scene.property("styling") else {
            "cellWidth": 30, "expanderWidth": 22, "visibleArrows": 2,
        }
        assert appearance == expected_appearance, (name, appearance, expected_appearance)
        print(f"Passed {name}", flush=True)

    try:
        check("initial delegates", 2)
        invoke("append")
        check("late delegate creation", 3)
        invoke("remove")
        check("delegate removal", 2)
        invoke("reorder")
        check("delegate reordering", 2)
        scene.setProperty("loadIcons", False)
        check("unloaded delegates", 0)
        scene.setProperty("loadIcons", True)
        check("reloaded delegates", 2)
        invoke("clear")
        check("empty tray", 0)
        invoke("append")
        check("first delegate after empty tray", 1)
        scene.setProperty("styling", False)
        check("adapter removal", 1, 22, 38)
        invoke("resizeNativeIcons")
        check("restored native binding", 1, 24, 38)
        scene.setProperty("styling", True)
        check("adapter recreation", 1)
        for _ in range(3):
            invoke("append")
            invoke("remove")
        check("burst of model changes", 1)
    finally:
        view.close()
        application.processEvents()


if __name__ == "__main__":
    main()
