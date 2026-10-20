# Cyrus Physics Lab 0.2.1

Standalone Max 2027 correction for millimetre-scale baked colliders. Static mesh
triangles are cooked in a bounded local scale and restored to their original
physical size. Assets below 2 cm diagonal also use a bounded uniform internal
solver length scale; public positions, gravity, velocities and output remain
in metres. This avoids submillimetre triangle-contact precision loss.
Finish validates the actual Editable Poly triangulation before
publishing it. Failed new worker startup releases its session and preserves baked
geometry. Errors identify the collider and the underlying cooking reason.

The 0.2.0 workflow below is retained. See the [0.2.1 repair report](../docs/Scatter_Physics_Research_2026-10-16/COLLIDER_COOK_021.md)
for exact evidence and the installer. Save completed scenes, run the 0.2.1 MZP
through Scripting > Run Script and restart Max 2027. Pending sessions use a
solver fingerprint; Finish/Freeze/Cancel them before upgrading.

# Cyrus Physics Lab 0.2.0

Finish settles a live brush session and bakes one independent **Editable Poly**.
Freeze bakes its current positions immediately, including unfinished overlaps.
Each baked batch is automatically bound as a static triangle-mesh collider. The
Lab's procedural rows/history for that batch are retired; source quality changes
then apply to future strokes. Baked geometry and material assignments are not
rewritten by palette/quality edits. Edit or delete a baked node normally; Start
recaptures surviving colliders. One Max Undo removes a completed batch and its
collider binding; Redo restores them together. Baked nodes remain ordinary scene
geometry if the authoring Lab is removed. Clear/Rebuild/JSON export affect only
retained procedural data, not baked scene nodes; save the MAX scene for batches.

Only checkbox press/release toggles source emission. Names select settings;
blank space and repeated row clicks leave check states unchanged. Unassigned
source materials receive a Standard material using their wire colour; assigned
single materials, UV channel 1 and smoothing groups are retained. The original
source is not assigned a fallback material. Multi/Sub source materials remain
unsupported. Start and Finish refresh the Lab's material slots.

Baking is native host-thread publication, with one Max Undo transaction. It
retains the pending preview on an allocation/conversion/budget failure. The
existing bounds remain: 64 colliders including the receiver, 200,000 combined
collider triangles, 200,000 vertices per collider and 2,000,000 output vertices/
faces. Dense render models can reach the static collision budget before the
body-count limit; use simpler source geometry or separate Labs. No collision
decimation or silent fallback is performed. Pending inputs stay locked until
Finish/Freeze/Cancel. Existing procedural results imported from earlier scenes
are included in the next successful bake.

See [0.2.0 workflow and qualification](../docs/Scatter_Physics_Research_2026-10-16/BAKE_WORKFLOW_020.md).
Use `CyrusPhysicsLab-0.2.1-Max2027.mzp` through **Scripting > Run Script**, then
restart Max 2027 yourself. The Lab remains standalone; no Computer Use, preset
changes or artist-profile installation is part of this delivery.

## Historical 0.1.9 delivery

The Models toolbar now uses compact **+ Add**, **x Remove**, and **Replace...**.
Tick models to enable future emission; highlight a row to edit/remove it. Remove
keeps the scene model and already placed bodies. Undo restores the binding.
Removed used models retain numeric snapshots and material slots; these count
toward the 64-slot bound. Clear permits their reuse.

Collision cooking retains the previous representation for valid hulls. Failed or
out-of-envelope pieces are recentered and normalized before float conversion,
with up to six retries per radius pass (two original plus at most twelve repair
cooks). The checked original-point-to-hull-plane envelope is min(0.25 mm, 10% of
proxy thickness, 0.1% of piece diagonal). Rounding remains separate. There
is no silent box/single-hull fallback. Invalid/out-of-budget pieces identify the
source/piece before world startup. The envelope grows with instance scale.
Detailed decomposition still approximates concavities; teapot openings and
arbitrary dense-pile settling remain limitations.

The quality popup retains its three rows during resizing. New icons default to
10 scene units and use a small first-click marker followed by drag sizing.
Saved radius/spinner remain in metres; existing saved icons keep their radius.

See [the 0.1.9 repair report](../docs/Scatter_Physics_Research_2026-10-16/STABILITY_UI_019.md) for scoped qualification and limits. Earlier receipts retain their original version. No Scatter integration, Computer Use, or artist-profile installation is included.

