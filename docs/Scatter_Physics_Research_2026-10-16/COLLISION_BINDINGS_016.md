# Physics Lab 0.1.6: collision proxy correction

Status: **implemented, qualified within the scope below, and packaged for user
testing**, 18 October 2026. No artist-profile installation or Computer Use.

## Version and scope

Standalone successor: **0.1.5 -> 0.1.6**. This is a corrective delivery
for misleading collision-proxy assignment and missing input validation. It does
not integrate with CyrusScatter or change other products. Scene schema 2 and
input version 2 remain; the exact solver fingerprint still guards pending replay.
Completed caches remain readable. Historical 0.1.5 receipts are preserved.

## Incident and causal reproduction

The user's diagnostic session `20261018-033933-283-pid14612` loads the exact
delivered 0.1.5 native hashes. Both prepared contexts assign `Plane001` to the
receiver, the additional static collider, **and source slot 0's custom proxy**.
The render model is `Sphere001`, diameter 0.0319659899 m. Its custom hull spans
2.2544152683 x 1.4229937650 x 0.0020000001 m: every displayed sphere represents
a broad, thin moving plate. The receiver is deduplicated from additional
colliders, so there is only one static collider in the captured solver input.

An ignored snapshot and replay are retained in
`build/physics-settling-016-20261018-01/`. Raw artist geometry is not copied into
maintained documentation. `settling-fixtures/replay.cpp` replays the first 64
recorded births per session against the existing 0.1.5 core.

At friction 0.6 / stickiness 0, all 64 oversized plates remain active after
30 seconds beyond the last birth; final maximum speed is 0.04689 m/s. Replacing
only their hulls with the existing automatic sphere proxies settles all 64:
zero speed, zero spin, no centres below the receiver, all centres over it. The
same result holds when resetting the launch heights to the authored 0.4 m.
This isolates proxy geometry without changing friction or the Jolt contact code.

The second session uses friction 0 / stickiness 0. In this finite-plane replay,
61 automatic spheres remain on the receiver and sleep; three roll/slide beyond
the boundary and fall. The direct replay intentionally does not cull fallen
bodies. Falling after losing support is expected; it is not evidence of passing
through the surface. The captured giant plates instead all leave the plane.

## Correction contract

- A receiving surface cannot also be a sprayed model's custom collision proxy.
  Reject both assignment orders before changing references; recheck on prepare
  for older saved bindings. Name both roles and the model in the error.
- Custom proxies must approximate the model in the same pivot-relative frame.
  A conservative gross-mismatch gate rejects a proxy diagonal greater than eight
  times the model diagonal, or centre offset greater than four model diagonals.
  This catches another large surface accidentally picked as a proxy. It does not
  resize or replace authored geometry silently. Automatic preparation is unchanged.
- Validate a proposed custom shape before publishing its binding. Recheck after
  geometry/transform changes when preparing a new solve. Failure preserves the
  previous proxy and complete result. Cached old results are not re-solved on load.
- The collision rollout names the selected model and custom proxy, uses the
  explicit action **Pick proxy...**, and explains that this is the moving model's
  shape. Static scene colliders remain in Objects. Controls retain narrow-panel
  layout and lock while pending.
- C++ owns bounded geometry checks; UI owns presentation only. Checks use copied
  meshes, bounded by existing 200,000-vertex input admission. No new worker,
  per-tick geometry scan, history storage, scene schema or physics tuning.
- Crash logs, recovery publication, fixed-step solver, friction and grip remain.

## Qualification scope

Exact captured replay; native flat-plane contacts at real source scale, edge
escape, continuous emission, Undo/Redo and recovery; Max 2027 actual rollout
callbacks and Painter SDK hit/miss tests in owned hidden profiles; invalid
assignment atomicity including legacy saved data; narrow layout; exact installer
payload and loaded identities. Physical pointer input and presented FPS are not
claimed by these scripted tests. No Computer Use or artist-session installation.

## Correcting an existing test node

1. Preserve a scene copy if the pending experiment is needed, then **Cancel
   session**. This discards the pending simulation and unlocks its inputs.
2. Select `Sphere001` under **Objects > Models**.
3. In **Collision and proxies**, click **Use auto**. The receiving plane stays
   assigned under Objects; it must not be the sphere's custom shape.
4. Start with **Friction 0.6**, **Stickiness 0%**, and **Bounce 0.05**. The proxy
   correction does not require stickiness to make spheres settle on flat ground.
5. **Start brush** again. Use **Finish** to settle and publish the result.

If a completed result already exists, changing its collision geometry requires
an explicit **Rebuild** (or clearing that test result). Merely opening a scene,
choosing Use auto, or rejecting a bad binding never moves the completed cache.
An old pending session retains its saved preview; it can Freeze or cancel, while
Resume continues to require its matching exact solver build.

