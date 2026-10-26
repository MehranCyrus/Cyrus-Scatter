# 0.87.0 execution ledger

Work in progress. No user delivery accepted yet. Original scene SHA-256: `69ff41356a5312dba7841bc47bbe49b6ce77a8ca79168fd045c8c17c618a8378`.

## Preserved baseline

`build/interactions087-inputs-20261025-01/` contains an owned scene copy, original scene hash, 341 source hashes and the pre-existing tracked diff/untracked inventory. The original `Test Scene/Terraces_Final.max` is never saved. Existing source edits are preserved.

## Findings, fixes and exact runs

| Stage / issue | Observation and action | Evidence / status |
|---|---|---|
| Raw scene inventory | 315 nodes, empty schema-59 Scatter owner, existing planting receivers and hidden library sources. Minimal profile lacked Corona classes | `interactions087-inventory-host-20261025-01`, successful read-only Max 2027 run |
| Dependency-aware inventory | Installed `CoronaMax2027.dlr` / utils restored renderer/material classes and proxy geometry. Geometry sum became 3,160,386 triangles. This attempt additionally loaded the old Lab binaries and exited nonzero after inventory; it is not accepted host qualification | `interactions087-inventory-host-20261025-02`; raw inventory retained, successor excludes unneeded Lab modules |
| Runner preflight | MAXScript `python.ExecuteFile` returns `#success`, not a boolean. Corrected the new owned runner to verify the emitted identity receipt instead of applying `not` to that symbol | Failed run `...-03`; successor `...-04` |
| Source reuse boundary | Compile existing native preparation/math with a preparation-only guard; reuse the independent fitter source. No second Jolt lifecycle or old Lab geometry class is embedded | New native rig target in `AminScatter/CMakeLists.txt`; standalone Lab's default compile path retains its solver |
| Mesh collision | Added double-precision BVH queries for explicitly admitted welded closed triangle meshes, whole-segment capsule witnesses and point occupancy. Rejected open/nonmanifold, singular, mirrored and nonuniform cases | Native test iterations 03–05; these are new Cyrus adapter tests, not original A/Jolt qualification |
| Grass topology | Actual A069/A068 are folded three-vertex sections, sometimes with a terminal tip, rather than round tubes. Added an explicit ordered-blade profile with connectivity and basal validation | Actual sources prepare: 467 and 514 rooted groups; saved-definition/hash rejection controls pass |
| Bushy grass roots | Bases span 13.9 mm vertically in the original tuft. A fixed 3 mm plane rejected valid bases. Preserve original root positions inside a bounded source-height basal band (25%, capped at 25 mm), require review | Initial actual-asset rejection retained in iteration 02; iteration 03 admits the measured tuft |
| Root cross section | Flexible root direction rotated delivered basal-ring vertices despite a fixed guide root. Added explicit source anchor flags and preserve the original basal vertices during geometry evaluation | Iteration 04 failed the anchor assertion; iteration 05 passes |
| Stable spatial updates | Old/new obstacle bounds restore leaving plants; an edited plant outside the original BVH is also included through bounded edit overlays. Exact unchanged input returns the same immutable snapshot | 5,000-instance numerical kernel test in iteration 05 passes |

## Current bounded measurements

MSVC 19.38, C++20 Release in a Max 2027 SDK-configured build, `build/interactions087-native-20261025-01/`. Candidate iterations are not frozen release producers.

- Actual source preparation/cache realization, one sampled run: small grass 11.1 ms / approximately 0.96 MB charged source payload; bushy grass 16.0 ms / 1.50 MB; lavender 262 ms / 35.9 MB; geranium 5.23 ms / 1.03 MB. These figures exclude allocator overhead, shared control blocks, host templates, draw/render/history and total peak memory.
- 5,000-instance kernel fixture: 1 nearby plant, 1 fitted guide, 33 iterations, 207 queries, approximately 0.72 ms evaluation; approximately 2.54 ms initial index build. Index payload 982,128 bytes; layout payload 593,015 bytes; sparse pose payload 540 bytes. Single synthetic numerical sample, **not Max presented FPS or terrace performance**.
- Saved definition round trips and geometry-hash rejection pass for both grasses, lavender and geranium. Rest reconstruction, mesh witness/material-coordinate reconstruction, single clearance, transform rejection, cancellation/query exhaustion, partial root masks, move-away restoration and immutable failure retention are covered.

