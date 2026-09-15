"""Checks panel appearance across changes to Plasma's container hierarchy."""

from pathlib import Path
import os

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtTest import QTest


def main():
    """Verifies floating mode and opacity after delayed attachment and display reconnection."""
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    application = QGuiApplication([])
    engine = QQmlApplicationEngine()
    engine.load(QUrl.fromLocalFile(str(Path(__file__).with_name("appearance") / "Scene.qml")))
    assert engine.rootObjects(), "Appearance scene did not load."
    window = engine.rootObjects()[0]

    def check(name, target, opacity, zone):
        """Checks floating state, background strength, and reserved space after attachment settles."""
        QTest.qWait(100)
        assert window.property("target") == target, (name, window.property("target"))
        assert window.property("floatingApplets") == bool(target), name
        assert window.property("zone") == zone, (name, window.property("zone"))
        values = window.property("opacities").toVariant()
        expected = [opacity] * 4 + [0] * 2
        assert len(values) == 6 and all(abs(actual - wanted) < 1e-6 for actual, wanted in zip(values, expected)), (name, values)
        print(f"Passed {name}", flush=True)

    check("unattached startup", 0, 1, 46)
    window.setProperty("attached", True)
    check("delayed ancestor attachment", 1, 0.33, 54)
    window.setProperty("floating", False)
    check("full mode while touching", 0, 0.33, 46)
    window.setProperty("floating", True)
    check("floating mode while touching", 1, 0.33, 54)
    window.setProperty("touchingWindow", False)
    check("window moved away", 1, 0.33, 54)
    window.setProperty("touchingWindow", True)
    check("window moved back", 1, 0.33, 54)
    window.setProperty("keepFloating", False)
    check("native floating behavior", 0, 0.33, 46)
    window.setProperty("keepFloating", True)
    check("restored floating preference", 1, 0.33, 54)
    window.setProperty("attached", False)
    check("display detached", 0, 1, 46)
    window.setProperty("attached", True)
    check("display reattached", 1, 0.33, 54)
    window.setProperty("backgroundCount", 0)
    QTest.qWait(100)
    window.setProperty("backgroundCount", 6)
    check("backgrounds recreated", 1, 0.33, 54)
    window.setProperty("styling", False)
    check("appearance removed", 0, 1, 46)
    window.setProperty("styling", True)
    check("appearance recreated", 1, 0.33, 54)
    window.close()
    application.processEvents()


if __name__ == "__main__":
    main()
