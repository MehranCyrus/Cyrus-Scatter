# Legacy row mode and geometry Generate — 0.3.2

Status: native bridge correction and focused SDK/Max qualification passed. The full
fourteen-item goal remains active. Current receiving preparation is qualified
separately; this document retains the ownership contract recorded before code.

## Reproduction and expected behavior

A saved older arrangement can retain `composition.book_rows=true`. The current
Modify panel has Min copies but no book-row popup. Its Generate command preserves
that hidden mode while staging the visible minimums. Native document validation
then rejects the combination, so the artist cannot complete an ordinary action
using the controls they can see.

The raw book-row branch does not schedule per-source required counts. Its native
guards are correct and must remain: admitting the combination would risk ignoring
the minimums. The current geometry workflow must instead explicitly select
ordinary placement as part of the same Generate transaction.

## Ownership, lifetime and atomicity before code

The implementation adds a transient native command-intent flag to
`StagedArrangeSettings`, default false. `read_placement_settings`, the shared entry
for current surface and path settings/Generate, sets it. `apply_arrange_settings`
uses it to set only the
successor's `composition.book_rows=false`, before document validation. Do this for
the current workflow even when all minimums are zero; otherwise the same visible
Generate button would retain an invisible alternate solver mode.

This is a bounded command field, not a saved schema, cache key, buffer or UI option.
The existing immutable successor copy and one native Generate transaction retain
ownership. No extra geometry capture, retained memory owner, timer, worker or
selection-triggered solve is introduced. Other composition settings and source
metadata remain unchanged. Opening/loading a scene does not rewrite it.

Keep previous placements, group descriptors and asset metadata during staging.
They are required to close protection across every member of an old row and to
preserve its internal gap, which may be smaller than the current global gap.
The ordinary solver already keeps that protected relationship and counts retained
copies toward the required quantity. Unlocked output may regenerate normally.
New ordinary placement forms no book-row recipes.

Successful Generate commits the mode, visible settings, minimums, seed and complete
result in its existing single Undo operation. A failed draft, capture, solve or
publication retains the predecessor's mode, groups, output, revision and seed.
One Undo/Redo must restore the full state. Do not make a MAXScript composition
setter call before Generate, clear groups, discard minimums or relax codec/raw API
guards. Explicit legacy raw generation remains strict and available to its tests.
Path mode must continue rejecting incompatible protected surface output atomically.

## Executed diagnostic

`build/legacy-book-minimum-audit01/receipt.json` binds a build-only executable to
the unchanged native03 static libraries. It reproduces the current raw/document
exceptions, then changes only the local staged row flag. Minimum5 / quantity6
succeeds, retains all three protected members exactly and preserves their group.
The result forms no new rows or balance work. Schema7 round-trips its minimums
and protected group while the original encoded predecessor stays byte-identical.
No Max host, unified bridge change or product source was executed by this probe.

The maintained native composition suite now adds a required-count witness with a
heavily weighted competing source, protected legacy gap/pose preservation,
same-seed repetition, no new row/balance work and real headroom underfill. A
counterfactual without minimums selects the competing source, so fulfillment is
not vacuous. The persistence suite keeps raw conflict validation strict, preserves
the untouched legacy bytes and round-trips the explicit ordinary successor.
`build/legacy-minimum-portable02/receipt.json` records those passing maintained
tests against the unchanged native03 math/codec libraries, including 70 persistence
checks. This focused execution does not test the new Max bridge. The preceding
portable01 attempt failed to locate the compiler before compiling or running any
test; it is not counted as a test failure or pass.

Both cache benchmark producers and the synthetic positive fixture now use the
same exact 0.3.2 version as their validator. All 36 Python validator regressions
pass. Their workload still measures native ordinary and explicitly requested
legacy-row Generate/Preview/Commit cache behavior; it is not Modify gesture,
rendering or UI latency evidence. The later opposite-order Max runs described
below validate their raw command evidence; final isolated acceptance remains open.

