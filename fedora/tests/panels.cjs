"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const test = require("node:test");

const source = fs.readFileSync(path.join(__dirname, "../.build/plasma/panels.js"), "utf8");
const workspacePlugin = "com.starboi.workspaces";
const widgetTypes = [workspacePlugin, "org.kde.plasma.kickoff", "org.kde.plasma.icontasks",
    "org.kde.plasma.systemtray", "org.kde.plasma.digitalclock", "org.kde.plasma.showdesktop"];

function session(screens = [0]) {
    let nextId = 1;
    const panels = [];
    const writes = [];
    const messages = [];
    const faults = {};
    const config = new Map();

    function addWidget(panel, type) {
        if (typeof type === "object") {
            const source = panels.find(item => item.items.includes(type));
            source.items.splice(source.items.indexOf(type), 1);
            panel.items.push(type);
            return type;
        }
        if (faults.widget === type) {
            return faults.widgetResult;
        }
        const settings = new Map();
        const widget = {
            id: nextId++, type, currentConfigGroup: [],
            get configKeys() { return [...(settings.get(this.currentConfigGroup.join("/"))?.keys() ?? [])]; },
            readConfig(key, fallback) {
                return settings.get(this.currentConfigGroup.join("/"))?.get(key) ?? fallback;
            },
            writeConfig(key, value) {
                writes.push([type, key, value]);
                if (faults.configKey === key) {
                    return;
                }
                const group = this.currentConfigGroup.join("/");
                if (!settings.has(group)) {
                    settings.set(group, new Map());
                }
                settings.get(group).set(key, value);
            },
            reloadConfig() {},
            remove() { panel.items.splice(panel.items.indexOf(this), 1); },
        };
        panel.items.push(widget);
        return widget;
    }

    function makePanel(screen = -1, location = "floating") {
        const settings = new Map();
        const panel = {
            id: nextId++, type: "org.kde.panel", screen, items: [],
            height: 46, opacity: location === "bottom" ? "translucent" : "adaptive", floating: true,
            hiding: location === "bottom" ? "autohide" : "none", lengthMode: "fit", alignment: "center", offset: 0,
            currentConfigGroup: [],
            get configKeys() { return [...settings.keys()]; },
            readConfig(key, fallback) { return settings.get(key) ?? fallback; },
            writeConfig(key, value) { settings.set(key, value); },
            reloadConfig() {},
            get location() { return location; },
            set location(value) {
                location = value;
                const opacity = config.get(`plasmashellrc/PlasmaViews/Panel ${this.id}/panelOpacity`);
                if (opacity !== undefined && !faults.opacityReload) {
                    this.opacity = ["adaptive", "opaque", "translucent"][opacity];
                }
            },
            widgets() { return faults.panelId === this.id ? undefined : [...this.items]; },
            addWidget(type) { return addWidget(this, type); },
        };
        panels.push(panel);
        return panel;
    }

    const bottom = makePanel(0, "bottom");
    Object.assign(bottom, { lengthMode: "fill", hiding: "none", alignment: "left", offset: 20, floating: false });
    for (const type of ["org.kde.plasma.kickoff", "org.kde.plasma.pager", "org.kde.plasma.icontasks",
        "org.kde.plasma.panelspacer", "org.kde.plasma.marginsseparator", "org.kde.plasma.systemtray",
        "org.kde.plasma.digitalclock", "org.kde.plasma.showdesktop"]) {
        addWidget(bottom, type);
    }
    const globals = {
        panels: () => [...panels],
        desktops: () => screens.map(screen => ({ id: nextId++, screen, type: "org.kde.plasma.folder" })),
        knownWidgetTypes: [...widgetTypes],
        ConfigFile: function (parent, group) {
            this.path = `${typeof parent === "string" ? parent : parent.path}/${group}`;
            this.writeEntry = (key, value) => {
                if (faults.opacityWrite) {
                    return false;
                }
                config.set(`${this.path}/${key}`, value);
                return true;
            };
            this.readEntry = key => String(config.get(`${this.path}/${key}`));
        },
        Panel: function () { return faults.panelResult ?? makePanel(); },
        print: message => messages.push(message),
    };
    return { panels, bottom, writes, messages, faults, globals, makePanel,
        apply: () => vm.runInNewContext(source, globals) };
}

test("rejects unassigned startup panels before creating duplicates", () => {
    const state = session();
    state.bottom.screen = -1;
    const count = state.panels.length;
    assert.throws(state.apply, /unassigned screens/);
    assert.equal(state.panels.length, count);
    assert.equal(state.writes.length, 0);
});

