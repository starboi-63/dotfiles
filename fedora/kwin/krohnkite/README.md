# Krohnkite column minimums

The [maintained KWin 6 fork](https://codeberg.org/anametologin/Krohnkite) supplies the tiling engine. The pinned alpha supports independent desktop selection per output. Stable `0.9.9.2`, inspected during setup, selected one desktop for all outputs.

`minimums.ts` adjusts column splits that violate application minimum sizes. It borrows available space from other tiles while preserving gaps and total size. Valid rectangles stay unchanged. Impossible fits retain upstream's floating fallback; the fix does not widen columns for oversized applications.

The build verifies the pinned archive and requires exactly one match for each of two source substitutions. `ColumnLayout.apply` passes computed rectangles through `fitColumnMinimums`; `WindowClass.minSize` reads current window hints instead of initial hints. Only the compiled script and package version differ from upstream. The original archive stays intact.

Vertical Columns starts with two equal-width columns. New windows join the focused column once both exist. Shift+Alt+H/L transfers windows between columns; Shift+Alt+J/K reorders a column. Monocle restores the same Columns layout instance when toggled off.

`tests/columns.cjs` exercises the patched upstream engine for both movement directions, dynamic minimums, floating panel reservations, displaced outputs, and repeated arrangement. Native application sizing still requires integration testing. Install `.build/krohnkite-patched.kwinscript` and log out/in to load changes. Never hot-reload Krohnkite.
