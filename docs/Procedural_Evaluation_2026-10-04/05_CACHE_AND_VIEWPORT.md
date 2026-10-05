# 05 — Cache dependencies, memory and viewport performance

Status: proposed refinement of existing caches. Preserve the current behavior before optimizing its granularity.

## Three different kinds of stored data

| Storage | Contains | Lifetime |
| --- | --- | --- |
| Saved authoring state | IDs/order, parameters, source/receiver references, rules, Brush history, sparse edits | Scene persistence and Undo |
| Derived memory cache | Surface sampling structures, prepared candidates, coverage evaluations, radii, accepted indices and display data | Session; evictable/rebuildable under a memory budget |
| Optional published disk snapshot | Versioned immutable evaluated data plus provenance/checksums | Explicit later feature for reuse, interchange or farm workflows |

Saving a scene does not require serializing every temporary spatial grid. A cache is reusable only when its dependencies still match. A loaded scene needs either valid persisted provenance or a new evaluation; a Python session ID or process pointer is not a durable identity.

## Useful cache boundaries

1. **Receiver snapshot/sampler:** geometry, topology, surface transform, relevant channels and validity.
2. **Source metadata:** display geometry/samples, artistic or automatic footprint information, transform conventions and revisions.
3. **Candidate pool per set:** stable anchors/IDs and deterministic ordinal range.
4. **Prepared set:** coverage eligibility, assignment, final proposal transforms, edits and radii, with reusable sub-results where worthwhile.
5. **Completed layer:** accepted index views, statistics and occupancy digest after shared cleanup/repair.
6. **Controller publication:** immutable references to compatible completed layers and the exact input revision.
7. **Display packets:** selected display representation and its resource generation.

The physical candidate cache may exceed the logical prefix requested by an evaluation. Store both values. Exposing the entire resident pool changes cleanup/refill decisions and violates cold/warm equivalence; only the versioned evaluation schedule decides which ordinals participate.

Do not copy every buffer at every boundary. Keep shared immutable buffers, compact indices/bitsets and sparse overrides. Store rejection details selectively; full per-pair debug data needs a cap. Retain temporary grids only when measured reuse exceeds their memory cost.

## Cache key contract

An output key includes its algorithm/schema version, owner identity, relevant normalized settings, relevant input revisions and upstream output identities. Keys describe **effective values**, including inherited settings. Avoid hashing a huge world snapshot or constructing whole-controller strings during each viewport redraw.

Revision domains should distinguish receiver topology/geometry/transform, coverage, source assignment, source geometry, spacing footprint, transforms, edits, population, rule/order and display. Scene callbacks must cover each domain; an explicit Update remains a recovery path for unsupported external changes. Do not drop broad current invalidation until mutation tests prove the replacements.

Time belongs in a key when an input is time-dependent or its validity interval ends. Do not globally remove time merely to improve cache hits. Likewise, a texture object's handle alone does not establish that its content or external bitmap is unchanged. Capture relevant texture validity/content revisions or conservatively invalidate at a defined boundary.

The readiness audit found `paintSetName` and `paintSetVisible` included by the generated `paintBaseInputKey` field loop. Their UI handlers intend presentation-only changes, but the key can change and invalidate a prepared result or mark Manual mode pending. This is a confirmed key-classification issue; the actual runtime cost was not measured in this audit. Add rename/visibility mutation fixtures before excluding them. Do not infer that rollout clicks themselves trigger this path.

Key construction must be a read-only operation over normalized effective settings. Current `syncLogicalSettings` writes inherited child values, and the Edit-key path also synchronizes transient visibility. Separate those effects from pure fingerprinting in the new adapter, with host-safe explicit publication. A function called “key” is not automatically free of side effects.

## Intended invalidation matrix

This table is the **target**, not a claim that current 1.2.3 already achieves it. Dependencies from shared budgets, cleanup and protected reservations can legitimately broaden a row.

