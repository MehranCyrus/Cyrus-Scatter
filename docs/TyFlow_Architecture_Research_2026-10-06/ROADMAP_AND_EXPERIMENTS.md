# Prioritized implementation loops and experiments

6 October 2026. These are recommendations for the next coding task; no production fixes were made in this research. They extend the [existing assessment roadmap](../TyFlow_CyrusScatter_Assessment_2026-10-06/ROADMAP.md) with the new static UI/display evidence.

## Loop 1: correct editing identity before optimizing the view

**Evidence:** P1 in [Comparison](CYRUS_COMPARISON.md), with exact template/generated behavior. A same-topic skip currently suppresses binding after owner change.

**Work:** Separate page creation from context binding. Retarget root/layer/set references on every actual identity change; keep same-context repeats cheap. Add a focused regression that proves which owner a real field writes. Preserve existing lazy topics, scene IDs, serializer and Undo behavior.

**Acceptance:** Across two roots and two layers each, all already built topics show/edit the intended owner. Repeated same-owner selection does not rebuild sections. Browsing/retarget/expansion leaves input parameters, candidate fingerprints, completed publication epoch and retained uploads unchanged. Delete/reset/Undo/Redo cancel tools and discard stale context safely.

This is the smallest correctness change and should precede a new UI package or large migration.

## Loop 2: make causal diagnostics available inside Scatter

