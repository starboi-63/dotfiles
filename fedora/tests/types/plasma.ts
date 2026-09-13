declare const panel: PlasmaPanel;
declare const widget: PlasmaWidget;

// @ts-expect-error Rejects unsupported panel modes.
panel.hiding = "always";

// @ts-expect-error Requires handling widget creation failures.
panel.addWidget("org.kde.plasma.digitalclock").writeConfig("showDate", true);

// @ts-expect-error Requires handling panel creation failures.
new Panel().location = "top";

// @ts-expect-error Requires validation of untyped configuration reads.
const enabled: boolean = widget.readConfig("showDate", false);

// @ts-expect-error Rejects unsupported clock enum values.
const dateMode: ClockSettings["dateDisplayFormat"] = 3;

// @ts-expect-error Rejects string values for boolean task settings.
const filter: TaskSettings["showOnlyCurrentScreen"] = "true";

// @ts-expect-error Prevents use of KWin globals inside Plasma scripts.
workspace.createDesktop(0, "");
