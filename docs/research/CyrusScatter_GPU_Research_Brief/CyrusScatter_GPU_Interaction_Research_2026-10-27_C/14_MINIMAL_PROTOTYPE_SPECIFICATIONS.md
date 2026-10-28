# 14 — Small prototypes that decide the architecture

[Contents](00_README.md) · [Phases](13_PHASED_IMPLEMENTATION_PLAN.md) · [Benchmarks](10_BENCHMARK_AND_VALIDATION_PLAN.md) · [Local probes](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md)

**All P0–P5 below are proposed and not executed.** Only X01–X10 in the optional Python file ran here. No working GPU kernel, Max plugin or replacement CPU fitter is delivered by this research.

The purpose is to answer a decision with a small isolated experiment, then stop or proceed. Use a test plugin/profile and standalone tools; production code changes remain the local team's separate authorization. Each prototype keeps a versioned source/pose packet so later backend comparisons reuse identical bytes.

## P0 — Find the real CPU critical path

**Owner:** numerical core plus host/display adapter engineers. **Input:** current release, actual G451 source, one independently edited collider, frozen layout and edit trace. **Output:** stage trace, active counts and byte/memory ledger with exact source/evaluator fingerprints.

Add bounded native counters around host capture, old/new spatial queries, retained-map copying, root classification, per-guide fitting, full visible-surface audit, frame construction, vertex/normal evaluation, unique-mesh assembly, uploads and host publication. Record unchanged-guide reuse and number of actual changed descendants. Do not move large coordination loops into MAXScript to collect telemetry.

Run B05/B06 plus the same active patch at N=1k, 10k, 100k and 1M if admitted. Capture pointer-received-to-first-result-presented as well as native-stage times. Hold the collider still, change camera/selection/F3 and verify zero new static solve and unchanged buffer upload counters. Compare several retained-pose populations D at fixed new K to expose whole-map copy cost.

**Pass:** all work populations and hidden copies are accounted for, correctness reference is replayable, and one stage has sufficient measured cost to justify a proposed optimization. **Stop:** there is no material arithmetic bottleneck, or latency is dominated by capture/maps/publication/drawing. Optimize that CPU/display boundary before CUDA. **Budget:** existing admissions unchanged; telemetry buffers ring-bounded with overflow reporting. No performance result is asserted here.

## P1 — Shared ribbon plus CPU pose, no external compute

**Owner:** display engineer with numerical evaluator owner. **Input:** the included R8 ribbon and the two prescribed proof poses below, then R33, authored twist, LEAF, BR63 and local G451. **Output:** supported HLSL path with CPU/GPU evaluator comparison and immutable pose/visibility revision IDs.

**Proof-pose recipe — proposed, not evaluated here.** For each `alpha ∈ {+π/3, −π/3}`, let `c0=(0,0,0)` and, for spans `j=0…6`, `theta_j=alpha*j/6`, `c[j+1]=c[j]+0.1*(sin(theta_j),cos(theta_j),0)`. Thus each span remains 0.1 m and the first span/root orientation stays at rest. At node `i=0…7`, rotate the frozen rest material frame about world +Z by `−alpha*max(0,i−1)/6`; use the evaluator's declared interpolation between node frames. Bind each ribbon ring to its matching guide node and preserve its signed transverse rest offset. Serialize the resulting frames/positions in the agreed layout, hash the packet, and use identical bytes on CPU/GPU. These imposed poses test delivery, not collision solving; no obstacle clearance is claimed. Additional UV/normal/binding channels must be created and fingerprinted locally, since X10 contains geometry/root indices only.

Sequence:

1. Freeze the CPU evaluator's material frame, binding interpolation, rest restoration and normal/tangent policy.
2. Upload one shared source vertex/index/binding definition. Pack two deliberately different pose pages plus rest sentinel and hidden-root cases.
3. Try public `SetBufferParameter`; try public texture lookup if buffer format/stage support fails. Keep tiny constant arrays only as a control, not the production population model.
4. Draw two instances, then 100, with stable IDs independent of batch sorting. Do not solve in `Display`/`Realize`.
5. Compare CPU positions, roots, sockets, normals/tangents and per-face material/UV identities. Include UV seams, fixed parts and hidden groups.
   Reserve delivery error within the final-surface clearance budget from [09](09_MEMORY_PRECISION_AND_HARDWARE.md); passing separate contact and parity ceilings is insufficient if their errors add.
6. Publish conservative item-local bounds before culling; test a bent leaf outside its rest box. Test stable per-instance picking after compaction, not just render-node hit detection.
7. Switch shaded/Wireframe views, camera and selection without changing poses. Observe no static refit or unchanged pose upload.

