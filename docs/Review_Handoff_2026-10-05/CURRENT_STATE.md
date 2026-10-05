# Current code, tested snapshots and unfinished UI work

## 1. What preceded the latest sidebar request

The earlier 0.7 candidate implemented an opt-in procedural policy (`groupPolicy == 3`) on top of the retained 0.64 display architecture:

- Ordered logical layers and ordered paint sets, with stable ownership and candidate identities.
- Separate within-set, between-set and between-layer spacing. Explicit sibling-pair overrides are independent of the sibling default.
- Source radii, scale-following radius bounds, and CS Edit instance/clone radius overrides.
- Authored-coverage exclusion and spacing between accepted plants, plus separately bounded accepted-target replenishment.
- Cached candidate/prepared stages, deterministic retries, protected authored edits and staged publication of a complete result.
- Manual/Live scheduling, persisted Brush histories, owner lifecycle, statistics and read-only policy-3 MCP inspection.

See the [implementation report](../Procedural_Implementation_0.7_2026-10-04/IMPLEMENTATION.md) for exact behavior and capability gates. These are implementation claims to review, not a substitute for inspecting the code.

The 4 October campaign recorded 13 native suites per SDK, 64 offline MCP tests, isolated Max 2027 procedural/Brush/Edit/persistence/UI tests, live MCP tests and 20k/100k navigation counters. Its generated source SHA-256 was `fb2350bb4f859dbbf4e043f2ee42d94f90084154996a822ca5cc18fc04ea7d29`. The [dated evidence](../Procedural_Implementation_0.7_2026-10-04/evidence.json) and runtime receipts remain unchanged.

Important boundaries: navigation timings were synchronous camera/redraw measurements, not presented-frame FPS. Different hidden baselines prevent claiming a 0.7 speedup over 0.64. The stronger evidence was zero placement/display-buffer rebuilds during navigation. Heavy Proxy drawing remained slow. SDK compilation did not qualify a Max 2026 application.

## 2. Latest artist request

Widening the modifier sidebar left large unused space and sometimes missing-looking sections. The artist wanted Max's native multiple-column behavior. They also asked why radius-spacing changes needed **Apply spacing**.

The previous UI placed general sections and all layers inside one large top-level subrollout. Max could not distribute those inner pages as independent command-panel pages. An inner `height:1` declaration could also be reevaluated on resize after the content had been fitted, clipping the UI.

Apply spacing previously committed the editor's staged rule fields; Update performed calculation in Manual mode. That distinction was unnecessarily surprising for ordinary spacing fields. The current source saves rule edits immediately and still lets Manual/Live decide when to calculate.

## 3. Latest source changes

| Location | Change |
| --- | --- |
| `AminScatter/tools/ui/templates/procedural-ui.ms` | Removed Apply spacing; enable/factor/gap/XY events call `saveRule`. Keeps binding guards and the selected peer during rebinding. Uses normal invalidation; does not force Manual to calculate. Background and selected-radius actions remain explicit buttons. |
| `AminScatter/tools/ui/templates/layers-first-panel.ms` | Stores fitted `contentHeight` rather than reevaluating a literal one-pixel subrollout height. Adds explicit unmount/lifetime guards for static layer slots. |
| `AminScatter/tools/ui/layers-first.cjs` | Generates real top-level plugin pages: main, Update, Surface, Viewport, Layer Manager, and ten layer slots. Keeps per-layer editor factories; removes unused outer/root factories. Initializes owners on page open. |
| `AminScatter/tools/ui/templates/layers-first-host.ms` | Defers binding until Max constructs native pages. Reuses pages on ordinary binding, remounts on structural layer changes, restores section states, and calls the native visibility/order helper. |
| `AminScatter/src/rollout_flow.cpp` | New small SDK helper, `cyrusSetRolloutVisible(hwnd, shown, category)`. The final revision uses `GetCommandPanelRollup`, verifies page/index ownership, sets category, then Show/Hide and UpdateLayout. |
| `AminScatter/CMakeLists.txt` | Adds the new helper to the native Scatter module. |
| `tools/procedural_lab/Max_Procedural_07_UI_*.ms`, `ui_geometry.py` | Private fixture setup, event/lifecycle checks and read-only Qt geometry evidence. |
| Generated script and inventory | Regenerated `AminScatter/scripts/AminScatterObject.ms`; control inventory becomes 217 because Apply spacing was removed. |

The new layout intends to flow **general pages and entire layer pages** between native columns. It does not split a single layer's internal sections into separate columns. The artist should verify whether this granularity meets the request.

