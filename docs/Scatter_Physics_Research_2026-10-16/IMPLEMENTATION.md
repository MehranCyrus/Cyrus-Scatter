# Standalone Physics Lab 0.1.0 execution ledger

Historical 0.1.0 delivery record. The corrective successor is documented in
[BRUSH_UI_011.md](BRUSH_UI_011.md); original receipts and hashes below are preserved.

16 October 2026. The independent test node is implemented. It is **not integrated
into CyrusScatter**. The user authorized standalone implementation and scripted
experiments, with **no Computer Use**. Physical mouse/tablet acceptance remains
open. This is an experimental delivery, not completion of the original plan's
production or integration gates.

## Scope and preserved baseline

New product source is in `CyrusPhysicsLab/`. Its independent version is **0.1.0**,
scene schema **1**, solver profile **cpl-leaf-1**. This starts a new experimental
product rather than changing Scatter's release/schema. Registration identities
are document `(0x6de730c1,0x24af591b)` and scripted object
`(0x6de730c2,0x24af591c)`. Artist category: **Geometry > Cyrus Labs > Cyrus Physics
Lab**. The native targets do not link against AminScatter.

Initial branch `codex/workflow-0.75`, HEAD
`9f8cc157279b6e257f1f4a0eb6280fc75b0ea58c`. Extensive tracked/untracked work existed
and continued changing in the main plugin, installer/gallery, tools and website.
This task edited only the standalone project and this research folder. There was
no commit, push, main-plugin integration or artist-profile installation/restart.
Owned disposable profiles were installed/restarted for package testing. Whole-tree
cleanliness is not claimed. Concurrent work subsequently advanced HEAD to
`4eed74777e23c4c1c1a6490c80e2e09ded436d37` through the gallery delivery; this task
did not make those commits. Standalone/research files remain untracked.

Startup workflow, current handoff and foundation were inspected. Knowledge
status/search returned `stale_evidence`, generation
`44bb57523e1286764c655754ce79ed3e4299bce12c0c71b7c49b212258dfa0d3`; direct maintained
source was used, without refreshing the index. The original research and phased
plan remain historical. Their unchecked checklists are not current test receipts.

## What is implemented

| Area | Implemented behavior | Practical boundary |
| --- | --- | --- |
| Physics Brush | Max Painter adapter, canonical BVH cursor ray, distance sampling, release to settle, pending preview and one result Undo | Actual mouse/tablet feel and DPI have not been exercised |
| Physics Area | Seeded bounded sampling, world-XY corner polygon inlet, BVH projection, scheduled births, atomic replacement | One closed Editable Spline loop; no integrated Paint documents |
| Collisions | Jolt CPU, source convex proxies, optional custom proxies, receiver role switch, additional static colliders, CCD and substeps | Rigid assets; general thin/concave contact and dense production piles remain experimental |
| Strokes and edits | Completed strokes frozen for append; explicit all-history replay; frozen erase; Clear; Undo/Redo | Rebuild can change previous placements; erase does not automatically re-settle support |
| Data | Native retained poses/geometry, stable IDs, deterministic emission channels, scene references, independent clone state | Same-build repeats only; no cross-engine/version determinism promise |
| Persistence | Native scene chunk, MAX save/reopen, bounded native JSON snapshot I/O, unfinished-result flag | JSON omits materials and does not infer live bindings; MAX is the complete handoff |
| Output | Combined native mesh with source material IDs, UV1 and smoothing groups | Not Scatter instancing; no extra UV channels, explicit normals or multi/sub source materials |
| Failure handling | Admission, bounded sampling and solve steps, cancel, previous-result retention; explicit Keep only after timeout | Arbitrary low-memory/unwind and device-loss behavior are not qualified |
| Delivery | Separate Max 2027 MZP with hashes, host guard, content-specific install directory and own startup/unregister script | Artist installation is left to the user |

The host owns all SDK access, captures numeric data before solving, and publishes
on the host thread. Single-threaded numerical jobs and bounded tick slices avoid
an asynchronous lifetime layer in this experiment. One dense numerical step or
mesh cook can still delay the host; a fixed slice is not a wall-clock deadline.

