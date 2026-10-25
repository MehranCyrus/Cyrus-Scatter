# Passive destination settings and preset-application prerequisite

24 October 2026. M03/M05/M06 foundation; full goal and preset application remain open.

F04/F05/F06/F10/F11 apply. Preset discovery supplies a saved typed document, but
application also needs the destination's actual settings, ownership, controller
availability, physical units and pending/publication distinction. The existing
Plan 0.73 subset is not a faithful representation of every native preset field.
Do not apply broader settings and silently replace the native result with that
older subset on the next edit. Complete O67/O68 remain required.

Provide a bounded passive read for one exact layer in an already scoped owned or
inspected controller. The model selects existing controller/layer IDs and named
categories; it cannot supply properties, scripts, paths or new scope. Read all
five existing native category families where their target is defined: population,
transforms, self-spacing and stored global density/scale falloff. Report explicit
unavailable bindings for receiver-bound Paint, area-line or Band curve targets;
do not infer an arbitrary curve-editor target or complete those later M07 bindings
by relabeling the global curve.

The fixed host reader uses the native scalar preset schema/capture/encoder. It
keeps raw current values distinct from exportable preset documents: out-of-format
or unavailable values cannot become fabricated valid defaults. Unsupported or
animated scalar controllers are described without sampling their values. Physical
distance fields cross the scene-unit/metre boundary once. Explicit self override,
layer defaults and effective self rule are reported separately.

Stored global curve arrays/packed graphs are read directly, with admission before
Python marshalling. Never call `getFallConfig`, `ensureFallCurves`, area/band
reconciliation or an interactive curve editor just to inspect. Empty/incomplete
stored curves stay empty/incomplete; a valid exported curve format is not proof
that its saved graph and samples reconstruct the same editable shape.

The read must not invoke task geometry fingerprinting, solve, rebuild/upload,
selection changes, source reconciliation, Undo, file IO or pending-editor commit.
It reports frame/units and cached pending flags; neither the MCP metadata counter
nor a matching settings hash proves current input geometry or placement freshness.
At most 32 scoped layers are searched, five categories requested, 34 scalar fields
per schema and 257 curve samples/2056 packed coordinates read; each graph is at
most 64 KiB and the response at most 160 KiB. Larger combinations require fewer
categories per call, never silent truncation.

Acceptance requires actual external-client and Max 2027 clean/pending reads,
all scalar and stored-curve families, units, explicit/inherited spacing,
unsupported/animated tracks, uninitialized curves, stale/missing/duplicate IDs,
important unaffected settings/publications, and exact source/loaded identities.
Read authority is not editability, adoption or application approval.

## Qualified development increment

The twenty-third development tool is `scatter_get_settings`. Omit `layer_id`
and `categories` to list exact scoped layer IDs; supply a layer ID and optionally
one to five categories to read settings. Names are untrusted display labels,
sanitized and clipped independently of IDs. Read-only inspection enrollment is
supported as well as assistant-owned controllers; neither grants edit authority.

Two failed owned runs remain preserved:

- `build/mcp-destination-settings-20261024-01/host01`: actual Max compilation
  rejected indexing a function invocation without parentheses. The fixed reader
  uses `(owner.cacheSnapshot())[3]`. The failed receipt is not acceptance.
- `build/mcp-destination-settings-20261024-02/host01`: exact readback detected
  premature Float rounding in the existing native preset capture's metre
  conversion. `preset-unit-precision.json` records -0.15 m becoming
  -0.15000000596046448 m; capture/encode/decode/apply reported a change and moved
  the stored value from -15.0 to -15.000000953674316 system units. This was a real
  native no-op defect, not a reason to relax the settings comparator.

The maintained `presets.ms` template now converts the scene-unit divisor to
Double for both capture and apply. The generated script was regenerated; a fresh
matched producer is `build/mcp-destination-units-20261024-01/receipt.json`.
Its 58 native suites passed (25.59 s). Generated integration check
`build/mcp-destination-units-generated-20261024-01/generated-check.json` passed;
it does not itself compile MAXScript or certify UI. The successor Python/tool
suite passed 567 tests (42.00 s), recorded in
`build/mcp-destination-settings-20261024-03-offline.xml`.

