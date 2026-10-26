# 05 Architecture and output

**Status: current-source observations followed by proposed integration design.** The snapshot is a dirty working tree on 24 October 2026, not a clean release. File hashes and branch/HEAD are in [repository-snapshot.json](references/repository-snapshot.json).

## Current source boundary

| Observation | Inspected source | Applicability |
| --- | --- | --- |
| Native placement Record is 96 bytes and contains transform, source, receiver and identity data | [placement_store.h](../../../AminScatter/include/placement_store.h) | No per-placement vegetation deformation payload exists in this record |
| Retained Mesh presentation uses reusable source geometry and per-instance presentation data | [mesh_display.inc](../../../AminScatter/src/mesh_display.inc) | A new shape evaluator needs an explicit output path |
| Standalone Physics Lab creates Jolt rigid bodies and static collider bodies | [jolt_world.cpp](../../../CyrusPhysicsLab/src/jolt_world.cpp) | Existing rigid workflows do not establish a rooted-rod implementation |
| Working-tree Lab documentation is 0.3.0; the committed historical baseline differs | [Lab README](../../../CyrusPhysicsLab/README.md) | Preserve the distinction when interpreting older reports |
| Jolt is pinned by exact commit in the Lab build tool | [build.py](../../../CyrusPhysicsLab/tools/build.py) | A version feature description does not establish local integration of that feature |

The current README reports Scatter 0.86.9.2/schema 59. R03's public-main version assumptions do not replace this local baseline. No host or renderer qualification was performed for this documentation task.

R12 inspected upstream Jolt but could not audit the local Lab wrapper from the public repository. Our narrower local checks confirm the dependency pin, rigid-body construction and declared limits; they do not qualify wrapper cache ownership, cancellation, Undo or Scatter integration. Keep the dependency findings separate from the wrapper's acceptance status.

## Proposed pipeline

1. Finish ordinary generation, projection, Edit handling, spacing/Relax and acceptance using existing ownership rules.
2. Capture a compatible accepted placement generation and owned source/obstacle snapshots on the host boundary.
3. Identify affected placement IDs and fit their prepared drivers using copied numeric data.
4. Decode and validate visible shapes under declared work/memory limits.
5. Stage a complete interaction result bound to the exact placement generation and dependency revisions.
6. Publish atomically, then let viewport, renderer and Bake consume that completed result.

No later ordinary placement cleanup may silently move a planted root after fitting. Any upstream change that affects roots or source transforms invalidates the downstream fit. Rigid settlement needs a separate publication inlet because its completed transforms intentionally differ from ordinary projected placements.

## Reuse boundary

| Existing capability | Candidate reuse | Feature-specific responsibility |
| --- | --- | --- |
| Owned input snapshots, units and stable-ID conventions | Common numeric capture and identity rules after source review | Root/rest metadata, semantic binding and full dependency revisions |
| Cooked rigid shapes and engine queries | Obstacle acceleration or capsule/shape contact queries | Whole-segment/envelope selection, multi-contact and containment policy |
| Worker execution | Bounded native work using copied inputs | Job/barrier audit, cancellation boundaries and independent memory limits |
| Completed rigid transforms | Rigid-settle results keyed by Cyrus identities | Rooted AcceptedFit state, quality checks and mode-specific publication |
| Existing mesh/render/Bake infrastructure | Reviewed host adapters and retirement conventions | Per-placement shape evaluation, appearance channels and actual output parity |

These are reuse candidates, not a claim that the current Lab implementation already supplies every listed contract. The proposed PreparedSource, AcceptedFit and EvaluatedVariant roles remain engine-independent. Jolt body IDs and temporary contact-array offsets cannot replace stable scene identity.

## Ownership and data

Keep shared source preparation immutable. Store optional fit state for affected placements keyed by owner, stable placement identity, source/preparation revision and compatible placement generation. A compact sparse deformation table is a proposed starting point; it is not a mandate to enlarge the existing 96-byte placement record.

The result should be engine-independent: rest/source references, accepted driver/frame state, status/diagnostics, deformed bounds and the revisions needed to validate use. Do not persist solver pointers, body handles or worker-array offsets as scene identity. An optional resumable simulation state needs a different, versioned contract from a static accepted shape.