## Earlier deliveries

An independent experimental **Max 2027 geometry object** for spraying rigid
assets, settling collisions and saving the composition. Its code, registration,
native storage, controls and installer are separate from CyrusScatter. This is a
test delivery; integration into Scatter follows a later decision after testing.

Version **0.1.8** adds a checked model palette, per-model collision quality,
cached convex decomposition and a correction for large rolling hulls. See
[the current research/test report](../docs/Scatter_Physics_Research_2026-10-16/COLLISION_QUALITY_018.md)
for the exact delivery, scene and remaining limits.

Version **0.1.7** added **Show collision shapes** under Collision and proxies
(**Show shapes** in narrow panels). Cyan wires show the actual cooked moving
proxies and completed blockers; amber wires show captured static colliders.
Toggle it while brushing or paused. It changes viewport inspection only. General
models such as teapots use a conservative convex proxy: handles and hollows can
be filled in the collision shape even though the render model stays detailed.
The wires make that approximation visible. Very large displays are bounded and
show a limited-display message.

**Viewport > Show Lab icon** adds a selectable Physics P/orbit marker, including
on an empty Lab. Its radius is in metres; size it during creation or with the
radius control. It stays editable during brushing. The marker has no rendered
surface and is not a collision body. Turn it off before converting the Lab to an
editable mesh or exporting its evaluated viewport mesh, to omit picking edges.
Native Physics JSON exports contain physical models only.

The mountain-brush fix allows tall assets to clear other models within a bounded
height-relative spawn budget. Crowded births are counted and skipped while the
accepted bodies keep moving. Move to a clearer area or use wider spacing if many
births are blocked. Finish is no longer required to resume a crowded simulation.
See [the mountain investigation and validation](../docs/Scatter_Physics_Research_2026-10-16/MOUNTAIN_BRUSH_017.md).

Version **0.1.6** corrects custom collision-proxy assignment. A proxy belongs to
the **moving model**; it is not the receiving surface. The panel now names both
the model and its proxy, and rejects receiver/model role conflicts and gross
size or pivot mismatches before starting physics. **Use auto** derives a suitable
shape from the model. Friction, grip and the contact solver are unchanged.

If a previous test used a plane as the sphere's custom proxy: **Cancel session**,
select the sphere under **Models**, click **Use auto**, set friction to **0.6**,
then **Start brush**. Cancel discards the pending test; save a copy first if you
need to preserve it. Completed results require **Rebuild** after changing shapes.
Zero friction allows objects to slide off finite surface edges; add appropriate
static colliders for real barriers. The brush only emits on the receiver.

See [collision correction and validation](../docs/Scatter_Physics_Research_2026-10-16/COLLISION_BINDINGS_016.md).

Version **0.1.5** adds **Collision and proxies > Stickiness (%)**, from 0 to 100.
Start with friction 0.6 and stickiness 50–80%, then increase if your assets still
slide or roll too freely on slopes. Zero preserves the previous physics path.
This is an artistic contact-resistance control: it combines added friction,
rolling resistance and small contact-jitter absorption. It does not glue assets
to walls or damp them in flight. Objects remain dynamic and can be pushed.
Settings lock while a session is pending; Finish, Freeze or cancel before editing.
Very steep slopes and rounded assets can still keep moving until Finish times
out. The preview is retained; Freeze accepts those current poses. Reopening an
older completed scene keeps its cached geometry. Older pending sessions can
Freeze, but Resume requires their original exact solver build.
See [surface-grip design and current validation](../docs/Scatter_Physics_Research_2026-10-16/SURFACE_GRIP_015.md).

Version **0.1.4** introduced continuous brushing: one native C++ worker owns the
live world across mouse gestures. MAXScript supplies controls and bounded host
commands; physics, queues, collision, history and recovery stay native. Scene
schema 2 stores paused live sessions. Schema-1 completed caches remain readable.
The new solver profile is `cpl-continuous-1`; an exact build fingerprint guards
replay of pending sessions. Existing automatic proxies and crash recording remain.
See [0.1.4 implementation and qualification](../docs/Scatter_Physics_Research_2026-10-16/CONTINUOUS_BRUSH_014.md).
The [0.1.1 brush/UI correction](../docs/Scatter_Physics_Research_2026-10-16/BRUSH_UI_011.md)
records the actual button, timer, SDK hit and native-layout checks. Older retained
results keep their recorded solver profile; reopening does not replay them.
The [0.1.2 automatic-proxy correction](../docs/Scatter_Physics_Research_2026-10-16/AUTO_PROXY_012.md)
records the Sphere32 reproduction and the corrected detailed-model workflow.

