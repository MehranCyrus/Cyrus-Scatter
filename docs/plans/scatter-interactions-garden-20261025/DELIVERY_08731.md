# Complete stem contact — 0.87.3.1

**Current qualified correction:** use the [Prepare model fix and tested installer](PREPARATION_FIX_08731.md).
It resolves the reported `findItem` / `ParamBlock2` runtime failure and has scoped
Max 2027 preparation, contact, Undo/Redo and save/reopen checks. Original build-only
receipts below retain their historical scope.

**Script-load correction:** the first package produced a user-reported MAXScript
parser error in Prepare model. Use the [revised installer and correction record](SCRIPT_LOAD_FIX_08731.md).
The original identities below remain historical build-only evidence, not a usable
runtime delivery. Product version remains 0.87.3.1; the correction is also untested
in Max at the user's request.

26 October 2026. **Build-only Max 2027 delivery for user testing.** The user chose
0.87.3.1 and requested no further tests or Max execution. Native Interactions is
6; saved parameter schema remains 61. [Artist workflow](ARTIST_WORKFLOW_08731.md),
[implementation/ownership](IMPLEMENTATION_08731.md).

## Change

The old native coverage pass excluded a rooted group when an upward ray hit a
collider. It skipped the group even when Hide roots was disabled. The fitter now
checks signed distance at the actual fixed root point/anchors, without projecting
the collider footprint onto the plant. All remaining contacting guides enter
fitting; there is no fraction-based bending selection.

Hiding is optional and defaults off for new layers. **Hide roots inside colliders**
uses the solid and Contact gap boundary. Fixed roots that conflict while hiding is
off report an explicit error and retain the previous complete result. No failed
guide is removed as a solver fallback. Source/fit work and memory admission remain
bounded and explicit.

**Prepare model** replaces the separate Analyze/Accept controls. It stages usable
definitions before committing them. Source-local guides remain shared across
instances. Minimum/connection edits automatically re-prepare existing prepared
sources; limit edits reuse saved inference and refresh admitted realizations.
Contact/display edits update immediately through the current contact publication.
Pending Manual scatter placement edits remain separate. Interactions tooltips,
including Advanced hover help, are removed; visible status text remains.

## Install

[Corrected Max 2027 MZP](../../../dist/CyrusScatter-0.87.3.1-20261026-preparefix/CyrusScatter-0.87.3.1-Max2027.mzp).
Run it through **Scripting > Run Script**, then restart Max. Install the complete
package because the fitter is native. No artist-profile installation, EXE,
2024/2026 build or new saved scene is part of this delivery.

Archive SHA-256: `e0c6a4289143cdc3fe697b04ecdf0640c34510d1fd32deda45c300ab087d2ac6`.
Generated script SHA-256: `f4db5fe2d697c16cbe95b8892ad06bedf6c25d8ee3d2fa98baa2449d77697608`.
The [build/package manifest](BUILD_08731.json) retains exact producer and payload
identities. SDK compilation and archive/payload/host/version integrity completed;
native tests and Max execution were not run for the delivered bytes.

## Evidence scope

The test-enabled producer `build/interactions08731-20261026-01/native-01` was
cancelled after the user changed scope; its pending receipt is not a delivery.
The successor `native-02` uses `--build-only`. Exact build/package identities are
recorded beside this report. No native tests, Python test campaign
or Max host validation is claimed for these bytes. Added regression source covers
an 80-blade overhead clump, actual-root exclusion, Gap and impossible fixed-root
failure retention; that source has not been executed for this delivery.

An intermediate generator consistency check completed before the user's no-test
instruction. Its script hash differs from the final payload; it does not qualify
the final script. Archive/version/host/payload integrity is verified as packaging
provenance. The generated MAXScript has not been compiled by Max.

The numerical bend geometry, complete mesh separation, all-guide participation,
automatic source refresh callbacks, Undo/Redo, save/reopen, physical dragging,
renderer output and performance remain acceptance items for user testing. Prior
0.87.3 passes retain their original hashes and do not qualify this successor.
Original scenes, unrelated work and artist profiles are preserved. Knowledge
retrieval was stale at intake, so current originals were inspected directly; the
knowledge index was not refreshed. No Git publication or website deployment occurred.
