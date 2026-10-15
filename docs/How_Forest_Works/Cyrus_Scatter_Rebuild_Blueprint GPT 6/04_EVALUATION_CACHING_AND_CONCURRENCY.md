# 04 — Evaluation, caching, concurrency, and incremental correctness

**Status: proposed Cyrus design. Research basis: R0 §8.**

## 1. Start with a correct reference, not a clever cache

Implement a pure full evaluator before an incremental evaluator. The full evaluator takes an immutable recipe and immutable input snapshots, then produces the accepted population under the selected behavior profile. It is the executable definition of the design.

An optimized evaluator may change traversal, partitioning, storage, and concurrency. It must not change the accepted result. This includes rerunning after a paint stroke, reopening a scene, changing worker count, or evicting caches.

Reference comparisons use canonical candidate IDs and values, not buffer order. Stages can store records differently while producing the same logical population.

## 2. The three-thread-domain rule

**Host domain:** scene access, reference handling, parameter evaluation, authoring transactions, SDK callbacks, host-owned resource publication.

**Pure compute domain:** immutable copied geometry, curves, images, fields, sampling, filtering, collision queries, CPU display preparation.

**Renderer/display domain:** calls only through a qualified output adapter and according to that API's documented lifecycle. It is not automatically equivalent to either of the first two.

Default to main-thread host access. A class being readable in C++ does not establish concurrent SDK safety. Max procedural maps and third-party source objects are especially important: do not send their live pointers into a worker merely because the operation appears read-only.

## 3. Job lifecycle

```text
Requested -> Capturing -> Prepared -> Computing -> ReadyToPublish
                      \-> Cancelled / Failed
ReadyToPublish -> Published or DiscardedAsStale
```

A request carries `sceneEpoch`, `layerUUID`, `authoringRevision`, `requestedTime`, `purpose`, and a dependency fingerprint. Publication checks all of them.

A cancellation token is advisory during computation but mandatory before publication. An expensive source evaluation that cannot be interrupted still cannot publish a stale result afterward.

Do not allow one queued rebuild per mouse event. Maintain at most one active compute job and one coalesced latest request per layer or dependency group. Brush overlay events can be processed independently of full population work.

## 4. Monotonic authoring revisions

Every committed authoring command receives a monotonic revision. Undo restores an earlier logical state but produces a new revision token; it does not reuse the old publication token. This prevents an old worker from matching a newly restored scene by accident.

A content fingerprint can still recognize reusable caches after Undo. Revision identity answers “is this the current request?” Content identity answers “can this derived result be reused?” Keep those separate.

Reset/open/merge operations increment a scene lifecycle epoch. A closed document's jobs and GPU buffers are retired through their owners.

## 5. Stage cache keys

A cache entry is valid only when every input it reads is represented in the key. Use typed keys rather than one ambiguous `sceneVersion`.

| Cache | Required identity/revisions |
|---|---|
| Receiver mesh snapshot | Node UUID, evaluated stack, time/validity, geometry/topology/UV/material-ID revisions |
| Receiver BVH | Geometry snapshot content, BVH algorithm/version, numerical profile |
| Object-space curve table | Curve topology/shape, interpolation tolerance, algorithm version |
| World-space projection structure | Local geometry plus relevant transforms/projection frame |
| Compiled area program | Area order, typed operations, local overrides, linked definitions |
| Paint contour/distance cache | Canonical tile contents, reconstruction rule, threshold, distance range/tolerance |
| Candidate enumeration | Generator domain, include UUID, sampling epoch, bounds envelope, seed channels used |
| Surface resolution | Candidate addresses/positions, receiver set, hit policy, surface revisions |
| Source/transform result | Eligible IDs, weights, maps, transform settings, source metadata, relevant Effects |
| Collision solution | All occupancy inputs, pair rules, pins, solver/profile/numerical versions |
| Tint stream | Accepted IDs, source/element keys, color fields, material settings |
| Viewport buffer | Population revision, preview policy, representation assets, display settings |
| Renderer prototype | Source revision, material structure, time sample, renderer ABI/capability profile |

A field reading camera distance adds a camera dependency. An Effect declaring unbounded scene queries forces conservative invalidation or is rejected from worker execution.

## 6. Dirty changes include semantic and spatial information

A `ChangeSet` contains changed parameter IDs, referenced-entity revisions, old and new support bounds, and reasons. Spatial changes use the union of old and new influence, not only the new brush/object position.

For a translated object exclusion, vegetation can reappear where the object used to be and disappear at its new location. Both regions are dirty. For a moved manual tree, dependent grass must update around both footprints.

