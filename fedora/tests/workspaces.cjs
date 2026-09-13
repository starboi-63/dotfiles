"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const source = fs.readFileSync(path.join(__dirname, "../.build/kwin/shortcuts/contents/code/main.js"), "utf8");

function session(count = 3) {
    const desktops = Array.from({ length: count }, (_, index) => ({ id: String(index) }));
    const output = { name: "Primary" };
    const otherOutput = { name: "Secondary" };
    const selected = new Map([[output, desktops[0]], [otherOutput, desktops[count - 1]]]);
    const actions = {};
    const calls = [];
    const workspace = {
        desktops,
        currentDesktop: desktops[0],
        activeWindow: { output, desktops: [desktops[0]], specialWindow: false, onAllDesktops: false },
        currentDesktopForScreen: screen => selected.get(screen),
        setCurrentDesktopForScreen: (desktop, screen) => selected.set(screen, desktop),
        createDesktop: (position, name) => {
            calls.push(["create", position, name]);
            desktops.splice(position, 0, { id: String(desktops.length) });
        },
        removeDesktop: desktop => {
            calls.push(["remove", desktop]);
            desktops.splice(desktops.indexOf(desktop), 1);
        },
    };
    vm.runInNewContext(source, {
        workspace,
        registerShortcut: (name, label, sequence, callback) => {
            assert.equal(sequence, "");
            actions[name] = callback;
            return true;
        },
    });
    return { workspace, actions, calls, selected, output, otherOutput };
}

{
    const state = session();
    state.actions.WorkspaceCreate();
    assert.deepEqual(state.calls, [["create", 3, ""]]);
    state.actions.WorkspaceRemove();
    assert.deepEqual(state.calls[1], ["remove", state.workspace.currentDesktop]);
}

{
    const state = session(1);
    state.actions.WorkspaceRemove();
    assert.equal(state.calls.length, 0);
}

for (const [action, origin, target] of [["WorkspaceMoveNext", 0, 1], ["WorkspaceMovePrevious", 2, 1]]) {
    const state = session();
    state.selected.set(state.output, state.workspace.desktops[origin]);
    const window = state.workspace.activeWindow;
    const otherDesktop = state.selected.get(state.otherOutput);
    state.actions[action]();
    assert.equal(window.desktops.length, 1);
    assert.equal(window.desktops[0], state.workspace.desktops[target]);
    assert.equal(state.selected.get(state.output), state.workspace.desktops[target]);
    assert.equal(state.selected.get(state.otherOutput), otherDesktop);
    assert.equal(state.workspace.activeWindow, window);
}

for (const [action, origin] of [["WorkspaceMovePrevious", 0], ["WorkspaceMoveNext", 2]]) {
    const state = session();
    state.selected.set(state.output, state.workspace.desktops[origin]);
    const original = state.workspace.activeWindow.desktops;
    state.actions[action]();
    assert.equal(state.workspace.activeWindow.desktops, original);
    assert.equal(state.selected.get(state.output), state.workspace.desktops[origin]);
}

for (const excluded of [null, { specialWindow: true }, { onAllDesktops: true }]) {
    const state = session();
    state.workspace.activeWindow = excluded;
    state.actions.WorkspaceMoveNext();
    state.actions.WorkspaceMovePrevious();
    assert.equal(state.workspace.activeWindow, excluded);
    assert.equal(state.selected.get(state.output), state.workspace.desktops[0]);
}

for (const current of [null, { id: "missing" }]) {
    const state = session();
    state.selected.set(state.output, current);
    const original = state.workspace.activeWindow.desktops;
    assert.throws(() => state.actions.WorkspaceMoveNext(), /no valid desktop/);
    assert.equal(state.workspace.activeWindow.desktops, original);
    state.workspace.currentDesktop = current;
    assert.throws(() => state.actions.WorkspaceRemove(), /no valid current desktop/);
    assert.equal(state.calls.length, 0);
}

{
    const state = session();
    state.workspace.activeWindow.output = null;
    assert.throws(() => state.actions.WorkspaceMoveNext(), /without an output/);
}

{
    const state = session();
    state.workspace.createDesktop = () => {};
    state.workspace.removeDesktop = () => {};
    assert.throws(() => state.actions.WorkspaceCreate(), /did not create/);
    assert.throws(() => state.actions.WorkspaceRemove(), /did not remove/);
}

{
    const state = session();
    const original = state.workspace.activeWindow.desktops;
    Object.defineProperty(state.workspace.activeWindow, "desktops", { get: () => original, set: () => {} });
    assert.throws(() => state.actions.WorkspaceMoveNext(), /did not move/);
    assert.equal(state.selected.get(state.output), state.workspace.desktops[0]);
}

{
    const state = session();
    state.workspace.setCurrentDesktopForScreen = () => {};
    assert.throws(() => state.actions.WorkspaceMoveNext(), /did not switch/);
}

{
    const state = session();
    const window = state.workspace.activeWindow;
    let active = window;
    Object.defineProperty(state.workspace, "activeWindow", { get: () => active, set: () => { active = null; } });
    assert.throws(() => state.actions.WorkspaceMoveNext(), /did not restore its focus/);
}

{
    const state = session();
    assert.throws(() => vm.runInNewContext(source, { workspace: state.workspace, registerShortcut: () => false }),
        /rejected shortcut registration/);
    state.workspace.currentDesktopForScreen = undefined;
    assert.throws(() => vm.runInNewContext(source, { workspace: state.workspace }), /per-screen desktop APIs/);
}

console.log("Workspace action checks passed using an in-memory substitute.");
