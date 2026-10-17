# Proposed storage, memory and Undo contracts

**Proposal, not implementation.** Read [scope and baseline](README.md) first. Preserve foundation F01–F12, including their qualification limits. Symbols named below for new types/interfaces are working design names, not existing APIs.

Some storage and adapter work is now implemented; the [execution handoff](EXECUTION_0860.md)
and exact receipts distinguish that work from the still-proposed publication,
history and downstream boundaries below. Do not infer complete implementation
from this design.

## 1. Boundary and stage order

MAXScript remains responsible for the existing UI and authored settings. Its bulk work is replaced with small validated requests and opaque immutable native values. It may retain one value per owner/generation, not one object per plant. Native computation returns bounded statistics and publication handles; it does not recreate complete script rows for another native function to consume.

Preserve the current sequence:

1. Resolve relevant authored settings, references, evaluated geometry/channels, current Analyzer output and receiver quotas on the host thread.
2. Generate receiver-local stable candidates, including existing distribution/source assignment, Areas/Bands, movement and initial Relax.
3. Apply existing optional final Relax, whole scale, mesh channel mask, Analyzer area and boundary falloffs in their current order; retain receiver-local cached results and normal data.
4. Combine receivers with correct face mapping; apply Paint union/density/scale, orientation, Empty/Point source policy and source transforms.
5. Apply the existing Analyzer boundary orientation special case, then CS Edit, then existing slope/altitude eligibility, then source-container admission.
6. Calculate radii, apply the three collision scopes, accepted-target refill and cleanup with the same bounded order/protected priorities.
7. Stage display, source correspondence, radii, statistics, Edit visibility and output metadata; commit one complete root epoch.

Do not fuse, reorder or parallelize dependent stages simply because their data is now native. Zero/no-op settings still require existing signed-zero/rounding behavior where observable. Preserve old Float32 boundaries at the corresponding stage even when no script object is created.

## 2. Native placements and immutable generations

Use the existing pure-data library for numerical structures. A native store owned by AminScatter holds receiver/prepared/published generations. A small GC-traced MAXScript value owns a reference to the native generation; releasing a script wrapper must not invalidate a renderer, Undo record or active transaction that still owns it.

Suggested placement fields:

| Field | Requirement |
| --- | --- |
| Transform | Twelve Float32 values at existing host-rounded stage boundaries; double arithmetic inside kernels where already used |
| Source | Compact slot, mapped through the generation's frozen source-correspondence table |
| Identity | Tagged generated candidate key or authored-copy key. Intern authored text/GUID data once; preserve exact existing external identity |
| Anchor | Receiver slot, receiver-local face and barycentric values; retain compatibility with concatenated face numbering at existing boundaries |
| Ownership | Band owner and population owner kept distinct from candidate/source identity |
| Flags | Protected Edit and other explicit current semantics, without implicit identity-by-array-index |

Use a simple contiguous per-receiver/per-population representation first. Start with compact records and index arrays; adopt separate columns or block sharing only where measured mutation/Undo cost justifies them. Do not add a general graph engine or custom allocator framework.

The numerical `amin::Instance` is useful scratch, but must not automatically become the permanent compact record: it includes double axes/position and redundant intermediate fields. Measure actual compiled `sizeof`, capacity, alignment, index tables and identity storage. For scale only, 200,000 hypothetical 128-byte records are about 24.4 MiB **for one array**; this is neither a proposed total-memory limit nor a measured saving.

### Mutability rules

- A builder owns mutable storage until freeze. Kernels may modify that storage only when no cache, Undo or published owner can observe it.
- Frozen receiver and prepared generations never change. A changed successor gets private storage for changed transforms/metadata; removal-only stages can use a bounded index view.
- Views retain their base. Avoid arbitrarily deep chains; flatten indices or compact at named boundaries when retaining a large rejected base would cost more than copying accepted records.
- In-place source transforms cannot run on a shared receiver/Paint base. Preserve the isolation currently provided by cloning/orientation output.
- Empty paths use a typed empty generation. No hidden fallback should expand native data into a full MAXScript Array.
- Bounded readback returns owned copies. A caller cannot mutate a native published transform through a returned Matrix3.

### Identity and module lifetime

Handles include type/capability and owning session/generation identity. Reject stale, wrong-kind or foreign-owner handles deterministically. Never save raw pointers/handles in scenes or recipes. Numeric worker inputs contain no `Value*`, `INode*` or mutable Max references.

Keep host reference tables separate and GC/SDK-traced. A numeric snapshot is not enough to keep a source node alive. Destructors release owned buffers without executing MAXScript, scene mutations or garbage collection; graphics/SDK resource disposal follows its required host-thread path. Stop/join existing owned work before unload.

Cross-module calls to Brush use an exported, versioned ownership contract from AminScatter with POD views and matching retain/release functions. The allocating module remains responsible for destruction. Do not create duplicate stores by linking the same static implementation into both modules. A missing/mismatched capability must fail before touching the scene.

