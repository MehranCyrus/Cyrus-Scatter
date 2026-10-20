# Geometry-driven Arrange 0.3.2 implementation and acceptance

Status: active implementation; not a qualified release. The user's complete
fourteen-item objective remains open. This ledger also includes the subsequent
requirement that all artist controls live in Modify without extra popup windows.
The quoted old plan's no-code sentence is superseded by the explicit instruction
to start coding. Preserve the qualified 0.3.1 archives, examples and receipts.

## Version and baseline

Select 0.3.2, the next patch under the parent version policy, for the complete
geometry-driven redesign. This is a substantial behavior/interface change even
though the development label advances one patch. C++ owns quantity, physical
space/fit, scale, packing, spline sampling, offsets and acceptance. MAXScript
owns the Modify presentation and bounded input/commands. Other Cyrus products
retain their versions and files. Registration identities remain unchanged.

Baseline: parent branch codex/workflow-0.75, HEAD
e3e81a6d204063efd9b77771ad9b0268ad2ea578; Arrange is untracked in the parent
repository. Unrelated tracked documentation changes predate this work. The
current 0.3.1 source/build/package receipts and archives are historical evidence,
not evidence for any modified source. No artist installation or restart.

## Ownership and recovery decisions

One native Document owns receiver/source/output references and saved settings.
Keep numeric snapshots native and host-independent. Max scene capture, reference
updates, UI callbacks and publication remain on the host thread. Draft Modify
edits are committed with Generate in one transaction; failure retains the
previous complete native state, output and saved seed. Preserve normal Undo,
clone, save/reopen and dependency invalidation. Passive selection, displaying
panels and reading saved fields must never capture geometry or solve.

New persisted quantity/scale/path fields require a new scene schema and exact
roundtrip/corruption tests. Path bindings and numeric path samples must have
explicit reference/lifetime, dirty and cache keys before host integration.
Keep original source geometry/materials unchanged; output transforms own scale.
Randomness is bounded and seeded. Every final candidate, after scale and offset,
passes support, clearance and collision checks. Broad-phase bounds cannot alone
prove support or fit. Packing limits bound candidates, query work, cells and
retained memory; finite underfill is reported without hiding requested counts.

The in-progress scene codec writes schema 7 and accepts released 3/4 and
development 5/6 input without modifying those original files. Schema 5 introduced
global amount/count and explicit random/fit scale ranges; schema 6 appends the
optional typed path layout; schema 7 appends per-source minimum-copy policies.
Max path capture, publication, reference lifecycle
and inline controls are implemented and undergoing actual host qualification.
This remains an unpublished development schema.

The current real native MSCustAttrib host already supplies the correct Modify
context and shared owner. Extend that host rather than creating a second
dialog/controller. Objects, placement, scale, path and overrides belong in native
Modify rollouts with one Document GUID/session binding. Object picking must
capture that binding, preserve the arrangement selection and recheck it after
the pick. All generation settings are staged with the existing atomic Generate
transaction; picking, browsing or opening sections is never an analysis trigger.

## Full requirement ledger

| ID | Required end state | Authoritative acceptance | Status |
| --- | --- | --- | --- |
| 01 | No furniture/category eligibility restrictions | Native mixed-tag/mask cases, actual Modify without type dropdown | Native and actual Modify passed |
| 02 | Obvious creation, toolbar, selectable icon and one native setup | Actual Create/action + icon/Modify owned-Max handlers | Macro, icon/Modify and helper initialization passed; mouse gesture untested |
| 03 | Generate applies drafts; no separate Apply | Actual Modify edit/Generate/Undo and failed transaction retention | Native and actual Modify passed |
| 04 | Usable compartments, shelves, steps and clearance from geometry | Independent cabinet/stair mesh support and clearance measurements | Native and actual divided-shelf/stair cases plus six complete device/imported-table cases pass; consistently closed inward receiving shells prepare automatically in private copies, ambiguous/open geometry stays authored |
| 05 | Fast broad phase plus complete physical validation/refinement | Adversarial holes, overhead, irregular fit, final-scale collision tests | Automatic compound sources and low-geometry base envelopes implemented; 14,314 compound and 1,360 base checks plus actual round-support/roof/prepared-plant/path/arch cases passed; broader precision/complex-receiver coverage pending |
| 06 | Quantity and Fill; no category caps; honest totals | 100 repeated copies across usable shelves, impossible count, protected/selective totals | Native, UI, 100-copy board and 100 detailed books across shelves pass; complete-device recovery preserves minimums/protection and explicitly reports occupied-table 2 requested / 1 placed / 1 unfilled |
| 07 | Original-first optional bounded uniform fit scaling | Oversized device, original-size preference across compartments, accepted reduction, source preservation | Global preference, Max cabinet/round-base/path fits and complete prepared plant pass; full device fixture proves original tall-cabinet preference, bounded short-cabinet/lower-shelf fit and two original devices on supplied Table06 |
| 08 | Clear random scale range combined safely with fit | Actual range, repeatability, final-scale fit, unchanged sources | Native, actual random-scale Modify and current Max fit API passed |
| 09 | Required/large first and permitted rearrangement | Mixed sizes, locks, obstacles, retained failure and priority witnesses | Native surface/path priorities and mixed props pass; later 185-input focused Max57 proves atomic legacy-row transition, exact protected closure, competing optional props, minima, Undo/Redo and reopened repeat. Final broader obstacle/selective gate remains open |
| 10 | Straight/curved path, count/spacing, center, align/reverse | Native arc-length witnesses and actual Max spline capture/output | Native and actual Max reference/capture/publication/lifecycle/inline UI passed; complete modeled sedan cases now also pass arc/heading, count/spacing and centimetre/inch conversion |
| 11 | Local lateral and longitudinal seeded jitter | Curved local frames, bounds and post-variation collision proofs | Native and actual Max variation/scale/Undo/inline UI passed; complete sedan variation independently proves local spread, final scale, road support, curved-lane containment and separation |
| 12 | Two directions, offsets, lane widths and per-side totals | Six cars, three each way, full footprints inside curved lanes | Complete 1,138-vertex sedan: 3 + 3 cars, narrow-lane fit, impossible minimum, protection and 6 + 5 spacing passed in Max; six independent actual-mesh proofs and five rejected invalid controls; static upright flat-Z road scope |
| 13 | Useful fit failure reasons and obstruction/scale feedback | Native diagnostics plus actual Modify captions/highlights | Implemented: 40 native checks of physical witnesses/verified sizes/limits and 31 mounted Max checks of captions, draft action, native highlights, final output and lifecycle; bounded-search limits documented |
| 14 | Real Max examples, physics/units, performance, lifecycle | Fresh exact-pair Max2027 campaign, independent geometry, installer | Current184-input native21 / Max450: earlier nine workflow/scenario cases plus device39 and packing64; 28 independent actual-mesh cases and 30 rejected controls. Eleven qualified hosts exit normally with every guard; failed road03 guard remains excluded, fresh road04 qualifies. Legacy row/minimum, current performance/lifecycle and final installer/autostart gates stay open; startup worker path narrowed, cause unresolved |
| UI | All controls in Modify; inline props/scale/path/overrides | Actual mounted UI, dropdown changes, owner switching, no popup calls | Five-rollout CA9 workflow including contextual feedback, Min copies, Keep clear/approach and safe mode switching passed 123 workflow +31 fit +31 status checks; complete car uses actual inline handlers; picker gestures unverified without computer use; optional receiving-surface overrides require a demonstrated need |