Volumetric hulls now use bounded internal rounding to prevent the reproduced
large-sphere rolling tunnels. Thin hulls retain their previous rounding policy. Jolt
subtracts the radius before rounding, so it does not inflate the outer hull;
the rounding approximation is capped at 1 mm in source space (instance scale multiplies it). Diagnostic wires show the cooked
convex outlines and do not draw the tiny rounded edge fillets.

## Model palette and collision quality

**Objects > Models** is a checked list. Tick one or more models to spray them;
select a row to edit that model's collision settings. Use **+** to add, **x** to
unlink the highlighted model, and **Replace...** to replace its binding. Removal
preserves existing bodies and their material slots; Undo restores the binding.
Finish, Freeze or cancel pending work before changing the palette or shapes.

**Collision and proxies > Collision quality** applies per model:

- **Fast**: the previous single convex hull, suitable for simple convex objects
  and thin leaf cards. Convex hulls fill concavities and holes.
- **Balanced**: compound approximation, 100k target voxels, up to 64 vertices per
  piece. The preset selects a maximum of 8 pieces.
- **Detailed**: compound approximation, 400k target voxels, up to 128 vertices per
  piece. The preset selects a maximum of 16 pieces.

**Max pieces** (1 to 16) limits complexity. **Volume error (%)** (0.1 to 10) is V-HACD's
voxel/hull volume target; lower can improve fit, but it is not a distance tolerance
and does not guarantee every hole survives. Cached pieces are reused while inputs
are unchanged. Explicit first preparation can take time; the UI waits for the
joined native worker. No decomposition runs during redraw or pointer sampling.
The pinned BSD-licensed V-HACD backend is archived; this is an evaluated Lab
backend, not a claim of maintained upstream support or exact collisions.

**Pick proxy** retains the artist-authored single convex override and ignores the
automatic quality until **Use auto** is selected. For thin/open cards use Fast or
a suitable volumetric custom proxy. The detailed mode rejects nearly flat models.
For retained procedural results from earlier deliveries, changing shapes requires **Rebuild all strokes** or Clear; baked batches are independent of new source quality.
enablement alone does not delete or rebuild previously scattered objects.
**Show collision shapes** reveals the actual cooked convex pieces. The
sample teapot has a much tighter exterior in Detailed mode, but its handle
opening is still filled at the 16-piece limit. Custom proxies are also single
convex hulls; they do not solve that opening. Inspect the wires for hollow assets. A bounded
convexity check keeps already convex solids on the existing one-hull path.

See [research, qualification and test scene](../docs/Scatter_Physics_Research_2026-10-16/COLLISION_QUALITY_018.md).

## Install and create the test object

Run the supplied **CyrusPhysicsLab-0.2.1-Max2027.mzp** through **Scripting > Run
Script**, save work, and restart **Max 2027**. The installer verifies hashes and
stages a content-specific laboratory directory plus its own startup script. It
does not replace Scatter files or load a new native binary over a running one.
To remove the lab later, run `Uninstall.ms` from its installed content directory
and restart Max. It removes only the lab registration/startup entry and preserves
package files and scenes. A saved lab object still needs its matching plugin to
open normally; keep the installer with test scenes.

Create **Geometry > Cyrus Labs > Cyrus Physics Lab**. Use the selectable viewport icon or Scene Explorer to select an empty lab. The Modify panel owns the controls for that object.

1. Open **Objects** and pick the receiving mesh used by the brush. One receiver is supported per lab
   object. Create additional independent objects for other authoring scopes.
2. In **Objects**, use **+** below Models. Checked sources are selected with equal probability; uncheck models to exclude them.
   Assigned source materials must be single materials; an unassigned source uses its wire colour. UV channel 1 and smoothing groups are retained.
