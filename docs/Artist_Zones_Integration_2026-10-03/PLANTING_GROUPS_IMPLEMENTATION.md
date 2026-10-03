# Implementation plan for shared planting groups

This plan addresses the [reproduced Brush preview and collision problems](PLANTING_GROUPS_REVIEW.md). Status: **core workflow and removal-only solver implemented in Scatter 1.1.0**. See the [implementation/qualification report](../Planting_Groups_2026-10-03/REPORT.md) and [artist guide](../Planting_Groups_2026-10-03/ARTIST_GUIDE.md). Existing retained display remains the baseline. Artist/renderer and actual Max 2026 qualification, selective dependency scheduling and constrained Relax remain separate gates.

## Product contract

One Scatter setup owns the receiving surface. Inside it, each plant group owns sources, coverage, density, randomization, footprint settings and manual corrections. Painting targets the selected group. The setup resolves interactions between groups and publishes coherent results for preview and final output.

Start with one shared static receiving object for painted groups, including curved meshes. Reuse existing multi-surface behavior for unpainted legacy groups; do not claim a multi-target Brush document. A different surface requires an explicit choice, not silent rebinding of saved strokes. If a shared surface is replaced, preserve each document and report validation/rebinding requirements.

Use existing group GUIDs and stable Edit keys. A group name, color, row position or source-material ID is not its persistent identity. Keep current plugin class IDs and saved references. No new scene helper is required per stroke or plant group.

## Artist workflow and native controls

Use the current native Max rollout host and reusable selected-group controls. Keep root settings clearly separate from the active group's settings.

| Control | Responsibility |
| --- | --- |
| Receiving surface | Shared target, shown once at setup level |
| Plant groups | Single native list: name, placed count, visibility and status |
| Selected group heading | Always identifies the group being edited or painted |
| Sources | One model or a variant palette for that group |
| Coverage | Whole surface or Painted; existing Area restrictions remain additional constraints |
| Density | Absolute candidate density in plants/m², with Count retained as an explicit alternative |
| Paint and Erase | One tool acting on the selected group's document, with existing editable history |
| Spacing | Within-group distance, relationships to other groups and conflict priority |
| Display status | Placed count, representation-specific shown count, pending changes or limiting budget |

Selecting Painted should initialize an empty document on the shared target when safe; do not make the artist pick that same surface again for every color. Returning to Whole surface disables the mask while retaining its history. Starting Paint on an existing document must never replace its history. Copy keeps independent paint and a new ownership ID while preserving the initial generated result.

Changing the active group during painting must finish or cancel the in-progress gesture explicitly, stop the previous target, bind the next document and show the new group. Switching should not leak a stroke between groups or change their seeds. Preserve the existing right-click stop behavior and one Undo action per committed stroke.

For new planting setups, recommend plants/m² because brush area then has a predictable density meaning. Display the effective candidate cap; the current density path caps at 100,000 per group. Do not silently change counts, units or cap behavior in existing scenes. Count means candidates over the receiver; do not refill every small painted patch to that Count.

## One evaluated population with distinct display representations

Maintain three separate revisions: saved coverage input, evaluated placements and displayed representation. Show when coverage/settings are newer than the published plants in Manual mode. Never present pending coverage as an already rebuilt population.

Plant centres, Point Cloud, Proxy and Mesh should consume the same committed final placement snapshot. With sufficient budgets and ordinary mesh sources, centres and Mesh must agree on instance identities and transforms. Point Cloud may have many samples per instance. Limited Mesh/Proxy must expose the shown subset and reason. Representation changes should rebuild display resources without rerunning placement/collision work when placement inputs are unchanged.

Coverage is a separate optional aid. First clarify existing dots and add an unmistakable distinction from plant centres. Then prototype a bounded tinted overlay on a copied receiving-surface representation. Test small brushes on large triangles, soft edges, curved targets, near/far views and depth ordering before choosing tessellation or another display method. No per-frame surface evaluation, stroke replay, material mutation or bitmap dependency is acceptable.

## Generation and collision order

The new policy requires a staged evaluator, not a recursive call from one layer into another:

1. Prepare receiver/source snapshots and a deterministic base population. Candidate identity exists before paint and collision removal.
2. Evaluate Area/zone eligibility, Brush weight and source policy against those candidates. Preserve surface roots and anchors separately from later manual transforms.
3. Apply source transforms and supported CS Edit operations using stable IDs. Preserve edits on candidates temporarily excluded by masks as dormant records.
4. Resolve supported spacing against eligible candidates and the already accepted placements of higher-priority groups, using configured pair rules and a spatial index.
5. Apply removal-only final cleanup. Publish this group's final placements, footprint data and revision for lower-priority groups.
6. Publish the complete setup snapshot. Build retained viewport representations from that snapshot; final render/bake evaluation uses equivalent inputs and collision policy, independent of preview budgets and viewport visibility.

Do not silently relocate plants as part of the first spacing implementation. Brush Relax remains paused until a separate constrained-movement implementation is qualified. Removal-only spacing and final cleanup should be correct first.

### Priority and pair relationships

Store pair rules by persistent group IDs. The geometric clearance rule for A and B can be symmetric while the winner is chosen by stable priority. For the initial flower/grass preset, the base cover has lower priority than painted groups; the UI must state this. Let the artist change priority explicitly. Within equal priority, define a stable visible order and persist it. Selection, rename, viewport mode and most-recent stroke are not ordering inputs.

For source-footprint mode, the proposed clearance is `radiusA + radiusB + pairGap`. Retain fixed-distance mode for simple setups and migration. Source footprints are artist-configured approximations; scale response must use the final transform. Do not claim exact leaf or branch intersection prevention.

Expose planar ground-footprint distance and spatial centre distance deliberately. World-XY distance ignores height and may incorrectly couple upper and lower parts of a rounded or folded surface. Spatial distance also couples nearby sheets. A geodesic or surface-component policy is separate work; curved painting support does not establish a surface-distance collision solver.

Use a grid or another measured local spatial index rather than all-pairs comparisons or Max geometry queries per candidate. Reuse existing native removal kernels where their contracts fit. Evaluate groups in priority order; independent snapshot/preparation work may later use bounded workers on copied data. A shared acceptance index must not be mutated concurrently without a deterministic design. GPU computation is not a prerequisite.

### Final cleanup and manual edits

A group must finish cleanup before its rows become another group's blockers. A removed plant cannot continue reserving space. Cleanup can leave unused space; the first solver should not iterate an unbounded refill/relaxation loop in pursuit of maximum packing.

Manual edits need an explicit preservation policy. Recommended contract: saved overrides are never deleted by automatic solving. An edited candidate excluded by its source mask stays dormant. A visible edited or cloned placement is evaluated at its actual transformed location. If preserving an artist override violates a spacing rule, show a conflict and retain the edit record; do not label the result collision-free. The solver design must specify how accepted overrides reserve space before ordinary procedural candidates and how conflicting overrides are reported.

Before implementation, pin this policy down in fixtures for movement, scale, deletion, clone and multiple Edit modifiers. Simply moving the existing Edit call earlier is insufficient: its signature and input set currently depend on the legacy pipeline. Refactor binding against the stable base identity separately from the currently visible survivor list. Assert that changing spacing or another group's paint cannot reinterpret an existing edit as a different plant.

## Cache and publication rules

Cache receiver geometry, the base population, evaluated coverage and accepted placements separately. Invalidation follows their inputs. A changed red mask should reevaluate red and the lower-priority groups whose rules depend on it; it should not reseed blue or rebuild the receiving mesh. Groups higher in priority or unrelated by rules remain reusable.

**1.1 implementation boundary:** prepared group candidates and completed setup placements are cached. A committed input change may rerun the setup's bounded priority resolver; selective dependency scheduling above is still a target, not a completed optimization. Display changes and camera-only navigation reuse the accepted snapshot. Density-map replacement identity is keyed; edits within a texture are refreshed with Update, without a general texture dependency watcher.

Blocker cache keys must include accepted-placement revision, relevant source footprint/scale data, pair rule and Edit revision. Do not cache blockers solely from pre-edit procedural settings. Hidden-in-viewport groups remain part of final placement rules. Disabling a group from output removes its plants and blocking influence.

Publish group changes coherently. In Manual mode, keep the previous completed placement snapshot until Update; allow separately labeled coverage feedback while painting. In Real-time mode, coalesce committed revisions and discard obsolete work before publication. Never publish red from one revision and dependent grass from another as if they were consistent.

Retain zero placement generation during camera-only navigation and UI browsing. During painting, bound overlay work; defer full dependent-group solving until a committed stroke or an explicitly designed bounded preview. Profile stroke commit, generation, collision, upload and navigation separately.

