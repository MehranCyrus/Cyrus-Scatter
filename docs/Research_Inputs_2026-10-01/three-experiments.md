# Three architecture-discriminating experiments

**Status: specifications, not measured runs.** See the main report and Sources.md for evidence boundaries and references.


These are specifications for the local engineer, **not completed experiments**. Select only the branches justified by the preceding measurement.

### E01 — Where does one artist action actually spend time?

**Question:** is the remaining problem repeated work, scheduling, pure computation, drawing, or the host/renderer? Can coalescing and narrow reuse solve it without another execution architecture?

**Input:** one small scene, one representative production scene, and a stress scene chosen to expose many controllers/layers or an existing memory threshold. Keep assets/seed/build fixed. Include an unchanged camera orbit, one display-only change, one density change, one source-transform change, a small manual edit, a geometry/topology edit and one render/IR transition. Test Manual and live-update modes separately. A camera-dependent feature, if enabled, is a distinct condition.

**Baseline/control:** verify loaded native and script build identities, not only files on disk. Save exact scene hashes/settings and final ordered output. Run the current unmodified workflow. Diagnostic controls may freeze a known-correct result or disable one subsystem to attribute cost, but must be labeled ablations—not shipping speedup comparisons. If redundant work is observed, change only coalescing or a single cache validity path in an isolated branch.

**Measurements:** event receipt, scheduled start, extraction/preparation, numerical stages, script/native conversion, commit, redraw invocation, presentation correlation, render preparation; per-revision call counts and invalidation reasons; CPU thread time and wall time; peak private commit/resident memory, plugin cache bytes and GPU memory. Record what remains unobservable rather than substituting another metric.

**Correctness oracle:** exact committed instance/ID/source/transform output against an explicit fresh rebuild; invalidation dependency checks; correct Manual behavior; selection state and loaded-scene persistence. For scheduling changes, add rapid alternating edits, Undo/Redo, node deletion, reset/load and canceled render. A retained stale result must never be marked current. Validate first, then time without intrusive checks.

**Raw output:** `run_manifest.json`, `events.csv`, `stage_spans.csv`, `output_hashes.json`, profiler trace paths, viewport presentation CSV, memory samples, fallback/cancel records, scripts/input trace and source diff. Suggested span columns: run_id, event_id, owner_id, revision, time_sample, stage, thread_id, start_ns, end_ns, item_count, bytes, cause, result.

**Decision/stop:** if no-op/display interactions already avoid calculation, reject a generation-cache rewrite as their fix. If scheduling dominates, test coalescing before async. If host extraction dominates, stop numerical offload proposals until extraction is addressed. If draw/queue time dominates, proceed to E02. A mutation missed by caching rejects that candidate regardless of timing. Proposed responsiveness goal: acknowledge ordinary input within 50 ms and cached actions within 100 ms at p95 on the declared scene/hardware; these are design targets, not guaranteed platform limits.

### E02 — CPU batches, retained expanded geometry, or shared viewport instances?

**Question:** which display representation gives the best navigation, update cost, memory and compatibility for the actual workload?

**Input:** freeze a correct placement result so all variants draw the same transforms/IDs. Sweep displayed population through small, production and stress ranges, including just below/above every actual cache cap. Cross that with few repeated sources versus many unique sources, simple proxies versus detailed meshes, and one versus many controllers. Add material diversity, UV overrides, mirrored/nonuniform transforms, selected instances, a deforming source, and a changed instance count. Run Standard/HQ and multiple viewports in supported hosts. Test a 32 GB machine and the target GPU; test another vendor before making a cross-vendor claim.

**Variants:** A current correct CPU batch path; B minimal retained expanded chunks; C shared geometry with SDK viewport instances. B and C are isolated prototypes only. Do not build both fully if an earlier controlled result rejects one. Keep displayed geometry, coloring, visibility, viewport dimensions and quality equal. Run separate explicitly degraded-preview tests only after like-for-like tests.

**Measurements:** stable-scene frame/present intervals; CPU submission and preparation, GPU timeline if supported; initial build, warm orbit, one-instance transform edit, population change, source deformation/topology and material change; bounds/picking latency; peak and steady CPU/VRAM; resource counts before/after deletion/reset; multi-generation/cap fallback behavior. Plot cost against both instance count and source/group count—one axis is insufficient.

