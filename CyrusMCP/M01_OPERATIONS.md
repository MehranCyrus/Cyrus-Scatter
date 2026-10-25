# M01 operation integrity

Implementation started 24 October 2026. This is partial M01 work; host qualification and the remaining transaction/Undo contracts are open.

## Contract selected for this increment

F05/F06/F07/F09/F10/F11 apply. The native host owns scene changes and publication; the service owns bounded admission, approval, operation receipts and durable journaling. Existing plan 0.73 ownership and exact approval remain unchanged. No new remote write authority or higher workload limit is introduced.

Each operation reports execution `state` separately from `effects`: `none`, `committed`, `verified_rollback`, or `unknown`. A failed operation can have committed effects. A successful native return is a commit witness; later fingerprint, export, redraw or journal errors must not erase its result/identity or claim that nothing happened. Before-call failure proves no mutation. A throwing host call proves rollback only with an explicit verified rollback witness; otherwise effects are unknown unless the host supplies a committed receipt.

Journal records are bounded to 128 and persisted atomically. Unresolved records cannot be evicted. Queued/running records found after restart require reconciliation; preserve any committed receipt already recorded. Durability failures block further mutation while exact-key outcome reads remain available. Re-enrollment/disconnection must not clear that block. Recovery now provides the local-only review/retirement workflow below; there is no model-callable permission reset.

The native executor remains synchronous: Cancel before execution proves no effects; cancelling native work after entry is not promised. Committed failure must disable unsafe automatic Undo, invalidate the proposal scope and retain the prior/native result evidence. Normal successful own-top-Undo remains unchanged in this increment.

Static design enrollment already rejects animated inputs. Its fingerprint must therefore omit unconditional timeline time, while retaining units, evaluated geometry, transforms, ownership and authored settings. Inspection remains conservatively time-sensitive until its dependency model is qualified. Relevant same-frame changes must still invalidate design scope.

No placement-sized allocations or worker changes are introduced. Journal records add small effect/recovery fields and reuse bounded native receipts; layout rows remain in the existing export path. No scene data, credentials or asset payloads are added to the journal.

## Acceptance

- Normal approved generation succeeds once; exact-key replay never generates again.
- Verified rollback stays failed with `verified_rollback`; a preflight rejection reports `none`.
- A host commit followed by fingerprint/export/redraw failure retains its receipt and reports committed effects, blocks new mutations and cannot be cleared by scope reset.
- An unclassified host exception reports unknown effects and blocks new mutations.
- Journal admission/running/commit/terminal/cancel persistence faults never cause unjournaled generation, lose in-memory outcome queries or permit a new-key replay.
- Restart preserves commit evidence and blocks unresolved work. Journal eviction retains unresolved records.
- Static design fingerprint is unchanged by an unrelated frame change but responds to enrolled geometry changes. Inspection retains its conservative behavior.

Offline tests must execute production service/Journal code. Fingerprint tests execute the production method with bounded fake host data; they do not establish real Max geometry/evaluation behavior. Actual Max 2027 faults, native result retention, UI lifecycle, installed client discovery and package identities remain required qualification.

## Evidence

Baseline: 265 tests passed in 34.22 s, command `build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q --junitxml=build/mcp-foundation-20261024-01/baseline.xml`. The run directory contains the recorded pre-edit source identities. Post-change evidence will be recorded after execution.

First increment: **286 tests passed in 31.80 s**, same test directories with `--junitxml=build/mcp-foundation-20261024-01/after-final.xml`. There are 21 new parametrized cases covering effect witnesses, malformed receipt data, storage failures at admission/execution/commit/terminal boundaries, persistent storage loss, cancellation, restart, unresolved-record eviction and production fingerprint/preflight methods. Existing licensing tests now supply the real Fault dependency to their extracted-method harness and also assert no-mutation effects. The initial focused harness failure is retained in `focused.xml`; the full final suite passes.

Receipts retain small commit identity fields before JSON validation/copy, so malformed host metadata cannot erase a known commit or poison serialized outcome queries. Agent-facing recovery guidance and the MCP README describe the new fields. Scope reset cannot clear the mutation block.

