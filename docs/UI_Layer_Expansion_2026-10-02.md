# Cyrus Scatter layer UI: diagnosis, implementation and 0.64 qualification

Date: 2026-10-02. Historical candidate: product **0.64**, native library **0.25**, UI revision **2026-10-02.2**. Source changes were tested in an isolated Max 2027.1 session. Normal-profile installation and broader host/DPI qualification remain separate.

The [rollback and diagnostic guide](UI_Layer_Responsiveness_2026-10-02.md) records
the current revision 4 candidate; experimental revision 3 was withdrawn. It also
corrects a revision 2 reporting error: the final generated script still included
the Collision hide/show handler despite the earlier prototype trace showing its
removal. The small removal remains in revision 4.

The [full implementation report](UI_Layer_Implementation_Report_2026-10-02.md) explains the changes, test methodology, exact counters, source ownership, package identity and remaining checks. This document retains the original diagnosis and proposed scope below the current status.

## Current result

Layer headers now build their six child sections on the first expansion. Opening a header selects that layer, clicking a manager row opens the matching layer, and Enter provides the same action. Layer Manager shows cached placement counts, compact states and selected-layer details. Reading those statistics does not generate points or request a viewport redraw.

The user's follow-up exposed two different problems. The earlier UI test session loaded **0.63 native binaries**, even though the local script/source contained the newer Mesh integration. It was not a valid test of the 0.64 Mesh improvement. That private scene was saved as `build/retained-integration-2026-10-02/ui-layer-status-01/previous-ui-test.max` and its Max process was closed. The replacement session uses native files byte-for-byte identical to the 0.64 Max 2027 package. The original artist `SaveSelect 2.max` session was preserved.

The flashing had a separate source in the UI code: a layout workaround hid and showed every control in any open Collision / Relax section. A layer expansion also executed parent layout twice. These operations were repainting controls; the measured navigation did **not** rebuild the scatter.

## Changes delivered in this candidate

- Correct the reversed `rolledUp` event condition for all ten layer slots. Retain lazy first creation and reuse the child controls on subsequent openings.
- Synchronize active-layer context between headers and Layer Manager. Map manager rows to their owning layer objects, including enable actions.
- Add Count and State columns, exact counts, completed preview mode/count, last build time and an enabled-layer total. Explicitly distinguish stale Manual data, disabled/hidden layers, errors, empty results and unbuilt results.
- Read scalar cache metadata through `uiLayerStats()` without changing the existing nine-field `cacheSnapshot()` contract. Remember the display mode associated with the completed cache; a transferred legacy cache reports an unknown mode instead of guessing.
- Poll background statistics using a 500 ms minimum-interval guard on the existing 300 ms timer while the manager is open; regular scheduling usually gives about 600 ms between polls. Explicit UI actions can refresh immediately. Change .NET strings only when their values differ; passive refresh does not recreate the rows.
- Remove the Collision control hide/show cycle. Set panel heights, positions, titles and selection only when changed. Run one final parent layout after layer expansion, with guards against intermediate layouts during mounting and selection.
- Track the width used to construct controls separately from the temporary rollout window width that Max resets during height changes. Repair that host width without misclassifying it as a new content width. Use `setWindowPos` without an immediate forced repaint.
- Coalesce actual width reconstruction until held input ends. Preserve the host scroll position and expanded section states, including sections under a currently collapsed parent. Width reconstruction is still used; this is not a replacement UI framework.

The changes belong to [host.ms](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/host.ms), [containers.ms](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/containers.ms), [performance.cjs](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/performance.cjs), [layer-status.cjs](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/layer-status.cjs), its [manager methods](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/layer-status-manager.ms), and related generator stages. The generated [AminScatterObject.ms](../AminScatter/scripts/AminScatterObject.ms) is reproducible: regeneration leaves its SHA-256 unchanged. No C++ renderer changes were made for this UI revision. The renderer script from `AminScatterObjectDraw` through the end of the file is also identical to the original 0.64 package.

## What was verified

