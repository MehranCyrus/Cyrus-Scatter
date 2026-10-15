# 23 — Developer handoff, interfaces, work packages, Definition of Done

## 1. What a development team should do first

1. Read chapters 01–04 and this handoff.
2. Obtain and audit actual Cyrus Scatter/CS Edit/Surface Analyzer source, tests and build environment (not reviewed for this document).
3. Select supported 3ds Max SDK versions and target render engines.
4. Baseline current behavior/performance on test fixtures.
5. Decide which modules can be retained, adapted or replaced.
6. Approve canonical types and versioned serialization format.
7. Build one vertical slice from input → candidate → area → source → output → Undo/Save.
8. Expand features only with unit, combo, persistence and benchmark tests.

## 2. Core C++ interface sketch

```cpp
// All interfaces below are design pseudocode; SDK signatures are not verified.
class ISceneSnapshotProvider {
public:
    virtual SceneSnapshot Capture(const SceneRequest&, TimePoint) = 0;
};
class ISurfaceSampler {
public:
    virtual SurfaceQueryResult Sample(const SurfaceQuery&) const = 0;
};
class IScalarField {
public:
    virtual double Sample(const FieldContext&) const = 0;
    virtual Dependencies Dependencies() const = 0;
};
class IRegionEvaluator {
public:
    virtual RegionSample Query(const SpatialQuery&) const = 0;
};
class IPlacementProvider {
public:
    virtual void Generate(const CandidateRequest&, CandidateWriter&) const = 0;
};
class ISourceSelector {
public:
    virtual SourceSelection Choose(const PlacementCandidate&, const SourceContext&) = 0;
};
class IConstraintSolver {
public:
    virtual ConstraintResult Resolve(const EvaluatedPopulation&) = 0;
};
class IEffectEvaluator {
public:
    virtual EffectResult Apply(ItemBatch&, const EffectContext&) = 0;
};
class IRendererAdapter {
public:
    virtual RendererCapabilities Capabilities() const = 0;
    virtual RenderResult Submit(const RenderStream&, const RenderContext&) = 0;
};
```

All `const` core interfaces should be thread-safe by construction or explicitly synchronized. Allocate input/output buffers through batch allocators/arenas to avoid one heap allocation per candidate.

## 3. Minimal vertical slice before broad feature work

Create a new scatter with two source cubes and one receiving plane. Add a 16×16 image distribution, one Include spline and one Exclude path. Project onto surface, choose sources by weights, apply random yaw, output points/boxes and at least one render instance adapter. Implement Undo for changing the Area order and saving/reopening the authored configuration. Verify deterministic accepted IDs.

**This small complete route reveals more architectural defects than implementing fifty disconnected UI spinners.**

## 4. Work-package template

```markdown
# ISSUE: CS-AREA-007
User story:
Behavior/evidence URL and version:
Scope and explicit non-goals:
Canonical units/default/range:
Input/output data contracts:
Spatial domain / coordinate convention:
Dependencies and dirty stages:
Thread safety and host callbacks:
Serialization / migration implications:
Undo and cancel behavior:
Failure and warning states:
Reference fixtures:
Unit and integration tests:
Performance benchmark:
Renderer capability implications:
Definition of Done:
Known differences / follow-up:
```

## 5. Suggested issue backlog — foundations

| ID | Work package | Deliverable | Blocking prerequisite |
|---|---|---|---|
| CORE-001 | Canonical IDs/types | UUIDs, typed coordinates, RNG channels | Repo audit |
| CORE-002 | Versioned domain schema | Source/Area/Scatter specs, migration harness | CORE-001 |
| CORE-003 | Immutable candidate buffers | SoA writer and stable IDs | CORE-001 |
| CORE-004 | Deterministic random service | Hash-to-float and source sampling | CORE-001 |
| CORE-005 | Dependency graph | Typed dirty propagation and versions | CORE-002 |
| CORE-006 | Job scheduler | cancellation, snapshot-aware publication | CORE-003/005 |
| HOST-001 | Scene snapshot | geometry/spline/UV and transform capture | CORE-001 |
| HOST-002 | Undo/save adapter | 3ds Max document persistence | CORE-002 |
| SURF-001 | BVH receiver cache | XY ray hit and surface samples | HOST-001 |
| SURF-002 | UV lookup | UV triangles, islands, overlap policy | SURF-001 |
| DIST-001 | Image generator | bitmap candidate records and density | CORE-003/004 |
| DIST-002 | Path generator | arc-length, offset/orientation | HOST-001 |
| DIST-003 | Reference provider | pivots/faces and name mapping | HOST-001 |

## 6. Suggested issue backlog — artist-facing systems

