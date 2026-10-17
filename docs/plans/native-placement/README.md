# Native placement pipeline — active implementation

Current execution: [measured N01 baseline and internal N02 storage work](EXECUTION_0860.md).
The active placement pipeline is still the qualified 0.85.4 route; no 0.86.0
installer or native-pipeline performance improvement is claimed yet.

17 October 2026. **Implementation resumed by the user’s [active objective](../improvement-program/OBJECTIVE.md). P01–P07 remain implemented.** The [reviewed implementation checkpoint](BASELINE_0854_20261017.md) is `7379ea3`, pushed and remote verified. First coherent native delivery: **0.86.0**, pending N01–N09 acceptance.

The following investigation describes the pre-implementation findings; its historical no-test statements do not override the fresh baseline receipt or active ledger. Baseline: delivered Scatter 0.85.4, schema 58, branch `codex/workflow-0.75`, HEAD `5aee4ef2242307b92e16c96e0106ee095d6a4215` plus existing dirty/untracked work. No product version changes, Max interaction, builds, installation, commits or pushes in this investigation. Slope/altitude behavior and settings remain outside the change scope.

## Recommendation

The [maintained foundation](../../ENGINEERING_FOUNDATION.md#native-foundation-and-language-boundaries) makes native bulk ownership, recovery and future time/state boundaries durable across tasks. Its physics/animation constraints guide this migration without adding a solver, asynchronous scheduler or animation product to N01–N09.

Move **bulk placement storage and transport** into C++, reusing the numerical algorithms already there. Keep the existing MAXScript UI, authored parameter blocks, layer management and small control messages. This is a migration of an existing pipeline, not a new scatter algorithm or a UI rewrite.

The largest opportunity is eliminating repeated conversion between native results and eight-field MAXScript rows. A second, separate opportunity is reducing CS Edit's full native map copies. Both matter: putting data in C++ does not automatically make its Undo cheap.

The intended artist result is the same planting and controls, with less temporary memory, cheaper large Count changes and preserved Undo. These are **acceptance goals**, not results already measured. Native execution alone does not guarantee an unblocked UI or unlimited counts.

## What inspection established

| Area | Current implementation | Consequence for the plan |
| --- | --- | --- |
| Generation, grids, much filtering and orientation | Numerical C++ functions, with script arrays between many stages | Retain algorithms; replace bulk transport and storage |
| 0.85.4 schedules/radii | Immutable native values with bounded script access | Extend this direction, with explicit shared generation ownership |
| Receiver/prepared/published placements | MAXScript arrays retained by controller locals; some stages share rows, others allocate new rows/matrices | Do not assume every array is a deep copy; trace aliasing and lifetimes individually |
| Procedural spacing | Native solver, but bridge constructs per-candidate string schedules and native sample copies, then returns script references | Use numeric identity and native views/indices without changing winner order |
| CS Edit | Native full `EditLayer` maps copied for calculation rollback and Edit Undo | Separate authored edits/selection from derived inputs, and replace large history copies |
| Preset Undo | Existing native restorer pins immutable script cache generations by reference | Preserve this behavior using native publication references; do not replace it with file reloads |
| Rendering/baking | PFlow groups transform arrays in MAXScript; Bake loops script rows | Include these consumers in the migration; report separately if a consumer remains transitional |
| Passive behavior | Existing Manual/Live gating and retained display caches | Preserve zero solves/uploads on idle and unrelated UI actions |

Evidence and source anchors: [source map and Forest comparison](SOURCE_MAP.md). Proposed ownership, Undo and memory contracts: [design](DESIGN.md). Executable sequence and task checklist: [implementation steps](IMPLEMENTATION.md). Required performance and Max 2027 evidence: [validation](VALIDATION.md). File identities are in [inspection manifest](EVIDENCE.json).

## Ordered work

These are migration steps **N01–N09**, independent of original P, improvement I and gallery PG identifiers. The active goal authorizes them first, then the remaining roadmap. Difficulty increases overall, but dependencies determine the order.

| Step | Work | Difficulty | Completion evidence |
| --- | --- | --- | --- |
| N01 | Freeze parity fixtures and measure allocations/Undo lifetimes | Low–medium | Comparable baseline and complete consumer inventory |
| N02 | Native placement store, bounded access, ownership and byte accounting | Medium | Immutable handles, lifetime/ABI/failure tests |
| N03 | Keep generation, Paint, masks and transforms native | Medium–high | Full ordered row parity; no internal script row expansion for migrated paths |
| N04 | Native radii, schedules, spacing and accepted indices | Medium–high | Same protected priority, collisions, refill, cleanup and stats |
| N05 | Native publication, preview and existing Undo integration | High | Atomic multi-layer publication and correct Manual/Live/preset history |
| N06 | Bounded inspection, native render consumption and bounded Bake | High | Same exact output; no hidden bulk script transform cache |
| N07 | Compact CS Edit storage and Undo | Very high | History cost follows authored changes, including dormant/copy/select cases |
| N08 | Final memory admission, cache release and responsiveness tuning | High | Measured peak reduction, bounded working set, no idle work |
| N09 | Full Max 2027 acceptance and exact-pair packaging | High validation effort | Signed-off matrix, MZP/EXE receipts, explicit remaining limitations |

Recommendation: complete one coherent path before broadening it. First prove simple Surface random → native placements → native acceptance → retained preview with ordinary Count Undo. Then add the existing optional stages, Edit and downstream consumers. Temporary comparison adapters belong in the qualification build; do not ship two indefinitely maintained placement engines.

## What will stay explicit

- Preserve F01–F12 as applicable, especially stable identity, stage order, independent collision scopes, Manual pending state, atomic publication and receiver-bound Paint.
- Keep existing candidate/retry/neighbor/geometry limits during the migration. Reassessing the one-million cap is a separate capacity decision after N09, not a shortcut for this work.
- Keep slope/altitude formulas, validation, units, protection and stage position unchanged. Only their row adapter would need to consume the native type.
- Preserve current scene/recipe identities and formats wherever storage is transient. Any necessary persisted Edit change requires a separately recorded format decision and round-trip tests before implementation.
- Keep Max SDK access and publication on the Max thread. Continue using the existing joined numeric worker executor. Background asynchronous solving is not assumed or silently added.
- Count-derived caches must not be pinned once per keystroke merely to make Undo appear instantaneous. Preserve authored history and use exact cached results or deterministic recomputation according to existing update semantics.

## Evidence limits and next action

The 0.85.4 [handoff](../memory-0854/README.md) records successful 50k/90k/200k Count tests and a cold 60k→90k copy. Those are historical baseline receipts, not tests of this proposal. No new host tests ran in this planning task. At this investigation’s original checkpoint the knowledge index reported stale enrolled parents, so direct source inspection supplied its evidence. The [subsequent knowledge repair](../../../tools/rag/KNOWLEDGE_REPAIR_2026-10-17.md) activated a reviewed fresh successor; it does not qualify this proposed migration.

Forest's inspected Lite 9.4.3 paths demonstrate native item storage, but its custom-item Undo copies two collections and its low-memory behavior remains unverified. Our immutable generation and compact-history proposals are Cyrus design decisions, not recovered Forest algorithms.

The next implementation action, if authorized, is N01, followed by the N02/N03 simple-path prototype and N04/N05 integration. Select the delivery version under [version policy](../../Release_Versioning.md#choosing-the-next-version) before changing product metadata. 0.85.4 remains the qualified baseline while implementation proceeds. Broader B26 stays open; completion requires the active goal and N09 acceptance, not this plan alone.