## Execution order

Implement native unrestricted eligibility, global quantity and bounded scaling
first. Add persistent native settings and the unified Modify transaction. Build
native path data/arc-length frames and physical path/lane queries, then bind real
Max splines and inline controls. Refine mixed-size packing and diagnostics against
adversarial fixtures. Create fresh owned Max2027 real examples for the cabinet,
books, stairs and two-way road; measure performance separately from UI appearance.
Qualify the exact final native/UI MZP with isolated installation and automatic
startup before delivery. Update user and technical docs from actual evidence.

No requirement is complete until its listed evidence covers the intended scope.
No private intermediate build should be installed into the artist profile.

## First implementation evidence

Native source now ignores historical furniture/source/category eligibility
masks and count caps. Explicit source weights, physical exclusions, support,
clearance and collision remain active. Quantity is global and includes protected
output. Optional bounded random scale and original-first fit probes validate
actual final geometry; the source model is unchanged. Fit uses descending
samples plus refinement of a verified bracket, not an optimal-packing proof.

`build/native-032-space01` compiled successfully and its new physical workflow
executable passed 5,275 checks. The whole initial campaign had five failures;
the frozen receipt remains pending and is not qualification. Changes to old
semantic-filter and schema assertions require fresh current-scope tests.
`build/native-032-space02` compiled and passed ten of thirteen executables;
three failed results are preserved and the next frozen run is in progress.

`build/native-032-space03` subsequently passed all thirteen native executables.
`build/native-032-host01` built both Max2027 modules and passed the same complete
native campaign. It adds read-only `caPlacementSettings` and atomic
`caGeneratePlacement`: ten bounded authored values, no furniture/category field,
fresh or repeated seed, and settings staged with generation. It also neutralizes
historical style/clustering/empty-space multipliers for that new simple route.

`build/native-032-host02` adds the actual Max geometry workflow fixture and a
roundtrip admission correction for unused Fill-mode quantity. It compiled both
modules and passed all thirteen native executables. An isolated Batch host
`build/host-032-geometry01` is exercising that exact frozen pair and fixture.
This is native API/physical evidence only; it does not test the new UI, which
has not yet replaced the old panels. Accepted/failed host results must be added
after the actual runner finishes; startup intent is not a passed test.

The first Max run failed before assertion entry: the new fixture used a
top-level `local report` declaration. Its receipt is failed (including missing
post-fixture identity output) and contributes no validation. The report block
is now scoped; `build/native-032-host03` is a fresh frozen build for that exact
corrected fixture. Native details and scope are documented in
[the core implementation](GEOMETRY_PLACEMENT_CORE_0.3.2.md).

Host03 completed with both Max2027 modules built and thirteen native executables
passed. The corrected exact-source fixture is now running in
`build/host-032-geometry02`. Its initial broad-board count test is not sufficient
to complete the practical 100-books requirement: add a dense multi-shelf scene
and independent full-footprint/collision verification before closing item06.

The second Max attempt loaded the exact pair and passed all five native/profile
guards, but scene setup stopped after its version assertion: fixture helper
names needed explicit global declarations before `fileIn`. It remains failed.
The corrected fixture is running as `build/host-032-geometry03`, from a fresh
host04 full SDK/native-test build.

Native review found an additional item07 acceptance case: if an earlier
compartment requires shrinking but a later one accepts the original size, the
solver must prefer the original-size placement. The current candidate-level
fit search does not establish that global preference. Add original-size search
across available spaces before the fit fallback, with a two-compartment
regression, rather than calling the current candidate-only fit complete.

