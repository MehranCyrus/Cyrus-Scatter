# 20 — Verification fixtures, reference outputs, and benchmarks

**Status: test specification. Except for the separately recorded Python oracle checks, these tests have not been executed. Research basis: R0 §§10–11.**

## 1. Three evidence levels

**Pure-core tests** run without Max and validate algorithms and contracts. **Host integration tests** validate SDK lifecycle, snapshots, Undo, persistence, and display. **Renderer qualification tests** validate actual translated output, materials, animation, and headless operation.

Passing a pure-core test does not establish the other two. A screenshot is evidence of an observed image, not proof of cache correctness or identity preservation.

## 2. Golden fixture format

Each fixture contains a recipe, source/receiver arrays or asset references, exact units/time/profile, operation sequence, and expected assertions. Small fixtures include canonical candidate tables and rejection reasons. Large fixtures store sorted-ID/value digests plus statistical summaries.

Record engine commit, dependency versions, platform, numerical profile, and command sequence. A fixture should be reproducible by a developer who was not present when it was created.

## 3. Core fixture catalog

| ID | Fixture | Critical assertion |
|---|---|---|
| T01 | 4×4 binary image on a plane | Known pixel-center addresses and tile transforms |
| T02 | Constant grayscale ramp | Stable thinning; approximate expected frequencies |
| T03 | Negative pattern coordinates | Correct floor/wrap and no border duplicates |
| T04 | Source weights plus Empty | Normalized selection; Empty has no occupancy |
| T05 | Source-list reorder | Canonical selection unchanged |
| T06 | Cluster parameter sweep | Size/roughness/mixing alter species field, not raw positions |
| T07 | Nonuniformly parameterized path | Arc-length spacing within declared tolerance |
| T08 | Closed and reversed paths | Defined seam/endpoints/orientation |
| T09 | Reference pivots/faces | Stable external identity and uniform triangle sampling |
| T10 | Stacked receivers | Correct hit policy and independent bound IDs |
| T11 | Sloped/vertical receivers | Density domain and alignment match declared mode |
| T12 | UV seams/overlaps/mirroring | No accidental dropped islands or identity merging |
| T13 | Include/exclude/include | Contribution order and later reintroduction |
| T14 | Overlapping includes versus union | Distinct semantics, no silent deduplication |
| T15 | Spline holes/self-intersections | Saved fill rule and boundary ties |
| T16 | Object Top Limit/overhang | Defined clipping and projected footprint |
| T17 | Narrow exclusion inside large footprint | Footprint test catches enclosed exclusions |
| T18 | Density/scale falloff curves | Independent outputs and zero-range behavior |
| T19 | Probability curves | CDF behavior, atoms, zero/negative rejection |
| T20 | Transform frames and locks | No double transforms; proper axis/channel relationships |
| T21 | Long collision chain | Demonstrate nonlocal acceptance change |
| T22 | Variable-radius accelerated collisions | Match naïve full solver |
| T23 | Old/new incremental closure | Match full solve after randomized edits |
| T24 | Pins and constrained overrides | Explicit survival, priority, and conflict diagnostics |
| T25 | Tombstones and identity epochs | Persistent suppression and orphan reporting |
| T26 | Paint max/min composition | Canonical quantized values and operation order |
| T27 | Paint tile boundaries | Identical contour/query results across partitioning |
| T28 | Paint short/long histories | Same canonical field, history-independent query path |
| T29 | Surface-attached paint | Deformation attachment and topology invalidation |
| T30 | Effects stage validation | Illegal writes/cycles rejected; correct invalidation |
| T31 | Camera/preview edits | Static population unchanged without population rules |
| T32 | LOD selection | Stable instance IDs, correct thresholds and bounds |
| T33 | Animation time mapping | Negative offsets, loops, frame/second distinction |
| T34 | Material/element preprocessing | Stable element IDs under supported changes |
| T35 | Collections and cycles | Deterministic membership and cycle rejection |
| T36 | Persistence and UUID remapping | Exact authoring round trip and coherent merge |
| T37 | Cancellation/publication races | Stale jobs never overwrite current state |
| T38 | Cache eviction/rebuild | Same output with warm and cold caches |
| T39 | Worker/page-size invariance | No authoritative dependence on scheduling/storage |
| T40 | Missing assets and limits | Typed failure; no silent final-quality reduction |

## 4. Host and output fixtures

| ID | Fixture | Critical assertion |
|---|---|---|
| H01 | Painter pressure callback | No double application of effective pressure |
| H02 | Painter stack mismatch | Requery correct evaluated receiver before binding |
| H03 | Stroke cancel/Undo/Redo | One transaction, exact authoritative restoration |
| H04 | Scene reset during job | Old lifecycle token cannot publish |
| H05 | Clone/merge/setup instances | IDs and references remap according to policy |
| H06 | Save during pending evaluation | Authoritative state remains complete/recoverable |
| H07 | Multiple viewports and resource reset | Correct retained resource lifecycle |
| H08 | Headless load/evaluate | No dependency on panels or active viewport |
| R01 | Shared mesh instances | Correct transforms and measured prototype reuse |
| R02 | Proxy/source capability | Correct supported behavior; explicit unsupported paths |
| R03 | Per-instance tint | Variation without unintended prototype duplication |
| R04 | Element edge masking | Correct representative-element behavior and original opacity |
| R05 | Animation/shutter samples | Correct time mapping and resource lifetime |
| R06 | Off-camera reflection/shadow | Default final output retains needed contribution |
| R07 | Repeated/interactive renders | No growing resource leak or stale data |
| R08 | Farm asset resolution | Reproducible output with explicit dependencies |