| Check | Result and evidence |
| --- | --- |
| Correct native engine | Loaded module paths identify the private 0.64 binaries. Hashes and package comparisons are in [qualification.json](UI_Layer_Evidence_2026-10-02/qualification.json) and [ready.json](UI_Layer_Evidence_2026-10-02/ready.json). |
| Layer navigation, statistics and lifecycle | **76 assertions passed** in [ui-regression.json](UI_Layer_Evidence_2026-10-02/ui-regression.json). All ten first expansions, warm reuse, manager selection, pending child states after width reconstruction, Manual/error/disabled/empty states and the cache contract were checked. |
| Passive statistics cost | In 100 synchronous refresh calls over ten cached rows, median **1.68 ms**, p95 **1.99 ms**. This is the scalar UI refresh duration, not viewport frame time. No placement/preview builds were added. |
| Mesh integration | **7 assertions passed** in [ui-mesh-064.json](UI_Layer_Evidence_2026-10-02/ui-mesh-064.json), using **5,500 instances / 352,000 represented triangles**. Category navigation and 30 scripted camera redraws preserved preview build counts, GPU generation and explicit upload count. Native draws advanced without new failures. Root control handles remained stable during navigation. |
| Actual mouse interaction | An untouched layer opened its six categories on one click. Collision / Relax controls remained visible after removal of the repaint workaround. Opening, closing and reopening categories were inspected in the private Max window. |
| Actual panel resizing | Dragged the command-panel boundary wider and back. Manager selection and counts survived. The final content width was 240 logical pixels; preview build counters and native generation/uploads were unchanged. See [ui-resize-064.json](UI_Layer_Evidence_2026-10-02/ui-resize-064.json). Native multi-column layout can still constrain layer-name width; tooltips and selected detail retain the full name. |
| Package | ZIP integrity and every manifest payload hash checked. Its script equals the tested script; its native files equal the original 0.64 package. This is package verification, not a normal-profile installer smoke test. |

The focused test recipes are [setup.ms](../tools/ui-tests/setup.ms), [regression.ms](../tools/ui-tests/regression.ms) and [mesh-064.ms](../tools/ui-tests/mesh-064.ms). They require the isolated integration fixture; they reset its disposable scene and must not be run in an artist session.

The [baseline trace](UI_Layer_Evidence_2026-10-02/ui-layout-baseline.json) and [candidate trace](UI_Layer_Evidence_2026-10-02/ui-layout-candidate.json) isolate the layout work:

| Action | Previous UI: executed layouts / hide-show cycles | Revised UI: executed layouts / hide-show cycles |
| --- | ---: | ---: |
| First layer expansion | 2 / 0 | 1 / 0 |
| Warm layer expansion | 2 / 0 | 1 / 0 |
| Open Collision / Relax | 1 / 1 | 1 / 0 |
| Open another layer while Collision is visible | 2 / 2 | 1 / 0 |
| Five unchanged layout requests with Collision visible | 5 / 5 | 5 / 0 |

Mount-time event entries with the `building` guard set are suppressed requests, not executed parent layouts. First expansion still creates six child rollouts; warm navigation mounts none. Traces were collected before the final `contentWidth` bookkeeping adjustment; final non-instrumented regression and Mesh checks cover the packaged script. The retained copies normalize MAXScript integer64 `L` suffixes to valid JSON; original trace hashes are recorded in the qualification receipt. Wall-clock trace timings are not a controlled latency benchmark.

## Trying the correct combination

The separate package is [Cyrus Scatter 0.64 + UI revision 2 for Max 2027](../dist/ui-layer-0.64-r2/CyrusScatter-0.64-Max2027.mzp), with [instructions](../dist/ui-layer-0.64-r2/READ-ME-FIRST.txt). Run it through Scripting > Run Script after saving work, then restart Max. The native engine remains 0.64; the UI revision is reported by `$.uiVersion()` when a scatter controller is selected. The original 0.64 package remains in `dist/retained-mesh-0.64`.

The already open private test window is named `Cyrus_UI_064_R2.max`. Its saved scene and raw probe scripts stay under `build/mesh-integration-2026-10-02/ui-layer-status-064-01/`. It is a UI/integration fixture, not a representative foliage performance benchmark. The normal Max profile was not installed or hot-reloaded by this work.

## Remaining qualification

This removes confirmed unnecessary repaint work and passed the focused interaction checks. It does not establish that every native rollout paint transition is imperceptible. No new FPS gain or zero-flicker guarantee is claimed.

- Test the packaged UI in Max 2026 and at 150%/200% DPI. This round used Max 2027.1 at the current desktop scaling.
- Complete broader add/remove/Undo, source/stroke list selection and keyboard-focus restoration checks. Preserving expansion and host scroll state is implemented; full editor-state persistence is not.
- Check long-name usability at narrow and multi-column command-panel widths, additional themes and all nested controls.
- Keep Brush implementation separate until the user accepts this interaction change.

