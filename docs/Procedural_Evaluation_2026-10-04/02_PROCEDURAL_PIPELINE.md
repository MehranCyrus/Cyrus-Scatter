# 02 — Procedural ownership, execution and publication

Status: proposed next evaluation policy. Preserve existing policies for existing scenes.

## A small dependency system, not a new general-purpose application

Use a fixed set of typed stages and revisioned outputs. A visual node editor is unnecessary. The artist sees ordinary native layers and Paint Sets; internally the evaluator knows which outputs each stage consumes.

```mermaid
flowchart TD
  A[Receiver snapshot and sampling settings] --> B[Stable candidates per set]
  A --> C[Source metadata and effective settings]
  B --> P[Movement and resolved support anchors]
  P --> D[Coverage and area eligibility]
  C --> E[Source assignment and transforms]
  D --> E
  Q[Authored records and validated bindings] --> F
  E --> F[Edits and effective radii]
  F --> G[Ordered layer solve]
  H[Completed occupancy of earlier layers] --> G
  G --> I[Layer union cleanup and bounded repair]
  I --> J[Immutable completed layer result]
  J --> N[Solve the next dependent layer]
  J --> K[Controller publication]
  N --> K
  K --> L[Point Cloud / Proxy / Mesh packets]
  K --> M[Final output / diagnostics / export]
```

Each logical layer is a distinct node in a finite ordered sequence; only relevant earlier results feed it. Cleanup repair is a bounded internal operation, not an unrestricted graph cycle. Publication waits for all required changed layers.

## Ownership

| Owner | Owns |
| --- | --- |
| Controller | Receiver references, units, policy/schema versions, ordered layer IDs, update/display defaults and publication |
| Layer | Ordered set IDs, population allocation, shared area/transform defaults, inter-layer rules, shared cleanup |
| Paint Set | Stable identity, source entries, coverage document, set weight, effective self-spacing rule and set-pair references |
| Source entry | Stable asset identity/reference, weight, artistic radius, follows-scale setting and source transform settings |
| Candidate/instance | Stable procedural key, surface anchor, selected source, transform, effective radius, edit flags |
| Rule | Scope, stable endpoints, metric, radius coefficient, extra gap and enabled state |

Adapt existing parent/base-set storage into this normalized read-only view. Do not initially recreate scene objects merely to obtain cleaner C++ structs. A copied layer/set must receive new identity namespaces while retaining the intended settings and copied Brush data.

Keep three concepts separate: **ownership identity**, **sampling key/seed**, and **execution order**. A copy gets new ownership IDs and remapped internal references; it may retain the same sampling recipe. A reorder changes collision precedence, not the seed or allocation tie-break key. Current child-set seeds depend on Edit keys, so identical-looking copies under the new contract require an explicit adapter, not an assumption about existing behavior.

## Ordinary order and dependencies

1. Persist explicit `layerOrder` and a `setOrder` inside each layer. These are IDs, not names or current UI selection.
2. Earlier items win ordinary collision conflicts; later items adapt to completed earlier results.
3. A relationship's distance can be symmetric while its winner is determined by order. Two-way distance checking does not imply two-way procedural recomputation.
4. Skip occupancy dependencies for unrelated pairs. A later layer with no relevant rule or fill relationship need not depend on all earlier layers.
5. Shared population allocation is an upstream dependency of siblings. Changing one weight can change several sets' candidate budgets.
6. Shared layer cleanup depends on the accepted sibling union. Initial selective caching may therefore invalidate the whole layer solve while still reusing each set's prepared candidates.

Persist a stable allocation tie-break key independently of `setOrder`. Reordering equal-weight sets must not incidentally transfer remainder candidates. A changed winner set can still change the final accepted composition through spacing; that is the intended consequence of reordering.

Show the effective sequence in the UI. An explicit reorder is one Undo transaction and invalidates the affected relationship consumers. Import old scenes using the **current effective priority/Edit-key order**, not an assumed visible order.

## Stage contracts