The configured external integration currently advertises seven tools and its fresh connection status returned `OUTCOME_UNKNOWN` / local connection interrupted. This is recorded as an integration gap, not a newly executed apply or proof of a host crash. Source stdio discovery is covered by the offline suite; installed-client/current-native integration remains unqualified.

## Local recovery review and retirement

The Automation panel's **Review unresolved operation…** action prepares bounded evidence for one operation and zero/one selected supported setup. It shows the recorded effects, selected owner/generation, cached publication/count and current authored-state hashes where available. Optional technical details remain expandable. The default confirmation is No.

Confirmation rechecks the exact operation digest, scene epoch, selected evidence and a five-minute review lifetime. Storage must succeed before the mutation block can be cleared. Changed evidence, stale/used tokens, multiple queued operations or storage failures reject confirmation. Each unresolved record needs its own review. Neither prepare nor confirm exists in public dispatch or the MCP tool registry.

The action retires the operation **without replay or scene mutation** and revokes the prior scope/approval. It records local approval and evidence durably; the original execution state and effects remain visible. In particular, `unknown` effects remain unknown: this is an artist decision to keep the inspected scene and abandon the old operation, not a claim of rollback or proof that unobserved effects never happened. Fresh enrollment and proposal approval are required afterward. Snapshot comparison does not recertify source appearance, all transforms or the entire scene.

## Current native-buffer compatibility corrections

An owned Max 2027 run with the exact 0.86.9.2 pair exposed two real integration gaps:

1. A native placement value reported a nonzero count but direct pymxs iteration yielded no rows. The adapter's old loop skipped footprint checks and built an empty export while metrics reported a population. The execution-record count check caught the inconsistency after commit. The failed witness retains 202 actual cached placements and its committed-failure receipt. Local retirement preserved that scene.
2. The current native publication page carries a two-value XY/XYZ radius pair. The old reader expected a scalar and rejected the payload. A direct cached native sample confirms the pair; source inspection of `placement_publication_value.cpp` establishes its layout.

`MaxHost.placement_rows` now uses immutable native tokens and at most 500 rows per page, within the existing 2,000-candidate design admission. Every final row is checked and exported; incomplete/oversized readback rejects the transaction. Current materialized script arrays, including empty arrays, are explicitly indexed. No new placement engine or unbounded bulk conversion is introduced.

Publication page schema **2.0** reports `effective_radii_m.xy` and `.xyz` separately. The manifest advertises the page schema and available metrics. The reader validates both finite, nonnegative values and converts each to metres. There is no guessed scalar alias or implicit conversion for the separate experimental ranker's older input contract.

## Prior native/client evidence — run 04, 24 October 2026

- **315 offline tests passed in 37.33 s**: `build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q --junitxml=build/mcp-foundation-20261024-04/offline.xml`. This includes 50 additional parametrized cases since the initial 265-test baseline. Source hashes recorded before the suite remained unchanged.
- Owned profile `build/mcp-foundation-20261024-04/host01`, PID 55420, Max 2027; five loaded native file hashes match the staged exact 0.86.9.2/Analyzer 0.14.2 payload. All 22 frozen runtime Python/JSON files match current MCP runtime source. No artist profile, connection or scene was installed/restarted/modified.
- Real external MCP SDK stdio discovery exposes twelve tools. Approved two-layer creation reports **197 accepted placements from 240 requested candidates**. The execution export contains all 197 rows; every published-page transform matches the export. Configuration/diagnostics reads and viewport PNG capture pass. An unshared trace request is denied. These are bounded synthetic assets and candidate-budget semantics, not an exact-target or library-asset qualification.
- Static design enrollment remains fresh across an unrelated timeline change. This test does not establish zero native solves/uploads for every static display action.
- An injected pre-publication layer-construction failure produces verified rollback. An injected fingerprint failure after real native generation retains committed effects and its result. Local review/retirement then keeps the native scene state unchanged and the old receipt queryable.
- Full receipt: `build/mcp-foundation-20261024-04/host01/foundation-results-450f87d2e9ef47c59876bd8f573455bd.json`; artifact ID `3f42516948e7c6df1230b3fc65c6d90f3fb98abff09edb8feca6fd9575fb46e5`. Qualification/launch metadata, loaded module paths, scoped request/results, journal and viewport image accompany it.
- Earlier failing and intermediate witnesses remain in runs `-02` and `-03`; they are not promoted to current acceptance. Every owned host was closed cleanly. The reusable campaign is `tools/mcp/foundation_campaign.py`; its `resume` action observes the same recorded process after startup observation expires rather than relaunching it.

