# Physics Lab 0.1.5: surface grip and terrain qualification

18 October 2026. Authorized: add stickiness for **surface grip on slopes**,
research Houdini's relevant controls, test the standalone lab broadly and on
varied mountain terrain. The user explicitly selected surface grip rather than
wall adhesion. Max 2027 only; no Computer Use, preset work, main Scatter
integration or artist installation.

## Design and version decision before implementation

Independent lab 0.1.4 → **0.1.5**, next development delivery. Add a dimensionless
`stickiness` setting (native 0–1, artist 0–100%, default 0). Friction remains the
existing 0–2 coefficient. Stickiness adds contact friction and bounded rolling
resistance on upward supporting contacts with static geometry, including fixed
completed bodies. It must not damp airborne bodies, weld dynamic bodies together,
pin transforms or attach to vertical walls. Zero must preserve the previous
solver path. The amount controls resistance, not a promise to hold any slope.

Host captures settings and meshes; the native worker owns solver/contact data.
No Max access or physics mutation from contact callbacks. Preallocated bounded
support records are consumed after the solver update. Checkpoint/recovery must
reproduce the same state without introducing a persistent hidden contact cache.
Pending sessions lock this setting. Publication, coupled Undo and crash logging
remain. Input encoding advances to distinguish the new setting; older completed
caches read with zero grip. Old pending solver fingerprints cannot Resume in the
new solver but retain the existing cached-preview Freeze path.

The performance envelope includes at most one support record per admitted body,
no per-contact unbounded history and no allocation in callbacks. Source capture,
render output, history and queue budgets remain independent. Failed admission or
publication retains the previous result. Numerical tuning will be recorded with
its measured outcome before qualification.

## Primary research checked 18 October 2026