The third Max host **passed 19 checks**, exited normally and passed all five
identity/profile gates. It verifies 100 actual output meshes, original-source
and material preservation, scale/contact/bounds/nonoverlap, repeated/fresh seeds,
Undo/Redo, invalid-draft retention, schema5 save/reopen and actual cabinet fit.
Receipt: `build/host-032-geometry03/receipt.json`. This uses the host04 pair and
does not qualify the subsequent native changes or any new UI.

The subsequent core now searches all regions at preferred size before a second
fit pass. It also corrects a fitted-parent pose propagation defect: stack
attempts now use the published reduced scale instead of the original candidate
scale. Two-compartment and fitted-stack regressions were added.
`build/native-032-space04` passed **all thirteen executables**, with **5,281**
checks in the expanded physical workflow executable. Current source differs
from the last Max-tested pair in those solver/test changes; a new SDK/host
campaign remains required after UI integration.

Next implementation: native generic creation/receiver binding and automatic
sampling, then replace old dialog entry points with the unified Modify rollouts
using the staged ten-field command. The old public UI still contains the type
dropdown/popups and is not a delivered redesign. Paths, priorities, refined
irregular collision, diagnostics and full release gates remain in the ledger.

A separately compiled diagnostic recorded a real book at x=970.023, z=440
over a cabinet's upper support. The fixture's old oracle bounded all levels
to x=[0,1000], but the upper board and wall caps physically form
[-20,1020] x [0,420]. The corrected independent oracle accounts for that known
literal union at z>=440; all other planes and numerical tolerances are unchanged.
Evidence: `build/space032-oracle-diagnostic/result02.txt`.

The new six-scenario golden has independently checked analytical requested
counts 12/14/13/6/6/5. Its original 0.1.1 predecessor remains unchanged; old
category-weighted poses are deliberately superseded by the approved behavior.
The first new golden was written with Windows CRLF while the raw C++ stream
contains LF. That representation mismatch is recorded and corrected only in
the new unpublished fixture. The full target/byte reviews remain under
`build/space032-golden-review/`. New paths, UI, native-host and installer gates
are still pending; none is implied by the numerical progress above.

The first unified UI SDK build, `build/native-032-ui01`, compiled both Max2027
modules and passed all thirteen native executables, including the new automatic
sampling cases. This qualifies the native build only. The actual mounted Modify
fixture is running in `build/host-032-ui01`; it has not yet produced accepted UI
evidence. Implementation details and explicit limits are in
[Unified Modify workflow](UNIFIED_MODIFY_0.3.2.md).

`build/host-032-ui01` failed its first mount assertion after one version check.
The host exited normally and all five native/profile identity guards passed.
That failed receipt is preserved. The fixture had not predeclared the UI globals
before compiling its helper functions; the next fixture explicitly binds those
globals and records actual object/view/CA/context/window identities and errors.
This is a test correction to investigate the mount, not accepted UI evidence.
The next native build also guards a missing helper base object and permits
receiver rebinds when a library contains stored assets with null scene sources.

`build/native-032-ui02` compiled both modules and passed all thirteen native
executables. Its normal host, `build/host-032-ui02`, confirmed real native
mounting, one Document, four mounted rollouts, horizontal control fit and the
actual Add selected props handler (13 passes). The fixture then failed by trying
to call dropdown `.selected` as a function: the selected text property hides that
handler. The failed receipt and trace are retained; five identity/profile guards
passed. Autodesk's documented shared-function pattern now connects the real
dropdown event and the test. Undo/Redo callbacks read saved values without a
solve and preserve unrelated drafts. Inline Props/Scale hydrate on their actual
open events. `build/native-032-ui03` is the fresh frozen successor for this code.

`build/native-032-ui03` again passed the complete SDK/native campaign. Its owned
normal-host run passed 35 assertions: actual mounted UI, unrestricted creation,
inline layout/intake, Quantity/Fill handler, visible random range, Generate drafts,
independent output support/bounds/material/nonoverlap, automatic sampling, fresh
and repeated seeds, atomic Undo/Redo with field refresh, invalid-range retention,
bulk duplicate handling, preserved drafts and native reusable-group copying.
It then failed the Remove prop handler assertion. The result is failed overall;
owner switching, macro entry and save/reopen were not reached. The next frozen
fixture records active view, inline source list, removal result and UI error to
diagnose that action without guessing. No user installation has occurred.

`build/native-032-ui04` passed the SDK/native campaign; its diagnostic normal
host reproduced the same failed removal assertion after 35 passes. The new
observation was decisive: immediately after native group creation, there was no
active Modify CA and its old view was retired. The new library contained all
three assets, while the retired list still showed two. Removal correctly refused
to act through a retired view. The UI successor resumes the unchanged Document
only if Max closed the context and no other view took over, then restores the
captured ten draft fields/Repeat seed. It also resolves explicit focus through a
pinned stack and rejects ambiguous Use geometry rather than creating a third
arrangement. `build/native-032-ui05` freezes these changes and regressions.

The successor **passed 52 actual Max2027 Modify checks** in
`build/host-032-ui05/receipt.json`, using `build/native-032-ui05`. The host exited
normally; loaded main/storage paths, unchanged copied binaries, private INI and
unchanged checked artist profiles all passed. This includes the group-context
regression, removal through the resumed view, pending draft preservation,
selection ambiguity, stale-view rejection, explicit focus through a pinned stack,
the real Create macro and schema5 save/reopen with inline scale restoration.
The exact source pair is now running the separate 100-copy/cabinet API fixture
in `build/host-032-geometry04`. No full release or renderer/gesture claim follows
from these checks; paths, refined collision/packing, diagnostics, real scenarios,
performance and final installer qualification remain open.

