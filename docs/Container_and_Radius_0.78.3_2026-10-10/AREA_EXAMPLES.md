# Include/Exclude, spline width and point-radius inspection

11 October 2026. Max 2026, unchanged Scatter 0.78.3 at `46374194c5dba42d643425e3810390b8ddb3f903`, Analyzer 0.14. Tests and documentation only; no product edits, installer changes or Git push. This supplements the [point-only check](SPLINE_POINTS.md).

## Scene to inspect

[Open the saved scene](../../build/vector-brush-078/include-exclude-visible2026-01/Include_Exclude_Point_Examples.max). The owned Max 2026 window remains open with example 14 selected. The user's original edited three-guide example remains at the origin; the 25 numbered cases are arranged to its right. Each has a separate native Max layer named `CSQA_XX ...`, a Scatter controller, hidden receiver and visible guide/label. Select the named Scatter controller to inspect its settings. All model sources in these 25 cases are Point placeholders; there are no plant or bush sources. Receivers are required sampling geometry.

There are **15,905 displayed points** across the 25 cases. Each starts with 2,400 candidates, so masks and spacing intentionally reduce the visible count. This is not accepted-target refill mode. Some cases show collision-radius rings as well as the point marker.

- [Overview](../../build/vector-brush-078/include-exclude-visible2026-01/Area_Examples_Overview.png)
- [Example 14: bands clipped by Exclude](../../build/vector-brush-078/include-exclude-visible2026-01/Area_Example_14_Closeup.png)
- [Original edited scene backup](../../build/vector-brush-078/point-examples-visible2026-01/Before_Include_Exclude_Check.max)
- [Raw evidence and identity receipt](AREA_EXAMPLES_EVIDENCE.json)

The scene and images are ignored local files, not Git backups. The original Max process and normal profiles were preserved. The separate audit host loads the matching Scatter and Analyzer modules. Images came from MAXScript's viewport capture; no computer use or mouse/keyboard injection was used.

## What explained the reported rectangle

The inspected rectangle had uniform node scale **0.384104**, a world footprint of approximately **461 × 307 mm**, and an **outside band width of 1,401.32 mm**. The active saved band width, not the small rectangle dimensions, explained the large rounded field.

Band Width is absolute world-space distance from the transformed spline. Scaling the spline does not scale this separate setting. Outside corners round because distance is measured to the nearest border segment. A 200 mm band is distinct from an Analyzer line's 200 mm **full width**, and from a source's 200 mm **collision radius**. The tests found no scale/distance calculation error in the covered cases.

Include/Exclude UI has an avoidable ambiguity: adding a shape defaults to Include and does not select its row. Changing the radio with no selected row does not change any stored Area. Highlight the row first, then choose its mode; the row prefix is the stored mode. This can explain a visible Include row beside an Exclude radio, but the earlier screenshot alone does not prove that sequence. The UI behavior is recorded for improvement.

## Numbered comparisons

| Case | Inspect | Points |
| --- | --- | ---: |
| 01 | Inside width 200 mm | 234 |
| 02 | Outside width 200 mm | 258 |
| 03 | Spline scaled to 40%, width remains 200 mm | 137 |
| 04 | Nonuniform scale and rotation, width 200 mm | 296 |
| 05 | Object offset and rotation, width 200 mm | 335 |
| 06 | Two consecutive 200 mm inside bands, separate groups | 596 |
| 07 | Include only | 568 |
| 08 | Exclude only | 1,841 |
| 09 | Overlapping Includes form a union | 646 |
| 10 | Exclude overrides Include | 684 |
| 11 | Scaled, rotated and offset Include | 271 |
| 12 | Concave L-shaped Include with an Exclude | 554 |
| 13 | Closed shape with an inner hole | 908 |
| 14 | Inside/outside bands cut by a diagonal Exclude | 537 |
| 15 | Include: delete 100 mm, then scale over 300 mm | 867 |
| 16 | Density curve over 400 mm | 696 |
| 17 | Band scale 0.5–1.5 and 40 mm source radius | 805 |
| 18 | Radius 80 mm + radius 80 mm + gap 20 mm spacing | 116 |
| 19 | Analyzer line, 600 mm full width, flat ends | 273 |
| 20 | Same line, round ends | 362 |
| 21 | Analyzer point discs, 250 mm radius | 206 |
| 22 | Line/point union with 200 mm street offset | 410 |
| 23 | Curved Include, circle radius 800 mm | 547 |
| 24 | Analyzer boundary: delete 150 mm, scale over 300 mm | 1,935 |
| 25 | Exclude: delete 100 mm outward, scale over 300 mm | 1,823 |