## Remaining work at the initial kernel checkpoint (historical)

Connect the numerical kernel to native Scatter source capture, persistent reviewed definitions, post-Edit placements, retained preview and full-quality output. Add the layer UI/settings, scale on the actual terraces and qualify held drag, publication failures, Undo/save/reopen and renderer/Bake parity. Heavy scene measurements and a runnable matched Max 2027 MZP remain required before delivery. The single synthetic timing is not a claim of completed integration or maximum performance.

## Native adapter and first Max fixtures (in progress)

- SDK adapter builds 03, 04, 06, 07 and 08 completed with MSVC/Max 2027 SDK. Builds 01/02/05 failed on JSON/MAXScript macro ordering, a noncopyable SDK vertex buffer iterator, and an unavailable primitive ID respectively; those failures are retained. These are incremental development builds, not release producer receipts.
- Added native source capture, frozen source-cohort admission, root-owned numeric state, post-Edit patches, shared source-face preview aliases, spatially batched posed preview and a private full-render source output class. Added an append-only schema 60 Interactions panel and reviewed source definitions. Existing schema 59 scenes load with interactions off. No Jolt runtime or old laboratory class registration is added to Scatter.
- `interactions087-smoke-host-20261025-01`: actual grass fixture stopped on a fixed-root envelope conflict. Root occupancy now uses the same basal envelope as the fitter. The original basal vertices remain anchored.
- `interactions087-smoke-host-20261025-02`: 80 actual grass instances, one sphere, five broad-phase candidates, one posed plant/eight fitted guides. Initial numeric contact fit 13.62 ms; native light preview preparation 0.0486 ms. Fixture then failed because its Edit inspection did not activate the intended layers. It is not a full accepted host pass.
- `interactions087-smoke-host-20261025-03`: native Cyrus Edit moves the individual obstacle and restores departing poses. That sampled kernel successor took 0.0078 ms, with no index rebuild. Fixture then exposed an Undo lifetime issue in the transient state holder; a correction retains the wrapper and explicitly verifies controller ownership before reuse. Undo remains pending qualification.
- `interactions087-smoke-host-20261025-04`: another UUID-derived placement arrangement hit the fitter's iteration budget. A separately counted, bounded basal-hinge search is being added as a fallback; candidates must preserve root/length/frame identity and independently pass refreshed whole-segment mesh contact queries. No unchecked pose is accepted. Failure still retains the complete preceding result.
- Posed light preview is being changed to complete original stem faces and selected whole foliage parts. This preserves source face/corner identity for texture and opacity UVs. Atlas pixels are shared; posed UV streams are separate and budgeted. Build 09 compiled, but this path has not yet passed host/material qualification.

All host paths above are under `build/`. Artist INI hashes were unchanged. The supplied `Test Scene/Terraces_Final.max` remains untouched. Timings are scoped CPU observations; no presented FPS claim is made.

### Max 2027 small fixture and real terraces