Relevant foundation contracts are F01 ownership, F02 conditional randomness,
F03 dependencies, F04 explicit evaluation, F05 atomic publication, F06 bounds,
F07 threads/lifetimes, F08 retained presentation, F09 geometry, F10 units and F11
persistence. These informed the independent design. This lab does not qualify or
close the main plugin's backlog, including B26.

## Engine comparison and provisional decision

Pinned sources are Jolt `1b2e77e3c6c09709e5edc79dc208459b8ff32051` and PhysX
`b97365c6ddb32fda8469bc788ec18024862b0368`. The dependency cache records downloaded
archive SHA-256 values. Builds use MSVC 14.38.33130, Windows SDK 10.0.19041.0, the
Max 2027 SDK and release CRT DLLs. Jolt uses conservative CPU instructions, C++20,
exceptions and single-threaded jobs. PhysX vendor targets retain C++14, CPU-only
static libraries and no CUDA. PhysX is present in the comparison/test executable,
not the Max modules.

The bounded comparison is
`build/physics-lab-comparison-20261016-06/comparison.json`: **80/80** runs passed
its numerical gates (two engines, four scenarios, 1/100 bodies, five repeats).
Each scenario/engine ran in a separate process; the executable was copied before
execution. Inputs use matching metre geometry/births and a 1/120-second emission
clock, four collision substeps, gravity, mass, damping and CCD policy. Internal
engine contact settings are recorded in the adapters; equal labels do not make
algorithms identical.

| 100-body fixture | Jolt median solve ms | PhysX median solve ms | Passes per engine |
| --- | ---: | ---: | ---: |
| Flat | 30.54 | 26.37 | 5/5 |
| Pile | 1567.77 | 165.59 | 5/5 |
| Curb | 32.32 | 26.80 | 5/5 |
| Fast drop | 33.82 | 38.94 | 5/5 |

Gates require completion, rendered-box floor penetration below 0.5 mm and OBB
pair penetration below 1 mm. All cohort transform fingerprints repeat within the
same executable/process environment. Peak process working set includes runtime
and preceding smaller tiers. These are local exploratory timings collected with
competing Max startup/build work, not controlled production benchmarks or FPS.
Cohort 05 also passed 80/80 under the same numerical configuration; cohort 06 uses
the exact frozen delivery comparison executable. The curb
case has an obstacle, but its oracle checks floor and body pairs, not exhaustive
curb penetration. The suite does not cover the entire E01-E10 matrix.

**Jolt remains the provisional lab engine**, because its thin-leaf configuration
has been exercised end to end in Max and its independent host adapter is working.
It is not declared a universal winner: PhysX was substantially faster in the
100-body cuboid pile. A future production decision needs matched curved-leaf,
general-collider and dense-scene comparisons. No second solver is shipped in Max
to postpone that decision.

Earlier cohorts remain under `build/physics-lab-comparison-20261016-01..04`.
Cohorts 02 and 03 completed 120 experiments each with Jolt 45/60 and PhysX 15/60
passes under earlier contact/substep configurations. Cohorts 01 and 04 include
process timeouts and incomplete files. Their speed and repeatability summaries
must not rank failed cases; a missing fingerprint is unassessed. The final runner
explicitly records timeout/nonexecution. No final 1,000-body dense qualification
is claimed.

## Geometry and settling decisions learned from failures

Curved near-zero-volume open hulls and ordinary triangle slab contact initially
allowed leaves to fall through the street. Automatic open proxies now project the
convex silhouette along the thinnest AABB axis and cap the original thickness
envelope. The visible render mesh retains its original curvature. Closed volumes
preserve their hull. Explicit silhouette proxies are required for alpha cards;
texture opacity never creates collision holes.

Only a verified eight-corner, twelve-triangle, closed, outward-facing axis-aligned
box is cooked as a solid box collider. Edge counts, plane membership and face area
are checked; missing faces and inward room shells are rejected by classification.
Other colliders use triangle meshes. This does not silently fill arbitrary holes.

Jolt uses thin-contact margins, eight position/sixteen velocity iterations, tight
contact-cache tolerances and four substeps. New host births conservatively rise
above XY-overlapping dynamic/frozen proxy bounds, with a five-metre lift rejection
budget. This addresses the rare interpenetrating spawn seen in a later ordinary
leaf demo. Actual adjusted births are recorded; replay consumes recorded births.

