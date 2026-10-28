# 08 — Asynchronous publication and lifetime ownership

[Index](00_README.md) · [Max gate](07_MAX_2027_INTEROP_FEASIBILITY.md) · [Failure matrix](11_EDGE_CASE_AND_FAILURE_MATRIX.md)

## This is a new subsystem

**[P]** The current executor joins its copied numerical work before host publication; this establishes no asynchronous GPU lifetime guarantee. **[D]** Introduce an owned snapshot/service boundary before introducing in-flight GPU work. Preserve the authoritative static semantics: each request solves the requested geometry from authored rest. A previous pose may propose an initial search direction only if it is revalidated and cannot change the final acceptance contract; initially disable warm starts to isolate parity. [PROJ02](17_SOURCE_LEDGER.md#proj02)

## Keys, ownership and states

**[D]** Every job carries a complete key:

```text
JobKey = (documentEpoch, ownerLifetimeToken, requestedGeneration,
          placementRevision, sourceFingerprints, bindingRevision,
          colliderGeometryRevisions, colliderTransformRevision,
          contactSettingsRevision, exclusionSettingsRevision,
          unitFrameRevision, evaluatorVersion, precisionQualityMode,
          deviceEpoch, backendBuildId)
```

The key has exact dependency content; a single sequence number does not make incompatible source arrays safe. `ownerLifetimeToken` is an owned weak identity or registry token, never a dangling `INode*`. Host code resolves it only when publishing. A GPU offset is valid solely with the allocation generation and source revision that created it. A scene Undo can restore authored values while still creating a new epoch/generation, so a completion from the pre-Undo world never aliases the restored state accidentally.

| Resource | Owner | Allowed readers/writers | Retirement condition |
|---|---|---|---|
| Captured geometry/transforms/settings | Immutable job snapshot with shared source references | Numerical CPU workers; upload staging | All queued jobs, readers and transfer fences released |
| Prepared CPU source/BVH | Revision-keyed cache | Read-only numerical jobs | No snapshot/renderer references; budget eviction |
| Compute buffers and command state | Backend service plus device epoch | Backend queue; explicitly granted graphics/readback consumer | GPU completion, graphics ownership returned, CPU callbacks drained |
| Upload/readback staging | Bounded pool | Producer until submitted, GPU during transfer, consumer after completion | Transfer fence and consumer release |
| Accepted canonical result | Publication owner / immutable snapshot | Viewport, renderer, Bake, export and audit | All consumers release; host destruction where required |
| Retained Max handles | Host graphics adapter | Supported Max callbacks under qualified contract | Host/device reset rules; never worker deletion by accident |
| Code/DLL and callback targets | Service lifetime lease | Workers, callbacks and renderer readers | Every call and completion drained before module unload |

Epoch checks suppress stale **publication**; they do not cancel GPU memory access or prevent code unloading under a worker. Both ownership and keys are mandatory.

## Event-to-present timeline

```mermaid
sequenceDiagram
  participant H as Host
  participant Q as Scheduler
  participant G as GPU queue
  participant V as Validator
  participant D as Display
  H->>Q: Owned request generation 41
  Q->>G: Bounded batch for 41
  H->>Q: Replace pending with generation 42
  G-->>Q: 41 complete; retire without publication
  Q->>G: Admit and dispatch 42 from rest
  G-->>V: Completed pose and diagnostic buffers
  V-->>H: Complete valid successor for 42
  H->>H: Recheck full key and owner lifetime
  H->>D: Atomically swap pose, visibility, bounds, picking
  D-->>H: Presented frame attribution
```

**[D]** Keep at most one in-flight generation and one replaceable pending CPU request for the first implementation. Double-buffer accepted/work outputs; a third slot is justified only when a graphics/render reader still holds the former accepted buffer. The pending request initially contains compact immutable deltas and references, not another full deformed mesh. Resource reservations account for all three slots before admission.

Long-running renderer readers can pin multiple older results even with only one compute job. Therefore cap retained backing pages/slots explicitly. If all admitted slots are pinned, coalesce the pending request and apply backpressure; never allocate a hidden fourth generation or overwrite reader-held memory. Separate CPU canonical render leases from GPU display-buffer leases where that allows safe earlier GPU retirement.

Pointer events are coalesced to the newest target state, while **cumulative invalidation is merged rather than replaced**. Keep the union of dirty collider/owner IDs, deletion tombstones, old/new influence regions and restoration dependencies since the last accepted baseline. Replace each edited object's target transform/settings with its latest value. A move of collider A followed by a move of collider B must still process both neighborhoods, including A's previous influence. Retire a dirty entry only when a successfully published successor covers that entry's revision; preserve edits arriving later. If the bounded dirty representation overflows, conservatively mark a larger region or the full owner set dirty and admit bounded work, rather than dropping invalidations. Add an A-move/B-move/A-delete test before any completion to the fake-backend suite.

Already submitted GPU work may still complete; cancellation means stop scheduling the next bounded batch and discard obsolete results. Do not promise immediate cancellation of an arbitrary kernel or free its buffers early. Local engineers must measure the maximum batch execution and cancellation-to-idle latency on the display GPU.

### Prevent starvation without publishing stale geometry

Under continuous fast input, strict newest-only publication can keep rejecting completions. Do not quietly publish an outdated obstacle pose. Coalesce before starting work, bound batch duration, reduce dispatch frequency, or show a separately labeled approximate preview tied to its own collider transform. On release, queue an exact final request and wait asynchronously. A stale result may remain visible as the **last complete** state with a visible stale indicator; it is not the successor for the current stone.

## Atomicity, chunks and root restoration

**[D]** Chunk independent numerical work to bound scratch; stage deltas privately until the entire request passes. Publication swaps one immutable descriptor containing pose pages, hidden-root masks, source references, material bindings, bounds, picking data and diagnostics. Failure of one required chunk leaves the previous accepted publication. Per-owner atomicity is a later explicit product choice, not an accidental mix of generations.

A moving-away or deleted collider must invalidate the union of old/new influence **and previous affected owners**. Re-evaluate affected roots from current exclusion settings; reuse exact rest geometry when no constraints remain. Do not preserve a deformed guide merely because no new collider candidate was found. Spatial restoration removes sparse pose records; it does not copy and rebind all vegetation.

## Invalidation and persistence table

| Event | Invalidates | Does not inherently invalidate | Required action |
|---|---|---|---|
| Collider translation/rotation/positive uniform scale | Collider instance query transform, local influence and dependent fit | Shared closed-mesh geometry/BLAS | Old/new plus prior contacts; recompute local gap and scale |
| Collider topology/vertices | Collider asset/BVH/field and dependent fits | Other collider assets | New fingerprint; bounded rebuild; retain old accepted publication meanwhile |
| Source geometry/preparation edit | Source buffers, guides/bindings if affected, all dependent poses | Other sources | Increment revision; old buffers pinned for old readers; no cross-revision pose reuse |
| Contact gap/root-mode/quality change | Fits and final validation | Placement population | Explicit fit generation |
| Hide settings | Root classification and dependent visibility; potentially fit feasibility | Source extraction | Reclassify whole rooted groups, keeping gap independent |
| Undo/Redo | Request generation and affected authored dependencies | Immutable identical assets can remain cached | New key; never revive a stale completion by numeric revision reuse |
| Units/frame conversion change | All numerical snapshots/poses and transformed caches | Source authored scene data | Invalidate unit key; recapture/rebase; no scaled stale result |
| Owner/instance delete | Matching job/publication eligibility and index membership | Other owners | Lifetime token tombstone; drain callbacks without SDK access |
| Scene reset/load | Document epoch, host references and jobs | Device kernel cache may survive if independent | Cancel/drain; reconstruct transient caches from persistent authored data |
| Wireframe/F3, camera, UI browsing | Draw style/view-specific state only | Static fitting and unchanged source/pose uploads | Zero solve/unchanged-upload counters |
| Unrelated timeline scrub | Nothing in a static interaction layer | Static poses | No implicit time-stepping; changed animated collider evaluated separately if explicitly supported |
| Graphics device recreation | Graphics handles, interop registrations, device epoch | Canonical CPU poses | Recreate through supported host path, reupload accepted result |

Persist authored source IDs/fingerprints, bindings/settings and explicitly chosen portable pose data only. Exclude GPU addresses, OS shared handles, fences, allocator state, CUDA/OpenCL contexts and transient kernel binaries from the scene. An on-disk optimization cache has its own versioned/rebuildable key and eviction policy; it is not authoritative scene content.

## Failures and recovery

**[V]** Windows WDDM TDR includes a default two-second preemption timeout; this is not an acceptable interactive kernel budget. Microsoft reserves TDR registry changes for targeted driver testing and says applications/end users should not use them as a normal remedy. [SYS01](17_SOURCE_LEDGER.md#sys01) [SYS02](17_SOURCE_LEDGER.md#sys02)

**[D]** Set an initial proposed per-dispatch target of 1–2 ms on the qualified display GPU, measure outliers, and split adaptive traversal/iteration batches. This is a hypothesis to validate, not a hard real-time promise. Iteration/query caps and admission limits give deterministic work bounds; wall-clock bounds still require hardware qualification. Never recommend increasing `TdrDelay` to make the feature usable.

| Failure | Proposed response |
|---|---|
| VRAM admission/allocation failure | No partial dispatch/publication; retire completed scratch; retry bounded CPU route or explicit smaller scope; report required/available bytes |
| Device removed/reset/hung, driver restart | Mark device epoch invalid; stop submissions; retain CPU accepted result; rebuild host display via supported reset path; disable compute until re-probed |
| Kernel/queue/event failure | Record stage, stable IDs, backend/error code; reject successor; do not trust buffers containing partial writes |
| Readback/surface validation incomplete | Keep accepted result; report pending/failed validation; no final convergence flag |
| Context or adapter mismatch | Select compact readback path or CPU, not cross-adapter zero-copy assumptions |
| Unsupported/headless/remote device | CPU path remains available; graphics bridge disabled independently of CPU feature |
| Renderer using much of VRAM | Recompute admission/headroom; throttle or suspend interactive compute; never evict renderer allocations owned by another subsystem |
| Fragmentation despite nominal free memory | Size-class pools, bounded large allocation test, retire fences, reduce scratch chunk size; no unbounded allocation retry |
| Shutdown or plugin unload | Revoke publication and stop submission; workers finish into detached owned completion records; drain success/error paths without waiting for callbacks that need the blocked host thread; destroy host-owned objects while their lifecycle callbacks remain available |

DXGI defines distinct removal/reset/hung error categories; log the actual error rather than treating all as ordinary no-memory conditions. After device loss, use the API's error/teardown path rather than waiting indefinitely for a normal completion fence. Dynamic process video-memory budget and usage are available through `IDXGIAdapter3::QueryVideoMemoryInfo`; exceeding a process budget can cause paging/stutter even when the board's advertised VRAM seems adequate. Both are Windows facts, not proof Max exposes every required adapter object to the plugin. [SYS03](17_SOURCE_LEDGER.md#sys03) [SYS14](17_SOURCE_LEDGER.md#sys14)

## Explicit memory ceiling

**[E/D]** Let `B_shared` be immutable source/collider data, `B_accept` accepted sparse poses, `B_work` next poses, `B_retired` old poses held by readers, `B_scratch`, `B_staging`, `B_hostMirror`, and `B_graphics`. Admission uses their simultaneous peak, plus measured allocator overhead and reserved Max/renderer headroom. Triple buffering does not mean only three pointer-sized descriptors: all referenced backing allocations count. Never drop `B_retired` until the last graphics/renderer fence/reference releases. The numeric scenarios in [09](09_MEMORY_PRECISION_AND_HARDWARE.md) demonstrate why all-active dense jobs require a different admission from sparse drag.