- `interactions087-smoke-host-20261025-12` **passed, process exit 0**: source analysis/review, retained Mesh, individual native Cyrus Edit move, actual native Undo restore and pending Manual count/seed isolation. One sampled Undo successor fit: 8.4662 ms, 12 broad-phase candidates, one posed plant, 12 fitted guides, no index rebuild. This incremental candidate is not the final delivery identity.
- Earlier Python Undo attempts incorrectly grouped fixture creation or suppressed native restore recording. Run 08 showed the controller itself was undone; run 09 preserved it but created no native restore. The accepted test separates Python setup from direct MAXScript Undo commands and asserts native restore counters. The transient state clone behavior remains owner-isolated (`deep_copy` returns undefined); the speculative wrapper-retention change was reverted.
- Loading the Corona-enabled owned scene succeeded but previous process teardown exited -1. Releasing the owned scene with an explicit reset before quitting gives exit 0 in terrace runs 01–03. The cleanup is recorded in runner arguments; it does not alter saved input/output scenes or artist profiles.
- The supplied `Rock_10.max` is one combined mesh containing 13 connected rock pieces. Its 83-vertex component has two triangular openings (six boundary edges); the other 12 are closed. The fixture detaches the largest-volume closed component (60 vertices / 116 faces), preserves map channels, explicitly normalizes it to 1.2 m maximum extent, and leaves the original file untouched. Details: `interactions087-terraces-host-20261025-02/collider-selection.json`.
- Solid-point-only root exclusion incorrectly attempted to bend roots under rock overhangs. Added upward coverage queries in the plant-local representation of world up. Covered root groups are removed before fitting. The root-coverage toggle belongs to the reacting layer; collider admission remains independent of placement spacing scopes.

Terrace run 03 **completed, process exit 0**, using the actual scene and both grasses, lavender, geranium, supplied closed boulder instances and a rigid tree layer. New models use standard diagnostic materials; this is CPU stage evidence, not render/material or presented-FPS qualification. These exploratory samples were collected during development; a later frozen producer must repeat the accepted scope.

| Stage | Reacting placements | Nearby candidates | Posed plants / fully covered instances | Hidden rooted groups | Fit ms | Whole Update seconds | Private process GiB |
|---|---:|---:|---:|---:|---:|---:|---:|
| Dense foreground | 1,116 | 347 | 47 / 47 | 29,258 | 3,833.43 | 4.992 | 7.392 |
| Full terraces | 11,300 | 3 | 2 / — | 1,274 | 5.95 | 1.634 | 7.457 |
| Full terraces | 56,500 | 10 | 3 / — | 2,076 | 45.70 | 1.736 | 7.556 |
| Full terraces | 281,000 | 54 | 7 / — | 3,811 | 432.32 | 3.164 | 7.739 |

The dense foreground is **not acceptable for live dragging**. It emitted 629,436 coverage/contact queries. Next optimization: certify complete basal-tuftenclosure with an interior ball above it, avoid per-blade work for fully covered instances, retain compact all-covered poses and reuse identical contact preview buffers during browsing. This is an exact conservative shortcut on admitted closed solids, not an approximate box/hull replacement. Its successor timings and actual held-drag behavior remain pending.

### Fixed-layout replay and successor development builds 23–35

Run 04 also completed and saved its foreground before the large tiers. Its UUID-derived arrangement differs from run 03: 502 nearby plants, 160 completely covered instances, 75 partially covered/bent plants and 89,217 covered rooted groups. Its sampled initial fit was 4,373 ms. These are **different arrangements**, not a controlled before/after comparison.

`build/interactions087-foreground-capture-20261025-02/foreground-kernel/` captures run 04's exact accepted definitions, immutable pivot-local SI vertex bytes and frozen placement transforms. The native source-snapshot function avoids a MAXScript snapshot's world-coordinate conversion and float multiplication differences. Earlier replay exports were correctly rejected by the prepared geometry hashes; no hash checks were bypassed.

Findings and fixes:

