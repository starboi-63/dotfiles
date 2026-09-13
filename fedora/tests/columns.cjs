"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

const root = path.resolve(__dirname, "..");
const source = fs.readFileSync(path.join(root, ".build/kwin/krohnkite/script.js"), "utf8");
const settings = JSON.parse(fs.readFileSync(path.join(root, "settings.json"), "utf8"));
const style = JSON.parse(fs.readFileSync(path.join(root, "style.json"), "utf8"));
const preferences = { ...settings.kwinrc["Script-krohnkite"] };
for (const edge of ["Top", "Bottom", "Left", "Right", "Between"]) {
    preferences["screenGap" + edge] = style.bar.padding;
}

function runtime() {
    const context = vm.createContext({ preferences, print() {}, assert });
    vm.runInContext(source, context);
    vm.runInContext(`
        KWIN = { readConfig: (key, fallback) => preferences[key] ?? fallback };
        CONFIG = KWINCONFIG = new KWinConfig();
    `, context);
    return context;
}

test("fits minimums in either orientation and preserves rectangles, gaps, and available space", () => {
    const context = runtime();
    vm.runInContext(`
        for (const horizontal of [false, true]) {
            for (const minimums of [[600, 150], [150, 600], [600, 557], [900, 150], [150, 150]]) {
                const rectangles = horizontal
                    ? [new Rect(20, 30, 578, 900), new Rect(606, 30, 579, 900)]
                    : [new Rect(20, 30, 900, 578), new Rect(20, 616, 900, 579)];
                const limits = minimums.map(value => ({ width: value, height: value }));
                const dimension = horizontal ? "width" : "height";
                const coordinate = horizontal ? "x" : "y";
                const result = fitColumnMinimums(rectangles, limits, horizontal, 8);
                assert.equal(result, rectangles);
                assert.equal(result[0] instanceof Rect, true);
                assert.ok(result.every((rectangle, index) => rectangle[dimension] >= minimums[index]));
                assert.ok(Math.abs(result[0][dimension] + result[1][dimension] - 1157) < 1e-8);
                assert.ok(Math.abs(result[1][coordinate] - result[0][coordinate] - result[0][dimension] - 8) < 1e-8);
                const before = JSON.stringify(result);
                fitColumnMinimums(rectangles, limits, horizontal, 8);
                assert.equal(JSON.stringify(result), before);
            }
        }
    `, context);
});

test("leaves impossible fits to upstream policy and rejects invalid size data", () => {
    const context = runtime();
    vm.runInContext(`
        const rectangles = [new Rect(0, 0, 900, 578), new Rect(0, 586, 900, 579)];
        const before = JSON.stringify(rectangles);
        fitColumnMinimums(rectangles, [{ width: 100, height: 600 }, { width: 100, height: 600 }], false, 8);
        assert.equal(JSON.stringify(rectangles), before);
        assert.throws(() => fitColumnMinimums(rectangles, [], false, 8), /matching lengths/);
        assert.throws(() => fitColumnMinimums(rectangles,
            [{ width: 100, height: NaN }, { width: 100, height: 150 }], false, 8), /finite/);
        assert.equal(fitColumnMinimums([], [], false, 8).length, 0);
    `, context);
});

test("moves either right tile into left stack through upstream engine without floating", () => {
    const context = runtime();
    vm.runInContext(`
        for (const selected of [1, 2]) {
            for (const origin of [0, 2194]) {
                for (const top of [46, 54]) {
                    const engine = new TilingEngine();
                    const area = new Rect(origin, top, 2194, 1234 - top);
                    const surface = { id: "trial", layoutId: "trial", output: { name: "trial", geometry: area },
                        activity: "trial", vDesktop: { id: "trial", name: "Trial" }, workingArea: area };
                    const entry = new LayoutStoreEntry("trial", "Trial", "trial", "trial");
                    const layout = entry.currentLayout;
                    assert.equal(layout.classID, "ColumnsLayout");
                    const context = { backend: "test", currentSurface: surface, currentWindow: null };
                    const tiles = [];
                    const arrange = () => engine.arrangeScreen(context, {
                        srf: surface, layout, workingArea: area, overCapacity: [],
                        tileables: engine.windows.list.filter(tile => tile.isTileable), visibles: tiles,
                    }, "shortcut", "test");
                    const snapshot = () => JSON.stringify(tiles.map(tile => ({ state: tile.state, rect: tile.geometry })));
                    for (let index = 0; index < 3; index++) {
                        const driver = { id: String(index), surface, minSize: { width: 150, height: index ? 150 : 600 },
                            maxSize: { width: Infinity, height: Infinity }, geometry: new Rect(0, 0, 700, 650),
                            floatGeometry: new Rect(0, 0, 700, 650), shouldFloat: false,
                            commit(_context, geometry) { if (geometry) this.geometry = geometry; } };
                        const tile = new WindowClass(driver);
                        tile.state = WindowState.Tiled;
                        tile.focusTime = index + 1;
                        engine.windows.push(tile);
                        tiles.push(tile);
                        context.currentWindow = tile;
                        arrange();
                    }
                    assert.equal(tiles[1].geometry.x, tiles[2].geometry.x);
                    assert.ok(tiles[0].geometry.x < tiles[1].geometry.x);
                    context.currentWindow = tiles[selected];
                    assert.equal(layout.handleShortcut(new EngineContext(context, engine), KrohnkiteAction.MoveLeft), true);
                    arrange();
                    const left = [tiles[0], tiles[selected]].sort((a, b) => a.geometry.y - b.geometry.y);
                    assert.equal(left[0].geometry.x, left[1].geometry.x);
                    assert.ok(tiles.every(tile => tile.state === WindowState.Tiled));
                    assert.ok(tiles[0].geometry.height >= 600);
                    assert.ok(Math.abs(left[1].geometry.y - left[0].geometry.maxY - 8) < 1e-8);
                    assert.equal(tiles[3 - selected].geometry.height, area.height - 16);
                    const moved = snapshot();
                    arrange();
                    assert.equal(snapshot(), moved);
                    tiles[0].window.minSize = { width: 150, height: 650 };
                    arrange();
                    assert.ok(tiles[0].geometry.height >= 650);
                    assert.ok(tiles.every(tile => tile.state === WindowState.Tiled));
                    assert.equal(layout.handleShortcut(new EngineContext(context, engine), KrohnkiteAction.MoveRight), true);
                    arrange();
                    assert.equal(tiles[1].geometry.x, tiles[2].geometry.x);
                    assert.equal(tiles[0].geometry.height, area.height - 16);
                    assert.ok(tiles.every(tile => tile.state === WindowState.Tiled));
                    assert.equal(entry.setLayout(MonocleLayout.id).classID, "MonocleLayout");
                    assert.equal(entry.setLayout(MonocleLayout.id), layout);
                }
            }
        }
    `, context);
});