The fresh owned Max 2027 successor is
`build/mcp-destination-settings-20261024-03/host01/destination-settings.json`:
seven actual external-SDK/native cases passed. Its artifact is
`28b4057a68f29f0492b970a97cb8b524fe4b085c9f74fabc3e8ac714c53dde2e`.
The cases cover:

1. Exact target listing, all five categories, centimetres, repeated identical
   reads and a clean scene with pending Manual settings. Native parameter state,
   publication identity, selection, node count, history, frame/Auto Key and cached
   build counters remain unchanged. Geometry/fingerprint entry points are trapped.
2. Explicit self override and independent inherited layer-default spacing.
3. Native population/transform/spacing capture/encode/decode/apply roundtrips
   preserve settings and history and report `changed=false` in centimetres.
4. Stored global density/scale samples, widths and exported documents without
   opening an editor; empty curves from the first case remain uninitialized.
5. Unsupported script and keyed numeric controllers report unavailable values;
   the settings read does not sample the script or invoke geometry fingerprinting.
6. Missing target rejection and a separately locally enrolled inspection scope.
   Local enrollment uses the existing broader observation path; this is not a
   claim that enrollment itself never samples controllers.
7. Duplicate layer IDs reject target listing and selected settings reads.

`increment-receipt.json` in that same host directory verifies 33 frozen runtime
files equal current source and five actually loaded native hashes equal the
owned payload. `AminScatter.dlx` is
`76b85de1f2ccb7ab1231b04dd23a1eb55e7c457ccdfe95b46713d220504e7a4b`.
All three owned destination-test hosts were closed after their observations.
No artist session was restarted and no installation or release was delivered.

## Next acceptance task

Implement exact approved use of all native preset categories and complete recipes
through the common queued operation, journal, idempotency and local review path.
Keep authoritative broader native settings intact during later refinements;
Plan 0.73 cannot silently become their replacement. Qualify actual curve
graph/sample reconstruction and explicit owner bindings rather than accepting
parser validity as compatibility. Test changed and identical applications,
Manual/Live state, independent spacing ownership, shared/static controllers,
preserved unrelated settings/history/publications, rollback, Undo/Redo,
intervening edits and post-commit failures. O67/O68, broader M03 acceptance and
the full M00–M13 objective remain open. This is scoped readback and a native unit
regression fix, not a preset-write API, final installed-client or package claim.

## Native curve application prerequisite — scoped host pass

The next native prerequisite reuses `CyrusPresetApply` for global layer density
and scale curves without opening an editor. F01/F04–F07/F10/F11 apply. The
destination remains an exact controller/layer binding; Paint/area/Band targets
still require their explicit receiver/path-bound identities. Curve enable flags,
widths and every unselected group remain untouched. An existing curve editor
must be closed explicitly; application does not flush its pending edits.

`cyrusPresetPrepareCurve` API 1 parses the bounded native document and uses a
private SDK `ICurveCtl`/`ICurve`, the same evaluator used by MAXScript's artist
curve control. It never activates a dialog or binds an owner/scene node. At most 257 points and
257 evaluations are admitted. A local strong reference releases the transient
reference graph before the SDK suspension guard restores Undo, animation,
Set Key, macro-recording and save flags. There is no retained prepared handle,
thread handoff, placement buffer or filesystem operation. JSON remains capped
at 64 KiB; bounded numeric vectors are small, while exact SDK allocation/peak
memory and long-session performance still need measurement.

Preparation compares the actual 257-point native trace against interpolation
of the saved samples using the existing editor's `0.0001*max(1,abs(expected))`
tolerance. Domain clamping follows that editor. Incompatible graphs, domain
mismatches and excessive/nonfinite results reject before authored Undo. Prepared
samples and canonical editable graph data are copied into existing PB2 fields
by the ordinary native preset transaction. Identical storage is passive; a
changed apply uses one existing native hold and preserves Manual pending state.
Normal native dependencies invalidate after an authored change; preparation does
not invalidate or calculate anything.

