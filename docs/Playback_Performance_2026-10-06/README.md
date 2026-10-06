# Playback invalidation and idle-work fixes

6 October 2026. This is a new local development candidate on `codex/floating-layer-editor-0.7.1`, based on `147e3f524aa3f4cd9db9bb2bffb7350f9f78de31`. Version remains **0.7.1**, serialization **53**. It is not the existing installed/package snapshot. No computer-use tools, artist scene, artist-profile installation, commit or push were used in this pass.

## What changed

1. **Unrelated animation stops invalidating Scatter.** The old time callback marked every Live layer dirty and requested a full redraw; candidate, group, blocker and transport keys also included the clock unconditionally. The replacement checks cached validity intervals for registered Scatter owners and enabled leaves. Static inputs have no time component. Genuine receiver, parent, source-geometry, parameter and density animation still invalidates its dependent result. Manual does no timeline validity queries or publication.
2. **Time validity is an explicit dependency.** The native query reads owned parameter controllers and explicit geometry/transform/map dependencies. An ordinary unanimated stock PRS can report a one-tick node-TM interval, so a narrowly identified stock controller graph is proven constant. Script, constraint, list and foreign controllers retain SDK validity; an unkeyed controller is not automatically constant. Each interval is intersected independently. There are no retained C++ scene references or mesh copies in this query.
3. **Density edits remain reliable without frame-driven rebuilding.** In-place texture notifications and revision keys now cover policies 1/2 as well as 3. Only an active density map is watched; a missing affected map cannot invalidate unrelated owners. Manual edits stay pending until Update.
4. **Retained Point Cloud matching respects deferred realization.** Matching requires a matching, enabled, nonfailed generation submitted to Nitrous, as Mesh already did. It no longer requires every point group's GPU resource to be realized. Buffer construction, reuse, memory limits, synchronization and explicit failure fallback are unchanged. Autodesk documents that culled items may never receive `Realize()` calls. This is a source/API correction; the headless off-screen-position fixture does not establish every frustum/device-loss case. [SDK contract](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_custom_render_item.html)
5. **Surface Analyzer stops recurring idle polling.** Its 250 ms timer is a one-shot queue, armed by relevant edits or expired input validity. Actual parent changes are included. Manual and settled inputs do not restart the timer; failure reports an error and waits for a real correction. Scatter consumes Analyzer's published revision, preserving the Analyzer's own Manual behavior.
6. **Unchanged editor selections do less UI work.** Current layer/set/topic selections do not rebind fields. Unchanged dropdown contents, selection and setup labels are retained. This is a small improvement to the existing optional/floating editor, not the integrated-column redesign. Its script compiles in the private host; interactive latency and layout are not qualified here.

The native bounded recorder can record `time.invalidated` for a genuine interval expiry. Recording remains default-off. Direct recorder controls in Scatter are still pending. The render-key reader uses published time/revision values and does not install density watchers, query native validity or evaluate a recipe.

## Evidence

See [results and exact boundaries](RESULTS.md), [source/build/runtime receipts](evidence/), and [next tasks](NEXT_WORK.md).

- Final private headless Max 2027 campaign: **1,312 assertions passed** on the recorded matching script/five-DLL set.
- Both SDK 2026 and SDK 2027: **14 Scatter native suites + 1 Analyzer suite passed per SDK**.
- Fresh Python/MCP/report-parser campaign: **137 tests passed**.
- Generator/integration checks retain **241 inventoried controls**, unchanged preview construction and closed MCP schemas. The retained implementation check permits only the documented matching-predicate change.

Source navigation: [validity query](../../AminScatter/src/input_validity.cpp), [generated lifecycle](../../AminScatter/tools/ui/input-time.cjs), [lifecycle template](../../AminScatter/tools/ui/templates/input-time.ms), [point matching](../../AminScatter/src/point_display.cpp#L295), [Analyzer scheduling](../../CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms#L443), [UI selection guards](../../AminScatter/tools/ui/templates/layer-editor.ms), [headless fixture](../../tools/procedural_lab/Max_Playback_Regression.ms).

## Boundaries that still matter

Timeline notifications and viewport drawing have some ordinary dispatch/drawing cost. Cached meshes still cost something to draw. These changes do not promise zero Max CPU or a particular presented FPS. The fixtures use small synthetic assets, not the artist's 2,940-plant scene or imported courtyard models.

Interactive playback/FPS, dropdown latency, DPI, full/partial frustum culling, device reset, Max 2026 runtime and Corona IR remain unqualified for this candidate. Existing Brush/Edit/container runtime receipts remain evidence for their dated builds; not every feature combination was repeated here. Conservative foreign-controller validity may still require frame evaluation. Undo/Redo retains the existing conservative refresh behavior.

The integrated Modify-panel layout, direct diagnostics buttons, reported `Corona IR stop failed: 2`, Brush BR-01, expanded policy-3 writes, ML and commercial licensing are not completed by this slice. MCP schemas/gates and licensing code are unchanged. Existing MZPs were not overwritten. **Do not load this script against an older DLL; it requires the matching new validity primitive.**

## Repeat without computer use

Run from the repository in separate private output directories:

```powershell
python tools/procedural_lab/check_generated.py
python tools/procedural_lab/offline_build.py --year 2027 --output build/playback-20261006/max2027
python tools/procedural_lab/offline_build.py --project analyzer --year 2027 --output build/playback-20261006/analyzer-max2027
python tools/procedural_lab/test_playback.py --binary-dir build/playback-20261006/max2027 --analyzer-dir build/playback-20261006/analyzer-max2027 --output build/playback-20261006/new-unique-run
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q
```

The runner rejects changed source/binary receipts, uses a unique disposable scene/profile configuration, and verifies actual loaded DLL paths/hashes plus script payload identity. Its artist-INI check is specific to that file; it is not a promise about every third-party cache file created by Max. It never sends commands to the artist's running Max.
