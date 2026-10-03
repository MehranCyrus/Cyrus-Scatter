# Cyrus Scatter 1.1 — shared planting groups

3 October 2026. Product version **1.1.0**, scripted class version **50**; persistent class IDs are unchanged. This implements the [shared-group plan](../Artist_Zones_Integration_2026-10-03/PLANTING_GROUPS_IMPLEMENTATION.md) over the retained Mesh/Point Cloud/Proxy foundation. The earlier [1.0.1 diagnosis](../Artist_Zones_Integration_2026-10-03/PLANTING_GROUPS_REVIEW.md) remains frozen evidence of the defects being corrected.

Use the [artist guide](ARTIST_GUIDE.md) for installation and the grass/red/blue/yellow exercise. Source/UI edits belong in the generator and templates, with the generated MAXScript committed alongside them. Binary packages and synthetic scenes stay under ignored `dist/v1/` and `build/cyrus-v1/`.

## Resulting workflow

The receiving surface is visible once at setup level. One native list selects a plant group. Reused native rollouts edit that group's plant assets, population, coverage, randomization and spacing. Painted coverage is a property of the selected group, with independent saved history; it is not another layer or scatter controller.

The manager reports placed plants, representation-specific shown counts, removals, manual conflicts, pending updates and errors. A separate Plant centres mode gives one centre per accepted plant. Point Cloud and coverage feedback are explicitly labeled so their many dots cannot be mistaken for plant instances. Controls fit the same narrow command-panel width as the existing native editor. Update also refreshes the Brush status immediately; final UI testing caught a stale pending label after an otherwise successful update.

Coverage now has a colored, surface-following overlay, coverage samples, and Off. The legacy Painter display callback did not reliably draw in the tested Nitrous host. Submission now runs through a normal viewport redraw callback and consumes prepared numeric geometry. Painter still owns picking and stroke gestures. Geometry/field evaluation is outside the draw callback; saved surface materials are not edited.

The recorded Max 2027 UI views show the [group manager](evidence/screenshots/group-manager.png) and [painted coverage before Manual Update](evidence/screenshots/paint-coverage.png). The latter deliberately retains the previously published plants while showing the newly painted field.

## Corrected evaluation order

1. Prepare deterministic candidates and existing Area/distribution/source rules.
2. Apply coverage, then source transforms and stable CS Edit overrides.
3. Reserve visible manual overrides at their actual positions. Keep overrides that violate a rule and report their conflicts.
4. Process groups by descending priority, with persistent Edit keys breaking ties. Reject ordinary candidates against completed higher-priority groups and protected overrides before reserving within-group space.
5. Apply removal-only cleanup before the group's rows can block later groups.
6. Commit the whole setup's accepted placement snapshot. Preview, final output and Bake consume that population with their documented source/output policies.

The new native spatial-grid resolver replaces recursive intermediate blockers for this policy. Pair rules use persistent group GUIDs, not row indices. Erased, rejected or cleaned-away procedural plants no longer reserve invisible space. Mutual pair rules have a declared winner instead of independently emptying both groups. Copy has independent ownership/history and copies relationships; Remove and Undo preserve the relationship targets.

Manual edits use stable candidate identities independently of spacing survivors. Dormant records survive mask exclusion. Published final IDs gate CS Edit handles, including viewport hiding. Two stacked Edit modifiers were checked for composed movement and a downstream clone without exposing that clone in the upstream modifier.

## Caching and compatibility

New setups use policy 2. Old saved scenes retain policy 1. Explicit conversion imports legacy blocker references to GUID pairs and is undoable; conversion with existing CS Edit bindings is refused without resetting them. A genuinely saved 1.0.1 plane/curved scene was loaded under 1.1 and matched its original IDs, stroke histories and transform fingerprints.

The resolver prepares reusable per-group candidate rows and commits an accepted setup snapshot. Display changes and camera navigation reuse that snapshot. Manual display changes preserve a pending-update state. Pair settings, priorities, source radii, Edit revisions, paint validity and density-map identity are inputs to relevant cache keys. Tests caught and corrected reuse when replacing same-class black/white density maps. Edits inside a map are refreshed by Update; this release does not add a general texture dependency watcher.

Selective dependency scheduling is not complete: a committed placement change can rerun the bounded setup resolver, while unchanged group preparation is reusable. Do not describe this version as evaluating only affected lower-priority groups. The retained rendering implementation remains in use; no CUDA/OpenCL compute or asynchronous Max SDK calls were added.

## Qualification