**Correctness oracle:** canonical drawn geometry/transform/color/channel data where accessible, independent hit-test selections and conservative bounds, deterministic fallback populations, and saved screenshots under fixed camera/lighting. Geometric equality is not necessarily pixel identity under a changed shader/driver path; investigate visible differences rather than letting broad image tolerances hide wrong normals/mapping. Final-render placements must be unchanged.

**Raw output:** manifest and variant feature flags, frozen input/result hashes, per-frame CSV, source/group/batch counts, CPU/VRAM allocation timeline, redraw and update timings, comparison captures, selection/bounds assertions, device/driver details and failures.

**Decision/stop:** use D03's proposed margin or a pre-agreed absolute frame-budget goal. Reject invisible HQ output, changed selection IDs, unbounded resources, silent degraded quality or cap-triggered population loss. Keep A if it meets target budgets and B/C do not earn their maintenance cost. Keep a specialized fast path plus fallback when only a clear eligibility subset wins. Do not extrapolate a six-layer proxy demo to detailed materials or render performance.

### E03 — Exact algorithm improvement, bounded CPU ranges, or GPU offload?

**Question:** does the eligible hotspot need a better algorithm, more CPU participants, a GPU, or none of these?

**Selection gate:** choose the largest *measured* owned-numeric stage from E01, not a fashionable kernel. Suitable candidates might be repeated proximity/closest-point queries or an independent per-point calculation. When no sufficiently large independent stage exists, record that finding and stop this experiment.

**Input:** export owned numeric snapshots with their input/output contract. Include small/medium/large point batches, low/high source mesh complexity, boundary holes/slivers, sparse acceptance where relevant, transformed geometry, changed inputs and unchanged reuse. Preserve seed/candidate order. Use actual exported datasets plus carefully labeled synthetic adversarial cases; do not call standalone timings Max benchmarks.

**Phase A — serial algorithm:** compare the current correct stage with a simple exact reference and a minimal prepared/indexed or allocation-reduced candidate. Count construction/refit cost, memory, tested primitives and queries. Apply the same predicates/tie order and compare outputs. If a changed distribution is required, stop treating it as an equivalent optimization.

**Phase B — bounded CPU:** compare serial to a small participant/grain sweep, including the caller and launch/join time. Preserve independent fixed output slots and any ordered final acceptance. Test one and many simultaneous controllers, foreground navigation and relevant active renderer modes. A persistent pool is a later branch only if thread startup materially dominates successful joined work.

**Phase C — GPU rejection floor:** only if a large eligible stage remains, implement the transfer/dispatch/readback floor from Section 7.3 for one justified backend. Include all required input/output bytes and synchronization with the actual CPU consumer; report cold allocation/context and warm reuse separately. If even the optimistic floor cannot meet the complete-operation target, reject GPU work. If it passes, one real kernel may be compared—not an entire engine port.

**Oracle:** exact IDs/counts/order and declared numeric parity; boundary/tie cases; independent geometric checks rather than only matching a possibly flawed baseline. CPU/GPU differences require the existing correctness contract or explicit approval of a narrower versioned one. Check failure/unsupported-device fallbacks and renderer coexistence before claiming adoption.

**Raw output:** immutable dataset metadata/hashes, build/compiler/FP flags, all stage timings, participants/grain, transfer bytes, buffer lifetimes, CPU/GPU memory, parity/error distributions, candidate reject reasons, and complete in-host eligible-operation timings after integration.

**Decision/stop:** prefer the smallest winner. Retain serial below a measured crossover. Require the D06 full-operation margin before shipping compute offload; passing a kernel-only comparison is insufficient. Reject any unsanctioned layout change, host access in workers, RAM/VRAM failure, significant interaction contention or unsupported deployment. A favorable synthetic kernel is justification for a real-scene test, not a product performance claim.

### Common trial discipline

Start with a short pilot to estimate variability and profiler overhead. Then choose enough paired repeated runs to resolve the pre-agreed decision margin; do not prescribe a magic number independent of noise. Alternate or randomize A/B order, include explicit cold and warmed states, keep raw trials, and use robust paired summaries/uncertainty. Set a time limit and minimum decision precision before collecting the final comparison; report inconclusive results instead of collecting until one wins.

Use p95 tails within sufficiently long captures, but report uncertainty across independent captures. Do not hide small-scene regressions in a grand average. As a proposed review flag, investigate regressions exceeding both 5% and 1 ms in an interaction; small absolute regressions may still matter for a tight frame budget, so that is not automatic permission. Require zero known correctness failures. Compare optimized Release builds using verified symbols; instrumentation overhead should be measured and kept out of the headline result.