test("converts stock panels into docks and preserves widget identities on repeat application", () => {
    const state = session([0, 0, 1, -1]);
    const launcher = state.bottom.items.find(widget => widget.type === "org.kde.plasma.kickoff");
    const showDesktop = state.bottom.items.find(widget => widget.type === "org.kde.plasma.showdesktop");
    state.apply();
    assert.equal(JSON.parse(state.messages.at(-1)).phase, "configured");
    assert.equal(state.panels.length, 4);
    assert.equal(state.bottom.items.includes(launcher), true);
    const top = state.panels.find(panel => panel.screen === 0 && panel.location === "top");
    assert.equal(top.items.includes(showDesktop), false);
    assert.equal(state.bottom.items.includes(showDesktop), true);
    assert.equal(state.bottom.lengthMode, "fit");
    assert.deepEqual(state.bottom.items.map(widget => widget.type), [
        "org.kde.plasma.kickoff", "org.kde.plasma.icontasks", "org.kde.plasma.showdesktop",
    ]);
    for (const screen of [0, 1]) {
        const panels = state.panels.filter(panel => panel.screen === screen);
        assert.deepEqual(panels.map(panel => panel.location).sort(), ["bottom", "top"]);
        for (const panel of panels) {
            assert.equal(panel.height, 46);
            assert.equal(panel.opacity, "translucent");
            assert.equal(panel.hiding, panel.location === "bottom" ? "autohide" : "none");
            assert.equal(panel.floating, true);
            assert.equal(panel.lengthMode, panel.location === "bottom" ? "fit" : "fill");
            assert.equal(panel.alignment, "center");
            assert.equal(panel.offset, 0);
        }
    }
    const clock = top.items.find(widget => widget.type === "org.kde.plasma.digitalclock");
    assert.equal(clock.readConfig("dateDisplayFormat"), 1);
    assert.equal(clock.readConfig("customDateFormat"), "ddd MMM d");
    assert.equal(clock.readConfig("fontFamily"), "Adwaita Sans");
    const result = JSON.parse(state.messages.at(-1));
    assert.deepEqual(result.panels.map(panel => panel.screen), [0, 1]);
    const membership = state.panels.map(panel => panel.items.map(widget => widget.id));
    top.floating = false;
    state.apply();
    assert.deepEqual(state.panels.map(panel => panel.items.map(widget => widget.id)), membership);
    assert.equal(top.floating, false);
    assert.equal(state.panels.length, 4);
    assert.equal(state.panels.flatMap(panel => panel.items).filter(widget => widget.type === workspacePlugin).length, 2);
});

test("returns existing Peek at Desktop to dock and preserves its identity", () => {
    const state = session();
    state.apply();
    const top = state.panels.find(panel => panel.location === "top");
    const peek = state.bottom.items.find(widget => widget.type === "org.kde.plasma.showdesktop");
    top.addWidget(peek);
    state.apply();
    assert.equal(state.bottom.items.includes(peek), true);
    assert.equal(top.items.includes(peek), false);
    assert.equal(state.bottom.readConfig("AppletOrder").split(";").at(-1), String(peek.id));
    assert.equal(top.readConfig("AppletOrder").split(";").includes(String(peek.id)), false);
    state.apply();
    assert.equal(state.panels.flatMap(panel => panel.items).filter(widget => widget.type === peek.type).length, 1);
});

test("rejects missing reference, missing plugins, or duplicate panels before writes", () => {
    for (const prepare of [
        state => { state.panels.length = 0; },
        state => { state.globals.knownWidgetTypes = []; },
        state => { state.makePanel(0, "bottom"); },
        state => { state.globals.desktops = () => []; },
    ]) {
        const state = session();
        prepare(state);
        const count = state.panels.length;
        assert.throws(state.apply);
        assert.equal(state.writes.length, 0);
        assert.equal(state.panels.length, count);
    }
});

test("rejects stale panel handles before configuration", () => {
    const state = session();
    state.faults.panelId = state.bottom.id;
    assert.throws(state.apply, /no longer available/);
    assert.equal(state.writes.length, 0);
});

test("detects ignored panel setters", () => {
    const state = session();
    const top = state.makePanel(0, "top");
    top.addWidget(workspacePlugin);
    Object.defineProperty(top, "height", { get: () => 40, set: () => {}, configurable: true });
    assert.throws(state.apply, /did not accept height/);
    assert.equal(state.writes.length, 0);
});

test("toggles only workspace panels and keeps mixed screens consistent", () => {
    const state = session([0, 1]);
    state.apply();
    const toggle = fs.readFileSync(path.join(__dirname, "../.build/plasma/toggle.js"), "utf8");
    const tops = state.panels.filter(panel => panel.location === "top");
    vm.runInNewContext(toggle, state.globals);
    assert.equal(tops.every(panel => !panel.floating), true);
    assert.equal(state.bottom.floating, true);
    tops[0].floating = true;
    vm.runInNewContext(toggle, state.globals);
    assert.equal(tops.every(panel => panel.floating), true);
    assert.equal(state.bottom.hiding, "autohide");
});

test("detects ignored configuration writes even when readConfig returns its default", () => {
    const state = session();
    state.faults.configKey = "showDate";
    assert.throws(state.apply, /did not retain Appearance\/showDate/);
    assert.equal(state.panels.length, 2);
});

test("handles widget creation errors and undefined returns", () => {
    for (const result of [new Error("Missing package"), undefined]) {
        const state = session();
        state.bottom.items = state.bottom.items.filter(widget => widget.type !== "org.kde.plasma.digitalclock");
        state.faults.widget = "org.kde.plasma.digitalclock";
        state.faults.widgetResult = result;
        assert.throws(state.apply, /could not create org.kde.plasma.digitalclock/);
        assert.equal(state.writes.length, 0);
    }
});

test("reports panel creation errors without a success summary", () => {
    const state = session();
    state.faults.panelResult = new Error("Missing panel plugin");
    assert.throws(state.apply, /could not create a top panel/);
    assert.equal(state.messages.some(message => message.startsWith("{")), false);
});

test("detects rejected opacity writes and failed panel reloads", () => {
    for (const fault of ["opacityWrite", "opacityReload"]) {
        const state = session();
        state.faults[fault] = true;
        assert.throws(state.apply, /did not (retain|apply) its opacity setting/);
        assert.equal(state.messages.some(message => message.startsWith("{")), false);
    }
});
