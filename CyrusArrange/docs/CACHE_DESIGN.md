# Reusable geometry/query cache design

This design is being implemented in 0.1.3. Native SDK builds and numerical tests
pass; host dependency integration still has an observed regression under repair.
See [the runtime contract](CACHE_RUNTIME.md) and [current qualification](RELEASE_VALIDATION_0.1.3.md)
for implemented behavior and executed evidence. This remains unfinished work in
[ROADMAP.md](ROADMAP.md). Existing gallery timings do not establish cache speedup;
that needs separate correctness-qualified measurements.

## Smallest useful boundary

`prepare_generation` currently captures furniture, inspects it, reconciles the
region registry, refreshes assets, captures obstacles, constructs
`FurniturePlacementQuery`, and solves. Generate then captures visual meshes and
publishes output; Preview stages bounds and an immutable registry.

Retain one immutable **furniture/obstacle geometry bundle per Document**:

- The raw `Result` from furniture-only inspection, with observation IDs.
- An immutable `FurniturePlacementQuery`, which already owns its collision
  triangles, support polygons, component topology and BVH.
- Its input stamp, geometry-only validity intersection, accounting and diagnostics.

Release captured body meshes and the combined inspection soup after construction;
the query owns the numeric data it requires. Do not retain evaluated Max meshes,
TriObjects, materials, assets, placements, output nodes or a DocumentState snapshot.
Keep asset recapture, stack-support validation and visual/material capture on the
existing path initially. Their cost will limit any measured benefit.

Split capture/inspection from registry reconciliation. On every solve, match
cached raw observations against the **current** immutable registry and furniture
source keys, or the valid staged Preview registry supplied to Commit. Reserve IDs
through the existing monotonic allocator; apply stable IDs to a command-local
copy of the regions. Never put authored labels/policies, reserved region IDs or
an old registry into the geometry cache as authoritative state. The current
`Region` owns its cell vector, so this first design explicitly pays for a bounded
deep copy when remapping IDs. A borrowed-cell Region view is a later measured
improvement, not a prerequisite for the first cache.

## Cache key and invalidation

The key is fieldwise, not a hash of padded C++ structs. It contains:

- Transient Document instance identity and a non-restorable geometry generation.
- Ordered furniture/obstacle root identities, expanded node identities and scope
  roles; persistent furniture source keys; the exact near-origin mm frame.
- Exact system-unit-to-mm scale; capture time and geometry validity interval.
- Each evaluated node's captured object-to-world matrix, including parity. On a
  proposed hit, expand/check the scopes again and compare current matrices on
  Max's main thread. Names, selection and container object addresses are not keys.
- Every inspection setting and admission limit, plus every `QuerySettings` field,
  including approach enablement, tolerance and build budgets. Changing a limit
  must not reuse an entry that bypasses its new admission check.

The first implementation is **same-time only**: changing time invalidates reuse even for static `FOREVER` geometry. Cross-time validity reuse is deferred until separately tested. Query the same evaluated world/object-transform convention and its validity as the cold path; caching must not introduce a new WSM/proxy interpretation. The detailed [implementation plan](CACHE_IMPLEMENTATION_PLAN.md) supersedes earlier cross-time proposals.

| Change | First-cache behavior |
| --- | --- |
| Seed, density, spacing, style, locks, selected regions, category weights or region semantics | Reuse geometry; run current registry matching, asset refresh, query probes and solve |
| Any inspection setting/budget or query setting | Miss and rebuild the bundle |
| Bound furniture/obstacle/source geometry, topology, transform, object-offset or hierarchy membership | Invalidate conservatively; source-only invalidation can be separated later |
| Root replacement, missing binding, source deletion, generated-node eligibility change | Revalidate scope; reject missing/unsupported inputs rather than serving stale geometry |
| Source material/UV/normal appearance edit | Keep numeric geometry only if unchanged; visual capture still reads current data before publication |
| Output edit/deletion | Keep geometry; retain current output-protection/lock/deletion handling |
| Unrelated scene edit, selection, browsing, passive panel refresh | No rebuild or solve |
| Undo/Redo, reset/new/open/merge, clone, owner destruction, module shutdown | Clear transient entries; no cache resurrection from Undo or saved files |
| Units/frame change or any time change | Miss; rebuild from current inputs |

