# Unresolved questions and controlled experiments

These experiments are proposed acceptance work, not executions performed by this assessment. No Max session, artist scene, installation or computer-use tool was used here. Future host campaigns should use bounded synthetic fixtures in an explicitly permitted private environment, without altering the artist profile. Preserve the prior recorded campaigns and collect new evidence under a new candidate identity.

## Questions the available evidence cannot answer

| Question | Current boundary | Smallest useful next evidence |
| --- | --- | --- |
| Why is tyFlow's UI faster in the reported experience? | No matched interaction timing. Qt rollouts and selected layouts are documented/observed, but private creation/rebinding policy is unknown. | Measure the specific interaction in comparable visible UI conditions. Public profiling and author documentation can describe behavior; they cannot recover private control ownership. Do not speculate beyond observed callbacks/layouts. |
| What spatial structures, allocators, channel storage and publication algorithm does tyFlow use? | SDK headers expose queries, not engine source. Selected float3 accessors are too narrow to characterize the whole engine. | Author-published implementation or an explicitly bounded new binary investigation, outside this assessment's current scope. Cyrus optimization does not depend on resolving this. |
| How much did the latest time-validity fixes improve presented playback? | Matching correctness receipts; no current FPS comparison or artist-session identity. | E0/E3/E4, with loaded identities, identical workloads and presented-frame timing. |
| What causes the reported dropdown delay? | Broad binds/lists exist; dropdown open/cancel was not measured. | E2 separates opening, selection, binding, layout and redraw. |
| Does same-topic retarget edit the preceding owner at runtime? | High-confidence source trace F1; no interactive reproduction. | E1 with distinct source lists and section-reference/writeback checks. |
| Are real node notifications and newly entering animated container sources handled? | Some classifier fixtures bypass delayed delivery; clock dependencies primarily track registered inputs. | E3 and E9 with actual callbacks enabled and elapsed message processing. |
| Is latest Proxy still the dominant drawing cost? | Immediate submission verified; poor historical timings from an older candidate. | E4's current staged timing, bounded counts and exact visual workload. |
| Does retained matching work with actually unrealized groups and device recovery? | Contract supports culling-aware matching; preserved fixture state was fully realized. | E6/E7 with visible state checks, not only off-screen positions. |
| What does Corona stop result 2 mean here? | Exact renderer/session identity and primary return-value contract unknown. | E5, inspect matching public interface/version and controlled lifecycle states. |
| Is memory bounded at process peak and is the current thread cap optimal? | Buffer/work limits exist; overlap/SDK/GPU/process peaks and contention remain unmeasured. | E8 plus draw replacement measurements, not a reservation-counter claim. |
| Is Max 2026/DPI/lifecycle/Brush-Edit compatibility ready? | SDK builds and targeted older fixtures; no complete latest host qualification. | E10/E11 on exact candidates and synthetic/retained compatibility fixtures. |

## Common protocol — E0: candidate and workload identity

Before interpreting a trial, capture the Git HEAD plus dirty/untracked source manifest, full generated script SHA, script payload marker, loaded native module paths/SHA, Max version, renderer version if involved, hardware, display/backend, viewport size/DPI, material/light/shadow settings and visible instances/triangles/points. A caption or an installer filename is insufficient. Reading a build receipt does not establish what an active artist session loaded.

Use one synthetic fixture and publication seed per paired comparison. Record raw samples and counter deltas. Warm up control creation and visible GPU realization separately from measured warm trials. Include a hidden/empty baseline within the same process; older different-process hidden baselines must not be subtracted as interchangeable constants. Randomize mode order, repeat at least three bounded trials, and retain failures/outliers. Use median and p95; report p99 only with enough samples and its sample count. Capture sampling/recording overhead separately.

Counters: validity queries, geometry captures, prepared candidates, solves, publications/epoch, preview preparation, buffer upload count/bytes, draw/submission, UI create/bind/list/layout/writeback, renderer transport and stop/start, pending timers, failures/drops. Add only the missing bounded instrumentation; do not print full placements every frame.