API rationale: Autodesk documents the [opposite meanings of the expansion event and creation option](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-DC435555-362D-4A03-BCF2-21179C5442F2.html), and [the repaint argument of `windows.setWindowPos`](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/Interaction-With-The-Operating/GUID-282F32AC-5A80-4FDB-B8C0-275D2CC15845.html). The rollout width property does not resize a rollout in the command panel, so a simple assignment was not a substitute for repairing the native window width.

---

## Original diagnosis and proposed scope — historical record

Everything below records the inspection **before implementation**. Its proposed tasks, source line numbers, hashes and statements that a fix was pending describe that earlier state. The current implementation and qualification limits are above.

The layer expansion glitch is reproducible in the open `SaveSelect 2.max` scene in 3ds Max 2027. Its cause is a reversed event condition in the code that creates layer controls on demand. The recommended next change is a small repair to that condition, followed by focused layout and interaction improvements. Keep the existing native Max interface and lazy creation of controls.

## What was observed in Max

The selected controller was `Cyrus Scatter001`, with six layers visible. All its categories and layers were initially collapsed. Individual mouse clicks produced this sequence:

| Action | Observed result |
| --- | --- |
| Click Grass once | Its arrow points down, but no child sections appear. |
| Click Grass again | Its arrow returns to the collapsed position. |
| Click Grass a third time | Source Object, Point Generation, Collision / Relax, Area, Diversity / Colors and Randomize XYZ appear. |
| Click Source Object once | Its controls appear on the first click. |
| Close Source Object and Grass, then open Layer Manager | Layer Manager opens on the first click. Its selected layer is still clover. |

This reproduces the reported symptom. More precisely, the observed sequence is **open empty, close, open populated**; a rapid pair of extra clicks can feel like a double-click requirement. No special double-click action is needed by the intended design.

The inspected sections were returned to their original collapsed state. No plugin installation, production source edit, scatter parameter edit or scene save was performed. Window activation required restoring and maximizing Max; this was not a viewport performance test. The FPS text in the captures is not benchmark evidence.

## How the interface is built

The runtime interface is MAXScript rollouts nested inside subrollouts in the Modify panel. Layer Manager also uses a .NET Windows Forms ListView. JavaScript is used during development to generate the MAXScript; it is not the runtime UI framework.

The source chain is [generate.cjs](../AminScatter/tools/ui/generate.cjs), [container templates](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/containers.ms), [host template](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/host.ms), feature stages including [performance.cjs](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/performance.cjs), and [responsive.cjs](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/responsive.cjs). The result is [AminScatterObject.ms](../AminScatter/scripts/AminScatterObject.ms).

There are ten separate layer slot declarations. Each layer creates six child sections when `ensureContents()` runs, then retains them while that layer remains mounted. The host calculates the total height and resizes the containing panels. The current width timer checks every 300 ms and can reconstruct the root and layer panels when their width changes.

The ownership of a fix matters: edit the generator stage or template and regenerate the output. Editing only the generated script would be overwritten by a subsequent build.

## Confirmed expansion defect

