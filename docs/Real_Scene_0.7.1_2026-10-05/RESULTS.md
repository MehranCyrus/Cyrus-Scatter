# Real-scene qualification results — 5 October 2026

## Scope and identities

The task used the supplied artist scene as an asset library and built a new editable landscape in an isolated Max 2027 process. Production Scatter source was not changed for this scene task. The existing 0.7.1 UI work remains separate in the working tree. No normal-profile installation, MZP packaging, commit or push was performed during this task.

The qualified Scatter script is `build/ui-071/final01/source/AminScatter/scripts/AminScatterObject.ms`, SHA-256 `07d0bca2efe330b8b632c1a483cea23c65629b0f7ef5c0cbecd2c6984f1f9924`. Product version is 0.7.1 and serialization version is 53. Four matching Scatter/Brush/Edit native modules were used. Surface Analyzer was built separately from current source for Max 2027 and included at startup. All five actual loaded module paths were checked. Full identities are recorded in `evidence/identity.json`.

The initial artist-scene fingerprint was `4c812b3e6cf1519c793075269b7c903463ca333a8548ef7b11bf4832e72dee76`, 185,413,368 bytes. The output scenes reference the supplied assets locally and are not self-contained redistributable packages.

## Asset and scene evidence

- Repaired 387 bitmap references in the copied scene; all required files were found in `Test Scene/maps`.
- Relinked all three Corona `.cgeo` proxies to existing local files. Native mesh snapshots exposed 563,380, 832,240 and 736,931 faces respectively, confirming detailed geometry rather than proxy icons.
- Preserved the supplied Corona plant materials. Renderer identified itself as Corona 15, build timestamp May 25 2026 16:07:51.
- Main receiver: a static 2,867-vertex / 5,520-face mesh with a flat meadow and a curved berm. Shared UV channel 1 supports density-map tests. Units are centimeters.
- Main delivery: five logical layers, eight paint sets/populations, 19 source-node groups, 15 distinct supplied asset geometries, and 10,724 exact published instances.
- The new trail has a 140 cm gravel width plus 6 cm edging on each side. Eight continuous erase strokes have 81 samples each; two continuous flower strokes have 69 samples each. They remain editable Brush documents.

## Runtime assertions

`tools/real_scene_071/campaign.ms` was run again on the completed curved-walk scene. Its checks restore the original publication before completing. The independent Python oracle consumes exported rows rather than the native collision index. Test receipt details and exact pair counts are in `evidence/independent-oracle.json`.