Use host presented-frame information or an independently qualified presentation trace for FPS when available. If only synchronous camera/redraw duration is available, report exactly that metric. Its inverse is not established presented FPS. Stage CPU time, GPU time, wall time and presentation intervals must have distinct names and collection methods. Counter stability proves reuse of monitored stages, not zero frame cost.

## Benchmark matrix

| Axis | Required comparisons | Main inference |
| --- | --- | --- |
| Evaluation mode | Disabled, Manual, Live | Disabled removes drawing as well as evaluation. Manual tests publication freeze; Live adds dependency response. |
| Animation | Static; unrelated animated node; animated receiver/source/parent/map/setting | Distinguishes false invalidation from necessary changes. Conservative foreign controllers are allowed to invalidate. |
| UI | Closed; selected-layer Modify; popup; both | Separates binding/layout/notification effects from calculation and drawing. Current source lacks the proposed integrated view, so mark that cell unavailable until R2. |
| Display | Mesh, Proxy, Point Cloud | Separates geometry/instancing/submission workload. Match semantic display budgets and state actual primitive counts. |
| Activity | Settled idle; fixed camera navigation; one specified edit; fixed timeline playback; IR | Different actions legitimately activate different stages. Compare like actions. |

Do not run a huge Cartesian product before learning anything. Start with static/unrelated playback in all three evaluation modes and display modes, UI closed and IR off. Then change one factor: real dependencies, each UI state, specified edits, and finally IR. Keep identical fixed frame/camera paths. Start heavy Proxy trials at bounded counts and stop on a declared stall/time budget; do not expose a host to unlimited high-count redraw.

## E1 — Owner routing and shared-view lifecycle

**Fixture:** Two logical layers A/B with distinct sources, values and paint-set lists; a second Scatter root C. Open A on Assets, then select previously unvisited B so both use topic 1. Record every active section's root/owner/obj, selected set, visible source list and model values before/after.

**Cases:** Same-topic A→B, B→A, A→C; remembered topic on both owners; all built topics; set changes; close/reopen; Undo/Redo; delete selected layer while root survives; delete root; clone root; load/reset synthetic scene. After R2, repeat with Modify and popup simultaneously open and with scene-source selection changing Modify context.

**Measures/pass:** References and values always match each view's chosen owner. A bounded scalar/source edit alters only that owner, one Undo step restores it, and the other view refreshes the affected fields without recursive writes. Browsing causes zero solve/publication/bridge-build/unchanged-upload deltas. Same-context topic clicks do not bind again. This directly tests F1; switching topics or pressing Refresh to hide stale references is a failure.

**Limit:** Headless control/reference checks can establish write destinations; they cannot establish visible layout, scrolling or interaction latency.

## E2 — Cold/warm UI latency and scaling

**Fixture:** Static unchanged scatter; 1, 32 and 1,024 registered source rows, within existing supported owner/population limits. Use distinct names/group memberships to prevent trivial identical-list shortcuts.

**Actions:** Measure script/startup loading, first Modify mount, first popup/topic creation, warm reopen, same/different owner, topic switch, expansion, dropdown open/cancel, actual selection, resize and scrolling separately. Do not use a selected-item event to stand in for list-open latency.

**Measures/pass:** UI create/bind/list/layout counts, main-thread duration and visible response, model-write/Undo counts, validity/geometry/solve/publication/upload deltas. Warm unchanged browsing must leave computational stages and authored data unchanged. Provisional UX targets are R3's 100 ms warm p95 and 250 ms cold p95 on a recorded reference system; report actual distributions and scale dependence. Recorder off/on comparisons establish overhead. No additional idle polling remains after controls settle.

**Limit:** A large list may incur necessary host drawing cost even if model binding is perfect. Native Qt/C++ migration is considered only after the slow stage and a limited alternative are measured.

## E3 — Live reuse and actual dependency delivery