- Root coverage now uses actual mesh projection distance and upward rays. A certified interior ball can classify a whole basal tuft. Completely covered poses have no per-guide arrays. Covered-root suppression remains reversible.
- Bounded capsule queries skip distant BVH nodes and distinguish exterior separation from containment before an unbounded nearest-surface search. The adapter still qualifies material coordinates, surface witnesses, normals and the signed-gap equation.
- Float-rounded Max rotations exposed an axis/gap witness inconsistency. The adapter now uses the exact matrix inverse, inverse-transpose normals and a caller-space reconstructed material witness. Strict witness tests remain enabled.
- A parent guide accepted a few micrometres of residual contact while its child correctly rejected that fixed root. The interaction fitter's penetration target is now 10 nm in source metres, below the adapter's root classification boundary. Fresh bounded-hinge candidates use the same strict clearance target. No frozen contract header changed.
- A bounded rotation search preserves each authored guide's curved shape and length around its rooted attachment, tries contact-directed orientations and validates all capsules again. The iterative rooted fitter remains the bounded fallback. This is a static contact pose, not a dynamics or stiffness model. `hinge_fits` counts these accepted searches; previous `hinge_fallbacks` receipts describe the earlier algorithm.
- Numeric jobs use the existing session CPU policy, automatically at most four participants. Workers only read copied/immutable numeric definitions and produce private results. All jobs join before an ordered failure check and staged merge. Host publication remains on the host thread.

| Fixed-layout kernel build | Initial fit ms | Eight-step median ms | Worst step ms | Scope |
|---|---:|---:|---:|---|
| 23 | 3,225.58 | Failed during movement | — | Strict witness rejection retained; not accepted |
| 31 | 1,972.57 | 1,021.87 | 1,332.08 | Serial, iterative fitting preferred; eight steps complete |
| 32 | 223.03 | 126.43 | 140.18 | Four numeric participants, validated rotation search preferred; eight steps complete |

These are development CPU kernel measurements on the **same captured actors**, not Max viewport FPS. Builds 33 onward also distribute mixed-source jobs across workers; their final host figures must be recorded separately.

Independent full visible-mesh audit of build 33's initial fixed-layout pose: **7,284,222 triangles across 502 nearby plants**, zero penetrating vertex/obstacle pairs, zero touching/crossing triangle pairs, zero planted-root drift, maximum stem-edge change **1.8116%**, maximum rigid foliage edge change approximately **5.1e-13**. The exhaustive diagnostic took approximately 269 seconds of accumulated per-plant CPU time. This proves that sampled pose in double precision; it does not certify every future pose or renderer float delivery.

### Preview and lifecycle successors

- Retained source triangle and instance streams now support immutable aliases and sparse edited/hidden instance masks. Rank/select maps visible ordinals without copying the complete transform population. Nitrous uploads the larger of the idle/navigation selected instance counts, with exact stream reuse and resource leases; it does not upload every stored placement merely to draw a limited prefix. SDK-free publication regressions and sparse ordinal tests pass.
- Prepared light tubes use original vertices from a few complete authored rings. Each preview corner retains an original incident face/corner address in the same material and outward sector. Whole foliage triangles retain exact original corner addresses. Lavender's posed preview decreases from 168,988 to **44,086 triangles**. Full render/Bake geometry remains 563,380 source triangles. The complete mesh view also reuses this shared prepared light source for unaffected reacting instances.
- Posed preview batches split at their 2M-triangle limit and recycle inactive spatial slots. Atlas pixels are shared; light/posed UV streams remain separately admitted. Actual material/render qualification follows separately.
- Contact settings and render-mode restaging retain effective Edit transforms when the exact frozen placement view is unchanged. Turning roles off retains only existing edited/disabled row history. A new placement epoch consumes the normal authored Edit stack instead of applying an old override twice.
- Collider deletion now reaches contact invalidation even when the row was not previously moved. Disabled history also participates in Undo. Coverage-off retains covered rooted groups at rest and bends uncovered groups; it does not attempt an impossible fixed-root displacement.
- Render packets retain pure geometry/rig data and their allocation leases, without scene weak watchers on renderer threads. All output packet/node/reference preparation precedes replacement. Captured authored normals are transported by material frames and instance normal transforms; this path still requires final renderer qualification.

`build/interactions087-smoke-host-20261025-14` **passed with exit 0** on the matched development candidate: source review, retained Mesh, individual native Edit movement and native Undo, pending Manual count/seed isolation, gap restaging, Collider-off/all-roles-off/re-enable, deletion/Undo, independent complete visible grass audit and save/reopen. Run 13 checked a still-unpresented handle immediately after a command; run 14 waits for actual presentation before taking the comparison point. Its grass audit checked 23,296 visible triangles with no intersections or root drift and maximum stem-edge change 0.853%.