Green guides indicate Include, red guides Exclude and yellow guides spline bands. Blue circles in Analyzer cases show the 250 mm point-mask radius. Orange source-radius rings in scale/spacing examples are a separate setting.

## Covered checks

- [x] 79 initial geometric/assignment assertions across cases 01–18, using independent Python polygon parity and Euclidean distance calculations against all original candidate IDs. Checks include false positives, false negatives, position/source preservation and displayed counts.
- [x] Uniform/nonuniform scale, rotation and object-offset transforms; cumulative band widths; Include union, Exclude priority, concavity and holes.
- [x] Add Point and Color groups assignment through generated callbacks; inside/outside bands, min/max scale, source radius, Follow Scale on/off and radius-based spacing. Minimum spacing in case 18 is at least 180 mm.
- [x] Area add, duplicate prevention, selection binding, Include/Exclude complement, removal keeping the scene spline and relinking restoring results. Remove was separately rechecked after completing panel mounting.
- [x] Area delete/scale/density effects, separate graph data, sampled custom graph storage and inward/outward falloff. The analytic circle check allows 2 mm for native spline tessellation.
- [x] Real Analyzer line/point union, line caps, full-width versus radius semantics, street offset, boundary falloff and unlink/relink behavior.
- [x] Manual falloff edits wait; explicit Refresh areas applies them; Live applies the relevant width change.
- [x] **25/25 exact placement fingerprints match after the final save/reopen in a separate request.** Final scene has zero preview errors and zero scene-node model sources.
- [x] Five unchanged evaluations/redraws across all 25 cases add **zero publication epochs and zero receiver candidate builds**. This is cache evidence, not an upload or FPS measurement.
- [ ] Physical picker/modal Select From Scene operation, graph-handle dragging, rapid physical owner switching, complete Undo/Redo and arbitrary DPI remain artist checks. The mode Undo returned to Include when run in a subsequent completed request; inline Undo/Redo inside a Python/Max hold did not qualify normal gestures.
- [ ] Direct Source objects assignment of Point placeholders remains B12; these examples use Color groups. This run does not test every option in the entire plugin or certify heavy-scene rendering.

## Measurements and diagnostic iterations

Recorded synchronous Update calls range from 87.10 to 456.61 ms across different cases. They are single observations in a growing, active scene, not repeatable medians for identical workloads or presented FPS. Per-case timings and the final counts are in the receipt; some timings precede the final count snapshot. No performance regression or speedup is claimed from these samples.

The chronological trace retains **170 passing and three failing assertions**, rather than erasing the failed attempts:

1. The first rapid Python view-switch Remove check failed. A separately mounted generated panel removed the link, retained the spline, returned all 2,400 candidates and restored the original 568 on relinking. The fixture now completes the panel mount before invoking Remove. Physical rapid switching remains unqualified.
2. The original Analyzer scale test supplied only two samples. `ensureFallCurves` expands fewer than five samples, so the resulting curve was not the linear ramp assumed by the oracle. Five linearly spaced samples pass the exact distance check. No production calculation changed.
3. An initial inline save/reopen check found the street-linked Analyzer stale after fixture edits. After an explicit Analyze, event drain and a completed save request, the independent reopen check passed for all 25 cases. A general save/reopen defect was not established.

Other fixture corrections included placing the street 30 mm outside the boundary instead of coincident with it (coincident edges do not identify a street-facing side), valid MAXScript expression scope/curve syntax, recovery-script path anchoring and scalar cache-counter comparisons instead of Max array identity comparisons. Raw failed-attempt receipts remain in the owned run directory. None are silently relabeled as product passes.

## Reproduction

Use the [owned-host workflow](../../tools/vector_brush_078/README.md). Load matching Max 2026 Scatter 0.78.3 modules, Analyzer 0.14 DLL and script before opening the copied point scene. The actual host is `include-exclude-visible2026-01`; loaded paths, hashes, source HEAD and artifact hashes are in the receipt. The normal Max 2026 profile hash remained unchanged.

Run `area_examples.ms`, `area_examples_extra.ms`, `area_examples_prepare.ms`, then `area_examples_verify.ms`, sequentially through `request.py`. These fixtures append cases; do not rerun them on the same populated scene. They use `area_examples_helpers.ms` and the corresponding Python files. The Python work runs on the Max thread through the private test transport, not the public MCP write API. Requests may take several minutes; inspect completion before submitting another after a timeout.

The actual campaign continued from saved checkpoints while correcting fixtures, rather than rerunning the entire corrected campaign from a blank scene. Final fingerprints, geometric recovery checks, native identities and scene contents were verified. Keep that distinction when reusing the fixture as a regression gate.