3. Collision shapes are prepared automatically; the detailed model stays unchanged.
   **Collision and proxies** names the selected model and its automatic or custom shape.
   **Pick proxy...** optionally binds a custom proxy; **Use auto** removes that override.
   A custom proxy's pivot,
   orientation and scale must correspond to the source. A missing source can be
   replaced explicitly in its existing row, then rebuilt; surviving row indices
   are preserved.
4. In **Objects**, add optional scene colliders. The receiver collides by default. Turn off **Receiver
   collides** to use a separate collision proxy while still picking on the visual
   receiver. A solid street slab is a useful initial test collider.
5. Open **Brush** to set radius, birth spacing, height, scale, seed and body limit.
   **Collision and proxies** contains thickness, friction, bounce, stickiness and custom proxies. Distances
   are **metres**, independent of the scene's display units.
6. Press **Start brush**, drag on the receiver and release. Keep drawing new
   strokes while earlier bodies fall, collide or settle. Releasing ends the
   gesture; the shared simulation stays live. Distance sampling means holding
   still adds no extra bodies, although physics continues.

The top controls apply to the pending session:

- **Pause** stops physics and leaves the brush, preserving pending objects and
  history. **Resume** continues the same world. Right-click and closing the panel
  also pause. Reopen the object's Modify panel to see its status and resume.
- **Finish** stops emission and waits for all supported bodies to settle, then
  bakes one Editable Poly and static collider in one ordinary Max Undo operation.
- **Freeze** bakes current positions immediately, including moving bodies and their unfinished overlaps.
- **Undo stroke / Redo stroke** pause and restore the full live world: earlier
  objects that the stroke pushed also return to their previous transforms,
  velocities and sleep state. Empty outside strokes create no history item.
- **Cancel session** discards all pending strokes and preserves completed output.

Finished sessions are fixed collision blockers for the next session. Max's global
Undo/Redo handles completed results; use **Undo stroke / Redo stroke** for pending
gestures. Global Undo pauses live work; undoing the completed base discards its
dependent pending session, whose last durable recovery remains in diagnostics.

Start requires a receiver and valid models. Settings and bindings lock while a
session is pending. A changed/deleted source, receiver, collider or owner frame
pauses authoring. Review the captured preview and **Freeze** it, or cancel and
prepare a fresh session. Finish cannot certify changed inputs.

Outside the receiver, births stop and the path breaks. Re-entering starts a new
path segment; a partly outside brush footprint skips unsupported candidates.
Objects can still roll off a finite surface. Pending objects wholly below a
conservative plane beneath every collider are removed and counted as fallen;
lower supporting colliders remain valid. This is distinct from surface collision
penetration. Lost removals participate in Undo/Redo.

Finish has a finite step and wall-time budget. On timeout, accepted work remains
paused: resume, undo, Freeze or cancel. Publication failure preserves both the
previous completed result and the pending preview; it requires an explicit retry.

**Result and files > Rebuild all strokes** explicitly resimulates the recorded
schedule for retained procedural rows using current bindings. It never edits baked nodes and does
not promise parity with another solver build. Schedules longer than its bounded
30,000-step budget are rejected without replacing the saved result.
**Erase nearby** removes retained procedural bodies with ordinary Max Undo; baked nodes are edited with ordinary Max tools. Procedural survivors stay
fixed until an explicit Rebuild.

## Procedural area and saved results

**Physics Area > Settle area** generates a bounded population, emits it on a
fixed-step schedule and replaces the lab's previous result only after completion.
Without a boundary it uses upward-facing receiver triangles. An optional closed
polygon spline restricts births; use corner knots and a world-XY outline. Convert
parametric shapes to Editable Splines first. Curved Bezier boundaries, multiple loops and the main plugin's Paint documents are not
part of this independent inlet. Objects can slide outside the birth boundary.

Save a **MAX scene** to preserve the complete object, sources, bindings, controls
and materials. Reopening displays cached geometry without starting simulation.
Saving or rendering pauses continuous brushing. A saved live session includes its
preview, canonical birth schedule and stroke history. **Resume** reconstructs the
matching build's world on the native worker; **Freeze** accepts its cached preview
without replay. Max's small unit-conversion roundoff is allowed when verifying
unchanged inputs; meaningful geometry/topology changes reject Resume. A
scene-unit conversion on open/merge is accepted only after every captured input
still agrees in metres. The numeric simulation keeps its original metre data.
Procedural
Area/Rebuild remain separate batch operations; their unfinished execution is not
persisted as a continuous session.