| Stage | Input → output | Required behavior |
| --- | --- | --- |
| Snapshot | Max references + validity → owned receiver/source data | Host-safe capture, explicit units and geometry/topology identities |
| Candidate generation | Surface sampler + sampling key/seed + ordinal range → anchors | Stable keys before filtering; ownership IDs label results without silently reseeding them; no display budget |
| Movement/support | Latent anchors + procedural movement/projection → resolved support anchors | Record surface correspondence separately from the final mesh origin |
| Eligibility | Resolved support anchors + area + Brush/density fields → accepted candidate view | Evaluate each probabilistic factor once at its declared coordinate; report reasons |
| Assignment/transforms | Candidate random channels + effective source/settings → instance proposals | Deterministic attributes; source Z offset/scale and final movement precede radius/spacing |
| Authored edits | Eligible proposals + validated edit records → edited proposals and active reservations | Validate owner, input membership, source and binding; deletes never reserve space; clones have distinct output IDs |
| Radius | Source metadata + final transform + override → metric radius | Never scale the object as a side effect of a spacing edit |
| Layer solve | Prepared sets + relevant upstream occupancy + rules → accepted views | Three scopes, stable order, protected-first, insert only accepted ordinary proposals |
| Cleanup/repair | Accepted sibling union + cleanup/fill policy → completed layer | Removal-only cleanup; bounded reconsideration; no transient blockers leave this boundary |
| Publish | Consistent set of completed layers → controller generation | One coherent revision, statistics and output digest |
| Display | Published placements + source display data + display settings → packets | Camera changes consume packets without placement generation |

The exact mathematical order is part of the versioned policy. Distinguish the sampled **latent anchor**, the **support anchor** after procedural movement/projection, and the **final instance origin** after source offsets and artist edits. Ordinary painted proposals must pass eligibility at their resolved support anchors. A deliberate source Z offset may lift the mesh above that surface; do not reject it because its final origin is no longer on the receiver. Collision uses the declared final-origin convention independently.

Painted movement retains the current projection guard until another contract is qualified. Unpainted free world movement remains a supported explicit mode; it must not acquire an accidental requirement that every final origin lie on a receiver. Specify the sampling coordinates of density, area and cluster assignment in the new generator adapter and preserve old-policy coordinates unchanged.

For new-policy projected painting, evaluate probabilistic coverage at the final support anchor once. Sampling a 50% field twice independently produces 25% acceptance. Even reusing the same threshold at both the old and new position implicitly intersects those two tests; that differs from testing only the final support anchor. Preserve a stable per-candidate threshold for repeat evaluations, but do not accumulate repeated thinning. These are new-policy semantics requiring fresh fixtures, not a correction to apply silently to old scenes.

## Cleanup and the released-space problem

Suppose an early flower candidate blocks a later grass candidate. Union cleanup then removes the flower. The cleaned flower must not block the next layer, and the grass candidate should be eligible for reconsideration when gap filling is enabled.

A single pass cannot both know the final union cleanup and use that future result during every earlier sibling decision. The recommended first implementation is a **bounded layer transaction**:

```text
capture fixed external occupancy, prepared inputs and active authored reservations
start the policy's canonical logical candidate-prefix schedule
cleanupSuppressed = empty set of candidate IDs
for a bounded number of repair rounds:
    resolve sets in order from the logical prefixes exposed for this round
        skip candidates suppressed by cleanup in this transaction
        use only accepted ordinary candidates and explicit reservations as blockers
    run the existing removal-only cleanup on the sibling union
    keep protected edits; record conflicts and cleanup diagnostics
    remember newly cleanup-removed ordinary IDs in cleanupSuppressed
    if targets and repair conditions are satisfied: finish
    if budget permits: expose the next scheduled prefix for underfilled sets
    if neither suppression nor candidate pool changed: finish
publish the last cleaned result, with underfill/repair-limit diagnostics
```

Rebuild scratch occupancy on replay, rather than retaining removed blockers. Previously collision-rejected candidates stay available and may succeed after cleanup releases space. Future logical layers consume only the last cleaned layer result. After a replay limit, do not claim every newly freed location has been reconsidered.

Cache capacity must not decide the exposed prefix: a warm pool may contain more candidates than a cold build. Always run the same logical schedule for the same input policy/budgets. Cleanup suppression makes logical batch boundaries observable, so fix and version those boundaries. Physical worker chunk sizes may vary only if they preserve that logical schedule and result. Increasing the work limit can change final membership; only the underlying candidate stream has a prefix guarantee.