| Capability | Evidence and result |
|---|---|
| Exact output and cached statistics | Warm consumers preserve publication epoch and prepared-build counters. All eight populations have valid output. |
| Source containers | Parking a real grass source reduces the grass output from 8,692 to 5,865 after Update; returning it restores all original rows, IDs and source settings. Manual retains the previous exact output while edits are pending. |
| Brush on curved geometry | A berm erase changes perennial output from 46 to 41; Undo and Redo reproduce both exact publications. |
| New curved walking trail | Saved field/history survives save/reopen. Before the final corridor erase, widening the outer border from 38 to 52 cm changes its flowers from 140 to 192; Undo restores exact output. Disabling the grass erase restores 9,535 grass instances, compared with 8,688 along the clear trail at that stage. The corrected final field is recorded separately in `flower-corridor.json`. |
| Actual pointer painting | Start Brush and Stop were clicked in the floating editor. A viewport mouse drag recorded a two-sample stroke and changed outer-border output from 132 to 264 after Update. Manual preserved prior output; Undo/Redo restored the exact before/after rows. This diagnostic stroke was undone, not saved into the delivery. |
| Saved stroke controls | Disable, radius, strength and softness affect output. Fill resets history and admits coverage; Empty clears it; Undo restores history and exact output. Baseline before trail: 296 flower instances, 216 with a stroke disabled, 239 with it edited, 1,431 with full coverage. The referenced outside-coverage clover becomes zero under full coverage. |
| Manual / Live spacing | Manual preserves the completed publication; Live evaluates the new spacing field. A 5,000 cm self-gap leaves at most one shrub. Restoring the field restores the exact seeded result. |
| Failure publication | Invalid source radius is rejected; publication epoch and previous valid rows survive. Restoring the input recovers normally. |
| Three collision scopes | Independent exhaustive distance checks cover enabled self, sibling-set and layer-pair rules. Finite transforms and unique per-set identities are also checked. |
| Area inclusion/exclusion | Independent geometry checks reject placements on the pavilion/terrace, pool or main entry path, and enforce the lavender ribbons. A separate polyline-distance oracle checks clearance from the new curved walk. |
| Retained display/navigation | Four preview modes, 12 camera steps per mode: no placement rebuilds or new unchanged-buffer uploads after warmup. All six floating-editor pages were visited for every owner without placement invalidation. |
| Render adapter | Native automatic PFlow population equals 10,724 exact instances across 19 source groups, including Corona proxies. Actual Corona images are delivered separately. |
| Bake | All 46 perennial instances preserve source base-object links; worst matrix-row error is below 0.000001. Clearing owned baked output restores the procedural preview. |
| Hide versus disable | Hidden/renamed layers preserve exact output and cache key. Disabled layers contribute no population; enabling restores the seeded result. Tested on the pre-trail scene. |
| Density / clusters / transforms | Black density yields zero; inverted black yields the full 500-candidate budget. 0.5 plants/m² agrees with measured surface area (346). Three source-color clusters and XYZ/projected movement produce the expected changed transforms. |
| CS Edit / radii | Move and clone operations, two selected-instance radius overrides, protected output at zero quota, and save/reopen bindings were exercised in a saved variant. |
| Global / inherited containers | Actual membership and inheritance were asserted in an independent option controller. Scale-following radius was checked with an independent matrix-scale formula for 200 placements. |
| Point / Empty / cleanup | 200 slots versus 105 mesh instances distinguishes Point placeholders. Weighted Empty works in candidate-budget mode; incompatible target mode is rejected. Whole-layer union cleanup was exercised across paint sets. |
| Analyzer / Line modes | Flat-surface Analyzer Area produces 39 placements, Analyzer assignment 206, and Line assignment 44 in saved option variants. Curved Analyzer input is explicitly rejected. |

Mutually exclusive and legacy options were tested in variants, rather than enabled together in a misleading main scene. The table describes tested cases; it does not certify every control combination.

## Performance interpretation

The two final 1,200 × 840 Corona previews completed with an eight-pass limit and eight configured CPU threads: **194.257 seconds** for the overview and **314.942 seconds** for the walking-path detail. Both frames were visually inspected. Native automatic-render error text was empty. These elapsed times include the scripted render call and are specific to this machine/workload.

`evidence/navigation.json` records synchronous camera movement, redraw and message-processing durations in milliseconds. These are **not presented-frame FPS**. The machine was also running the user's original Max session and other applications; this is not an isolated benchmark.

Retained telemetry demonstrates cache/upload reuse. It does not demonstrate zero CPU work: host traversal, input-key checks, display work and message processing still execute. Complex source meshes remain expensive even with instancing, and viewport budgets can cap their displayed population. Exact output and render output are separate from preview caps.

This work does not justify GPU compute or unlimited-FPS claims. Performance next steps should profile the CPU sections and p95 interaction latency with controlled workloads, then account for Brush history size, candidate counts, source topology and memory. Large target values remain bounded: the current evaluator caps candidates per population and has explicit attempt/round limits; it does not guarantee filling a dense or heavily masked region.

## Reproduced limitations and fixture corrections