**Result and files > Save / Load** are bounded JSON files containing cached geometry, UVs,
poses, birth history and the settings recorded with the solve. Import retains the
current object's editable controls and does not guess live source/collider or
material bindings. Rebind and review them before authoring/rebuilding. Materials
and bitmap files are not embedded in JSON; MAX scenes are the full test handoff.
File I/O stays native to avoid large temporary MAXScript row arrays.

Moving a Lab moves its retained procedural composition; baked nodes have independent transforms. Before adding more work in
a different origin/unit frame, use explicit Rebuild or Clear. Authoring requires
the lab object's rotation and scale to be reset; source transforms are baked into
their captured geometry. Static inputs are the supported initial workflow.

## Collision geometry and current limits

Fast automatic proxies use a convex outline. Detailed models above 128 vertices get a
bounded conservative convex approximation with at most 192 collision vertices;
their original render vertices, faces, UVs and smoothing remain unchanged. This
can leave a small collision gap around curved/concave details; choose a custom
proxy when its silhouette needs closer control. No manual low-poly copy is needed
for a normal sphere. Open meshes are flattened along their
thinnest axis and given caps around their thickness envelope; the rendered mesh
keeps its original curvature. Small automatic proxies retain the previous path.
A closed custom proxy keeps its supplied thickness and is cooked as a convex
hull. Concavities and holes in dynamic assets are filled by that hull. Explicit custom proxies may have at
most 128 input vertices before thickening; an oversized custom mesh is rejected
when picked, preserving the previous binding. Opacity maps do not trim
collision geometry: alpha-card leaves need an explicit silhouette proxy.

Verified closed axis-aligned boxes use solid box colliders. Filled upward-facing
horizontal rectangle meshes, including subdivided Max Planes, use a finite solid
box with a 10 cm slab below their exact top surface. Boundary, winding and area
checks reject holes and inconsistent coverage. Other meshes retain triangle
collision geometry; arbitrary open meshes are not filled. General thin-body/triangle-mesh contact
and dense piles remain experimental; the evidence includes failed configurations.
Do not infer production reliability from the simple test scenes.

The absolute admission bounds are 5,000 bodies, 64 sources, 64 explicit colliders,
200,000 combined render-source vertices/faces, 200,000 collider faces and
2,000,000 output vertices/faces. Bodies, pairs, contacts, queued samples, scratch
and steps have separate limits. These are rejection boundaries, not performance
promises. Pair/contact budgets above 65,536 are rejected before solver creation;
the numerical scratch policy is 128 MiB. Extreme allocation/unwind behavior outside
that admitted envelope is not qualified. These limits are not supported-scene
capacity promises. The UI defaults to 1,000 bodies. Dense steps
or cooking can delay feedback; real mouse response and sustained production use
still need artist testing.

The test node builds a combined native mesh from retained poses. It does not use
Scatter's instancing/display pipeline. Additional UV channels, explicit normals,
multi/sub materials, animated/deforming colliders, cloth, realistic wind, local
contact-island re-settling and two-way scene-object dynamics are outside 0.1.5.
Other lab outputs must be converted to external meshes before binding them.

Native arrays and file I/O reduce MAXScript pressure, and large text-return APIs
check heap headroom. This does not close the main plugin's B26 or establish
arbitrary low-memory/GPU failure recovery. No artist heap preferences are changed.

## Reproduce the experiments

All development builds and host tests use Max **2027 only**. The work was
authorized without Computer Use; tests use numeric code and MAXScript. Physical
mouse/tablet feel, layout/DPI and renderer combinations beyond the recorded
fixture remain separate acceptance.

```powershell
python CyrusPhysicsLab/tools/build.py --dependencies-only
python CyrusPhysicsLab/tools/build.py --output build/physics-lab-<fresh-run>
python CyrusPhysicsLab/tools/compare.py --build build/physics-lab-<fresh-run> --output build/physics-compare-<fresh-run>
python CyrusPhysicsLab/tools/host_test.py --build build/physics-lab-<fresh-run> --output build/physics-lab-host-<fresh-run> --fixture CyrusPhysicsLab/tests/host_continuous.ms
python CyrusPhysicsLab/tools/host_test.py --build build/physics-lab-<fresh-run> --output build/physics-lab-grip-<fresh-run> --fixture docs/Scatter_Physics_Research_2026-10-16/grip-fixtures/host_grip.ms
python CyrusPhysicsLab/tools/package.py --build build/physics-lab-<fresh-run> --output dist/physics-lab-<fresh-run>
```

