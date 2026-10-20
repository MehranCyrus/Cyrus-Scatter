# Native fit feedback — 0.3.2 implementation contract

Status: verified development checkpoint; not a release. The full goal stays active.
Previous verified checkpoint: `build/keep-clear-032-progress01/progress.json`.
No artist installation, existing-session edits or computer use is authorized.

## Ownership and invariants before implementation

The immutable C++ physical query returns a small copied numeric witness with its
existing rejection: support/boundary, overhead, side clearance, occupied body or
output, spacing, access or stacking. Body and output identities remain distinct.
Only an actual narrow-phase rejection may name a blocking body. Compound-source
root broad-phase hits cannot become witnesses when the occupied pieces pass.
Support-space bounds are sampling context, not a proof of an exact compartment.
Messages describe tested positions and do not promise optimal/exhaustive packing.

Each solve records at most eight representative failed root poses for each of
at most 256 sources. On underfill, a separate native follow-up budget admits at
most 4096 probes and 5,000,000 query-work units. It checks the final published
candidate set, including protected output. Surface checks retain full footprint,
edges, static geometry, spacing and regional front policy; path checks also retain
the complete lane ribbon and fixed base center. No source mesh, seed, output ID,
quantity, random sequence or accepted placement may change because of feedback.
The ordinary solve work/candidate/rejection counters keep their meaning. Feedback
has separate work/probe/truncation counters. Exhausted optional feedback must not
discard a successfully validated generation or invent a fit. Budget/validation
failure makes a proposal unavailable, never accepted.

Proposed reductions use bounded descending samples and verified refinement, not
an optimal-size proof. They may check below the artist's current minimum, down
to the existing hard 1% floor, only to report a possible change. The final
suggested pose/scale must pass the same physical query against final output.
Changing the visible fit draft does not publish that pose or resize the source;
Generate remains the atomic application step. Original scale is preferred by the
production solver, and fit hints do not bypass it.

The result owns at most 256 numeric reports plus bounded failure seeds while
solving; no mesh/proxy/probe spans or host pointers survive the solve. Query
components gain copied body identity/role metadata; retained accounting includes
their actual sizeof/capacity. The native Document owns one immutable transient
feedback snapshot, stamped to accepted state identity, input epoch and geometry
ticket, with time/units checked at read. Undo/reopen/dirty inputs make it stale.
It is not saved or copied into Undo history. Dependency callbacks only invalidate
the stamp; they must not capture/solve or release a potentially large payload.
A successor can coexist with its old bounded report during preparation; this is
not a total Max/process RAM guarantee.

One separate native highlight holds at most two copied world-mm boxes and a
freshness stamp. It shares the existing viewport callback but never replaces a
staged Preview or disarms Live. Drawing only checks freshness and draws numeric
lines. Scene reset/Undo/units/time invalidate it. It creates/selects no scene
nodes. Only the currently bound Modify view may show/hide its owner's highlight.

The contextual report and suggested-fit action stay inside Props in Modify and
collapse when irrelevant. No Apply, Advanced window, geometry transport, scripted
solver, automatic source resizing or silent acceptance of a failed proposal.

## Required proof

Native tests must distinguish true height/depth/support/occupied/spacing/access
witnesses, reject false compound broad-phase witnesses, verify reduced-size
proposals at final physical scale, preserve poses/seed/main counters, handle
nonmonotone search conservatively, and bound work/rows/probes. Actual mounted
Max tests must exercise original-failed/verified cabinet fit, draft-only proposed
settings, no popup, owned highlight freshness, owner switching, failed Generate,
Undo, save/reopen and passive browsing. Re-run current physical/path/shelf/compound
scenarios and independent actual-mesh invalid controls for the final exact pair.
Preserve previous goldens and review all intentional message/work changes.

## First implementation evidence and current limits

`build/native-032-feedback-core01` compiled the new native core. Eighteen of its
nineteen suites passed; the sole failure was the intentionally changed artist
warning snapshot. `build/feedback-golden-032-review01/review.json` compares all
six scenarios: every pose bit, main stat/work value and rejection is identical;
only the technical success/underfill warning text changes. The previous golden
is preserved. The new test reads `geometry_feedback_032.golden`.

The first full SDK pair, `build/native-032-feedback-host01`, built both modules
and passed all nineteen suites. Its owned mounted runs reached five new fit
checks and ten existing Modify checks before a measured-width assertion stopped
each fixture. Both failed receipts are retained and are not qualification. The
new native height report, checked reduction and contextual display were observed,
but highlight/draft/lifecycle acceptance had not yet run.

