# 08 — Asynchrony, publication and resource lifetimes

[Contents](00_README.md) · [Interop](07_MAX_2027_INTEROP_FEASIBILITY.md) · [Failure matrix](11_EDGE_CASE_AND_FAILURE_MATRIX.md)

**P.** This is a new subsystem. The supplied synchronous executor does not establish any of these guarantees. Concurrency should be introduced around a frozen CPU evaluator before introducing a new collision algorithm.

## Ownership contract

| Object | Owner | Who may read it | Release condition |
|---|---|---|---|
| Live Max nodes/references/materials | Host adapter | Approved host callbacks only | Host SDK rules; workers never retain raw scene pointers |
| Immutable source/collider numeric snapshot | Versioned CPU cache | Worker, validation, rendering lease | No jobs/results/Undo leases refer to that generation |
| GPU source/BVH/field buffers | Per-device backend generation | Its command streams and completed draw snapshots | All referencing compute and graphics work complete |
| Job input and result pages | Scheduler job | Exactly named compute/CPU stages | Completion/cancellation retirement, not user cancellation alone |
| Published pose/visibility/bounds | Host publication owner | Draw and renderer readers by immutable lease | Replaced and all readers/fences retired |
| Graphics handles | Max display adapter on approved thread | Retained draw path | Max lifecycle plus last graphics use; never infer ownership from raw pointer availability |
| Compiler modules/pools | Optional backend service | Jobs of that backend/device generation | All modules' work retired; bounded cache eviction |

The CPU scene is authoritative. Portable persistence contains source identities/revisions, prepared data or rebuild recipes, settings, placement IDs and optionally versioned CPU pose results. It contains no CUDA pointer, D3D handle, OS sharing handle, device ordinal, stream, fence, allocator state or compiled binary assumption. Reopening selects devices and reconstructs caches.

## Revisions and completion types

A job token includes `scene_epoch`, owner generation, `base_publication_sequence`, published layout revision, relevant source/binding revisions, relevant collider geometry/pose revisions, contact/exclusion settings revision, units/frame revision, evaluator/quality revision and backend/device generation. Include only dependencies actually used; unrelated animation or camera revisions must not invalidate static work. A binding fingerprint change invalidates the bind and its pose data, not just its vertex upload.

Return a tagged result:

```text
CompleteValidated(token, pose_delta, visibility_delta, bounds, diagnostics)
CompleteApproximate(token, pose_delta, error_contract, refinement_needed)
Incomplete(token, reason, counts, last_finished_stage)
Cancelled(token)
Unsupported(token, capability_reason)
DeviceFailed(token, device_generation, error)
```

`CompleteApproximate` is not a final success. Initially, only `CompleteValidated` replaces the production authoritative snapshot. If an explicitly enabled interactive preview is later shipped, maintain a separate preview lease/status; renderer, Bake and save use the validated publication. Never silently promote the preview after mouse release.

## Event-to-result timeline

```mermaid
sequenceDiagram
    participant H as Host
    participant S as Scheduler
    participant G as GPU service
    participant D as Draw readers
    H->>S: Snapshot revision r, bounded plan
    S->>G: Upload deltas and submit chunk r
    H->>S: New pointer event revision r+1
    S->>S: Coalesce pending input; mark r superseded
    G-->>S: Chunk r fence completes
    S->>G: Submit newest job r+1
    G-->>S: Poses, counts and completion
    S->>S: Validate complete successor
    S-->>H: Ready token r+1
    H->>H: Verify dependencies and publish atomically
    H->>D: New immutable draw snapshot
    D-->>S: Previous reader and graphics work retired
```

The real implementation may overlap independent work, but the dependency order is mandatory. No scene SDK work occurs in GPU callbacks. Completion callbacks enqueue a host message; they do not publish directly. Progress notifications have bounded frequency.

### Coalescing and cancellation

Allow one newest pending input per owner and a fixed maximum in-flight generation count. New pointer events replace pending desired input; they do not append unbounded jobs. Retain the union of dirty collider/setting identities since the last validated publication, and recompute from that published baseline to the newest desired transforms. Replacing pending B must not forget an unpublished edit to A. Unpublished intermediate positions need not produce persistent bends or a swept corridor; if an interactive preview exists, it has a separate lease and invalidation policy. Already submitted GPU commands generally cannot be cheaply withdrawn. Stop future chunks, retain their allocations until completion, and discard stale output. Do not release a buffer because a cancellation flag changed.

Chunk by estimated worst-case contact/iteration work and measured completion time. A cancellation counter is sampled between bounded dispatches; optional in-kernel cooperative cancellation may skip writes but must still reach all required workgroup barriers. Never return early in only some lanes before a barrier. Avoid long kernels that wait on host updates.

Compare final revision tokens again on the host immediately before publication. For full-map replacement, require `base_publication_sequence` to equal the current publication sequence; otherwise requeue against that base. A separately designed disjoint-delta merge can revalidate and rebase, but relevant-only scene tokens do not alone prevent an old full-map copy from overwriting a newer unrelated publication. Undo/Redo increments a monotonic epoch even if the scene returns to numerically identical geometry; this prevents ABA reuse of an old request. Deleted/recreated stable IDs have a new owner generation. Source replacement, unit changes, file load/reset and shutdown invalidate relevant jobs before any potentially recycled identity can be accepted.