The SDK implementation is based on the checked Max 2027 local `icurvctl.h`,
`ref.h`, `hold.h` and `samples/maxscript/mxscurvectl/mxscurvectl.cpp`, including
its native `GetValue(..., lookup=false)` path and point/tangent/flag meanings.
The new pure numeric trace/domain tests pass in the 58-suite native producer
`build/mcp-preset-curves-20261024-01`. Actual owned host parity, all-category
application/no-op, Undo/Redo, clean/Auto Key/outer-hold preservation and negative
tests are being qualified; none is accepted from the offline tests alone.
Public queued preset application, authoritative broader settings/refinement,
post-commit recovery and O67/O68 closure remain required.

Two actual failed successor receipts remain preserved at
`build/mcp-preset-application-20261024-01/host01/preset-application.json` and
`build/mcp-preset-application-20261024-02/host01/preset-application.json`.
Neither is acceptance. The first owned diagnostic,
`curve-construction-debug.txt`, records five default SDK points starting at
X `0,0,0,0,1`; sequential live assignments produced `0,0,0,0.75,1` instead of
`0,0.25,0.5,0.75,1`. Disabling constraints only on the final assignment was
insufficient: the Max 2027 sample implementation shows that setting properties
on a curve-bound `ccPoint` immediately calls the native setter with constraints.
The second owned native-only diagnostic (`native-five-point-debug.txt` and its
`native_five_points` scenario receipt) independently verifies that the corrected
C++ evaluator reconstructs five points while the bound UI-point fixture fails.

Restoration now constructs detached `ccPoint` values before inserting complete
points without incremental neighbor constraints. Native documents are validated
before SDK construction; reopening stored graphs separately validates their
bounded dimensions, finite coordinates, flags, increasing X and endpoints.
Endpoint locking/flags remain explicit. Both the typed preset loader and the
ordinary stored-curve loader use this restoration path. Global editor close also
checks for actual sample/graph changes before writing its configuration, rather
than unconditionally marking an unchanged graph dirty. These source fixes still
require the fresh successor's actual host acceptance below.

`build/mcp-preset-application-20261024-03/host01/preset-application.json`
then passed exact four-curve UI/native parity, bounded passive preparation
(including 257 points, Auto Key/frame and an existing outer hold), incompatible
graph rejection and population/transform/spacing apply/no-op/Undo/Redo with SDK
readback. It failed before the first curve authored hold because `presets.ms`
is compiled before the core's `CyrusFallPack`/`CyrusFallUnpack` definitions.
Explicit forward global declarations fix that lexical binding. The owned
`preset-scope-debug.txt` and `preflight_scope_failure` scenario preserve that
observation without hot-reloading product functions. All three failed owned
hosts were closed. The final source awaits its own complete successor; partial
cases from failed runs do not qualify the complete operation.

The fourth run (`build/mcp-preset-application-20261024-04/host01`) reached a real
curve commit, then correctly failed its identical-apply assertion. Its
`preset-array-debug.txt` records a PB2 `ArrayParameter` versus an `Array`, both
with 257 identical values: raw comparison was false and comparison after an
explicit `as array` copy was true. The captured collection also retained the
`ArrayParameter` type. Capture and no-op comparison now copy bounded stored
floats into plain arrays; current sample/graph sizes are admitted before that
copy. No broad numeric tolerance or forced-success result hides the defect.
This fourth failed receipt and its actual extra history entry are preserved;
the owned host was closed before staging the next pair.

The fifth/sixth runs preserve further failures rather than qualifying only the
easier subset. Both reached all five native apply/no-op/capture/Undo/Redo cases
and external SDK readback. The ordinary editor browse then exposed forced
post-save presentation and graph-text differences. The fifth run's
`curve-browse-diagnosis.json` records no parameter changes during its separate
reproducer, but closing forced the display-helper count from seven nodes to
eight; `curve-browse-nodes.txt` identifies `Cyrus_Point_Display`. Normal Save
already schedules its presentation restoration. Unchanged browsing must not
force that work.

The sixth run's `packing-precision-debug.txt` independently records Float versus
integer flag spelling (`1.0` versus `1`) with equal decoded graph coordinates.
It also records the stored Float `0.12345679104328156` becoming `0.123457` under
ordinary packing. The separate actual captured-curve roundtrip changed sampled
values by up to `1.9371509552001953e-06` and created history; original and successor
documents remain in `precision-roundtrip.json` / `precision-after.json`.

