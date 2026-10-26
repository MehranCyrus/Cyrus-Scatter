# CyrusScatter 0.87.0 — Max 2027 Interactions trial

25 October 2026. Scoped artist-test delivery. The integrated layer contact workflow is implemented; production-wide qualification remains separate. Original Paint, Cyrus Edit storage 2 and the independently versioned Analyzer/content remain in place. No artist installation, restart, Git commit or push was performed.

Later delivery notes: the [three-host build-only EXE](INSTALLER_0870_COMPATIBILITY.md) packages this feature set without new runtime tests; Max 2024/2026 remain untested. The subsequent [Git checkpoint](GIT_CHECKPOINT_0870.md) records source publication. The statements below about no EXE or Git push describe this original Max 2027 r4 trial operation.

## Files and installation

- [Max 2027 installer](F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.87.0-20261025-r4/CyrusScatter-0.87.0-Max2027.mzp) — run through **Scripting > Run Script**, follow its result, then restart Max. This version has no new Max 2024/2026 package or combined EXE. Existing library content is reused.
- [Detailed trial scene](F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.87.0-20261025-r4/Trials/Terraces_087_Detailed.max) — 20M idle / 10M navigation face limits; recommended for inspecting the rigid tree and foliage.
- [Responsive trial scene](F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.87.0-20261025-r4/Trials/Terraces_087_Responsive.max) — 8M / 5M; display limits can substitute boxes. Both scenes have the same placements and 5% leaf/blade preparation.
- [Select test stone helper](F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.87.0-20261025-r4/Trials/Select_Test_Stone.ms) — run after opening the supplied scene to select the hero and restrict Edit markers to the three stones. It does not open or discard a scene; it was executed successfully in final artist session 12.
- [Artist workflow](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/plans/scatter-interactions-garden-20261025/ARTIST_GUIDE_0870.md), [execution and issue history](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/plans/scatter-interactions-garden-20261025/EXECUTION_0870.md), [machine-readable qualification and scene hashes](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/plans/scatter-interactions-garden-20261025/QUALIFICATION_0870.json).

Installer SHA-256: `195e1ea9d0802ed8aff8289a42a5a17ef8393aa309ea03c45d1f73750132615a`. Producer 06 uses the Max 2027 SDK, Release/MSVC 19.38, Ninja, verified compiler dependency closure and no development fault injection. All four native modules, generated script and 0.87.0 managed Gallery/Installer payloads are bound by package hashes. Archive integrity/version/host guards pass. Actual installer handlers and fresh installed startup were not repeated for 0.87.0; exact extracted bytes were host-tested. Never mix a loose script with older native modules.

## What works

The **Interactions** panel gives each layer a clear **Collider** or **React to colliders** role. Analyze, review and accept each source's inferred roots/branches; instances share its rest rig while keeping independent compact poses. Closed rock meshes use native triangle queries. The broad phase includes plant reach and old/new stone neighborhoods; it restores departing plants. Covered rooted groups are reversibly hidden while placement identities remain stored. Search bounds, root coverage and visible contact gap are separate.

Native C++ owns preparation, geometry/index storage, bounded contact fitting, pose lifetimes and sparse preview data. Workers consume copied numeric data; host access and publication stay on the host thread. Complete successors replace previous complete results. Pending Manual counts/seeds wait for Update scatter. One unshared Cyrus Edit modifier per controller is admitted. This is static rooted contact, with a validated fast rotation fit and iterative fallback; it adds no wind or inertial simulation and does not load a Jolt runtime.

The artist trial has **12,416 reacting plants, ten rigid trees and three stones**. Eight plant populations reuse four prepared assets: small grass, bushy grass, lavender and geranium. The supplied boulder component is reused at three sizes. The original terrace architecture is retained; the old static foreground rock is hidden in the derived scenes. Source materials use diagnostic colours. This is an interaction fixture rather than a finished landscape render.

## Measured performance

The exact package repeated eight individual native Cyrus Edit stone commands at each tier. Every contact generation advanced; placement epoch/build counts stayed unchanged. These are CPU command times and synchronous redraw samples, **not presented FPS**. The terrace campaign ran separately from our native builds, audits and other Max qualification hosts. Local density differs between tiers, so this is not an equal-density scaling benchmark.

| Reacting plants | Whole Update (s) | Move median / worst (ms) | Fit median (ms) | Preview median (ms) | Redraw median (ms) | Affected plants |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1,116 | 8.820 | 147.65 / 151.34 | 106.74 | 35.34 | 39.53 | 432–437 |
| 11,300 | 1.343 | 0.52 / 0.64 | 0.10 | 0.05 | 10.50 | 3–4 |
| 56,500 | 1.642 | 37.94 / 39.18 | 30.81 | 6.07 | 15.87 | 18–18 |
| 282,500 | 3.606 | 61.81 / 63.06 | 42.58 | 17.03 | 23.47 | 69–71 |