The temporary suppression policy avoids repeatedly accepting the same cleanup-rejected point forever. It also biases the result: a suppressed point might have gained neighbors from a later batch. This is a deliberately bounded, deterministic heuristic, **not maximal packing or an optimal density solver**. Suppression is scoped to one transaction, not persisted as an artist deletion. Record its count and policy version. Qualify this choice against the no-refill baseline before enabling it by default.

Cleanup retains its current single-pass neighbor/component semantics. It does not assert every survivor still has the requested neighbor count after other points disappear. Iterative graph pruning would be a different feature and algorithm version.

Removal cannot introduce a distance collision. Consequently the final cleaned subset remains collision-valid, except declared protected conflicts, even when a work limit stops further filling. A work limit may cause underfill; it must never justify publishing intersecting ordinary proposals.

## Protected artist edits

Capture protected records as a separate authored-input dependency, then resolve **active reservations** after validating their bindings and eligible inputs, before ordered solving. A stored record alone is not an active blocker. This explains the exception where a manually positioned plant in a later layer can reserve its location against an earlier procedural layer. It is not a backward dependency on a later computed result, and ordinary manual transforms need not invalidate candidate generation.

- Disabled owners contribute neither ordinary proposals nor protected reservations.
- Viewport-hidden owners retain their evaluation/output participation.
- Deleted instances contribute no reservation.
- Conflicting protected instances survive and receive diagnostics; do not call the result entirely collision-free.
- Unresolved source/anchor/edit bindings receive an explicit error or conflict state, not silent rebinding to another plant.
- A protected plant outside its coverage remains an authored exception with a visible diagnostic, according to the selected edit policy.

Current CS Edit emits a row only while its input ID exists in the incoming eligible population. Erasing the input anchor's painted membership therefore suppresses its bound edits/clones, while retaining their stored records. This is different from moving an otherwise eligible plant outside coverage. Preserve that distinction. Current base-generation signature changes can require an explicit Edit reset; do not promise that arbitrary count/seed/topology changes already preserve bindings.

The proposed accepted-target policy preserves valid protected instances even when their count exceeds the target. Supporting that when quotas shrink requires reconstructing and validating their input anchors independently of the ordinary candidate prefix. That adapter is a release gate. Until qualified, reject an incompatible conversion/change without deleting records; do not turn stale records into unconditional reservations. See the zero-weight and identity contracts in [11](11_OPTION_CONTRACTS.md).

## Update, cancellation and error behavior

Manual mode retains the last completed generation and labels it pending. Live mode coalesces changes and computes a new result; it must not restart generation on each redraw. New input cancels or supersedes a pending job. Verify the captured input revision before publication and discard obsolete results.

Use immutable stage outputs and build temporary replacements. Publish a new controller generation only when all required changed layers succeed. Reuse unchanged layer outputs by reference. Errors retain the previous good result and identify the failed owner/stage; they do not combine new layer A with stale dependent layer B while claiming a complete generation.

This boundary includes transient CS Edit selection/publication state, statistics and display consumers. The current `cyrusEditPublish` path updates modifiers sequentially; it is not proof of an atomic multi-consumer transaction. Stage and validate those updates before commit, or retain a rollback snapshot and test injected failures. Cache-key construction and configuration reads must not mutate saved settings or publish results.

The initial implementation can remain synchronous at the current safe execution boundary. Asynchronous workers are a later scheduling change, with cancellation and lifecycle tests, rather than a prerequisite for correct dependencies.

## Relax and future procedural effects

The existing painted/shared-policy Relax restrictions remain visible until explicitly replaced. Do not remove a guard just because the collision solver improved.

A future Relax stage must propose moves, project them to the correct receiver, revalidate area/coverage and all applicable spacing rules, then update its spatial index. Moving points after collision without those checks invalidates the result. It needs independent curved-surface, boundary-crossing and identity tests.

Every later effect should declare: input attributes, produced/modified attributes, identity behavior, affected revisions, CPU/host requirements and whether it can add, remove or move points. A small common stage contract is enough to support future modifiers.