Packing now uses explicit nine-significant-digit Float formatting with
`userLocale:false`; numeric graph comparison does not confuse spelling with a
data edit. The Max 2027 [formattedPrint documentation](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Language-Reference/Values/GUID-19874C74-DEE5-4BCD-A5FD-4F0F51EB3451.html)
specifies selectable precision and locale-independent decimal output. The owned
diagnostic separately proves the proposed text converts back to the original
Max Float; the documentation alone does not prove Cyrus roundtrip behavior.

The editor now records whether a user edit or explicit preset application
occurred. Loading/closing existing data does not authorize resampling or
replacing an older graph encoding. That flag participates in preset preparation
rollback, and real point edits still use the existing authoring path. The new
successor adds precise Bezier capture/reapply, older-encoding passive browsing
and an ordinary authored editor edit/Undo/Redo; their results must still be
inspected before acceptance. The fifth and sixth owned hosts were closed.

### Editor Undo qualification failures and successor

The seventh and eighth owned runs both pass the first eleven cases, including
all five category applications, precise Bezier capture/reapply and passive
five-point/older-encoding browsing. Both then stop at the ordinary scripted
editor edit's Undo after the temporary CurveControl has closed. Native
Application Error dialogs were directly observed; these are fatal failures,
not ordinary observation timeouts or passing Undo results. Their receipts and
terminal observations remain under `build/mcp-preset-application-20261024-07`
and `build/mcp-preset-application-20261024-08`. Both owned Max processes were
confirmed absent after acknowledging their error dialogs. No additional crash
report was submitted; Autodesk's report dialog states that basic crash data is
sent automatically. The artist's separate Max session was not changed.

The seventh run preserves `owned-editor-edit-crash.dmp.zip` and a raw dump
summary. Exception-context addresses and candidate code pointers are diagnostic
evidence, not a symbolized stack or proof of the production cause. The eighth
run's stage marker is `before_undo`, with no active hold. Merely moving dialog
closure after hold acceptance did not resolve the failure.

Both failed probes placed a programmatic edit to the transient SDK curve
controller inside scene Undo. The ninth successor instead prepares that UI
view with Undo disabled and its model callbacks suppressed, proves preparation
did not change scene state, and records only persistent model changes in one
authored hold. This matches the existing preset preparation boundary. It still
requires exact authored-state Undo/Redo after closing the editor, and separately
tests ordinary editor preset application and failed preparation restoration.
Until that successor passes, the failure remains open. This scripted probe
does not qualify physical dragging or prove its Undo lifetime is safe; artist
interaction remains a separate M04 acceptance gate.

The ninth successor now **passes all thirteen cases** in
`build/mcp-preset-application-20261024-09/host01/preset-application.json`, artifact
`fb04f23fc7b97a812358f5ea00c6d76b5ae96cecaaebe4313a9423a9be4d081a`.
The edit stage reaches `complete` with no active hold. Exact model Undo/Redo
after editor closure and ordinary UI preset application/failed-prepare
restoration pass. The external MCP SDK is 2.3.0 on CPython 3.11.13; it creates
the owned setup and reads every applied category through the public settings
reader. Category applications and editor actions are private scripted probes,
not public MCP preset writes or physical artist consent.

Its live `increment-receipt.json` verifies 33 frozen MCP runtime files against
current source and five actually loaded native hashes. The matched native
producer is `build/mcp-preset-curves-20261024-07` (58 suites); its generated
script SHA-256 is
`13f31bb10c33fe2a41ec3f970c65a002af4615596e240899badcae7687db666f`.
That source's offline Python/tool run passes 567 tests in 41.33 seconds
(`build/mcp-preset-curves-20261024-07-offline.xml`). The ninth owned host was
closed after freezing its receipt. This closes the scoped native evaluator,
storage and scripted editor prerequisite, not public application, physical
dragging, M03 or the full goal.

### Composed native application — scoped pass; physical editor failure

`CyrusPresetApply` now has an explicit `transaction:#caller` mode. Ordinary
callers retain the default single-preset hold. Composition requires an active
caller hold, both root/layer transfer guards, a stored target without an editor,
and a predetermined seed policy. It preserves that hold on success and failure;
the caller owns cancellation, publication restoration, configuration tags and
final UI publication. It performs no intermediate UI binding or redraw.