## 3. Native acceptance without duplicate populations

Keep receiver schedules numeric. Use numeric lookup/indexing for generated candidates and an interned authored-key route for protected copies. Preserve current schedule order and ordinal semantics; do not replace them with container iteration order.

Let spacing consume immutable position/radius/identity views and return accepted indices/reasons/statistics. Avoid another complete transform copy merely to select winners. Audit internal solver-owned grids, reason vectors, conflict sets and refill scratch as well as input arrays. A native view does not make those allocations disappear.

Retain separate logical collision scopes and protected reservations. Count, attempted candidates, accepted plants, preview instances and exact output remain distinct. Sparse painted regions and accepted-target retries need measurement using generated/attempted counts, not only their much smaller accepted result.

## 4. Cache ownership and invalidation

| Owner | Retains | Release/reuse policy |
| --- | --- | --- |
| Receiver cache | Frozen numeric candidates/anchors/normal snapshot for its exact dependency key | Reuse unchanged receiver; replace changed generation only after successful preparation |
| Prepared layer | Eligibility/transforms/Edit result for the preparation key | Radius/spacing-only changes should reuse it where the existing key permits |
| Root publication | Accepted data, source mapping, radii, stats and epoch | Pinned until complete successor commit; usable while pending Manual edits exist |
| Viewport/renderer | Data/resources for a particular publication | Pin while in use; unchanged data must not re-upload |
| Active transaction | Before/after owners needed for commit or rollback | Release on success/failure; not an artist history item by itself |
| Host Undo | Authored records; native snapshots only where the operation needs them | Release when Max releases the history record, including abandoned Redo |
| Inspection request | Publication reference for bounded readback | Drop after response; never solve during inspection |

Begin with the existing dependency keys. Replacing key generation and moving storage at the same time would make parity failures hard to isolate. Preserve geometry, topology, transform, selected UV/mesh channel, time-validity, Paint revision, source membership, variation domain, Edit and Analyzer dependencies. Display-only settings stay out of placement keys.

A shared evaluated receiver snapshot is a possible later optimization within N08, after proving same-frame notifications and exact key equivalence. Forest's known same-frame channel issue is a reason to test freshness, not a behavior to imitate. Explicit Update must still observe changed channel/geometry data.

Evict only reconstructible, unpinned caches. Never evict the published result, pending rollback or required Undo data to make a new Update fit. No disk spill or compression is proposed initially. Count down should free obsolete data once all legitimate pins disappear; lower OS working set immediately is not a valid ownership-release test.

## 5. Undo and atomic publication

### Preserve the operation's existing meaning

| Operation | Proposed history behavior |
| --- | --- |
| Count/seed/scale and other parameter edits | Keep Max's authored parameter Undo. In Live, reuse an exact native cached result or recompute once after restored settings settle; do not save a full result for every edit by default |
| Manual parameter Undo/Redo | Restore authored settings and current Manual pending semantics. Do not silently evaluate. The current cold-copy witness requires explicit Update to regenerate rows |
| Ready-preset Load | Retain exact before/after publication references and authored scene references in its one existing operation. Undo/Redo cannot reload files or silently substitute new assets |
| Instance move/delete/copy | Store changed authored records and required base bindings. Keep deterministic output IDs, dormant edits and Redo data |
| Selection | Compact selection state/change set; no full copies of all derived transforms |
| Calculate / failed successor | Separate transactional rollback from artist Undo. Failure retains previous complete publication and usable history |

MAXScript parameters remain the sole authored owner for existing settings; the native request is an evaluated snapshot, not a second independent copy to synchronize as saved state. Native Edit records remain the authored owner for instance edits. Native Paint documents remain the authored coverage owner.

### Commit protocol

N05 binding decision: use a small immutable source cohort per population,
shared by its placement generations, rather than a process-global handle
registry. It identifies the exact ordered source roles/IDs and scene bindings,
including Point/Empty/unassigned policy. Count and display changes must not
invent a new semantic source mapping; replacing/reordering assets must not reuse
the old mapping merely because its cardinality matches. At publication, freeze
the receiver slot/identity, face-range and binding-revision correspondence as
well as the complete input signature and root epoch. Validate candidates and
prepared/published populations against these bindings before install. The current
bare native view has only source cardinality and session owner; it is insufficient
for this production boundary.

Keep bulk placements/radii and source/receiver correspondence in native owned
storage. Host references stay on the host thread; any necessary GC/SDK reference
retention must use verified Max lifetime semantics, never a raw scene pointer
handed to workers. A root publication owns the complete ordered population,
statistics and draw/output references. Small UI summaries bind that publication.
Keep authored parameters, ordinary scalar Undo and current receiver-bound Paint
ownership unchanged. These binding/publication types remain pending until source,
GC, scene lifecycle and actual controller tests prove them.

