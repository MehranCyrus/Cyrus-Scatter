# Requirements and the inspected CPU system

**Baseline: L — scoped 0.87.4.3 source inspection; historical host receipts are identified separately.**

## The interaction the artist expects

An artist prepares each unique plant source, places instances with arbitrary admitted rotations/scales, and moves an individual collider using Cyrus Edit. Nearby stems and their leaves bend while planted roots remain attached. When the collider leaves, plants return to their authored rest state. The user should not have to reconstruct scatter placements or re-prepare identical instances during dragging.

This is currently **quasistatic fitting**, not a physical time-step simulation. A GPU migration must reproduce that behavior before adding wind, inertia, damping, velocity, or two-way rigid-body coupling. For the same final inputs, moving the collider through different mouse paths should not create different final vegetation merely because an internal warm start differs.

## Source-to-display pipeline

```text
Original source mesh + preparation editor overrides
  -> owned preparation snapshot, metres, core +Y up
  -> shared Source: rest mesh, guides, anchors, attachments, correspondence

Published scatter layout + stable instance identities + Cyrus Edit overrides
  -> old/new spatial neighborhoods
  -> relevant collider queries per affected plant
  -> CPU fitSource, root exclusion, optional exact surface checks
  -> successor interaction snapshot with sparse poses
  -> retained preview / final geometry consumers
  -> Max host publication and viewport presentation
```

### Shared preparation

`AminScatter/include/interactions_source.h` defines shared prepared geometry, guide/root mappings, anchors, fixed decoration, per-guide vertex/face correspondence, preview mappings, limits, and fingerprints. Source preparation is asset work, not work that should repeat per placement. Different source definitions or artist overrides require different cache identities even when the original mesh happens to be instanced.

Preparation quality is independent of execution hardware. Welded branching geometry, ambiguous leaf bases, decorative trunks, multiple independent root groups, folded blades, and poorly attached foliage need correct authored classifications or geometric inference. CUDA cannot infer botanical intent from a bad binding automatically. Explicit Keep fixed/Bend/Follow stem assignments remain useful.

### Existing locality

`AminScatter/src/interactions_engine.cpp` builds a plant bounds hierarchy and obstacle indexes. Updates include neighborhoods around both previous and successor collider positions, independently edited transforms, and directly edited reacting instances. This supports restoring plants where a collider used to be. Under-collider exclusion needs projected reach, not only a small 3D sphere around the collider center.

The current engine already evaluates copied numerical data with native CPU workers. Work claims are dynamic for varied plant cost; results merge in stable input order. Large automatic jobs may use up to eight participants, subject to the session override and bounded scratch memory. This is synchronous execution: introducing an asynchronous GPU queue would be a new lifetime/publication subsystem.

### Sparse poses, with an important caveat

`Pose` shares unchanged guide definitions, stores changed guide poses, hidden-root state, and sparse rigid attachments. It does not permanently allocate a full deformed vertex array for every untouched plant. However, each posed plant still has per-guide lookup/state arrays, and an update copies retained pose/root-count maps into its successor. Thus locality does not prove every CPU operation is O(number of changed guides). Measure map copying and publication costs at large retained-state counts before attributing all delay to fitting.

`posePoint` and `poseDirection` are the semantic reference for final geometry. The current transform uses rest and posed material frames, shortest-path spherical interpolation, root treatment, and rigid attachments. The synthetic GPU probe uses a simpler normalized quaternion interpolation; it does **not** qualify equivalence to these functions.

## Requirements to preserve

| Requirement | GPU implication |
|---|---|
| Ordered layers and independent collision scopes | Carry stable layer/source/instance IDs; no global all-to-all coupling |
| Source shared across instances | Upload immutable rest geometry/bindings once per preparation revision |
| Positive uniform scale is the admitted interaction transform | Convert clearance and hide distance consistently; reject unsupported transforms explicitly |
| Max scene units/+Z versus internal metres/+Y | Convert at explicit capture/delivery boundaries, with typed units |
| Contact gap and Hide margin are independent | Separate constants, masks, invalidation, and diagnostics |
| Inside solid and Under collider differ | Implement volume classification separately from downward footprint queries |
| Root positions stay fixed | Zero-mobility anchors must be enforced throughout fitting and deformation |
| All relevant stems can react | No hidden percentage of guides; preview blade percentage changes display only |
| Last complete result survives failed successors | Compute privately, validate, publish atomically |
| Manual pending placement edits wait for Update | GPU work must respect setting ownership and existing update mode |
| Navigation/selection does not rebuild static data | Redraw must reuse retained sources/poses and buffers |
| Renderer/Bake/export remain correct | Preview shader output is not automatically a CPU mesh for downstream consumers |
| Undo/Redo and scene reset remain coherent | Invalidate outstanding revisions; never publish results for deleted/reused owners |

These map particularly to foundation contracts F03–F08, F10–F11 and the physics/animation extension contract. Before implementation inspect the current repository file `docs/ENGINEERING_FOUNDATION.md`; its inspected identity is in [the source record](evidence/local_source_identity.json). The report is a proposal, not a replacement for repository contracts.

## Current admission is not realtime capacity

The inspected engine admits at most 1,000,000 instances in one interaction layout, 16,384 obstacle instances, 64 relevant colliders for one plant, and 4,096 transient instance overrides. It also charges layout/index/query payloads against 512 MiB. That charge is **not total process memory**: source preparation, retained poses, driver allocations, viewport buffers, renderer data, and other native work need separate accounting. Source/fitter limits exist in addition to these admissions.

Raising a count alone does not increase usable performance. A new backend should report which bound was exceeded and its measured requirement. If a queue overflows, return incomplete/resource-limit status and retain the prior complete generation. Never truncate a collider list and call it complete.

## Existing scoped performance evidence

The repository's `docs/plans/interaction-hide-wireframe-20261027/DELIVERY_08743.md` receipt records one 200-plant fixture using a 451-guide, 22,032-vertex, 27,501-triangle grass source. Its identity is recorded in [the source record](evidence/local_source_identity.json). One update had three nearby candidates, six fitted guides, and 62 hidden rooted groups, with native contact evaluation about 4.05 ms. The independent visible-mesh audit checked 23,497 visible triangles in that fixture. A separate 5,000-instance numerical test exercised one neighborhood.

Those are historical scoped observations, not measurements rerun here. They do not establish input-to-present latency, 5,000 complex plants bending simultaneously, renderer throughput, or a GPU speedup. The standalone experiments in this report answer different, smaller questions.

## What to profile before selecting a backend

Capture one revision ID across: mouse input received, authored transform captured, neighborhood query completed, retained-map successor copied, fitting completed, geometry constructed, upload submitted/completed, host render item published, and first presented frame. Record stage wall times, summed worker times separately, bytes copied/uploaded, active populations, and old/new revision ages. A 4 ms native fitter plus a 25 ms geometry upload calls for a different fix than a 40 ms fitter plus a 1 ms compact upload.