The successor campaign adds whole-command guards, all five categories plus
configuration tagging in one hold, static-controller sharing preservation,
identical no-op behavior and a rejected later category followed by caller
cancellation. New source needs its own matched producer and host evidence;
the ninth run above does not qualify this later transaction change.

The tenth owned campaign passes all sixteen cases on
`build/mcp-preset-transactions-20261024-01`: all thirteen earlier cases plus
caller guards, five-category composition/configuration tagging/shared-controller
preservation and rejected-successor caller cancellation. Its artifact is
`8f64b0bd8f77d94e8c913e4a99bd92948be596c78291d043c715c47ecfcac4f4`;
33 runtime files and five loaded hashes match. The producer passes 58 native
suites in 25.39 seconds; 567 Python/tool tests pass in 43.58 seconds. The frozen
campaign driver now lives in the run, preserving executed bytes after later
driver edits.

An additional **physical** Computer Use test then dragged the ordinary density
curve's middle point from `[0.5,40]` to approximately `[0.5,58.724]`, closed its
title bar and verified changed density samples with other settings and Manual
publication preserved. History contained `Move Points` followed by `Select`.
Undo produced a directly observed native Application Error. Its separate
`physical-editor-campaign.json` is failed, `physical-editor-history.json` stops
at `before_undo`, and before/after native states are preserved. The sixteen
scripted cases remain their narrower evidence; they do not qualify physical
editor Undo. The owned Max and report were closed without an additional report
submission; the artist process was preserved.

**Lifetime repair hypothesis / ownership contract:** the local Max 2027 SDK
`samples/maxscript/mxscurvectl/mxscurvectl.cpp` shows that ordinary curve wrappers
retain their `ICurve` but keep a raw `ICurveCtl*`, call its `Redraw()` during
updates, and drop the control's strong owner on `WM_CLOSE`. A native Undo
lifetime record should retain the existing control until its history is
retired. This is a source-supported hypothesis, not yet a proven crash cause.
The proposed record performs no scene restoration of its own and retains one
existing native reference rather than copying curve/placement arrays. Track
selection as well as point/tangent/insert/delete/reset events; deduplicate one
control per active hold. Accept/Cancel releases the per-hold registration;
discarding history releases the retained reference. No persistent pointer,
permanent registry of retired controls, worker, scene node or history clearing
is used as a workaround. Verify physical close/Undo/Redo, discard/release and
unchanged browsing on a fresh matched successor before claiming a repair.

### Controller lifetime repair — scoped scripted and physical pass

The fresh `build/mcp-preset-application-20261024-11/host01` successor passes all
sixteen scripted cases, then the separate physical drag/close/Undo/Redo and
history-retirement campaign. Both receipts identify artifact
`c2d0721ec5db1a5117bca6f896e770bf25797121efffcf1874bbd4b912122664`.
`increment-receipt.json` verifies 33 frozen runtime files and five actually
loaded native module hashes. The native producer is
`build/mcp-preset-transactions-20261024-02`, with 58 suites passing in 24.45
seconds and a complete frozen-input/dependency receipt. Python/tool checks pass
567 tests in 42.25 seconds
(`build/mcp-preset-transactions-20261024-02-offline.xml`). Generated checks pass
with 333 controls; the actual cold Max load and host cases provide the separate
script execution evidence. Generated script SHA-256:
`f49e11a3704f7267b71ccc3e9bff143f70450f57ae393d8bc990f7530f593df7`.

The native `CurveControlLifetime` record retains the existing `ICurveCtl` with
`SingleRefMaker`. Direct dependency lookup admits at most 1024 references and
requires one matching single-curve control. One active control is registered
per authored hold, with at most sixteen active controls. `EndHold`/failure
removes that registration; history retains the reference until the record is
discarded. Restore/Redo do not execute scripts or modify the scene. The record
reports its own size, without claiming a measurement of the retained SDK graph
or whole-process memory. There are no copied curve or placement buffers and no
permanent retired-control registry. Selection callbacks join the same lifetime
contract without marking the curve authored. `CyrusPresetTransactionVersion()`
returns 1 for the composed script API; future public callers must check it
before entering their authored hold.