**Pass:** declared [numerical tolerances](09_MEMORY_PRECISION_AND_HARDWARE.md), exact visibility/material/identity semantics and correct culling/picking; no private APIs. Measure shader draw overhead across multiple views/passes and saved CPU/upload/memory cost. **Reject default adoption:** parity fails or repeated static draw costs exceed the savings. **Budget:** start ≤100 instances, bounded pose pages ≤16 MiB as a proposed lab cap; grow only after actual stride/capability proof. This cap is a prototype limit, not a hardware requirement.

## P2 — Interop in four separate layers

This adopts I0–I3 from [chapter 07](07_MAX_2027_INTEROP_FEASIBILITY.md). It does not duplicate the full source/API table.

| Proof | Small operation | Required evidence | Decision |
|---|---|---|---|
| I0 standalone compute | Transform/evaluate 256 eight-node ribbons with an owned packet | CPU parity, status, completed transfer/kernel timings, device/driver/compiler identity, clean missing-device path | Is compute deployment/numerics viable independently of Max? |
| I1 standalone D3D11 sharing | Owned buffer with known integer ID pattern and float vertex output; double generation handoff | Resource creation descriptors, same adapter, register/map or import/semaphore sequence, no simultaneous access, 10k retire cycles | Does the chosen API/driver sharing mechanism work in an owned app? |
| I2a public Max HLSL | P1 CPU-pose upload path | Supported buffer/texture lookup and retained draw lifecycle | Is the useful fallback viable? |
| I2b native Max bridge | Read-only native D3D interface acquisition, then one plugin-owned resource through a documented draw/consumption path | Exact installed SDK declarations/sample basis, device LUID identity, context/COM ownership, completion and recreation behavior | Is direct compute sharing or D3D11 compute inside this host supportable? |
| I3 renderer/Bake | P5 output at same source/pose revision | Correct final materialized geometry and ownership | Can the user receive consistent production output? |

A successful standalone sample cannot satisfy I2. An `ID3D11Device*` getter cannot satisfy the resource, context and retirement portions. If I2b requires private casts, host-context takeover or undocumented retained-buffer ownership, close that route. Use compact CPU readback plus P1 public uploads; compare its complete cost before investing further.

**Ownership test:** two viewport readers, one in-flight compute result and one deletion/recreation event. Delay each completion in turn; no live reader may see overwritten bytes, and no old-generation result may publish after device/scene epoch change. **Budget:** two data slots plus explicit retired pages; refuse allocation of an unbudgeted third payload. Never use an infinite keyed-mutex wait from a sample inside the host.

## P3 — Matched static fitting on a narrow admitted profile

**Owner:** numerical/GPU engineer. **Input:** prepared independent R8/R33 guides, fixed roots/material frames, positive uniform transforms, analytic spheres and rigid boxes, Contact gap and independent exclusion settings. **Output:** complete CPU-readable guide poses and diagnostics, not viewport pixels.

Define one static objective and stopping rule. Start from rest for each edit; add warm starts only after cold/warm/path-order equivalence is quantified. Reuse exact analytic controls for segment parameter, witness, outward normal, signed gap and root containment. Initially exclude branch force feedback, self-collision and arbitrary open/deforming collider solids. Add closed mesh BVHs only after analytic completeness passes; fields are a later separate error profile.

Implement the same equations and order policy in CPU, CUDA and OpenCL. Compare node/Jacobi versus colored guide scheduling as explicit algorithm variants. Each query has count/work/depth limits and an incomplete flag that cannot be read as clear. Return all errors even if no contact was appended. No follower-blade omission or solver-driven hiding is allowed.

Mandatory fixtures: endpoints outside while a span crosses; entire span inside; visible fixed root inside gap but outside exclusion; two stones; narrow gap below blade width; broad leaf collision with clear centerline; sharp corner; zero span/NaN; local scale and 1e6 m origin; contact budget and cancellation. The actual broad-leaf surface remains CPU-validated or conservatively certified with complete fallback.

**Pass:** all admitted fixtures meet invariants and completeness; all rejected cases return honest status; the candidate beats complete CPU route p95 by the proposed 20% margin in a measured large-work bin, including compact pose readback/validation/Max upload. Keep tiny neighborhoods on CPU when they do not cross over. **Stop:** no admitted large-work bin wins end to end, validation erases the benefit, or comparable quality needs a complex general simulation engine. Keep CPU and any independently qualified P1 drawing improvement.