R11 usefully separates PreparedSource, AcceptedFit and EvaluatedVariant as proposed record roles: immutable rest/binding data, placement-specific accepted guide state, and evaluated output geometry/bounds. These names describe ownership boundaries, not delivered C++ types or an approved persistence schema. Bone/cage authoring tools may feed the chosen representation only after conversion and pose parity are demonstrated.

Place bulk storage, geometry math, contact search and numerical work in native C++. Keep UI and bounded authored commands in the existing orchestration layer. Host API access, source evaluation and publication follow the host-thread boundary; numerical workers use owned snapshots. A renderer callback may have its own execution/lifetime constraints and must consume pre-evaluated owned data safely rather than assuming it can access arbitrary host state.

## Invalidation and reuse

| Change | Proposed response |
| --- | --- |
| Obstacle transform/geometry or membership | Reconsider old/new influence and previous dependents; refit compatible affected placements |
| Accepted placement/source transform | Refit surviving IDs whose relevant inputs changed |
| Source topology, root metadata or binding | Rebuild preparation and invalidate dependent fits |
| Appearance-only edit | Reuse shape only when appearance channels do not affect preparation/physics |
| Fit quality, clearance or base attachment | Refit the affected interaction set |
| Selection, camera navigation, unrelated animation | Reuse completed static result and unchanged buffers |
| Relevant animated input in Live mode | Re-evaluate according to existing Live semantics and the declared time policy |

Before reuse, compare full compatible inputs. Stable IDs alone do not guarantee unchanged accepted populations, transforms or source assignments under F02. A local edit can affect an entire guide, and plant-to-plant coupling would broaden the dependency set.

A cooked-shape key must include geometry revision, cooking/representation policy and the supported scale policy. Translation/rotation can often reuse the same local shape while updating its pose; geometry changes or scale baked into vertices require a new compatible shape. This is a cache-design requirement to verify, not a claim that all current wrapper caches obey it.

R13 further distinguishes shape cooking from transformed query instances. Include role, units, winding, convex rounding and cooking tolerances in compatibility. Engine ShapeSettings cache Create results; changing settings without clearing/replacing that cached result can reuse old geometry. Prefer immutable per-generation snapshots and a newly compatible cooked result rather than mutating a shape while another job queries it. These are integration requirements, not evidence of a fault in the current Lab cache.

R14 closes a further ownership gap: per-query locking does not freeze the obstacle set for an entire iterative solve. Pin one immutable query-world generation, private world or owned transformed-shape snapshot for all iterations. A stone edit creates another generation. Rejecting stale publication is necessary but cannot repair a solve that mixed old and new obstacle poses internally. Refcounting preserves lifetime; shape and transform revisions preserve meaning.