With friction and stickiness both zero, collisions can send objects along a
surface and beyond its physical edge. They then fall under gravity. The brush
clips *births* to its receiver; it does not constrain later simulated motion to
the painted area. Add actual static barriers if the composition needs a wall.

## Contact investigation and qualification limit

A new strict every-frame probe detected **3.225 mm of transient overlap** at the
first impact of the 32 mm sphere fixture, followed by correct settling. This is
different from crossing through a floor or continuing to bounce. The maintained
test distinguishes transient impact overlap (5 mm gate) from settled overlap
(1 mm gate), and also asserts sleep and an unchanged subsequent second of poses.
The initial test's 1 mm every-frame gate failed; that result remains in the
attempt logs and is not claimed as passed.

Jolt's [PhysicsSettings reference](https://jrouwe.github.io/JoltPhysics/struct_physics_settings.html)
describes a motion threshold before CCD casts are used. Inspection of the pinned
`PhysicsSystem.cpp` also shows the cast penetration is capped by the configured
penetration slop. An experimental reduction of the cast threshold from 0.75 to
0.1 improved the small-sphere impact, but caused a 15-degree leaf/slope regression
(117.56 mm vertical penetration). That candidate was rejected and reverted.
**No Jolt solver or grip tuning is included in this correction.** Perfect
sub-millimetre contacts at every impact are not qualified by this delivery.

## Accepted results and delivery

The [machine-readable evidence](COLLISION_BINDINGS_016_EVIDENCE.json) records
source, fixture, native and installer hashes and the retained receipt paths.
Only the final runs listed here establish this delivery's qualification.
Earlier candidate/harness attempts remain in the ignored run folders.

| Evidence | Result |
| --- | --- |
| Native core, continuous brush, grip/terrain, new collision suites | **6,065 checks passed** (3,175 + 413 + 1,898 + 579) |
| Captured replay, 0.1.5 vs 0.1.6 | **384 complete body states match exactly**, including transforms, scale, velocity, spin and sleep; Jolt source logic unchanged |
| New flat-plane matrix | 64 spheres per case; friction 0/0.6 and grip 0/0.8; all sleep within 275–409 steps (2.29–3.41 simulated seconds); settled penetration below 0.001 mm in this fixture |
| Finite edge | Sphere crosses the boundary before falling; no hidden wall; outside brush misses add no bodies/history |
| Installed Max 2027 workflows | **264 checks passed**: 57 continuous + 109 collision/legacy/layout + 98 terrain |
| Actual sphere/plane scene in Max | 64 detailed Sphere32 bodies Finish successfully; full 482-vertex/960-face render models retained; continuous SDK strokes, outside rays, exact live Undo/Redo, cached save/load, result Undo/Redo |
| Proxy admission | Wrong receiver role in both assignment orders, another oversized plane, changed proxy geometry and direct source/proxy API rejected before publication; valid custom proxy retained after failed replacement |
| Earlier saved scenes | 0.1.5 bad binding is named and blocked; Use auto preserves cache until explicit Rebuild; old pending preview survives rejected Resume and can be cancelled to repair bindings |
| Terrain host regression | Slope, hills, ridge, valley, rough terrain, terraces and a holed surface; grip/friction, continuous strokes, Undo/Redo, save/replay and Freeze |
| Layout | **72 native controls each at 100% and 150%**: bounds, font fit and overlap checks pass. New label/field stacking fixes clipped Stickiness caption at narrow widths |
| Diagnostics | Recording, watcher readiness and watcher liveness verified during the owned host test; recovery/save paths exercised. No new intentional-crash campaign was needed for this input/UI correction; 0.1.5 crash receipts remain historical |
| Installer | Archive integrity, all payload hashes, Max 2027 guard, isolated installation, automatic startup and loaded installed native/script identities verified |

Final ordinary build: `build/physics-settling-016-20261018-01/native-01/`.
Installed qualification: `build/physics-lab-016-installer-02/`.
150% layout: `build/physics-lab-016-layout150-02/`.

Package: [CyrusPhysicsLab-0.1.6-Max2027.mzp](../../dist/CyrusPhysicsLab-0.1.6-20261018-01/CyrusPhysicsLab-0.1.6-Max2027.mzp)
(803,796 bytes).

SHA-256: `69aefcbf805a0df5c866bb48012893dbc1aa89430844a8941e578d4a9eec96b7`.

Run it through **Scripting > Run Script**, save work, then restart **Max 2027**.
This task installed/restarted owned disposable test profiles only; the artist
session and existing diagnostic directory were not changed. No main Scatter,
preset, licensing, commit, push or deployment work is part of this correction.

Next artist acceptance: repair the existing sphere's proxy with Use auto and
repeat start, successive strokes, pause/resume and Finish on the original plane.
Physical mouse input, presented FPS and arbitrary geometry are not certified by
the scripted/SDK evidence above. The prior steep rounded-body settling limitation
and the transient-impact overlap limit described above remain explicit.
