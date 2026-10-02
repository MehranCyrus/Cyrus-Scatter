# Remaining layer/settings flash: traced resize sequence

2026-10-03. The user reports the remaining flash while opening or closing a layer or one of its settings panels. This follow-up traces source UI **2026-10-02.5** in a new private Max 2027.1 process, PID 13396. The trace derivative adds logging only. Production source and installation were not changed in this investigation. The artist window was in active use, so its loaded revision was not independently confirmed.

## Confirmed operations

The width/statistics timer was disabled during the four opening/closing probes. Every probe changed the main rollout's height, and that property assignment immediately changed its native width from **240 to 162 pixels** and centered it. The existing width repair then restored **240 pixels** and the 4-pixel inset.

| Action | Main height | Native width sequence |
|---|---|---|
| Close warmed Grass layer | 488 → 350 | 240 → 162 → 240 |
| Open warmed Grass layer | 350 → 488 | 240 → 162 → 240 |
| Open Collision / Relax | 488 → 731 | 240 → 162 → 240 |
| Close Collision / Relax | 731 → 488 | 240 → 162 → 240 |

Opening a nested setting additionally changes the inner sections height and the layer height before updating the outer subrollout and main rollout. The trace places the **main rollout height assignment** immediately before the 162-pixel reset. An unchanged layout call caused no height or width writes. No width rebuild/remount was recorded, and scatter build counters/dirty state stayed unchanged.

[Raw sequence](evidence/layer-resize/layer-layout-sequence.json) and [summary](evidence/layer-resize/SUMMARY.json). The actual native-window shrink/restore is confirmed. Its relationship to the reported brief visible flash is strongly supported, but no high-speed frame capture established the flash's duration or all contributing paint operations.

## Polling is not an idle resize loop in this fixture

- Layer Manager closed: 236 width checks, **zero width writes, height writes or control remounts**.
- Layer Manager open: 221 width checks and 111 statistics reads, again **zero width writes, height writes or control remounts**.
- One statistics read occurred on layer activation even with the manager closed. The source routes selection through `syncSelection()`; that read did not cause a layout write independently.

The second idle observation crossed midnight. Raw `timeStamp()` subtraction became negative; the summary preserves it and also records elapsed time modulo one day. Conclusions use event counts rather than presenting these idle intervals as a performance benchmark.

Revision 5 repaired stale narrow pixels and expedited repair after reopening the main header. It did **not** eliminate the transient width reset caused by changing the main rollout's height. Settled-width and cache-preservation checks therefore cannot establish that layer expansion is visually flicker-free.

## Smallest next experiment

Test one bounded change around this exact height/width operation, with warmed controls and passive statistics held constant: perform layout with intermediate painting suspended, restore painting on success and exception paths, and redraw the complete owned control subtree at the final geometry. Compare real layer/setting clicks and check scrolling, hidden/collapsed state, retained HWNDs, cache counters and command-panel resizing before adopting it.

This is a proposed experiment, not an implemented fix. [Microsoft's WM_SETREDRAW contract](https://learn.microsoft.com/en-us/windows/win32/gdi/wm-setredraw) describes redraw suspension, including visibility changes and the need to redraw children/frame areas afterward. Those constraints mean a blind pair of messages is insufficient qualification. If the containing Max/Qt host still paints intermediate geometry, use a supported native rollup/layout integration rather than accumulating repaint patches. [Autodesk's IRollupWindow API](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-CPP-API-REF/class_i_rollup_window.html) exposes page-height and layout operations; integration with this scripted nested host remains untested.

The first-visit control construction cost is separate and unchanged by this trace. The reusable-editor/Qt investigation remains relevant to that cost, but this finding supports targeting the specific resize operation before replacing the complete UI.

## Reproduction

Local invocation-only harness: `_local/maintenance/ui-main-reopen-2026-10-02/launch-flash-lab.py`, `flash-measure.ms`, `flash-idle-read.ms`, `flash-manager-read.ms` and `summarize-flash.py`. Private files and source/trace hashes are recorded in [launch receipt](evidence/layer-resize/launch.json); verified loaded native paths are in [ready receipt](evidence/layer-resize/ready.json). These local harness files are ignored and are not artist startup scripts.

The first probe attempt hit a MAXScript compile-time binding issue for `UILayerNode`; an explicit global declaration corrected the harness before any measurements were collected. This did not require a product change.