The separate current-source Max geometry campaign passed **all 19 checks** in
`build/host-032-geometry04/receipt.json`, with normal exit and all five identity/
profile guards. This independently checks 100 actual outputs (full footprint,
contact, scale range, pair nonoverlap, source/material preservation), repeated
and fresh seeds, Undo/Redo, invalid-draft retention, schema5 save/reopen and a
450mm device fitting beneath 280mm clearance while honoring its scale floor.
The native build, 52-check UI host and 19-check geometry host share the same
142-file source map. The verified progress checkpoint is
`build/ui-032-progress03/progress.json`. The full goal remains active; no installer
or artist profile was changed. Continue the remaining ledger requirements rather
than interpreting this foundation as a completed fourteen-item release.

## Native path component phase (historical checkpoint)

Source now adds `path.h`, `path.cpp` and `path_tests.cpp`. It contains bounded
world-millimetre Bezier arc inversion, sampled full-footprint lane containment,
quantity/spacing, source-forward alignment/reverse, local jitter, one/two-lane
counts, uniform random/fit scale, output collision/gap, physical-query delegation
and protected output. Path settings/references/publication and inline controls
have not been integrated into Max yet. Items10–12 remain incomplete.

The initial frozen path02 SDK/native build passed fourteen suites and 7,615 path
checks. The subsequent preflight-admission regression passes 7,616 focused checks;
`build/native-032-path03` is the frozen SDK/native successor in progress. The
previous Max UI52/geometry19 receipts remain baseline evidence for their own
142-file native/UI pair, not qualification of this new source. No installer or
artist profile was changed. See [native path decisions](PATH_CORE_0.3.2.md) and
[required host integration](PATH_HOST_INTEGRATION_0.3.2.md).

The final path-native successor `build/native-032-path03` compiled both Max2027
modules and passed all **fourteen native suites**, with **7,616 path checks**.
Its 145-file source map is current and recorded with the receipt digest in
`build/path-032-progress01/progress.json`. The path component is numerical-only
so far; native Max references, schema6, capture, transactions, inline Path UI and
actual Max scenarios remain open. The earlier 52/19 host passes retain their
frozen baseline scope. Continue host integration; do not mark the goal complete.

## Current Max path and compact Modify integration

Schema6 now stores the typed optional layout and both lane IDs. Real Document
reference6 binds the evaluated spline through Undo, clone, deletion and load.
Host capture copies transformed world-millimetre Bezier controls; final native
publication rechecks path contents and current dependency/time/unit tickets.
Path-only queries explicitly omit required mesh support while keeping collision
checks. Bound receivers still validate actual support and clearance. Path mode
does not need the surface inspection grid.

The initial full SDK build exposed a PathArrangementResult extraction error; the
document codec fixture also needed its unsupported-version and footer offsets
updated for schema6. Both failures are preserved as diagnostics. Subsequent
`build/native-032-path-host02` passed fifteen suites and
`build/host-032-path01` passed 26 actual Max path checks. The first mounted UI
extension stopped after 55 passes: native binding had committed, then the UI
called a refresh function before its lexical declaration. Moving that helper
after the refresh definition fixes the source error. The failed receipt remains
`build/host-032-path-ui01`.

The current source merges Path, Two-way lanes and Path variation into **one Path
rollout**, leaving five sections total. Only the main section and Props start
open. Path hides irrelevant width, second-lane and spacing controls and compacts
its rows. All normal entry actions focus this native Modify view; Generate
stages the visible values with the solve. There is no separate Apply or new
settings dialog. [The development user workflow](GEOMETRY_USER_WORKFLOW_0.3.2.md)
explains the normal steps.

Frozen current pair `build/native-032-path-host03` passed both Max2027 modules and
all **15 native suites**. Its owned normal-Max run
`build/host-032-path-ui02` passed **78 mounted Modify checks**, including path
binding, contextual compact fields, six actual cars, count/spacing, jitter,
dropdown mapping, no solve when opening sections, Undo/Redo, clear/restore,
save/reopen and automatic spline selection through the Create macro.
`build/host-032-path02` passed **26 path API checks** on that same source pair.
Both hosts exited normally and passed all five identity/profile guards.
The matching `build/host-032-geometry05` then passed **19 geometry/fit checks**,
including the 100-copy board and bounded cabinet fit, with normal exit and all
five guards. The four receipts share the current 149-file source map; their
digests and remaining scope are in `build/path-host-032-progress01/progress.json`.
See [the detailed checkpoint](MAX_PATH_MODIFY_VALIDATION_0.3.2.md).

These are primitive road/car tests and actual control handlers, not mouse-pick,
visual-quality, full real-model or final-installer certification. Independent
collision/surface overrides, packing/diagnostic refinement and the remaining
real-model/performance requirements stay open. Do not mark the full goal complete.

## Detailed books and arbitrary stair props

The next focused source pair adds `arrange_shelves_stairs_tests.ms` and
`verify_shelves_stairs.py`; all production C++/UI hashes remain unchanged from
the preceding path/Modify checkpoint. `build/native-032-shelves03` passed both
SDK modules and fifteen native suites. `build/host-032-shelves02` passed **22 Max
checks**, with normal exit and all five native-pair/profile guards. Independent
actual-mesh verification and four deliberately invalid geometry controls passed.
The 151-file map and exact receipt/artifact digests are recorded in
`build/shelves-032-progress01/progress.json`.