Completion requires sleeping bodies or linear/angular motion below 0.002 m/s and
0.05 rad/s for 60 fixed steps. Reaching the finite step limit is a timeout, not
success. The previous complete result stays authoritative. Only the explicit
**Keep Current (unsettled)** action accepts that preview and persists
`settled=false`. Other failures cancel and preserve the result.

Absolute admission bounds: 5,000 bodies, 64 sources, 64 explicit colliders (the
receiver can consume a collision slot), 128 pre-thickening proxy input points,
200,000 combined source vertices/faces, 200,000 collider triangles and 2,000,000
output vertices/faces. Pairs/contacts are capped independently at 65,536; scratch
policy is 128 MiB; a tick accepts 1-120 outer steps; sample segments cap at 256
births; Area attempts cap at 64 per requested body. These are rejection boundaries,
not supported-capacity or latency promises.

The original Jolt sample allocator aborted the process on exhaustion. The lab
owns scratch allocations instead. A deliberately oversized million-contact test
then demonstrated unsafe unwinding/stalling inside Jolt jobs. Such pair/contact
budgets are now rejected before solver initialization, and the numerical test
verifies that preflight rejection. This does **not** establish safe arbitrary
allocation failure inside an admitted solve. That limitation remains explicit.
CTest has a 30-second numerical-test watchdog; host runners stop only their owned
process handles on timeout.

## Verification receipts

Frozen ordinary delivery: `build/physics-lab-010-delivery-20261016-05/receipt.json`.
The working build directory `build/physics-lab-010-20261016-core01` was subsequently
used for a private fault build and returned to ordinary configuration; its later
link timestamps are not the delivered pair.
It records all standalone source hashes, shared SDK/helper/header hashes,
dependency pins/archive receipts, toolchain, fault flag and binary hashes.
The directory was reused for expensive vendor builds; prior attempt logs are
retained. The final ordinary build/configure/CTest pass follows all source changes.

- Numeric CTest: **2,426 contract assertions**, covering BVH versus exhaustive ray
  oracle, codecs, emission IDs/gaps, both engines' simple contacts, cancel/body cap,
  timeout, low-contact exhaustion, oversized preflight rejection, solid-box
  classification and curved leaf floor contact.
- Ordinary host 18: **18 assertions**, Painter start and scripted samples/release,
  cancellation, Clear/Undo/Redo, retained geometry, UV1/smoothing, independent clone
  without duplicating scene inputs, native save/reopen and snapshot roundtrip.
- Ordinary host 21: **21 assertions**, 100-body Area, unchanged idle counters/poses,
  append preserving prior transforms, replay, erase/Undo, body admission, underfill,
  changed-source rejection and deleting an owner during a pending solve.
- Ordinary host 19: centimetre scene, rotated/nonuniform/offset source, mirrored
  receiver, transformed corner polygon, 12 rows/96 vertices, save/reopen and
  self-binding rejection.
- Ordinary host 20: **60 curved leaves automatically settled**, three source
  materials, Scanline render, native JSON and MAX scene. An independent rendered
  vertex oracle found minimum street height **0.7158 mm** and no vertex below the
  analytic ground. This is not a general pair/curb penetration proof.
- Private host 26: the current source with private injection enabled passed
  pre-commit and post-assignment exceptions, prior-result retention, timeout,
  explicit Keep and unfinished-file roundtrip. Its private receipt is frozen at
  `build/physics-lab-010-private-20261016-26/receipt.json`. Package tooling rejected
  this private build before creating an output directory. Host 11 is earlier
  supporting evidence. No private fault commands are in the shipped pair.
- Ordinary package host 25 installed the final MZP payload into its owned profile
  with SHA verification. Its `restart06-receipt.json` confirms both modules loaded
  from that installed content directory, and automatic startup registered the
  matching script. The installed-pair rerun repeated all four ordinary fixtures:
  18 basic assertions, 21 extended assertions, transformed units/mask, and the
  automatically settled 60-leaf demo. No manual class fileIn was used at restart;
  the custom plug-in INI carried the directory written by the installer.
- Ordinary host 27 reopened that final MAX scene with the frozen delivery pair
  and rendered a JPEG without replay. The JPEG was visually inspected. The PNG
  is valid 16-bit RGBA; JPEG provides a convenient preview for image viewers.

