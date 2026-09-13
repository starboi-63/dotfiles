function createDesktop(): void {
    const count = workspace.desktops.length;
    workspace.createDesktop(count, "");
    if (workspace.desktops.length !== count + 1) {
        throw new Error("KWin did not create a desktop. Its desktop limit may have been reached.");
    }
}

function removeDesktop(): void {
    const desktops = workspace.desktops;
    if (desktops.length <= 1) {
        return;
    }
    const current = workspace.currentDesktop;
    if (!current || !desktops.some(desktop => desktop.id === current.id)) {
        throw new Error("KWin returned no valid current desktop.");
    }
    const count = desktops.length;
    const desktopId = current.id;

    workspace.removeDesktop(current);
    const remaining = workspace.desktops;
    if (remaining.length !== count - 1 || remaining.some(desktop => desktop.id === desktopId)) {
        throw new Error("KWin did not remove the requested desktop.");
    }
}

function moveWindow(direction: -1 | 1): void {
    const window = workspace.activeWindow;
    if (!window || window.specialWindow || window.onAllDesktops) {
        return;
    }

    const output = window.output;
    if (!output) {
        throw new Error("KWin returned a window without an output.");
    }
    const current = workspace.currentDesktopForScreen(output);
    const desktops = workspace.desktops;
    const position = current ? desktops.findIndex(desktop => desktop.id === current.id) : -1;
    if (position < 0) {
        throw new Error("KWin returned no valid desktop for the window's output.");
    }
    const target = desktops[position + direction];
    if (!target) {
        return;
    }

    window.desktops = [target];
    if (window.desktops.length !== 1 || window.desktops[0]?.id !== target.id) {
        throw new Error("KWin did not move the window. Desktop switching was skipped.");
    }
    workspace.setCurrentDesktopForScreen(target, output);
    if (workspace.currentDesktopForScreen(output)?.id !== target.id) {
        throw new Error("KWin moved the window but did not switch its output's desktop.");
    }
    workspace.activeWindow = window;
    if (workspace.activeWindow !== window) {
        throw new Error("KWin moved the window but did not restore its focus.");
    }
}

function togglePanel(): void {
    callDBus("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", "evaluateScript", panelToggleScript, () => {});
}

if (typeof workspace.currentDesktopForScreen !== "function"
    || typeof workspace.setCurrentDesktopForScreen !== "function") {
    throw new Error("Workspace Shortcuts requires KWin's per-screen desktop APIs.");
}

const shortcuts = [
    { name: "WorkspaceCreate", label: "Create Desktop", callback: createDesktop },
    { name: "WorkspaceRemove", label: "Remove Current Desktop", callback: removeDesktop },
    { name: "WorkspaceMovePrevious", label: "Move Window to Previous Desktop and Follow", callback: () => moveWindow(-1) },
    { name: "WorkspaceMoveNext", label: "Move Window to Next Desktop and Follow", callback: () => moveWindow(1) },
    { name: "WorkspaceTogglePanel", label: "Toggle Workspace Panel Floating", callback: togglePanel },
];

for (const shortcut of shortcuts) {
    if (!registerShortcut(shortcut.name, shortcut.label, "", shortcut.callback)) {
        throw new Error(`KWin rejected shortcut registration for ${shortcut.name}.`);
    }
}