This proves 100 complete prepared books on divided shelves, and 48 mixed props
on actual modeled treads, including full final-scale support, clearance,
solid/pair avoidance, exact source mesh/UV/material preservation, repeatability,
protected quantity/pose, Undo and logical scene save/reopen. The original library
Max/metadata/maps remain unchanged. Native generation calls measured 118ms and
75ms after scene preparation; these are not cold-load/render/FPS benchmarks.
The cabinet/stairs and fruit/bin are original modeled test assets; the book is
the full prepared imported mesh. See [the complete focused report](SHELVES_STAIRS_0.3.2.md).

The first host attempt stopped at a test assertion comparing pre-Protect double
values with the accepted actual Max transform. Protect intentionally captures
current node transforms, including artist edits and float scale. The corrected
witness reads that accepted pose before regeneration; its measured deltas are
zero. Failed receipts and partial exports remain preserved.

The stair case's valid output is 43 fruit, 4 books and 1 bin on three of six
treads. It exposes the next production improvement: large/required source
priority and deliberate distribution before small-object fill. Continue that
packing work, diagnostic/highlight feedback and inline independent overrides;
do not treat physical validity or this focused pass as completion of the whole
fourteen-item objective. Curved real-model roads, units/performance coverage,
picker/create gestures and exact final installer acceptance also remain open.

## Required props and balanced priority packing

The next production change implements native required deficits, largest-first
surface packing, balanced usable-space search, and independently seeded Fill
regions. A selected source's optional Min copies field stays in Props in Modify;
it is zero by default and commits only with Generate. Protected output counts
once toward total and minimum. Impossible required copies remain honestly
unfilled. Preferred/original size is searched before verified fit reductions.

Frozen `build/native-032-packing-host02` passed both Max2027 modules and all **17
native suites**. On that exact 154-file source map, owned Max runs passed **83
Modify**, **26 detailed shelf/stair**, **26 path API** and **19 geometry/fit**
checks. All four exited normally and passed all five identity/profile guards.
Independent actual-mesh proof and four negative controls passed. The new source
schema7 footer and transient CA version5 preserve native identities and old-file
read support. See [the algorithm, API and proof](PACKING_PRIORITY_0.3.2.md) and
`build/packing-032-progress01/progress.json` for exact identities.

The new 100-book distribution is 24/23/26/27 over four levels. The 48 stair props
now include 15 books, 16 bins and 17 fruit across all six treads, satisfying
minimums of eight books and four bins. Generation measured 59/28 ms after scene
preparation; neither number is a general benchmark. Previous receipts and
goldens retain their historical meanings. Path minimums and explicit book-row
composition with minimums are not yet supported at this checkpoint and reject
explicitly. The full objective remains active.

## Shared path minimums and current exact-pair checkpoint

The next native implementation removes that temporary path restriction. Minimums
apply to combined active lane copies, including protected output once. Required
large sources precede optional demand; a bounded optional fallback fills usable
slots with other selected sources without consuming missing required copies.
The surface proposal kernel also normalizes extreme finite protected rotations
before trigonometry. Source identity, material and mesh remain unchanged.

Clear path preserves the combined Quantity target. In Center spacing mode it
uses the current output count, within admission/minimum bounds, without recapture
or solve. CA version6 rebases mode/count and preserves genuinely pending unrelated
gap, scale, seed and minimum edits. A fresh mounted test caught the former spacing
mode behavior after 83 passes; its failed receipt remains preserved. The successor
passed that exact witness plus pending-draft preservation and Undo.

Current frozen `build/native-032-path-min-host02` passed both Max2027 modules and
all **17 native suites**, including 8,199 path, 5,174 packing and 66 minimum-storage
checks. Four owned Max2027 runs on its identical **154-file source map** passed
**88 Modify**, **37 path API**, **26 shelf/stair** and **19 geometry/fit** checks:
**170 total**, all with normal exit and all five identity/profile guards.
Independent shelf/stair mesh verification and four deliberately invalid controls
also passed. Exact hashes and scope are in
`build/path-minimums-032-progress01/progress.json`; see
[the implementation report](PATH_MINIMUMS_0.3.2.md).

This pair retains the 100-book and 48-prop geometry distributions above. Its
generation calls measured 102/55 ms after preparation while the owned UI campaign
also ran. Timing variation from earlier runs is not a before/after benchmark or
a latency/FPS guarantee. No artist installation or computer use occurred.

Continue irregular source-envelope/support refinement, useful failure reasons,
proposed fit/highlights and inline independent overrides. Resolve the explicit
book-row/minimum interaction without requiring an inaccessible retired control.
Complex imported receivers, actual car models/curved roads, broader units,
performance/lifecycle coverage, gesture acceptance and the final exact installer
remain open. The full fourteen-item goal is active, not complete.

## Automatic compound source collision refinement

The current pair `build/native-032-collider-host03` passed both Max2027 modules
and all **18 native suites**, including **14,313 compound-collider checks**.
The identical **160-file source map** passed **187 actual Max checks**: existing
Modify88, path37, geometry/fit19 and shelf/stair26, plus 17 connected concave-source
cases. All five owned hosts exited normally and passed all five identity/profile
guards. Two independent actual-mesh verifiers passed and rejected eight invalid
controls. Exact source, module, receipt/export and scene hashes are in
`build/collider-032-progress01/progress.json`.

