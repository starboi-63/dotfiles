"""Checks panel reservation against Qt's native layer-shell properties."""

from pathlib import Path
import os

from PySide6.QtCore import Q_ARG, QMetaObject, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtTest import QTest


def main():
    """Verifies floating transitions and reservation restoration without a desktop session."""
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    application = QGuiApplication([])
    engine = QQmlApplicationEngine()
    engine.load(QUrl.fromLocalFile(str(Path(__file__).with_name("reservation") / "Scene.qml")))
    for _ in range(100):
        if engine.rootObjects():
            break
        QTest.qWait(20)
    assert engine.rootObjects(), "Reservation scene did not load."
    window = engine.rootObjects()[0]

    def check(name, expected):
        """Checks settled reservation and rejects repeated writes."""
        QTest.qWait(100)
        assert window.property("zone") == expected, (name, window.property("zone"), expected)
        changes = window.property("changes")
        QTest.qWait(100)
        assert window.property("changes") == changes, name
        print(f"Passed {name}", flush=True)

    def native_zone(value):
        """Simulates Plasma updating its native reservation."""
        assert QMetaObject.invokeMethod(window, "nativeZone", Q_ARG(int, value))

    check("floating inset", 54)
    window.setProperty("floating", False)
    check("edge mode", 46)
    window.setProperty("floating", True)
    check("floating restoration", 54)
    changes = window.property("changes")
    window.setProperty("floating", True)
    check("repeated floating assignment", 54)
    assert window.property("changes") == changes
    window.setProperty("alternate", True)
    check("previous panel releases reservation", 46)
    assert window.property("alternateZone") == 62
    window.setProperty("alternate", False)
    check("original panel regains reservation", 54)
    assert window.property("alternateZone") == 54
    native_zone(46)
    check("native reservation overwrite", 54)
    window.setProperty("thickness", 50)
    check("panel height change", 58)
    window.setProperty("padding", 12)
    check("floating padding change", 62)
    window.setProperty("userConfiguring", True)
    native_zone(74)
    check("panel edit mode", 74)
    window.setProperty("userConfiguring", False)
    check("edit mode exit", 62)
    window.setProperty("visibilityMode", 1)
    native_zone(-1)
    check("hidden panel", -1)
    window.setProperty("visibilityMode", 0)
    native_zone(50)
    check("visible panel", 62)
    window.setProperty("styling", False)
    check("adapter removal", 50)
    native_zone(55)
    check("removed adapter stays disconnected", 55)
    window.setProperty("styling", True)
    check("adapter recreation", 62)
    window.setProperty("styling", False)
    check("final native restoration", 50)
    native_zone(-1)
    window.setProperty("styling", True)
    check("native disabled reservation", -1)
    window.setProperty("styling", False)
    check("unused adapter preserves disabled reservation", -1)
    window.close()
    application.processEvents()


if __name__ == "__main__":
    main()