| Change | Earliest affected result | Reuse that should remain possible |
| --- | --- | --- |
| Orbit/pan/zoom | Camera/display submission only | All placement, Brush and source preparation; warm retained buffers |
| Expand/collapse UI or read statistics | UI only | All computational results |
| Pure preview tint/budget/mode | Display packet/style | Final accepted placements and generation inputs |
| Viewport visibility | Display membership | Placement and collision results; renderer participation unchanged |
| Rename layer/set | Presentation metadata | Candidate identities and placements |
| Enable/disable set | Allocation and affected occupancy dependencies | Unrelated receiver/source snapshots |
| Set share weight | Sibling allocation/candidate limits | Surface sampler and unchanged source data; candidate prefixes if supported |
| Brush stroke/erase | That set's coverage preparation | Candidate anchors; other set preparation; affected layer solve may rerun |
| Layer area mask | Member-set eligibility | Surface/source snapshots; candidate anchors if generation policy permits |
| Collision gap or multiplier | Relevant solve/radius consumer | Candidate positions, coverage and source samples |
| Source artistic radius | Effective radius and relevant solves | Positions, geometry buffers and coverage |
| Source scale/offset | Instance transform, effective radius, solve and display | Support-anchor coverage when independent of source footprint/offset |
| Procedural movement | Resolved support anchor, eligibility, assignment/transform and solve | Latent candidate anchors under the new random-channel contract |
| Source geometry edit | Source display; footprint if geometry-derived | Placements if radius and placement are independent of geometry |
| Pure display color | Style packet | Placement; exceptions for colors used as assignment/group keys |
| Manual move/delete/radius edit | Authored constraints and affected solve | Unrelated prepared data; upstream layers may change for global reservations |
| Seed/distribution/topology | Candidate namespace and downstream | Unrelated layers and independent source metadata |
| Pair enable/order change | Dependency graph and affected solves | Prepared candidate inputs |
| Cleanup setting | That layer's cleanup/repair and dependent layers | Prepared set proposals |

A dependency should normally propagate only when its **consumed output** changes. Changing a layer's label must not change its occupancy digest. Changing a rule may produce identical accepted occupancy; once the new result is verified, downstream placement results may remain reusable. Start with correct revision invalidation and add output-digest short-circuiting only where its cost is justified.

## Memory and eviction

Assign configurable process/controller budgets after measurement. Account for shared source buffers once and distinguish owned from referenced bytes. Report current and peak resident cache payload estimates separately from process working set and GPU resource estimates.

Evict rebuildable least-recently-used intermediate entries first. Keep the current published result alive while display/render/export readers hold it. A new generation may temporarily coexist with the old one; admission control must consider that peak and reject/cancel a build rather than allocate without a limit. Eviction changes speed, not accepted output.

Empty or disabled caches are real reusable states. Invalid/stale/error are different states; none should masquerade as an empty successful scene. Device loss invalidates device resources, not necessarily candidate/placement data.

Eviction must also preserve the logical replay history implied by the policy: rebuild the canonical transaction when necessary instead of resuming from an arbitrary warm accepted subset. Saved authoring overrides and the current published generation must not be discarded as if they were expendable candidate pools.

## Keep the existing drawing paths

The repository has retained native Point Cloud and Mesh generations, and a separate cached Proxy batching path. Preserve all three while replacing placement evaluation. The adapter should hand them accepted transforms/source references, not make each display path independently decide placement.

Warm navigation acceptance target: **zero new placement generations, zero Brush evaluations and zero retained geometry/point uploads caused solely by camera motion**. Drawing, visibility submission, bounds and permitted future view-dependent LOD work still have costs. Device recovery, display changes and genuinely animated inputs are excluded from the warm static test.

Preview sampling and budgets remain display-only. Exact final output must use the accepted placement set, not the displayed subset. The UI should distinguish accepted plants, shown plants and cloud samples so a lower preview budget is not mistaken for lost painting.

Historical [retained Mesh results](../Retained_Mesh_Preview_2026-10-02/RESULTS.md) and [1.2 qualification](../Layers_First_2026-10-03/REPORT.md) establish prior measured fixtures. They are not a guarantee that every heavy vegetation scene has the same FPS. Camera path, source complexity, viewport size, driver, display mode and background scene must be controlled in the next comparison.

## Threading and acceleration

Capture Max scene data and perform scene/Undo mutation at the appropriate host-safe boundary. Workers consume owned numeric snapshots. Autodesk documents broad SDK thread-safety limits; a rendering API's main-thread helper is evidence for the restriction, not automatically the correct scheduler for this plugin. See [the research register](09_RESEARCH_AND_DECISIONS.md).

Start by preserving the existing bounded CPU parallel work and pure native spacing solver. Parallelize independent preparation only after profiling. A greedy priority solver cannot simply process all candidates concurrently without changing who wins. Use fixed ordering and deterministic reductions; prove equality against the serial oracle across thread counts.

GPU display is already useful. CUDA/OpenCL computation is a separate investment with transfer, scheduling, portability and determinism costs. Do not add it to avoid fixing broad invalidation or redundant work. Qualify CPU correctness and measure the remaining bottleneck first. Likewise, retained Proxy, automatic screen-size detail and out-of-core scenes remain independent experiments, not implicit deliverables of the collision redesign.