Native solve-local sources build conservative connected Z-band boxes lazily
after complete-bound overlap. Full support, edges and path lanes stay mandatory.
Static geometry/containment, prop pairs, spacing and access sweeps can refine
against those pieces. Closed geometry is certified from paired oriented edges;
unknown/open topology or insufficient precision allowance keeps the full root
envelope. Internal cuts overlap within contact tolerance and cannot bypass gap
checks by a small vertical separation. No source/material, saved schema, retained
receiver cache or UI control changed. Proxy descriptors never outlive the solve.

Actual Max proof accepts an original-size device within a protected connected
arch, around an independent static device and at shared path base centers, while
blocking actual leg/beam or protected intersections. Undo, source appearance and
reopen/regeneration passed. Independent proof uses the authored analytic arch
solid and every actual source/output vertex, not the native proxy algorithm.

The 100-book geometry remains unchanged. Stair placements now use levels
7/7/6/7/12/9 with 15 books, 16 bins and 17 fruit. An old envelope-only gap assertion
stopped the first run. The current verifier proves pair separation from envelope
distance or a separating projection of all actual mesh vertices. One pair's
envelopes are only 5.728516 mm apart, but minimum proved actual-mesh separation
across the campaign is 10.003906 mm against 10 mm requested. It rejects absent
separation proof. Current generation observations are 100/51 ms for books/stairs
and 2 ms for the modeled nested pair, under concurrent owned qualification; these
are not general performance or before/after benchmarks.

See [the implementation, limits and complete proof](COMPOUND_COLLIDERS_0.3.2.md).
Prior goldens, failed attempts and released archives remain preserved. Continue
support-patch/in-band precision, per-source failure/proposed-fit/highlight feedback
(including removing the generic technical success warning), inline receiving-surface
overrides, book-row/minimum handling and the remaining real-model/units/performance/
installer campaign. No artist installation or computer use occurred; the full
goal remains active.

## Current inline Keep clear checkpoint

The [Keep clear report](KEEP_CLEAR_0.3.2.md) records the successor to the compound
checkpoint. The existing fourth section now combines independent obstacles,
optional approach checking and placement protection. Native Add retains missing
references and normalizes groups; revision-guarded Remove repairs one slot.
Role rejection and scope commit/Undo stay in C++. The optional approach draft
commits with Generate, minimums, settings, seed and output; failed drafts retain
the accepted result. Passive opening performs no solve. No extra popup or Apply.

Fresh `build/native-032-keep-clear02` built both SDK modules and passed eighteen
native suites. The exact 160-file pair passed **216 actual Max checks** across
Modify117, geometry19, path37, shelves/stairs26 and compound17. Both independent
actual-mesh verifiers passed and rejected eight invalid controls. All five owned
Max processes exited normally and passed all five identity/profile guards.
Schema7 and actual source/material geometry remain unchanged; the transient
view is CA7. Only bridge, Modify script and its fixture changed from the prior
source map. The first UI attempt stopped after 76 checks on a missing fixture
global declaration; its failed receipt remains preserved and is not promoted.

Exact receipts, hashes, private scene paths, unchanged 0.3.1 archives and remaining
scope are in `build/keep-clear-032-progress01/progress.json`. The full goal and
release/installer work remain open. Continue useful per-source fit feedback and
highlights, support/precision, inline receiving-surface overrides, legacy book-row
handling and the broader real-model/units/performance/gesture acceptance.

## Native fit feedback checkpoint — 165 source files

[Fit feedback](FIT_FEEDBACK_0.3.2.md) now supplies copied native physical witnesses,
per-source explanations, bounded checked-size proposals and an independent native
viewport highlight. It does not use category eligibility. Contextual controls stay
in Props, collapse when irrelevant and apply only visible drafts; Generate remains
the atomic application step. Default successful status no longer contains the
technical broad-phase explanation.

Native advice uses final output, unchanged source meshes and a separate bounded
budget. Surface source caches are separate, and regional Fill only collects
failure seeds until all production children finish. Paths preserve base centers
and complete lane containment. Proposed UI values are checked after float-spinner
conversion. Reports never enter saved schema7 or Undo history; stale input/time/
unit/owner state cannot draw or apply them. Highlights preserve nodes, selection
and any staged Preview.

The exact 165-file pair `build/native-032-feedback-host04` built both modules and
passed all 19 native suites, including 40 feedback and 14,314 compound checks.
Its six owned Max runs passed 247 checks: 117 workflow, 31 fit, 19 geometry, 37 path,
26 shelves/stairs and 17 compound. Both independent mesh verifiers passed and
rejected eight invalid controls. All processes exited normally with all five
identity/profile guards. Actual shelf/stair/arch mesh exports and both qualified
0.3.1 archives are byte-identical to the prior checkpoint.

The early warning-only golden change was reviewed across six scenarios with all
pose bits/main work/rejections identical. Failed width and missing-button-handler
attempts remain preserved. Exact hashes, all source inputs, private scene paths
and remaining work are in `build/feedback-032-progress01/progress.json`. This is
verified development progress; full fourteen-item acceptance, source-base/finer
precision, receiving-surface overrides, legacy book-row/minimum handling, broader
real-model/unit/performance/lifecycle/gesture tests and final installer/startup
remain open. No artist installation, restart or computer use occurred.

## Automatic base and inline edge-gap checkpoint — 170 source files

[Automatic base support](BASE_SUPPORT_0.3.2.md) separates a conservative low
geometry envelope from the complete collision body. It preserves authored
footprints and source meshes. A bounded support-center proposal fixes a reproduced
production miss on a narrow round receiver; all ordinary validation still runs.
Path generation/fit uses the same actual base center. Fill demand and large-first
priority continue to account for the whole body.