1. Capture settings/revisions and root ownership under the existing host scheduling/reentrancy guard. Determine whether this is cached, Manual-pending or an authorized successor.
2. Admit estimated additional resources, retaining the old result and all existing history. Capture referenced numeric inputs.
3. Build candidate/prepared/accepted data and pending Edit binding state without modifying the published generation.
4. Stage every required preview/output descriptor and any operation-specific history record. Validate source mappings and owner liveness.
5. Commit root/leaf fields and Edit publication as one host-thread transaction. Preallocate rollback state and metadata before the install tail. Notifications that allocate/fail must not leave mixed epochs.
6. Release obsolete unpinned state. Run observers separately; observer failure must not claim the committed result was rolled back.

Reuse the existing PointDisplay staging/recovery instead of claiming a single pointer swap solves all Max callbacks. True GPU device loss remains a distinct test boundary. On failure before completion, preserve the previous complete output and current authored intent with a specific error; do not silently lower Count or flush Undo.

### Compact Edit implementation direction

Separate `EditLayer` into authored identity/binding/delta/deletion state, selection state and immutable derived input/publication views. Replace calculation rollback's full-map copy with a staged successor/reference swap. Replace artist `EditRestore` full-map copies with operation deltas or immutable changed blocks. Prefer per-command deltas for small edits; use compact selection bitsets and bounded block sharing for large selections where simpler.

Preserve original-row ordering, copied-row ordering, suppressed/deleted state, dormant candidates after Count reduction, receiver disappearance/reappearance, topology binding rejection and cloned GUID remapping. A no-op row may still carry order or dormant identity significance; do not simply delete all identity rows.

Restore and Redo must be safe when repeated, including cancel/Restore(false), nested/super holds and discarded Redo. Capture the intended after-state at a qualified operation boundary. The preset implementation currently captures on first Undo; do not copy that timing to arbitrary asynchronous callbacks without testing intervening operations.

Report history-owned costs honestly through `RestoreObj::Size()` with checked integer conversion and an explicit shared-allocation attribution policy. Keep a separate 64-bit unique-buffer ledger to distinguish physical retained bytes from conservative per-record attribution. Test actual Max 2027 trim behavior before selecting the policy; no tiny constant pretending to measure large retained buffers. Respect normal host history policy without clearing it, changing preferences or silently dropping older commands to satisfy an Update.

## 6. Memory admission and failure behavior

Separate **work limits**, **transient memory**, **cache retention**, **Undo retention**, **CPU preview** and **GPU resources**. Native memory still consumes process/system commit. Available RAM alone cannot admit a large allocation reliably, and a check before allocation is not a guarantee that allocation later succeeds.

Track unique live/reserved bytes by owner/stage, vector capacity and scratch high-water marks. Model incremental peak as:

`existing pinned bytes + additional input snapshots + successor/scratch peak + new display/output resources + operation-specific history + bounded script/SDK overhead + headroom`.

Count shared buffers once in physical totals and expose their pin reasons separately. Account for vector growth/reallocation overlap, compacted outputs, spatial indexes, identities and old/new display generations. Resolve overflow before allocation. Conservative allowances remain for opaque SDK/driver memory; do not call estimated totals exact process usage.

Before refusing an Update, discard eligible transient scratch/unpinned caches, then admit within available commit/headroom. Never clear required history or the previous result. Handle allocation failures at each owned stage, including after preparation and during commit; destroying a failed builder must not require large new allocations. Do not deliberately exhaust the artist machine to test this.

Retain the 0.85.4 script reservation until counters prove that no remaining hot path expands placements into script rows. Then remove the candidate-scaled estimate from the native Update path; keep only justified bounded scripting overhead and any explicit export consumer allowance. Never reduce `heapSize` or edit saved heap preferences as part of migration.

## 7. Consumers and responsiveness

Preview, source-use summaries, radius rings, exact output and full parity fingerprints should read native views. MCP continues to export at most 500 cached placements per page with publication identity checking. Do not add an uncapped convenience `toArray()` used by production code.

PFlow currently stores all transforms in `CyrusPFData`. First qualify an on-demand bounded native accessor usable by the existing Script Operator, pinning one publication for its entire evaluation; this removes persistent bulk script storage but still incurs per-particle dispatch. Then, if measured necessary and supported by the Max 2027 SDK, qualify a native channel-fill adapter. Exact scale/frame/material/proxy and render-lifecycle parity are mandatory. Do not promise that an uninspected PFlow SDK route already exists. If it cannot be qualified, mark full render migration incomplete rather than silently retaining a bulk fallback.

Bake may remain host-driven scene authoring using bounded pages or a host-thread native visitor. Creating many real nodes and their host Undo is intrinsically more expensive than retaining scatter instances. Preserve one user operation and failure cleanup; never equate native placement savings with unlimited cheap baking.

Use the existing held-interaction deferral and consolidate relevant edits so a released spinner value gets one final successor. Keep navigation independent from calculation. Measure actual event latency and stage blocking separately from native solve timing. The first migration remains synchronous with joined workers. If long stages still block unacceptably, record a separate bounded scheduling/cancellation design; do not introduce background host access or claim that C++ alone makes 200k edits instantaneous.
