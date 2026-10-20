# Path host integration contract — 0.3.2 development

The pure C++ component and Max host integration are implemented. Historical frozen
build `build/native-032-path-host03` passed both SDK modules and all fifteen native
suites. Owned Max2027 Batch `build/host-032-path02` passed 26 actual-output checks,
including two-way cars, transformed curves, source preservation, final-scale
collisions, seed repeatability, Undo/Redo, deletion, clone and schema6 save/reopen.
All five module/profile guards passed and Max exited normally. This evidence uses
primitive models; real-model and full acceptance remain open. Mounted Modify
`build/host-032-path-ui02` passed 78 checks and the matching geometry regression
passed 19. See [the detailed checkpoint](MAX_PATH_MODIFY_VALIDATION_0.3.2.md).
The full fourteen-item goal remains active.

The [path-minimum extension](PATH_MINIMUMS_0.3.2.md) has a newer source map:
`build/native-032-path-min-host02` passed seventeen native suites and
`build/host-032-path-min-api02` passed 37 Max path checks with normal exit and all
five identity/profile guards. Required counts now span the combined lanes and
persist through Generate, Undo/Redo, clear-path and schema7 scene reopening.
The corresponding mounted UI passed 88, shelf/stair26 and geometry/fit19 checks,
all on the identical 154-file source map with normal exit and all five guards.
Source/receipt hashes are in `build/path-minimums-032-progress01/progress.json`;
earlier receipts remain bound to their original source maps.

## Saved model and real references

Extend the same native Document, OwnerAttribute, output publication and undo
transaction. Add an optional typed path layout, its curve index, PathSettings,
one/two PathLane records and a real path-node binding. Allocate both lane IDs
through the monotonic host allocator and admit them to the existing 32-bit
region/lane identity range. First-lane quantity must agree with the main authored
quantity; right-side quantity remains independent. No duplicate scripted state.

Use document schema6 for this new footer rather than relabeling prior schema5
bytes. Read3/4/5 with their exact existing defaults and accept6 explicitly. Reject
corrupt counts/enums/Booleans/ranges/IDs, missing payloads and trailing bytes;
failed decode must not advance the caller's high-water. Include lane IDs when
recovering the high-water. Preserve released files and private historical scenes.
Scene node pointers remain real Max references, never serialized handles.

The prior reference layout was owner0, furniture1, assets2, outputs3, expanded input
observer4, obstacles5. Path6 is appended, preserving those meanings. The former
six-ref Document and five-container BoundReferences are expanded consistently in save/load,
clone, Undo, staging, install, dependencies and admission. A new path container
has at most one slot, possibly null after deletion. Empty older scenes initialize
that slot without rewriting original files. Add the path root to transient
CommandDependencyWatch and current-input relevance; deleting/moving/editing the
path must dirty the arrangement and invalidate active command tickets. Passive
browsing still only reads saved data. Path sampling is fresh per Generate, with
no new retained cache initially.

## Host capture and validation

Capture the evaluated ShapeObject on Max's main thread. Read the post-WSM object
transform before borrowing evaluated geometry, matching the existing receiver
capture frame. Require CanMakeBezier; preflight total curves/pieces and check the
actual BezierShape afterward. The installed SDK exposes SplineCount/GetSpline,
Spline3D KnotCount/Segments/Closed/GetLineType/GetKnotPoint/GetInVec/GetOutVec.
Honor LTYPE_LINE with actual linear controls; for curved segments, copy outgoing
and incoming absolute handles. Transform every control into arrangement-local
world millimetres. Reuse identical knot values at joins and the closed seam so
the numerical chain is continuous. Reject unadmitted/unsupported shape data with
an actionable message; do not substitute uniform parameter spacing.

A complete capture snapshot owns the copied control chain, closure, transform,
curve index, time/units and validity. Hold the real owner/input references through
staging. Recheck current dependencies and the actual path snapshot before/after
publication. An evaluated callback edit, path deletion, scene/time/units change
or owner replacement must cancel the transaction and retain old settings/output.

When receiving road geometry is bound, use the existing native physical query
for contact, clearance and static collision after lane checks. When only a path
is chosen, its authored Z defines the base height; full-lane and output collision
checks still apply. Independent obstacles in path-only mode require a deliberate
collision-only query route, not fake support. A support-less path is an authored
placement path, not a claim that invisible ground was found. Keep positions in
the existing local millimetre frame and publish world transforms through the
existing source/material-preserving native publisher.

## One transaction and one inline view

Extend PreparedGeneration with explicit optional path input, numeric result and
validation state. The geometry key explicitly permits an empty receiver list
only with a bound path and records whether mesh support is required. Reuse
receiver geometry only when present and valid. Branch solve to arrange_path while retaining the same staged
asset refresh, output lifetime/publication guards, failure rollback and Live
entry. Preserve or reject protected placements explicitly; clearing/changing
path mode cannot silently discard locks. Book-row groups do not become path
stacks. Clone and save/reopen must preserve the typed layout and appropriate
real path/source remapping without claiming original output nodes.

Add bounded native bind/clear/read commands and a staged Generate path-settings
argument. Generate commits path/scale/amount drafts and the chosen seed with the
result in one hold. Binding commands are explicit Undoable edits and do not
inspect receiving geometry or solve. Resolve source/receiver/obstacle/path/output
role overlap and ambiguity before committing. Reuse the active view's owner GUID
and serial across pick operations and native context changes.

The same real transient CA gains one inline Path rollout, containing the useful
path/spacing/alignment, forward axis, reverse, spread and second-lane controls.
No new dialog. Expose Quantity/Spacing contextually and preserve pending drafts
through group-context restoration and Undo/Redo. Public creation may recognize
an evaluated spline selection; no furniture-type dropdown returns. The selectable
icon, toolbar and native modifier continue to edit the same Document. The current
source merges the earlier three path sections into this one compact rollout.
Controls are shown according to path/quantity/width/two-way context. Opening or
resizing that presentation must not solve or commit pending drafts.

## Required new evidence

Before a path acceptance claim: frozen core/SDK pass; actual Max straight and
curved spline capture under rotation/nonuniform transforms/units; six real cars
with three each way; independent base-center, heading, full footprint and pair
collision measurements after jitter and scale; repeated/fresh seeds; mode/lane
changes; locked output; failed capture/publication retention; Undo/Redo; path
edit/deletion/rebind; clone; save/reopen; passive UI/cache behavior; inline handler
and owner switching tests. Native-only 7,616 checks do not replace these. Full
real-model stairs/shelves, diagnostics, packing refinement, performance and final
installer gates remain separate requirements in the main ledger.