Host profiles are `build/physics-lab-host-20261016-<number>/`, with launch identities,
loaded module paths, fixture hashes, assertions and errors. Earlier failed runs
remain there. Hosts 18-21 share the tested numerical/native implementation before
a native rebuild adding the SDK MAXScript LibInit entry point and a comment correction; exact hashes and qualifications are
retained separately. The final installed-pair rerun is the delivery witness. The numerical comparison
executable and package/native/script hashes are in IMPLEMENTATION_EVIDENCE.json.
No physical brush, viewport FPS, tablet or UI/DPI measurement is claimed. All host
work was hidden CLI/MAXScript on **Max 2027 only**, with no Computer Use.

## Failure history and package checks

Initial compiler experiments fixed PhysX vendor C++14 requirements, static-link
defines and the revision's cooking-library layout. An early mixed-startup/third-party
profile timed out before bootstrap and was stopped by its owned watchdog. The
final isolated fixtures use standard Max plug-ins plus the lab pair. Arbitrary
third-party coexistence remains artist acceptance.

Area initially underfilled a small mask by sampling the whole receiver. Polygon
bounding-box sampling plus down-ray BVH projection corrected that. Rectangle
tests first needed conversion to Editable Spline and then corner knots; unsupported
Bezier outlines continue to reject. Pending authored settings were split from
committed solve settings so saving a prior result does not relabel it with controls
that have not produced it. A test-run/build-log overlap exposed a locked log;
subsequent builds and dependent operations were serialized.

Installer tests caught a fixture's missing global forward declaration, then a
restart-harness weakness: a custom `-p` configuration omitted the installed
native user-INI entry while still running startup scripts. Attempts with that
configuration failed or timed out; the profiles/logs are preserved. Explicit
startup loading was explored and removed. The final test configuration carries
the actual directory written by the installer into its isolated `-p` file. The
native extension now exports the SDK LibInit entry point. Final startup requires
both expected loaded native hashes/paths before loading the matching hashed
script; it refuses absent/mismatched modules instead of publishing a half-working
class. Installation stages files and asks for restart. The content directory ID
includes the complete standalone source identity and native pair.
Autodesk documents [plug-in search locations](https://help.autodesk.com/cloudhelp/2023/ENU/Max-Developer-Help/3ds_max_sdk_features/miscellaneous_topics/plugin.ini.html).
The installed-pair restart witness is required in addition to documentation.

Packages 01-04 are superseded preflight artifacts, not user deliveries. The
final [MZP](../../dist/CyrusPhysicsLab-0.1.0-20261016-05/CyrusPhysicsLab-0.1.0-Max2027.mzp)
is 645,573 bytes, SHA-256
`1f59e7b417c3fa81882edc8040163508386b4456f3bb7736e89fae6436631d38`.
Package identities and the startup restart receipt are listed in the machine ledger. ZIP integrity and all manifest payload hashes are checked. Max 2027 guards,
exact ordinary pair, no private injection commands and installed loaded paths must
match. Unregister preserves files/scenes and only removes this lab's matching
registration/startup. The artist's Max session has not been restarted.

## Test delivery and next acceptance

Read [the artist/test guide](../../CyrusPhysicsLab/README.md). Run the final MZP
through **Scripting > Run Script**, save work and restart **Max 2027**. Create
**Geometry > Cyrus Labs > Cyrus Physics Lab**, or open the supplied 60-leaf MAX
scene and select `Standalone_Physics_Leaves`. Start with a solid street slab,
small counts and an explicit silhouette proxy for textured leaves.

The demo scene, render, JSON snapshot and exact final package paths are recorded
in [IMPLEMENTATION_EVIDENCE.json](IMPLEMENTATION_EVIDENCE.json). Binaries, installers,
scenes and SDK caches are ignored by Git and need separate backup.

Before integration: obtain artist brush feel/DPI/Undo acceptance; test realistic
source assets, alpha silhouettes, concave streets/holes/slopes and dense piles;
measure controlled latency/memory and long-session behavior; examine allocation
failure, animated/instanced inputs and additional renderers/materials; revisit the
engine decision with matched thin-leaf quality. Bindings/settings UX and JSON
validation should receive further hardening before production. Wind, cloth,
deforming colliders, two-way scene dynamics, local support re-settling, GPU work
and main-plugin integration are not implemented in this standalone delivery.
