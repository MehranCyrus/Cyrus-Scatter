# Cyrus Physics Lab 0.1.3

An independent experimental **Max 2027 geometry object** for spraying rigid
assets, settling collisions and saving the composition. Its code, registration,
native storage, controls and installer are separate from CyrusScatter. This is a
test delivery; integration into Scatter follows a later decision after testing.

Version 0.1.3 adds crash-surviving local diagnostics and guards late Painter
callbacks after a rejected/cancelled stroke. It retains the 0.1.2 automatic
collision-shape reduction for detailed source models,
including ordinary 32-segment spheres. It keeps scene schema 1 and uses solver
profile `cpl-leaf-3`. Scatter's version, schema,
registration and licensing are unaffected. Use fresh test scenes with the exact
qualified package. See [execution and evidence](../docs/Scatter_Physics_Research_2026-10-16/IMPLEMENTATION.md)
and [the research](../docs/Scatter_Physics_Research_2026-10-16/README.md).
The [0.1.1 brush/UI correction](../docs/Scatter_Physics_Research_2026-10-16/BRUSH_UI_011.md)
records the actual button, timer, SDK hit and native-layout checks. Older retained
results keep their recorded solver profile; reopening does not replay them.
The [0.1.2 automatic-proxy correction](../docs/Scatter_Physics_Research_2026-10-16/AUTO_PROXY_012.md)
records the Sphere32 reproduction and the corrected detailed-model workflow.

## Install and create the test object

Run the supplied **CyrusPhysicsLab-0.1.3-Max2027.mzp** through **Scripting > Run
Script**, save work, and restart **Max 2027**. The installer verifies hashes and
stages a content-specific laboratory directory plus its own startup script. It
does not replace Scatter files or load a new native binary over a running one.
To remove the lab later, run `Uninstall.ms` from its installed content directory
and restart Max. It removes only the lab registration/startup entry and preserves
package files and scenes. A saved lab object still needs its matching plugin to
open normally; keep the installer with test scenes.

Create **Geometry > Cyrus Labs > Cyrus Physics Lab**. Use Scene Explorer to
select an empty lab object when necessary; its geometry appears after the first
result. The Modify panel owns the controls for that object.

1. Open **Objects** and pick the receiving mesh used by the brush. One receiver is supported per lab
   object. Create additional independent objects for other authoring scopes.
2. In **Objects**, use **Add...** below Models. Multiple sources are selected with equal probability.
   Sources need a single material. UV channel 1 and smoothing groups are retained.
3. Collision shapes are prepared automatically; the detailed model stays unchanged.
   **Collision and proxies** shows Automatic or Custom for the selected model.
   **Pick...** optionally binds a custom proxy; **Use auto** removes that override.
   A custom proxy's pivot,
   orientation and scale must correspond to the source. A missing source can be
   replaced explicitly in its existing row, then rebuilt; surviving row indices
   are preserved.
4. In **Objects**, add optional scene colliders. The receiver collides by default. Turn off **Receiver
   collides** to use a separate collision proxy while still picking on the visual
   receiver. A solid street slab is a useful initial test collider.
5. Open **Brush** to set radius, birth spacing, height, scale, seed and body limit.
   **Collision and proxies** contains thickness, friction, bounce and custom proxies. Distances
   are **metres**, independent of the scene's display units.
6. Press **Start brush** at the top, drag on the receiver and release. Emission is
   sampled by distance; holding still emits no extra bodies. Release finishes
   settling and commits one Undo operation.

Start stays disabled until a receiver and valid models are bound. Status and errors
are beside Start/Stop. Input controls lock while brushing or settling.

**Stop** cancels pending work and preserves the previous completed result. Existing
strokes act as frozen collision blockers for new ones. **Result and files > Rebuild all strokes** instead replays the history with the current settings and bindings;
earlier and later bodies may move together. This is an explicit solve, not a
promise to reproduce a different engine/profile's original result.

**Result and files > Erase nearby** removes nearby bodies as a frozen edit with Undo. Remaining
bodies retain their transforms, so use Rebuild if removed support should change
the pile. Closing the panel ends authoring and cancels pending work.

If settling reaches its finite step limit, the prior result remains authoritative.
Choose **Keep preview** deliberately to accept the preview, or **Stop** to cancel.
An accepted unfinished result records `settled=false`. Invalid inputs, contact
exhaustion and allocation errors cannot be accepted through Keep Current.

## Procedural area and saved results

**Physics Area > Settle area** generates a bounded population, emits it on a
fixed-step schedule and replaces the lab's previous result only after completion.
Without a boundary it uses upward-facing receiver triangles. An optional closed
polygon spline restricts births; use corner knots and a world-XY outline. Convert
parametric shapes to Editable Splines first. Curved Bezier boundaries, multiple loops and the main plugin's Paint documents are not
part of this independent inlet. Objects can slide outside the birth boundary.

Save a **MAX scene** to preserve the complete object, sources, bindings, controls
and materials. Reopening consumes stored geometry and transforms without replay.
Saving or rendering during a pending solve cancels that tentative session and
uses the last committed result.

**Result and files > Save / Load** are bounded JSON files containing cached geometry, UVs,
poses, birth history and the settings recorded with the solve. Import retains the
current object's editable controls and does not guess live source/collider or
material bindings. Rebind and review them before authoring/rebuilding. Materials
and bitmap files are not embedded in JSON; MAX scenes are the full test handoff.
File I/O stays native to avoid large temporary MAXScript row arrays.

Moving a completed lab object moves its composition. Before adding more work in
a different origin/unit frame, use explicit Rebuild or Clear. Authoring requires
the lab object's rotation and scale to be reset; source transforms are baked into
their captured geometry. Static inputs are the supported initial workflow.

## Collision geometry and current limits

Automatic proxies use a convex outline. Detailed models above 128 vertices get a
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
contact-island re-settling and two-way scene-object dynamics are outside 0.1.2.
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
python CyrusPhysicsLab/tools/host_test.py --build build/physics-lab-<fresh-run> --output build/physics-host-<fresh-run>
python CyrusPhysicsLab/tools/host_test.py --build build/physics-lab-<fresh-run> --output build/physics-extended-<fresh-run> --fixture CyrusPhysicsLab/tests/host_extended.ms
python CyrusPhysicsLab/tools/package.py --build build/physics-lab-<fresh-run> --output dist/physics-lab-<fresh-run>
```

The build command never launches Max or installs files. The host command creates
an owned hidden profile and exits it. Do not direct fixtures at an artist session.
Engine comparisons copy their executable and preserve quality failures. Recorded
timings are local experiments, not presented FPS or a universal engine ranking.

`--faults` builds private commit-failure probes for `tests/host_faults.ms`; the
packager rejects those builds. Rebuild without that flag and qualify the ordinary
pair before delivery. SDKs, source caches, binaries, scenes and MZPs live under
ignored `build/` or `dist/` and need a separate backup from Git.

Jolt CPU is the current test-node engine. PhysX CPU is compiled into the offline
comparison executable, not the Max modules. Exact dependency commits are in
`tools/build.py`. Jolt and nlohmann notices accompany the package. The execution
ledger records why this provisional choice was made and which gates remain open.

## Crash diagnostics in 0.1.3

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
an experimental diagnostic build. The separately documented edge-footprint abort
and empty-gesture Undo behavior have not been redesigned in this patch.
