/** Describes shared appearance values from style.json. */
interface PanelStyle {
    readonly bar: {
        readonly height: number;
        readonly padding: number;
        readonly opacity: number;
        readonly keepFloating: boolean;
        readonly sectionSpacing: number;
        readonly logoSize: number;
        readonly minimumWidth: number;
        readonly preferredWidth: number;
    };
    readonly status: {
        readonly size: number;
        readonly spacing: number;
        readonly clockPadding: number;
        readonly dateTimeSpacing: number;
        readonly fontFamily: string;
        readonly fontWeight: number;
        readonly dateFormat: string;
        readonly chevronDuration: number;
    };
    readonly metrics: {
        readonly padding: number;
        readonly spacing: number;
        readonly fontFamily: string;
        readonly labelSize: number;
        readonly valueSize: number;
        readonly labelSpacing: number;
        readonly labelTracking: number;
        readonly labelOpacity: number;
        readonly cpuWidth: number;
        readonly networkSize: number;
        readonly networkWidth: number;
        readonly networkSpacing: number;
        readonly arrowSize: number;
        readonly arrowOpacity: number;
    };
    readonly workspaces: {
        readonly maximumIcons: number;
        readonly minimumWidth: number;
        readonly height: number;
        readonly inset: number;
        readonly spacing: number;
        readonly padding: number;
        readonly iconSpacing: number;
        readonly iconSize: number;
        readonly iconWidth: number;
        readonly iconHeight: number;
        readonly indicatorSize: number;
        readonly indicatorRadius: number;
        readonly cornerRadius: number;
        readonly activeOpacity: number;
        readonly hoverOpacity: number;
        readonly idleOpacity: number;
        readonly borderOpacity: number;
        readonly minimizedOpacity: number;
        readonly overflowOpacity: number;
        readonly emptyOpacity: number;
        readonly createWidth: number;
    };
    readonly tooltips: {
        readonly fontSize: number;
        readonly titleWeight: number;
        readonly spacing: number;
        readonly maximumWidth: number;
        readonly detailOpacity: number;
    };
}

declare const style: PanelStyle;