- SideFX [RBD Bullet Solver](https://www.sidefx.com/docs/houdini/nodes/sop/rbdbulletsolver.html)
  describes contact friction, a separate dynamic-friction scale and heightfield
  collision. This supports distinguishing contact resistance from general drag.
- SideFX [RBD Configure](https://www.sidefx.com/docs/houdini/nodes/sop/rbdconfigure.html)
  separates friction from rotational stiffness (inertia scaling) and explicit
  pinning. We do not label inertia changes as friction.
- SideFX [Sticky collisions](https://www.sidefx.com/docs/houdini/destruction/sticky.html)
  creates contact-triggered constraints. That is adhesion, which the user did not
  choose; we are implementing surface resistance, not that constraint workflow.
- Jolt [ContactListener](https://jrouwe.github.io/JoltPhysicsDocs/5.6.0/class_contact_listener.html)
  and the pinned `ContactListener.h` permit contact-setting changes but forbid
  physics-state mutation/locking body API use in callbacks. The installed pinned
  header, rather than the online version alone, determines the implementation.

These references inform our design. Houdini was not run, its solver was not
reconstructed and equivalence with Houdini is not claimed.

## Acceptance matrix

- [x] Default-zero regression and settings/JSON validation; no silent PhysX use of a Jolt-only grip feature.
- [x] Slope angle/friction/grip matrix, blocks, rounded bodies and curved leaf proxies; useful resistance, bounded measured penetration and velocity-reducing grip operations. Steep rounded-body settlement remains limited as recorded below.
- [x] Smooth hills, sharp ridges, valleys, stepped/rough mountain terrain and holes/edges; actual finite collision geometry.
- [x] Unchanged flight, vertical-wall contact, upward separation and dynamic-only contact in the exact-state fixtures; supported bodies can be pushed away again.
- [x] Coupled live Undo/Redo, deterministic replay, save/reopen, old cached result and old pending Freeze behavior.
- [x] Actual button/Painter SDK continuous brushing, outside/re-entry, pause/resume, Finish/Freeze, Max Undo and lifecycle.
- [x] Unit/transform handling, new control bounds/font metrics, Area/Rebuild and source/proxy regression. No visual or physical-input qualification.
- [x] Private failure retention, crash recovery and representative performance checks.
- [x] Exact qualified ordinary pair, MZP integrity and isolated installed/restarted workflow.

## Baseline and evidence

Source snapshot and dirty inventory:
`build/physics-grip-015-20261018-01/`. Starting HEAD
`c2a301af2e74a8af33702e46669c4d0357faf75d`. Existing 0.1.4 code was already
untracked/modified from the earlier authorized work; preserve it and its exact
qualified package. Knowledge verification is stale (29/36 enrolled parents);
the lab is unenrolled, so direct source and new receipts are required.

## Using the control

Create the independent lab through **Geometry > Cyrus Labs > Cyrus Physics Lab**.
Choose a receiver and source models, then open **Collision and proxies**. Keep
**Friction** at 0.6 for an initial comparison and vary **Stickiness (%)** between
0, 50, 80 and 100. Use the same source geometry and slope when comparing results.
Zero runs the previous collision path. Higher values increase resistance to
sliding and rolling; they do not specify an angle that every asset must hold.

The setting applies to the next simulation capture. Finish, Freeze or cancel a
pending session before editing it. Existing completed bodies stay in place;
**Rebuild all strokes** is the explicit way to resimulate recorded work with
current settings. A MAX scene saves the editable value. Result JSON preserves the
value used by its solve, while retaining the importing object's editable controls.

Continuous brushing remains available while earlier objects are moving. Outside
the receiving surface, emission stops and the path breaks. Re-entering begins a
new segment. Finite terrain and holes remain finite: grip creates no hidden floor.

**Known limit:** a rounded convex source on the tested 75° slope retained slight
rotation and reached the Finish budget. The preview remained available and Freeze
worked. The block finished on slopes through 75°; the rounded source finished
through 60°. Use Freeze to accept a composition that has not met the quiet-motion
criterion. This is an experimental rigid-body placement tool, not wall adhesion.

## Implemented native behavior

Let `s` be Stickiness divided by 100. The contact listener admits only dynamic
bodies touching static geometry, with a support normal whose vertical component
is greater than 0.05. Completed/frozen lab bodies qualify as static support;
contacts between live dynamic bodies keep ordinary friction. The contact must be
within the configured speculative envelope, `min(0.002 m, proxy thickness)`.

The listener adds `4s` to the solver's combined friction. It records one support
normal per body, choosing the most upward normal with a deterministic tie-break.
It neither allocates nor calls the locking body API. After the solver update,
the worker reduces tangential speed by at most `4s × gravity × normal.z × dt`.
Angular speed is reduced by at most that amount divided by the scaled source
bounding radius, with a 1 mm lower radius bound. Neither reduction reverses its
velocity component. This is calibrated artistic rolling resistance, not a
measured material coefficient or an inertia change.

For a supported body, contact-normal chatter with magnitude at most 0.02 m/s is
reduced by the factor `s`. An outward velocity greater than 0.02 m/s skips the
extra velocity adjustments, allowing meaningful bounce and departure. The
algorithm introduces no attractive force and changes no transforms. Its explicit
braking operations only remove velocity magnitude; this is not a claim of a
general energy-conservation proof for the underlying collision solver.

All grip work remains in C++. The rollout and `cplSetGrip` are bounded authored
commands. The setter validates a staged settings copy and rejects mutation while
work is pending. Native values must be finite and inside [0,1]. PhysX comparison
worlds explicitly reject nonzero grip rather than silently ignoring it.

At the maximum admission, the support array holds 5,128 records (approximately
160 KiB in this build); it is allocated once per enabled world. Each update clears
this bounded array and visits existing dynamic bodies. Zero grip installs no
listener or support array and skips the extra pass. Body/source/output/history
and diagnostic limits are otherwise unchanged.

Support data is transient and regenerated after each step. In-memory checkpoints
retain the existing complete Jolt state. Durable recovery stores canonical births
and the captured setting, and still verifies the exact solver fingerprint. Input
encoding advances from 1 to 2; scene schema remains 2. Version-1 input and its
authored settings default to zero grip. A regression test exposed an older-scene
load failure when the unversioned authored settings were incorrectly read as new
settings; Load now uses the saved input version for that migration.

## Numerical qualification

The ordinary candidate passes **3,175 core + 413 continuous + 1,898 grip/terrain
checks = 5,486 native checks**. This includes malformed settings, input migration,
PhysX rejection, deterministic recovery and full-state Undo/Redo. Forty matched
zero-grip runs against the exact 0.1.4 executable have identical final pose hashes,
settling-step counts and collision-quality results: five repeats of one and 100
bodies in flat, pile, curb and fast-impact cases. All forty quality cases pass.

The 192-case slope matrix uses two source shapes, angles 0/15/30/45/60/75°,
friction 0/0.2/0.6/2 and grip 0/25/50/100%. It checks finite motion and rendered
vertex penetration. Peak vertical penetration across that matrix is **2.278 mm**,
below its 5 mm vertical gate. This measurement is vertical distance, not distance
normal to a steep plane.

Selected results at friction 0.6, after 480 fixed steps (four simulated seconds):

| Source | Slope | Drift, grip 0 | Drift, grip 100 |
| --- | ---: | ---: | ---: |
| Thin block | 45° | 16.779 m | 0.00108 m |
| Thin block | 60° | 29.773 m | 0.00177 m |
| Rounded convex source | 45° | 18.379 m | 0.11228 m |
| Rounded convex source | 60° | 30.031 m | 0.16895 m |

Drift is horizontal travel divided by the slope cosine. The unassisted bodies
leave the finite test plane and continue falling; these large numbers are not
four seconds of uninterrupted surface sliding. Shape, drop position and contact
settlement all affect the result. The comparison establishes useful resistance
in these fixtures, not a universal calibrated friction curve.

Six finite triangulated terrain families exercise smooth hills, sharp ridges,
valleys, rough mountain faces, terraces and a central hole. They use 10–12 births
each, with repeated live gestures, exact recovery, Undo/Redo and continued replay.
No admitted body was lost in those supported placements. Maximum final vertical
penetration is **0.237 mm**, below the 1 mm terrain gate. Outside-only gestures
create no bodies. Separate exact-state comparisons verify unchanged flight,
dynamic-only contact, vertical-wall contact and upward departure. An impact test
also verifies that supported bodies remain movable.

## Rejected tuning and test corrections

The first rounded-source fixture had duplicated poles and incorrect mesh closure;
it was corrected to an outward-wound closed convex source. An overly narrow
support-depth test lost contacts inside Jolt's actual speculative envelope; it
now uses that same bounded envelope. Tiny contact-normal jitter prevented several
Finish cases; the bounded chatter absorption described above resolves the tested
15–60° rounded cases.

Stronger angular braking, inertia-derived torque and separately updated substeps
were tried and **rejected** after the slope matrix exposed severe mesh-contact
penetration. They are absent from the delivered algorithm. Retained iteration
reports include `grip-iteration-06-failed.json`, `-07.json`, `-08.json` and `-09.json`
under the run directory. Their underlying collision instability is not claimed
to be solved for arbitrary configurations. The earlier qualified grip formula
was restored; its final full matrix and explicit steep-slope timeout/Freeze gate
are the delivery evidence.

A lifecycle test initially edited the original source after merging a cloned
scene. The lab correctly referenced the merged source. The fixture now edits
`lab.sourceNodes[1]` and verifies invalidation of the actual bound model.

## Max 2027 and recovery qualification

All hosts used disposable hidden profiles and scripted/native SDK operations.
No Computer Use, physical mouse input or artist-session installation was used.
The normal profile was checked for byte preservation. The exact native modules
and script were recorded for every run.

| Witness under `build/` | Result |
| --- | --- |
| `physics-lab-015-grip-host-02` | 98 actual rollout/Painter SDK checks over slope, hills, ridge, valley, rough terrain, terraces and hole; continuous strokes, outside/re-entry, live Undo/Redo, pending save/reopen/replay, Freeze and Max Undo/Redo |
| `physics-lab-015-secondary-host-02` | Native control bounds, overlap and font metrics at 150% scale; repeated lifecycle, global Undo, clone/merge, owner deletion/reset, frame/unit/source invalidation, transformed Area, two-session Rebuild and unchanged cached 0.1.0/0.1.1 scenes |
| `physics-lab-015-lifecycle-host-02` | Grip locked during pending work, centimetre units, rotated/translated slope, independent cloned pending state, Finish, result JSON, merged bindings, Area/Rebuild Undo and source-change rejection with cached Freeze |
| `physics-lab-015-fault-host-01` | Private build: both publication failure points retain the prior result and preview, explicit retry/Undo works, timeout retains preview and Freeze records an unsettled result |
| `physics-lab-015-recovery-host-01` | Both new crash recordings replay, restore stroke Undo/Redo and Freeze; wrong solver fingerprints reject replay but permit cached Freeze; genuine 0.1.4 recording also retains cached Freeze with grip defaulted to zero |
| `physics-lab-015-installer-02` | Final MZP installed only into an owned profile, followed by automatic startup/restart; all 57 continuous checks and the 98 grip/terrain checks pass on the installed payload |

An additional native curved-leaf witness uses the same compiled core on six
terrain families at 25%, 80% and 100% grip: **18 cases and 948 checks pass**.
It verifies supported counts, penetration, proximity to support, exact recovery,
Undo/Redo and Freeze. The largest nearest-render-vertex gap is 2.942 mm; the
automatic open-leaf proxy is a conservative thickness envelope. Combined with
the main suites, this is **6,434 native
assertions**. Counts are fixture assertions, not exhaustive scene coverage.

The deliberately triggered access violation in `physics-lab-015-fatal-01`
recorded the fault, a complete **10,913,901-byte** first dump, its success receipt
and durable live recovery with 80% grip. A later dump attempt failed; its error
receipt remains and the first complete dump is preserved. The harness then
terminated only its owned process. In `physics-lab-015-hardkill-01`, immediate
exit 77 preserved events and recovery but produced no exception dump, as expected
for that termination path. These are intentional diagnostic probes, not observed
spontaneous plugin crashes. Keep full recording folders, including per-dump
receipts; the latest dump-attempt status alone is insufficient.

## Performance scope

The scripted Max witness used 1,000 pending low-poly boxes, 80% grip and twenty
further SDK strokes. Sample-to-snapshot plus redraw-call latency was **81 ms
median, 118 ms p95 and 118 ms maximum**; cancellation took **28 ms**. This includes
the scripted synchronization boundary. It is not physical input latency or
presented viewport FPS. The whole Max process peaked near 2.18 GB working set;
that includes Max and its loaded environment, not just the physics world.

The separate native capacity runs each advance 360 fixed steps, archive, Undo and
Redo. Both sizes finish the measured interval with zero moving or lost bodies.

| Bodies | Grip | Median step | p95 step | Sampled peak private memory |
| ---: | ---: | ---: | ---: | ---: |
| 1,000 | 0% | 4.73 ms | 6.29 ms | 33.34 MB |
| 1,000 | 80% | 3.21 ms | 8.07 ms | 33.19 MB |
| 5,000 | 0% | 27.89 ms | 37.21 ms | 50.02 MB |
| 5,000 | 80% | 17.70 ms | 38.92 ms | 50.05 MB |

Grip changes motion and time spent active, so this is not an isolated per-contact
overhead benchmark. These are single local capacity witnesses with simple boxes,
not a guarantee of real-time 5,000-body production brushing. The body defaults and
absolute admission bounds remain 1,000 and 5,000 respectively.

## Delivered pair and installation

[CyrusPhysicsLab-0.1.5-Max2027.mzp](../../dist/CyrusPhysicsLab-0.1.5-20261018-02/CyrusPhysicsLab-0.1.5-Max2027.mzp)

- SHA-256: `331efe2f34382ecb47cd3e967d0683d0bf96b374cab5043cec9d800bd3d4e5c9`
- Package size: 800,866 bytes; archive CRC, all payload hashes, Max 2027 guard,
  version identities and installed native/script identities verified.
- Ordinary binaries and matching symbols:
  `build/physics-grip-015-20261018-01/qualified-docs/`.
- `core-01/` now contains the **private fault build**. Do not deliver it. Its
  compiled-source hashes match the ordinary candidate; packaging rejects its fault flag.
- Structured results and hashes: [SURFACE_GRIP_015_EVIDENCE.json](SURFACE_GRIP_015_EVIDENCE.json).

Package `-02` corrects mixed Windows/UTF-8 punctuation in README.md found during
the documentation-link audit. `qualified-docs/receipt.json` records this explicit
documentation-only successor to `qualified/`: every compiled source, native
binary and script hash is unchanged, with no recompilation claimed. Package
`-01` is superseded. The final archive passed its fresh isolated installation test.

Run the MZP using **Scripting > Run Script**, save work, then restart **Max 2027**.
Create **Geometry > Cyrus Labs > Cyrus Physics Lab** and use **Collision and
proxies > Stickiness (%)**. The artist's running Max was not installed into,
restarted or closed by this task. The installer is independent of CyrusScatter.

Real mouse/tablet feel, visual appearance on the artist's display, representative
production mountains, dense mixed assets and renderer combinations remain artist
acceptance. No main Scatter integration, preset work, commit, push or website
publication is part of this delivery. Keep the ignored build/package artifacts
with test scenes; the versioned source documents do not replace binary backups.