The original scene and artist INI remain preserved. Frozen producer tests, final held pointer drag, large Max command/display statistics, material/render/Bake checks, final saved scene and exact MZP remain delivery gates.

## Final development corrections and scale campaign

Builds 36–43 added whole-source rest-box/triangle SAT rejection before guide work, explicit source/preview/render allocation leases, source appearance freshness, frozen review meshes at published instance locations, and a bounded authored-Edit collector for contact restaging. The collector preserves edits made while a collider role is off without consuming pending Manual population changes. One unshared Cyrus Edit modifier is admitted per controller; ambiguous stacked/shared Edit ownership is rejected.

Render outputs are separately tagged temporary nodes. Particle Flow collection excludes them, owner hiding removes them, and visibility/validity is part of the output refresh key. Clearing PFlow must not delete the private posed source outputs. Render packets retain pure copied geometry and numeric snapshots, without scene watchers on renderer threads. Bake uses the same complete mesh construction, with bounded allocation and rollback on failure.

The actual A069 folded-blade preview has 228 triangles at 5% rather than 4,360 full source triangles. Actual lavender uses 44,086 preview triangles rather than the temporary 168,988-triangle stem preview; full source remains 563,380 triangles. Original face/corner addresses preserve UV sectors. Preview reduction does not remove source guides from the contact solve or faces from full output.

`build/interactions087-terraces-host-20261025-07` passed with exit 0 on development candidate 13. It uses the same frozen UUID layout from terrace run 04. Four tiers each received eight individual native Cyrus Edit stone moves. All 32 contact generations advanced, handle positions matched, errors were empty, and placement epoch/build counts stayed unchanged during movement.

| Reacting plants | Whole Update (s) | Initial fit (ms) | Move command median / worst (ms) | Contact fit median (ms) | Preview preparation median (ms) | Synchronous redraw median (ms) |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1,116 dense foreground | 8.664 | 106.582 | 151.91 / 156.83 | 110.03 | 35.42 | 37.84 |
| 11,300 across terraces | 1.362 | 1.189 | 1.116 / 1.701 | 0.725 | 0.064 | 9.98 |
| 56,500 across terraces | 1.556 | 7.372 | 1.903 / 2.308 | 1.460 | 0.065 | 10.81 |
| 282,500 across terraces | 3.626 | 6.750 | 11.972 / 15.074 | 6.719 | 4.727 | 14.78 |

These are separate command and synchronous redraw samples, **not presented FPS**. First Update includes cold host/source/display work. Local density differs substantially between the dense foreground and spread terrace tiers, so the table is not an equal-density scaling benchmark. Sampled private process memory was 8.13–8.75 GB decimal, including the original terrace scene, library source meshes, Max and plug-ins; explicit kernel payload charges are not process peaks.

The fixed numerical replay improved from build 23's 3,225.6 ms initial fit (subsequent movement failed a strict witness check), to build 31's 1,972.6 ms initial / 1,021.9 ms median move, build 32's 223 ms initial / 126.4 ms median move, and build 36's 69.83 ms initial / 58.99 ms median move. The latter eight-move sequence completed, worst 63.40 ms. Unlike different random layouts, this fixed-input replay supports the causal performance comparison. See the retained run logs for individual samples and code revisions.

Numerical replay 33 independently audited 7,284,222 complete visible triangles in 502 near plants: zero penetrating vertices, zero touching/crossing triangles, zero planted-root drift, maximum stem-edge change 1.8116% and maximum rigid-leaf edge change approximately 5.1e-13. The exhaustive check took 269 seconds. It covers the initial double-precision pose, not every later movement or renderer float rounding.

