# 10 — CS Edit Internals

## Identity

Native modifier Class ID:
`Class_ID(0x43b612e9, 0x578124cd)`

Descriptor:
- Class: `Cyrus Scatter Edit`
- Internal name: `CyrusScatterEdit`
- Category: `Cyrus`
- SuperClass: `OSM_CLASS_ID`

## Row model

`EditRow` stores:
- `inputId`;
- `outputId`;
- source index;
- transform delta;
- deleted flag;
- selected flag.

Copies receive new persistent output IDs.

## Stack model

`cyrusEditStack` starts with base identities `b:<row-index>`, then applies enabled CS Edit modifiers from lower to upper while preserving stable IDs.

`applyStable()`:
- migrates legacy index-based layers when mapping is provable;
- marks ambiguous/base-generation changes invalid;
- remaps incoming IDs to current source rows;
- suspends missing inputs rather than deleting their edits;
- lets new incoming IDs pass through;
- emits only non-deleted currently-present rows.

Identity metadata remains native; downstream scatter/PFlow still receives `#(transform, sourceIndex)`.

## Persistence

Current save chunk: `0x4001`.

Loader also reads legacy `0x3901`.

Current chunk stores per layer:
- key;
- signature;
- invalid/legacy flags;
- rows;
- source;
- delta;
- deleted/selected;
- inputId/outputId.

Safety guards limit layer count, row count and string lengths.

## Interactive modifier behavior

The modifier supports subobject selection and Max transform modes:
- Move;
- Rotate;
- uniform/nonuniform Scale;
- Delete;
- Clone.

Undo/redo uses `RestoreObj` and the Max hold system.

## Fingerprints/topology

`cyrusEditFingerprint` hashes placement position/source plus caller-provided signature using FNV-like 64-bit accumulation.

`cyrusEditTopology` hashes surviving row/source topology.

Base seed/layout changes are intentionally considered different base generation and can invalidate edits.

## Historical migration

The 0.40 guide documents the transition from 0.39 index-based records to stable persistent identities. Ambiguous old mappings are retained rather than guessed.

## Licensing implication

Evaluation of saved edit state must remain available for scene fidelity/render. Interactive mutation commands are a separate `ModifyScatter` capability.
