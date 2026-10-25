# Cyrus vegetation collision adapter — Owner A

This module implements `make_jolt_world` and every `CollisionWorld` method from the frozen C++20 contract. It is a standalone, immutable **public-Jolt query adapter for solid spheres and rigid oriented boxes**, with explicitly separated double-precision analytic witness refinement. It performs no timeline simulation, plant fitting, mesh deformation or host integration.

The integration target is **`cyrus_vegetation_collision`**. It publicly links `cyrus_prototype_contract` and privately links the verified static Jolt target. Public declarations remain in `../include/cyrus_vegetation/prototype_v1.hpp`; implementation details and diagnostic receipts remain private to this directory.

## Identity and build profile

| Item | Identity |
| --- | --- |
| Handoff edition | `CyrusScatter_Vegetation_Core_Handoff_v1` |
| Owner | A — collision |
| Frozen header SHA-256 | `f5c9b72e513a1c6ceea74f79bc0005175381691b65c99af47dc2debaebc7e42f` |
| Jolt commit | `1b2e77e3c6c09709e5edc79dc208459b8ff32051` |
| Upstream archive | `https://codeload.github.com/jrouwe/JoltPhysics/tar.gz/1b2e77e3c6c09709e5edc79dc208459b8ff32051` |
| Archive SHA-256 | `6bb6d626b7b70096cd07f1b25c0c223df035ab6386885f07f77baa88ae7d3998` |
| Upstream version labels | Header 5.6.1; CMake project 5.6.0. The commit is authoritative. |
| License | Jolt MIT notice retained in `cmake/Jolt-LICENSE.txt`; no full engine tree or binaries are returned. |

The new profile enables double world positions, assertions, cross-platform deterministic mode, C++ exceptions and RTTI. On x86 it uses the SSE2 baseline and disables SSE4.1/4.2, AVX/AVX2/AVX512, F16C, FMA, LZCNT and TZCNT. DX12, Vulkan, Metal and CPU-compute backends are disabled. Jolt is static; object layers are 16-bit; custom allocation is enabled; object streams, debug renderer, profiler, floating-point exception mode and IPO/LTO are disabled. The MSVC runtime follows the enclosing configuration. Floating-point contraction/fast-math are disabled or constrained to the configured precise profile. Inherited higher-ISA compiler flags cause a compile-time rejection rather than an SSE2 claim.

Contract positions and analytic refinement use double. Jolt primitive dimensions, rotations and local query arithmetic still use float. `backend()` returns the commit, configured flags, actual `JPH::GetConfigurationString()` and precision description. Generated `collision/collision-build-options-<configuration>.txt` and `compile_commands.json` provide build details. The deterministic switch and repeatability controls do not establish bitwise equivalence across untested compilers/platforms.

## Build and test

Requirements: a C++20 compiler, CMake 3.20 or newer, and the unchanged handoff starter scaffold. Configure **the starter directory**, not this subdirectory: it supplies `cyrus_prototype_contract`. Restore this module at its original path in the same handoff edition. No root CMake or shared header edit is necessary.

The following are reproducible command templates; substitute your own paths. Actual executed commands and exit codes are in the evidence receipts.

### Offline source-root build

Use an unchanged extraction of the exact upstream archive. Keep build products outside its source tree.

```sh
cyrus_starter="/path/to/packet/docs/research/vegetation-core-handoff/starter"
cyrus_jolt="/path/to/JoltPhysics-1b2e77e3c6c09709e5edc79dc208459b8ff32051"
cyrus_build="/path/to/build/cyrus-collision-release"

cmake -S "$cyrus_starter" -B "$cyrus_build" \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCYRUS_COLLISION_JOLT_SOURCE_ROOT="$cyrus_jolt"
cmake --build "$cyrus_build" --config Release \
  --target cyrus_collision_tests --parallel 2
ctest --test-dir "$cyrus_build" -C Release -R '^collision_' --output-on-failure
```

### Configure-time download

Use a fresh build directory and omit the offline source root, or explicitly clear it. `FetchContent` enforces the archive SHA-256 before the same source-file verification runs.

