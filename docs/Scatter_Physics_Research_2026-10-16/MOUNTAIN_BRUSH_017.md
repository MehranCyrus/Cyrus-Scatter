# Physics Lab 0.1.7: mountain brush, collision shapes and viewport icon

18 October 2026. Standalone Max 2027 investigation and delivery record.

## Scope and version decision

Standalone **0.1.6 -> 0.1.7**: add an artist collision-shape display, a selectable
viewport icon requested during this task, and correct the reproduced large-model
spawn failure. The complete scope remains a lab test delivery with unchanged
registration IDs and recipe schema; the independent patch step follows the lab's
existing test-version sequence. No main Scatter/preset integration,
Computer Use, artist installation, commit or push. Max 2027 only. Registration
identities, scene schema 2 and input format 2 remain. The saved UI flag is appended
to the lab parameter block; derived display geometry is transient. Solver replay
continues to require its exact build fingerprint.

## Initial evidence

Artist diagnostics: `20261018-073946-797-pid39068`, exact delivered 0.1.6 pair.
No exception payload was recorded. Ten live sessions are present; sessions 6–10
each accept one pyramid before a five-metre spawn-separation exception. The worker
pauses, ends the gesture, and rejects later samples. The recording contains five
original spawn exceptions and 540 subsequent "Brush is paused" command errors.
Finish clears the pause and advances the retained body. This explains the
reported one-object/stopped-animation behavior without a MAXScript-memory theory.

The actual scene is preserved at `Test Scene/Mountain Scene Brush Test.max`.
SHA-256: `99ee36fd84f34995ca565aa27ad6292a5b83b46a24ea7cfbe92a7ab87315b28e`.
An owned copy and raw diagnostic snapshots live under
`build/physics-mountain-017-20261018-01/`. Scene geometry is not published in docs.

Scene inspection finds a 250 x 250 m mountain, 10,201 vertices / 20,000 triangles,
and `Pyramid001` approximately 1.062 x 1.186 x **10.462 m**. The source pivot is
at its base. The scene also contains Forest objects and a missing main Scatter
class in the isolated lab profile; those unrelated objects are preserved and are
not needed to test the actual receiving mesh and source.

At task startup, the reviewed knowledge corpus verified 37/37 enrolled sources at generation
`b5d6a58e03cd54a24b8e2c8efe26204939f1cfdeba384db36812699f00ec1e22`, but does not
enroll Physics Lab. A broad query exceeded the response bound; a narrower exact
path query returned no match. This task uses directly inspected lab source and
fresh receipts. No knowledge refresh is performed.

## Implementation contract

### Spawn handling

- Keep the native worker running when the brush requests a crowded birth.
- Make the existing conservative spawn lift relative to the candidate's height:
  at most `max(5 metres, 2 * world-space candidate height)`. This permits a tall
  model to clear another model without accepting an unbounded vertical tower.
- Reject only individual births that still require excessive lift. Count and log
  blocked births, retain accepted births and continue the gesture/simulation.
  Body/contact/preview/history admission and genuine solver failures keep their
  explicit failure policies. Mass, friction and artistic grip settings remain.
- Keep accepted birth IDs stable, with gaps for rejected candidates. Store blocked
  counts alongside checkpoint/recovery counters; preserve Undo/Redo, cancellation
  and the previous completed result. An empty blocked gesture creates no Undo item.

### Large-model contact detection

The first corrected actual-scene workflow exposed a second defect: one of eight
dense pyramids and three of twenty-one wider-radius pyramids went through the
interior of the mountain. A tall-box test also lost three bodies. These were
not legitimate finite-edge departures. A native replay of the accepted births
confirmed whole hulls below the terrain's lowest height while their pivots never
left the receiver. The dense pyramid that tunnelled began over twelve metres
above the terrain; initial birth overlap does not explain that failure.

The old 2 mm speculative contact envelope was sized for small scattered assets.
Jolt's linear cast does not sweep the complete angular movement of a long body;
its pinned `PhysicsSystem.cpp` explicitly describes that limitation. Widening
detection to the upstream default 20 mm prevented the reproduced large-body
failures. Increasing substeps alone, a larger hull radius, enhanced internal-edge
removal, changing manifold reduction, or changing warm-start preservation did
not remove all failures. Applying 20 mm to every source set broke an existing
thin-leaf slope witness (7.77 mm vertical penetration at 15 degrees). A contact
validation filter did not preserve the rounded-body matrix either. None of those
failed candidates is delivered.

