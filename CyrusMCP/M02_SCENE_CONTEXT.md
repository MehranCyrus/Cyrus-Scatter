# Scoped scene context and reusable task roles

24 October 2026. M02 contract and increment evidence. The initial read-only path
below is implemented; the full milestone remains in progress. Follow [the milestone goal](IMPLEMENTATION_GOAL.md),
[scene onboarding](SCENE_ONBOARDING_WORKFLOW_20261023.md) and operation rows
O03/O04/O09/O25 in [the coverage matrix](OPERATION_COVERAGE.md).

## First useful increment

Add a read-only onboarding scope for explicitly selected scene objects. An artist
can share a small selection and a brief before preparing a valid Scatter design
site. Reuse `scene_get_context`; discovery must truthfully distinguish onboarding
metadata from current design admission and cached Scatter inspection. A broad
catalog or an onboarding role must never promote a scope into write authority.

Start with a declared small object-count and response-byte limit. Reject an
oversized selection before traversal. Read bounded native metadata first; do not
walk all scene objects, expand every hierarchy, export geometry, reconcile source
containers, calculate Scatter or render while connecting. Explicitly report
uninspected geometry, omitted neighbors and measurements unavailable at this stage.

Use opaque task references backed by the actual native object references. Names
are display hints and untrusted data. No name-based lookup or same-name replacement
rebinding is permitted. Rename retains the binding; deletion makes it missing.
Scene reset/open clears transient authority and references. Durable continuation
and cloning/merge/XRef policies remain M09 acceptance work.

## Shared task record

Keep one bounded task model used by the native panel and assistant context:

- Task identity/revision, brief, confirmed consequential choices and constraints.
- Object references and confirmed roles: receiver, boundary/zone, source,
  exclusion, preserve and context. One object can have several roles.
- Role evidence: artist assigned, artist confirmed suggestion, or unconfirmed
  suggestion. A suggested role never grants permission or becomes a hard fact.
- Fact/measurement snapshot identity, method, units, validity and omissions.
- Current editable grant and proposal/operation references, separate from roles.

Avoid a second Scatter scene model. Native authored settings, geometry, publication
and update mode remain authoritative. Store neither placements nor copied asset
geometry in task memory. Keep the initial task transient and explicitly report that
limit until M09 persistence is qualified.

Artist assignment/correction and Pick/Highlight are local controls. Highlight
must declare its selection effect and stay within shared references. Correcting
roles must not rename, regroup, move or modify artist nodes. The current design
adapter's distinct-site/source/region requirements remain explicit until broader
combinations pass native qualification; a richer task role does not silently widen
that execution contract.

## Invalidation without repeated onboarding

Retain the brief and still-valid reference/role choices while refreshing facts.
Invalidate measurements when their geometry, unit or transform dependencies change.
Invalidate exact proposal approval whenever its consequential dependencies change.
Publication freshness remains separate from both: Manual authored edits can be
pending while the earlier complete publication remains the displayed/exported result.

Do not infer unchanged geometry from a matching name, transform or bounding box.
Metadata-only cards explicitly leave geometric validity unmeasured. Add deeper
measurements through bounded supported native reads with actual dependency keys;
unsupported procedural geometry needs a precise handoff, not an estimated claim
presented as a verified dimension. Later dependency/caching optimizations in M12
must preserve these contracts.

## Questions and user effort

Inspect the selected scope first. Ask for the target or asset role when unresolved,
or for a consequential choice when evidence and prior intent cannot resolve it.
Put aesthetic defaults in the concrete proposal. Do not require scene cleanup,
renaming, exact density, source percentages or authored planting zones merely to
start. Source mix, candidate count, accepted target and spatial flower coverage
remain distinct quantities. Preserving an existing object does not automatically
create a canopy setback or preserve particular generated instances.

## Acceptance for the first increment

Verify organized and misleadingly named mixed selections; duplicate names, rename,
deletion and same-named replacements; multiple roles; bounded input/text/payload;
role correction without scene mutation; no accidental solve/upload or broad scan;
and explicit unsupported/unmeasured geometry. Verify the actual external client
reads the same task record shown in Max. Read-only onboarding must reject every
authoring path, including stale design tokens and attempted role-based promotion.

Follow with explicit supported bounds/units/geometry measurements, relevant scoped
neighbors, preserving confirmed intent across geometry refresh, and handoff into
the approved design workflow. Those are required M02 work; an attractive metadata
card alone does not complete scene understanding, adoption or the milestone.

## Implemented first increment

The local **Inspect selected scene objects (read-only)** action shares 1–32 selected
native references without a prepared Scatter design site. Metadata contains bounded
labels/types, visibility/frozen state, parent links within the grant and an explicit
outside-scope-parent indicator. A fixed native helper truncates text before pymxs
copying. No children, surrounding objects, materials, geometry or semantic classes
are surveyed implicitly. Metadata is limited to 32 KiB; scene context to 64 KiB.