**Fixture:** Use existing synthetic playback shapes and identified modules. Preserve isolated classifier tests but add a separate campaign with real NodeEventCallback delivery enabled. Pump messages for the configured delayed/coalesced callback interval, with a bounded deadline and explicit pending-state checks.

**Actions:** Static/unrelated timeline; two-key receiver/source and parent transforms; real geometry/topology edits; density-map edits/animation; settings animation; Brush/Edit inputs; Analyzer input edit and failure; Manual/disabled/hidden states; rewind; Undo/Redo. Include a script/list/constraint controller that conservatively changes validity; do not demand a false FOREVER interval.

**Measures/pass:** Unrelated playback: prepared/solve/publication/upload counts remain unchanged after warm-up, no blanket per-frame geometry capture, timers settle. Real dependent changes: expected placement/transform/producer revision changes; no missed update. Manual retains completed publication until explicit Update. Analyzer failure stops retries and reports error. Measure actual frame times separately; caching assertions alone do not quantify FPS.

**Limit:** Callback classification invoked directly cannot qualify real scheduling. Conservative one-tick validity may correctly cause work; document its input type instead of labeling it a regression.

## E4 — Current viewport costs and retained Proxy feasibility

**Fixture:** Same source, count, seed, publication, viewport/camera path and visual settings across Mesh/Proxy/Point Cloud. Start at 1k and 20k; increase only within a declared time/memory limit. Record actual source/proxy triangles and visible points because mode names alone do not define equal draw workload.

**Measures:** Hidden/disabled baseline, synchronous submission/redraw, presented frame distribution where supported, dependency checks, generation/preparation, uploads, GPU drawing where a qualified collector exists, UI and IR activity. Use IR off initially. Measure steady state and generation replacement separately, including process/system/GPU peak where available.

**Pass/decision:** Establish which stage accounts for the excess. If Proxy submission dominates with stable caches, R4's small retained pilot must preserve visual output and reduce that stage without bad tails, excess memory or lifecycle failures. If renderer work or materials dominate, a Proxy storage rewrite has not answered the problem.

**Limit:** Zero uploads still permits substantial drawing. Disabled being faster does not diagnose broken caching. A flat retained preview shader is not a production-render material parity test.

## E5 — Corona contract and lifecycle isolation

**Fixture:** A permitted private synthetic renderer scene with identified renderer/Max/candidate versions. Inspect the installed public renderer interface methods and version-specific primary documentation. Capture bounded phase/result events without logging scene geometry.

**Actions:** IR inactive/active, docked/floating modes, one real input change versus no change, repeated coalesced changes, explicit stop, synthetic save/open/reset and production render entry/exit. Track request identity and reentry while stop/start pumps messages. Bound each trial and keep the error/pending state visible.

**Pass:** No perpetual restart/check timer or stale bridge. A failed stop does not trigger an unsafe rebuild/start. No redundant stop/build/start for an unchanged published key. Completed transport counts/material/source mapping agree. State meanings and result-code treatment are supported by the matching contract; retain U where they are not.

**Limit:** Do not map result 2 to success by guess, suppress exceptions as a fix, or qualify a different installed script by its line number. This assessment did not execute renderer actions.

## E6 — Genuine partial culling and retained matching

**Fixture:** Multiple retained groups with one initially visible and another off-frustum before its first realization. Check actual per-group readiness/submission, not only position. The preserved off-screen fixture reported fully realized state and is not this test.

**Actions/measures:** Submit, settle, navigate while some groups are genuinely unrealized, then reveal them. Record identities, matching/fallback result, pending release timer, generation and per-group upload deltas where available.

**Pass:** An enabled, submitted, nonfailed matching generation stays valid without requiring every group to be realized. No fallback/release loop while off-screen. Revealing a previously unrealized group may perform its necessary first upload once; unchanged visible redraws do not upload again. Coarse bounds must enclose data correctly.