The build command never launches Max or installs files. The host command creates
an owned hidden profile and exits it. Do not direct fixtures at an artist session.
Engine comparisons copy their executable and preserve quality failures. Recorded
timings are local experiments, not presented FPS or a universal engine ranking.

`--faults` builds private commit-failure probes for `tests/host_continuous_faults.ms`; the
packager rejects those builds. Rebuild without that flag and qualify the ordinary
pair before delivery. SDKs, source caches, binaries, scenes and MZPs live under
ignored `build/` or `dist/` and need a separate backup from Git.

Jolt CPU is the current test-node engine. PhysX CPU is compiled into the offline
comparison executable, not the Max modules. Exact dependency commits are in
`tools/build.py`. Jolt and nlohmann notices accompany the package. The execution
ledger records why this provisional choice was made and which gates remain open.

## Crash diagnostics and recovery

Recording starts automatically when you press **Start brush**. **Open logs** in
the brush header opens the current recording folder. After a crash, open
`%LOCALAPPDATA%/Cyrus/PhysicsLab/Diagnostics` and keep the newest timestamp/PID
folder. Zip that entire folder for diagnosis; nothing is uploaded automatically.

The folder contains flushed `events-*.jsonl` files with button/callback order,
screen/world hit coordinates, normals, pressure, emission recipes and solver/
commit/error state; `context-*.json` snapshots contain exact source/receiver/
collider geometry, settings and saved/pending bodies. `build-identity.json` and
`modules.json` identify the package and loaded modules. A separate hidden watcher
records fatal-code notifications to `exception.txt`, writes `exception-*.dmp`
where possible, and records dump success/failure and the process exit code.
UI/timer records also include MAXScript free heap bytes and process working-set,
private and peak working-set bytes. A runtime error alone does not mean the heap
is exhausted. `dump-attempts.jsonl` retains attempt outcomes; successful dumps have
their own `.dmp.json` receipt. A failed later dump preserves a complete older dump.

Event files retain four 8 MiB segments, context snapshots retain eight slots with
a 32 MiB limit per snapshot, and the watcher retains two dumps. Old recording
folders remain available. Capture errors are reported by `cplDiagnosticInfo()`;
its `recording`, `watcher_ready` and `error` fields must indicate a working recorder.
The diagnostic helper never attaches as a debugger or replaces Max's crash handler.
Immediate process termination, system failure, disk errors, stack exhaustion or
fail-fast termination can prevent a final dump. Events already flushed survive
an ordinary application crash; capture does not rely on a clean shutdown.
The first fault dump is preserved; the second slot records the newest later
fault, so repeated rethrows cannot overwrite the original exception context.

The recorder captures Painter callbacks delivered to this brush, rather than
unrelated desktop clicks. Local context/dump files can contain scene geometry and
process memory; share only the recording you intend to investigate. This remains
an experimental diagnostic build.

`live-recovery-N.json` is atomically replaced after gesture/control boundaries and
about once per second while the world changes. Its companion `.status.json` says
whether the slot was active, committed or cancelled. Up to eight live sessions
own recovery slots, each capped at 32 MiB. Keep the whole timestamp/PID folder.
After a crash, open the saved MAX scene with its original bindings, select the lab
object, cancel any older pending state, and use **Result and files > Recover
session...** to load the relevant recovery JSON. Review its cached preview before
Resume or Freeze. An older solver build can Freeze its preview; Resume requires
the exact recorded build. The last unflushed commands or physics steps can be lost
on abrupt termination; the durable file is a recovery boundary, not a guarantee
of recovering the final mouse event.

The queue reserves capacity for controls (384 sample / 512 total commands).
History has 128 gestures and a 64 MiB checkpoint budget. Session work stops at
120,000 steps; Finish also has its own bounded budget. These limits reject further
work without silently deleting accepted history. Native snapshots avoid
placement-sized MAXScript arrays. A 5,000-body low-poly stress is a capacity check,
not an interactive-performance promise; use the measurements linked above.
