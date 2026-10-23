# Cyrus Surface Analyzer 0.14.2

The **Scatter 0.86.8.7 EXE** includes Analyzer **0.14.2 for Max 2027 only**. The matching standalone `CyrusSurfaceAnalyzer-0.14.2-Max2027.mzp` is also qualified. The [delivery report](../docs/plans/code-quality/DELIVERY_08687.md) records exact-package installation, loaded-helper rejection, restart and analysis checks. This is an independent installer safety and backup correction; the analysis algorithm is unchanged.

The historical [0.86.8.6 combined delivery](../docs/plans/combined-installer/DELIVERY_08686.md) and [0.86.8.5 delivery](../docs/plans/combined-installer/DELIVERY_08685.md) retain their matching Analyzer 0.14.1 payloads and qualification for Max 2024, 2026 and 2027. The prior [0.86.8.3 report](../docs/plans/refinement-program/DELIVERY_08683.md) retains its original Max 2027 scope.

The package supplies guide freshness, a native contract guard, verified immutable runtime installation and loaded-module startup resolution. Close Max 2027 before using the EXE, then reopen it. The EXE installs both products; no separate Analyzer installation is needed. For the standalone route, use **Scripting > Run Script** with the matching Analyzer MZP, then restart Max 2027. Analyze old guides explicitly; Scatter in Manual mode still needs its own Update.

The .14.2 MZP delegates to the same managed Analyzer transaction engine as the EXE. Exact recognized .14/.14.1 installations can migrate; unknown/custom startup files, receipts or plugin registrations block installation and remain intact. Original bytes are retained under `scripts/CyrusSurfaceAnalyzer/Backups/v2/` using verified create-only publication. Interrupted temporary backups can be retried; an older differing final backup is preserved with a migration record. Follow the reported conflict or recovery path. A different Cyrus installer already loaded in Max requires a restart before retrying the MZP.

Previous 0.14 behavior: general model/display notifications no longer trigger analysis; geometry, topology, transforms, stack changes and parameter changes still update.

Realtime analysis waits for mouse release. Internal Cyrus PFlow deletion events no longer trigger a redundant analysis. Use the native module matching the target Max year and package hash.

In the matching supported Max host: Create > Geometry > Cyrus > Surface Analyzer.
Independent native C++ analysis engine with a MAXScript Modify panel.

## Controls

- **Fit radius** replaces Min width in the UI. A disk of this radius around every accepted point must fit inside its element, clear of both exterior edges and holes. It is a hard geometric constraint in the element plane. Zero disables footprint clearance. New nodes default to 0.5 metres; old scene Min width migrates to half that value. The legacy parameter remains serialized but is no longer used by UI analysis.
- **Point radius** controls centre-to-centre separation. This is independent of Fit radius. It does not mean disks must be non-overlapping.
- **Min points** is a total minimum per element. Zero keeps radius-only spacing. The minimum can reduce Point radius separation (marked `*`), but never violates Fit radius. If no eligible space remains, no point is fabricated; the UI reports an unmet minimum.
- **Relax steps**, 0–200, controls a bounded iterative constrained Laplacian solver on the clipped guide paths. It reduces raster zigzags; points are then redistributed and exact boundary clearance is rechecked. Zero disables relaxation. This is geometric guide relaxation, not a physical simulation or globally optimal point packing. Rings retain their circular form.
- **Ring factor** controls the preferred ring radius as a fraction of centre clearance. Fit radius can shrink it further so point footprints fit.
- **Min length** retains the existing path/region length filter. Resolution (48–768) controls raster analysis precision and cost.
- **Update > Manual** preserves output until Analyze. **Real-time** updates geometry, topology, transform, time and setting changes using source events (150ms delay) and a 250ms main-thread timer. Idle inputs do not recompute. Analysis pauses during rendering and never runs from viewport drawing.

## Elements, geometry and results

Each edge-connected mesh element is analyzed independently before plane fitting and boundary extraction. Attached elements may have different heights or orientations. Holes remain within their element. Vertices must be welded; proximity does not join separate topology. Individually nonplanar elements, closed solids and invalid boundaries are rejected with their element index. A failed update preserves the prior cache.

Auto chooses a principal straight region for approximately orthogonal boundaries, a ring for balanced radial stars, or branched paths otherwise. Minor short edges and small edge-angle deviations no longer automatically force the branched method. Manual method overrides remain available; Auto is a heuristic and cannot infer every design intention.

Straight regions use an approximate largest raster rectangle in a basis aligned with the longest boundary edge. Branched paths come from raster thinning. Fit radius clips guides, relaxation reduces small bends, and a final analytic point-to-boundary test checks every accepted point, including minimum-count replacements. Very narrow features can be missed by raster resolution. The eligible region need not be fully covered, and some branches can receive no points due to separation from other branches/elements.

Surface area is the sum of world-space triangle areas. Overlapping faces are not unioned. With positive Fit radius, Region area is the raster estimate of feasible point-centre area. With Fit radius zero, it retains the mode-specific rectangle/disk/width-filter region measure. Path is aggregate guide length. Areas display in square metres using scene system units.

## Output and persistence

The Analyzer script records whether its published guides are current. Relevant edits invalidate that record; Analyze renews it. Current and pending states survive save/reopen. The matching current Scatter script rejects stale Layout/Area/falloff guides while retaining its last complete result. Use Analyze, then Update scatter in Manual mode. Older saved guides without the freshness record require one explicit Analyze; a version caption alone does not identify the matching script/package.

Boundary/path/point toggles draw cached results. Explicit spline/helper exports create independent snapshots, not live links. Source meshes are not modified. Cached results, update mode and settings persist in MAX files. Nodes and guides are schematic and non-rendering. Cyrus Scatter can reference Analyzer paths and sample points through its Area controls; that Scatter adapter evaluates path bands and point-radius masks in world XY, even though Analyzer itself supports separately oriented planar elements. See the [artist-zone integration audit](../docs/Artist_Zones_Integration_2026-10-03/CODEBASE_AUDIT.md#a03--analyzer-integration-exists-but-its-geometry-scope-differs) for the current source scope and proposed extensions.

Keep versions' binary folders separate and restart Max after installation. Source scene files are never overwritten by installation. Extremely small Point radius values exceeding the candidate budget are rejected explicitly. C++ analysis remains single-threaded and synchronous; large meshes/many elements/high resolution can still pause the UI.

## Build and checks

Build Release x64 with the Max 2027 SDK and the [current build workflow](../docs/Max_2027_Installation.md#rebuild-for-developers). Run analyzer_tests. The .14.2 MZP binds its native module, script, startup wrapper and shared managed installer through descriptor and payload hashes. The [candidate report](../docs/plans/code-quality/DELIVERY_08687.md) records exact installer and restart checks separately from pending final delivery acceptance. Historical scripted Max 2026 integration checks cover Analyzer line/point masks, boundary falloff and save/reopen in the [0.78.3 area examples](../docs/Container_and_Radius_0.78.3_2026-10-10/AREA_EXAMPLES.md); they do not establish new .14.2 qualification for that host. Physical input, high DPI, long sessions and the full host/output matrix remain open.

Tests cover attached mixed elements, radius exclusion, minimum overrides, hard Fit radius after Relax and minimum replacement, tilted surfaces, holes, slightly non-orthogonal straight regions and impossible footprints. Real Max tests validate final boundary distances, UI, live updates, idle behavior and saved settings. The supplied three-shape scene is used only in separate test processes and copied preview outputs.