New native documents start at zero edge gap. Saved margins are preserved. Optional
Edge gap is inside Keep clear and applies with Generate. Child mount hydrates
accepted state before interpreting drafts, including saved true approach values.
All five rollouts remain in Modify; no popup or Apply was added. The view is CA9;
scene schema7 and library format2 are unchanged.

The exact 170-file pair `build/native-032-base-host04` passed all 20 native suites,
including 1,360 base checks, 40 feedback checks and 14,314 compound checks. Seven
owned Max processes passed 279 checks: Modify123, base26, fit31, geometry19, path37,
shelves/stairs26 and compound17. Every process exited normally with all five
identity/profile guards. Three independent actual-mesh verifiers passed and
rejected thirteen invalid controls. The complete 40,953-vertex prepared plant
retained effective materials and every mapped UV corner at original scale on a
smaller plate. Original source files/maps and both 0.3.1 archives are unchanged.

Exact receipts, source/document snapshots, measured timings, private scenes,
reviewed test changes and failed attempts are recorded in
`build/base-032-progress01/progress.json`. This is verified development progress.
The full fourteen-item goal remains active: broader imported receivers/real cars,
units, performance/history/lifecycle, legacy book-row/minimum behavior and final
installer/startup acceptance remain open. No artist installation, restart or
computer use occurred.

## Native status/Undo checkpoint — 171 source files

[Status and Undo](STATUS_UNDO_0.3.2.md) correct a reproduced native lifecycle
defect: a rejected scale draft's message returned after a later successful
Generate was undone, despite correct restored values and output. Native restore
now clears historical transient text while preserving dirty/dependency flags,
Live arming and complete state. Fresh dirty/load notices remain visible and
refer to Generate. Clone/protection wording uses Generate and Protect selected.
No new widget, popup, Apply action, saved field or placement computation was added.

The exact `build/native-032-status-host03` pair passed all 20 native suites. Eight
successful owned Max runs passed 310 checks: Modify123, status31, base26, fit31,
geometry19, path37, shelves/stairs26 and compound17. Each passed all five identity/
profile guards and exited normally. Three independent mesh proofs passed and
rejected thirteen invalid controls. All eleven actual mesh exports are byte-
identical to the base checkpoint; placement geometry and shaders are unchanged.

The initial status reproduction and two over-strict test attempts remain preserved.
The latter incorrectly required an empty message even for current dirty notices;
final checks preserve known notices with nonzero dirty flags and independently
verify settings/poses, controls and no extra solve. A separate owned path startup
crashed before identity/test execution. Its verified worker dump/logs are retained;
the cause is unidentified. Sequential retry passed 37 checks. No startup fix is
claimed or substituted for the failed receipt.

Exact 171 source inputs, maintained documentation snapshots, hashes, private scenes,
failed attempts and unchanged 0.3.1 archives are in
`build/status-032-progress01/progress.json`. The full fourteen-item goal and full
release remain open, including broader imported receivers/cars, units/performance/
history/lifecycle, coarse precision, legacy book-row/minimum handling and installer/
startup acceptance. No artist installation, restart or computer use occurred.

## Native device/query checkpoint — 177 source inputs

The [complete-device report](DEVICE_IMPORTED_0.3.2.md) records a reproduced
preferred-size search defect and receiving-query admission failures on actual
imported furniture. Bounded headroom-cell proposals now find the demonstrated
original-size cabinet fit before shrinking. Zero-area receiving faces are omitted
only from derived query geometry. Nonzero faces with edges below the topology
grid remain intact; affected bodies rebuild topology with exact coordinates using
the same cleared temporary buffers. Invalid input, work limits and atomic failure
remain enforced. No new popup, UI field, schema or source-model edit is introduced.

The warning-free native10 pair passes twenty suites and nine fresh Max runs:
Modify123/status31/base26/fit31/geometry19/path37/shelves26/compound17/road37,
**347 checks**. Four full-mesh proofs pass seventeen cases and reject eighteen
invalid controls; the independent lane-domain audit also passes. Some fit/stair
layouts differ after the search change, and later road cases inherit deliberate
fresh seeds. All compared source/receiver geometry is unchanged; same-seed
repetition and actual final geometry pass within the new pair. Do not claim
cross-version byte identity. Both current road previews were inspected from disk.

The new complete-appliance fixture is not accepted: its full run passes thirty
checks then Table06 publishes zero of two full-size devices. A separately owned
Max diagnostic confirms inward-facing closed glass; flipping just that glass on
a disposable copy changes native support to the physical top and publishes one
device. Independent actual geometry proves two fit, so constrained packing remains
open as well. Neither diagnostic constitutes a production orientation fix or a
full scenario pass. See [winding/packing evidence](RECEIVER_WINDING_0.3.2.md).

The exact 177-input snapshot, receipts, changed-output audit and preserved failures
are recorded in `build/device-query-032-progress01/progress.json`. The full
fourteen-item goal remains active, including completion of this real-device case,
legacy book-row/minimum handling, the earlier unidentified startup crash and final
installer/private installation/autostart acceptance. No 0.3.2 package is delivered.

## Quantity recovery checkpoint — 180 source inputs

The [bounded recovery report](PACKING_RECOVERY_0.3.2.md) records a maintained
old-core failure and the C++ correction for ordinary Quantity layouts blocked by
an earlier unlocked choice. The initial solve remains. Up to four alternate
domains share its work/candidate limits, retain every protected/unselected pose,
honor explicit obstacles and minimums, and replace the best result only when
placed count and minimum fulfillment do not worsen. The authored seed and scale
limits remain unchanged. Advice runs once for the chosen final result. No new
artist setting, popup, schema or host transaction is introduced.

