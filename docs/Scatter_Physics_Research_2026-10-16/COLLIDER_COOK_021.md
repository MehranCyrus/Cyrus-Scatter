# Physics Lab 0.2.1 — small baked mesh colliders

19 October 2026. Standalone Max 2027 repair. No Computer Use, artist-profile
installation, Scatter integration, preset work, commit or push.

## Artist failure and the missing test condition

The supplied session `20261019-031210-718-pid43280` loaded the delivered 0.2.0
native/script pair. It recorded 21 Fast teapots, then a successful bake of
86,016 render triangles. Max's Editable Poly conversion and subsequent
triangulation yielded 84,672 triangles. Detailed source cooking then succeeded
with 16 hulls. The next world failed while creating **the baked static mesh**,
before Painter could start. The exception file was empty: this capture records
a handled cook failure, not a fatal Max crash or a MAXScript heap exception.

The 0.2.0 suite did test Fast/Finish-or-Freeze/Detailed/restart, including teapots
on the mountain. It used much larger assets. Its results did **not** establish
support for this millimetre-scale case; “tested everything” was too broad.

The exact captured input reproduces the 0.2.0 failure. Jolt's underlying reason
was `Need triangles to create a mesh shape!`. All 84,672 valid small triangles
were removed by its absolute near-zero test. Their cross-product magnitudes
ranged from about 1.10e-9 to 3.96e-7 square metres, below the 1e-6 area-vector
threshold. The old wrapper discarded that reason and exposed only
`Jolt collider cook failed`. Retrying Resume then targeted the retired worker.

The preserved numeric capture is under
`build/physics-collider-021-20261019-01/artist-capture/`; the original is untouched.
`context-3.json` SHA-256:
`3808d1e943934720c5934a2d509483e29f4f1b60c3203ad42800b24b46b40d75`.

## Correction and ownership

Static mesh cooking now uses a bounded local coordinate scale derived from the
smallest valid triangle. An inverse `ScaledShape` and the original offset put
the cooked surface back at its actual physical size. Every valid unique triangle
must survive Jolt's cleanup; losing triangle detail causes an explicit error.
Only relatively collinear faces and duplicate index triples are removed.
There is no convex/box fallback or render-mesh decimation. Existing exact boxes
and finite rectangular floors retain their established collision representation.

Cooking alone was insufficient for very small moving bodies: an added 2 mm box
test landed on a 0.5 mm tessellated slope and then lost contact. A bounded
uniform **solver length scale** corrects the contact calculation too. For an
enabled source diagonal below 2 cm after minimum instance scale, powers of two
bring its extent toward 20 cm internally, capped at 1024. Normal-sized scenes
remain at scale 1. Geometry, positions, linear velocity, gravity and physical
distance/speed thresholds are converted consistently. Time, angles, friction,
mass and angular velocity are unchanged. External data, scene geometry, emitter
logic, grip semantics and saved transforms remain in metres.

Finish/Freeze triangulates its staged Editable Poly and cooks that actual
collider **before** starting scene publication. Failure leaves the pending
preview and previous nodes/bindings intact. Publication remains one Max Undo
transaction. New-worker startup failure releases the failed worker/recovery slot
and returns to Start while retaining earlier geometry. This cleanup applies
only to a worker created by the failing Start; an existing pending session is
not cleared by a later worker failure. Saved recovery data is retained when a
recoverable session already exists. Errors include the static
collider number and underlying cause; `bake.collider.ready` logs counts and
cooking scale, and preparation logs the solver length scale.

The host owns mesh capture, conversion, scene nodes and Undo. Jolt consumes
copied numeric buffers on its worker. Cooking remains bounded by the existing
200,000 triangle/vertex admission, with linear geometry copies plus a bounded
ordered duplicate set; it adds no unbounded retry or retained geometry cache.
The new numerical code changes the solver fingerprint. Finish/Freeze/Cancel
pending sessions before upgrading; already baked Editable Poly scenes reopen.

## Qualification and delivery

The final installed pair passed in the disposable profile
`build/physics-lab-collider-021-installed-03`. The real MZP was installed there,
Max 2027 was restarted with that profile, and its automatic startup loaded the
exact packaged binaries and script. The combined fixture invoked the real button
handlers and SDK Painter callbacks, without OS mouse/keyboard automation.

