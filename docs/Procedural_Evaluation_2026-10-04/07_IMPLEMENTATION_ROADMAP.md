# 07 — Implementation roadmap and engineering checklist

This is the **frozen planning checklist before implementation**. Its boxes describe that starting point, not today's status. The [current delivery checklist](../Procedural_Implementation_0.7_2026-10-04/STATUS.md), [implemented subset](../Procedural_Implementation_0.7_2026-10-04/IMPLEMENTATION.md) and [Max 2027 report](../Procedural_Implementation_0.7_2026-10-04/RUNTIME_REPORT.md) now record completed work and remaining gates. The earlier [readiness review](10_READINESS_REVIEW.md) remains unchanged historical evidence. Keep future changes small and measurable, preserve artist scenes, and retain the [0.7 pre-release version decision](../Release_Versioning.md).

## P0 — Freeze behavior and add observability

Purpose: know whether a later change preserves old results and display performance.

- [ ] Record the checked-out source revision, generated-script identity, SDK/toolchain and loaded native module hashes.
- [ ] Capture old-policy transform/source/ID digests for single-set, multi-set, Brush, edited and cleanup fixtures.
- [ ] Capture current Point Cloud/Proxy/Mesh/centres display counters and navigation timings using identical source geometry and camera paths.
- [ ] Add non-mutating stage/rejection instrumentation where missing; ensure reading it never triggers generation.
- [ ] Inventory inherited versus set-owned fields before changing `syncLogicalSettings`.
- [ ] Add source/rotation/scale-by-candidate digests, clone output IDs and source-offset/support-anchor cases to the baseline; count equality is insufficient.
- [ ] Measure rename/visibility pending/build behavior and ensure read-only statistics/configuration paths do not mutate or evaluate planting.

**Gate:** reproducible old-policy fixtures; counters explain current builds and display uploads. Historical reports are references, not replacements for the new baseline.

## P1 — Normalize ownership and introduce the new policy

Dependencies: P0.

- [ ] Add typed effective Layer/Set/Rule records, stable endpoint validation and a separate policy version.
- [ ] Adapt current parent/base-set storage without rebuilding every scene object.
- [ ] Centralize policy capability dispatch and audit all literal policy-2 branches, including Manual preview, Edit visibility, copying and UI guards.
- [ ] Persist explicit layer/set order; normalize old priority/Edit-key order during explicit conversion.
- [ ] Separate owner IDs, sampling keys, allocation tie keys and final Edit output IDs. Define random-channel stability and source-row correspondence under a versioned generator contract.
- [ ] Define latent/support/final-origin coordinates and validate protected reservation activation before exposing any new rule UI.
- [ ] Keep legacy generator/solver behavior available and unchanged.
- [ ] Add copy/remove/reorder/Undo/save-reopen fixtures and generated-script consistency checks.

Primary areas: `logical-layers.ms`, `planting-model.ms`, `layers-first.cjs`, source/identity helpers and the generated script.

**Gate:** identity survives rename/reorder, copies are independent, old scenes retain their output, rule endpoints cannot drift.

## P2 — Independent collision scopes and effective radii

Dependencies: P1.

- [ ] Extend the native numeric solver and bridge for variable-radius self-spacing, normalized pair rules and explicit XY/XYZ metrics.
- [ ] Use one relationship per pair; keep deterministic protected-first acceptance.
- [ ] Add scoped rejection/conflict reporting and bounded diagnostic pair samples.
- [ ] Add source-radius inheritance/multiplier behavior; qualify scale, mirroring and shear policy.
- [ ] Add sparse per-instance radius overrides after the candidate/Edit binding contract is proven.
- [ ] Verify original/clone overrides are independent and inactive/unresolved records never reserve space.
- [ ] Wire a shared native rule editor for self, sibling and layer scopes; opening it must not compute.

Primary areas: `group_spacing.h/.cpp`, `group_spacing_bridge.inc`, source-radius generator, CS Edit storage/stack, logical ownership and spacing UI factories.

**Gate:** exhaustive oracle agreement, independent knobs behave independently, old-policy outputs unchanged, actual transformed positions/radii satisfy every enabled rule except declared protected conflicts.

**First artist-testable milestone:** a Garden layer with red/blue/yellow sets whose self-spacing and pair spacing can be adjusted separately, plus a tree layer with a separate relationship. No refill is needed to validate this milestone.

## P3 — Background fill and bounded target replenishment

Dependencies: P2 and stable candidate-stream support.

