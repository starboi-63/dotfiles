# Krohnkite column minimums

The pinned upstream package supplies the tiling engine. `minimums.ts` adjusts sizes inside a column when its weighted split would violate an application's minimum size. It preserves total space and gaps, borrows from tiles with spare space, and leaves already valid rectangles unchanged. If minimum sizes cannot fit together, upstream's floating fallback still applies. This does not resize column widths to accommodate oversized applications.

The build verifies the original package's SHA-256 digest before making two exact source substitutions. `ColumnLayout.apply` passes its computed rectangles through this function. `WindowClass.minSize` reads current window hints instead of retaining hints from initial mapping. Both substitutions must match exactly once. Only the compiled script and package version differ from upstream. The original archive remains unchanged, and the output is `.build/krohnkite-patched.kwinscript`.

Vertical Columns starts with two equal-width columns. New windows join the focused column once both exist. Shift+Option+H/L moves a window between columns, and Shift+Option+J/K changes its position within a column. Monocle retains and restores the same Columns layout instance.

`tests/columns.cjs` executes the patched upstream classes and checks the three-window movement, reverse movement, dynamic minimums, both panel reservations, displaced output origins, unchanged gaps, and repeat arrangement. Native window sizing after login remains a separate integration check. Updating the installed package requires normal logout/login. Do not hot-reload Krohnkite.
