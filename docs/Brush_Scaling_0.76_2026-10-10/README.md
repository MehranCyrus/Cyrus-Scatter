# Brush preparation and 0.76 qualification — 10 October 2026

Baseline: pushed checkpoint `40c750e` on `codex/workflow-0.75`. Scatter is now **0.76 / package 0.76.0**; saved schema **54** and calculation model **CyrusUnified1** are unchanged. Analyzer remains the matched **0.14** implementation from the courtyard fixes. MCP remains **0.73.0 / closed plan 0.73**; only its help catalog's product version changed. No new remote authoring authority was added.

## Completed changes

- [x] Aggregate preparation limits: at most **1,000,000 derived dabs** and **8,000,000 dab-to-face links per Brush document**, including reused strokes. Authored sample count is also checked before preparation.
- [x] Resampling and connected-patch growth reject work before exceeding the count limit. There is no approximate coverage, silent truncation or deletion of authored paint.
- [x] Contiguous, exact-size face lookup replaces separately growing per-face link lists. Stroke and dab order are preserved.
- [x] Ordinary host reads no longer copy the entire authored document before field preparation. An active, uncommitted gesture still needs a combined snapshot.
- [x] Resampling no longer copies all original samples only to clear them immediately.
- [x] The 0.76 UI captions, CMake/package version, generated manifest, help catalog and current documentation agree.

The previous immutable field survives a failed successor. At the Scatter boundary, the existing complete placements, epoch and preview survive. Over-budget authored history stays available for Undo/recovery. These are **per-document count limits**, not a total-memory cap: scene geometry, old/new fields, derived vector capacity, authored documents, Undo, feedback and multiple Paint Areas have additional costs. B04 remains partly open for whole-scene/peak-memory and physical input-to-feedback qualification.

## Measurements

Same CPU workload and compiler settings, five repetitions, 20,000 connected faces, spatially distributed soft paint and erase. Append reuses the prior immutable field. Timings exclude viewport feedback, publication and Undo storage.

| Strokes | Full preparation, 0.75 → 0.76 median | Append preparation, 0.75 → 0.76 median |
| ---: | ---: | ---: |
| 100 | 0.837 → 0.717 ms | 0.236 → 0.106 ms |
| 1,000 | 8.406 → 6.504 ms | 1.800 → 0.237 ms |
| 3,000 | 24.568 → 19.246 ms | **5.040 → 0.749 ms** |

The 3,000-stroke append case is about **6.7× faster**. Maximum difference from full ordered replay was `1.11e-16`. These short CPU timings are evidence for this preparation step, not a promise of equivalent end-to-end brush speed. [Before](evidence/before.csv), [after](evidence/after.csv), [benchmark source](../../tools/brush_lab/scaling_benchmark.cpp).

The Max history fixture authored 1,000 soft paint/erase gestures, then explicitly updated 1,000 candidate plants. It accepted 594 plants in **51.23 ms** for that Update. Unchanged reads reused the field/publication; opaque erase, Manual pending state, Undo/Redo and save/reopen retained the expected result. This does not measure physical tablet/mouse input or continuous tint feedback.

The production-limit fixture used an 80,000-face receiver. One hundred broad dabs produced exactly 8,000,000 links and succeeded. The next dab failed with a specific face-link error; existing placements, epoch and preview cache remained identical. All 101 authored strokes remained stored. Removing the extra stroke recovered the exact result; Undo/Redo rechecked the limit and recovered correctly.

### Courtyard regression

The original **53,520-placement, ten-layer** courtyard retained all ten position/model fingerprints. That fingerprint does not independently prove full matrix/ID equality. Equal shown counts, triangle budgets, camera and viewport were used for the following synchronous navigation measurements:

| Mode | 0.76 median synchronous redraw |
| --- | ---: |
| Box Proxy | 114.0 ms |
| Sphere Proxy | 107.2 ms |
| Pyramid Proxy | 111.2 ms |
| Mesh | 113.7 ms |
| Points | 116.1 ms |

Preparation, publication and retained upload/resource counters stayed unchanged during navigation. These are **not presented FPS**. Differences from the preceding 0.75 retained-Proxy run are within a range where session variation matters; no additional drawing improvement is claimed from this Brush change.

