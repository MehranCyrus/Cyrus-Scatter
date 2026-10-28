# CyrusScatter 0.87.5.3 — source workflow, scale and dense scenes

Repairs the reported `New Plants test 22.max` workflow and separates retained
viewport publication from expensive exact render construction. Both source lists
share authored membership; missing rows are removable; source-node scale and
Models Scale compose once; supported Scale changes retain Cyrus Edit deltas.
Original Library/Scene preset implementation is preserved.

[Artist instructions](ARTIST_GUIDE.md), [causes and decisions](AUDIT.md),
[completed checklist](PLAN.md), [native Undo ownership](SOURCE_COMMAND_UNDO.md),
and [exact qualification](QUALIFICATION_08753.json).

## Install and try

- [Max 2027 MZP](../../../dist/CyrusScatter-0.87.5.3-20261028/CyrusScatter-0.87.5.3-Max2027.mzp).
  Run through **Scripting > Run Script**, then **restart Max**. Install the complete
  matched script/native/managed package. No older host or EXE is included.
- [Original-style Test22 copy](<../../../Test Scene/Interaction 0.87.5.3/New_Plants_22_0.87.5.3.max>):
  1,000 grass instances and one stone, original source-node scale approximately
  0.158294 and Models Scale 0.5. The placed axis scale is approximately 0.0791468.
- [Broad stone stress copy](<../../../Test Scene/Interaction 0.87.5.3/Broad_Stone_Stress_0.87.5.3.max>):
  1,000 grass instances, source-node scale 1 and Models Scale 0.65. It retains the
  physical Cyrus Edit drag. Parked sources are hidden for review.

Both trial copies use Live, **Under collider**, a 500,000 moving-triangle limit
and unlimited idle detail. These are explicit trial choices. Original materials
and authored Edit rotations remain; copied-scene map paths resolve against the
existing local library. Both pass fresh native MAXScript save/reload checks.
The artist's original MAX file is unchanged.

Existing preparations remain readable. Including node scale can change the
recalculated size of sources which earlier builds displayed at imported size;
this is an intentional correction. Source location/orientation retain their
preceding placement semantics.

## Delivered corrections

| Reported issue | Correction |
| --- | --- |
| Interactions still lists a removed sphere | Both views bind canonical authored source-row IDs. Adding through either list updates both. |
| X cannot remove a deleted or empty model | Removal resolves row identity without requiring a live node. A stale click refreshes without deleting a successor. Point/Empty rows stay removable, although they provide no interaction mesh. |
| Replacement needs another + or reports stale data | Staging reads its successor's source arrays. Replacement preserves row settings and invalidates only its incompatible preparation/custom collider link. Manual retains the preceding publication until Update. |
| Manual source scale is ignored | Evaluated positive unsheared source-node scale, Models Scale and candidate scale compose once. Prepared plant and collider frames agree. |
| Models Scale after an instance move fails | Typed source binding permits this setting revision while retaining instance identities and Edit deltas. Genuine incompatibilities remain guarded. |
| Dense preview hits a combined 1 GiB render allocation | Viewport packets retain immutable source/pose references. Public multi-mesh render callbacks and Bake construct complete bounded batches when requested. |
| Unnecessary work during dragging/orbiting | Exact collider metadata and candidate-frame reuse reduce CPU repetition. Prepared GPU bindings retain their buffer and memory lease through Edit release. Camera activity and idle restoration share one authority. |
| Full textured navigation is expensive | Explicit Fast navigation sets a 500,000 moving-triangle quota, retains the idle quota and restores idle detail. It draws complete-instance subsets; placement counts and render geometry stay intact. |

The bounded native authored-state journal passes actual picker replacement and
one-step Max Undo/Redo with preparation/proxy restoration. Model/Point/Empty
enrollment, prepared-row removal, Scale, Z offset, Fast navigation, rollback and
caller-owned cancellation also pass.

## Evidence and practical costs

The final package is built from `native-09`, installed only in disposable profiles
and loaded through installed startup. **62/62 native tests pass.** Qualification
seals 68 scoped host receipts, generated source, package members and loaded pairs.

| Final-host control | Observation |
| --- | --- |
| Eight numeric Cyrus Edit stone moves, broad Inside solid case | Median fit 1,735.55 ms; median Edit command 1,753.58 ms. Actual movement is asserted; preparation/capture/cooking, layout, base candidates and receivers stay cached. |
| Under collider at the initial broad footprint | 157.43 ms fit; 24,659 hidden rooted groups; 820 fitted guides, compared with 12,552 in the broad Inside solid control. This changes hiding policy and is not equal-output acceleration. |
| Real mouse orbit with original textured materials | Planned idle 27,501,084 triangles; moving 495,102. Moving and restored idle draws occur without contact work, publication change or geometry/transform/owner/pose/binding uploads. Draw callbacks are not FPS. |
| Actual mouse Cyrus Edit drag | Stone X changes from 763.839 to 826.532 cm. Preparation/capture/cooking and base/receiver builds stay unchanged; geometry and binding uploads are zero. Required pose/instance data and final publication still update. |
| Source re-preparation after warm dragging | Binding upload is 4,400,160 bytes, verifying that new preparation invalidates reuse. |
| Dense exact output | Combined construction estimate 1,886,342,964 bytes is admitted as 15 batches; the first 385,014-face batch is constructed through public callbacks. The viewport accepts the scene. |
| Smaller complete exact-output control | Public multi-mesh output and Bake both produce 550,020 faces across two batches. |

Separate paired numeric replay preserves pose digests, warnings and logical work
budgets: median 2,201.82 to 2,111.45 ms, about 4.1%. This is a controlled CPU
comparison, not a universal Max speedup. Final-host timings above are a separate
run and must not be compared to that baseline as identical conditions.

## Limits and preservation

Deep overlap still reports stem-edge strain warnings; successful runtime updates
do not establish natural or physically exact bending. Contacts require positive
uniform similarity; mirrors, shear and singular transforms stay guarded.
Source-command Undo handles static settings; its keyed-controller guard is
inspected but not independently exercised in Max by this campaign.

Exact construction targets 128 MiB per batch with hard 1 GiB/20M-element bounds.
Returned meshes belong to the renderer; this is not a total renderer-memory/RSS
cap. Single-mesh callers retain their combined bound. External-renderer output
and long sessions remain separate acceptance.

No automatic stone convex hull, source decimator or CUDA solver is added. This
source stone already has only 84 triangles; the grass population and deep
contact footprint dominate. Arbitrary collider topology, exposed roots and
universal million-object real-time behavior remain open.

Library implementation matches the task-start snapshot; managed Scene code,
Scene preset and recipe templates change only release strings. Content and
independently versioned products stay unchanged. Artist profiles were not
installed/restarted, the original scene hash is preserved, and no git push or
website publication occurred. Knowledge retrieval was stale; current source was
inspected directly and no index refresh is claimed.

Identity: Scatter/managed **0.87.5.3**, Interactions **13**, source-transform **2**,
source-command Undo **1**, Edit **4** / storage **3**; scene **63**, portable recipe
**9**, Scene preset metadata **1** remain.

MZP SHA-256: `a19e3fb15838fe6106531a0f1220272f64e7bebf90978ea57dd4058baa6a39af`.
Earlier failed/superseded build and harness receipts retain their original status.