## 5. Exact versus statistical assertions

Exact assertions include canonical IDs, source mappings under a fixed profile, integer coverage bytes, saved parameters, and rejection states. Floating-point positions use declared tolerances unless a certified deterministic build requires exact bit patterns.

Statistical tests do not demand exactly 25% of a finite sample from a 0.25 probability. Use a predeclared tolerance based on sample count or a fixed statistical test and seed set. Avoid repeatedly changing tolerances until a bug passes.

A visual comparison uses fixed camera, exposure, source assets, renderer settings, and color management. It supplements numerical tests; it does not replace them.

## 6. Metamorphic tests

Some guarantees can be tested without knowing every expected coordinate. Changing tint must preserve placement IDs/transforms. Changing worker count or cache page size must preserve the entire logical output. Increasing a stable density gate preserves the eligible candidate subset before collisions. Deleting all caches must not alter rebuilt output. Duplicating an immutable source reference without changing its UUID interpretation must follow the collection policy.

These tests are particularly effective against accidental coupling and hidden mutable random streams.

## 7. Randomized edit sequences

Generate bounded sequences of paint, source weight, source radius, path movement, receiver transforms, manual edits, Undo/Redo, and cache eviction. After every committed edit, compare the incremental evaluator with a fresh full evaluator.

Use deterministic operation seeds and save the smallest failing sequence. A shrinking/minimization step should reduce a 200-operation failure to the few operations needed to reproduce it.

## 8. Performance matrix

Vary one axis at a time before testing combinations:

| Dimension | Suggested levels, not measured results |
|---|---|
| Candidates | 10k, 100k, 1M, 5M where memory allows |
| Receiver triangles | 1k, 100k, 1M, 5M |
| Sources | 1, 8, 64, compound/proxy mixes |
| Area complexity | Simple rectangle, 1k segments, many holes/linked regions |
| Paint history | 10, 1k, 10k gestures with controlled current coverage |
| Coverage | Sparse, dense, many small islands |
| Collision saturation | Low, moderate, very high rejection |
| Radius variation | Uniform, 10× ratio, 100× ratio |
| Animated samples | 1, 8, 32, bounded-cache pressure |
| Dependency depth | Single layer, tree-to-grass, several chained populations |

Warm and cold runs are separate. Record p50/p95 and peak memory, not only the fastest run. Disable unrelated variable workloads or report them.

## 9. Proposed responsiveness targets

These are initial engineering goals for a declared test workstation, not guarantees and not observed results:

- Brush cursor/coverage feedback: target p95 within 33 ms under the standard paint fixture.
- Ordinary navigation: target no population-evaluation work for camera-independent layers; frame rate is measured separately.
- Command validation/authoring commit: target short bounded main-thread work; expensive compilation/capture is profiled explicitly.
- Exact population updates: budget by scene class and report completion latency rather than pretending every million-instance edit is instantaneous.

Do not trade correctness for a target silently. The UI can maintain responsive overlays while exact work completes.

## 10. Required timing breakdown

Measure host snapshot capture, map preparation, surface acceleration, candidate enumeration, surface queries, field evaluation, source/transforms, boundary tests, collision index/solve, override application, compaction, viewport upload, picking, renderer translation, and source-sample preparation.

Record invalidation reasons and caches reused. A full update that is fast in a tiny scene may still hide unnecessary work that becomes catastrophic at scale.

## 11. Memory and leak testing

Track authoring paint, Undo records, candidates, accepted instances, spatial indices, source samples, old/new snapshots, GPU resources, and renderer prototypes separately. Repeated scene open/reset, render, and cancellation cycles should return to a stable baseline after expected caches are evicted.

Test out-of-memory handling through injected allocation failures in the pure core. Preserve authoritative state and last valid output; do not publish partial buffers.

## 12. Qualification report template

```text
Fixture ID:
Host / renderer / SDK versions:
Engine commit and behavior profile:
Hardware / driver / RAM:
Input assets and hashes:
Operation sequence:
Expected assertions:
Observed result:
Timing percentiles and peak memory:
Warnings / limitations:
Evidence artifact locations:
Status: pass / fail / blocked / not run
```

“Blocked” is not “pass.” Unsupported renderer edge behavior remains blocked even when the rest of the scene renders correctly.

## 13. What was actually executed in this package

See `examples/reference_validation.json` and chapter 00 for the generated check results. The Python oracle exercises small mathematical invariants, including deterministic selection, ordered contributions, paint operations, and collision-update equivalence. It does not run Max, compile C++, test UV geometry, evaluate GPU performance, or qualify any renderer.