The physical test repeats the failed predecessor's mouse drag from `[592,506]`
to `[592,435]`; the displayed middle point changes from `[0.5,40]` to about
`[0.5,58.724]`. Native readback proves only density curve data changed and the
Manual publication/solve count stayed unchanged. Lifetime counts move from
`[1,0]` to `[3,0]`: exactly one extra selection hold and one drag hold, with no
active registrations. Undo and Redo after closing the editor restore exact
model/publication states and retain `[3,0]`. Only **after** that verified Redo,
resetting the disposable owned scene retires history and returns `[0,0]`.
Reset is a release test, not a workaround for failed Undo. The owned host was
closed after evidence capture; the artist's Max session remains untouched.

Reproduce with `tools/mcp/preset_editor_interaction_campaign.py`: `begin`, the
actual physical mouse gesture and title-bar close, then `verify`, `undo`, `redo`
and `release`, each with the same fresh `--base`. The runner freezes its driver,
records each boundary and refuses replay after uncertain outcomes. Its native
probe module and the sixteen-case campaign driver are already frozen in that
run. Earlier fatal receipts remain unchanged.

This qualifies the reproduced ordinary **live-owner global density** path and
the native composition prerequisite, not every curve/editor lifecycle or public
MCP preset application. Owner removal/invalidation, selection-only history,
other curve targets and long-history/peak-memory cases remain M04/M07/M09/M12
acceptance. Source review identifies that `retainCurveUndo` currently skips an
invalidated view; controller history lifetime must be independent of model
target validity, so that boundary needs its own repair/test before closing the
owner-deletion gate. Public exact approval/dequeue checks, authoritative native
settings/workload admission, full recipe use and O67/O68 remain required.

### Transaction integration decision

The public integration will extend the existing closed owned-change proposal
with frozen preset references rather than adding arbitrary field setters. Read
authoritative native settings again for validation and dequeue, preserve their
controller bindings, and compose presets plus explicit count/seed patches in
the existing caller-owned hold. Identical effective changes have a verified
no-effect receipt without a new configuration, history entry or solve.

Population admission must reuse native receiver allocation **without building
its candidate schedule**. A high-density rejected proposal must not first
allocate the million-row schedule it is supposed to reject. Split allocation
from schedule materialization, retaining the existing evaluator's quotas,
rounding, density cap and retry rules. Bounded grid validation may explicitly
prepare a native grid snapshot under the remaining cell budget; this is
proposal preparation, not passive inspection or a published Scatter solve.
Release transient snapshots after reading their bounded summary.

Transform/scale changes must update only the affected owned derived masks in
the same authored transaction, when their conservative footprint/movement
bounds change. Keep artist regions, layer/source IDs and unaffected layer
results. Review these derived-mask effects. Later Update reads authoritative
native population/transform state; the bootstrap Plan 0.73 is not its settings
serialization. Receipts/export distinguish native population modes, quotas,
attempts/cells, emitted/displayed results and bootstrap provenance.

The next implementation must compose the existing typed native preset engine
inside one caller-owned authored transaction, preserving its ordinary local
single-preset transaction behavior. Do not add an arbitrary property/script API
or write configuration identity in a second unrelated Undo step. Native owner
and complete publication restoration, configuration tagging and post-commit
outcome recording belong to the same operation contract.

Keep the source preset's frozen grant/document identity, exact destination IDs,
current settings snapshot and selected category effects in validation/review.
Recheck them after approval and again when dequeued; refresh/revoke, intervening
manual edits and changed geometry cannot reuse an earlier approval. Preparation
is read-only. Applying identical effective storage must have an explicit proven
no-effect outcome rather than manufacturing an authored change or new history.

Authoritative native settings must survive subsequent count/seed patches and
Update. Plan 0.73 remains a bounded creation format, not a complete native
settings serialization. Derive execution/workload and footprint admission from
the actual proposed native state; do not label density/accepted-target settings
as Count or let a broader preset bypass the current placement budget. Preserve
unselected groups, static shared-controller owners, independent spacing scopes,
Manual pending results and all already qualified failure/journal behavior.
Expose application only through the existing exact local review/common
apply/status pipeline once these contracts and their external-client tests are
implemented. Full recipe use and all remaining milestone gates stay required.