| Coverage | Final evidence |
| --- | --- |
| Native core, continuous sessions, hulls, quality, grip, bindings, mountain/display and small baked meshes | 8/8 CTest suites passed |
| Exact supplied numeric capture | 84,672/84,672 valid baked triangles retained, cooking scale 128; world creation and simulation passed |
| Native small-body contact | 2 mm box supported and sleeping on a translated, finely tessellated slope; physical height 0.401159 m, solver scale 64 |
| Native scale semantics | Metre-space free-flight position/velocity agree within 1e-6; angular velocity and checkpoint restoration preserved |
| Small-object grip | On an 11.46-degree slope with friction zero, grip off slid/fell; grip on remained supported and slept |
| Fast → actual Finish → Fast restart → Detailed → brush → bake → reopen | 7 cases / 195 assertions: teapot radii 3.34, 30 and 300 mm; sphere/pyramid radii 3.34 and 300 mm |
| Exact captured scene reconstructed in Max | 22 assertions; Fast, Detailed, Balanced and Detailed again; continuous strokes and Cancel retain the original 21-teapot batch |
| Failed Start and failed bake recovery | 18 assertions; three failed Starts recover after removing the invalid collider; failed bake preserves preview and earlier geometry |
| Checkbox, materials, continuous/outside brush, live Undo/Redo and atomic bake Undo/Redo | 56 workflow assertions |
| Baked surfaces used by later strokes and budget rejection | 13 additional assertions, 69 cumulative; stacked centers 0.2999 and 0.4999 m; genuinely oversized batch rejected without publication |
| Save/load recovery | 12 assertions |
| Original mountain geometry copied for testing | Pyramid, sphere and teapot at Fast/Balanced/Detailed: 9 cases / 138 assertions, including a quality change and new stroke after each bake |

Every first Fast batch in the seven transition cases used **Finish successfully**.
One second Detailed batch and five mountain batches reached a finite settling
bound and then used Freeze. Across the combined run these were five wall-time
limits and one simulation-step limit; they are not reported as successful
natural settling. All resulting colliders cooked and allowed another session.

The final diagnostics contain 29 successful prepublication collider checks and
29 bake commits, the five deliberately induced invalid-geometry/budget
rejections, and the six settling limits above. There were no unexpected errors.
Owned Max PID 40984 exited with code 0 and zero fatal-exception notifications.
Physical mouse input, visual shading and renderer output were not inspected;
material references, fallback colors and preserved baked bindings were checked
through the host API.

The [machine-readable evidence](COLLIDER_COOK_021_EVIDENCE.json) contains the
source hashes, loaded-pair identities, captured input, native results, host
counts and installer receipt. Failed/incomplete candidates remain preserved:
the cook-only candidate failed the tiny platform contact test; an initial budget
fixture generated only 193,536 triangles and was corrected to prove it exceeds
200,000; a 600-second candidate host run timed out during mountain case eight.
None is counted as final qualification. The final suite completed with a
1,200-second allowance and the guarded startup-cleanup binary.

The final delivery directory is `dist/CyrusPhysicsLab-0.2.1-20261019-02/`:

- `CyrusPhysicsLab-0.2.1-Max2027.mzp`: 936,377 bytes; SHA-256
  `48a03d3a6e5b599be18d5205c014c71c4930f9045b807984c94a441839d132cc`.
- `CyrusPhysicsLab-0.2.1-Testing-Kit.zip`: installer, report, evidence and three
  scenes: the captured teapot reproduction, the small Fast/Detailed transition,
  and the mountain with pyramid/sphere/teapot sources. The captured scene is
  reconstructed from numeric logs, not the artist's original MAX/material file.
- `CyrusPhysicsLab-0.2.1-Source.zip`: exact product sources and build receipt.
  `testing-artifacts.json` records the kit, source archive and scene hashes.

The delivered DLX hash is
`0ebfd746592855d3c8eea4d3b3dc3a7bacdbe6d09f5c24e24e28620e24b380be`;
the UI script hash is
`c65ee89821d2b2415e701bb2392b51528a0fe54c7ef098cb2bbf9890df92b1cf`.
Archive CRC, every payload hash, the Max 2027 guard and absence of private probe
or PDB files were verified. The earlier `-01` package is a preserved candidate.

To update: Cancel a failed pending session (or Finish/Freeze a valid one), save
the MAX scene, run the final MZP through **Scripting > Run Script**, then restart
Max 2027. Keep the already baked Editable Poly nodes. There is no need to enlarge
the scene or clear existing baked geometry to use this correction. Artist
profiles were not installed into or restarted. The original mountain file's
SHA-256 remains
`99ee36fd84f34995ca565aa27ad6292a5b83b46a24ea7cfbe92a7ab87315b28e`.

## Limits and references

The combined 200,000 static triangle budget, 64 collider bound and finite Finish
settling limit remain. Freeze deliberately preserves current poses. Extremely
disparate mesh detail that cannot retain every valid face within the bounded
cooking frame is rejected with a split-collider message. This is scoped numerical
qualification, not proof for arbitrary topology, infinitesimal geometry, huge
world offsets, physical mouse input, presented FPS or every renderer.

Primary implementation evidence:

- [Pinned Jolt MeshShape sanitation and errors](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/Collision/Shape/MeshShape.cpp).
- [Pinned IndexedTriangle area test](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Geometry/IndexedTriangle.h)
  and [Vec3 near-zero default](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Math/Vec3.h).
- [Jolt maintainer explanation of scaled mesh shapes](https://github.com/jrouwe/JoltPhysics/discussions/1712).
- Native source: `CyrusPhysicsLab/src/jolt_collider.inc`, `jolt_world.cpp`,
  `max_bake.inc`, `max_host.cpp`; regression source:
  `CyrusPhysicsLab/tests/collider_cook_tests.cpp` and `collider-021-fixtures/`.

Earlier [0.2.0 bake qualification](BAKE_WORKFLOW_020.md) retains its original
hashes and scope. Its workflow guide remains applicable with the cooking and
small-object precision correction described here.
