declare const output: KWinOutput | null;
declare const desktop: KWinDesktop;

// @ts-expect-error Requires null check before passing output.
workspace.currentDesktopForScreen(output);

// @ts-expect-error Distinguishes desktop handles from output handles.
workspace.currentDesktopForScreen(desktop);

// @ts-expect-error Requires null check before using active window.
workspace.activeWindow.desktops = [desktop];

// @ts-expect-error Requires bounds check before using desktop entry.
workspace.desktops[0].id;

// @ts-expect-error Prevents assignment to read-only desktop list.
workspace.desktops = [];

// @ts-expect-error Rejects incorrect desktop argument type.
workspace.createDesktop("last", "");

// @ts-expect-error Excludes browser globals from KWin scripts.
document.title;
