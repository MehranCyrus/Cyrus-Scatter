# Asynchronous execution, publication, and resource lifetime

**Status: P. The current interaction executor is synchronous. This document specifies a new subsystem, not existing guarantees of a GPU implementation.**

## Ownership must be explicit

| Owner | Owns | Must not do |
|---|---|---|
| Max host thread/controller | Scene references, authored settings, capture, Undo, SDK render-item publication | Wait indefinitely for a device or let workers call scene APIs |
| Immutable CPU source/layout snapshot | Copied numeric data, stable identity mapping, source/collider revisions | Borrow mutable mesh or node memory from Max |
| Compute service | Device context/streams, admitted work, scratch and completion events | Publish directly to a deleted controller or manipulate Max UI |
| Published interaction generation | Complete poses/masks/status and matching draw references | Mutate buffers that a draw or renderer is still reading |
| Retire queue | Superseded allocations until all compute/graphics/CPU readers finish | Free a mapped/in-flight resource simply because its request became stale |

Separate borrowed host interfaces, owned SDK handles, owned COM references, CUDA/OpenCL objects, and CPU snapshots. Define destruction order and failure handling in code before adding concurrency.

## Revision key

Every work packet should carry a controller lifetime token, scene epoch, layout/source/preparation/collider revisions, unit/transform policy version, interaction settings revision, target transform revision, and device epoch. Stable instance IDs map through the captured layout, not current mutable selection/list indices.

Semantic changes such as new geometry, changed hide mode, edited guides, Undo or scene reset invalidate incompatible jobs completely. An old transform sample may remain a coherent preview only under the explicit interactive policy below; it must never be accepted against different source or settings revisions.

## Proposed state machine

```text
Captured -> Admitted -> Submitted -> Completed -> Validated -> Published
              |            |             |            |
          Rejected      Superseded      Failed       Stale
              +------------+-------------+------------+
                          -> Retired after reader completion
```

Submission captures immutable data and reserves peak memory. Completion means the device finished, not that the result is usable. Validation checks finite values, status/completeness, offsets, visibility ownership, bounds and current semantic revisions. Host publication swaps a complete successor. Failure retains the previous complete result and exposes a useful status.

## Coalescing without starvation

Do not queue every mouse event. Keep one admitted in-flight batch and one replaceable latest target, with bounded scratch/retained generations. Coalesce additional input into the pending target. Kernels already submitted are not generally cancellable instantly; mark them superseded and retire safely after their completion event.

There are two possible preview policies:

- **Strict latest:** discard every transform sample that is no longer latest. Simple, but continuous fast dragging can prevent any result from appearing.
- **Bounded-lag coherent preview:** publish monotonically newer completed transform samples within a declared age budget, while always scheduling the newest pending target. Source/settings/scene epochs must still match exactly. On mouse release, require the exact final target.

The second is a better candidate for fluid interaction, but it needs a product-visible pending indication and metrics for result age. A collider owned by our retained draw path should display the matching published transform together with its vegetation, optionally showing the authored target as a temporary ghost. An external ordinary Max node moves independently; we cannot claim atomic publication of that node and our vegetation. Its preview may temporarily lag, and this limitation must be explicit.

Do not use a stale-fit buffer with a new instance transform and label the combination one complete generation. Root-group masks, pose indirection, bounds and collider sample identity must travel together.

## Buffer reuse and synchronization

Use a small ring or page generations with explicit ownership states. A slot is reusable only after compute and graphics readers have finished. Double buffering is not automatically enough when several frames and compute batches are in flight. Prefer an admitted maximum and backpressure/coalescing over unbounded extra allocations.

For classic CUDA sharing, map/unmap defines ownership transfer; do not issue graphics reads during the mapping. For OpenCL sharing, acquire/release plus the required event/queue ordering plays the corresponding role. External-memory/fence APIs have a different protocol and must not be mixed casually with classic map/unmap assumptions. [CUDA interoperability rules](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/graphics-interop.html).

Raw D3D11 immediate-context access needs external serialization and a host-supported callback. Avoid worker calls into the Max immediate context. DXGI work can interact with the UI message thread, making blocking synchronization particularly risky. [Microsoft D3D11 threading](https://learn.microsoft.com/en-us/windows/win32/direct3d11/overviews-direct3d-11-render-multi-thread-intro), [DXGI best practices](https://learn.microsoft.com/en-us/windows/win32/direct3darticles/dxgi-best-practices).

Poll completion with nonblocking event queries from a bounded host service point or signal a host-owned completion queue. Do not busy-spin on the main thread or call a global device synchronization for every input event. Per-batch status/readback should be compact and versioned.

## Undo, deletion and reset

GPU results are derived caches. Undo records authored settings/transforms/preparation, not device pointers or a huge GPU vertex dump. Undo/Redo increments the relevant epoch and recomputes/reuses matching immutable data. A scene reset invalidates all owners before freeing host references. Late completion resolves a lifetime token and drops safely if its owner no longer exists.

Deleting one collider restores its old neighborhood. Deleting a source while a kernel runs must keep its captured numeric snapshot alive until retirement. Node-handle reuse must not match an old controller token. Multiple controllers must not share mutable pose pages accidentally.

## Device loss and CPU fallback

Treat device removal or compute failure as a device-epoch change. Stop admitting that backend, retire unusable resources according to API state, and produce a coherent CPU successor when possible. Keeping an old GPU pointer is not a valid retained-result strategy after a reset; reconstruct a CPU/SDK-owned representation from authoritative data.

WDDM can reset a GPU that fails to complete/preempt work in time. Do not instruct artists to disable or lengthen TDR as the feature's operating model. Use bounded batches, measured occupancy, prompt failure handling and normal driver recovery. [Microsoft TDR overview](https://learn.microsoft.com/en-us/windows-hardware/drivers/display/timeout-detection-and-recovery).

## Required concurrency tests

Rapid drag with reversals, repeated setting edits during compute, Undo before completion, source deletion, scene reset/open, controller deletion/recreation, device recreation, multiple views, render during a pending drag, failed queue admission, and shutdown with in-flight work must be exercised. Check both visible correctness and resource retirement. A successful single buffer write does not qualify any of these lifecycle guarantees.