| ID | Work package | Deliverable | Blocking prerequisite |
|---|---|---|---|
| AREA-001 | Region evaluator | closed/open spline inside/distance | HOST-001 |
| AREA-002 | Ordered Area stack | provenance and Include/Exclude | DIST-001/AREA-001 |
| AREA-003 | Object exclusion | projected raster + accuracy control | HOST-001 |
| AREA-004 | Falloff curves | include/exclude density + scale/height | AREA-001 |
| PAINT-001 | Host brush session | pressure, surface hits, visual overlay | HOST-001 |
| PAINT-002 | Authoritative strokes | add/erase, Undo, save | HOST-002/PAINT-001 |
| PAINT-003 | Coverage tile compiler | cache and SDF | PAINT-002 |
| PAINT-004 | Incremental redraw | changed tiles, preview safety | CORE-006/PAINT-003 |
| SRC-001 | Source registry | weighted/empty/compound sources | CORE-002 |
| SRC-002 | Diversity | Color ID and clusters | DIST-001/SRC-001 |
| TR-001 | Transform evaluator | curves, maps, mirroring | SRC-001 |
| CON-001 | Collision solver | stable priorities and broadphase | TR-001 |
| CON-002 | Boundary policies | Point/Size, renderer Edge contract | AREA-002/CON-001 |
| EDIT-001 | Sparse overrides | edit/pin/delete/add/orphan | CON-001/CORE-001 |
| EDIT-002 | CS Edit bridge | selection/transform/Undo workflow | EDIT-001/HOST-002 |

## 7. Suggested issue backlog — production/advanced

| ID | Work package | Deliverable | Blocking prerequisite |
|---|---|---|---|
| VP-001 | GPU point cache | stable budget preview and upload | CORE-003 |
| VP-002 | ID picking | select/transform accepted items | VP-001/EDIT-001 |
| RND-001 | Neutral render stream | source/instance/attribute descriptors | CORE-003/SRC-001 |
| RND-002 | Arnold adapter | capability-tested source/instance output | RND-001 |
| RND-003 | Corona adapter | capability-tested output | RND-001 |
| RND-004 | V-Ray adapter | capability-tested output | RND-001 |
| SHDR-001 | Instance tint bridge | colors and material variants | RND-001 |
| RND-005 | Camera/LOD | culling, level selection, animation envelope | RND-001 |
| ANIM-001 | Source sample cache | bounded evaluation of animated assets | SRC-001 |
| FX-001 | Typed built-in modifiers | fields, stage, read/write sets | CORE-005 |
| FX-002 | Expression VM | restricted typed AST/bytecode | FX-001 |
| LIB-001 | Library/presets | assets, recipes, scene reference repair | CORE-002 |
| UTIL-001 | Bake/export | Max instance/mesh and neutral instance export | RND-001 |
| QA-001 | Golden regression runner | full/differential build tests | CORE-003 |
| QA-002 | Version/render matrix | automated/manual SDK scenes | RND-* |

## 8. Data-contract review checklist

Before implementing any subsystem, resolve: stable ID, world/UV coordinate space, units, projection, state mutability, owning thread, source revision, output cache key, invalidation, serialized state, Undo unit, failure states, output capabilities, and test names. An interface lacking these fields is likely to generate coupling later.

## 9. Definition of Done per feature

A feature is production-ready only when:

- User-facing behavior is described with version/evidence.
- Input and output types are stable and tested.
- It works in isolation and in the declared combinations.
- It does not access host API from unsafe worker threads.
- Changes invalidate exactly the required stages (conservative fallback is acceptable).
- It supports Undo/Redo and save/load when authored.
- Missing references/invalid inputs fail visibly, not silently.
- Results are deterministic and full/incremental builds agree if incremental is exposed.
- Renderer/viewport limitations are accurately declared.
- It passes benchmark regression tests and has actionable diagnostics.

## 10. Rebuild risk checklist

**Never:** overwrite old customer scene data without migration; use random array indices as persistent IDs; permit stale worker publishes; assume `Texmap` calls are worker safe; infer renderer capability from name; delete orphan manual overrides silently; optimize collision tiles without differential correctness; rewrite existing architecture without baseline profiling.

**Always:** preserve source data, document deliberate parity differences, capture performance evidence, keep a simple full rebuild fallback, and ship clear failure states.

## 11. What to hand to a coding agent

For each bounded task, provide the relevant chapter, selected files from **actual repository**, a narrow goal, exact version/SDK, existing test fixture, required interface, no-change boundaries, and a definition of done. Instruct it to run unit/integration tests, report changed files and known limitations, and not perform unrelated refactors. A giant one-shot "clone ForestPack" coding prompt is unlikely to produce safe, coherent or testable output.

## 12. Final design target

The goal is an engine where an artist can place millions of repeated objects, shape compositions through ordered regions and brushes, edit individual heroes, keep the results stable under revisions, and render accurately—while all of those features share **one coherent model of candidate identity, spatial fields, dependencies and outputs**.
