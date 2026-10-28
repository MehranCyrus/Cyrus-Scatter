<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 08 — Asynchronous publication and lifetimes

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Starting point

**[P]** Current numerical work is synchronous. Workers consume owned snapshots, join, merge in stable order, and host-thread publication follows. Adding GPU work is therefore a new asynchronous subsystem, not a small kernel replacement.

## Ownership model

| Object | Owner | Lifetime key | Mutability |
|---|---|---|---|
| source snapshot | source-definition cache | `(sourceID, sourceRevision, evaluatorRevision)` | immutable |
| collider geometry/BVH/SDF | collider asset cache | `(assetID, geometryRevision, representationRevision)` | immutable after cook |
| collider transform snapshot | request | request key | immutable |
| published placements | interaction owner | placement revision | immutable generation |
| active-work buffers | request arena | request serial + device generation | transient |
| GPU source buffers | GPU cache | source key + device generation | immutable |
| GPU collider buffers | GPU cache | collider key + device generation | immutable |
| result pose generation | interaction owner | complete request key | immutable after publish |
| viewport buffer generation | display subsystem | pose generation + graphics-device generation | transient/rebuildable |
| renderer/Bake mesh | output request | pose generation + output settings | transient or explicit baked asset |

GPU pointers, native device objects, fences, allocator blocks and compiled kernels are never scene-authoritative data.

## Request key

```cpp
struct InteractionRequestKey {
    uint64_t scene_epoch;
    uint64_t owner_id;
    uint64_t owner_revision;
    uint64_t placement_revision;
    Hash128  source_set_fingerprint;
    uint64_t collider_geometry_revision;
    uint64_t collider_transform_revision;
    uint64_t settings_revision;
    uint64_t units_frame_revision;
    uint64_t request_serial;
    uint64_t device_generation;
};
```

A result may publish only if every semantic revision except transient device generation still matches and the device generation is valid for any GPU-resident output.

## Event-to-result timeline

```mermaid
sequenceDiagram
    participant UI as Max/UI host thread
    participant C as Coordinator
    participant W as CPU workers
    participant G as GPU queue
    participant P as Publisher
    UI->>C: collider edit + revisions
    C->>C: coalesce; snapshot owned data
    C->>W: old/new query + compact active work
    W-->>C: active lists
    C->>G: enqueue bounded generation
    UI->>C: newer collider edit
    C->>C: mark older serial superseded
    G-->>C: completion fence for old serial
    C->>C: discard old result; retire buffers
    C->>G: enqueue newest generation
    G-->>C: completed compact poses
    C->>W: independent CPU validation/materialization as required
    W-->>C: complete certified result
    C->>P: host-thread publish if revisions match
    P-->>UI: newest complete generation visible
```

See [diagrams/02_async_lifecycle.mmd](diagrams/02_async_lifecycle.mmd).

## Coordinator state machine

```text
Idle
 ├─ edit → Capturing
Capturing
 ├─ invalid/over-budget → FailedRetainingLastGood
 └─ snapshot complete → Queued
Queued
 ├─ superseded → CancelRequested
 └─ submitted → InFlight
InFlight
 ├─ superseded → StaleInFlight
 ├─ device failure → DeviceFailed
 └─ fence complete → Validating
Validating
 ├─ revisions changed → Discarded
 ├─ quality failed → FailedRetainingLastGood
 └─ pass → ReadyToPublish
ReadyToPublish
 ├─ host recheck fails → Discarded
 └─ host publish → Published
```

## Coalescing

- Keep at most one pending newest request per interaction owner.
- Do not allocate a full successor for every mouse message.
- Let in-flight GPU work finish or hit cooperative checkpoints; mark it stale rather than blocking the host.
- Reuse preallocated arenas only after the completion fence and all consumers release them.
- Preserve old/new collider transform history needed to restore plants when the newest request is finally solved.

A coalescing policy must report skipped intermediate input rather than claiming continuous collision.

## Cancellation

GPU cancellation is cooperative:

