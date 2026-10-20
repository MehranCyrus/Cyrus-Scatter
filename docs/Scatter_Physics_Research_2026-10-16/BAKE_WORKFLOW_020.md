# Physics Lab 0.2.0 — finished geometry and independent brush quality

18 October 2026. Standalone Max 2027 Lab. No main Scatter integration, presets,
Computer Use, artist-profile installation, commits or publication.

## Delivery contract

The successor to 0.1.9 changes the completion workflow: **Finish** settles and
bakes the complete pending session into one ordinary **Editable Poly**, then
automatically registers that node as a static collider. **Freeze** performs the
same bake at the current poses, including unfinished overlaps. The Lab retires
that batch's procedural rows and birth recipe. Changing Fast/Balanced/Detailed
therefore applies to future births without rewriting existing geometry.

This is independently versioned **0.2.0** because it changes ownership and artist
workflow after delivered 0.1.9. Scatter remains 0.86.0. Native numeric input format
2, saved Lab schema 2 and registration IDs are unchanged: baked nodes are ordinary
saved Max geometry and their references use the existing collider slots.

The actual baked polygon surface is used for static collision. It does not retain
the moving source's convex approximation. Moving objects still use the chosen
convex quality; complex holes remain approximate while dynamic. Completed static
geometry can have concavities. Collision shape inspection uses amber for these
static surfaces and cyan for dynamic convex pieces.

## Materials and palette input

Assigned single materials are preserved by reference, as normal Max material
sharing. Unassigned sources get a Standard material in the Lab's Multi/Sub slot
using the source's wire colour. The source itself remains unassigned. Start and
Finish refresh slots; a baked batch retains the material container assigned at
its creation. Editing a shared material's contents remains a normal scene-wide
material edit. Material IDs use stable physical source slots; UV channel 1 and
smoothing groups are retained. Multi/Sub source materials remain unsupported.

Only a left press and release within the same checkbox glyph toggles emission.
Row text selects collision settings; blank space, repeated selected-row clicks,
keyboard check attempts and drag-out releases cannot toggle enablement. Inputs
remain locked while a session is pending. ItemCheck notifications from the
CheckedListBox's default behaviour are rejected; the glyph command changes the
native policy and refreshes the view. Max Undo restores policy.

Microsoft's [CheckedListBox source](https://github.com/dotnet/winforms/blob/main/src/System.Windows.Forms/System/Windows/Forms/Controls/ListBoxes/CheckedListBox.cs)
documents why CheckOnClick=false alone is insufficient: a repeated selected-row
notification can still toggle. This upstream reference informs the fix; actual
Max control metrics and owned scripted tests establish the scoped host evidence.

## Ownership, failure and editing

Native C++ still owns numeric preparation, simulation, history and mesh assembly.
Workers consume copied inputs. Max's host thread stages a triangle mesh, converts
it to an SDK polygon mesh, fills the real Editable Poly class, then publishes the
node, material assignment, collider binding and retired Lab state inside one hold.
The SDK's bare PolyMeshObject is deliberately not the delivered editable node.

One Max Undo removes the batch and its collider binding together; Redo restores
the geometry/material assignment. A completed bake is a geometry boundary: live
stroke Undo does not edit an earlier baked batch. Existing procedural rows loaded
from an older scene join the next completed bake. Clear/Rebuild/JSON export affect
procedural data only. Baked nodes are saved in the MAX scene and survive deletion
of the authoring Lab. Clone retains normal Max collider-reference semantics.

Edit, move or delete a baked node normally. The next Start recaptures its evaluated
mesh and transform. Editing a bound collider during an active session pauses that
captured world; Freeze/Cancel is required before recapture. Deleted collider holes
are skipped and reused; no stale handle is dereferenced.

No node is created until validation and conversion succeed. Publication failures
roll back the scene/binding/state hold and retain pending preview. Existing crash
recording remains active, with bake.prepare/bake.commit/bake.rollback and failure
events added. A rejected bake can be retried or cancelled explicitly.

## Resource bounds

The existing caps remain: 64 colliders including an independently added receiver,
200,000 combined collision triangles, 200,000 vertices per collision mesh, and
2,000,000 output vertices/faces/UV vertices. A complex batch may reach the static
collision budget before the body limit. Baking checks the complete next-session
input before publication; it does not silently simplify or omit geometry. Use
lighter models or separate Labs when needed. Static scene geometry consumes this
same collision budget.

