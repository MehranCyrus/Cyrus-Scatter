# Modify status and Undo — 0.3.2 development

Status: fixed and verified as development progress, not a release. The exact pair
passed 20 native suites and 310 Max checks. The full fourteen-item goal remains
active. Previous verified snapshot:
`build/base-032-progress01/progress.json` (20 native suites / 279 Max checks).

## Trigger and intended behavior

Generate valid placements. Enter an invalid random-scale range and Generate;
the command fails and the native Document/view correctly display its error.
Correct the range and Generate successfully, then Undo that successful generation.
The accepted old settings/placements should return without reviving the obsolete
draft-validation error. Redo should restore the complete new result. The active
failed command must still show its current error until recovery; failure must
retain the accepted result and seed. Surface and path entry points both apply.

Source inspection shows `StateRestore` copies `Lifecycle::error` into its before
snapshot, and `restore_state` restores that string. Owned normal Max reproduction
`build/host-032-status-repro01/receipt.json` confirmed the defect after seven
successful checks: old settings, poses, seed and revision were preserved, the
corrected Generate cleared the current error, then Undo restored both the valid
accepted result and the obsolete native/visible message
`Invalid saved quantity or uniform scale range.` The failed receipt is preserved;
Max exited normally with all five module/profile guards. Its matched SDK build
passed all twenty native suites.

## Ownership, recovery and resource boundaries

Native Document state remains authoritative. Status/error is transient command
feedback, distinct from the saved authored settings, reference bindings, dirty
flags and placements. If reproduction confirms the issue, historical errors
should not return with Undo/Redo. Preserve dirty/dependency invalidation, reference
restoration, protected identities, accepted output, stats and failure behavior.
The view continues reading the same Document; no popup, Apply, new control,
schema, library format or independent presentation state is required.

Any fix must be bounded constant-size native lifecycle bookkeeping, with no
geometry capture, solving, extra cache or added history-sized storage on Undo or
panel refresh. Preserve current error reporting on failure and atomic rollback.
Validate surface/path handlers, state/pose/seed retention, subsequent successful
Generate, Undo/Redo, live drafts, passive refresh, saved/reopened state and the
existing exact-pair campaigns. Retain the failed reproduction receipt.

Implementation decision before editing C++: after copying the restored lifecycle,
clear its transient message with `std::string::clear()`, before notifying views.
Preserve all other lifecycle fields and the existing invalidation/restore path.
This introduces no buffer, geometry work, new allocation or persistent field;
existing string capacity may remain. Dirty restored inputs still show the view's
pending-Generate status, and a subsequent failed command writes its fresh error.
Rollback callers already report the new command's failure after restoration.

First repaired host attempt `build/host-032-status-ui01` confirmed cleared native
and visible Undo status, exact accepted state and unchanged command sequence.
Its combined immediate Redo assertion then failed. The next fixture separates
native settings/poses from controls and processes queued Qt work consistently
after both Undo and Redo. No second product defect is claimed before this evidence.

The second attempt confirmed that Redo settings, poses and Copies were correct
both before and after queued UI work. Its message was the current pending-input
notice, not the obsolete scale error. `Lifecycle::error` also carries nonfatal
dirty/load notices, so requiring every restored message to be empty was too strict.
The acceptance must reject the obsolete message while retaining known current
notices paired with nonzero dirty flags. Do not suppress dependency invalidation
to make this test pass. Reopen must similarly retain its current load notice and
require the existing explicit validation Generate.

Before further source edits: align input-change/load/clone/protection notices
with the actual **Generate** and **Protect selected** labels. These are bounded
message changes only, preserving dirty flags, Live arming and all compute paths.
Add a real Manual source-edit check for the current notice and successful recovery.

Current targeted result: `build/host-032-status-ui03/receipt.json` passed all
31 checks with both surface/path handlers, complete state/pose/seed retention,
current failed-command errors, Undo/Redo, no extra solve during passive refresh,
genuine pending drafts, load validation and a real Manual source edit/recovery.
Redo kept the current dirty notice; it did not restore the obsolete scale error.
The corresponding `build/native-032-status-host03` passed all twenty native suites.
The complete base/plant fixture passed 26 host checks on that same pair, with
independent actual-mesh proof.

## Full successor campaign

Eight successful owned Max runs exited normally with all five identity/profile
guards: Modify123, status31, base26, fit31, geometry19, path37, shelves/stairs26 and
compound17, totaling **310 checks**. All three independent mesh proofs passed and
rejected thirteen bad controls. Their six base, two shelf/stair and three compound
exports are byte-identical to the preceding 170-file checkpoint. This change does
not alter placement math, source geometry, shaders or saved formats. Native scene
schema7, library version2 and transient CA9 are unchanged.

One additional owned path process failed during startup before identity/test
execution. Its verified child PID50488 dump records an access violation at null
RIP in worker thread2960; there is no identified faulting caller. The two Arrange
module names occur in the dump, so no cause or external-plugin attribution is
claimed. Logs, failed receipt, dump and parsed analysis are preserved under
`build/host-032-status-path03`. A fresh sequential run in
`build/host-032-status-path04` passed all 37 checks with the correct pair/profile.
This retry does not establish a startup-crash fix. Broader startup/lifecycle and
full release acceptance remain open.

Only `src/arrange_document.cpp`, the new actual-host fixture and its runner's
normal-host allowlist changed from the verified base snapshot. The native restore
adds one transient-string clear; four message literals now match the current
buttons. Inspection of the installed MSVC14.38 `xstring` clear implementation
shows `_Eos(0)` with no new buffer/geometry allocation. Existing lifecycle-copy
and string-capacity retention remain; this is not a total Undo RAM or latency
claim. Dirty flags, Live arming, source/reference invalidation and complete result
restoration remain active.

The exact 171 source inputs, maintained documentation snapshots, receipt hashes,
source/private-scene identities, all failed attempts and unchanged 0.3.1 archives
are recorded in `build/status-032-progress01/progress.json`. No artist installation,
restart, computer use or renderer qualification occurred. The entire original
fourteen-item goal remains active.
