# Test plan and decision gates

This is the full qualification contract. The initial implementation has evidence for parts of these rows; see the [per-ID results and control inventory](../results/0.1.0-2026-10-10/FEATURE_STATUS.md). Checkboxes below remain unchecked until the entire row is qualified. Initial timings are in the [dated report](../results/0.1.0-2026-10-10/README.md). Report unsupported cases as N/A with a reason, never as passes.

## Qualification levels

1. Native unit/oracle tests establish math, storage and deterministic behavior.
2. Scripted tests in owned Max profiles establish host execution, callbacks, serialization and counters.
3. Presented-frame measurements establish actual viewport timing only when a reliable presentation signal is available.
4. The artist tries all four tools and judges control, clarity and feel. Automated replay cannot replace that step.

No computer-use automation. Do not reset or load files in the artist's running session. Record package/source/loaded-module hashes, Max build, compiler flags, CPU/GPU/RAM, units, viewport mode, candidate count and fixture hashes for every run. A caption is not identity evidence. Do not launch heavy trials concurrently or let compilation compete with timing.

## Accuracy and shared fixtures

Use a 10 m square plane with two triangles and the same plane at approximately 100k and 1m triangles. Also use a sloped terrain, rotated wall, sphere, two stacked receivers, a thin double-sided shell and a connected folded sheet. Include unequal triangles, degenerate faces and a documented non-manifold fixture. Save deterministic recipes and traces so scene binaries are not the sole reproduction record.

Start with a 1 mm boundary-error target on the 10 m plane and brush radii 20 mm, 200 mm and 2 m. Also measure 2 mm and 5 mm accuracy tiers; do not compare a 5 mm raster against a 1 mm vector result without saying so. Features narrower than the selected tolerance are a separate limitation test, not a reason to ignore ordinary lost regions. Report maximum border error, area difference and false inclusion/exclusion outside the uncertainty band. Derived outline error and canonical query error are separate columns.

Independent analytic disks/capsules and manually specified polygon fixtures provide oracles. For hard chronological painting, a deliberately slow independent evaluator resolves operations at fixed points. Do not use the current Cyrus preview or one candidate's output as truth. Use exhaustive small-domain sampling plus targeted boundary points. For curved geodesic footprints use simple known cases (sphere arc, unfolded adjacent faces) and a separate high-accuracy reference; ordinary Euclidean capsules are not their oracle.

Freeze query candidates and deterministic random thresholds. Test 10k, 100k and 1m queries separately from the number displayed. Same replay trace, ordering, coordinate frame, geometry and tolerance apply to every comparable run. Events at 30/60/120/240 Hz derived from the same path should produce equivalent results within tolerance. A radius calibration test must settle diameter versus radius and system-unit conversion first.

## Test register

Every implementation run fills a result per method: PASS, FAIL, N/A or NOT RUN; evidence path; numeric values; limitation. The checkboxes mean the test has evidence, not that it passed.

| ID | Experiment | Acceptance / purpose | Evidence captured? |
| --- | --- | --- | --- |
| I01 | Start/Stop, click, drag, miss, re-entry; 4 sampling rates | Correct size; swept coverage; no gap bridges; no event-rate accumulation | [ ] |
| I02 | Escape, close, owner deletion, selection change, repeated start | Cancel or commit as specified; no stale callbacks, stuck Painter or changed global preferences | [ ] |
| H01 | Add, overlap, erase hole, repaint, disjoint islands | Correct ordered hard coverage; repeated paint is idempotent | [ ] |
| H02 | Expanding letters/scribble matching the reported failure | Earlier areas never disappear; enlarge until old preview's effective budget is exceeded | [ ] |
| H03 | Same footprint, 1/10/100/1k/10k gestures | Separate history growth from final spatial complexity | [ ] |
| H04 | Same gesture count, increasing path length and painted area | Separate coverage growth from history count | [ ] |
| H05 | Thousands of islands, sawtooth borders, narrow holes, repeated cuts | Polygon/index/tile worst cases; error and complexity costs | [ ] |
| H06 | Small and huge radii, variable radius mid-drag, very long gesture | No truncation, unexplained removal or retroactive radius edits | [ ] |
| S01 | Soft repeats, stroke overlap and erase, event-rate changes | Common formula; no accidental extra opacity per input event | [ ] |
| S02 | Inner/outer boundary fade, holes and exclusions | Distance semantics explicit; outside candidates considered; exclude wins | [ ] |
| G01 | Coarse/dense equivalent planes and seam crossings | Small brush independent of artist mesh density; bounded error | [ ] |
| G02 | Slope, wall, sphere, back side and connected folds | Declared projection/surface behavior; leakage quantified; unsupported domain explicit | [ ] |
| G03 | Scale, nonuniform/mirrored transforms, large origin, mm/cm/m units | Radius calibration, stable local attachment and numerical range | [ ] |
| G04 | Deform unchanged topology; swap/reorder faces at same face count | Correct invalidation; no false reuse based solely on count | [ ] |
| R01 | 1/2/20/21 receivers; reorder, remove and restore | Stable region ownership; unchanged receivers reused; missing target inactive | [ ] |
| R02 | Named regions; Include/Exclude overlap; duplicate receiver | Correct identity; no doubled candidates; no hidden ownership switch | [ ] |
| U01 | Undo/Redo per gesture, cancel, clear, save/reopen, clone | State/query equivalence; separate document identity; no orphan callbacks | [ ] |
| V01 | Outline/fill/points independently enabled and combined | Resolved border agrees with coverage; toggles do not change authored state | [ ] |
| V02 | Orbit/pan/zoom and idle; unrelated node/animation changes | Zero paint rebuilds and unchanged-buffer uploads for static data | [ ] |
| V03 | Manual pending/Update and Live; append edit during pending work | Correct visible revision/status; no stale successor publication | [ ] |
| B01 | Memory/work limit, cancellation, allocation/worker failure injection | Atomic failure; prior complete state retained; no silent omissions | [ ] |
| P01 | Cold prepare, warm edit, mouse-up completion, query and display costs | Separated measurements, tails and cache counters | [ ] |
| P02 | Plateau after repeated edits/clear; save size; load rebuild | No leak/unbounded derived-cache growth; authoritative history cost visible | [ ] |
| A01 | All four artist trials with normal mouse and useful plant samples | Artist reports latency, border trust, control and workflow friction | [ ] |