`build/native-032-feedback-host02` builds both modules and passes all nineteen
suites, including **40 native feedback checks**. These cover actual roof/side/
back/gap/access witnesses, discarded compound broad-phase witnesses, independent
height and lane arithmetic, float-spinner representability, nonmonotone fit
intervals, preferred-size success, all 256 rows, bounded/exceptional probes,
off-center path anchors, and regional Fill phase isolation.

Regional Fill shares one bounded failure recorder across its native children.
Only the outer solve runs advice, after every child and all production work.
Surface advice uses a separate source-proxy catalog and reconstructs blockers
from final poses, so optional work cannot alter a parent's lazy collision cache.
Main and advice catalogs can coexist; child and advice catalogs do not coexist.

On this x64 build each FitReport is 352 bytes: at most 90,112 bytes of report
values per snapshot. Old and prepared successors can coexist (180,224 bytes of
report values). Seed storage reserves exactly eight slots per source on its
first failure. Source proxies and numeric obstacle arrays retain their existing
per-source/per-placement bounds; surface advice adds one bounded numeric catalog
and blocker array, and borrows immutable asset meshes. These are value/capacity
limits, not measured allocator overhead or total Max/process memory.

The Apply suggestion value is checked again after conversion to the float
percentage that a MAXScript spinner can represent. A value that fails this final
physical check is never offered as an applicable setting. Advice may still show
a valid exact pose when the bounded follow-up cannot produce an applicable UI
value. Complete Max acceptance and the final exact-pair campaign remain pending.

Official UI references inspected during runtime layout investigation:
[editText fields](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/Rollout-User-Interface-Controls/Rollout-User-Interface-Controls-3/GUID-FC73C160-735C-4F65-A71D-722D63BBB591.html)
and [common control properties](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/Rollout-User-Interface-Controls/GUID-3880D745-8496-4DFB-8B31-4DEAC152DBB3.html).
Actual HWND bounds, not the documentation alone, decide layout acceptance.

Both second mounted attempts stopped on the same concrete label rectangle:
`EditTextControl:groupName` at x1690, width33, with the Props content origin at
x1717. Repositioning the composite name edit field had moved its left caption
27 pixels outside the rollout. Other measured controls fit. The redundant left
caption is removed; the field retains its existing full width, default name and
tooltip. `build/native-032-feedback-host03` is the fresh frozen successor for
this fix. The first/second failed hosts and their rectangle logs remain intact.

The third build passed all nineteen native suites, and its existing mounted UI
suite passed all 117 checks. The dedicated fit fixture then stopped after eight
checks because the new buttons lacked pressed-event bindings. Their real event
handlers now dispatch the already guarded native-backed commands. This was a
product wiring defect, not a successful full fit run; that failed receipt stays
in `build/host-032-feedback-fit03`.

`build/native-032-feedback-host04` is the corrected exact pair. It passed both
SDK modules and all nineteen native suites, with 40 focused feedback checks.
Its owned normal-Max fit run `build/host-032-feedback-fit04/receipt.json` passed
**31 checks** with normal exit and all five loaded-module/profile guards. These
exercise actual mounted actions, completed native display callback calls, far
world-mm highlight bounds, independent actual output support/roof bounds, source
and material preservation, draft-only settings, failed-generation retention,
separate Preview coexistence, owner switching, time/units/input invalidation,
Undo/Redo and save/reopen without persisting advice. The highlight creates no
scene nodes and retains selection. Pixel appearance, mouse picking, renderer and
final installer are not claimed.

The same pair also passed the existing 117-check Modify suite, 19-check geometry,
37-check path, 26-check shelves/stairs and 17-check compound suites. All six owned
Max processes exited normally and passed all five loaded-pair/profile guards.
Total: **247 actual Max checks**. Both independent actual-mesh verifiers passed
and rejected all eight intentionally invalid controls. Their shelf/stair/arch
exports are byte-identical to the prior Keep clear checkpoint. There is no
before/after performance, pixel-appearance or optimal-packing claim.

Exact source/native/receipt/export/scene identities and all 165 frozen source
inputs are in `build/feedback-032-progress01/progress.json` and its `source_inputs`
directory. Schema7, source/material geometry, existing archives and examples are
unchanged. The transient view is CA8. Both qualified 0.3.1 archives were rehashed
and remain byte-identical. All failed attempts and golden reviews are preserved.

Full release work remains open: finer automatic base support and compound
precision, receiving-surface overrides, legacy book-row/minimum handling,
broader real-model/units/performance/lifecycle/gesture evidence and the final
exact installer/automatic startup. No artist profile installation, restart or
computer use occurred.
