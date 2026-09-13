interface ColumnSize {
    width: number;
    height: number;
}

interface ColumnRect extends ColumnSize {
    x: number;
    y: number;
}

/** Fits column tiles to application minimums without changing available space or gaps. */
function fitColumnMinimums<Rect extends ColumnRect>(
    rectangles: Rect[], minimums: readonly ColumnSize[], horizontal: boolean, gap: number,
): Rect[] {
    if (rectangles.length !== minimums.length) {
        throw new Error("Column rectangles and minimum sizes must have matching lengths.");
    }
    const dimension = horizontal ? "width" : "height";
    const coordinate = horizontal ? "x" : "y";
    const entries = rectangles.map((rectangle, index) => {
        const minimum = minimums[index]?.[dimension];
        const length = rectangle[dimension];
        if (minimum === undefined || !Number.isFinite(minimum) || minimum < 0
            || !Number.isFinite(length) || length < 0) {
            throw new Error("Column lengths and minimums must be finite and nonnegative.");
        }
        return { rectangle, length, minimum: Math.ceil(minimum) };
    });
    const available = entries.reduce((total, entry) => total + entry.length, 0);
    const required = entries.reduce((total, entry) => total + entry.minimum, 0);
    if (required > available || entries.every(entry => entry.length >= entry.minimum)) {
        return rectangles;
    }
    const expanded = entries.reduce((total, entry) => total + Math.max(entry.length, entry.minimum), 0);
    const deficit = expanded - available;
    const spare = expanded - required;
    const ordered = [...entries].sort((left, right) => left.rectangle[coordinate] - right.rectangle[coordinate]);
    let position = ordered[0]?.rectangle[coordinate] ?? 0;
    for (const entry of ordered) {
        const length = Math.max(entry.length, entry.minimum);
        const reclaimed = deficit * (length - entry.minimum) / spare;
        const fitted = Math.max(entry.minimum, length - reclaimed);
        entry.rectangle[coordinate] = position;
        entry.rectangle[dimension] = fitted;
        position += fitted + gap;
    }
    return rectangles;
}