```sh
cmake -S "/path/to/packet/docs/research/vegetation-core-handoff/starter" \
  -B "/path/to/build/cyrus-collision-online" \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCYRUS_COLLISION_JOLT_SOURCE_ROOT=
cmake --build "/path/to/build/cyrus-collision-online" --config Release \
  --target cyrus_collision_tests --parallel 2
ctest --test-dir "/path/to/build/cyrus-collision-online" \
  -C Release -R '^collision_' --output-on-failure
```

For a library-only build, configure with `BUILD_TESTING=OFF` and build target `cyrus_vegetation_collision`. A pre-existing target named `Jolt` is rejected: this standalone profile must not silently reuse an unverified engine configuration.

### Exact-source verification

Both setup routes verify all 613 regular files under `Jolt/` and `Build/`, plus `LICENSE`, against `cmake/jolt-source.sha256`. Missing, changed, symlinked or extra files in that inventory fail configuration. Source-only verification can run without compiling:

```sh
cmake -DCYRUS_JOLT_VERIFY_ROOT="/path/to/exact-jolt-source" \
  -P "/path/to/starter/collision/cmake/VerifyJoltSource.cmake"
```

`evidence/source-verification.json` records the successful exact-byte check and a negative check using a deliberately incorrect temporary hash manifest. That check returned the expected source-mismatch failure without modifying upstream source. This verifies source admission, not a loaded Max module.

## Admitted data and numeric range

All physical values are metres in a right-handed, Y-up patch. Quaternions are active local-to-patch rotations in xyzw order. No obstacle scale/shear matrix is admitted; dimensions must already be baked into a positive sphere radius or box half-extents.

| Input | Admission |
| --- | --- |
| Obstacle population | At most caller `max_obstacles` and a hard profile cap of 4096. |
| Scene generation | Nonzero. |
| Obstacle IDs/revisions | Nonzero ID, geometry revision and pose revision; IDs unique within the snapshot. |
| Numeric fields | Finite, including inactive sphere/box dimension fields. |
| Orientation | Finite quaternion with norm error at most `1e-10`; its copied value is normalized. Sphere orientation has no geometric effect. |
| Declared minimum feature `f` | `1e-6 <= f <= 1000` m. This is an adapter profile, not an engine-wide minimum. |
| Sphere radius / each box half-extent | `f` through 1000 m. |
| Obstacle center / query coordinates | Each component within `[-1e6, +1e6]` m; tighter precision checks still apply. |
| Query tolerance `t` | `1e-10 <= t <= f/4` m. |
| Point exclusion radius | 0 through 1000 m. |
| Capsule segment | Distinct finite endpoints; length `f` through 1000 m. |
| Capsule geometric radius | `f` through 1000 m. |
| Capsule clearance | 0 through 1000 m; effective radius is the sum, at most 2000 m. |
| Guide/span IDs | Nonzero and returned unchanged. |
| Limits | Every field nonzero, including fields belonging to later fitter/delivery stages. Zero never means unlimited. |

Malformed inputs return `InvalidInput`; finite inputs outside the declared supported profile return `Unsupported`. Admitted coordinates do not guarantee an answer at every tolerance. Each analytic witness carries a conservative engineering roundoff allowance, `1024*DBL_EPSILON` times a coordinate/extent/span scale. If this exceeds `t`, the query returns incomplete `Ambiguous`. Comparisons too close to a clear/contact or inside/outside boundary also return ambiguity when the allowance prevents a trustworthy distinction. Rebase the patch before float conversion or choose a meaningful admitted tolerance; no lost caller precision can be recovered afterward. This allowance is not a formal interval proof or a measured engine error.

## Public behavior and use

1. Capture `SceneSnapshot` and explicit `BackendOptions`.
2. Call `make_jolt_world`; proceed only when `outcome == Outcome::Ok` and `world` is present.
3. Keep the returned `shared_ptr<const CollisionWorld>` alive throughout queries; check `generation()` against the requested job generation.
4. For every query, require **both** `outcome == Outcome::Ok` and `complete == true` before consuming its hits or interpreting an empty contact vector as clear.
5. Rebuild a new world for a changed obstacle pose/geometry generation. Old and new worlds can coexist until their respective users finish.