This is scripted owned-host/API evidence with a real MCP SDK client, not physical artist approval/UI interaction, a production Codex-plugin upgrade, broad renderer/material qualification, performance certification or all-native-feature acceptance. The configured integration's earlier seven-tool snapshot remains distinct from this source-built twelve-tool client.

Remaining work at that receipt included existing-owned refinement and failed-successor publication retention; the successor evidence below addresses those scoped scenarios. Wider Undo/restart/durability cases, selected-recovery inspection budgets, configure-only versus apply-and-calculate semantics and physical panel recovery acceptance remain open. M00 still needs operation-level coverage and final package/client alignment. Large-publication manifest per-set admission also needs alignment with current native limits and workload tests. M02–M13 remain open; this stage is not complete.

## Next refinement increment

The native fixture now checks same-controller replacement followed by own Undo, plus failed replacement at `layers` and `publish` checkpoints. Acceptance compares full cached row/identity/radius digests, layer identities, authored settings, generation tags, node count and an unrelated artist-object sentinel. A matching authored fingerprint alone is insufficient. Receipt files are written before assertions so a failure retains its actual native witness.

The existing native `cyrusPresetTrackPublication` implementation retains complete cache generations by reference for authored Undo/Redo. Inspect and reuse that boundary if the MCP replacement path lacks publication restoration; do not rebuild placement-sized Python state or treat ordinary parameter Undo as proof of native-frame recovery. Native changes, if required, need their own matched build/package qualification. No rollback guarantee is expanded until these scenarios pass.

### Refinement correction under qualification

Run `build/mcp-foundation-20261024-05` exposed two current-host defects. After a successful replacement, a deferred native callback assigned the initially empty root layer ID; the next freshness check rejected an unchanged scene. A separate, explicitly recorded raw native Undo probe restored the old child identities and generation tag but kept the newer **198-row** publication instead of the previous **131-row** result. That probe bypassed the already-stale service guard for diagnosis only and is not a passing service workflow. Both failed refinement receipts, the fingerprint trace and raw Undo witness are preserved.

The candidate initializes the new root identity inside its creation hold. Existing-owned replacement joins the existing `cyrusPresetTrackPublication` native checkpoint before changing settings or layers. New roots and child owners join `cyrusRecipeTrackCreated` immediately after creation, before configuration/calculation. Required native helpers and the helper's ten-child limit are checked before mutation; the smaller existing design admission remains in force.

Ownership remains with native immutable publication generations and Max's authored Undo hold. The native checkpoint pins previous/next generations by reference; it adds no placement-sized Python copy or solve. Undo history therefore retains native generations until the history entries are discarded. The existing native lifetime restore releases discarded, undone created-owner caches only when they have no scene-node dependents. This reuses the already packaged native implementation and does not change its allocator or claim a new measured memory bound.

Failure recovery now checks the previous immutable publication manifest/identity and owner/generation tags as well as authored fingerprint and removal of created nodes. A changed publication cannot be called a verified rollback merely because the parameters match. Any readback/restoration uncertainty remains an uncertain operation with the existing recovery guard. The native fixture additionally compares every cached row (including identities, transforms and both radius metrics), tests Undo/Redo, and injects failures at `layers`, `preview` and `publish`. Fresh run `-06` qualifies these scoped scenarios below; no native acceptance is inferred from offline mocks.

### Latest evidence — run 06, 24 October 2026

