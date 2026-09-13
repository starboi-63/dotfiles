# Appearance settings

[style.json](style.json) contains the saved appearance values. This reference describes every setting in file order. See the [setup instructions](README.md#configuration) for applying changes.

Dimensions and spacing use logical pixels, which follow desktop scaling. Clock and tooltip font sizes use points. Opacity values range from `0` (transparent) to `1` (opaque), except `bar.opacity`, which uses a percentage. Font weights use `400` for regular and `600` for semibold.

## Top bar

| Setting | Meaning |
| --- | --- |
| `bar.height` | Top panel height, excluding its outer floating margin. |
| `bar.padding` | Gap between tiled windows, gap between tiles and the available screen edges, and space to the left of the Fedora logo. The theme controls the panel's outer floating margin separately. |
| `bar.opacity` | Background strength from `0` to `100`, applied over the theme's own transparency. Text and icons stay opaque; native blur and shadows remain. |
| `bar.keepFloating` | When `true`, keeps floating margins even when a window touches the panel and reserves that space above tiled windows. When `false`, Plasma controls when the panel becomes flush. `Alt+B` still switches between floating and full-width modes. |
| `bar.sectionSpacing` | Space between the logo, workspace strip, and CPU/network section. |
| `bar.logoSize` | Width and height of the Fedora logo. |
| `bar.minimumWidth` | Minimum width requested by the custom widget containing the logo, workspaces, and metrics. Excludes the separate tray and clock widgets. |
| `bar.preferredWidth` | Preferred width of that custom widget before Plasma distributes available panel space. |

## Bottom dock

| Setting | Meaning |
| --- | --- |
| `dock.matchBarOpacity` | When `true`, applies `bar.opacity` to the dock background. When `false`, restores the theme's normal dock opacity. Requires the Dock Appearance widget when enabled. |

## Tray and clock

| Setting | Meaning |
| --- | --- |
| `status.size` | Width and height of tray icons and the custom chevron. |
| `status.spacing` | Extra horizontal space per tray icon. Each icon cell is `status.size + status.spacing` wide. |
| `status.expanderWidth` | Size reserved for the tray expansion control. Its visible chevron uses `status.size`. |
| `status.fontFamily` | Font family for the date and time. Qt chooses a fallback if the font is unavailable. |
| `status.fontWeight` | Font weight for the date and time. |
| `status.clockFontSize` | Font size for the date and time, in points. |
| `status.dateFormat` | Qt date format used beside the time. `ddd MMM d` shows an abbreviated weekday, abbreviated month, and day number, such as `Sun Sep 13`. |
| `status.chevronDuration` | Duration of the tray chevron's rotation, in milliseconds. Set to `0` for an instant change. Plasma's global animation setting can also disable it. |

## CPU and network

| Setting | Meaning |
| --- | --- |
| `metrics.rightPadding` | Space after the network readings, before the next panel widget. |
| `metrics.spacing` | Space between the CPU reading and the network readings. |
| `metrics.fontFamily` | Font family for CPU and network text. Qt chooses a fallback if the font is unavailable. |
| `metrics.labelSize` | Font size of the `CPU` label, in logical pixels. |
| `metrics.valueSize` | Font size of the CPU percentage, in logical pixels. |
| `metrics.labelSpacing` | Space between the `CPU` label and its percentage. |
| `metrics.labelTracking` | Additional spacing between characters in the `CPU` label. |
| `metrics.labelOpacity` | Opacity of the `CPU` label. |
| `metrics.cpuWidth` | Preferred width reserved for the CPU percentage to reduce movement as it changes. |
| `metrics.networkSize` | Font size of upload and download values, in logical pixels. |
| `metrics.networkWidth` | Minimum width reserved for each network value. |
| `metrics.networkSpacing` | Space between each network arrow and its value. |
| `metrics.arrowSize` | Width and height of upload and download arrows. |
| `metrics.arrowOpacity` | Opacity of upload and download arrows. |

## Workspaces

| Setting | Meaning |
| --- | --- |
| `workspaces.maximumIcons` | Maximum number of window icons shown per workspace. Additional windows appear as a `+N` count. |
| `workspaces.height` | Minimum height requested by the workspace strip and custom bar widget. Buttons fill the actual strip height after its inset. |
| `workspaces.inset` | Margin on all four sides of the scrollable workspace strip. |
| `workspaces.spacing` | Space between workspace buttons and before the create button. |
| `workspaces.padding` | Equal left and right padding inside each workspace button. |
| `workspaces.iconSpacing` | Space between the workspace number, window icons, and any overflow count or empty marker. |
| `workspaces.iconSize` | Width and height of each window icon. |
| `workspaces.iconWidth` | Width reserved for each window icon's container and hover area. |
| `workspaces.iconHeight` | Height of each window icon's container and hover area, including its active-window marker. |
| `workspaces.indicatorSize` | Width and height of the marker beneath the active window's icon. |
| `workspaces.indicatorRadius` | Corner radius of the active-window marker. |
| `workspaces.cornerRadius` | Corner radius of workspace buttons. |
| `workspaces.activeOpacity` | Background opacity of the selected workspace, using the theme's highlight color. |
| `workspaces.hoverOpacity` | Background opacity of a hovered, unselected workspace. |
| `workspaces.idleOpacity` | Background opacity of an unselected workspace without hover. |
| `workspaces.borderOpacity` | Border opacity for the selected workspace or a button with keyboard focus. |
| `workspaces.minimizedOpacity` | Opacity of icons representing minimized windows. |
| `workspaces.overflowOpacity` | Opacity of the `+N` count for windows beyond the icon limit. |
| `workspaces.emptyOpacity` | Opacity of the dot shown for an empty workspace. |
| `workspaces.createWidth` | Width of the create-workspace button. |
| `workspaces.minimumWidth` | Minimum width reserved for the workspace strip when other bar content needs space. |

## Tooltips

These settings apply to the custom bar's tooltips. The system tray and dock retain their native tooltips.

| Setting | Meaning |
| --- | --- |
| `tooltips.fontSize` | Font size for tooltip titles and details, in points. Uses the desktop theme's font family. |
| `tooltips.titleWeight` | Font weight for tooltip titles. |
| `tooltips.spacing` | Vertical space between a tooltip's title and details. |
| `tooltips.maximumWidth` | Maximum width of tooltip text before wrapping. Excludes the native popup's outer padding. |
| `tooltips.detailOpacity` | Opacity of secondary tooltip text, such as a window title below its application name. |