Construction deep-copies each admitted obstacle, including its pose and both revisions, then owns immutable native shape references. Caller edits, vector destruction and input ordering cannot change an existing world. Entries and results are sorted by stable caller obstacle ID. Native body IDs are not used as caller identity; this adapter has no live bodies or `PhysicsSystem`. Guide/span IDs are copied into contacts. Query results echo the world generation. The caller remains responsible for assigning meaningful new revisions/generations when source data changes.

### Point classification

`classify_point(p, exclusion)` returns exactly one `PointHit` for every obstacle on complete success. It performs a real public `Shape::CollidePoint` solid query for each primitive and independently refines its signed distance in double. The reported gap is:

```text
primitive_signed_distance(p) - exclusion_radius
```

Outside means gap greater than `t`; Inside means gap less than `-t`; the remaining band is Boundary, subject to precision qualification. OBB exclusion is Euclidean signed-distance expansion, not simply expansion of all half-extents. Root containment and roots in the exclusion band are therefore available even when a surface-overlap query would find no remote surface. An empty scene returns a complete empty result only after normal input, cancellation and budget checks.

### Whole-segment capsule contacts

`query_capsule` examines the complete directed segment against **every** obstacle. It performs the real public `CollisionDispatch::sCollideShapeVsShape` call with a Jolt capsule as shape 1 and the copied obstacle as shape 2. It then computes the minimum primitive point signed distance over the continuous centerline in double. Every obstacle whose qualified gap is within `t` is returned; an irrelevant obstacle is omitted. No early nearest-obstacle termination is used.

There is **one deepest centerline-SDF witness per relevant obstacle**. This is a documented manifold reduction, not an exact rigid-capsule minimum translation depth/vector or a complete contact manifold. For spheres the selected parameter is the closest segment point to the center. For OBBs a finite piecewise quadratic/affine candidate set gives the minimum point SDF along the segment. The box refinement needs no heap allocation and has at most 32 candidate evaluations.

Every returned witness is checked for finite unit outward normal, primitive surface membership, directed `u` in `[0,1]`, axis reconstruction and gap consistency:

```text
axis_point = a + u * (b - a)
signed_gap = dot(outward_normal, axis_point - obstacle_point)
             - geometric_radius_m - clearance_m
```

The native capsule radius contains geometric radius plus clearance **once**. Primitive refinement subtracts these values once when forming the reported gap; it does not add a second inflation. A raw engine contact is never assigned an invented `u`. Raw misses cannot establish outside or clear: analytic refinement supplies the admitted solid/capsule classification, including wholly contained spans. A gross contradictory native hit or malformed raw witness returns ambiguity. The private diagnostic receipt distinguishes native calls/hits, refined contacts and native misses supplemented by refinement.

At medial-axis ties a valid normal may be nonunique. Ties are deterministic, but normals can change discontinuously. Downstream finite fitting steps must requery. A collision-free capsule only certifies its declared envelope, not undeclared blade edges or the rendered surface.

### Frames, transforms and native settings

The contract material-frame tangent is **local +Z**. A Jolt capsule is longitudinal along **local +Y**. The adapter explicitly rotates +Y onto `b-a`; it does not treat a guide material frame as a capsule pose. Cylinder half-height is half the segment length, with pose at its midpoint.

All admitted native primitives have local COM zero; construction checks that invariant. Each obstacle center supplies a per-pair origin. Point positions and capsule midpoint translations subtract that origin **in double before float conversion**. Point queries then apply the inverse native obstacle rotation. Shape queries use the capsule rotation/local translation and copied obstacle rotation at zero translation, both with unit scale. Raw positions are relative to that per-pair origin; diagnostics add the obstacle center back. Final refined witnesses are in patch coordinates.

Native `mPenetrationAxis` points in the direction that moves shape 2 out. With the obstacle as shape 2, its corresponding outward query-response normal is the negative normalized axis. Returned contact normals instead come from qualified primitive geometry. Boxes are created with explicit convex radius zero; Jolt's default rounding is not user clearance. Shape-query settings use collision tolerance `t`, maximum separation `t`, dimensionless penetration tolerance `1e-4`, and no face collection. Native discrepancy checks use a separate float-scale allowance; that allowance does not replace the contract tolerance or certify raw contacts as exact.