`build/interactions087-render-host-20261025-04` passed with exit 0 on candidate 14. It includes the small lifecycle suite, edits while Collider is off, Undo, pending Manual count/seed isolation, role toggles, deletion/Undo, save/reopen, full grass Bake with all three test material IDs and original UV values, PFlow separation, clear/rebuild, owner hide/unhide, and an actual Scanline render using the private posed output. The actual delivered world-SI-float Bake was independently replayed: 4,360 triangles, zero penetration/touching, minimum surface gap 0.38755 mm. Its separate material/pixel/export receipts retain the exact scope. This is not a Corona/all-renderer certification.

Terrace run 05's movement timings are invalid: the fixture used viewport mode 4 instead of the real Mesh mode 3, and contact generation did not advance. Run 06 corrected that and passed 32 moves, then failed final fixture layer creation under disabled Undo. Run 07 fixes the fixture. Early render runs 01/02 had script-global/random-contact fixture errors; run 03 left autoRender false. Run 04 explicitly enables render flags. None of those failed candidates is counted as complete acceptance.

## Frozen delivery candidate

`build/interactions087-release-20261025-02/AminScatter/receipt.json` is the clean production producer: Max 2027 SDK, Release, MSVC 19.38, Ninja, no development preview/placement fault injection, verified compiler dependency closure, **59/59 native tests passed**. Producer 01 is retained but superseded after later source corrections. Generated checks pass 347 semantic controls, 13 pages and 37 feature IDs; the complete Python run passed **573 tests** in 41.06 seconds.

`dist/CyrusScatter-0.87.0-20261025/CyrusScatter-0.87.0-Max2027.mzp` is built from producer 02 and the newly built 0.87.0 managed Installer/Gallery pair. ZIP integrity, complete payload hashes, version/host guards and producer manifests pass. Exact extracted-payload Max runs, physical pointer observation and the final artist scene receipt follow in the delivery report. No artist installation, restart, Git commit or push has been performed.

## Physical pointer findings and correction (supersedes the preceding candidate)

The first pre-release package and the `-r2` package are withdrawn, retained with `WITHDRAWN.txt`. Their command/render passes do not establish final interactive acceptance.

1. Pointer run 04 exited during a real Sky drag. The retained minidump and a diagnostic relink map identify `CSEdit::requireEditableFeedback` through `CSEdit::Move`: a second native mouse event encountered pending GPU feedback and threw a MAXScript RuntimeError outside the script interpreter. Build 44 admits a native gesture against its complete starting frame, retains shared feedback/COW blocks for the gesture, validates row correspondence, and contains pointer-transform exceptions at the SDK boundary. Scripted transforms retain explicit validation/error behavior. End/Cancel/panel teardown release the gesture frame. Run 05 passed two actual drags and native Undo/Redo; pending Manual population inputs remained untouched.
2. A stronger run 06 also checked renderer-committed feedback rather than only the guide/contact generation and live handle. It showed that completed GPU buffers waited for `pointsMatch`, reached by an idle path skipped during held interaction. Both brief detailed and longer fast-view drags retained the preceding rendered frame during the observed hold. This is distinct from the fixed pointer exception.
3. Build 45 adds one registered readiness message per realized generation. The worker posts only immutable window/message/AnimHandle values. The existing owned Edit panel validates modifier, display object and controller identities on the host thread, then requests the ready container update/redraw. There is no worker scene access, placement rebuild, new polling timer or per-instance message loop. Old/deleted panel/owner messages are ignored. The production-body publication fixture verifies a single wake, no worker commit, and host-only promotion. Run 07 passed both real drags with renderer feedback and gizmo already updated before release, plus native Undo/Redo and Manual pending preservation.

Run 07 also exercised the actual generated Interactions panel through Sky: Analyze geranium, inspect the frozen review reference/22 guides/6 roots, Accept, then Apply. The review was removed, the original source stayed hidden, and a pending 10,011 amount still had its preceding 10,000 placements with the same epoch. Closing the Edit panel after readiness posts did not fail.