Existing `input_epoch`, revision and state-pointer identity are unsuitable as the
sole key: authored edits and successful publication change them even when geometry
is unchanged. Add a transient monotonic geometry generation outside restored
Lifecycle/DocumentState snapshots. It must observe relevant input notifications
even while the publication guard suppresses owned-output notifications. The
current broad `updating` early return needs that distinction before caching.
Never rewind this generation during Undo. Conservative extra misses are safe.

Drain hierarchy events before lookup and after capture, then recheck generation,
root/expanded identities, matrices, time, units and owner before admitting a
bundle or publishing output. A third-party object that changes without correct
notifications/validity remains a qualification limit; an optional forced-cold
command provides recovery, not proof that such objects are supported.

## Ownership, limits and atomic behavior

Store the transient entry outside DocumentState, preferably owned by Document;
short synchronous commands borrow a `shared_ptr<const GeometryBundle>`. Undo
records never retain cache entries. An LRU accounting service uses weak Document
registration and removes it on destruction; it must not keep a deleted setup
resident through a strong reference. Clone/load start empty. Preview continues to
own only its current bounded boxes/registry, never a duplicate geometry bundle.

Proposed starting retention limits: four entries globally, one per Document,
one million cached triangles, one million cached inspection cells and 256 MiB of
accounted retained buffers in aggregate. These are proposed tuning values.
Implement query byte accounting for vector capacities, support-path storage,
components and map/index allocations before enabling byte-based admission. An
estimate must be labelled an estimate; 256 MiB is not a whole-Max RAM guarantee.
Retained registry cells and existing Preview/Undo allocations remain separate.

Enforce current per-operation geometry/body/cell/work limits before construction.
Charge resident, borrowed and replacement entries once each; eviction cannot free
a command's borrowed object. Track old/new bundle overlap and cold construction
scratch in peak measurements. No allocation or eviction runs inside drawing or
reference callbacks. Cache admission failure skips retention and uses the complete
cold bundle for that command; it must not turn otherwise valid generation into a
new cache-limit error. Existing operation-limit failures still fail explicitly.

Build and validate an immutable bundle privately before exchanging any entry.
Cache availability never means a clean document or a successful arrangement.
Solving, source validation, staged-registry handling, scene publication and Undo
retain their present transaction boundaries. Failed Generate/Preview/Commit keeps
the previous committed output and authored state. Manual remains pending until an
explicit action; Live uses its existing main-thread scheduler. Preview disarming,
stale-preview refusal and explicit Generate/Commit rearming remain unchanged.

## Qualification before enabling

Add cache hit/miss/reason and capture/inspection/query-build/solve/publication
timings. Keep original geometry work diagnostics separate from work actually
executed on a cache hit. All SDK access remains on the main thread.

Compare forced-cold and cached runs on the same authored inputs and registry:
exact stable IDs, regions, poses, locks, warnings, candidate/rejection counts,
full-bound fit and Preview/Commit mesh agreement. Avoid allocating fresh IDs
independently in the two comparison paths: first establish a stable registry or
use one fixed reservation in a nonpublishing test harness.

Exercise every invalidation row, including group add/remove, nonuniform/mirrored
transforms, object offsets, relevant animation, unit changes, missing references,
rule-only edits, output edits, unrelated edits, Undo/Redo, clone and reopen. Lowered
budgets must still reject appropriately. Inject capture/query/solve/publication
failure and retention-admission failure. Prove old output survives, stale geometry
is never used and no timer bypasses Preview's Live disarm. Measure cold versus warm
wall time, peak/retained/history memory and idle behavior on small and admitted
large scenes; report numeric and visual publication costs separately.
