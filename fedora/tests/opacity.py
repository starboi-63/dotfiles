"""Checks panel opacity matching and restoration with native Qt bindings."""

from pathlib import Path
import os

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtTest import QTest


def main():
    """Verifies optional background matching without changing desktop settings."""
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    application = QGuiApplication([])
    engine = QQmlApplicationEngine()
    engine.load(QUrl.fromLocalFile(str(Path(__file__).with_name("opacity") / "Scene.qml")))
    assert engine.rootObjects(), "Opacity scene did not load."
    window = engine.rootObjects()[0]

    def check(name, normal, solid):
        """Checks all six backgrounds after bindings settle."""
        QTest.qWait(100)
        values = window.property("values").toVariant()
        assert len(values) == 6, values
        assert all(abs(actual - expected) < 1e-6 for actual, expected in zip(values, [normal] * 3 + [solid] * 3)), (name, values)
        changes = window.property("changes")
        QTest.qWait(100)
        assert window.property("changes") == changes, name
        print(f"Passed {name}", flush=True)

    check("shared strength", 0.33, 0.198)
    window.setProperty("reverseOrder", True)
    check("reordered backgrounds", 0.33, 0.198)
    window.setProperty("selectedCount", 3)
    check("removed backgrounds restore bindings", 0.33, 0.48)
    window.setProperty("selectedCount", 6)
    check("returning backgrounds", 0.33, 0.198)
    window.setProperty("selectedCount", 0)
    check("detached panel", 0.8, 0.48)
    window.setProperty("selectedCount", 6)
    check("reattached panel", 0.33, 0.198)
    window.setProperty("matching", False)
    check("disabled matching", 0.8, 0.48)
    window.setProperty("nativeStrength", 0.9)
    check("restored native binding", 0.9, 0.54)
    window.setProperty("matching", True)
    check("matching restored", 0.33, 0.198)
    window.setProperty("panelStrength", 0.5)
    check("native opacity mode change", 0.33, 0.165)
    window.setProperty("strength", 0.45)
    check("configured strength change", 0.45, 0.225)
    window.setProperty("strength", 0)
    check("transparent background", 0, 0)
    window.setProperty("strength", 1)
    check("full background strength", 1, 0.5)
    window.setProperty("mounted", False)
    check("component removal", 0.9, 0.45)
    window.setProperty("nativeStrength", 0.7)
    check("removed component stays disconnected", 0.7, 0.35)
    window.setProperty("strength", 0.33)
    window.setProperty("mounted", True)
    check("component recreation", 0.33, 0.165)
    window.setProperty("matching", False)
    window.setProperty("mounted", False)
    check("disabled component removal", 0.7, 0.35)
    window.close()
    application.processEvents()


if __name__ == "__main__":
    main()