Within a shared Jolt runtime, multiple worlds can share compatible immutable shapes; bodies, IDs and constraints remain world-specific. Factory, dispatch/type registration, default material, allocation and diagnostic hooks have shared lifetime ownership. A new fitter must not replace or unregister those services while the rigid service uses them. Inspect the actual Cyrus module/linkage, ABI/build and allocator boundary before sharing engine resources; matching a source SHA alone does not establish that compatibility. This is a required integration audit, not qualification of the current wrapper. [Multiple-system contract](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Docs/Architecture.md#L853-L867).

## Rod preparation, reset and result extraction

A CPU rod experiment needs canonical positions, velocities, rod orientations/angular velocities and immutable rest constraints. Resetting only particles, or hard-skinning them, does not reset the complete rod state. At this pin, ApplySoftBodyCreationSettings requires removal from the physics system before reinitialization; canonical recreation is another baseline. Treat engine replay as a distinct state/membership contract, not as an arbitrary rest-frame editing API. [Body reset contract](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/Body/Body.h).

Preserve semantic guide/segment remaps through preparation and optimization. Extract completed particle positions and rod rotations in the body's current center-of-mass frame, then apply that frame exactly once. Rigid body-origin and COM transforms differ too; test an offset pivot before publishing settled placement transforms. The source, obstacle, basis/origin/scale and binding revisions belong to the immutable result signature. [COM and transform conventions](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Docs/Architecture.md#L315-L358).

Choose world Update or the documented manual CustomUpdate route deliberately, with one owner of stepping and supported locking/lifetime boundaries. A post-step particle projection must also own contact refresh, bounds and velocity/frame consistency; mutable vertex access alone does not qualify it as a safe contact adapter.

## One visible shape across outputs

Build one deterministic CPU reference evaluator for the selected representation, then use its completed geometry for the first viewport, render and Bake experiment. This is an architectural recommendation, not a requirement to eagerly expand every unaffected instance. Prove one explicitly selected production renderer first. No renderer has been selected or qualified by this research packet; record its ClassID, exact build, CPU/GPU mode and adapter version when that experiment is authorized.

Max's GeomObject/render interfaces and render-time instancing facilities provide relevant hooks. They do not automatically give each Scatter placement a distinct deformation through a shared source callback. Mesh ownership, validity intervals, temporary mesh deletion and concurrent reader lifetimes need an explicit adapter design. [GeomObject](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_geom_object.html), [render-time instancing](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/namespace_max_s_d_k_1_1_render_time_instancing.html).

Validate UVs, map channels, material IDs, smoothing/explicit normals, bounds, picking and frozen output. A correct viewport silhouette does not qualify renderer output. Render-time subdivision or displacement requires a stated support boundary.

R11 adds important adapter checks. Max Mesh shallow copies can share channels, and a renderer can attach mutable mesh cache data. Owned numerical snapshots and consumer-specific SDK adapters therefore need separate lifetimes; wrapping a borrowed Mesh in a smart pointer does not make its channels immutable. [Mesh ownership/cache API](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_mesh.html).

Capture a coherent evaluated mesh and transform before traversal, including object offsets, transformed parents and world-space modifiers, to avoid double transformation. [INode evaluation and transforms](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_node.html).

The explicit-normal SDK documentation contains a limited-pipeline-support warning. Treat that as a reason to test the selected custom-object, ordinary-mesh and Bake routes; it does not establish that every current renderer ignores authored normals. Use a visibly non-geometric normal fixture. When baking a reflected transform, permute winding and matching map/normal corner indices together and preserve tangent handedness. [MeshNormalSpec](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_mesh_normal_spec.html).

Picking must use the completed bent geometry and a batch-face to placement/source-face map. Test a bent tip outside its original bounds. Full mesh delivery, exact repeated variants and renderer-proxy export are separate qualification profiles. A proxy conversion command can help prepare an owned source; it is not a generic runtime extraction or arbitrary deformation API.

## Memory and publication

Let A be affected placements and V the render vertices per source. Unique expanded positions alone can scale with A times V, even if the guide state is compact. This is a budgeting observation, not a measured allocation or performance claim. Include shared rest data, preparation, guide state, contact scratch, decoded geometry, old/new publication overlap, renderer copies, GPU buffers and Undo retention in peak accounting.

Exact identical shapes can share a deformed prototype. Approximate shape clustering requires an error budget and contact revalidation at each placement; otherwise a reused variant can intersect a stone. Track variant count and temporal/LOD popping before treating clustering as a solution.

An exact variant key should include source revision, evaluator version, effective local guide pose, normal policy and geometry-affecting options. Confirm equality after a hash match. Batching reduces submission overhead while distinct position/normal arrays still require storage; count geometric positions, split output-stream vertices and faces separately.

Cancellation, stale inputs, allocation failure and owner deletion must retire staged work without late publication. Keep previous complete output available. Readers need generation leases or another proven lifetime mechanism while old results retire. Save/load and Undo should restore coherent authored settings and results without holding an ordinary Undo transaction open across asynchronous work.

For engine reuse, make each update bounded and check cancellation between calls; do not assume a safe abort midway through a running Jolt update. Audit nested scheduling and barrier waits before sharing a host worker pool, including oversubscription and shutdown. Preserve separate outcomes for setup failure, cancellation, engine-capacity errors, unresolved contact and accepted quality. These are proposed adapter obligations, not measured cancellation guarantees.
