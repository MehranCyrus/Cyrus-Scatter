# Cyrus Vegetation Core v1 — owner C delivery module

## Identity

- Role: **C — prepared ribbon evaluation and independent visible-mesh validation**
- Edition: `CyrusScatter_Vegetation_Core_Handoff_v1`
- Frozen public header: `starter/include/cyrus_vegetation/prototype_v1.hpp`
- Verified frozen header SHA-256: `f5c9b72e513a1c6ceea74f79bc0005175381691b65c99af47dc2debaebc7e42f`
- Exported CMake target: `cyrus_vegetation_delivery`
- Required shared target: `cyrus_prototype_contract`

This module implements only the two frozen entry points owned by C:

```cpp
EvaluationResult evaluate_ribbon(...);
ValidationResult validate_candidate(...);
```

It does not call owner A, owner B, Jolt, a mock collision backend, 3ds Max, a renderer, or a host adapter.

## Implemented evaluator

`evaluate_ribbon` uses the frozen one-guide binding contract exactly:

1. Resolve every binding by semantic `span_id`; never infer association from position.
2. Compute the span center by linear interpolation.
3. Compute the material frame by normalized shortest-path quaternion slerp.
4. Rotate the complete xyz `rest_local_offset` and add it to the center.
5. Use the same sampler for rest reconstruction and deformed evaluation.
6. Preserve render-vertex order, UV seams, triangle indices and face material assignments.
7. Produce area-weighted unit geometric normals and exact componentwise position bounds.
8. Publish the privately staged mesh only after all admission, reconstruction, geometry, cancellation and resource checks succeed.

The evaluator rejects unsupported full-turn twist and adjacent near-pi frame ambiguity. Quaternion sign changes alone do not change output. Coincident vertices are never welded. Authored custom normals and tangents are explicitly outside v1.

## Independent validator

`validate_candidate` re-evaluates the supplied pose through a separate reference sampler; it does not call `evaluate_ribbon`. It checks:

- source, revision, guide and mesh identities;
- fixed root, root mode, span lengths and frame validity;
- independent rest reconstruction and deformed position correspondence;
- declared full-offset envelope sufficiency;
- exact topology, UV, material and exact bounds preservation;
- independently recomputed geometric normals;
- root-envelope conflicts;
- every visible triangle against every admitted obstacle.

Sphere clearance uses exact point-to-triangle minimum distance, including triangle interiors and wholly contained triangles. Oriented-box clearance transforms triangles to box-local coordinates and uses a full triangle/AABB separating-axis test with the box expanded on each local axis. That OBB expansion is a conservative L-infinity certificate, not exact Euclidean offset geometry, and the reported SAT-axis overlap is not advertised as exact physical penetration.

## Resource and cancellation behavior

Every frozen `Limits` field must be nonzero. The module checks node, obstacle, render-vertex, triangle, obstacle/triangle-pair and conservative payload/scratch budgets. The memory value is a **conservative vector-payload estimate**, not a measured allocator peak. Cancellation is checked before allocation, in bounded geometry loops, and before successful completion. Failure returns no partially successful mesh and never edits any input.

## Build and test

From `docs/research/vegetation-core-handoff/starter/`:

```bash
cmake -S . -B build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j2
ctest --test-dir build --output-on-failure
```

All CTest names begin `delivery_`:

- `delivery_evaluator`
- `delivery_validator`
- `delivery_adversarial`
- `delivery_contract`

The test executable can also print all individual executed cases:

```bash
./build/delivery/cyrus_vegetation_delivery_tests all
```

Execution receipts are under `evidence/`. The supplied archive carried future modification timestamps relative to the build container; the final evidence build used a temporary source copy with normalized mtimes while preserving file bytes and frozen SHA-256 values.

## Executed coverage

The headless tests include passing controls as well as rejection cases:

- clear rest and the catalog-authored feasible sphere pose;
- root displacement, root inside a sphere and all three root modes;
- bad length, bad frame, bad source revision and wrong mesh pose;
- nonzero longitudinal offset, seam/logical IDs by binding order and quaternion sign invariance;
- unsupported full turn and ambiguous pi frame rotation;
- topology, UV, material, bounds and normal corruption;
- deliberately insufficient catalog-style width envelope;
- a visibly penetrating wide ribbon whose center guide is clear;
- large triangles whose vertices are outside while their interiors intersect a sphere or box;
- wholly contained triangles, rotated boxes and two-obstacle cases;
- cancellation, work/resource limits and a large-coordinate local-patch control;
- private triangle/sphere and triangle/AABB controls;
- optional diagnostic OBJ output.

See `evidence/COVERAGE.md` and `evidence/test-summary.json` for the requirement mapping and execution status.

## Known limitations

- Narrow v1 only: one prepared guide/ribbon, sphere and rigid OBB obstacles, local metre patch.
- No source extraction, automatic blade recognition, multi-guide skinning, full-turn twist, arbitrary mesh solids, SDFs, alpha-silhouette collision, self-contact or dynamics.
- No authored split-normal/tangent preservation. Normals are area-weighted geometric normals; unreferenced vertices or exactly cancelling incident faces are rejected.
- OBB clearance is conservative and may reject a triangle that is Euclidean-clear near a rounded box corner.
- No performance benchmark or allocator peak measurement was performed. CTest elapsed times are not product performance evidence.
- No viewport, renderer, Bake, Undo, save/reopen, Windows/MSVC, DLL/runtime-sharing or Max 2027 qualification was executed.
- `EvaluatedMesh` has no semantic-ID arrays. This implementation preserves binding order and validates against the retained `PreparedRibbon`; the requested shared-contract improvement is recorded separately.

## Local integration note

The coordinator can add this directory unchanged beneath the frozen starter and link `cyrus_vegetation_delivery`. Call `evaluate_ribbon` only after a source and pose pass the frozen identity/admission contract, then call `validate_candidate` against the exact immutable snapshot before publication. Treat `Pass` as a narrow core certificate only; generation/source identity against owner B's `SolveResult`, host dependency freshness, viewport/render/Bake agreement and failure retention remain coordinator/host responsibilities.
