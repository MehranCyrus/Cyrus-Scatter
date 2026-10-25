# Approved prepared-source use — implementation contract

24 October 2026. Implemented with scoped offline, Max 2027 / real SDK and scripted
native-widget evidence below. Not a release or completed M03 qualification.

Reuse the existing portable package worker, finite material adapters and native
mesh creation. A separate local source-package grant allows approved creation
of hidden, non-rendering source copies in a selected scene task. The selected
scene objects remain read-only. Model calls never choose a path, start file
scans, approve proposals or import `.max` files. Package preparation is local,
bounded, cancellable and separate from scene mutation.

The model sees physical source bounds, stable references to one immutable
prepared revision, readiness limits and resource budgets. It selects source
references, validates a typed use proposal, waits for exact local approval and
uses the existing apply/status/idempotency journal. Import receipts identify
new source nodes and the pinned package revision. Success adds only these nodes
to the same task as source roles; design enrollment remains a separate grant.

Ownership: the operation owns only its new source nodes. It does not replace
artist sources, attach layers, change existing materials, move selection or
calculate placements. Native Undo owns imported geometry/material lifetimes;
the shared prepared handle owns copied package data until local revoke/reset.
Bitmap files use the existing hash-addressed imported-asset cache and remain
available for saved scene references; revocation/Undo must not delete them.

Admission: at most three package nodes and three selected imports, no packaged
receivers, splines or Point/container nodes; graph <=256 KiB, recipe <=128 KiB,
128 files/maps and 64 materials; declared files <=64 MiB, mesh files <=32 MiB,
and image pixels <=64 million. The actual two-source package has 51,985,254
pixels and 17,448,773 payload bytes, so the first 16-million-pixel proposal denied
it before any preparation or scene mutation. The successor uses the existing
native plant admission before preparation and again before staging: six encoded
mesh equivalents, two RGBA32F image equivalents and 1 GiB base allowance, with
an additional 2 GiB available physical/commit reserve. This is a conservative
admission estimate, not measured peak process memory or a maximum-load pass.
Native validation checks full package hashes/types before a grant is
ready. Source geometry remains <=1 million vertices /2 million triangles total;
decoded source mesh storage <=128 MiB. These are admission ceilings, not proven
maximum-size latency or process-memory guarantees. Preparation/native mesh,
live copies, shader/bitmap state and Undo can coexist; measure peak/history
memory in M12 before expanding the cohort or ceilings.

Freshness: exact task/scope/revision and prepared revision are pinned to review.
Role/brief changes, geometry-sharing changes, reset/open/disconnect and grant
replacement/revoke invalidate approval. Prepared mesh bytes are immutable;
content changes require explicit local re-preparation. Native stage rechecks
finite renderer profiles and cached image identities. Imported physical scale
uses package metres and current system units, never a guessed catalog label.

Failure: admission/journal errors before native entry have no scene effects.
Track each native-created node immediately, including nodes created before a
later stage error. On failure, restore through the authored hold and verify the
tracked nodes are absent, scoped native state/selection and prior Undo history
are retained. If that cannot be established, record unknown effects and require
local reconciliation. Preserve committed source identities before completion
bookkeeping; post-commit failures never authorize replay. Local Undo requires
the matching top history entry and verifies the owned nodes and earlier scope.

Qualification must cover actual grass/flower meshes/materials, same-task role
binding and subsequent design use; missing approval, revoke/stale/tampered
input, busy host, license denial, cancellation, duplicate apply, journal and
post-stage faults, prior-history Undo/Redo, scene reset/open/close and old-build
denial. Offline tests and the previous private native staging proof alone do
not qualify this public operation. B38 remains open for the original GUI merge.

## Implemented workflow

The source server exposes nineteen tools and seven resources. The new
`assets_validate_use` takes `cyrus.asset-use/1.0` with scope/task/task revision,
prepared grant, selected opaque source references and `destination=task_sources`.
Its schema rejects paths and extra fields. `scatter_apply_plan` queues this
validated operation through the existing approval/idempotency/journal machinery;
`scatter_get_status` reports its original receipt. Imported sources do not consume
the two planting-application budget. A grant currently permits one source-copy
operation; choose all intended sources together or share a new grant locally.