1. **Strict Brush geometry fingerprint on generated tiny values.** The initial Gaussian terrain included extremely small positive Z values. Save/reopen caused the Brush surface fingerprint guard to reject it, despite no visible geometry difference. Snapping only this generated terrain's heights below 0.001 cm to zero, and collapsing its UV modifier before authoring strokes, produced exact save/reopen passes. No artist geometry or production hash implementation was changed. The evidence supports a precision/canonicalization edge case; it does not prove that every fingerprint mismatch is harmless. See `surface-diagnostic.json` and `terrain-roundtrip.json`.
2. **Analyzer is planar.** The curved receiver is outside its current contract. A flat receiver variant exercises Analyzer behavior without implying curved support.
3. **Line/Analyzer assignment remains on the existing policy.** The new procedural path example uses native Brush coverage, not unsupported procedural Line assignment.
4. **Fill/Empty are resets.** An initial diagnostic incorrectly expected Fill followed by Empty to preserve old strokes. Source inspection confirmed the documented reset behavior; the corrected test uses Undo and passes. This was a fixture assumption, not a production defect.
5. **Direct diagnostic Brush calls require a validated target.** After loading or rebinding, fixtures call `cyrusBrushBind` before `cyrusBrushDab`. The supported Start Brush UI performs its own preparation.
6. **Sparse painted targets can underfill.** A narrow border with a small accepted target and bounded whole-surface candidate pool did not fill that target. The final border uses a declared 40,000-candidate shared budget, with 132/229 accepted plants after its final corridor erase. Attempt factors above 32 were correctly rejected during fixture tuning. No work-limit guard was bypassed.
7. **Startup module identity matters.** Analyzer had to be present in the private startup plugin directory and its script loaded before scene deserialization. Trying to dynamically load the extension into an already incomplete host was not a valid substitute. The final launcher verifies the pinned files and actual loaded paths.
8. **Offset flower strokes need corridor clearance at tight bends.** The independent polyline check found eight flower centers within 90 cm of the path centerline, including three within the 76 cm path-plus-edging width. A final 104 cm centerline erase on both flower fields corrected this scene-design issue. No native Brush behavior was changed.

## Evidence boundaries and next checks

The new landscape, source-container workflow, final publication and native Brush histories were tested in real Max 2027. The fresh-process launcher validates the complete saved scene with matching native modules. Original-input preservation and deliverable hashes are recorded in the delivery manifest.

Not certified here: every renderer, other Max years, every DPI/multimonitor arrangement, large production-scene scaling, arbitrary animated/deforming Brush targets, arbitrary topology edits, network relocation of asset paths, all licensing/payment flows, or MCP write support. Policy-3 MCP mutation and ML capabilities were not added by this scene work. The previous UI qualification is separate evidence, not replaced by this scene test.

The independent oracle checked **7,071,654 collision pairs**. All 10,724 instance identities were unique within their paint sets. The closest plant center was **23.485 cm outside the walk's outer edging**. This checks centers and the declared spacing radii; it does not claim every leaf polygon stays within that footprint.

A separate status diagnostic reproduced a false **Pending** label: immediately after Update all dirty flags are false; after redraw they become true while the publication key still equals the current input key and the epoch is unchanged. This is an unresolved UI status issue, not evidence of a changed planting. See [FINDINGS.md](FINDINGS.md).

The smallest next engineering loop is: correct the false Pending status with a regression test; isolate the tiny-value fingerprint case in a native persistence test; profile the slowest CPU interaction paths on a clean host; then broaden UI gesture, DPI and scene-size tests with a pinned script/DLL build. Preserve the retained-buffer cache behavior and exact-publication checks as acceptance criteria.

## Primary references used

- [Chaos Corona MAXScript interface](https://docs-chaos.atlassian.net/wiki/spaces/CRMAX/pages/124394405/MAXScript): renderer/proxy inspection and automation.
- [Chaos render limits](https://support.chaos.com/hc/en-us/articles/4528499329041-How-to-set-limits-for-rendering-in-Corona-for-3ds-Max): finite render-pass configuration. Delivered image settings and elapsed times are recorded in `render-final.json`; renderer counters returned after rendering were not treated as reliable pass-count measurements.
- Local native source: `AminScatter/src/brush.cpp`, `brush_host.cpp`, and `point_display.cpp`; local MAXScript ownership/evaluation and generated UI source. Source facts, runtime assertions and visual inspection are distinct evidence.
