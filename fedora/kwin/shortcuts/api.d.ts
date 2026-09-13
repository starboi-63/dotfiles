/** Describes consumed KWin 6.7 APIs documented in API.md. */

declare class KWinOutput {
    private readonly outputIdentity: never;
}

interface KWinDesktop {
    readonly id: string;
}

interface KWinWindow {
    readonly output: KWinOutput | null;
    readonly specialWindow: boolean;
    onAllDesktops: boolean;
    desktops: readonly KWinDesktop[];
}

interface KWinWorkspace {
    readonly desktops: readonly KWinDesktop[];
    currentDesktop: KWinDesktop | null;
    activeWindow: KWinWindow | null;
    createDesktop(position: number, name: string): void;
    removeDesktop(desktop: KWinDesktop): void;
    currentDesktopForScreen(output: KWinOutput): KWinDesktop | null;
    setCurrentDesktopForScreen(desktop: KWinDesktop, output: KWinOutput): void;
}

declare const workspace: KWinWorkspace;
declare const panelToggleScript: string;

declare function callDBus(
    service: "org.kde.plasmashell",
    path: "/PlasmaShell",
    interfaceName: "org.kde.PlasmaShell",
    method: "evaluateScript",
    script: string,
    callback: () => void,
): void;

declare function registerShortcut(
    name: string,
    label: string,
    sequence: string,
    callback: (action: unknown) => void,
): boolean;