- CPU front-end loops check a generation token at bounded intervals.
- Long GPU kernels can check a cancellation flag only if doing so does not corrupt output; this does not revoke already written data.
- Multi-stage graphs stop submitting later stages when cancellation is observed.
- All outputs remain private until complete; partial buffers are never published.
- Stale completion callbacks enqueue retirement, not publication.

## Double/triple buffering

### Minimum

- published generation `G0` remains immutable;
- successor generation `G1` is built privately;
- one active GPU scratch/pose output buffer;
- one upload/readback staging buffer.

### Triple-buffer case

Needed only if display still consumes `G0`, `G1` awaits validation/publication, and newest `G2` is already executing. This can multiply pose/scratch memory.

**[R]** Bound queues to one in-flight plus one newest pending request. Do not allow unbounded pointer-event generations.

## Peak memory formula

```text
peak = shared_sources
     + collider_caches
     + published_pose_and_display
     + in_flight_pose_and_scratch
     + pending_snapshot
     + upload_readback_staging
     + validation_materialization
     + renderer_or_Bake_copy
     + Undo/history retention
```

Every prototype must report each term. A single “VRAM used” number is insufficient.

## Stale-result events

A pending/in-flight result is discarded after:

- Undo/Redo changes collider/source/settings revisions;
- owner/layer/instance deletion;
- placement population publication;
- source replacement or preparation edit;
- scene reset/load/merge;
- unit or coordinate-frame change;
- interaction capability/evaluator revision change;
- device recreation;
- plugin shutdown/unload.

The callback must not dereference scene objects. It communicates through owned IDs and a host-thread queue.

## Device loss and TDR

**[V]** Windows GPU timeout/recovery can reset the graphics device and purge video-memory resources. **[S29]** Therefore:

1. mark the current graphics/compute device generation invalid;
2. stop publication of all results depending on it;
3. release/retire registrations and transient buffers after allowed cleanup;
4. keep CPU scene/published pose truth intact;
5. rebuild optional GPU caches lazily;
6. switch to CPU fallback and report the accelerated path unavailable;
7. never prevent scene load or plugin startup.

Avoid long monolithic kernels; chunk work and keep dispatch duration well below TDR exposure. This is a reliability principle, not a guaranteed timing threshold.

## VRAM exhaustion and fragmentation

- Use capacity-class pools and explicit admission before dispatch.
- Estimate source, pose, contacts, scratch, output and staging separately.
- Query actual allocation errors; do not rely only on nominal VRAM.
- Keep a reserve for Max, viewport textures and GPU renderer.
- On admission failure, use smaller chunks, lower declared interactive quality, CPU fallback, or retain last good result.
- Never evict currently published buffers without a valid replacement.

## Compilation and cache lifetime

Kernel/shader cache key:

```text
backend + device architecture + driver/runtime version
+ kernel/evaluator revision + precision/quality feature set
+ source schema version (not individual instance ID)
```

Do not compile one program per source instance. Bound cache size, record failures, and invalidate on incompatible driver/backend changes.

## Publication transaction

```cpp
bool try_publish(ResultGeneration r) {
    assert(r.complete && r.validation_complete);
    HostSnapshot now = capture_minimal_revisions_on_host();
    if (!matches(r.key, now)) return false;
    if (r.device_dependent && r.key.device_generation != current_device_generation())
        return false;
    swap_published_generation(r);  // atomic owner-level handoff
    enqueue_old_generation_retirement_after_consumers();
    return true;
}
```

No scene object or graphics handle is modified before this final transaction.

## Irrelevant events

The following must not enqueue a static interaction solve or unchanged upload:

- camera navigation;
- selection changes;
- UI browsing;
- viewport shading/wireframe toggles;
- unrelated animation time changes;
- renderer preview activity not requesting final geometry;
- unchanged source/material/buffer state.

The display subsystem may change draw state independently of the interaction owner.

## Diagnostics

Per owner/request expose:

- pending / in-flight / validating / published / stale / failed / CPU fallback;
- active plants, guides, spans, pairs and visible vertices;
- uploaded/read-back bytes;
- source/collider/request revisions;
- approximation tier;
- failure reason and first/worst witness IDs;
- last complete publication timestamp/serial;
- device/runtime and fallback reason.

Do not expose kernel block size or internal tuning as primary artist controls.