**Limit:** Group-level bounds can provide coarser culling than per-instance items. Measure that draw tradeoff before adding spatial groups or per-instance items.

## E7 — Supported graphics-resource recovery

**Fixture/actions:** Use a supported viewport/backend/device-resource transition in the private host environment; do not induce unsupported driver crashes. Include multi-viewport and close/reopen lifecycle. Record backend/version and whether SDK resources actually changed.

**Pass:** Retained geometry/points recover visibly without stale resources, dangling controller references or endless mismatch timers. Resource recreation may legitimately upload unchanged data once after loss. Placements and authored model remain unchanged; graphics failure uses a bounded fallback/error path. Old generation/resource memory is released after replacement.

**Limit:** Keeping a system buffer is insufficient evidence. If the transition never invalidates resources, report the device-loss case untested rather than passed.

## E8 — Solver worst cases, determinism and memory

**Fixture:** Fixed seeds and stable IDs; concentrated candidates, disparate radii, planar/spatial scopes, sibling/layer conflicts, protected later Edit rows, cleanup/refill shortfalls and largest supported admission. Use bounded native tests before expensive host trials.

**Measures:** Neighbor visits, rounds, grid/blocker allocation and temporary peak, stage times, shortfall/failure reason; participants 1/2/4 and supported explicit limits. Include controller-recipe/key construction and host capture separately so native solve is not blamed for unrelated time.

**Pass:** Ordered accepted IDs/transforms/reasons are deterministic across execution choices. All current population/sample/attempt/round/neighbor limits hold; failures expose no partial completed publication. Refill and future protected reservations preserve semantics. Measured process/GPU replacement peak is reported separately from accounted buffers.

**Limit:** Do not parallelize greedy acceptance or retain upstream results after a protected later change without proving equivalence. A hierarchy/pool/GPU experiment requires a measured hot kernel and comparison to simpler reuse/reservation first.

## E9 — Container registration versus animated entry

**Fixture:** A source container with a known static rectangle; one registered model with an animated parent and one initially unregistered model outside the rectangle that animates inside. Use actual node callbacks and timeline delivery.

**Pass:** Define the intended registration/parking contract first, then verify event/time classification, source identities and per-source settings without scanning the scene every idle frame. Registered animated inputs update correctly; initial entry either registers at the documented trigger or is explicitly an authored/manual action. Preserve parked settings and bounded subtree/fallback behavior.

**Limit:** The current dependency stamp fixture for registered sources does not establish the initially unregistered-entry behavior. Do not add blanket scene polling to cover an undefined product contract.

## E10 — Existing BR-01 identity compatibility

**Fixture:** Retained old authored Brush/Edit identity data with signed zero, subnormal and ordinary coordinate representations; exact mesh vertex and face data. Compare relevant serialization/load round trips before designing a compatibility fix.

**Pass:** Valid old authored data remains usable where topology is actually identical; genuine geometry/topology changes remain rejected. A migration or normalized identity representation is introduced only with exact comparisons, version/compatibility evidence and rollback-safe behavior. No broad disabling of identity validation.

**Limit:** This is an existing release gate in Live NEXT_WORK, not evidence that tyFlow's private identity system has been understood. Do not open artist scenes or alter their stored data as part of this assessment.

## E11 — Host/UI qualification gate

**Fixture/actions:** Exact private candidates in Max 2027 and 2026, supported DPI scales and command-panel widths; native rollout reorder/scroll/resize; all inventoried feature families; popup/Modify lifetime combinations from E1; clone/delete/load/reset/Undo; independent production/IR cases from E5.

**Pass:** No clipped/unreachable controls, stale ownership, duplicate writes, orphan dialogs/tool modes/timers or changed saved owner identities. Host-owned rollout lifecycle remains correct. Scene save/load reconstruction and Manual semantics pass. Record each unsupported/unexecuted cell explicitly.

**Limit:** Passing SDK compilation and a headless control inventory is valuable but cannot qualify visual behavior, another running Max version or production renderer integration.