## Required acceptance

Maintain native witnesses for strict raw rejection, ordinary minimum fulfillment
with a competing optional source, protected row closure and honest capacity
underfill. Preserve old-state and successor codec roundtrips. In actual owned
Max2027, create a legal legacy row setup, save/reopen it, draft Min copies through
Modify, and use the real Generate handler. Verify unchanged mode before Generate,
atomic transition, protected poses/materials, invalid-draft retention, single
Undo/Redo, reopen and same-seed repetition. Exercise zero minimums and the path
entry point. No popup, furniture category or additional Apply action is acceptable.

## Focused actual Max acceptance

`build/native-032-legacy-minimum03` freezes 185 inputs and passes all 21 native
suites without compiler warnings, including the added composition witness and
70 persistence checks. `build/host-032-legacy-minimum03` passes **57 actual Max2027
checks**, exits normally and passes both loaded-module paths, unchanged binary
hashes, private INI and artist-profile preservation guards.

The actual mounted Modify fixture covers four scenarios: protected legacy surface
rows with a competing optional source, zero-minimum ordinary placement, successful
path minimums, and rejection of an incompatible protected surface-to-path change.
It checks save/reopen before the transition; invalid scale/minimum drafts without
premature migration; exact five required books plus three optional decor copies;
one accepted revision; protected row member order and 3mm gap against 20mm external
spacing; no new row/balance work; actual output bounds; unchanged original source
geometry/live materials; one Undo/Redo with no extra solve; and accepted
save/reopen/repeat. A rejected path command keeps the old state/nodes and adds no
Undo item before the actual path-binding command. Raw explicit row APIs remain
strict and still form rows in a sole-book control.

Protected pose records are compared by unique stable ID, with every eight-field
record exactly equal. The ordered row descriptor remains exact. Three executed
comparison controls accept a record permutation but reject a 0.00001 pose change
and duplicate/missing IDs; this is not a rounded-position comparison.

The first host stopped after 15 checks because its assertion incorrectly required
the output array's protected sublist to retain its previous order. Exact per-ID
protection is the contract; native publication may order that list differently
while preserving the descriptor's ordered members. The second host passed 53
checks then hit a MAXScript method-call syntax error in the final rejection
assertion. Both failed receipts, all identity/profile guards and exact source
snapshots are preserved. No production code changed after native01; native02/03
correct only the fixture. Failed attempts are excluded from the 57 total.

This scene is a legal raw legacy recipe authored and saved by the current pair;
it is not evidence of opening an independently released old binary fixture.
The previous 450-check complete geometry checkpoint uses its own 184-input pair
and is not relabeled as 185-input qualification. Final current-pair lifecycle,
package manifest, installer and automatic-startup acceptance remain open.

## Backend cache follow-up on the same 185 inputs

`host-032-legacy-perf-normal03` and `host-032-legacy-perf-reverse03` each exit
normally with **1,109 assertions** and every native/profile guard. The independent
`legacy-cache-performance03-proof.json` validates both raw command schedules,
complete result records, physical bounds, groups, executed cache work and memory
accounting. Each run has 120 paired commands, four seed baselines and twenty
separate context commands. Cold and warm ordering is reversed between processes.

The first run overlapped a read-only offline evidence audit. Consequently its
times are observational and do not satisfy the final no-overlapping-QA timing
gate, irrespective of the driver's initial status wording. No machine-idleness,
Modify gesture latency, FPS, renderer or general-scene speed claim follows.
Final acceptance requires a fresh pair after the release inputs are frozen.

`build/legacy-minimum-032-progress01/progress.json` preserves the exact 185-source
checkpoint, receipts, documentation snapshot and this scope distinction. Its 57
focused workflow assertions are not added to the older 184-input 450 total, and
benchmark assertion counts remain separate from scenario correctness counts.