Cold Update was **17.24 seconds**, warm forced Update **3.54 seconds**. The cold cost remains substantial and is not solved by this batch. Compare the [previous phase measurements](../Courtyard_Fixes_0.75_2026-10-10/README.md) before conflating preparation with Max's first redraw.

## Qualification and reproduction

The [results](RESULTS.json) and [campaign](evidence/campaign.json) record the final checks. Use an owned redirected Max 2027 profile; never execute reset-scene fixtures in an artist session.

- Release SDK build and all **14 Scatter native tests**; the Brush executable includes **35,580 assertions** covering accelerated/reference picking, curved and disconnected geometry, mixed opacity/erase, nonuniform/sheared/reflected metrics, incremental histories, limits and failure recovery. These assertions overlap the native-test coverage and are not additional tests in that total.
- Generated UI, approved layout and help-catalog checks; **141 Python tests**.
- **15 focused Max Brush assertions**, plus core publication, plane/sphere Paint Areas, Proxy/Analyzer, Manual/Live, spacing, source containers, Relax, Edit persistence and exact output/PFlow/bake/failure regressions.
- **942 full Scatter/Analyzer playback assertions** and a Corona production geometry smoke: 100 plants, Sphere Proxy selected, 320×240, one pass, 1,504 ms, publication preserved and no bridge error. The inspected image shows the source cones; lighting is overexposed. This checks geometry/output lifecycle, not material fidelity or sustained IR.

The first mixed-sequence run failed the Analyzer clean-layer assertion; a subsequent inspection showed current guides and a clean layer, and an instrumented repeat remained stable. The fixture now pumps the delayed initial notification sequence before taking its steady-state baseline. That is a test precondition correction, not a product scheduling change or proof that every mixed-sequence issue is resolved. The failure and observation are retained in [initial campaign](evidence/campaign-initial.json), [state](evidence/analyzer-failure-state.json) and [repeat](evidence/analyzer-observed.txt). A second stop caught a hardcoded 0.75 fixture assertion; only its expected version changed. [That run](evidence/campaign-version-fixture.json) is retained too. The initial catalog version mismatch was corrected in its generator and the checks rerun.

Run the normal [build/test workflow](../AGENT_WORKFLOW.md). Load `Max_Layer_Regions_074.ms` and [Max_Brush_076.ms](../../tools/procedural_lab/Max_Brush_076.ms), then call `B76History()` and `B76Limit()`. Enable `AMIN_BUILD_BRUSH_BENCHMARK` for the standalone native benchmark. The copied [campaign](scripts/run.py), [resume](scripts/resume2.py), [launcher](scripts/launch.py) and [benchmark](scripts/benchmark.py) drivers record this machine's exact local paths; adapt owned build/output paths for another checkout. The benchmark driver takes label, library path and an optional matching include directory. The before measurement linked the frozen 0.75 native library with its then-current matching header; use that checkpoint's headers when reproducing, since the native Field signature changed in 0.76. Original scenes and plant assets remain local and ignored by Git.

## Delivery and remaining work

Install the matching pair, then restart Max:

- [Cyrus Scatter 0.76.0 — Max 2027](../../dist/Brush_Scaling_0.76_2026-10-10/Max2027/CyrusScatter-0.76.0-Max2027.mzp)
- [Cyrus Surface Analyzer 0.14 — Max 2027](../../dist/Brush_Scaling_0.76_2026-10-10/Max2027/CyrusSurfaceAnalyzer-0.14-Max2027.mzp)

[PACKAGE.json](PACKAGE.json) pins the runtime-tested payloads. Archive verification is separate from installer execution; these packages were not installed in the artist profile. The Analyzer payload is unchanged from the prior matched candidate. An old guide without saved freshness still needs one explicit Analyze. No scene/schema migration is introduced by the Brush optimization.

[Final delivery checks](evidence/protection.json) verified the source/package hashes, 121 local documentation links and the unchanged original courtyard file. Only the verified owned Max process was stopped. Website and the unrelated landing-page design were left unchanged. Installers, scenes and build outputs remain ignored local artifacts; Git carries source, docs and selected qualification evidence.

Keep [B01/B02/B04/B11 and artist/release gates](../BACKLOG.md) open: mixed display sequences, receiver-local stability, whole-scene Brush memory/latency and cold viewport realization need separate evidence. Physical pointer/tablet/DPI, sustained renderer/device sessions and Max 2026 runtime remain unqualified. This is a tested development candidate, not a claim that the entire product is perfect.