“Retain the last complete result” applies only while that publication remains compatible with the current scene/owner lifetime and source contract. Deletion, reset or an incompatible source replacement cannot resurrect an old result. A device-only failure can retain valid CPU data while rebuilding display; an invalidated owner with no compatible result instead reports pending/unavailable according to the host policy.

## Two versus three buffers

**P.** Start with two mutable generation slots and a single pending host snapshot, with backpressure when the next slot cannot be retired. Distinguish a logical slot from total live physical pages. Immutable source/rest data is shared. If the old draw generation, new publication and in-flight successor all coexist, three pose generations may be live despite a UI description of double buffering.

For mutable pose bytes `B`, a naïve double copy is `2B`; published + in-flight + awaiting graphics retirement can be `3B`, plus CPU mirrors, upload/readback staging and scratch. Sparse copy-on-write pages reduce duplication only for unchanged pages. Maximum resident bytes are computed from reference counts before submission; a third generation is not allocated as an emergency surprise.

A renderer can keep a lease longer than a viewport frame. Its request must not pin unbounded GPU generations. Prefer CPU immutable poses for final geometry and bounded CPU mesh caches, while GPU pages retire after display completion. Existing whole-map successor copies should be measured and may be replaced by persistent/chunked maps if they dominate; that optimization is independent of CUDA.

## Synchronization and graphics boundaries

A CUDA/OpenCL completion event orders compute and readback on its queues; it is not automatically a Max draw fence. A graphics interop map/unmap, keyed mutex, or imported semaphore only applies when the exact supported resource pathway has been proven. Raw `ID3D11Device*` access alone does not supply a safe owner/thread policy.

For the initial supported-upload route, finish CPU-visible poses, validate, then publish via existing Max handle mechanisms. Draw reads completed handles only. Never block inside `Display` waiting for a solver or hold a host/UI lock while waiting for the GPU. D3D query `GetData` is asynchronous status reporting and, when used, is subject to immediate-context rules; polling it is not permission to seize Max's context. [R14](17_SOURCE_LEDGER.md#r14)

Selection, F3/Wireframe, material viewport mode and camera changes may select different retained streams or draw states. They must not refit guides, recapture colliders or upload unchanged pose pages. View-dependent LOD, if later offered, uses a separate display revision and explicit picking/render parity policy.

## Failure and recovery

| Event | Required action |
|---|---|
| Query/contact budget overflow or nonfinite data | Mark incomplete, preserve preceding complete pose/visibility/bounds; identify object and stage |
| VRAM admission failure | Decline before submission; evict unused caches, reduce bounded batch size or route whole job to CPU; never drop arbitrary guides |
| Allocation failure after admission | Clean up acquired resources by lifetime state; preserve result; report actual requested/available budget |
| Kernel/runtime failure | Quarantine backend generation; discard unpublished outputs; route subsequent work to CPU if admitted |
| Device loss/reset/recreation | Invalidate all device-generation handles/registrations; retain CPU snapshot; rebuild display and compute resources only through supported callbacks |
| TDR | Recover through host/device lifecycle; bounded work design must avoid it; do not instruct users to disable timeout protection |
| Rendering starts on same GPU | Re-evaluate process budget and contention; pause/lower-priority fit submissions or CPU-route according to measured policy |
| Headless/remote session | Query capabilities anew; no assumption that the interactive display adapter or interop route exists |
| Shutdown/reset | Reject publication, drain or retire bounded jobs, unregister only after dependent resources are idle; explicit timeout/error path without use-after-free |

Windows normally uses a two-second TDR preemption timeout; this is a recovery threshold, not an acceptable interactive kernel budget. Microsoft says applications should not manipulate TDR registry keys outside targeted driver-development testing. Proposed chunks target a few milliseconds at most, with the actual cap established on the slowest admitted device and worst fixtures. [R03](17_SOURCE_LEDGER.md#r03) [R04](17_SOURCE_LEDGER.md#r04)

On GPU loss the last complete **CPU result** remains available, but the former GPU image may itself be invalid. Recreate retained display resources or materialize a CPU fallback through the supported host path. Do not promise that lost VRAM can continue drawing unchanged.

## Artist-visible states

Expose `Ready`, `Updating`, `Preview—refining` only if that mode exists, `Previous result retained—reason`, and `CPU fallback—reason`. A stale previous result is visibly labelled after a failed successor. Show aggregate affected plants/guides, hidden rooted groups and the principal error; offer a diagnostic selection of affected IDs. Do not show successful completion when only the compute kernel finished and validation/publication remains pending.

The [fault matrix](11_EDGE_CASE_AND_FAILURE_MATRIX.md), [prototype specifications](14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md) and [acceptance checklist](18_ACCEPTANCE_CHECKLIST.md) turn these rules into reproducible tests.