Sampled private process memory was 8.47–9.29 GB decimal, including the original scene, source meshes, Max and plug-ins. This is not complete GPU/global allocation or transient peak accounting. The same fixed numeric replay improved from build 31's 1,021.9 ms median move to build 50's 59.00 ms (worst 68.36 ms); initial fit decreased from 1,972.6 to 74.15 ms. The execution log records intermediate failures and causal changes. Different regenerated scene layouts are not used as a controlled before/after comparison.

## Correctness and interaction evidence

- **59/59 native tests** and **573 Python tests** pass. Generated checks account for 347 controls, 13 panels and 37 feature IDs; layout checks pass. Offline passes alone do not establish Max behavior.
- Exact payload render/lifecycle run 04 passes roles/gap restaging, edits made while Collider is off, deletion/Undo, pending Manual preservation, save/reopen, PFlow separation, owner hide/unhide and an actual Scanline render of private posed outputs. The actual world-SI-float Bake audit checks **17,440 triangles**, zero penetration/touching pairs, minimum surface gap **0.34375 mm**. Test material IDs 1/2/3 and source UV values are retained. This does not qualify all renderers, production shaders or every pose.
- Exact payload pointer run 09's first archived gesture passes **14 observed frames**, with a held contact successor, renderer-committed stone feedback and the actual Max gizmo matching before release. Later pointer/Undo checks are inconclusive: a Redo assertion failed and Computer Use reported manual input. These attempts remain retained; neither a confirmed plugin cause nor a completed physical Redo repair is claimed. Historical run 08 belongs to the earlier withdrawn package.
- Separate final artist run 12 passes a hero stone command with native Undo/Redo and a pending 10,011 amount retaining 10,000 placements. Both smaller stone rows move independently, other stone transforms stay fixed, and Undo restores them. Both trial copies are saved; the detailed scene reopens and rebuilds its own valid contact runtime. Your current test window was left alone.
- The reopened final trial's independent complete-mesh replay checks **7,812,598 triangles in 491 nearby plants**: zero penetrating vertices, zero touching/crossing triangles, root drift **0 m**, maximum rigid-leaf edge change **3.78e-13**, maximum stem-edge change **23.65%**. This exhaustive double-precision diagnostic is separate from the actual float Bake check and is not an interactive operation.

## Issues found and fixes

The issue log retains strict witness failures, source/branch admission problems, preview cost, stale Edit restaging, render-output ownership and failed fixtures. Key later fixes were frozen gesture feedback/SDK pointer exception containment, a host-thread GPU-readiness wake so completed geometry can appear during a held drag, and planted tube/frame handling. A full saved-garden audit caught 53.57% lavender basal skin strain despite collision clearance. Preserving a clear first span and aligning the joint frame to its actual averaged tangent reduced that lavender case to 11.60%. A freshly checked flexible-base fit remains available when the fixed span prevents clearance. Earlier packages r1–r3 are withdrawn; their successful subchecks are historical.

## Limits and next artist checks

Preparation currently admits reviewed ordered tube stems and ordered folded blades. Unsupported topology, mirrored/sheared/nonuniform transforms and ambiguous shared/stacked Edit ownership are rejected. Proxies need an explicit source mesh snapshot. New copied Edit instances need Update scatter. Recipe export rejects prepared definitions/active roles rather than dropping their data. Saved schema 60 opens schema 59 with Interactions off; preserve original scenes when upgrading.

Strong bending can still distort stems: the provisional 25% edge-change ceiling is a coarse trial gate, not a biomechanical or natural-bending guarantee. Conservative stem/foliage envelopes can leave extra clearance even at zero gap. Trees in this fixture are rigid. Wind, inertia, plant self-collision, two-way contact, deforming collider meshes and broad animation/seek/rescale/soak coverage remain outside this trial. Source, actor, guide, query, pose and output budgets can reject a successor while retaining the previous complete result.

Please concentrate artist testing on drag feel, gap/root coverage, strong-bend appearance and **physical Undo/Redo without concurrent input**. Test other sources/materials/renderers on copies. The original `Terraces_Final.max` hash remains `69ff41356a5312dba7841bc47bbe49b6ce77a8ca79168fd045c8c17c618a8378` and the artist INI hash remains unchanged. No website publication or artist-profile installation is implied by these local artifacts.
