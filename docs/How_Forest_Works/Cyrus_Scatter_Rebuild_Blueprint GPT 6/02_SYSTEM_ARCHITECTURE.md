# 02 — System architecture and execution order

**Status: proposed Cyrus design. Research basis: R0 §§1, 8, 11.**

## 1. The architecture in plain language

Think of the plugin as three connected products: an authoring application inside Max, a pure placement engine, and several output translators. The artist edits a recipe. The host captures the required scene data. The placement engine creates a reproducible population from owned snapshots. Viewport and renderer adapters consume that population without owning its rules.

```text
3ds Max scene and UI
        |
        v
Host adapter / commands / references / Undo
        |
        v
Immutable input snapshot + authoring recipe
        |
        v
Shared geometry, surface, map and region preparation
        |
        v
Canonical candidates -> attributes -> constraints -> final population
        |
        +------> viewport / picking
        +------> Particle Flow transport
        +------> renderer-specific adapters
        +------> diagnostics / bake / export
```

The diagram is deliberately not a class hierarchy. Each arrow represents a data contract with ownership, revision, and failure rules.

## 2. Module boundaries

| Module | Owns | Must not own |
|---|---|---|
| `cyrus_model` | Persistent recipe, IDs, parameters, edits, paint assets | Max SDK pointers |
| `cyrus_core` | Canonical sampling, transforms, gates, reference solver | Scene nodes, dialogs, renderer calls |
| `cyrus_spatial` | Mesh BVHs, curve queries, region fields, spatial indices | UI state |
| `cyrus_eval` | Dependency DAG, job cancellation, immutable stage outputs | Arbitrary scene mutation |
| `cyrus_host_max` | Scene references, snapshot capture, units, Undo, save/load, event routing | Independent competing scatter algorithm |
| `cyrus_viewport_max` | Nitrous resources, display subset, selection translation | Authoritative instance count |
| `cyrus_transport_pflow` | Instance-to-particle transport and capability checks | Candidate generation |
| `cyrus_renderer_*` | Prototype translation, instances, attributes, time samples | Authoring decisions |
| `cyrus_ui_mxs` | Panels, workflows, scriptable commands | Per-instance numeric loops |
| `cyrus_tools` | Analyzer adapters, CS Edit bridge, libraries, scene lister | Hidden duplicate state |
| `cyrus_testkit` | Fixtures, canonical outputs, comparisons, timing instrumentation | Shipping behavior changes |

These are logical libraries. Do not create a separate DLL for every row before measuring build, ABI, and deployment needs. A static host-independent core with a version-specific Max plugin is a reasonable first packaging decision.

## 3. Persistent versus derived data

Persistent data is the smallest complete description of artistic intention: recipes, sources, references, canonical paint, source weights, parameter curves, manual edits, algorithm/profile versions, and units.

Derived data includes acceleration structures, compiled contours, candidate pages, accepted-instance buffers, renderer prototypes, and GPU buffers. It can be discarded and reconstructed. A saved disk cache may accelerate loading, but it is valid only under a complete input fingerprint.

A surface cache cannot become the only location of receiver attachment information. A GPU buffer cannot become the only location of hand-edited transforms. The application must remain recoverable after deleting all derived caches.

## 4. Input capture

The host adapter evaluates source and receiver objects at the requested time and stack position. It converts needed data into owned, immutable arrays. Record object identity, topology revision, geometry revision, mapping revision, transform revision, material revision, and evaluation validity.

Snapshots identify exactly which evaluated mesh they represent. A face number without a topology/stack fingerprint is not a durable surface binding.

Do not capture the entire Max scene by default. The dependency graph requests only inputs used by the recipe. Shared receivers and repeated source/time samples reuse snapshots.

## 5. Compile the recipe before generating placements

A `CompiledLayerPlan` resolves parameter inheritance, area order, required map channels, field dependencies, Effects stages, collision policy, and required output attributes. It rejects cycles and unsupported combinations before expensive work begins.

For each include contribution, compile its effective generator and the later exclusions that can affect it. This respects ordered area semantics without repeatedly traversing the whole UI list for every candidate. Reordering an area changes the compiled program, not the area's stable identity.

The compiler also answers whether an edit is local, globally influential, or has unknown support. Unknown is treated conservatively.

## 6. The selected evaluation order

The order below defines **CyrusV1**. It is intentionally stricter than an arbitrary post-processing chain.