## Owner B and C integration boundary

Before fitting a planted guide, Owner B should classify its root with the declared root exclusion radius/envelope. An inside root is a local hard-root conflict; a boundary result must be handled using the declared tolerance. Do not silently move a hard root or treat incomplete classification as feasible. Root-position anchoring and root-orientation stiffness remain distinct Owner B policies; this adapter implements neither anchoring nor a rod engine.

Owner B must enforce its own whole-job iteration/query/memory limits, lengths/rest/frame policies, update proposals and cancellation. Refresh all relevant obstacle contacts after finite movement. An unresolved search is not proof of global geometric infeasibility. Owner C's independent whole-visible-triangle validator is still required before accepting a fitted ribbon. A contact witness, clear centerline or `ConvergedCandidate` alone is not final render-mesh acceptance.

## Work, cancellation and allocation accounting

`BackendOptions.limits.max_query_calls` is a **per-public-operation native dispatch budget**, not a mutable lifetime counter. A complete point or capsule query needs one native call per obstacle, including obstacles ultimately clear. If `N > max_query_calls`, it fails with `ResourceLimit` before any native dispatch. Repeated valid calls do not consume hidden world history. Owner B must separately count public operations across a fit.

Point queries require room for `N` results. Capsule queries reserve at most `min(N, max_contacts_per_query)` contacts and fail with `ResourceLimit` if all relevant obstacles do not fit. The per-pair native collector holds at most four shape hits; its fifth hit causes failure, never silent truncation. The primitive point collector admits one hit and detects overflow. All failure paths discard staged result vectors and leave `complete == false`.

Cancellation is checked before work, after acquiring the per-world mutex, between obstacle operations, inside hit collectors and before publishing success. There is no preemption inside a native geometry kernel or mutex wait, and no asynchronous cancellation-latency claim. Construction checks between bounded loops and after sorting. The profile caps construction/sort population and all result populations. Jolt's internal kernel work is not represented by a second public iteration counter.

The byte limit enforces an explicit **payload accounting policy**, not a measured peak or allocator-enforced global hard cap. With `Centry` the actual entry-vector capacity, `Cresult` the actual output-vector capacity, and `shape_i` the admitted native primitive type:

```text
owned_charge = sizeof(JoltWorld)
             + Centry * sizeof(Entry)
             + sum(sizeof(shape_i))
             + 4096

point_scratch_charge   = Cresult * sizeof(PointHit) + 65536
capsule_scratch_charge = Cresult * sizeof(Contact)  + 65536

admit only if owned_charge + operation_scratch_charge <= caller byte limit
```

The 4096-byte metadata and 65536-byte operation charges are explicit reservations, **not measured allocator usage or proved maximum stack sizes**. Construction initially charges the larger primitive size for each proposed entry, then recomputes using actual entry capacity and actual shape types. Requested capacities are checked before allocation; actual `std::vector` capacity is checked afterward. Standard-library over-allocation is therefore detected after allocation rather than prevented by a custom byte-limited allocator.

Excluded from exact instrumentation are allocation headers/alignment, shared-pointer control storage and strings beyond their reservation, native factory/type registries/default material, Jolt internal allocations, allocator bookkeeping, C++ runtime/stack infrastructure, process/thread diagnostic state and other worlds. The permanent runtime state uses fixed placement storage. Result vectors retained by callers after return and multiple simultaneously live worlds need caller/coordinator aggregate accounting. Private diagnostic `accounted_*_bytes` values are these charges, not `peak_owned_and_scratch_bytes` measurements. No memory/performance benchmark is claimed.

## Concurrency, lifetime and failures

Public geometry queries serialize per world with a mutex. Shapes/poses/options remain immutable; query collectors and settings are local. The caller must keep the world and the borrowed cancellation flag alive for each synchronous call. Two worlds may remain alive and be destroyed in either order. Their shapes are released before the final runtime lease unregisters types and destroys the shared factory/default material.