- **322 offline tests passed in 39.82 s**, `build/mcp-foundation-20261024-06/offline.xml`. This is 57 cases above the initial baseline. New regression cases deny false rollback on changed publication/generation, missing owner, surviving created node or authored mismatch. Recovery selection now rejects more than 32 child owners or 1,024 aggregate root/child source rows before detailed traversal; remaining large-field/read bounds still need review.
- Owned Max 2027 PID **52500** loaded the exact Scatter **0.86.9.2** / Analyzer **0.14.2** payload. All five loaded native module hashes match the frozen payload, and all **22 runtime Python/JSON files** match current source. Recorded runtime/test/fixture input hashes remain unchanged through both campaigns. Native C++ and packaged scripts were not modified for this fix.
- Successful same-controller replacement produced **135 → 189** accepted rows. The real local service Undo preserved freshness and restored the original rows, layer identities, authored settings, root ID and generation tag. Native Redo restored the successor. The unrelated object's handle, transform and dimensions remained unchanged.
- Failures at `layers`, `preview` and `publish` retain the complete previous **133**, **136** and **132** rows respectively. Every row digest, layer identity, authored hash, generation tag, node count and unrelated-object snapshot matches. Each operation reports `failed` / `verified_rollback`, and exact-key retry returns the same receipt.
- A separate real SDK stdio campaign discovers twelve tools, creates **200 accepted rows from 240 candidates**, exports all 200 and matches every published transform. Configuration/diagnostics reads, unshared-trace denial and viewport PNG capture pass. It also repeats unrelated-time freshness, new-creation failure rollback, a committed post-generation fault and local retirement with unchanged native scene state.
- Receipts under `build/mcp-foundation-20261024-06/host01/`: `refinement-567e497b2f624b849a379036629a3d55.json` and `foundation-results-652d4a1d102340b18dd35bebc6114da8.json`. Artifact ID **`787d6fdb6d77133e8e78ed63c7d2f144a1fe640437ceefdee0d869b924b81ab4`**. Qualification/launch records, requests, journal and native viewport image accompany them. Hosts from runs 05 and 06 were closed cleanly; the original seven-tool connection and artist profile were not changed.

These cases qualify this bounded replacement/Undo correction, not targeted editing, Manual configure-only behavior, all failure timings, physical artist approval, long-session memory, restart/adoption or a newly packaged MCP release. Next implement and qualify typed configure-only versus Update semantics without replacing stable layers or rebuilding the Manual publication. Preserve this successful replacement path and its historical/failing evidence while closing the wider lifecycle and operation matrix.

### Successor configure/Update increment — run 07

[Owned-change contracts and exact evidence](M01_CHANGES.md) now qualify typed count/seed patches through the actual SDK/native path, with 338 offline tests and 13 discovered source tools. Configure-only preserves the previous Manual publication and warm retained resources; explicit Update and Live combined changes preserve current owned layer identities and untouched settings. New failure checkpoints and configure/Update Undo/Redo pass. The existing complete replacement campaign also passes after sharing its native row verifier.

The separate SDK recovery campaign passes with **197 accepted rows from 240 candidates**, matching export/page transforms, configuration/diagnostics/capture, unshared-trace denial, unrelated-time freshness, verified rollback, committed post-generation fault and local retirement preserving the native scene. Receipt: `build/mcp-foundation-20261024-07/host01/foundation-results-4de66fd53779406aadc9644d38c11caf.json`, artifact `5611404e2e84a8e083fd0eaeb1ffa1ebb9c22de8ea58ee6a5337d1587ce407cb`. Owned PID 49552 was closed cleanly. No original configured connection, artist scene/profile or installed package was changed.

M01 remains in progress: complete selected-recovery large-field bounds, configure-specific crash/durability/uncertain-outcome cases, physical panel approval/recovery behavior and remaining lifecycle contracts. Durable resume/adoption and broader manual conflict handling also have explicit M05/M09 work. M00 still needs the operation-level matrix and installed-client/package alignment. These are development source increments, not certification of the entire MCP integration.