**Evidence:** The bounded native recorder and passive script hooks already exist. tyFlow separately exposes simulation, upload and reset-cause diagnostics; its documentation warns that printing detailed logs adds overhead and should be disabled outside investigation. [Debugging](https://docs.tyflow.com/tyflow_objects/tyFlow/debugging/).

**Work:** Add compact Start/Stop/Save controls and active duration/event/drop state in Scatter. Keep exports explicit. Use existing events and counters first. Add only missing timing/cause fields needed to answer UI, callback, preparation, solve, publication, upload, bridge and IR questions. Distinguish a notification received from a dependency invalidated and a job actually run.

**Acceptance:** Disabled recording creates no recurring timer, log-file writes or solve/redraw requests. Enabled recording obeys configured bounds, reports dropped/evicted data and stops at its duration limit. Reading/saving the log does not update the scene. Exports include script/native identities, units, controller IDs and clear missing-data indicators. Engineer sessions remain `training_eligible: false` unless a separate explicit dataset workflow permits otherwise.

Keep renderer result/error details bounded and correlate causes with publication epochs. Avoid copying artist geometry, texture pixels or whole scene paths into every event. This is an engineering tool, not a permanent telemetry database.

## Loop 3: qualify idle, playback, culling and Corona on the exact candidate

**Evidence:** Current playback receipts establish many counter/output invariants but not presented FPS, all queued notification delivery, partial realization, interactive UI or the reported Corona stop exception.

**Work:** Use a disposable profile and copied scenes once interactive testing is authorized in the next task. Record source/module hashes before loading. First reproduce the user's cases with current candidate bytes, then compare Manual/Live/disabled. Run bounded real notification and renderer tests, using the recorder to identify causes.

**Acceptance:** Static unrelated animation causes no new prepare/solve/publication/unchanged-buffer uploads after settling. Relevant animated receiver, source, parent, setting or map changes do update correctly. Manual remains frozen until Update. Quiet open UI performs no placement work; lightweight host callbacks and actual drawing are expected. Corona IR settles without repeated scene resets or an uncaught stop callback exception. Fully/partly culled items return to view correctly without perpetual re-publication; device recovery either succeeds or reports a bounded fallback/failure.

Do not suppress all notifications to make counters pass: that can hide real changes. The original preservation instruction still excludes the artist scene/profile from private tests.

## Loop 4: build the integrated selected-layer view with a measured pilot

**Evidence:** Selected tyFlow Qt paths retain construction, rebind parameters, classify effects and explicitly manage rollups. Current Scatter section binding can refresh a broad active set; its dropdown latency is not measured.

**Work:** Use the [proposed layout](UI_AND_BINDING.md), one selected-layer context and separate global controls. Pilot a native Qt/Max rollout widget against current scripted fields, preserving the same model and solver. Keep an optional Edit layer popup as another view over that model. Use scoped signal guards, stable-ID list models and targeted changed-field updates.

**Acceptance:** Cold construction, warm retarget, dropdown open, expansion, resizing/scrolling and value commits have separate traces. Fields preserve scope, Undo, animation and save/reopen. Wider command-panel columns preserve visibility/order/scroll state; no empty or duplicate pages appear. Opening a dropdown or the optional popup does not change solver/publication/upload counters. Two open views synchronize the correct owner without duplicate mutations or evaluation. Normal artist actions stay clear without exposing implementation details.

Set latency budgets from the measured baseline on the recorded machine and fixed fixtures; report p50/p95 and worst case. A practical pilot goal is visibly improved warm interactions with no correctness regression, not an unqualified universal millisecond/FPS promise. If the SDK bridge cannot preserve current scripted parameter behavior, solve that narrow boundary before porting all sections.

## Loop 5: reduce measured draw or compute cost

**Evidence:** Proxy still calls `gw->triangle` per face/redraw; retained Mesh/Point Cloud already avoid unchanged reinitialization. Workers launch/join per numeric job. tyFlow's complete private GPU/pool implementation is unknown.

**Work order:** First profile Proxy CPU submission and retained draw cost. Prototype retained proxy source shapes/instances only if submission is material. Then profile actual changed-input computation, source copying, script/native array conversion and thread-launch cost. Optimize the dominant path with the smallest change. Consider a persistent pool only for demonstrated repeated-job overhead; consider GPU computation only for a parallel numeric stage with a favorable transfer/residency budget.

**Acceptance:** Same placements/transforms/material/visibility/bounds/picking and deterministic collision winners; bounded memory and failure fallback; unchanged navigation performs no new preparation or uploads. Changed inputs, Manual/Live and render/exact output agree. A speed claim includes count/source complexity, viewport/renderer, machine, warm/cold state, distributions and memory. Every improvement preserves the measured 0.63/0.64 baselines or records a justified tradeoff.

## Controlled experiment matrix

| ID | Fixture / action | Measure | Pass or useful conclusion |
| --- | --- | --- | --- |
| E1 | Warm popup retarget, same topic, distinct owners/sources | Bound owner IDs, field reads/writes, Undo and mutation counters | The selected owner alone changes; exposes F1 directly. |
| E2 | Open/close/search dropdown with 10 / 100 / 1,000 registered source rows | UI construction/bind/model/layout time and native crossings | Locates UI cost without attributing it to simulation. Equal list guards must not prevent a new identity from binding. |
| E3 | Open integrated view, optional popup or neither; quiet 60 seconds | Callback/bind/timer counts, thread CPU samples, prepare/solve/epoch/upload counters | No placement/display reconstruction caused by a settled view. Compare bounded recorder off/on overhead. |
| E4 | Static scatter plus unrelated animated car; Manual / Live / disabled | Same viewport/camera/shading, presented frame times, thread CPU, counters | Distinguishes calculation regressions from drawing overhead; disabled removes drawing as well as engine work. |
| E5 | Animate receiver/source/parent/count/map and rewind | Output/transform digest, relevant validity queries, classified notification causes | Correct changes and deterministic return; no stale-result optimization. Include an unkeyed script controller. |
| E6 | Real queued node/map/Undo events at same time and during playback | Delivery count, invalidation cause, one completed transaction | Coalescing works with actual message-loop delivery. A direct classifier call alone is insufficient. |
| E7 | Point/Mesh fully visible, partly culled, wholly culled, visible again | Submitted generation, per-item realization/uploads, bounds and image | Correct recovery and no repeated upload/publication loop; distinguish culled from fully realized headless state. |
| E8 | 3k / 20k / 100k plants, same source complexity; Point / Proxy / Mesh | CPU preparation, draw submission, upload bytes/time, presented frame distribution, RSS/VRAM | Finds Proxy submission or GPU draw bottleneck independently of placement caching. Respect admission limits. |
| E9 | Changed-input numeric jobs at 1 / 2 / 4 participants | Job size, thread launch/wait, computation, bridge copies, deterministic digest | Pool/thread changes only if measurements justify them; stop at oversubscription or diminishing returns. |
| E10 | Tight dense spacing, infeasible accepted target, largest radii, cleanup/refill | Candidate/neighbor visits, rounds, shortfall, peak working memory | All bounds enforced with honest statistics and previous-publication retention on failure. |
| E11 | Corona production render versus IR, then real edit/UI browse/stop | Renderer transitions/results, build signature/epoch, invalidation causes, errors | IR does not repeatedly reset for unchanged inputs; reported stop error is either reproduced/explained or left open with exact identity. |
| E12 | Save/reset/reopen/merge/delete with both views/tools previously active | Registry/context identities, listener lifetime, source catalog settings | No leaked listeners or stale owner; parked source data survives return; no scenes/profiles overwritten. |

Use an identical camera and redraw workload for paired comparisons; randomize test order or repeat A/B/A to detect cache/thermal differences. Record first-build versus settled behavior. Compare counters only after settling and include dropped-log health. Avoid using synchronous `redrawViews()` duration as presented FPS or inferring total CPU from a single timer.

## Data required in a performance receipt

Record exact source/payload/native hashes, loaded module paths, Max/renderer versions, hardware/display settings, units, layer/set/source counts, triangles and display mode, seeds, limits, generation/output digests, workload actions, warm/cold state and recording configuration. Distinguish UI binding time, SDK input acquisition, candidate work, collision/cleanup/refill, publication, source/transform copies, render-item preparation, realization/upload, submission/draw and renderer bridge transitions. Capture memory residency separately from bounded reservation counters.

The native recorder can correlate phases/causes; host profiling supplies call-stack/thread and presented-frame evidence. No current log alone gives every timing or GPU measurement listed here.

## Further binary investigation only where it changes a decision

1. Follow the custom render-item implementation assigned at submit RVA `0x01ddf130`: map its Realize/Display lifetime and ownership to the SDK, then inspect buffer dirty/upload gates.
2. Inspect smaller helpers from simulation dispatch RVA `0x03f80b70` only for a specific measured question such as thread launch or source-mesh duplication. Preserve the known timeout boundary.
3. Decode one PB parameter's user label and full effect path if deciding how to classify a comparable Scatter option. Do not guess UI semantics from a numeric parameter ID.
4. Benchmark a matched observable static display workload before asserting a cross-product performance advantage. tyFlow's particle history/solvers and Scatter's deterministic plant rules are different requirements.

Do not adopt a new graph framework, native rewrite, worker pool or GPU solver simply because vendor imports suggest one. Keep the existing stable calculation/publication boundaries and simplify the measured problem.