Exact curated outputs and byte identities are recorded in [the evidence manifest](evidence/MANIFEST.json). Fixtures run in disposable Max profiles, never the artist's open scene.

| Check | Result / scope |
| --- | --- |
| Max 2026 native build | 12/12 native suites passed against its SDK; no actual Max 2026 runtime claim |
| Max 2027 native build | 12/12 native suites passed; isolated interactive host checks below |
| Python tools / MCP regression | 62 tests passed; no new MCP capabilities added |
| Native resolver | Exhaustive oracle comparisons, randomized inputs, boundaries, XY/3D, scaled radii, protected conflicts, invalid inputs, dense 100k rejection case |
| Four shared groups | Grass/red/blue/yellow accepted counts 732/84/25/26; red 290 eligible candidates becomes 84 after within-group spacing |
| Paint then spacing | Independent greedy oracle matches accepted rows; erase restores available grass/other flower space |
| Final blockers | Rejected group, final cleanup, moved blocker, hidden/disabled distinction, mutual pair rules |
| Edit | Move, dormant mask, spacing change without reseeding, clone/delete Undo, conflict preservation, handle visibility, stacked modifiers |
| Curved receiver | Nonuniformly scaled sphere; 98 accepted plants from 4,000 candidates; spacing and topology/target validation |
| Source/output policy | Weighted Empty and Point-only sources, black/white density maps, exact hidden-group Bake |
| Native UI | Reused editor handles over repeated selection; actual mouse stroke and right-click exit; coverage visible in Nitrous |
| Overlay | Tint/samples/Off; 15 camera movements do not rebuild candidates/field or issue field queries |
| Retained Mesh | 20,000 instances; 45 camera/redraw steps with zero placement generation, Brush query or retained-buffer upload increments |
| Renderer | Real 128×128 Scanline render with 3,567 accepted plants; hidden group retained in final population; transient nodes cleaned |
| Persistence | Save/reopen checks exact group IDs, priorities, pair rules, stroke histories and accepted transform fingerprints |
| Installer / startup | Actual Max 2027 MZP installation in a private profile; fresh startup and four loaded module paths/hashes matched the package; installed-file campaign passed |
| Uninstall | Owned registrations removed in a disposable profile; unrelated registration, scene controllers and recoverable product files preserved; new Brush redraw callback removed |

The camera-step measurements are synchronous host timings, not presented FPS. The demo uses primitive stand-ins rather than production foliage. These checks preserve the previous performance design; they do not establish unlimited real-time performance for arbitrary scenes or qualify Corona/V-Ray/FStorm output.

## Bounds and deliberate limits

- Existing UI limit: 10 groups; generation cap: 100,000 candidates per group. Density is evaluated across the receiver before masking; there is no unbounded refill loop.
- Coverage preview: at most 32,768 triangles with bounded subdivision work; sample display uses the existing bounded candidate aid. Reduced-detail status concerns the overlay, not mask evaluation accuracy. Small brushes on large triangles and curved geometry are covered by native tests.
- One static receiving object per painted setup; no animated/deforming/multiple painted targets, automatic topology remap, UV-map export or geodesic spacing.
- Pair footprints are configured radius approximations. Conflicting manual overrides remain visible and reported, so a conflict result must not be described as collision-free.
- Brush Relax and shared-group Boundary Relax remain paused. Preserving stable, constrained movement is separate work.
- Legacy conversion with existing Edit bindings remains guarded. Dedicated artist and renderer qualification, Max 2026 runtime testing, very long-history performance and adaptive point detail remain open.

## Reproduction and next checks

See [developer commands](../../tools/v1/README.md). `planting_qualification.ms` checks group resolution, output policies, overlays, Edit and prepares a saved scene. `planting_reopen_fixture.ms` verifies that scene in a fresh process. `planting_legacy_fixture.ms` compares a real older saved scene to its original expectations. The gesture fixture verifies a real preceding mouse gesture rather than fabricating one.

For artist acceptance: paint overlapping red/blue/yellow regions above grass; change a pair's priority/gap; erase red and Update; compare Plant centres and Mesh; hide versus disable blue; save/reopen a copy. Try the equivalent exercise on a static sphere using 3D rather than XY spacing. Record the scene, representation, candidate/placed/shown counts and any error when reporting a discrepancy.

After those checks, prioritize actual production foliage/renderer and Max 2026 testing. Then profile stroke commit and group resolution on larger scenes before adding selective dependencies or more concurrency. Keep automatic point-detail research and broader semantic-zone/MCP/ML work separate from this correctness release.