### Successor bounded recovery and panel evidence — run 08

[Selected recovery and Windows input evidence](M01_RECOVERY_BOUNDS.md) now supplies native cell/text/depth/aggregate admission before Python copying, configuration identity retained before receipt validation, and real panel approval, default-No cancellation and retirement with unchanged native rows/authored state. The configured post-commit witness preserves the old publication and new configuration across a real journal-object reload. Final suite: **341 passing tests**; the complete thirteen-tool SDK recovery campaign passes again. Failed native helper experiments remain historical evidence, not acceptance.

M01 still needs process-loss/host-restart, uncertain Undo failures, additional lifecycle/resource combinations and remaining interaction/artist acceptance. General scoped scene reads and returning/adopted setups require their M02/M05/M09 contracts; selected recovery's limits do not automatically qualify those paths. The [operation matrix](OPERATION_COVERAGE.md) now defines the required domain rows; full limits, combinations and delivery remain open.

### Successor real process-loss tests

[Three owned process-loss/fresh-host cases](M01_PROCESS_LOSS.md) now pass through the external SDK and Max 2027. Queued and unacknowledged native work remain unknown; a persisted commit/configuration witness survives unknown completion. Exact-key reads, new-key denial, immediate startup UI blocking, saved native settings/IDs and local retirement are verified. **349 offline tests pass**. Journal loading now rejects invalid state/effect/recovery data and duplicate identities, and oversized save preserves the old reloadable file. Approved-base target identity remains distinct from a commit witness.

M01 still needs uncertain Undo/finalization failure handling and broader lifecycle/storage/interaction combinations. These controlled terminations are not power-loss or arbitrary native/renderer crash certification. Cold reopen of pending Manual configurations reconstructed their publications; M09 returning-task/publication semantics remain explicitly unresolved rather than assuming the old warm frame persisted. See the exact observed populations and qualification limits in the linked report.

### Successor local Undo integrity

[Verified and uncertain local Undo](M01_UNDO.md) now covers admission, exact-top preflight, a native restored-state witness, durable receipts, committed presentation failures and unknown-completion recovery. **369 offline tests pass**. The owned Max 2027 campaign passes creation/refinement Undo/Redo, a fault after actual native Undo, a fault after verification and denial of an unrelated top history entry. The real thirteen-tool SDK regression passes configure/Update/Undo/Redo in proxy/Mesh/Point Cloud, three failed-successor phases, Live mode boundaries and configure-only Undo/Redo. The host closed cleanly; exact receipts, hashes and qualification limits are in the report. No native payload or product version changed.

Broader lifecycle/storage/UI and artist gates remain open. Next implement the [bounded scene/task onboarding contract](M02_SCENE_CONTEXT.md) and carry those gates into the affected feature campaigns. Metadata-only cards must not imply geometry understanding, adoption or write authority. The full M00–M13 goal remains active.

### Unsupported framing rejection — 24 October successor

The unrelated native-preset regression run
`build/mcp-preset-curves-20261024-03-offline.xml` passed 566 tests and observed a
Windows `ConnectionAbortedError` while testing unsupported chunked framing.
The existing transport rejects `Transfer-Encoding` before reading its body or
queuing a ticket. Its attempted JSON error is best-effort when a connection is
closed with unsupported input still arriving; this is distinct from a validly
framed authenticated RPC or an uncertain authored operation.

The test now separates those contracts: all validly framed authentication,
Origin and Host rejections still require a structured error. Five repeated
chunked requests carrying a correctly signed `scatter.apply_plan` payload must
either return `ok=false` or close/reset the connection, and must always leave
the queue empty. Timeouts and other errors are not swallowed. Production
transport/authentication/admission behavior is unchanged. The focused transport
suite passed 12 tests (`build/mcp-preset-curves-transport-20261024-01.xml`); the
full successor passed 567 tests in 40.77 s
(`build/mcp-preset-curves-20261024-03-offline-successor.xml`). The original failed
receipt remains preserved. This does not close broader M01 lifecycle or client
compatibility acceptance.
