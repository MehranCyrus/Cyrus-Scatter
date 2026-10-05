# Cyrus Scatter 0.7 — Max validation report

> **Snapshot boundary:** These results cover the generated source and binaries identified in this report. Later 5 October native-column/automatic-spacing work is unfinished and has separate [status and evidence](../Review_Handoff_2026-10-05/CURRENT_STATE.md). This report does not qualify that newer worktree.

4 October 2026. The user authorized computer access after the coding phase. Testing used separate Max 2027 processes and private plugin/configuration directories. The artist's open Max process, scene and installed plugin profile were preserved.

## Outcome

The implemented procedural policy is ready for **artist testing in Max 2027 within the limits below**. Its generated MAXScript loads in a clean process with the matching native binaries. The calculation, Brush, Edit, publication, UI and live MCP fixtures pass after the integration fixes described here.

This is version **0.7.0**, not a production 1.0 release. Max 2026 binaries compile and pass their native suites, but a Max 2026 application is not installed here, so that host and its installer transition remain unqualified. The MZPs were rebuilt and their payload hashes verified; the artist profile was not replaced.

## Fixes found by real Max testing

1. **MAXScript case syntax:** numeric case labels adjacent to `leaf` were parsed as invalid numeric/time literals. The procedural UI generator now emits an explicit separator.
2. **Exception rethrow:** the calculation catch block used an unsupported argument to `throw`. It now uses Max's argumentless rethrow, preserving the original failure.
3. **Definition order and owner scope:** the procedural methods were generated before some layer/group state existed. Early unqualified references could bind to the wrong scope. Persisted declarations now precede their users, methods follow the existing layer helpers, and early injected calls qualify their owner with `this`. Clean-process tests verify ordering, set creation, stable sampling and copy/remapping.
4. **Monitoring output:** the performance monitor emitted MAXScript's `L` suffix on Integer64 counters, making the report invalid JSON. It now serializes those values as ordinary decimal integers without converting them to imprecise floating point.

These are integration/reporting corrections. The retained drawing implementation was preserved. The final generated script is `fb2350bb4f859dbbf4e043f2ee42d94f90084154996a822ca5cc18fc04ea7d29` (SHA-256).

## Executed checks

| Area | Evidence and result |
| --- | --- |
| Native code | 13/13 suites in both SDK builds, including 240 comparisons with an independent exhaustive solver; the runtime fixes did not change these native inputs. |
| Offline MCP | 64 passing tests, including the policy-3 inspection contract and legacy-mutation guard. |
| Generated script | Reproducible output, 218 inventoried controls, successful clean Max 2027 load. An inventory is not a claim that every control was manually clicked. |
| Ordering and three spacing scopes | Independent self, sibling-set and inter-layer distances checked on actual accepted centres. Reordering changes the ordinary winner. Explicitly disabling a pair restores its population. |
| Radii | Source radius follows final source scale; per-instance overrides and protected zero-quota clones exercised. Native tests additionally cover nonuniform, mirrored and sheared transforms. |
| Brush and backgrounds | Planar ray/dab tests cover Paint/Erase, Undo/Redo, soft coverage, whole-field references, disabled/hidden references, outside coverage, between-plants spacing and their combination. Bounded refill reached 2,000 accepted plants in each of two sets in the fixture. |
| Actual pointer input | A mouse stroke on a nonuniformly scaled sphere changed one-stroke coverage to two strokes. Manual mode held 123 plants before Update; Update produced 378. Undo restored 123; Redo restored the placement/source fingerprint. |
| Area and stable candidates | Include/exclude rectangles filtered correctly. Surviving candidate IDs and full transforms stayed identical when increasing the candidate count. |
| Copy/remove | Copied a layer with Base reordered after its child; rules and background IDs remapped, paint documents remained independent, Remove/Undo/Redo restored the expected owners and rules. |
| Manual/Live/error recovery | Manual froze the previous publication until Update; Live published changes. Invalid input retained the preceding cache and epoch and recovered when corrected. |
| Edit lifecycle | Source/receiver replacement rejected incompatible bindings. Undo restored the original placement/source fingerprint. A later-owner failure retained the previous publication and selected Edit IDs. Stale radius overrides were rejected after an Edit reset plus seed change; explicit clearing recovered. |
| Persistence | Curved painted scene saved and reopened with preserved history/results. A topology change was rejected without deleting paint; restoring the topology recovered it. |
| Native UI | Mouse-wheel scrolling and Apply spacing worked. Twenty layer/rule rollout close/open cycles retained control handles and caused zero placement or display rebuilds. This is not a high-speed video measurement of flicker. |
| Live MCP | All nine existing campaign programs passed, plus new policy-3 inspection. Queries retained scene state, exported ordered rules and source IDs, and distinguished pending settings from the last published epoch. |

The nine live campaign programs are qualification, schema-2 layers, fault/cancellation scenarios, stdio, capability boundaries, retained preview, inspection, budgets and layer inspection. Policy 3 is **read-only over MCP**; this is not a new mutation schema or an ML implementation.

## Navigation and the 0.64 comparison

Both builds used a 2,000 × 2,000 unit plane, one 32-triangle source, the same camera path, 1,302 × 750 viewport, shaded display, five points per plant, and sufficient display budgets to show every Mesh instance. The new sampler intentionally produces different random placements. The 0.7 case also exercised a full Brush field. Tests used 90 steps per mode at 20,000 plants and 60 at 100,000.