Some changes have no bounded support: a seed change, global normalization, a globally evaluated nearest-neighbor relationship, or an unconstrained Effect. Such changes mark the relevant stage/layer globally dirty.

## 7. Partitioning is an implementation detail

Use spatial pages to distribute work and bound allocations. Pages have half-open ownership regions so boundary samples are emitted exactly once. Query halos provide neighboring data, but candidates retain canonical identity independent of page size.

Maintain both origin-domain indexing and final-position indexing when transforms can move candidates. A candidate generated in tile A can occupy tile B; invalidation and collision search must account for both.

A cache page might contain `CandidatePage`, `ResolvedPage`, and optional attribute streams. It should not necessarily retain rejected heavyweight records forever. Preserve enough provenance for diagnostics or regenerate inexpensive stages on demand.

## 8. Why a fixed collision halo is insufficient

Take a line of equal spheres where each overlaps only its immediate neighbors. Greedy acceptance in fixed order keeps A, C, E, G. Removing A can keep B, D, F, H instead. The change can propagate across the entire line.

Therefore a finite geometric radius is not a finite acceptance-dependency radius. The halo proposal in R0 §8.3 is useful for geometric queries but is not a correctness proof for local greedy collision updates.

The default implementation recomputes the layer's collision solution after affected candidates have been reevaluated. Optimize only after adding exact old/new conflict-component handling, described in chapter 11. Global fallback is a valid outcome, not a failure of the engine.

## 9. Atomic publication and cross-layer coherence

A downstream grass layer reads a specific **final edited tree population revision**, not a partially updated candidate buffer. The grass result records that tree revision.

For ordinary interactive work, layers may publish independently with visible dependency-staleness badges. For a coherent final render, acquire a consistent dependency closure: every dependent layer must reference the upstream revisions included in the same render snapshot. Evaluate in topological order.

Do not mix new tree locations with grass exclusions generated from old tree locations and call the combined scene exact.

## 10. Manual and Live update modes

**Live:** authoring changes automatically schedule a current population update.

**On gesture end:** brush/transform feedback updates immediately; population evaluation is coalesced until the gesture ends or an idle preview is permitted.

**Manual:** authoring state changes and dirty indicators appear, but an explicit Update builds the population.

Final render defaults to **Evaluate current authoritative state**, even in Manual mode. An optional “Render cached population” mode must be separately named, persist its frozen fingerprint, and show that the authoring state may differ. This prevents accidental stale farm renders.

## 11. Bounded memory and backpressure

Give cache classes budgets and priorities. Active published outputs and in-flight renderer samples are pinned. Eviction can target unreferenced derived entries, never the only copy of authoritative paint or edits.

Track temporary peak memory, not only persistent cache use. Full rebuilds may hold old and new populations simultaneously. Before allocating, estimate the complete stage peak including sort keys, spatial indices, source samples, and GPU staging.

If an allocation exceeds budget, use a specified route: smaller work pages, streaming, eviction, deferred lower-priority work, or a clear error. Never silently reduce final population density to fit RAM. An explicit preview-quality reduction can be allowed for interactive output only.

## 12. Parallelism policy

Parallelize independent preparation, candidate evaluation, and field sampling first. Preserve deterministic output through canonical IDs and stable compaction. Collision priority is independent of task completion order.

Use a bounded worker pool. Avoid each layer spawning its own all-core pool and multiplying the effective thread count. Reserve a configurable amount of CPU capacity for host responsiveness. The appropriate count is measured on target workstations, not asserted from core count alone.

Small jobs should run without expensive scheduling overhead. Job granularity, batch size, and cancellation frequency are performance parameters, not saved artistic parameters.

## 13. Observability

Log stage start/end, input fingerprints, invalidation reason, cache hit/miss, allocated bytes, cancellation age, and publication outcome. Show a user-facing subset without flooding Max listeners.

An “Explain rebuild” view should answer: “Scale changed -> footprint changed -> collisions rebuilt -> grass dependency updated.” This turns perceived randomness into an inspectable dependency chain.

## 14. Required verification

Run randomized edit sequences against both full and incremental evaluators. After every edit, compare accepted IDs, sources, transforms, and essential attributes. Repeat with warm and cold caches, different partition sizes, forced cancellation, Undo/Redo, and memory pressure.

A viewport frame-rate target is not enough. Record p50/p95 brush-overlay latency, authoring commit latency, exact population latency, and main-thread blocking separately. Targets in chapter 20 are engineering goals, not measured performance claims.
