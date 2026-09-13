(() => {
    const workspacePlugin = "com.starboi.workspaces";
    const existingPanels = panels();
    const reference = existingPanels.find(panel => panel.location === "bottom");
    if (!reference || !Number.isInteger(reference.height) || reference.height <= 0) {
        throw new Error("An existing bottom panel with a valid height is required.");
    }
    const panelHeight = reference.height;
    const panelOpacity: PanelOpacity = "translucent";
    const screenIds = [...new Set(desktops().map(desktop => desktop.screen))].filter(screen => screen >= 0);
    if (!screenIds.length || screenIds.some(screen => !Number.isInteger(screen))) {
        throw new Error("Plasma returned no valid active screen IDs.");
    }

    const requiredWidgets = [workspacePlugin, "org.kde.plasma.kickoff", "org.kde.plasma.icontasks",
        "org.kde.plasma.systemtray", "org.kde.plasma.digitalclock", "org.kde.plasma.showdesktop"];
    for (const plugin of requiredWidgets) {
        if (!knownWidgetTypes.includes(plugin)) {
            throw new Error(`Required Plasma widget is unavailable: ${plugin}.`);
        }
    }

    type PanelSettings = Pick<PlasmaPanel, "screen" | "location" | "height" | "lengthMode"
        | "alignment" | "offset" | "hiding" | "floating">;

    function setPanelValue<Key extends keyof PanelSettings>(
        panel: PlasmaPanel, key: Key, value: PlasmaPanel[Key],
    ): void {
        panel[key] = value;
        if (panel[key] !== value) {
            throw new Error(`Panel ${panel.id} did not accept ${key}.`);
        }
    }

    function configurePanel(panel: PlasmaPanel, screen: number, location: "top" | "bottom"): void {
        if (panel.opacity !== panelOpacity) {
            const views = new ConfigFile("plasmashellrc", "PlasmaViews");
            const config = new ConfigFile(views, `Panel ${panel.id}`);
            const opacity = { adaptive: 0, opaque: 1, translucent: 2 }[panelOpacity];
            if (!config.writeEntry("panelOpacity", opacity) || config.readEntry("panelOpacity") !== String(opacity)) {
                throw new Error(`Panel ${panel.id} did not retain its opacity setting.`);
            }

            // Reloads panel settings because Plasma 6.7.4's opacity setter targets QWindow.
            panel.location = location === "top" ? "bottom" : "top";
            panel.location = location;
            if (panel.opacity !== panelOpacity) {
                throw new Error(`Panel ${panel.id} did not apply its opacity setting.`);
            }
        }
        setPanelValue(panel, "screen", screen);
        setPanelValue(panel, "location", location);
        setPanelValue(panel, "height", panelHeight);
        setPanelValue(panel, "lengthMode", "fill");
        setPanelValue(panel, "alignment", "center");
        setPanelValue(panel, "offset", 0);
        setPanelValue(panel, "hiding", "none");
    }

    function panelWidgets(panel: PlasmaPanel): PlasmaWidget[] {
        const widgets = panel.widgets();
        if (!widgets) {
            throw new Error(`Panel ${panel.id} is no longer available.`);
        }
        return widgets;
    }

    function addWidget(panel: PlasmaPanel, plugin: string): PlasmaWidget {
        const widget = panel.addWidget(plugin);
        if (!widget || widget instanceof Error || widget.type !== plugin || widget.id <= 0) {
            throw new Error(`Panel ${panel.id} could not create ${plugin}.`);
        }
        if (!panelWidgets(panel).some(existing => existing.id === widget.id)) {
            throw new Error(`Panel ${panel.id} did not retain widget ${widget.id}.`);
        }
        return widget;
    }

    function createPanel(screen: number, location: "top" | "bottom"): PlasmaPanel {
        const panel = new Panel();
        if (panel instanceof Error || panel.type !== "org.kde.panel" || panel.id <= 0) {
            throw new Error(`Plasma could not create a ${location} panel on screen ${screen}.`);
        }
        print(`Created panel ${panel.id} for screen ${screen}.`);
        panel.screen = screen;
        panel.location = location;
        panel.floating = true;
        return panel;
    }

    function moveWidget(source: PlasmaPanel, target: PlasmaPanel, widget: PlasmaWidget): PlasmaWidget {
        const moved = target.addWidget(widget);
        if (!moved || moved instanceof Error || moved.id !== widget.id
            || panelWidgets(source).some(item => item.id === widget.id)
            || !panelWidgets(target).some(item => item.id === widget.id)) {
            throw new Error(`Plasma did not move widget ${widget.id} to panel ${target.id}.`);
        }
        return moved;
    }

    function configureWidget(
        widget: PlasmaWidget, group: string, settings: Readonly<Record<string, ConfigValue>>,
    ): void {
        widget.currentConfigGroup = [group];
        if (widget.currentConfigGroup.length !== 1 || widget.currentConfigGroup[0] !== group) {
            throw new Error(`Widget ${widget.id} did not select configuration group ${group}.`);
        }
        for (const [key, value] of Object.entries(settings)) {
            widget.writeConfig(key, value);

            // Checks presence before supplying default that selects KConfig's value type.
            if (!widget.configKeys.includes(key) || widget.readConfig(key, value) !== value) {
                throw new Error(`Widget ${widget.id} did not retain ${group}/${key}.`);
            }
        }
        widget.reloadConfig();
    }

    function configureClock(clock: PlasmaWidget): void {
        const settings = {
            showDate: true,
            dateDisplayFormat: 1,
            dateFormat: "custom",
            customDateFormat: "ddd MMM d",
            use24hFormat: 0,
            showSeconds: 0,
            autoFontAndSize: false,
            fontSize: 10,
            fontWeight: 400,
            fontFamily: "Adwaita Sans",
            showLocalTimezone: false,
        } satisfies ClockSettings;
        configureWidget(clock, "Appearance", settings);
    }

    const plans = screenIds.map(screen => {
        const bottom = existingPanels.filter(panel => panel.screen === screen && panel.location === "bottom");
        const top = existingPanels.filter(panel => panel.screen === screen && panel.location === "top"
            && panelWidgets(panel).some(widget => widget.type === workspacePlugin));
        if (bottom.length > 1 || top.length > 1) {
            throw new Error(`Screen ${screen} has multiple matching panels. Select a layout before applying.`);
        }
        if (bottom[0]) {
            panelWidgets(bottom[0]);
        }
        return { screen, bottom: bottom[0], top: top[0] };
    });
    for (const plan of plans) {
        const { screen } = plan;
        if (!plan.bottom) {
            const bottom = createPanel(screen, "bottom");
            addWidget(bottom, "org.kde.plasma.kickoff");
            addWidget(bottom, "org.kde.plasma.icontasks");
            configurePanel(bottom, screen, "bottom");
            setPanelValue(bottom, "lengthMode", "fit");
            setPanelValue(bottom, "hiding", "autohide");
            plan.bottom = bottom;
        }
        if (!plan.top) {
            const top = createPanel(screen, "top");
            addWidget(top, workspacePlugin);
            plan.top = top;
        }
    }

    const changedPanels: { screen: number; top: number; bottom: number }[] = [];
    for (const { screen, bottom, top } of plans) {
        if (!bottom || !top) {
            throw new Error(`Screen ${screen} is missing a prepared panel.`);
        }
        configurePanel(top, screen, "top");
        const rightWidgets: PlasmaWidget[] = [];
        for (const plugin of ["org.kde.plasma.systemtray", "org.kde.plasma.digitalclock"]) {
            const source = panelWidgets(bottom).find(widget => widget.type === plugin);
            const existing = panelWidgets(top).find(widget => widget.type === plugin);
            if (source && existing) {
                throw new Error(`Both panels contain ${plugin}. Resolve duplicate widgets before applying.`);
            }
            const widget = existing ?? source ?? addWidget(top, plugin);
            if (plugin === "org.kde.plasma.digitalclock") {
                configureClock(widget);
            }
            rightWidgets.push(source ? moveWidget(bottom, top, widget) : widget);
        }

        const peekPlugin = "org.kde.plasma.showdesktop";
        const topPeek = panelWidgets(top).find(widget => widget.type === peekPlugin);
        const bottomPeek = panelWidgets(bottom).find(widget => widget.type === peekPlugin);
        if (topPeek && bottomPeek) {
            throw new Error("Both panels contain Peek at Desktop. Resolve duplicate widgets before applying.");
        }
        const peek = topPeek ? moveWidget(top, bottom, topPeek) : bottomPeek ?? addWidget(bottom, peekPlugin);
        const leftWidgets = panelWidgets(top).filter(widget => !rightWidgets.some(right => right.id === widget.id));
        configureWidget(top, "General", { AppletOrder: [...leftWidgets, ...rightWidgets].map(widget => widget.id).join(";") });

        for (const widget of panelWidgets(bottom)) {
            if (widget.type === "org.kde.plasma.pager" || widget.type === "org.kde.plasma.marginsseparator") {
                const widgetId = widget.id;
                widget.remove();
                print(`Requested removal of obsolete dock widget ${widgetId} from panel ${bottom.id}.`);
            } else if (widget.type === "org.kde.plasma.icontasks") {
                const settings = { showOnlyCurrentScreen: true, showOnlyCurrentDesktop: true } satisfies TaskSettings;
                configureWidget(widget, "General", settings);
            }
        }

        const dockWidgets = panelWidgets(bottom).filter(widget => widget.id !== peek.id);
        configureWidget(bottom, "General", { AppletOrder: [...dockWidgets, peek].map(widget => widget.id).join(";") });
        changedPanels.push({ screen, top: top.id, bottom: bottom.id });
    }

    print(JSON.stringify({ phase: "configured", panels: changedPanels, height: panelHeight, opacity: panelOpacity }));
})();