| Stage | Responsibility | Output |
|---|---|---|
| S0 Snapshot | Capture scene and authoritative state | `InputSnapshot` |
| S1 Prepare | BVHs, curves, field programs, maps, source metadata | `PreparedInputs` |
| S2 Enumerate | Canonical candidates for each include/generator | `CandidatePage` |
| S3 Resolve | Receiver hit, binding, UVs, normal, slope, height | `ResolvedCandidatePage` |
| S4 Eligibility | Ordered regions, source-independent masks, density, material-ID/slope/height gates | Eligible candidate records |
| S5 Source/shape | Source selection, random transforms, area scale, placement Effects | Proposed transforms and footprints |
| S6 Artistic edits | Tombstones, constrained overrides, independent manual items, pins | Edited candidate set |
| S7 Final geometry gates | Requested reprojection, strict boundaries, post-move validity | Occupancy candidates and pins |
| S8 Occupancy | Deterministic collision/spacing solution | Accepted population |
| S9 Presentation attributes | Tint-only Effects, material attributes, animation sample references | Final logical instances |
| S10 Outputs | LOD, output visibility, preview selection, renderer translation | Output-specific representations |

Parameters have declared stages. An Effect writing position cannot run at S9. An Effect writing source must run before final footprint calculation. Renderer opacity does not retroactively create missing candidate centers.

### Density that depends on final source or position

The common density gate runs at S4 using the resolved position and an independent random channel. A source-dependent density modifier is a separately named S5 gate. A final-position field is sampled after requested reprojection at S7. The plan records which domain each field reads.

There is no hidden fixed-point loop. A plugin extension that requires feedback from the final collision solution must become an explicit iterative solver with convergence rules or be rejected.

### Pinned objects

Pins are materialized separately from procedural eligibility. They can survive density/coverage changes, but require a valid source and a valid saved attachment policy. They enter S8 before ordinary candidates. Colliding pins remain visible with conflict diagnostics; the engine does not silently delete a hand-placed object.

### Camera-dependent population controls

Distance density that deliberately changes the population belongs before S8. Ordinary view culling and LOD belong at S10. This prevents a viewport orbit from regenerating a static layer merely because the camera representation changed.

## 7. The dependency graph is not necessarily the execution graph

A dependency edge means one result requires another. Work can be fused for performance without removing the conceptual stage boundary. For example, projection, slope filtering, and normal collection can share one traversal, while retaining separate diagnostic counts.

Do not allocate every intermediate buffer for every scene. The compiler can request a minimal attribute set and fuse cheap passes. The reference evaluator remains simple and unfused so it can detect mistakes in optimized paths.

## 8. Shared services

A shared surface service can expose receiver geometry, ray hits, normals, barycentric bindings, and attributes. Surface Analyzer can supply these only after its contract is audited. It must not be assumed compatible merely because it has “surface” in its name.

A field service exposes scalar, vector, categorical, and distance queries. A curve service exposes positions, tangents, arc length, closest point, and offsets. A source service exposes bounds, pivots, compound children, and sample references. All three are reusable by distribution, Effects, painting, and outputs.

## 9. Output contracts

`PopulationSnapshot` is immutable and keyed by a recipe/input revision. An output adapter acquires a reference, builds its representation, and releases it after all CPU/GPU/render use has finished.

Output configuration includes purpose: interactive preview, final render, selection, or export. It is invalid to feed a preview-limited buffer into a final-render adapter without an explicit preview-render command.

Output failures preserve the last good interactive representation but cannot silently pass it as a successful final render. A farm render should fail with a specific error when it cannot reproduce required state.

## 10. Failure and recovery

Each stage returns either a valid immutable result or a typed error. Partial allocations use RAII and are released on cancellation. A failed source load does not corrupt other layers. A global error such as out-of-memory is reported with the requested allocation and stage.

Jobs carry both a scene lifecycle token and a layer revision. A job from a closed scene cannot publish into a new scene that happens to reuse the same node handle.

## 11. Example of an ordinary edit

The artist changes a flower tint curve. The command validates and stores the curve, creates one Undo transaction, increments the material-attribute revision, and marks S9/S10 dirty. The source meshes, surface BVH, candidates, and collision solution are reused.

The artist enlarges those flowers. Source/transform and footprint stages become dirty; strict boundary and occupancy results may change. Downstream grass that uses those flowers as exclusions becomes dirty only when the new final flower population is published.

This is the distinction between a dependency-aware system and a collection of callbacks all calling `RebuildEverything()`.

## 12. Implementation sequence for this architecture

First write a host-independent reference evaluator with a flat receiver and simple sphere sources. Next add a minimal host adapter and one proven output path. Add stages only with test fixtures and cache-key definitions. Introduce incremental and parallel execution after the full evaluator is trusted. Never make an optimization the only available implementation of an incompletely specified behavior.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S10]: https://docs.itoosoft.com/forestpack/forest-plugin/display
