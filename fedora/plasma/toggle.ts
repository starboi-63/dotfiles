(() => {
    const bars = panels().filter(panel => panel.location === "top"
        && panel.widgets()?.some(widget => widget.type === "com.starboi.workspaces"));
    if (!bars.length) {
        throw new Error("No workspace panel is available.");
    }
    const floating = !bars.every(panel => panel.floating);
    for (const bar of bars) {
        bar.floating = floating;
        if (bar.floating !== floating) {
            throw new Error(`Panel ${bar.id} did not change its floating setting.`);
        }
    }
})();