The task editor and `scene_get_context` share one transient brief/role record.
Local assignment/removal supports all six nonexclusive roles. Pick uses current
Max selection, and Highlight explicitly selects shared table references only.
**Task details…** reopens the same task; it does not reconnect or discard the brief.
Scope reset/disconnect/open and other enrollment clear task memory and release
held task references. Missing objects remain missing rather than rebinding a name.

The fourteenth source tool, **scene_measure_objects**, explicitly measures 1–3
supported static mesh objects within 10,000 triangles/12,000 vertices total. It
returns world-axis-aligned bounds in metres, evaluated counts, a geometry snapshot
hash and the method/validity limits. Inherited transforms are part of a selected
object's world geometry. Existing static-input class/controller/hierarchy admission
applies before evaluation; evaluated admission is checked again. Unsupported
splines/procedural/proxy objects get a precise rejection, not fabricated bounds.

No measurement cache is retained. Metadata revisions cover metadata/task changes;
they cannot certify unchanged geometry. The assistant must remeasure relevant
geometry. Internal bounded mesh snapshots/vertex/triangle data are temporary, never
sent to the model or stored in task state. Mesh cleanup now runs in `finally`,
including rejected evaluated geometry. Peak memory and general workload latency
remain M12 measurements, not a performance claim from the language used.

Onboarding cannot validate/apply designs, configure existing setups, Undo a result,
export a generation, capture a publication or gain authority from a role. Old design
approval does not cross enrollment. The existing 24 normal-call budget applies;
requests, response bytes and source geometry are independently bounded.

## Evidence and remaining acceptance

- Run `build/mcp-scene-20261024-01`: **396 offline tests in 35.87 s** and a passing
  owned Max 2027/real SDK scene campaign. This is the first implementation before
  the reset-reference cleanup and explicit task-reopen control.
- Run `build/mcp-scene-20261024-02`: **397 offline tests in 38.13 s**. The 28 new
  cases since the Undo increment cover production task authority, duplicate names,
  multi-role correction, rename/deletion, bounded input, snapshot-only measurement,
  old-design rejection, physical units, early/evaluated admission, temporary mesh
  cleanup and reference lifetime. Offline extracted-method tests are not native proof.
- The second exact-source Max/client scene campaign passes with **14 tools**:
  `host01/scene-0e5471748bed4e6b814bbfab0878dbb6.json`, owned PID **52460**. Native
  metadata/UI task values agree; duplicate names have distinct IDs, long Unicode
  labels are truncated before copying, and an unshared parent stays unnamed.
- Explicit Plane/Cone/Box bounds match metres; rename retains task/roles, a 0.5-unit
  height edit changes the geometry hash and measured height, and switching the
  owned scene's system units makes a 30-unit plane measure 0.3 m. Deletion plus a
  same-named replacement stays missing. A 33-object selection is rejected while
  retaining the prior task. Reopening task details retains the brief; disconnect
  releases references and disables stale controls.
- Measurements preserve selection, node transforms/count, Undo history and the
  independently inspected earlier complete Mesh publication, authored hash, cache
  builds and retained owner revision/prepares/uploads. Unsupported spline and
  outside references reject; design/typed-change/old-approval attempts reject.
  These are small synthetic, scripted-local-action fixtures with an actual SDK;
  no artist consent or general semantic scene understanding is inferred.

The separate saved-scene probe in run 02 passes:
`host01/scene-passive-83ac302d58e74bf2af6e8e9ed8f9224a.json`. Both metadata and
measurement reads retain an explicitly clean save flag, exact scene-state snapshot,
publication, cache builds and retained revision/prepares/uploads. The fixed private
fixture saves a new create-only owned checkpoint before the read interval; it is
not a model-callable save tool.

Two earlier probe receipts remain failed. The first failed its clean-state setup
assertion before either public read (`scene-passive-f5fb8d680d404d0cb1c5da1a18d0c37c.json`).
The second passed both clean-state read checks but compared resource counters across
Save (`scene-passive-5a2d6afb2a054056a48109897a0c7c18.json`). Existing
`CyrusPointBeforeSave`/`CyrusPointAfterSave` callbacks intentionally remove/recreate
transient display owners; the earlier owner revision changed 2→1 while publication
identity/builds stayed unchanged. The passing successor warms that independent save
lifecycle before taking its read baseline. Original fixture/driver bytes and
qualification lineage are preserved under `history/` and the owned profile.

Windows inspection in run 02 opened **Task details…** through input on the returned
owned window (PID 52460 / window 2229560). It exposed a real layout defect: fitting
the first column to a long Unicode name hid role/status columns. The source now
elides that column, reserves visible role/status space and adds object types to
labels to distinguish duplicate names. Fresh run 03 qualifies that UI successor;
run 02 is not evidence that the corrected pixels or handlers were already tested.