The apparent tree cube was a viewport face allowance: the actual rigid A072 tree has 432,640 triangles. Raising the allowance exposed its mesh without rebuilding placements. Final trial copies deliberately distinguish responsive 8M/5M idle/navigation face limits from detailed 20M/10M. The four-tier timing fixture retains its lower default display allowance; do not compare it to the detailed saved view as if they had the same drawing cost.

## Final package qualification

Clean producer **04**, Max 2027 SDK Release, passes **59/59 CTest** cases including the extended production publication-body fixture. All **573 Python checks** pass on the final sources (56.74 seconds). The installer is `dist/CyrusScatter-0.87.0-20261025-r3/CyrusScatter-0.87.0-Max2027.mzp`, SHA-256 `f69a4ef584695e7b11e9c7706e2b50bc60281077f26ddef70bd01e1ac51167b8`. Source/native/managed producer closure, ZIP integrity, full payload hashes and Max 2027/version guards pass.

Exact extracted payload runs `interactions087-final-render-20261025-03` and `interactions087-final-terraces-20261025-03` pass with process exit 0 and the original artist INI hash unchanged. The latter repeats all 32 stone commands with advancing contact generations and unchanged placement epochs/build counts. Its final 282,500-plant tier has 17.84 ms median / 20.61 ms worst command time; the dense 1,116-plant foreground has 136.40 / 156.14 ms. Separate Max qualification processes overlapped, and local contact densities differ. These CPU command figures are **not presented FPS or a controlled cross-version benchmark**.

The actual final Bake audit covers 12,962 delivered world-SI-float triangles: zero penetrating vertex/obstacle pairs, zero touching triangle/obstacle pairs, minimum surface gap 0.33352 mm. Source material IDs 1/2/3 and UV values pass; Scanline renders the private posed output. Other renderers and every future pose are not implied.

Exact-package pointer run **08** passes two real Sky gestures, with renderer-committed stone feedback, contact successors and the actual Max gizmo matching before mouse release (held generations 2 and 7). Manual amount/seed values, placement epochs and build counts remain unchanged; native Undo/Redo passes. Both final scene copies are saved and the responsive copy reopens and rebuilds its own valid runtime. Further full-trial audit results and exact saved hashes belong to [the delivery report](DELIVERY_0870.md).

## Saved-garden quality review — supersedes candidate r3

The reopened artist trial contains 12,416 reacting plants, ten rigid trees and three colliders. Its complete diagnostic checked **7,811,066 visible triangles in 491 nearby plants**, finding zero penetrating vertices, zero touching/crossing triangles, zero root drift and rigid-leaf edge changes below 4e-13. It also found **53.5656% maximum stem-edge change** at a lavender base. The contact-only result was insufficient; r3 is withdrawn before artist delivery.

The fast rotation had turned a planted tube's basal material frame while the delivered root-ring vertices stayed fixed. The successor prefers retaining the first span and basal frame. It uses a freshly checked flexible-base fit when the fixed span prevents clearance. Folded grass blades keep their separately tested flexible base. New rooted-tube regression cases exercise upper-stem and basal-span obstacles. A material-frame/tangent review, complete successor audit, exact-package host repeats and new scene copies are required before delivery. Failed development builds/replays remain retained; the delivery report identifies the accepted successor.

## Accepted r4 artist trial — final scope

Producer **06** is sealed against the corrected sources and compiler dependency closure. Its Max 2027 SDK Release build passes **59/59 native tests** in 27.40 seconds. The final production-source Python run passes **573 checks** in 51.99 seconds; generated inventory/layout checks pass. The material frame at a clamped basal joint now follows the average of its actual incoming/outgoing spans. Publication rejects an invalid frame. The rooted-tube regressions exercise both upper-stem and basal-span contacts, fixed roots, cleared visible triangles and tangent consistency.