**Proposed initial lab bounds:** 256 guides × at most 33 nodes, eight obstacles, 100k pair work items and a 64 MiB scratch ceiling. These are experiment caps, not existing product admissions or supported library limits. Exceeding any returns incomplete; increase one cap at a time with memory/time evidence.

## P4 — Latest complete successor under races and failure

**Owner:** async scheduler/host engineer. **Input:** CPU reference jobs first, then identical GPU packets. **Output:** deterministic event log proving state/ownership, with injected delays/failures and allocation counters.

The minimal sequence is deliberately adversarial:

```text
publish P0
edit collider A -> request r1(base=P0), delay its worker
edit collider B -> r2 includes unpublished dirty A and B
finish r2 -> publish P1
finish r1 -> reject stale base/token, never overwrite P1
Undo -> new scene/contact epoch even if numeric transforms match
delete/recreate owner, replace source, change units, reset file
finish all old requests -> none publish
cancel before/after count, during bounded dispatch, before commit
hold a draw/renderer lease while replacing result -> retire only after use
inject allocation/device/compile failures -> keep last still-applicable CPU publication
```

Also test dirty-A then dirty-B when neither job has published, and edit A again back to its last-published transform. Coalescing preserves the desired latest state and required restoration, without retaining unwanted simulation history. A full-map successor checks `base_publication_sequence`; disjoint-delta rebasing is a separately specified optimization.

Retention is scoped to the current scene/owner lifetime and compatible source contract. Undo, deletion, source replacement or scene reset can make P1 inapplicable; never resurrect it after that invalidation. A device-only failure can rebuild display from still-valid canonical CPU data. If no compatible complete result exists, display the explicit pending/unavailable state under the host's documented policy.

**Pass:** zero stale commits, use-after-free, partial visibility publications or uncapped queued generations across 10k synthetic edit/retirement cycles; all allocation ledgers return to their expected retained baseline. No claim of reliability probability follows from that count. **Stop:** lifecycle cannot be expressed with owned numeric snapshots and approved host callbacks. Keep synchronous publication until fixed.

GPU device-loss tests belong in a disposable local profile. Prefer injectable backend failure first; do not provoke TDR on a user's working scene or disable TDR. Verify recovery after actual host graphics recreation separately. Last-good CPU data survives; lost GPU handles must be rebuilt.

## P5 — Production geometry, persistence and distribution

**Owner:** host/render integration plus release engineer. **Input:** one source with seams/custom normals/multiple materials, a branch attachment, broad leaf, fixed part, hidden group and unique posed instances. **Output:** viewport, renderer, Bake and exported geometry comparisons at the same accepted revision.

Run the production renderer selected locally; record its exact version. Test rest and posed assets, different instance scales, renderer cancellation, rendering during an update, off-screen instances, save/reopen, copy/merge/Undo, source edit invalidation and a machine with no optional compute backend. Verify correct material IDs, UV channels, normals/tangents, transforms, hidden-group counts, topology and ownership/deletion. Do not export rest geometry because no viewport buffer exists.

Inspect plugin import tables and lazy loading: absent CUDA/OpenCL driver/runtime must leave the CPU plugin loadable. Record actual redistributed files, licenses, hashes and signature checks; exercise corrupt/incompatible compile cache, driver changes, insufficient VRAM and device mismatch. GPU pointers and compiled handles must not appear in portable scene data.

**Pass:** exact semantic channel/identity agreement plus declared numerical tolerances, successful CPU fallback and clean failure retention. **Reject release:** any required renderer/Bake path depends on a volatile viewport-only buffer or silent approximate/incomplete result.

## Proposed interface sketch

This is a design sketch, **not a frozen header or compiled implementation**:

```cpp
// Numeric packets have explicit strides, source IDs, units and revisions.
// Opaque backend handles never enter the scene file.
struct JobToken { SceneEpoch scene; PublicationSeq base; DependencySet used; };
struct WorkPlan { Counts counts; ByteBudget memory; WorkBudget queries; };
Status prepare_sources(OwnedImmutableSourcePacket, SourceGeneration*);
Status submit(JobToken, OwnedJobPacket, WorkPlan, JobHandle*);
PollResult poll(JobHandle); // Pending, CompleteValidated/NeedsValidation, Failed
void cancel_future_chunks(JobHandle); // not permission to free in-flight buffers
Status read_completed_pose(JobHandle, CallerOwnedPoseBuffer);
void retire(JobHandle, CompletionDependencies);
```

For the initial GPU route, a backend cannot self-certify `CompleteValidated` until the authoritative surface validator has completed. The host owns the final status transition and dependency check. Prototype interfaces use plain data/explicit release functions across DLL boundaries, with version/size negotiation and no STL/CRT allocation transfer by accident.