The latest generated source hash is recorded in `evidence/generated-check.json`. It passed reproducible generation, delimiter and protected-file checks. This checker is **not** a MAXScript compiler.

## 4. What the latest UI tests actually establish

Intermediate private run: `build/mcp-qualification/procedural07-ui-20261005-e/`. Its loaded Scatter binary was `eabbbeab35453dbbfeae92316b5d1ff9578a19f4f97e563ed4f4a9323885fbbe`.

The copied `evidence/ui-intermediate-acceptance.json` reports:

- Auto-save event-method checks for all four editor scopes.
- Manual publication remains unchanged until Update.
- Undo/Redo and selected-peer preservation.
- Twenty forced layout/open-close cycles retaining controls, with zero generation/preview builds.
- Three deselect/reselect cycles and add/copy/reorder/remove/Undo page-ownership checks.

**Limitations of that receipt:** most controls were exercised by invoking MAXScript event methods. It does not prove pointer interaction, Live debounce, all native column transitions, wheel routing or absence of flicker. The fixture did not assert Qt visibility for unused slots. Its source was loaded from the then-current generated file without retaining an exact script snapshot; do not invent a precise tested-source hash for it or equate it with final HEAD/worktree.

The subsequent read-only Qt inspection, copied as `evidence/ui-intermediate-geometry.json`, found actual native two-column layout, but also **unused layer slots still visible and pages ordered unexpectedly**. General pages existed; some were below the visible area rather than missing from the model. The then-current helper filtered for a Win32 `RollupWindow` ancestor, which is unsuitable for the observed modern Qt host hierarchy.

After that observation, the helper was changed to the documented command-panel interface, page ownership checks and explicit categories. The script now treats helper failure as an error rather than silently ignoring it.

**Final revision status:** Max 2027 native build and all 13 native tests passed. Generated-source checks passed. The final helper and its three-argument script calls have **not** been loaded/tested together in Max. The final helper change has **not** been rebuilt for the 2026 SDK. No final column visibility/order success is claimed.

## 5. Required continuation checks

1. Verify final `GetPanelIndex` / `GetPanelDlg` / `GetPanel` behavior across native columns and hidden pages. Confirm Show/Hide and category ordering actually work; compilation is insufficient.
2. Check all active pages visible exactly once and all unused slots hidden after startup, copy/remove/reorder, Undo/Redo and modifier re-entry. Include multiple controllers and saved scenes.
3. Resize with real pointer input through one, two, three and back to one native columns. Check no clipped content, blank pages, repeated reconstruction or generation. Preserve each layer's expanded sections and selection.
4. Test wheel and blank-background dragging in every column. `rollout_scroll.cpp` was preserved; that does not prove its previous outer-container routing works with the new hierarchy.
5. Test actual spacing spinner/checkbox edits and peer changes in Manual and Live. Check focus, Undo grouping, pending statistics, debounce and publication. Reset inheritance must not select a different pair.
6. Recheck legacy policies, retained Point Cloud/Mesh buffers, Brush feedback, source/radius controls, exact output and MCP inspection with the final UI/native pair.
7. Build both SDKs, verify loaded hashes, package and verify payloads only after the final source qualifies.

## 6. What is preserved or still deliberately limited

The offline checker confirms the current `point_display.cpp`, `preview.cpp`, `rollout_scroll.cpp`, and MCP `models.py` / `contracts.py` match the committed checkpoint after normalizing line endings. Integration behavior still needs testing.

Remaining product boundaries include ten stored populations including child sets, bounded attempts/rounds, static Brush surface correspondence, guarded unsupported Relax/assignment combinations, sibling-scoped outside-coverage composition, no automatic cross-system-unit migration of combined Brush/Edit/radius state, no general dependency graph/disk cache, and no adaptive unlimited point-cloud preview. Policy-3 MCP mutation and ML training/inference are not implemented. These should be evaluated against the roadmap, not described as completed.

## 7. Installation and source pairing

`dist/procedural-0.7-candidate/CyrusScatter-0.7.0-Max2026.mzp` and `CyrusScatter-0.7.0-Max2027.mzp` still contain the earlier tested candidate. They **do not include the latest automatic-spacing/native-column changes**. The demo is also an earlier artifact. Do not overwrite their historical evidence or present them as a build of the current worktree.

The current script requires the new native helper, with its final three-argument signature. Loading it alongside an installed older native binary, or an intermediate two-argument helper, is invalid. Use a fresh isolated Max process with a matching native build; do not hot-replace a loaded DLL or silently modify the artist's profile.

All changes remain local. The new conversation must inspect both tracked and untracked files. Local build paths are not a Git backup.