Task details / Shared content provides **Share prepared source package…**, status
and revoke controls. Only the locally selected bounded package is prepared. A
ready grant exposes physical geometry facts and immutable references; existing
`.max` catalog references do not become importable. The native review names the
source copies, metre dimensions, topology, revision, hidden/non-rendering state,
resource upper bounds and persistent bitmap/Undo effects. After exact local
approval, native staging creates only selected source nodes, preserves selection,
stamps ownership and adds source roles to the same task. Max may uniquify display
names; receipt asset references, not names, establish correspondence.

The fixed internal helper stages only selected nodes, in request order, with
animation disabled during authored geometry/material creation. It tracks nodes
immediately through the generated `CyrusAssetStage` optional `createdNodes`
argument. Other native package/recipe consumers retain the default behavior.
`cyrusAssetPreparedSourceInfo` returns bounded scalar metadata from an immutable
prepared mesh without creating temporary scene nodes. Native source API 1 and
tracked-stage API 1 are both required; older matching pairs deny the feature.

The local Undo result has its own journal receipt and verifies removed nodes,
earlier scoped state/selection and Undo history. Successful Undo clears transient
task/grant state under the existing policy; returning-task restoration is still
M04/M09 work. Native Redo can restore the source nodes without a new MCP import.
Operation receipts are commit-time witnesses; they do not imply that those nodes
still exist after later artist edits, Undo or a scene change.

## Executed evidence

Repository branch `codex/workflow-0.75`, HEAD
`588abff0ce211d7dc63798b8c5310631895465c7`, with concurrent tracked/untracked work
preserved. The native prototype retains caption 0.86.9.2 and independent Analyzer
0.14.2, distinguished by exact hashes; it does not replace the frozen delivery.

- `build/mcp-prepared-sources-20261024-01/receipt.json`: clean Max 2027 SDK build,
  **58 native suites pass in 23.94 s**. Input manifest:
  `b7e965f3cce7f1d1b3639cc2f0d12086ddb0748b3f2b33f4740e2e5a808ecfcb`.
  Main native module:
  `5f9f7152133089260d0b2bcd81a1e6d63c85d01468c12775bbbe61ff0b73b2d4`.
  Generation/check and approved-layout guards pass. These build/pure suites do
  not independently prove the new MaxScript keyword or live source workflow.
- `build/mcp-prepared-source-use-20261024-03/offline.xml`: **491 Python tests
  pass in 37.023 s**. New tests cover separate grants, exact approval, same-task
  binding, idempotency, cancel/revoke/stale refs, metadata budgets, journal
  failure and none/rolled-back/committed host outcomes. Their fake host faults
  are contract evidence, separate from actual native failures below.
- Final successor `build/mcp-prepared-source-use-20261024-04/offline.xml`:
  **493 tests pass in 36.682 s**. Two additional tests execute the actual host
  method against a runtime double: license denial precedes the native hold,
  and a post-commit completion fault preserves committed identity while leaving
  `selection_preserved=null`. The earlier focused test's misplaced `tmp_path`
  assertion failure is retained in run 04 `focused.xml`; its passing successor
  is the full suite above.
- Run 03 `host01/prepared-assets.json`, owned **PID 53060**, now closed: real
  nineteen-tool official SDK/client and matched native/script pair. Local native
  proposal review/approval widgets are invoked programmatically. Actual package:
  A069 grass and A062 flowers, two meshes, twelve materials, 61 maps, 48 files,
  17,448,773 payload bytes, 1,730,788 encoded mesh bytes and 51,985,254 image
  pixels. The inherited conservative native working estimate is 2,747,654,680
  bytes plus its 2 GiB available physical/commit reserve; this is not a measured
  process peak or residency result.
- Its first case denies an unapproved apply without scene change, imports both
  sources in deliberately reversed request order, and verifies same task/roles,
  opaque-reference correspondence, physical geometry, preserved selection and
  earlier Undo history. Auto Key remains enabled at frame 160 while new sources
  remain static. Exact-key replay returns the original operation. Local Undo
  removes only the two sources; native Redo restores their geometry, source refs,
  hidden and non-rendering state after the preparation handle was released.
- A real injected failure **after both nodes were staged** reports verified
  rollback and retains the complete earlier state/history. A newly approved
  operation then succeeds on the same unchanged task/grant. Its separate design
  handoff releases the prepared handle, preserves task ID and uses both imported
  source meshes in native planting. **143 actual rows from 160 candidates**
  (73 flower /70 grass) match the exported publication. Shortfall is explicit;
  these are candidate budgets, not exact targets or density.
