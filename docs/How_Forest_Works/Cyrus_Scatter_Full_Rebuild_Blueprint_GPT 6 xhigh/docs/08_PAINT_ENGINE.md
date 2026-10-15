# 08 — Complete Paint Area subsystem: fast strokes, durable coverage, erase, falloff and Undo

**[FP-DOC]** ForestPack Paint Areas support direct viewport add/erase, brush size, tablet-pressure-sensitive sizing, falloff preview, include/exclude semantics and conversion to/from splines. Official paint instructions use a receiver in XY mode; the private paint storage architecture is not documented. [Source](https://docs.itoosoft.com/forestpack/forest-plugin/areas). **[CYRUS-DESIGN]** This chapter proposes an original implementation.

## 1. Define artist semantics before choosing storage

An artist does not paint geometry instances directly; they paint **coverage** that controls which candidates can be accepted. A painted region must remain when source models, density or random seed change. Erase modifies authored coverage, not merely today's accepted plant list.

The required editor must answer:

- Is brush radius measured in world units, screen pixels, UV distance or percentage of receiver?
- Does the tool paint all surfaces under the cursor, the nearest hit, or a chosen receiver?
- How do repeated dabs combine: union, max coverage, additive strength or layered opacity?
- Does erasing remove area coverage to zero, subtract brush strength, or create an ordered negative stroke?
- Can old strokes be individually edited, or only undone as transactions?
- Must paint follow deformation? What happens after topology changes?
- Is painted area mask binary or soft? How does boundary distance/falloff interact with it?

**Recommended initial product contract:** world-unit brush size; nearest *active* selected receiver; ordered add/erase brush actions with union/subtract binary coverage; smooth visual preview; transaction Undo; optional soft brush strength as a later independently versioned feature. Surface-bound UV painting is an extension unless deliberately prioritized.

## 2. Three separate data models

```text
Authoring authority           Compiled evaluator             Presentation
  stroke transaction log  --> tiled coverage field       --> brush overlay
  plus optional contours      plus distance field              preview plants
  receiver bindings            area IDs, revisions              affected-tile highlight
```

The authoritative record is durable and editable; compiled evaluation tiles and GPU overlays are discardable. A large history does not imply all strokes are evaluated per candidate per frame.

## 3. Proposed authoritative stroke format

```cpp
struct StrokePoint {
    WorldPoint hit;
    Optional<SurfaceBinding> attachment;
    float pressure01;
    float radiusSceneUnits;
    float strength01;
    double timestampOrder; // input sequence only, no wall-clock dependence
};
struct PaintStroke {
    Uuid strokeId;
    Uuid areaId;
    PaintOp op;         // Add | Erase
    PaintSpace space;   // XYWorld | ReceiverUV | SurfaceBound
    Uuid receiverId;
    std::vector<StrokePoint> samples;
    Bounds3 conservativeAffectedBounds;
};
```

For large projects, compact repeated samples using quantization with declared tolerances. Keep transaction boundaries; do not store each mouse move as a separate Undo transaction.

## 4. Brush input and hit sampling

1. Enter paint mode; acquire a host painter session and active area/receiver list.
2. Receive `StartStroke`, hit samples and `EndStroke`/cancel events from verified Autodesk painting API or custom viewport interaction.
3. Use host hit data (`worldPoint`, normal, node, barycentrics, face index, pressure, modifier keys).
4. Normalize event order, clip invalid pressure/radius, and convert to canonical scene units.
5. Fill gaps by resampling stroke positions at distance step proportional to minimum brush radius, e.g. `step ≤ minRadius/4` (candidate heuristic; benchmark).
6. Draw a provisional overlay immediately; do not await plant regeneration.
7. Merge samples into one in-memory transaction and compile touched coverage tiles.
8. On end, commit durable stroke/Undo transaction and schedule final authoritative update.
9. On cancel, restore changed tile versions or transaction snapshots and drop provisional stroke.

**SDK note:** Autodesk documents `IPainterCanvasInterface_V5::StartStroke`, `PaintStroke`, `EndStroke`, `CancelStroke`, and `PainterDisplay` callbacks. Exact signatures/hosting differ by Max SDK release; use the installed headers. [Autodesk Painter interface](https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-CPP-API-REF/class_i_painter_canvas_interface___v5.html).

## 5. Coverage compositor

For a circle dab center `c`, radius `r`, in an XY plane:

`inside = (distance(x,c) <= r)`. For soft brush propose `alpha = curve(clamp(1 - distance/r,0,1))*strength`.

Possible compositors:

- **Binary Add:** `coverage = max(coverage, dab)`.
- **Binary Erase:** `coverage = coverage AND NOT dab`.
- **Soft Add:** `coverage = 1-(1-coverage)*(1-dabAlpha)`.
- **Soft Erase:** `coverage = coverage*(1-dabAlpha)`.

Binary and soft compositors are not interchangeable. Preserve operation order in case of erase-then-add, overlapping strokes and noncommutative behavior. The exact soft-blend formula is a **Cyrus design**, not documented Forest behavior.

## 6. Raster compilation strategy

Recommended hybrid:

- **Edit authority:** compact stroke transactions (or editable contours for converted regions).
- **Sampling cache:** fixed-world-size tiled raster with sparse allocation; coverage bitset for binary and 8-/16-bit normalized texture for soft.
- **Boundary cache:** distance transform or contour representation per tile with neighboring seam exchange; recompute only touched/halo regions.
- **GPU overlay:** uploads only changed tiles; same authoring version determines visual coverage.

Choose tile size and world resolution via experiments. Set a declared minimum meaningful brush radius and an accuracy bound; consider multi-resolution tiles for giant world spaces. Track coverage error across resolution changes. Cache key includes stroke revision, paint-space transform, receiver revision, raster resolution and compositor version.

### Raster resolution and jagged edges

A low-res bitmap may visibly stair-step. Use antialiasing and signed-distance-derived edge smoothing in presentation; the **generation** mask must still have deterministic semantics. When the brush is smaller than raster pixel pitch, automatically increase tile resolution or explain why editing precision is limited. Do not silently lose thin strokes.

## 7. Erase and history behavior

A destructive edited bitmap is fast but cannot reconstruct individual stroke histories. A full list of strokes is flexible but can become expensive. Hybrid logging + compiled current-result cache gives both, but introduces cache-invalidating transactions. Undo can store either command inverse, changed-tile diffs or authoritative stroke-log revision. Compare memory on long sessions.

For a brush transaction:

```text
BeginStroke: capture old edited-tile descriptors (copy-on-write)
Dabs: modify working tile versions, extend dirty bounds
Commit: write stroke action + tile revision, publish stable edit
Undo: remove/reverse stroke in authority, restore/recompute touched tiles
Redo: deterministically replay authoritative operation
```

A cancelled paint drag must restore exact authoritative and compiled versions; no ghost strokes or stale worker publication.

## 8. Spatial attachment and deformation

For **XY paint**, strokes are planar coverage and may stay at XY locations while terrain moves vertically; this is convenient for lawns and architecture but not curved surfaces.

For **surface-bound paint**, each sample stores receiver face and barycentric/UV data so it can follow deformation. Topology updates can orphan samples; show a rebind workflow. UV stamps must consider seams, distortion and overlapping islands. Do not mix surface-bound and world-XY coverage into one field without a conversion policy.

## 9. Paint → Spline and Spline → Paint

- Raster to spline: extract iso-contours (marching squares at a declared threshold), simplify with world-space tolerance, preserve holes and handle self-intersections.
- Spline to raster: fill boundaries using declared winding rule and resolution.
- Conversion is **not necessarily lossless**: record sampling tolerance and replacement/duplicate policy.
- To preserve editability, provide **Convert to contour copy** versus **Replace paint authoring source**.
- Round-trip tests must compare coverage within declared boundary error, not just whether outlines look similar.

## 10. Falloff preview

Display two overlays:

1. Authored coverage (where artist actually painted).
2. Effective generation influence (including density/scale falloff and later area exclusions).

A plant rejected by collision should not appear as a hole in paint. Debug modes: authored mask, compiled mask, distance field, candidate positions, accepted positions, collision rejects.

## 11. Performance and local updates

On each stroke only touched tiles need coverage recomposition. Population changes can extend through falloff, random translation, Effects and collision propagation. Always know conservative influence bounds; if unbounded, fall back to larger/full recomputation.

Use job token + revision snapshot; if dab N+1 arrives before job N finishes, job N result must not publish. Coalesce rapid dabs; keep cursor/overlay responsive. The final release of the mouse must trigger authoritative complete evaluation. See `04_EVALUATION_CACHING.md`.

## 12. Host integration details

Brush callbacks interact with 3ds Max viewport/painter. Catch modifier-key conflicts, scene selection changes, node deletion mid-stroke, Escape/right-click cancellation, undo during a stroke, screen-DPI changes, tablet pressure no-data, surface behind a front object, and Max shutdown. Never dereference `INode*` held by worker tasks. Use proper theHold/restoration policy; test with Max's Undo stack and active modifiers.

## 13. Paint engine acceptance tests

| Case | Check |
|---|---|
| 10 strokes, same locations | Idempotent binary union output |
| Add → Erase → Add same circle | Correct ordered coverage |
| 1,000 overlapping strokes | Brush P95, cache memory, correctness |
| Stroke across tile boundary | No seam in coverage/distance field |
| Tiny radius at giant scene scale | Declared error tolerance, not dropped silently |
| Rapid successive strokes + cancellation | No stale publish, exactly one undo unit per stroke |
| Surface moved vertically | XY paint behavior stays documented |
| Mesh deformed, same topology | Surface-bound samples follow correctly |
| Topology changed | Orphans detected; no silent teleport |
| Convert to spline and back | Coverage difference within tolerance |
| Undo paint then change density | Authoritative state remains correct |
| Camera orbit while painting | Brush doesn't force unwanted generator rebuild |
| Save/reopen in different units | Same world-space brush sizes/coverage |

## 14. Build order for painting

**P1** Minimal world-XY paint coverage + direct overlay + stable density acceptance, no incremental occupancy optimization. **P2** Tiled incremental compiled masks + transaction Undo + boundaries/falloffs. **P3** Correct collision propagation and cross-scatter dependencies. **P4** Surface-bound brush, deforming receiver, contour conversion and soft-pressure workflows. **P5** performance profiling and dense production validation.

Do not begin with a highly complex undoable stroke graph before the simple path is correct; do not ship the simple path while pretending it has all advanced features.