**The strongest result is work reuse:** across all measured navigation modes, neither build rebuilt its display cache or republished/uploaded retained buffers. Policy 3 also performed zero prepared-placement rebuilds, zero controller publications and zero monitored Brush preparation/filter work during navigation. Mesh telemetry confirmed all 20,000 / 100,000 instances were displayed.

The table contains median **synchronous camera + `completeRedraw` + posted-message processing**, in milliseconds. These are not presented-frame GPU measurements or a promise of interactive FPS.

| Population | Build | Scatter hidden | Point Cloud | Proxy | Mesh | Centres |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 20,000 | Frozen 0.64 | 48.56 | 47.24 | 87.23 | 46.42 | — |
| 20,000 | Procedural 0.7 | 17.87 | 18.47 | 63.64 | 19.20 | 17.93 |
| 100,000 | Frozen 0.64 | 47.30 | 46.63 | 2,188.86 | 34.88 | — |
| 100,000 | Procedural 0.7 | 17.88 | 20.02 | 2,253.29 | 18.87 | 16.12 |

The hidden baselines differ substantially between processes, and the machine was shared with other open applications. Therefore these numbers **do not establish that 0.7 is faster than 0.64**. The counter evidence supports preserving retained navigation behavior. Proxy's large cost occurs in both builds and remains a separate drawing-path limitation. At 100,000 displayed proxies, the trials included long stalls (up to roughly 21 seconds in 0.7 and 42 seconds in 0.64). Do not raise Proxy's display limit to those values expecting Mesh-like performance.

For 0.7 at 100,000 plants, Mesh P50/P95/P99 were **18.87 / 29.41 / 71.25 ms**. Point Cloud was **20.02 / 41.22 / 61.27 ms**. All raw steps and percentile summaries are retained in [navigation-summary.json](evidence/runtime/navigation-summary.json) and its adjacent raw files. P95/P99 use nearest-rank percentiles; 60–90 samples provide limited tail precision.

Initial Update took about **411 ms at 20,000** and **729 ms at 100,000** in the recorded 0.7 trials, versus 61 / 116 ms for the simpler old-policy trials. This is a functionality/cost comparison, not identical solver work: the new path performs additional identity, Brush, rule and publication work. These are single-run observations, not established update-time percentiles. Process peak working sets were approximately 2.62–2.70 GB for the already-used 0.7 test process and 2.49–2.53 GB for the baseline process. These are whole-process lifetime peaks, **not isolated scatter allocation measurements**.

## Verified limitations and supported recovery

**System-unit conversion:** Max can rescale scene geometry when loading into different system units. Stored Brush anchors/radii and Edit/radius metadata are not yet migrated together. The existing surface guard rejects the rescaled painted receiver and preserves history. Reopening with **Adopt the file's units** (`useFileUnits:true` in the fixture) restores the original painted result. Keep saved scene units for 0.7 testing. This behavior is independently reproduced in [units-acceptance.json](evidence/runtime/units-acceptance.json). Autodesk documents the load behavior in [File Loading and Saving](https://help.autodesk.com/cloudhelp/2022/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/File-Access/3ds-Max-Scene-Files-Access/GUID-624D3D05-B15D-4A97-9F15-DA35CDB0DDD2.html).

**Heavy Proxy:** lower the displayed instance limit or use retained Mesh/Point Cloud/centres. Retained proxy rendering should be a measured follow-up; the current procedural change does not solve immediate-mode drawing cost.

**Scope:** static Brush receivers, sibling-only coverage composition, bounded accepted-target search, existing policy capability gates, read-only policy-3 MCP and no ML remain as documented in [IMPLEMENTATION.md](IMPLEMENTATION.md). Arbitrary production foliage, renderer combinations, every device/driver, every UI option and Max 2026 runtime have not been exhaustively qualified.

## Next engineering gates

1. Artist acceptance on copies of real projects in Max 2027, retaining the saved system units.
2. Max 2026 host load/Brush/Edit/save/reopen and installation tests on a machine with that application installed.
3. An isolated retained-Proxy experiment with the same visual output and display budget; measure buffer reuse, submission cost and presented-frame timing.
4. Coordinated unit migration for Brush, Edit bindings and world-distance metadata, with uniform-rescale, Undo, merge and reopen tests. Do not partially scale just the Brush radius.
5. Broader real-asset/update-memory qualification before raising work limits or enabling new assignment adapters. A future MCP mutation schema must explicitly represent procedural rules and cannot reuse schemas 1/2 to overwrite them.

## Evidence and local artifacts

[Runtime summary and hashes](evidence/runtime/summary.json), [complete build/package evidence](evidence.json), and [reproduction instructions](VALIDATION.md) identify the tested code and modules. Private raw logs and disposable scenes remain under `build/mcp-qualification/procedural07-runtime-b/`; the frozen comparison lives in `procedural07-baseline-064/`. No auth/connection secrets were copied to the documentation evidence.

The candidate folder also contains `CyrusScatter-0.7-Example-Max2027.max`, created by `Max_Procedural_07_Demo.ms`. It demonstrates an earlier Trees layer and a Flowers and Grass layer with separate red/blue painted sets, sibling spacing and outside-coverage background grass. The example uses Manual update and retained Mesh; crowded painted sets deliberately report bounded target shortfall. The separate 0.7 test window is left open on this example for artist inspection. The frozen 0.64 comparison process was closed.

The source and docs remain local working-tree changes. No Git commit/push was performed in this validation pass, and unrelated licensing work was preserved.
