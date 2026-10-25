# Local Undo outcome integrity

24 October 2026. M01 increment; the full milestone and master goal remain open.

## Behavior and ownership

The Automation panel's local Undo action now has a durable operation receipt,
separate from the creation/configuration receipt it reverses. Undo remains a local
artist action, absent from public MCP dispatch. The assistant can query its receipt
with `scatter_get_status` and must preserve an uncertain result rather than request
another Undo.

Before entry, the service requires a reconciled, fresh scope, no queued mutation
and its last owned revision. It saves admission and running state before calling
the host. The adapter also checks Max's busy state, its current lightweight Undo
witness and the exact top history label. A rejected preflight records no effects;
it never skips another history item or clears native history.

After native Undo returns, the adapter checks the earlier authored fingerprint,
immutable publication identity and owner/generation/configuration tags, plus
removal of nodes created by that hold. Only that complete witness permits
`native_undo_verified=true`. The result identifies restored owners, or identifies
the removed owned controller for a creation Undo. It does not certify appearance
or the entire unrelated scene.

- Successful verification records committed effects, revokes scope and proposal
  authority, and requires fresh enrollment for subsequent authoring.
- An exception after entering native Undo, or a mismatched restored witness,
  records unknown effects and blocks new mutation until local recovery review.
- A redraw failure after verification retains committed effects and the restored
  identity in a failed receipt. It also requires local review.
- Storage failure retains the best live effect witness and blocks further mutation.
  Reload of an unfinished record remains uncertain; it never replays Undo.

The service records known effects and small identity fields before validating or
copying the receipt, so malformed metadata cannot erase a known native effect or
poison journal/status JSON. Local retirement preserves original state/effects and
scene state; its existing bounded evidence and durable-save requirements apply.

## Resource and failure contract

The adapter keeps one lightweight witness: earlier owner/mask references,
fingerprint, publication identities, created-node references and the Undo label.
It is bounded by the existing enrolled task/transaction admission and replaced
only by a successful successor. A failed successor retains the preceding witness.
Scope reset clears it. No placement arrays or second native evaluator are added.

The already packaged native `cyrusPresetTrackPublication` and
`cyrusRecipeTrackCreated` helpers continue to own immutable cache retention and
release through Max's native history. This change adds verification and truthful
outcome handling; it makes no new measured history-memory guarantee.

Unknown completion deliberately does not attempt an automatic Redo, another Undo
or scene reconstruction. Those would introduce another unapproved uncertain
mutation. Reopened-task reconstruction remains the separate measured M09 gap in
[the process-loss report](M01_PROCESS_LOSS.md).

## Qualification

Fresh run: `build/mcp-undo-20261024-01`. The exact packaged Scatter 0.86.9.2 /
Analyzer 0.14.2 pair is staged in an owned Max 2027 profile with frozen MCP runtime
and private fixtures. Runtime version 0.73.0 remains development; no product
version, native binary or generated MAXScript changed.

The initial offline suite passes **369 tests in 37.75 seconds**, including 20 new
Undo cases (`offline.xml`). After the small panel correction described below, the
final suite passes **369 tests in 33.42 seconds** (`offline-final.xml`). Tests exercise the production coordinator
and extracted host methods for native preflight, verified/uncertain completion,
malformed known-commit receipts, each journal-save boundary, pending-operation
serialization, durable queries, reload guards and authority revocation. These do
not substitute for native execution.

The five-case native campaign passes in owned PID **51292**, artifact
`789f85ef616d3b52e26dba23201f6ac71f62e164e51ce57b0b8ab038a4e0cdd6`:
`host01/undo-08d31faf5b894babb441fb8a7881a45a.json`.

- Creation Undo removes exactly its created nodes, preserves an unrelated object,
  revokes scope, and leaves a queryable succeeded/committed receipt. Native Redo
  restores the exact authored state, full published-row digest and identities.
- Refinement Undo/Redo restores earlier/newer complete publications and authored
  state. The restored earlier result has 135 rows in this fixture.
- An injected failure immediately after actual native Undo records
  outcome_unknown/unknown, even though the independently inspected scene has the
  earlier 132-row result. Local retirement preserves that result and keeps effects
  unknown. Inspection does not retroactively promote the operation to success.
- An injected presentation failure after verification records failed/committed
  with the restored 131-row identity. Local retirement preserves the result and
  original committed evidence.
- An unrelated sentinel edit at the top of history causes failed/none without
  undoing either that edit or the current 204-row publication.

Every applicable comparison includes all published rows, authored hash,
generation/configuration tags, root/layer IDs, node count and an unrelated object's
identity, dimensions and transform. Private fault controls/local confirmations are
not public MCP tools.

The real SDK stdio regression also passes, with 13 source tools and all three
display modes: configure retains the previous publication; explicit Update changes
accepted counts **138→173** (proxy), **129→166** (Mesh), **135→163** (Point Cloud).
Update Undo/Redo restores exact pending/complete publications and authored state.
The three existing change fault phases retain the complete previous publication.
Live configure-only is denied, Live combined configure/Update passes, and separate
configure-only Undo/Redo restores old/new authored settings and configuration tags
while retaining the same publication. Receipts are
`host01/changes-42316b737ff44b62bfaaa69c5c59111b.json` and
`host01/change-edges-604dbce47d354dddbbe5a1d2d0ec5a8c.json`, under the same artifact.

All 24 frozen runtime Python/JSON files matched source during these native runs;
all five loaded native hashes match the staged exact pair. The owned host closed
cleanly afterward. A subsequent small panel correction keeps its connection label
when Undo is rejected and clears the diagnostic-share checkbox after successful
scope revocation. That display branch awaits the next native panel/UI campaign;
the qualified coordinator/adapter code is unchanged. The frozen panel copy and
original run remain preserved.

Physical UI interaction, artist consent, all history/storage/lifecycle boundaries,
all-native-feature parity and final package/client acceptance remain separate gates.

The successor run `build/mcp-scene-20261024-02` also passes the five-case Undo
campaign through the actual panel methods, with source SDK now exposing fourteen
tools. `host01/undo-85724104a111430da70e5b87ba0c1187.json` verifies the earlier
connection-label correction: successful Undo shows no scope; uncertain/committed
failures show local review and disable another Undo. This is scripted native
widget-method evidence, separate from the physical task-editor input described in
[M02](M02_SCENE_CONTEXT.md).