### UI and lifecycle successors

- Run **03**, owned PID **35008**, has **397 offline passes in 39.51 s** and passes
  the fourteen-tool scene campaign: `host01/scene-84a6c4f0d24b4fa5865ea30b16cc0474.json`.
  Its saved-scene read probe also passes:
  `host01/scene-passive-e5e8139762f24812897b212ad166188e.json`.
- Actual Windows input targeted returned owned window **4265946**, verified against
  that PID's main window. It opened the task editor, entered/saved a brief, selected
  receiver then preserve and clicked **Assign to Max selection** for each, closed
  the task view and reopened it. The brief and both roles remained visible. The long
  label was elided while role/status columns and duplicate-name object types stayed
  visible. Max was maximized to keep the full workspace in view; this is not a
  comprehensive small-window/responsive qualification.
- `scene-ui-witness.json` verifies the same task ID/brief/roles through the real SDK
  after input. Native node count, all shared transforms, selection, Undo history
  and an initially false save-required flag remain identical. Fixtures prepared the
  synthetic scene and selected the known receiving object; they did not type the
  brief or invoke those assignment buttons. This is automated Windows input, not
  human artistic approval, a user-effort study or full panel acceptance.
- Source inspection then found the existing reset callback cleared model state
  before the new task view refreshed. Run **04**, owned PID **34080**, qualifies the
  correction and close cleanup. **397 tests pass in 38.47 s**. Its real Max reset
  callback clears/disables task widgets immediately, before any client request or
  explicit fixture refresh: scope/task None, zero held references/rows, empty brief,
  disabled details/dialog and current status text. The old scope is rejected by
  the SDK. Reconnecting works; closing the panel releases references/task memory and
  closes its bridge. Receipt:
  `host01/scene-lifecycle-7f4177b2c1484a7c84c5f2da39330855.json`.

All runs use the exact staged Scatter **0.86.9.2** / Analyzer **0.14.2** pair in owned
Max **2027** profiles. Runtime has 25 Python/JSON files. Run 04 matches current
runtime source exactly; run 03 differs only in the later reset/close branches of
the panel, with its tested task-editing/layout handlers unchanged. All owned hosts
are closed. Qualification/launch metadata, frozen source, loaded paths/hashes,
offline XML and scope-specific receipts remain under each run. No native payload,
product version, artist profile or configured client was installed or changed.

Relevant neighbors, richer geometry/receiver/source readiness, image context,
progressive scope extension, handoff retaining intent into an approved design task,
durable task resume, broad performance and physical artist-workflow acceptance
remain open. The current new-enrollment/reset policy deliberately clears transient
task context; it is not the final seamless M04/M09 experience. M02 is not complete.

## Scope extension and explicit design handoff contract

The successor [handoff increment](M02_HANDOFF.md) implements the following contract
with 413 offline passes and scoped native/SDK evidence. The earlier reset/unrelated
enrollment clear policy above remains valid; this explicit handoff now retains intent.

Preserve task ID, intent, nonexclusive roles and actual native references while the
artist explicitly adds selected context objects (32 total, including missing slots).
No automatic neighbor scan, same-name rebinding or call-budget reset is introduced.
New objects start unassigned. Local role corrections invalidate any prepared grant
review; role strings alone cannot promote inspection into authoring.

A local **Enable design proposals…** review requires one receiver and 1–3 sources,
with up to three boundaries/exclusions. Show concrete input names/IDs and effects;
default to Cancel. Confirmation rechecks task, scope and metadata identities and
expires after five minutes. It performs bounded native input admission without
creating scene nodes. Only a fresh design scope permits later exact approved
creation/refinement. Preserve the same task and map original object IDs to the new
design input IDs. Task objects themselves remain read-only; preserve is not a
canopy setback or instance-retention instruction. Capture stays off until separately
enabled locally.

If no boundary is assigned, use the whole already-verified horizontal convex
receiver polygon as a virtual region. No input spline is created at enrollment;
approved generation creates its existing bounded owned masks. Unsupported receivers
and contradictory roles reject without losing the prior read-only task. Explicit
boundaries/exclusions retain their existing distinct-reference/convex-spline rules.

Design-connected task roles/scope are shown for reference; rebinding still requires
new qualification and is not silently applied to an existing setup. Brief edits
invalidate proposals/context tokens while preserving native output and own Undo.
Geometry measurement exposes source-local dimensions/radii and qualified receiver
eligibility separately from world AABB. Materials, renderer/proxy dependencies and
asset provenance remain explicitly unchecked until M03. No geometry/measurement
cache or second evaluator is added. Static settings may be fetched from the existing
capability resource rather than repeated in every task context.