[Autodesk's rollout event documentation](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-DC435555-362D-4A03-BCF2-21179C5442F2.html) specifies that the `rolledUp` event argument is `true` for an expanded rollout and `false` for a collapsed rollout. This differs from the similarly named `rolledUp:` creation option, where `true` requests a collapsed rollout.

The generator currently emits:

```maxscript
on layerPanel_1 rolledUp state do (
    if not state and not parentView.building do ensureContents()
    parentView.layoutPanels()
)
```

That loads the children on collapse. On the first expansion, `children` is still empty; `fitHeight()` sums an empty array and assigns zero content height. The native header changes its arrow correctly while our content remains absent. Closing the panel constructs the children, so the next expansion works.

The minimum proposed correction is:

```maxscript
on layerPanel_1 rolledUp expanded do (
    if expanded and not parentView.building do ensureContents()
    parentView.layoutPanels()
)
```

Apply this through `performance.cjs`, where all ten handlers are generated. Naming the event argument `expanded` and the mounting option `collapsed` makes the two meanings explicit. Keep the existing `children.count == 0` guard so a warm panel is not reconstructed on every opening.

This is a confirmed source defect with a matching live reproduction. The corrected handler has **not** been installed or runtime-tested in this investigation. It should repair the first-click behavior without changing placement calculations or the retained viewport renderer; that separation must be checked during implementation.

## Related findings and priorities

| Priority | Finding and evidence | Recommended action |
| --- | --- | --- |
| First repair | `overlaps.cjs` also emits `if not state do refreshOverlap()` for Layer Manager. Source-confirmed: the refresh happens on collapse. Manager is already populated by its initial `open` handler, so this is not the same empty-panel failure. | Refresh cached manager values on expansion. Do not attach a scatter rebuild to this event. |
| Next layout pass | `host.ms` reconstructs all root rollouts and layers during a width rebuild. It saves expansion flags but not all control selections, keyboard focus or scroll positions. | Resize controls in place where practical. Coalesce width changes, and retain any necessary reconstruction only after preserving UI state. Measure before replacing the existing mechanism. |
| Next layout pass | `performance.cjs` restores child expansion flags only when the parent was expanded. A collapsed layer can therefore lose its remembered child states after reconstruction. Source finding; not separately reproduced during this visit. | Store pending child states by layer object identity and section key. Apply them when that layer is next lazily mounted. Keep the documented fresh-selection collapse policy unless deliberately changing it. |
| Next layout pass | Height calculation uses `23.333 * dpiScale`; scale is inferred from rollout and window heights. Every layout pass can hide and show all controls in an open Collision / Relax section. | Establish consistent logical-pixel measurements, guard against nested layout calls during child creation, and reduce repainting to affected controls. Clipping or flicker across DPI settings remains a test hypothesis, not a confirmed cause of this click bug. |
| Usability pass | After inspecting Grass, Layer Manager still selected clover. Source confirms that layer header expansion does not call `selectLayer()`. | Show an explicit selected-layer label beside manager settings. Keep expansion and selection distinct in the first repair; any later synchronization must be deliberate and tested. |
| Usability pass | The `Refresh counts` button calls `obj.refreshAll()` before reading statistics. Source-confirmed: the action rebuilds previews, despite its modest label. It was not pressed during this inspection. | Either label the existing behavior clearly as a rebuild, or offer cached counts with a visible stale status and a separate explicit Update action. |

The additional layout findings are not evidence that Max requires a different UI framework. The current implementation can support a reliable interface after its state and layout responsibilities are made clearer.

## Making the interface easier to use

Keep the familiar expandable categories, but give the user clearer context and a shorter path to common controls:

1. Keep Enable, update mode, Update and a concise status together near the top. Read status from cached results; browsing the interface should not trigger point generation.
2. Keep Layer Manager focused on choosing, enabling, naming, adding and removing layers. Give overlap and final cleanup settings their own clearly labelled group with the affected layer name visible.
3. Preserve the current layer section names for the first repair. Use consistent margins and label widths, and test long source names at a narrow command-panel width.
4. Reduce the Source Object section's long stack of equally prominent buttons by grouping add actions and separating less frequent Point/Empty/replacement actions. Preserve keyboard access and discoverability.
5. Make open panels stay where the user expects while resizing. Preserve source/stroke selections and scroll position during a structural refresh. Consider explicit Expand All / Collapse All controls only after ordinary expansion is reliable.

These are proposed interaction improvements, not a completed visual redesign. The immediate goal is predictable clicks, stable scrolling and clear layer ownership. Brush controls should then enter the same lifecycle and layout system instead of introducing another independent set of resize workarounds.

## Quick status for each layer

The follow-up request is to show how much scatter each layer contains directly in Layer Manager. Add a right-aligned **Count** beside each name, with a compact state indicator. Label the count as **Placements from the last preview build**. Show the full state text below the selected row and in a tooltip; use a Status column when the panel has enough width. Preserve the existing enable checkboxes and layer order.

Illustrative values only, not measurements of the user's scene:

| Layer | Count | Status |
| --- | ---: | --- |
| Grass | 24.6k | Cached |
| Leaves | 8.2k | Cached |
| clover | 12.4k | Needs update |
| BushesCenter | 320 | Cached |
| Bourder | 1.1k | Off |
| Street_Plant | -- | Not built |

The selected-layer detail should give the exact placement count, preview mode and preview count, and **Last preview build: N ms**. A footer can total the last known counts for enabled layers, explicitly marking the total stale or incomplete when appropriate. Long names retain a tooltip; status must not depend on color alone. Use modest formatting and fixed count-column width so changing numbers do not move the name or selection.

### Use precise meanings for the numbers

The generated script already exposes `cacheSnapshot()` at line 11271. Its scalar fields provide most of the starting data:

| Existing value | What it can tell the user | Limit |
| --- | --- | --- |
| `generatedCount`, snapshot field 5 | Placement rows from the latest preview generation, after its filters and CS Edit | This path uses `previewOnly:true`; point-only sources can be included. It is not a guaranteed final-render object count. |
| `cachedPointCount`, field 2 | Point Cloud: cached preview dots. Proxy/Mesh: cached shown instances | Record the mode belonging to that completed cache. These are not necessarily the points or instances visible inside the current camera view. |
| `dirty` and `previewError`, fields 3 and 4 | Known pending changes and preview failures | A failed preview sets `dirty=false`; never infer success from that flag alone. Known invalidation is not a complete proof that every external dependency is current. |
| `previewBuildMs`, field 7 | Duration of the last preview build attempt | This includes placement and preview preparation. It is not frame time, per-layer FPS cost or render duration. |
| `requestedCount` and `densityCapped`, fields 8 and 9 | Requested generation count and the existing density-cap warning | Requested count is not the final number left after filters. |

For example, a layer can have 1,000 tree placements and a much larger point-cloud dot count. Both are useful, but they describe different things. Placement count also does not measure RAM, VRAM or surface area occupied: source complexity, preview mode and shared resources matter.

The existing native `cyrusRetainedStats` implementation in [point_display.cpp](../AminScatter/src/point_display.cpp) mixes controller-generation statistics with process-wide upload and reservation counters. Those byte counters must not be presented as individual-layer RAM or VRAM. Defer a memory column until a scoped native metric accounts for shared storage and clearly distinguishes CPU buffers, upload payload and GPU allocation.

### Keep status collection inexpensive and truthful

Add a small read-only scalar accessor on the layer for presentation data; do not change the positional `cacheSnapshot()` contract used elsewhere. Keep completion validity and the preview mode associated with the completed result. A zero count from a successful empty build must be distinguishable from an unbuilt or failed result. `previewBuildCount==0` alone is insufficient because `forcePreviewUpdate()` resets that counter while an older cache can still exist. The current failure path can also retain a generated placement count after preview-buffer creation fails.

Read the controller's `layerObjects` and enable flags directly. Do not use `layerEntries()` or `allStatus()` for passive statistics: that path synchronizes layer settings. Do not call `placements()`, `previewCache()`, `refreshAll()`, `previewPoints()` or request a viewport redraw from a status refresh. No point-array traversal, mesh evaluation or scene-wide scan is needed.

Update existing row subitems only when their displayed values change. The current `refresh()` clears and recreates the list, so it should remain a structural operation rather than the statistics refresh path. Coalesce updates after completed builds and known invalidations. If a timer is needed to pick up script-driven changes, use one guarded scalar check while the manager is visible, for example every 500 ms, and stop it when the panel closes. Measure its overhead before qualification.

Recommended states are Cached, Needs update, Not built, Empty, Error and Off. Off preserves the last known count in a muted style and contributes zero to the enabled-layer total; preview-hidden and controller-disabled conditions need explicit explanations in the selected detail. In Manual mode, display the cached value with Needs update instead of calculating just to refresh the number. On an error, show an error state even if an intermediate placement count is available. Do not claim retention of a last successful statistic unless that metadata has actually been recorded.

The current ListView already uses Details mode. Microsoft documents [columns and subitems](https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.listview.view?view=windowsdesktop-9.0) and [item tooltips](https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.listviewitem.tooltiptext?view=windowsdesktop-9.0), so the proposal can extend the existing control. Host-specific sizing, hover behavior and dark-theme readability still need Max 2026/2027 testing.

## Implementation sequence

### Repair and qualify expansion

- [ ] Correct the layer event polarity in `performance.cjs` and the manager refresh polarity in `overlaps.cjs`.
- [ ] Regenerate the script and confirm all ten layer slot handlers changed consistently.
- [ ] Exercise real header clicks in Max. Verify first expansion mounts exactly six child sections, collapsing mounts nothing new, and reopening reuses the existing sections.
- [ ] Test one layer, all ten slots, a newly added layer, and a controller reselected in Modify. Use a disposable scene for add/remove and Undo tests.
- [ ] Keep the existing explicit restoration of an already-expanded layer during a rebuild; the `building` guard suppresses ordinary lazy initialization in that path.

### Stabilize layout and lifecycle

- [ ] Measure counts and durations for content creation, layout and width reconstruction before changing their scheduling.
- [ ] Suppress intermediate parent layouts while mounting a group of children, then perform one final layout. Restore flags and report an error if mounting fails; a partially initialized panel must not appear successfully loaded.
- [ ] Preserve pending section states, source/stroke selections and scroll position independently of disposable rollout controls.
- [ ] Move toward resizing existing controls. If native host constraints require remounting, coalesce it and restore state explicitly.
- [ ] Qualify the Collision / Relax repaint workaround before removing or narrowing it.

### Polish the visible workflow

- [ ] Add clear selected-layer context to manager settings.
- [ ] Add cached placement counts and state indicators beside layer names, plus selected-layer details, following the data meanings and refresh restrictions above.
- [ ] Clarify actions that rebuild scatter, including Refresh counts.
- [ ] Reduce long vertical sections with purposeful grouping, and check narrow widths and long names.

Do not combine this first repair with a renderer rewrite, a new UI framework or the Brush implementation. Each can be evaluated separately after the expansion regression is covered.

## Acceptance checks

| Check | Required result |
| --- | --- |
| First click and subsequent toggles | Arrow and contents agree immediately for every layer slot; no close/reopen workaround. |
| Nested categories | Source Object, Point Generation, Collision / Relax, Area, Diversity / Colors and Randomize XYZ expand correctly. Ordinary value dropdowns keep their existing selection behavior. |
| Width and scaling | No clipped controls, repeated reconstruction loop or lost scroll position after widening/narrowing the command panel. Check 100%, 150% and 200% scaling on suitable test configurations. |
| State restoration | Expanded and collapsed parents recover their remembered child states after width rebuilds; structural layer edits never bind controls to the wrong layer. |
| Side effects | Pure open/close/layout actions produce no placement or preview rebuilds in a settled scene. Record cache/rebuild counters and dirty state instead of inferring this from viewport FPS. |
| Per-layer status | Check successful zero, unbuilt, error, stale Manual, disabled and hidden-preview cases. Point Cloud dot counts and Proxy/Mesh instance counts have correct labels, including after mode changes. Exact values are available alongside abbreviated row counts. |
| Status refresh | Updating counts preserves selected rows, checkboxes, keyboard focus and scroll position; it adds no scatter rebuild or redraw request. Totals exclude disabled layers and identify stale/incomplete data. |
| Failure and closure | Switching objects, closing Modify, and a failed child mount leave no stuck `building` flag, duplicate controls or abandoned timers. |
| Supported host versions | Run interactive checks in Max 2027 and Max 2026. SDK compilation alone does not qualify UI behavior in the boss's Max version. |

No performance target or fixed-build pass is claimed here. The expected result is correct first-click expansion while preserving the existing lazy-loading benefit. Native engine suites are not a substitute for these UI checks.

## Source provenance and limits

Inspected repository base: `1bfb400abc19b7472b4c20621970d435ac214c33`, with existing unrelated local changes. Source anchors at inspection:

| File | Anchor |
| --- | --- |
| `AminScatter/tools/ui/performance.cjs` | Lines 4–7: lazy content handler and expanded-layer restoration |
| `AminScatter/tools/ui/overlaps.cjs` | Line 97: manager event; line 92: count button rebuild |
| `AminScatter/tools/ui/templates/host.ms` | Lines 15–29: layout/repaint; 34–63: reconstruction and width polling |
| `AminScatter/tools/ui/templates/containers.ms` | `CyrusMount`, Layer Manager selection, layer height and contents |
| `AminScatter/scripts/AminScatterObject.ms` | Lines 9645–9661: first layer; equivalent handlers through slot ten; lines 11441–11489: generated host |

SHA-256 of `performance.cjs`: `DAABA06AC7FC1B61241A12DABD4A733495C7F4D0D4F5C2F94259362488DFFA75`.

SHA-256 of the inspected generated script: `5EA52529AEA520F0450C2542F69924901EC95DA7B9F3DC3FDE5D4A1362BB098B`.

The installed script at `C:/Users/Mehran/AppData/Local/Autodesk/3dsMax/2027 - 64bit/ENU/scripts/AminScatter/AminScatterObject.ms` also contains the reversed manager condition and all ten reversed layer conditions. This disk inspection is not proof of the exact full script image already loaded in Max. The live click sequence independently confirms the visible failure.

The older [0.58 performance guide](../AminScatter/Performance-0.58-guide.md) describes the intended lazy-loading behavior and historical checks. This investigation adds a direct first-click reproduction; it does not rerun or validate those earlier test claims. Source Object and Layer Manager were visually inspected here; exhaustive controls, all layers, other DPI settings and a corrected build remain pending.