The selected world setting uses **0.4% of the smallest source's maximum local
span at minimum authored scale**, clamped between the previous small-asset
distance `min(2 mm, thickness)` and 20 mm. It measures bounding span independently
of pivot offset. All-small source sets keep their previous envelope; adding a
large model does not force a centimetre envelope onto an existing small model.
The setting is captured when preparing the world and recorded as
`contact_distance_m` in `live.created`. Penetration slop remains at most **0.1 mm**;
no hull inflation, upward corrective force, terrain slab substitution, CCD
threshold reduction or mass/grip rewrite is introduced.

This is a bounded correction qualified for the tested model sizes, scales and
terrain. Jolt's envelope is a world setting. Widely different source sizes in
one interacting world can still require a compromise; the actual mountain tests
below use one source type per case at scale 0.8–1.2. Arbitrary mixed scales and
extreme speeds are not qualified by those passes.

### Terrain clearance at birth

Replaying the wider-radius case also measured a birth with a vertex 110 mm below
the mountain: a clear pivot alone did not clear the whole source. Before adding
a body, the native receiver BVH now supplies a conservative upper height for
triangles whose XY bounds overlap the source's world-space XY AABB. Raise the
birth only enough to clear that bound by the existing thickness. The query uses
the copied receiver, admits at most one million BVH visits, and creates no host
access, force, ongoing projection or persistent expanded geometry. It also
catches a peak inside a broad model footprint that corner-only rays can miss.

This is conservative: an overlapping triangle's higher vertex can raise a birth
slightly more than the exact footprint requires. On a folded or multi-level
receiver, the upper surface can determine that clearance. The actual heightfield
mountain is the qualified use case; underpasses and wall/ceiling scattering are
not established by these tests. Receiver misses still emit nothing.

The existing 75-degree rounded high-grip witness now Finishes at step 356 after a
clear birth, instead of timing out from its earlier embedded start. The old test
that required that failure was updated to require successful bounded Finish.
A separate deliberately one-step Finish budget verifies timeout retention and
Freeze, so the failure-policy gate remains covered. Historical 0.1.5/0.1.6
timeout receipts retain their original labels.

