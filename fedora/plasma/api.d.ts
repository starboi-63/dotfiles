/** Describes consumed Plasma 6.7.4 APIs documented in API.md. */

type PanelLocation = "floating" | "desktop" | "fullscreen" | "top" | "bottom" | "left" | "right";
type PanelOpacity = "adaptive" | "opaque" | "translucent";
type ConfigValue = string | number | boolean;

interface PlasmaWidget {
    readonly id: number;
    readonly type: string;
    readonly configKeys: readonly string[];
    currentConfigGroup: string[];
    readConfig(key: string, defaultValue?: ConfigValue): unknown;
    writeConfig(key: string, value: ConfigValue): void;
    reloadConfig(): void;
    remove(): void;
}

interface PlasmaDesktop extends PlasmaWidget {
    screen: number;
}

interface PlasmaPanel extends PlasmaDesktop {
    location: PanelLocation;
    alignment: "left" | "center" | "right";
    lengthMode: "fill" | "fit" | "custom";
    offset: number;
    height: number;
    hiding: "none" | "autohide" | "dodgewindows" | "windowsgobelow";
    floating: boolean;
    readonly opacity: PanelOpacity;
    widgets(): PlasmaWidget[] | undefined;
    addWidget(widget: string | PlasmaWidget): PlasmaWidget | Error | undefined;
}

interface ClockSettings {
    showDate: boolean;
    dateDisplayFormat: 0 | 1 | 2;
    dateFormat: string;
    customDateFormat: string;
    use24hFormat: number;
    showSeconds: 0 | 1 | 2;
    autoFontAndSize: boolean;
    fontSize: number;
    fontWeight: number;
    fontFamily: string;
    showLocalTimezone: boolean;
}

interface TaskSettings {
    showOnlyCurrentScreen: boolean;
    showOnlyCurrentDesktop: boolean;
}

declare const Panel: { new (): PlasmaPanel | Error };
interface PlasmaConfigGroup {
    writeEntry(key: string, value: ConfigValue): boolean;
    readEntry(key: string): unknown;
}
declare const ConfigFile: { new (file: string | PlasmaConfigGroup, group: string): PlasmaConfigGroup };
declare const knownWidgetTypes: readonly string[];
declare function panels(): PlasmaPanel[];
declare function desktops(): PlasmaDesktop[];
declare function print(message: string): void;