Peak publication includes the old state, solved state, assembled triangle mesh,
conversion mesh and editable successor; temporary meshes are released before
acceptance. Undo retains scene geometry and immutable before/after Lab states.
Repeated batches retain copied collider snapshots under the same bounds. This is
not a claim of constant memory or identical speed to convex-only collisions.

## Qualification

See [the machine evidence](BAKE_WORKFLOW_020_EVIDENCE.json) for the final exact
source/script/native, installer and host identities. Earlier failed candidate
runs remain preserved under build/. The final delivery directory is
`dist/CyrusPhysicsLab-0.2.0-20261018-02/`; the installer is
`CyrusPhysicsLab-0.2.0-Max2027.mzp`, SHA-256
`46985acbc004549c942e067431c814b6a499c468ed68a601e950bba458f018b5`.
The archive guards Max 2027, verifies every payload hash, includes licenses and
excludes private probes/fault builds and PDBs. Installation tests use owned profiles.

| Scenario | Evidence |
| --- | --- |
| Native physics, continuous world, hull/quality, grip and collision regressions | Seven CTest suites; final build receipt and tests.log |
| Checkbox glyph/row/blank/drag-out, policy Undo, materials, continuous/outside/live Undo, bake and quality change, deletion/edit/clone/Clear | 56 scripted workflow assertions |
| New sphere on baked platform and over-budget retention | 12 additional assertions; measured bottom/top about 0.2999/0.4999 m on a 0.3 m platform |
| Pending save/Resume, direct cached Freeze and Undo/Redo | 12 assertions |
| Before/after-assignment failures, retained preview, no orphan node, retry and Undo | 16 assertions using a separate unpackageable fault module |
| Objects/quality controls and seven rollout bounds/font metrics | Actual owned control rectangles at 100% and 150%, including scale change while mounted |
| Mountain pyramid, sphere and teapot | Nine source/quality cases, 140 assertions; continuous and outside paths, Finish/Freeze baking and subsequent quality change |
| Cold reopen, material sharing, ordinary poly survival and renderer witness | 18 reopen assertions; 400 x 300 Scanline render with 21,114 coloured pixels and zero black pixels |
| Mixed sources and artist handoff | 14 mixed-source assertions and 22 cumulative checks after artist-scene reopening; all three material IDs retained |

Finish has a finite settling budget. Six of the nine final mountain cases reached it and were
explicitly frozen; they are not reported as fully settled Finish successes. The
machine evidence records the actual count. This is especially relevant to the
original approximately 10 m tall pyramid and uneven terrain. No forced sleeping
or solver/friction changes were introduced to make the matrix finish.

### Defects found during implementation

- The first UI run caught an unqualified forward call to the new material refresh.
  The caller now captures its plugin owner explicitly (`this.rebuildMaterial`).
- SDK polygon conversion returned a bare PolyMeshObject. A type assertion caught
  this; publication now creates the real Editable Poly plug-in class and copies
  the converted polygon mesh into it.
- The first mountain helper inspected the old timeout flag before asynchronous
  Freeze publication. The helper now waits for command completion; the finite
  settling limit remains visible rather than being treated as a settled success.
- The size checks found a native-label/managed-list overlap after UI scaling.
  Objects layout reapplies every fixed label/control position. Both target sizes
  and their transition are then checked with actual control rectangles.
- The publication audit moved potentially allocating diagnostic arguments outside
  the accepted transaction's rollback catch. Logging failure cannot restore only
  the old Lab state after Max has already accepted the new scene geometry.

The kit contains the installer, ready mountain scene, two baked regression scenes,
artist/technical guides, machine evidence, native render witness and a hash manifest.
The separate source ZIP preserves the exact product sources in the build receipt.

A concurrent edit later expanded the shared SDK configuration's allowed-year
metadata. That external edit was preserved. A fresh explicit Max 2027 configure,
no-op build and seven-suite pass verified unchanged product binaries. The evidence
retains the previous receipt and records both shared-file identities; the tested
installer payload and script/native hashes did not change. No other Max year was
built or tested for this delivery.

Physical mouse/tablet operation, screen pixels, mixed-monitor DPI and presented
FPS are not tested. Scripted control events, SDK painter paths, native simulations,
mesh/material data and isolated rendering have separate evidence. Arbitrary dense
piles and all third-party renderers are not certified by these scenarios.