- [ ] Separate candidate-budget and accepted-target modes in data and UI.
- [ ] Implement deterministic ordinal batches and hard generated-candidate/memory/round caps.
- [ ] Fix/version logical prefix and replay boundaries; cache capacity and physical worker chunking must not choose them.
- [ ] Add background role/references and the two domain interpretations.
- [ ] Implement the layer cleanup barrier and bounded replay with temporary cleanup suppression.
- [ ] Rebuild scratch occupancy after removal; expose underfill, attempt-limit and repair-limit outcomes.
- [ ] Preserve set shares; do not silently redistribute quota or remove protected over-target plants.
- [ ] Qualify valid protected-input reconstruction when quota shrinks to zero; reject unsupported binding transitions while preserving records.
- [ ] Evaluate probabilistic coverage once at the declared support anchor; test lifted source geometry and empty/whole-surface background references.
- [ ] Reject cycles/forward fill references and unsupported generation-mode combinations explicitly.
- [ ] Distinguish Point slots from renderable plants; initially reject weighted Empty sources with accepted-target mode so replenishment does not silently erase intentional gaps.

Primary areas: scatter candidate generation, Brush/area filtering adapter, group evaluation and cleanup orchestration, population/coverage UI.

**Gate:** impossible targets finish predictably; released-space fixture is reconsidered; final ordinary output remains collision-valid. Cold/warm/evicted runs and all allowed physical worker partitions produce identical IDs/transforms under the same fixed logical schedule. Changing that schedule is an algorithm change, not a performance tuning knob that may silently alter planting.

Density-target integration, all advanced line/Analyzer combinations and painted Relax are separate follow-ups. Maintain visible guards until their tests exist.

## P4 — Narrow invalidation without changing outputs

Dependencies: P1–P3 functional contracts; selected revision instrumentation can begin in P0.

- [ ] Introduce receiver/source/coverage/rule/order/edit/display revision domains.
- [ ] Separate candidate/prepared-set/completed-layer/display keys using the matrix in [05](05_CACHE_AND_VIEWPORT.md).
- [ ] Reuse immutable buffers and accepted index views; budget old/new generation coexistence.
- [ ] Track explicit occupancy dependencies and authored-reservation dependencies.
- [ ] Verify all scene callbacks, external map changes, source deletion, Undo and time validity before removing broad fallback invalidation.
- [ ] Add cache eviction/rebuild equality and stale-job/publication tests.
- [ ] Stage or roll back Edit publication, statistics and display state together; inject failures between consumers and verify the prior generation survives coherently.

**Gate:** every mutation produces a correct result; radius-only changes reuse candidate/coverage inputs; unrelated branches remain reusable; orbit and UI navigation add no placement work.

Do not implement a universal graph scheduler as a prerequisite. A small fixed dependency table plus per-owner keys can deliver most of this benefit.

## P5 — Qualify native integration and performance

Dependencies: P2–P4.

- [ ] Run pure native suites on both supported SDK builds, then validate the actually loaded binaries in isolated Max.
- [ ] Exercise curved Brush, areas, layer/set state, transforms, edits, renderer/Bake paths and lifecycle scenarios from [08](08_VALIDATION_AND_EXPERIMENTS.md).
- [ ] Compare current baseline versus new policy using both ordinary and extreme radius distributions.
- [ ] Select shipping refill caps from measured work/memory and usability; record the values and rationale.
- [ ] Confirm existing retained display packets consume the new results without regressions.
- [ ] Test native UI at representative panel widths and DPI without remount loops or computation on rollout changes.

**Gate:** passing scoped correctness/lifecycle evidence, no unexplained warm-navigation regression, bounded worst-case work, clear unsupported cases. Fix findings before claiming production readiness.

## P6 — Extend MCP and synchronize documentation

Dependencies: stable native policy and P5 acceptance.

- [ ] Add read-only configuration/diagnostic fields first.
- [ ] Version plans/settings for ownership, three scopes, fill and work limits; keep v1/v2 unchanged.
- [ ] Implement approved bounded apply/export using the same evaluator and actual published generation.
- [ ] Test schema rejection, scope ownership, approval digest, idempotency, cancellation, Undo and underfill behavior.
- [ ] Update artist help, capability registry, system map, public docs and release notes together.
- [ ] Document what future ML recipes can now express without advertising ML implementation.

**Gate:** native UI and MCP produce equivalent effective inputs and results for supported cases; unsupported requests fail clearly.

## P7 — Measure before expanding

- [ ] Investigate radius-bucket grids only if heterogeneous radii dominate time.
- [ ] Investigate worker scheduling only if independent numeric preparation dominates update latency.
- [ ] Investigate view-dependent point detail/retained Proxy only if drawing dominates navigation.
- [ ] Investigate geodesic metrics or animated surfaces only when artist fixtures require them.
- [ ] Investigate GPU placement or learned patterns only against a measured CPU/procedural baseline.

These are optional research branches, not commitments required for the first release. There is no honest date estimate until P0 measurements and P2 binding risks are resolved.

## Delivery discipline

Each milestone includes the change, fixture, source/build identity, raw results, interpretation and remaining limitations. Keep generated files reproducible. Do not update old research reports to make their measurements appear current. A final release checklist must distinguish build success, pure native tests, Max runtime checks, renderer qualification and artist acceptance.
