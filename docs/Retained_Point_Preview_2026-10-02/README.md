# Retained Point Cloud integration — 0.63 candidate

> Historical implementation record. For the current product use [the documentation index](../README.md) and [backlog](../BACKLOG.md). Measurements and instructions below apply to their recorded build.

2 October 2026. This implements the next bounded loop after the [private display experiment](../Heavy_Scene_Viewport_2026-10-02/RESULTS.md). It keeps **Point Cloud / Proxy / Mesh**. No additional Preview / Full Detail toggle is needed for this change.

## What changed

Point Cloud now shares an immutable native point snapshot with a Nitrous display owner. Completed positions stay in graphics buffers while the camera moves. The old per-point GraphicsWindow submission remains the fallback and a session-only comparison option. The controller icon and CS Edit still provide selection; no expensive picking of every preview dot was added.

There is one disposable display node per visible controller, with items for its enabled layers/source groups. Creation, cache publication and deletion happen on Max's main thread outside the redraw callback. Drawing consumes native data; it does not evaluate MAXScript values or source nodes. A weak controller reference disables drawing on deletion. The existing release timer handles direct external property changes missed by the owned UI/event path.

The existing owned UI and source/undo events publish completed preview caches before requesting redraw. A redraw that discovers unpublished data uses the native marker fallback and schedules publication. Thus an external edit can have a transitional fallback frame; this is not an asynchronous calculation engine or a promise of zero edit latency.

Display nodes are stripped before save/hold/autobackup and rebuilt after the file operation, including failure completion notifications. GPU buffers and pointers are never serialized. Existing persisted parameters and the scatter class ID remain compatible. Display nodes are nonrenderable, cannot convert to a mesh, ignore Zoom Extents and have locked transforms. The renderer's placement/Particle Flow transport is unchanged.

Point buffer payload reservations are bounded at **64 MiB per generation / 128 MiB per process**. These limits cover float3 position payload, not total RAM or measured VRAM: the immutable CPU snapshot, the SDK system copy, graphics overhead and outstanding old generations also cost memory. Allocation failure disables that generation's retained items and keeps the original CPU cache for marker drawing. Refreshing/replacing the preview retries. Nitrous owns device resources; actual device loss and a second GPU remain unqualified.

## A small coverage correction

The old preview budget used `ceil(total / budget)` as an integer stride. Asking for 500,100 points with a 500,000-point budget displayed only 250,050. The new display-only selector chooses exactly `min(total, budget)` evenly spaced indices. It preserves order, avoids duplicates and uses integer quotient/remainder arithmetic to avoid multiplication overflow. It does not consume placement RNG or change render transforms/source IDs.

This removes a large density jump at budget boundaries. It does **not** provide camera-dependent detail. The budget still applies per controller and is divided between enabled layers. When there are more plants than preview dots, some plants necessarily have no displayed dot. A source sampling error now names the source and appears in the aggregate layer status, rather than looking like a successful empty preview.

## Measured results and qualification

See [RESULTS.md](RESULTS.md) for final measurements, environment, accepted runs and limits. The accepted tests exercise the actual controller and generated script, not only the standalone prototype. Raw evidence and exact recipes are retained beside the report.

The key remaining quality gap is clear: a fixed 500,000-dot budget over 10,000 shrubs averages only 50 dots per shrub. More efficient drawing cannot reveal unsampled branches on zoom. A focused 50-shrub fixture with 10,000 samples per shrub shows substantially more shape detail. These are explicitly different populations, not proof of automatic LOD or equivalence to FStorm.

## Try the candidate

Packages are generated under `dist/retained-point-0.63/`. Max 2027 was exercised interactively; Max 2026 is compiled and native-tested but its application runtime has not been tested here. The existing 0.62 boss handoff is preserved.

1. Save your work and run the matching `CyrusScatter-0.63-Max2027.mzp` through **Scripting > Run Script**, then restart Max.
2. Work on a scene copy. Choose **Point Cloud** in the existing Display mode list and enable Show preview. The retained path is automatic.
3. Use Points/plant and the point budget to control quality. Proxy and Mesh continue to use their existing drawing implementations and limits.
4. For a controlled comparison in the MAXScript Listener, use `CyrusRetainedPointDrawing false` for the old native markers, then `CyrusRetainedPointDrawing true` to restore retained drawing. This switch is session-only and does not alter placements.

`CyrusPointLastError`, `CyrusPointAvailable`, `CyrusPointOwner <controller>` and `cyrusRetainedStats <owner>` expose diagnostics. Counters report explicit plugin buffer initialization and issued draw calls, not completed frames or driver transfer traffic. Read [the harness guide](../../tools/performance/retained_integration/README.md) before using fixture scripts; those scripts reset their private scene and must not run in an artist session.

## Next loop

1. Establish a close-up quality target with representative real foliage and preserve the accepted frame-time measurement procedure.
2. Test shared source point sets and stable prebuilt density levels with coarse spatial regions. Select existing data by projected size, with hysteresis, without re-running placement or rebuilding the whole cloud on camera motion.
3. Compare that against simply increasing the retained point budget; keep the simpler method if it meets both quality and memory limits.
4. Qualify overlapping controllers, selected/frozen/layer visibility, save-selected/merge, renderer/IPR cancellation, device recovery, Max 2026 and a second workstation before broad deployment.

The target remains a useful wide landscape and close inspection in the **same** scene. Arbitrary full mesh detail at an invariant FPS is not a claim of this candidate.

## Implementation map

| File | Responsibility |
| --- | --- |
| `AminScatter/include/point_preview.h`, `src/point_display.cpp` | Immutable snapshots, native display items, weak controller binding, bounds, payload reservations and counters |
| `AminScatter/src/preview.cpp` | Existing GC cache shares point data directly; marker fallback and diagnostic export read the same snapshot |
| `AminScatter/include/preview_sampling.h` | Exact bounded preview-index selection |
| `AminScatter/tools/ui/retained-points.cjs` | Generated controller synchronization, transient ownership, persistence callbacks and fallback status |
| `AminScatter/src/edit_plugin.cpp` | Registers the private display class through the existing DLM; no additional binary |
| `tools/performance/retained_integration/` | Isolated builds, interactive host recipes, comparisons, analysis and evidence collection |

The implementation follows the [Autodesk retained-display interfaces](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_object_display2.html). Save/open process completion notifications are documented by [Autodesk's Max 2026 changes](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/What-is-New-in-MAXScript/What-was-New-in-MAXScript-in/GUID-56622940-9CCA-47BF-B1E2-375AAC5AAD23.html). FStorm's video motivates the experience; its proprietary implementation has not been established.