The exact `build/native-032-packing-recovery02` pair passes all twenty suites,
including 5,468 space-workflow checks, with no compiler warnings. Focused native
validation of the complete captured Table06/source, after reversing only the
glass in an owned data copy, places both full-size devices for all sixteen seeds;
the preserved old native code underfilled seven. Production glass orientation is
still unchanged and remains the next receiving-geometry issue.

`build/host-032-packing-recovery03` passes 64 actual Max2027 checks with all five
identity/profile guards, including sixteen repeated seed pairs, complete source
appearance/UVs, protection, explicit-obstacle underfill, minimums, random sizes,
Undo/Redo and save/reopen. An independent actual-mesh verifier passes five cases
and rejects five invalid controls. The occupied half-table explicitly remains
2 requested / 1 placed / 1 unfilled. Current source/receipts are preserved in
`build/packing-recovery-032-progress01/progress.json`.

The first 64-check run and the expected failing imported-device run also detected
artist-profile changes and remain unqualified. Their receipts and profile audit
are preserved; the fresh 64-check repeat passes every guard. No artist profile
was restored or artist session controlled. The preceding 347-check campaign is
historical for its 177-input pair, not current 180-input regression certification.
The full fourteen-item goal remains active: receiving winding, complete imported
device acceptance, broader current-pair regression, legacy row/minimum behavior,
the earlier unidentified startup failure and final installer/autostart are open.

## Receiving preparation checkpoint — 184 source inputs

The [receiving preparation report](RECEIVING_PREPARATION_0.3.2.md) records bounded
private-mesh orientation before both inspection and precise queries. Shared native
topology retains body boundaries, supports hard-edge duplicates and real tiny
edges, and prepares only robustly closed unambiguous inward components. All
analysis/allocation/work admission finishes before winding swaps. Open,
inconsistent, nonmanifold, zero-volume and potentially nested/intersecting shells
retain authored facing. Scene/source geometry, appearance and persisted schemas
remain unchanged. No new control or popup is introduced.

The exact native03 SDK pair passes **21 suites**, including 31 new receiving
checks and 5,468 space-workflow checks, with no compiler warnings. Its complete
device host passes 39, quantity recovery 64, and current broad regressions 347:
**450 qualified actual Max checks** across eleven owned profiles. Six independent
actual-mesh proofs pass 28 cases and reject 30 controls, with a separate road lane
domain audit. Two full-size devices now use the physical top of unmodified
Table06. Source/material/UV/file preservation, preview, Undo and three-owner
reopen/repeat all pass. The device overview is supplementary and partly crops its
right table; full geometry is independently proved.

Eight broader runs pass in the original paced campaign. Its first road run
finishes 37 checks but fails a changed `Plugin.UserSettings.ini` hash guard;
`3dsMax.ini` stays identical and the writer is unknown. That receipt remains
failed and excluded. Fresh road04 passes 37 and every guard; only it counts in 450.
No artist file was restored or artist session controlled. All compared original
receiver/source geometry is identical to the earlier 177 pair; base/shelf/stair/
compound exports are byte-identical. Deliberately fresh later road seeds can
change unit-case output, which passes current-pair physical and repetition checks.

The [offline startup audit](STARTUP_FAULT_0.3.2.md) reconstructs the same Corona/CEF
worker unwind chain in both preserved null-RIP dumps. No Arrange frame occurs
on that failing chain. Missing instruction/global pages and weaker Legion image
identity prevent a root-cause conclusion or exclusion of earlier corruption.
No startup fix is claimed from subsequent normal starts.

`build/receiving-preparation-032-progress01/progress.json` seals all 184 source
inputs, maintained documentation, exact receipts, independent proofs, scenes,
inspected renders, original archive/model identities and failure audits. The full
fourteen-item goal remains active. Next is the reproduced
[legacy row/minimum conflict](LEGACY_ROW_MINIMUMS_0.3.2.md), current-workflow
performance/lifecycle and final exact package/private install/autostart. Release
auditing also found old 0.3.1 performance/installer assertions and removed-popup
expectations; these need current meaningful evidence, not relaxed guards or
restored retired UI. No 0.3.2 installer is delivered.

## Focused legacy migration and cache checkpoint — 185 inputs

The [legacy row/minimum fix](LEGACY_ROW_MINIMUMS_0.3.2.md) passes 21 warning-free
native suites and 57 actual normal-Max assertions, including three nonvacuous
comparison controls. The mounted Modify command atomically chooses ordinary
geometry placement while preserving protected legacy groups, exact poses and
internal gap. It tests competing optional props, required copies, failed drafts,
zero minimums, path transitions, Undo/Redo and save/reopen/repeat. Current-pair
authored legal raw legacy data is covered; independently released binary scenes
retain a separate migration gate. Two failed fixture attempts remain preserved.

Two backend cache runs on this same pair pass 1,109 assertions each and current
independent raw-data validation. They exercise native ordinary and explicit raw
row commands. Their timings are observational because offline evidence auditing
overlapped the normal-order run. They do not qualify Modify latency, FPS or an
isolated final performance gate. That gate will use fresh final-source runs.

`build/legacy-minimum-032-progress01/progress.json` seals the exact 185 inputs and
receipts. The previous 450-check, 28-proof-case checkpoint remains 184-input
evidence. Current release preparation is porting retired UI assumptions while
retaining raw/library/lifecycle/cache/material contracts, with 32 functional
suite names planned plus separate scoped backend performance and installed
startup acceptance. The complete fourteen-item goal remains active.