Primary references checked against the pinned implementation:
[Jolt PhysicsSettings](https://jrouwe.github.io/JoltPhysics/struct_physics_settings.html)
defines the speculative envelope and warns about ghost contacts if it is too
large; [pinned PhysicsSystem.cpp](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/PhysicsSystem.cpp)
explains rotation before linear casting. The selected size rule is a Cyrus
experimental policy supported by the retained tests, not an upstream prescription.

### Collision-shape display

- Add **Show collision shapes**, off by default and editable during live brushing.
  Cyan wires show moving/model proxies; amber wires show static collision surfaces.
  The display is diagnostic viewport geometry and never changes render output.
- Derive model wires from the same cooked Jolt convex hulls, adding each hull's
  centre-of-mass offset back into source-pivot space. Apply the same birth pose,
  scale, captured origin and metre conversion as the simulation. Draw certified
  plane/box colliders as their actual solid shapes and general terrain as its
  actual collision triangles. Do not use render meshes as proxy stand-ins.
- Cache numeric source/static wires at explicit preparation or a cold explicit
  inspection boundary. Redraw consumes cached wires/current poses only; toggling
  visibility does not restart, pause, advance, recook or invalidate the solver.
- Bound cached geometry and per-redraw line work separately at 200,000 segments.
  Unique cached segment storage is at most 9.6 MB per owner plus vector overhead;
  preparation also has bounded edge-deduplication scratch and may overlap old/new
  caches. The 200,000-segment redraw budget is shared across enabled owners.
  Expose limited-display status rather than imply a
  truncated overlay is complete. No per-body expanded wire cache or display data
  is added to Undo, scene files, render meshes or crash-recovery recipes.
- Use the existing Max 2027 redraw-callback approach with a small native command.
  A native non-owning document registry removes entries at destruction and scene
  retirement; draw only a live bound owner. No workers access Max or graphics APIs.

The wire view shows cooked proxy topology and poses. It does not visualize
individual contact points, impulses, rounded convex skins or the speculative
detection envelope. Teapot handles/hollows and the torus centre may be filled by
the conservative convex proxy; the detailed rendered models remain unchanged.
When a visibility toggle prepares its cache for the first time during a paused
or stale pending session, it uses the captured pending collision input rather
than recapturing edited scene geometry. Publication rollback likewise restores
the overlay that belongs to the retained pending world.

### Selectable viewport icon

The follow-up request adds **Viewport > Show Lab icon**, on by default, and a
**Radius (m)** control (0.25 m default, 0.0001–1000 m). The P/orbit/cube wire mark
uses CyrusScatter's controller pattern: a visible line icon and zero-area picking
edges on the same object. It creates no extra scene nodes, physics bodies,
colliders or per-body expanded icon cache. An empty Lab can be selected directly.
Creation's second drag sizes the marker; the radius and visibility remain
editable during a live or paused session. Idle colour is Cyrus red; selection
is white. Three plane rings keep the marker visible from side views.

Numeric icon generation, picking-mesh assembly, display state and drawing live
in native `src/max_icon.inc`; MAXScript owns the saved controls and bounded
commands. Shared icon topology is 123 line segments; its evaluated picking mesh
adds 246 vertices and 123 zero-area faces per Lab. This small fixed overhead is
outside the physical source/body geometry budget. Icon lines share the global
200,000-line redraw budget with collision inspection. Registration holds no
scene-node reference. Destruction/reset removes it; load/merge/Undo/Redo restore
valid owner handles at explicit scene boundaries. No global node-display hook
is replaced and the public scripted-object registration is retained.

The final mesh path allocates body-plus-marker buffers once before filling
them. It does not resize/copy an already assembled large body mesh just to add
the icon. Physical geometry admission remains 2,000,000 vertices/faces/maps;
the marker's fixed padding is separately bounded at 256 vertices / 128 faces.
This removes an avoidable full-preview copy; it is a source-level allocation
change, not a claim of measured presented-FPS improvement. The current draw
command targets the active viewport; other viewport layouts are not certified
as identical by the single-view host receipts.

The `cplMesh` physical geometry command, saved simulation data and native JSON
exports omit this marker. The evaluated Max mesh contains the picking edges
while **Show Lab icon** is enabled, so turn it off before converting to an
editable mesh/poly or exporting that evaluated mesh. This distinction is
intentional and documented in the control tooltip. Rendered area is zero; the
Max 2027 Scanline render comparison checks identical images with a visible
physical model and the marker enabled/disabled. It does not qualify every
third-party renderer or arbitrary modifier stack.

The first numeric resize probe tested a point outside the old camera framing;
reframing the larger marker fixed the harness. A separate render probe initially
used the wrong camera transform and produced a blank image; explicit camera TM
and a positive visible-model check corrected that test. Neither failed harness
was accepted as a product pass. The SDK hit probe uses Max's actual object
`HitTest`; no OS mouse input or Computer Use is involved.

Reference pattern inspected directly:
`AminScatter/tools/ui/templates/unified-core.ms`, `iconLines` / `buildMesh` /
`AminScatterObjectDraw`; no main Scatter code was changed. Autodesk's
[SimpleObject documentation](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Plug-ins/GUID-C0BFFE27-BB59-4265-8F70-BFE8A636F7CB.html)
documents mesh-driven selection/display. The selected approach avoids changing
the class inheritance or intercepting unrelated node-display callbacks.

## Acceptance

Reproduce the old failure using the actual scene; then test continuous strokes
and motion before Finish, blocked births, outside misses/re-entry, Undo/Redo,
scene/recovery save/replay and Finish/Freeze. Test the original tall pyramid,
teapot, rounded and hard-edged sources on the actual mountain. Validate proxy
wire geometry/pivot/unit mapping, live toggle stability, render-output identity,
cached redraw, owner deletion/reset, saved settings and 100%/150% layout. Package
and run the exact final pair through an owned installer/restart profile. Preserve
the original artist scene/profile/logs. Script/SDK tests do not certify physical
mouse input, displayed pixels, presented FPS or arbitrary geometry.

## Failed candidates and harness limits retained

The first display candidate invoked host/redraw work from a parameter-set hook
during scripted-object creation. Both owned hosts stalled at creation. Removing
that hook while retaining the same native pair allowed construction to complete.
Visibility now changes through the explicit checkbox command and binding/start
boundaries; parameter deserialization itself has no host/redraw side effect.
The candidate, symbols and two approximately 5 MB initialization minidumps are
retained in `candidate-01/` and the first owned profiles, not delivered.

The subsequent Python-driven workflow emitted multiple pyramids, animated before
Finish, displayed wires and reached `live.finish.ready` at step 1,021. Publication
correctly rejected the harness's open Max Undo hold. The workflow driver was
rewritten in MAXScript, matching the already qualified button/Undo tests; Python
is used only for read-only mesh fingerprints. No product guard was weakened and
the failed Python run does not qualify publication or completed-result Undo.

The first private publication-fault test detected the overlay reverting to the
previous completed input after an injected post-assignment failure. It correctly
retained the pending physics, but the old wires were misleading. Restore now
selects the retained pending capture whenever a pending session exists. Both
pre-assignment and post-assignment fault cases must pass before delivery.

The build also encountered a Windows linker PDB-write failure. The old symbols
were preserved under the owned build directory and the link/build was rerun.
This was a build-tool failure, not an observed artist-session crash.

## Artist workflow

1. Install the new `.mzp` through **Scripting > Run Script**, save work and restart
   **3ds Max 2027**. A matching script/native pair is required.
2. Select the standalone **Cyrus Physics Lab** object. Under **Collision and
   proxies**, enable **Show collision shapes** (**Show shapes** in narrow panels).
3. Cyan is the model proxy at its simulated pose; amber is the captured static
   collision geometry. Toggle while brushing or paused. A limited-display message
   means the bounded wire view is incomplete.
4. If crowded births are skipped, move the brush into a clearer area or increase
   spacing. The already accepted simulation continues without pressing Finish.
5. Under **Viewport**, leave **Show Lab icon** enabled to select the node even
   with no bodies. Increase its radius for a large landscape; turn it off before
   converting/exporting the evaluated Max mesh.
6. Old completed scene caches remain visible. A pending session belongs to its
   exact solver build: preserve it with the old build or Freeze its cached poses;
   Resume across solver fingerprints remains intentionally guarded. The artist's
   original mountain scene and diagnostics are retained unchanged.

## Qualification and remaining limits

Final delivery identities and exact receipts are recorded in
[MOUNTAIN_BRUSH_017_EVIDENCE.json](MOUNTAIN_BRUSH_017_EVIDENCE.json). Final source,
package, installed-pair, original-scene preservation, host and replay checks pass
the evidence collector. Intermediate candidates retain their scoped receipts.

The extra procedural 250 m terrain witness exercises 16 tall pyramids and 16 tall
boxes for 3,600 steps each. No hull passes wholly below the terrain. At thirty
simulated seconds, 14/16 pyramids and 12/16 boxes sleep; the remaining bodies still
move (maximum speeds approximately 0.011 and 0.139 m/s). Maximum final sampled
vertex depth is 2.63 mm and 5.02 mm respectively, below that large-terrain test's
10 mm bound. This is not a claim of perfect zero-depth contact or universal
settling. Freeze preserves the preview when a physical composition keeps moving
until its explicit Finish work bound.

All host checks use owned Max 2027 profiles, MAXScript commands, read-only mesh
measurements and the private SDK Painter hit/callback probe. No Computer Use,
captured UI pixels, physical mouse input, presented viewport FPS, artist installation or
main Scatter integration is implied.

Depth reporting distinguishes a vertical heightfield sample from distance along
the local terrain normal. A preliminary 10 mm **vertical** replay check flagged
the still-moving teapot at 10.31 mm in run 07; the corresponding normal depth was
9.54 mm, with 7.25 mm on sleeping bodies. Both values are retained. Final actual
mountain contact acceptance uses a 10 mm sampled **normal-distance** bound,
keeps vertical values in the evidence, and separately rejects any interior
whole-body tunnelling or accepted-body loss. This clarifies the slope-dependent
measurement; it is not a zero-penetration claim or a relabeling of that failed
preliminary check. The additional procedural-terrain witness above retains its
original 10 mm vertical bound.

## Final Max 2027 test delivery

The **final** mountain workflow uses the original copied receiver and source,
plus teapot, torus and tall-box sources. It passes **210** scripted assertions:
multiple births and motion before Finish, a second stroke while bodies move,
outside misses/re-entry, full-motion live Undo/Redo, saved paused recovery,
collision-cache toggles including a cold toggle, unchanged render-mesh hash
when toggling collision inspection, result Undo/Redo, deletion and a live crash
recorder/watcher. All **81 accepted bodies** are retained; no interior body is
lost. Crowded rejected births are counted separately.

Depths in the table are rounded up to 0.01 mm.

| Actual mountain case | Accepted / published | Final workflow | Replay maximum normal depth | Published maximum normal depth |
| --- | ---: | --- | ---: | ---: |
| Original tall pyramid, dense 1 mm brush radius | 8 / 8 | Freeze after Finish bound | 2.82 mm | 0.11 mm |
| Original pyramid, original 5 m radius | 21 / 21 | Freeze after Finish bound | 4.02 mm | 4.02 mm |
| Teapot | 12 / 12 | Freeze after Finish bound | 9.54 mm | 9.37 mm |
| Torus | 19 / 19 | Freeze after Finish bound | 4.49 mm | 4.49 mm |
| Tall box | 21 / 21 | Freeze after Finish bound | 6.31 mm | 6.31 mm |

This dense matrix uses friction **0.6**, bounce **0.05**, stickiness **0%** and
scale **0.8–1.2**. **All five final cases reached the 3,600-step (30 simulated
seconds) Finish bound and were explicitly Frozen.** Automatic settling of these
dense, low-grip piles remains an acceptance item. Earlier candidate runs did
automatically Finish some cases, but those outcomes do not replace the final
run. This delivery fixes emission/clock pausing and the reproduced interior
tunnelling; it does not guarantee every large pile stops within thirty seconds.
The UI retains that moving preview and reports the bound instead of silently
publishing it as settled.

The independent canonical replay runs 4,000 steps after the last accepted birth.
It finds **zero receiver departures and zero whole-body interior tunnels** in
all five cases. Every accepted birth has at least **195 mm** measured vertex
clearance in this particular matrix. Its maximum sampled vertical depth is
10.32 mm on the moving teapot; normal depth is 9.54 mm. Published Freeze poses
are measured separately because they are not identical to the later replay
step. These large-model tolerances are distinct from the retained small-sphere
and thin-leaf gates.

Additional final checks:

- **Five native suites pass:** 3,175 core, 413 continuous, 1,898 grip/terrain,
  579 collision and 230,492 mountain/display checks (the latter includes repeated
  per-body/per-step finite-state and terrain checks). The **192** direct-birth
  slope rows match 0.1.6 exactly; receiver-footprint birth tests have fresh results.
- **150 icon checks pass** on the final pair: default/empty selection through
  Max's real object HitTest, resized/hidden picking, no extra nodes, live control
  isolation with no recook/clock advance, save/load, independent copy and deletion.
  A physical box is positively visible in both Scanline renders; the enabled/
  disabled icon images have identical SHA-256
  `ba55df7ce82b4f9f987eea9482761207981d34ae07641f027c287fe0c7268825`.
- Native control rectangles/font metrics pass at **100% and 150%**, including
  the new Viewport rollout. Measured logical rollout widths are 162 and 108.
- Private **pre- and post-assignment publication faults** retain the completed
  result, pending bodies and matching collision wires; explicit retry and Undo pass.
- The final `.mzp` installs and automatically starts in an owned restarted
  profile, then passes **57 continuous** and **150 icon/render/layout** checks.
  Installed script/native hashes match the package. The artist profile is unchanged.
- External watcher receipts for the four final host runs and installed runtime
  record **exit code 0, zero exception notifications and empty exception payloads**.
  The initial installer-only setup creates no Lab and has no runtime recorder;
  its separate completion/installation receipt is preserved.

### Installer and retained identities

Run [CyrusPhysicsLab-0.1.7-Max2027.mzp](../../dist/CyrusPhysicsLab-0.1.7-20261018-04/CyrusPhysicsLab-0.1.7-Max2027.mzp)
through **Scripting > Run Script**, save work and restart **Max 2027**. No artist
installation or restart was performed during this task. The earlier 0.1.7
candidate packages are superseded by the **20261018-04** package.

| Artifact | SHA-256 |
| --- | --- |
| Final MZP | `4ac2b699093e9fb5cb405012103b51412e8c8e63c7017edd691421f06120ccd4` |
| Native DLX | `a2a89444185ea6bfe51e8eab406779150926540532265ace05267f99aeadcd15` |
| Native storage DLH | `d4d14ec87b582f0ef8a0bb5b34ecdca99d25cdd785230681b47dfad951a119a8` |
| Final source ZIP | `5dc55cbe27afddd66e5e34d6421074a8f870cf6be550f3c41f80c690dfa59029` |

Archive integrity, every payload hash, the Max 2027 guard and automatic startup
were verified. The private fault build and SDK probes are excluded from the
package. The source archive and final PDB are retained under
`build/physics-mountain-017-20261018-01/`; runtime evidence and installers are
ignored artifacts and will not be present in a source-only Git clone.

Final receipt folders: `build/physics-lab-017-mountain-09`, `icon-05`,
`layout150-07`, `fault-after-04`, and `installer-04` (each latter name has the
same `build/physics-lab-017-` prefix). Numeric replay is in
`build/physics-mountain-017-20261018-01/replay-09`. The original scene hash is
unchanged. No CyrusScatter/preset code, artist scene/profile, publication,
commit or push forms part of this delivery.