The standalone process owner requires initially null Jolt factory, default material and allocator hooks; a foreign runtime is `Unsupported`. Runtime state lives in fixed process-lifetime placement storage so its mutex is not destructed before a late ordinary owner. **All worlds must nevertheless release before Jolt's own global C++ static teardown.** Arbitrary cross-translation-unit static shutdown, foreign mutation of engine globals and cross-DLL Max ABI coexistence are outside this profile.

Checked default allocation wrappers translate ordinary null allocation into `std::bad_alloc`; public construction/query operations return `AllocationFailure` and no accepted partial output. Unexpected exceptions become `InternalError`. `backend()` is the frozen API exception: it has no `Outcome`, so allocation of identity strings may propagate `std::bad_alloc`. Catastrophic failure may also prevent diagnostic strings from being allocated even though the failure status survives.

Pinned Jolt hash-table growth is not strongly exception-safe: a failed replacement allocation can lose the old storage from reachable member state. On runtime-initialization failure, the owner releases reachable factory maps/default material/factory, restores its initially null hooks, and poisons further acquisition. Reachable cleanup after an ordinary allocation failure returns `AllocationFailure`; failed cleanup returns `InternalError`; later acquisition returns `InternalError` and requires restart. This prevents repeated uncertain leak accumulation. Complete OOM reclamation, foreign-runtime recovery and exception propagation through every native `noexcept` path are not guaranteed. The source-backed rationale is in `evidence/source-audit.md`.

## Verification and remaining scope

The final Linux x86-64 GNU 13.3 Release run recorded **15/15 CTests passing** in `evidence/ctest-release-final.log`, with its command/exit receipt in the matching JSON. Native identity reported double world positions, SSE2, assertions, cross-platform deterministic mode, RTTI and exceptions. The initial run is retained separately. `tests/README.md` describes independent analytic controls separately from raw engine tolerance observations.

Final-source build/test receipts are `evidence/build-release-final.log` / `.json` and `evidence/ctest-release-final.log` / `.json`; both returned exit 0. A separate Debug build with AddressSanitizer and UndefinedBehaviorSanitizer also passed all 15 cases with `halt_on_error=1`, using `ASAN_OPTIONS=detect_leaks=0:halt_on_error=1` and `UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1`; see `evidence/ctest-asan-ubsan-no-lsan.log` / `.json`. The first sanitizer run is retained in `evidence/ctest-sanitizers.log`: it returned exit 8 because LeakSanitizer could not read `/proc/<pid>/task` in this environment. Leak checking is therefore **blocked/unvalidated**, not a clean leak result. No sanitizer diagnostic appeared in the successful address/undefined-behavior run. `RETURN-REPORT.md` and the return manifest identify all runs and remaining unexecuted checks.

Coverage includes sphere and rotated-box controls, segment crossings with both endpoints outside, wholly contained segments, root/exclusion classification, normal/gap/u reconstruction, axis placement, scale admission/precision ambiguity, two obstacles and stable ordering, limits/incomplete-empty failure, already-requested cancellation, snapshot mutation, two-world teardown order and repeatability. Seeded OBB sampling is a bounded independent diagnostic; positive samples alone are not a mathematical continuous-clearance proof. Native shallow-contact observations use explicit metre-scale float tolerances and do not inherit the double-refinement controls' tolerance.

Not established: asynchronous cancellation latency, forced allocator-failure injection, race/concurrent-query stress, LeakSanitizer validation, cross-platform/compiler execution, configure-time network fetching, cross-DLL interoperability, Max 2027 launch or plugin loading, production renderer delivery, plant binding, ribbon evaluation, full-dynamics/rod fitting, terrain/triangle-mesh/SDF/hull queries, arbitrary scales, benchmarks or measured memory peaks. R12/R13/R14 source and historical results remain separately labelled evidence; their harnesses were not rerun or relabelled as this module's tests.

For the coordinator: merge only this directory into the same frozen edition, verify the manifest/header hash, configure the starter with the exact offline tree or hash-enforced download, link `cyrus_vegetation_collision`, run the `collision_` tests, then add joint B/C tests against the same snapshot generation. No shared declaration change is required.