- A modified graph without its declared manifest hash is denied during native
  preparation, releases the handle, shares no ready sources and preserves scene
  state. Campaign artifact:
  `97519a1002e2d9d5898ddbd54f0787cae5f442df9e217f1b7db5210bfa19d556`.
  `increment-receipt.json` confirms all **30 frozen runtime files** match current
  source and all **five actually loaded native hashes** match the staged pair.
- Run 03 `prepared-assets-lifecycle.json` qualifies ready-grant release on local
  disconnect, actual native reset, owned save/reopen and panel close. After close,
  a separately bound private read verifies grant/token/reference/task release and
  closed bridge. Artifact:
  `3acfd86263486e9dd6dfc8611b928c7c86ed6799b52afe795837cb1b005182a3`.
  It does not claim interruption of an actively reading file worker.
- `build/mcp-prepared-sources-old-20261024-02/host01/prepared-assets-old.json`,
  owned **PID 11056**, now closed: exact historical packaged 0.86.9.2 / Analyzer
  0.14.2 pair, current thirty-file source runtime/nineteen-tool SDK. Native asset
  capability is absent; sharing is disabled, direct local preparation is denied
  before file access, remote validation has no grant, and scene/selection/history
  remain equal. Loaded native hashes and runtime/source equality pass its
  increment receipt. Artifact:
  `84a3ccdf21150a48801ea880882d23fa225d48111f9e8431cc3691f753dcb5ba`.
  This is negative compatibility evidence, not current-source qualification of
  the historical payload.

### Final post-commit successor

Run 04, owned PID 33736, repeats the complete scripted-widget/SDK workflow on the
final source and adds a fifth actual native fault case. It publishes **139 rows
from 160 candidates** (65 flower /74 grass), with matching actual export. Run 03's
143 rows remain its own fresh-scene witness; these independently created owners
are not a cross-scene deterministic-equivalence test.

After the native source hold commits, an injected completion fault reports
`failed` with **committed effects**, retained asset-use/source identities and
`selection_preserved=null`. Exact-key retries return that original outcome;
new writes require local reconciliation. A private local check verifies the two
expected source nodes and geometry; the existing local retirement review then
keeps the scene without replay or deletion and retains the historical committed
effect. Its generic recovery view still does not identify an asset group as a
Scatter controller or prove absence of other effects. Source-focused returning
task/adoption remains an M09 prerequisite.

Final workflow artifact:
`899e3bed26404095cfa65b37cda779dc33e9d0c2d17fdd6dcbea59241587e78f`.
Its `increment-receipt.json` verifies all thirty frozen runtime files against
final source and all five actually loaded native hashes against the matched
payload. Older source equality claims above describe their observation time;
this successor changes the post-commit witness boundary, not the old-pair
capability-denial path.

Run 04 also repeats all four grant lifecycle cases successfully. Final lifecycle
artifact: `a15ba211f7ea83843a682845bcb9f765e095be245d7ee1e7c183312979400bd9`.
Its close receipt records PID 33736 closed. Python compilation and tracked diff
whitespace checks pass; Git emits existing CRLF normalization warnings. All
owned sessions from this increment are closed.

## Preserved failures and remaining acceptance

Run 01 denies the actual image cohort under the initial 16-million-pixel limit
before preparation. Run 02 records a missing hidden/non-rendering review phrase;
the corrected final source includes it. An API-only follow-up imports and verifies
Undo, but its private driver incorrectly compared display names instead of opaque
references. Max's normal unique-name suffixes explain that assertion; no engine
reordering repair was needed. Final run 03 checks both reference order and matching
geometry. The first old-pair launch copied an internal historical producer and was
correctly refused because current source changed. No host was launched for that
attempt; its files remain preserved. The successor uses the original verified
historical MZP pair via the supported historical-package qualification path.

Private fixture corrections do not count as additional product coverage. All
owned processes used here are closed. No artist profile installation, restart,
commit/push, published package, training/telemetry or external asset upload is
performed. Existing B38 `.max` GUI import remains unfixed and excluded from MCP.

Finish linking installed content to vetted prepared packages, preset discovery
and approved settings/full-recipe use, broader source/units/dependency scenarios,
source-import-specific busy/license/storage/process-loss witnesses, artist
interaction, rendered material/UV/normal equivalence and workload/memory/latency
qualification. General proxy types, receiver/context package import and arbitrary
shader constructors are not silently enabled. Full M03/O09/O66–O68, M04/M09
returning-task behavior, intended installed-client packaging and the wider
M00–M13 matrix remain open.