## Compatibility and migration

Existing files keep the legacy solver policy by default. New setups may use the new policy once qualified. Conversion must be explicit and undoable, with before/after placed counts and a visible explanation that spacing survivors can change. Preserve source assets, surface references, mask histories, layer IDs, Edit records and seeded candidate transforms wherever the mapping is valid.

Convert blocker references from indices to stable group IDs for the new policy. Reorder, rename, Copy, Remove, Undo and save/reopen must not silently target different groups. Circular legacy blockers require a declared priority order, not an inferred recursive conversion. If existing Edit binding cannot be mapped safely, leave that setup in legacy mode with a precise explanation rather than resetting user work.

The old 0.64 installer remains a comparison build; it cannot be assumed to read newly saved Brush data. This work does not alter the older saved-scene comparison procedure.

## Implementation sequence and acceptance gates

- [x] Verify installed 1.0.1 bytes and loaded modules in a disposable Max 2027.1 profile.
- [x] Reproduce independent mask-dot counts, Point Cloud counts, Mesh limits and Manual publication.
- [x] Prove four independently painted groups can share a target using existing records.
- [x] Reproduce pre-mask spacing, removed blockers, mutually empty blockers and edited blocker positions.
- [x] Add new-policy fixtures beside the unchanged 1.0.1 diagnostic.
- [x] Separate stable candidate preparation, masks, spacing and Edit binding; preserve the legacy route.
- [x] Implement removal-only spacing after eligibility using priority and accepted final blockers.
- [x] Introduce shared target binding and native selected-group controls over existing records.
- [x] Correct preview labels, centre identity, limits and Manual pending feedback.
- [x] Implement bounded continuous coverage; test its numeric field and visible Nitrous submission.
- [x] Qualify save/reopen, Undo/Redo, Copy/Remove, stacked Edit, viewport/output membership and Scanline output in Max 2027; build/test both SDK targets.
- [x] Package 1.1.0 with a grass/three-flower plane demo and curved-surface fixtures; see its separate evidence.
- [ ] Test actual Max 2026 installation, UI, Brush and rendering.
- [ ] Complete production foliage/renderer and artist acceptance on plane and curved receivers.
- [ ] Add an artist-facing group reorder interaction if needed; no new reorder control ships in 1.1. Pair identity already uses GUIDs and tie order uses stable Edit keys.
- [ ] Profile and implement selective dependency scheduling only where it pays for its complexity.
- [ ] Qualify constrained Brush/Boundary Relax before enabling it.

Required solver cases include empty/full/soft/overlapping masks, erase, masks changing near spacing boundaries, explicit pair gaps, conflicting priorities, a removed higher-priority plant, moved/deleted/scaled/cloned Edit output, hidden versus disabled groups, multiple sources, nonuniform target transforms, and repeated deterministic evaluation.

Required display cases include unlimited and constrained budgets, a source exceeding the face budget, a zero-face/unsupported source, centre-only placeholders, pending Manual masks, stale results, and camera navigation during painting and after publication. Source conversion failures must be reported separately from budget limitations.

Measure representative light and heavy gardens on the current retained-display baseline. Establish bounds for candidate count, stroke history, grid occupancy and memory. Use a simple exhaustive distance oracle for small native solver tests. Only expand performance optimization after output and identity invariants pass.

## Reproducing the current diagnostic

Use a new private run name; never run this fixture in the artist's open scene. The recorded run used a verified private 1.0.1 installation as its source:

```powershell
python tools/v1/launch.py --run group-mask-audit-new --installed-from build/cyrus-v1/hosts/v101-relax-reset
# Wait for this run's transport-ready.txt before submitting a recipe.
python tools/v1/request.py --run group-mask-audit-new --timeout 45 tools/v1/identity_fixture.ms
python tools/v1/verify_install.py build/cyrus-v1/hosts/v101-relax-reset --loaded-profile build/cyrus-v1/hosts/group-mask-audit-new
python tools/v1/request.py --run group-mask-audit-new --timeout 45 tools/v1/group_mask_diagnostic.ms
```

The diagnostic creates synthetic nodes only in that private process and writes `group-mask-diagnostic.json` there. It asserts current limitations deliberately. It does not simulate mouse painting or benchmark FPS. Close only the private process after verifying its PID and command line against its `launch.json`.
