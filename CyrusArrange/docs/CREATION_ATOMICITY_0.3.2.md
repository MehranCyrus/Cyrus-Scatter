# Geometry-bound creation and raw amount ownership

The native document owns its icon, bindings, saved settings and Undo state. The
current UI owns only the captured command context. An invalid receiving selection
must fail before leaving a new icon/document behind. Creating an icon and then
binding in separate already-accepted commands does not meet that contract.

The native `caCreateArrangement` entry will accept either no argument (an explicit
empty setup) or one node array. The latter performs existing bounded receiver or
single-spline admission and binding in the same outer native hold. It reuses the
native binding commands instead of duplicating role/lifetime/path validation.
Failure cancels the complete creation; success is one Undoable scene edit. The
icon is positioned at its first normalized input pivot and calculation origin.
Binding does not analyze, capture mesh buffers or solve. Selection/panels stay
passive. Receiver admission checks evaluated geometry type and triangle conversion
capability, with the existing4096-node bound. Numeric generation/cache lifetime
and peak mesh budgets do not change; only bounded temporary input references exist.

A command-local native watch pins/observes the normalized hierarchy across scene
callbacks. Rooted MAXScript values hold a fresh normalized receiver array, rather
than re-reading the caller's mutable array after icon creation. Owner/document,
source hierarchy/transforms, time and units are rechecked before acceptance.

The old explicit `caCreateSetup nodes category` entry has an eleven-field
density-based settings API. The shared initializer now defaults new artist
arrangements to Quantity100, so this raw entry must explicitly retain Fill mode.
The category remains descriptive. Current empty/geometry-bound artist creation
continues to use Quantity100. This is an API ownership distinction; it does not
restore category masks, caps or a furniture dropdown.

Required host witnesses: invalid helper/empty selection/mixed receiver rejection
without new nodes or Undo entries; one native bound creation with unchanged
sources, no analysis and pivot-positioned icon; one Undo/Redo of creation; normal
single-spline and failed empty spline creation; direct raw Fill versus current
Quantity defaults. Existing mounted modifier/helper and lifecycle tests remain.
Real owned node-created callbacks cover input deletion and mutation of the
caller-owned array; neither may redirect or leave a partial native command.
Source inspection motivated this correction; the fresh acceptance below now
covers the listed creation witnesses.

The partial186-input native01 campaign passes21native suites and139unified,
83region,52raw-composition and78obstacle assertions (352 total), all guarded.
Those exact sources are preserved in `build/release01-partial-checkpoint`.
Dispatch stopped before further hosts; the already-running fourth host completed
normally. No Max process or per-host runner was stopped. This is not32-suite
or installer qualification.

Further review identified a distinct window after initial binding: positioning
the icon can synchronously trigger a transform handler that edits the same native
Document. Owner identity and receiver watches alone cannot detect that edit.
The final marker commit therefore compares the post-bind state pointer before
publication and the accepted pointer afterward, failing the whole creation if
either changed. A real owned node-created callback installs an immediate transform
handler that authors seed/gap at the nonzero final pivot; the regression requires
the edit witness, complete rejection, retained prior owners and the next Undo
sentinel. The fresh release03 execution below supplies that witness.

Autodesk documents immediate notifications when `handleAt` is omitted and
explicit handler cleanup in [Change Handlers and When Constructs](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/GUID-513285B3-DBF6-471E-B587-B5BE14D4D875.html).
The actual regression below confirms the documented immediate behavior here.

Native02 passes21suites. Its first normal host exits before fixture entry and
remains failed. The fresh retry reaches the real immediate transform callback:
revision2 becomes3, seed981723 and gap37 are authored, native creation rejects
the changed state, no new owner remains and the next Undo restores the preexisting
sentinel. The retry then fails its cleanup assertion, so it does not qualify the
complete unified workflow. All native/profile guards pass for that executed retry.

The cleanup assertion incorrectly used `sweep:true`, which explicitly enumerates
retired change-handler values still held by callbacks/history. The successor
fixture retains its exact owned handler, disables and deletes it explicitly,
clears the reference and verifies that no registered handler or owned node-created
callback remains. It does not weaken Document-edit/rejection/Undo assertions.
Exact native02 inputs and both failed receipts are preserved in
`build/release02-source-snapshot`.

## Fresh release03 acceptance

The 189-input native release03 build passes all21 native suites. Its owned normal
Max2027 host `build/host-032-release03-arrange_unified_modify_tests` passes
**143 assertions**, exits0, and passes both loaded-native paths, unchanged binary
hashes, private INI and artist-profile guards. This includes the real same-Document
transform edit, complete stale-state rejection, original Undo sentinel and exact
owned-handler unregistration. Full source inputs are preserved under
`build/release03-source-snapshot`.

This qualifies the bounded creation and mounted-control contracts on that pair.
The remaining release families, independent geometry, scoped performance and
unchanged-MZP installer/autostart gates are separate and remain open.
