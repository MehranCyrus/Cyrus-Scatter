# Embedded engine and public-source study

16 October 2026. SOURCE observations were made through GitHub search/fetch tools at the revisions below. No engine was compiled, executed or benchmarked. Library licenses are recorded as published metadata; dependency/notice review remains part of any later integration.

## Inspected revisions

| Repository | Commit inspected | Files/questions |
| --- | --- | --- |
| [JoltPhysics](https://github.com/jrouwe/JoltPhysics/tree/1b2e77e3c6c09709e5edc79dc208459b8ff32051) | `1b2e77e3c6c09709e5edc79dc208459b8ff32051` | HelloWorld setup/update, convex hull settings, update errors and CMake options; inspected CMake identifies 5.6.0 |
| [PhysX](https://github.com/NVIDIA-Omniverse/PhysX/tree/b97365c6ddb32fda8469bc788ec18024862b0368) | `b97365c6ddb32fda8469bc788ec18024862b0368` | HelloWorld step/completion boundary; use PhysX 5.5.0 documentation separately for geometry/CCD concepts |
| [Bullet](https://github.com/bulletphysics/bullet3/tree/d3afe76132fc76b0f9b2359cbaef47a3766e7fbb) | `d3afe76132fc76b0f9b2359cbaef47a3766e7fbb` | Fixed-step accumulator/clamp and compound-shape source discovery |

GitHub searches returned revision-bearing file URLs. Subsequent fetches used those exact commits. See [EVIDENCE.json](EVIDENCE.json) for file blob IDs and the ignored raw receipts for returned excerpts. Search results alone were used only as leads; code claims below use fetched files.

## Concrete source lessons

### Jolt: bounded buffers are a correctness boundary

[HelloWorld.cpp, lines 250–350](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/HelloWorld/HelloWorld.cpp#L250) separates body, pair and contact capacities; demonstrates a static floor and dynamic body, a fixed step, batching/broadphase guidance and activation callbacks. Its comments warn that exhausted contact capacity can allow intersections/fall-through. Callbacks may run from jobs.

[EPhysicsUpdateError.h](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/EPhysicsUpdateError.h) exposes separate manifold, body-pair and contact-constraint exhaustion flags. **PROPOSAL:** Cyrus must treat any such update error as a failed tentative solve and preserve the previous complete result. A body-count cap alone is insufficient. No Max API or UI work belongs in a physics job callback.

[ConvexHullShape.h, lines 20–65](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/Collision/Shape/ConvexHullShape.h#L20) exposes hull tolerance/convex-radius controls and a 256-point hull limit. **PROPOSAL:** use bounded leaf proxy generation with physical tolerances. Do not confuse geometric thickening with collision skin or blindly inherit defaults intended for larger assets.

[Build/CMakeLists.txt, lines 1–90](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Build/CMakeLists.txt#L1) exposes precision, determinism, SIMD, global flag override and debug/profiling options. **PROPOSAL:** configure these explicitly inside a Max dependency build. Review CPU requirements, compiler runtime, floating-point environment and symbol scope; don't import a sample's whole build policy into Cyrus.

Jolt's [architecture documentation](https://jrouwe.github.io/JoltPhysics/#deterministic-simulation) conditions repeatability on matching mutation order and binary code, with additional cross-platform requirements. It also distinguishes source-space shape origin from center of mass. **PROPOSAL:** keep saved transforms authoritative and store solver revision/options with any replay recipe. Do not promise engine-upgrade replay equality. Published project license: [MIT](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/LICENSE).

### PhysX: simulation completion precedes consuming results

[SnippetHelloWorld.cpp, lines 95–140](https://github.com/NVIDIA-Omniverse/PhysX/blob/b97365c6ddb32fda8469bc788ec18024862b0368/physx/snippets/snippethelloworld/SnippetHelloWorld.cpp#L95) uses a fixed `simulate` step followed by `fetchResults(true)`. **PROPOSAL:** a Cyrus solve can never publish data from an unfinished step; scheduling, cancellation and scene-lifetime checks must surround that completion boundary.

The [5.5 collision guide](https://nvidia-omniverse.github.io/PhysX/physx/5.5.0/docs/RigidBodyCollision.html) distinguishes ordinary triangle-mesh restrictions from dynamic meshes cooked with SDFs. Thus, the blanket assertion that PhysX cannot simulate any dynamic triangle mesh would be wrong. Convex/compound proxies remain the proposed first approach for small leaves; SDFs add preparation/memory costs and do not make degenerate flat geometry a sensible rigid volume.

The [advanced collision guide](https://nvidia-omniverse.github.io/PhysX/physx/5.5.0/docs/AdvancedCollisionDetection.html) discusses CCD strategies. **PROPOSAL:** test fast/thin leaf contact using fixed steps, appropriate shape thickness, contact offsets and selected CCD. The [rigid-body dynamics guide](https://nvidia-omniverse.github.io/PhysX/physx/5.5.0/docs/RigidBodyDynamics.html) supplies mass/inertia, damping and sleep concepts. Published SDK license: [BSD-3-Clause](https://github.com/NVIDIA-Omniverse/PhysX/blob/main/LICENSE.md). Current online SDK docs are not proof of the embedded version in tyFlow or Max.

### Bullet: accumulated wall time is not a free replay contract

[btDiscreteDynamicsWorld.cpp, lines 380–450](https://github.com/bulletphysics/bullet3/blob/d3afe76132fc76b0f9b2359cbaef47a3766e7fbb/src/BulletDynamics/Dynamics/btDiscreteDynamicsWorld.cpp#L380) accumulates elapsed time, derives fixed substeps and clamps execution to `maxSubSteps`. Its accumulator is reduced using the requested substep count before the clamp. **PROPOSAL:** our authoring clock must count the fixed steps actually executed. Feeding an arbitrarily delayed UI timer into an engine does not guarantee all elapsed time is simulated.

Bullet is especially useful as a reference alongside Houdini's documented Bullet workflow, but SideFX's proprietary integration and this upstream revision are distinct products. No equality of output or performance is implied. The repository publishes its [license](https://github.com/bulletphysics/bullet3/blob/d3afe76132fc76b0f9b2359cbaef47a3766e7fbb/LICENSE.txt).

## Selection matrix — judgment, not benchmark ranking

| Candidate | Reason to evaluate | Main integration question |
| --- | --- | --- |
| Jolt CPU | Clear standalone C++ setup, bounded error signals and repeatability documentation | Leaf contact quality, proxy preparation, CPU/build policy and cancellable Max scheduling |
| PhysX CPU | Direct conceptual alignment with tyFlow; broad geometry/contact controls | Packaging/runtime isolation, cooking cost, error handling and shutdown in a Max process containing other physics plugins |
| Bullet CPU | Relevant to Houdini's procedural RBD model; accessible fixed-step implementation | Small thin-body quality, threading strategy and sustainable maintenance for this embedding |

Recommend comparing Jolt and PhysX first with identical saved birth streams, physical units and proxy geometry. Use Bullet if those fail a decisive requirement or if its workflow/maintenance evidence justifies a third candidate. Do not build a multi-engine abstraction into the product merely to run this research comparison. A small disposable comparison harness is sufficient later.

No evidence currently requires GPU computation. First measure shape preparation, contacts, solve, transform transfer, Max redraw and upload separately. Prefer a CPU proof whose final output is the existing retained instancing path; GPU output rendering and GPU physics are separate questions.