The exact package is `dist/CyrusScatter-0.87.0-20261025-r4/CyrusScatter-0.87.0-Max2027.mzp`, SHA-256 `195e1ea9d0802ed8aff8289a42a5a17ef8393aa309ea03c45d1f73750132615a`. It supersedes r1–r3. Source/native/managed closure, ZIP integrity, all payload hashes and version/Max 2027 guards pass. Installer handlers and fresh installed startup were not repeated for 0.87.0; archive qualification and exact extracted-payload host qualification are distinct. No artist profile was installed or restarted.

Exact-payload render run **04** passes with exit 0. Its actual delivered world-SI-float Bake contains **17,440 triangles**, zero penetrating/touching pairs and minimum surface gap **0.34375 mm**. All three test material IDs and the source UV set survive. The private posed output renders in Scanline. Production Corona shaders and all renderers remain outside this result.

Exact-payload terrace run **04** passes all 32 native stone commands with advancing contact generations and unchanged placement epochs/build counts. This terrace campaign ran separately from our native builds, audits and other Max qualification hosts. Local density differs between tiers; these are CPU command and synchronous redraw costs, not presented FPS or an equal-density benchmark.

| Plants | Whole Update (s) | Move median / worst (ms) | Fit median (ms) | Preview median (ms) | Redraw median (ms) | Affected |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1,116 | 8.820 | 147.65 / 151.34 | 106.74 | 35.34 | 39.53 | 432–437 |
| 11,300 | 1.343 | 0.52 / 0.64 | 0.10 | 0.05 | 10.50 | 3–4 |
| 56,500 | 1.642 | 37.94 / 39.18 | 30.81 | 6.07 | 15.87 | 18 |
| 282,500 | 3.606 | 61.81 / 63.06 | 42.58 | 17.03 | 23.47 | 69–71 |

Sampled private memory is 8.47–9.29 GB decimal including the original scene, source models, Max and plug-ins. Frozen numeric replay 50 completes eight moves: 74.15 ms initial fit, 59.00 ms median and 68.36 ms worst. Different regenerated host layouts are not compared as if identical; the fixed captured replay supports the performance progression.

Pointer run **09** archives a successful exact-package held gesture: 14 observed frames, held generation 2 and final generation 4, with renderer-committed feedback and the Max gizmo matching before release. An early observer accessed temporarily absent feedback during activation/resize; the diagnostic now skips such frames. Later Redo checks failed and a later coordinate attempt hit a changed layout. Computer Use reported manual input in the window. Those attempts are **inconclusive**, retained without claiming either a confirmed plug-in cause or a completed physical Redo repair. The user's current window was then left alone. Historical successful physical Undo/Redo in run 08 belongs to the withdrawn preceding package.

A separate final artist session **12** passes hero command/Undo/Redo while a Manual amount remains 10,011 against 10,000 published placements. Both smaller stone rows move independently, leave the other two stone matrices unchanged and Undo correctly. Both scene copies are saved and the detailed copy reopens with a valid new contact runtime. Runs 10/11 are retained fixture parser failures (top-level local scope and a catch-expression throw); run 12 uses a bounded local execution scope. No product-source change was needed for those fixture errors.

The reopened final trial's frozen-producer numerical audit checks **7,812,598 complete visible triangles in 491 nearby plants**: zero penetrating vertices, zero touching/crossing triangles, zero planted-root drift, maximum rigid-leaf edge change 3.78e-13 and maximum stem-edge change **23.65%**. It took 264.06 seconds of accumulated audit CPU time. The corrected lavender case is **11.60%**, down from r3's 53.57%; the final worst case is a geranium stem. The provisional 25% edge ceiling is a coarse artist-trial gate, not proof of natural deformation. Exhaustive double-precision checking remains separate from the actual float Bake test.

The [delivery report](DELIVERY_0870.md) and [qualification manifest](QUALIFICATION_0870.json) pin final scene/package hashes and remaining acceptance. Physical Undo/Redo without concurrent input, subjective bending/gap quality, additional source profiles, production materials/renderers and broader animation/fault/soak coverage remain artist/future work. The original scene hash and artist INI hash remain unchanged. No Git commit, push, website publication, artist installation or restart was performed.