The initial [control inventory](../results/0.1.0-2026-10-10/FEATURE_STATUS.md#window-control-inventory) maps every exposed control to these IDs and distinguishes underlying API tests from physical mouse interaction. Continue qualification from that inventory.

## Metrics and provisional targets

The following are **design targets for this workstation, not current results or promises**. Calibrate them after the host spike, record any revision before ranking methods, and keep the same target for comparable trials.

| Metric | Initial target / reporting rule |
| --- | --- |
| Pointer callback CPU | p95 <= 8 ms on the representative terrain fixture; report geometry/hit work separately |
| Callback-to-ready feedback | p95 <= 33 ms, p99 <= 100 ms; includes queued/coalesced work and extraction |
| Mouse-up to completed preview | p95 <= 150 ms for the representative fixture; report worst case on stress fixtures |
| Input-to-presented pixels | Measure separately if instrumentation supports it; otherwise explicitly UNMEASURED |
| Correctness | No lost committed component; no wrong hard query outside declared approximation band |
| Warm 100k coverage queries | Report median/p95 and index preparation separately; provisional target <= 50 ms |
| Memory | Initial 512 MiB owned-paint budget for representative fixtures, counting active state, Undo, indexes and publication overlap; report process memory separately |
| Idle/orbit | No paint evaluation or unchanged-data upload; record draw CPU/GPU cost independently |

Use at least five cold runs and ten warm repetitions after two warmups. Capture per-event samples during long gestures; enough events must exist for meaningful percentiles. Report median, p95, p99, maximum, dropped/coalesced inputs and cancellation latency. Small sample sets must not advertise precise tail estimates. Include total elapsed wall time and allocated bytes, not only a favorable kernel timer.

Counters: geometry snapshots, spatial-index builds/reuses, touched faces/tiles/segments, candidate evaluations, contour vertices, display chunks rebuilt, uploaded bytes, complete/pending revisions, queue depth, limited/rejected edits and Undo bytes. Warm reuse claims require counter evidence; identical output alone is insufficient. Instrumentation overhead gets a measured baseline.

The 512 MiB target is an experiment budget, not permission to drop paint or Undo silently. If the next atomic edit cannot fit, reject/cancel it visibly or offer an explicit user action. Measure the failure point and retained state. Do not distort the test by retaining only a convenient subset of history.

## Decision process

First apply correctness, data retention, lifecycle and domain gates. A fast failing method cannot win. Then compare p95 interaction, worst cases, accuracy, memory, implementation complexity and artist feedback for each supported domain. No blended score may hide missing curved-surface support or different soft semantics.

Possible outcomes: one method wins; one terrain and one freeform method are justified; a candidate needs another focused trial; or none is ready. A hybrid is a new proposal with explicit conversion/ownership costs, not an automatic fallback. Record why the rejected methods lost and what evidence might change that conclusion. Only then propose Cyrus integration.

## Result format for the implementation phase

Create one run manifest plus CSV/JSON event measurements and a short summary with columns: method, fixture, domain, semantics, accuracy, state size, touched work, prepare/edit/query/boundary/upload timings, tail timings, maximum queue depth, failures, and evidence links. Store local images/scenes/raw logs under ignored lab output; retain small reviewed summaries and reproduction commands in Git. Never check off a runtime row from code inspection alone.
