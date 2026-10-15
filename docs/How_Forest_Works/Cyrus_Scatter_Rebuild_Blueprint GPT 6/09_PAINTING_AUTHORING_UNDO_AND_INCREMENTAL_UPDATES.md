# 09 — Painting: authoring, representation, Undo, and responsive updates

**Status: proposed Cyrus design. Research basis: R0 §3.3 and §8.5–8.6. Host callback evidence: S21.**

## 1. Decide the meaning before choosing the storage

Painting edits a spatial definition, not the current list of plants. Changing sources after painting must not require repainting. Erasing paint changes coverage; deleting a plant creates an instance-edit tombstone. These are separate commands.

The reference documents paint/erase, receiver-based painting, and spline conversion. It does not establish ForestPack's private current storage format [R0 §3.3]. This chapter deliberately selects a Cyrus model.

## 2. Two authoring modes

### Region Paint

The artist paints a region. A saved threshold, default 0.5, converts canonical coverage into a hard region through the declared contour reconstruction. Independent area falloff controls density and size near its boundary.

### Density Paint

The artist paints a continuous density multiplier from 0 to 1. No hard interior is implied. A value of 0.25 means approximately one-quarter candidate survival before later constraints, not plants at one-quarter size.

A Density Paint field has no automatic meaningful boundary for distance falloff. A user can explicitly extract an isocontour at a chosen threshold to create a Region Paint definition.

## 3. The selected authority: current canonical tiles

For the initial projected backend, the authoritative state is the current fixed-resolution, quantized coverage grid. Store it in sparse tiles. A stroke log supports audit/replay and optional history tools, but it is not required for every sample query or every scene load.

This is a refinement of the research's hybrid proposal. It avoids a brush query whose cost grows simply because ten thousand old strokes exist. It also avoids promising editability of arbitrary historic strokes unless that capability is actually implemented.

Save the grid origin, cell size, quantization, reconstruction version, paint mode, receiver/frame binding, and populated tile contents. Changing resolution is an explicit resampling command with Undo, not an automatic cache eviction.

## 4. Projected backend

Use a `PaintDomainUUID` with a saved frame and receiver restriction. Coordinates are defined in a fixed two-dimensional grid. A tile key is derived from those coordinates, and its sample cells have half-open ownership.

The default brush affects only the selected/frontmost receiver. A separate “through selected receivers” mode deliberately stamps multiple domains. Two slabs at the same XY position must not share paint merely because their positions project identically.

A receiver-local projected domain follows rigid object transforms. It does **not** automatically follow arbitrary vertex deformation. The UI names that limitation and offers the surface-attached backend where required.

For multiple projected sheets inside one receiver object, require a sheet restriction or surface-attached paint. Do not silently flatten folded surfaces.

## 5. Surface-attached backend

Use a UV-independent per-face micro-grid or microtriangle atlas keyed by receiver topology, face, and barycentric location. Coverage follows deformation with unchanged topology. Atlas edges share or reconcile seam samples using geometric adjacency; material/UV seams do not automatically create cracks.

Resolution is defined relative to the reference mesh. Deformation can stretch the effective world-space texel size; expose that fact and offer explicit resampling. Arbitrary topology changes invalidate the atlas unless a correspondence is supplied or a deliberate reprojection operation is performed.

Brush neighborhoods can use a graph of micro-samples along surface adjacency. A bounded Dijkstra search from the hit sample yields a discrete surface-distance brush. This is exact relative to that graph, not an exact continuous geodesic. Refining the graph improves its approximation but costs memory and work. Keep its resolution and algorithm version in the authoring contract.

A faster tangent-disc mode can be offered with depth and normal-angle limits. Name it as a local projection approximation; on folded thin geometry it must not masquerade as surface-distance painting.

## 6. Brush kernel

For normalized radial distance `q = distance/radius`, define a kernel with zero outside q >= 1. A hardness parameter specifies the constant interior and a smooth boundary transition. Radius must be positive and finite.

The default region brush uses:

```text
b = clamp(effectiveStrength * kernel(q), 0, 1)
Add:   coverage' = max(coverage, b)
Erase: coverage' = min(coverage, 1-b)
```

For the exact integer contract, quantize the brush value first: `b16 = floor(clamp(b,0,1)*65535 + 0.5)`. Then store `max(c16,b16)` for Add and `min(c16,65535-b16)` for Erase. This order defines complement behavior at rounding ties. It matches the executable reference. These operations are selected for predictable non-accumulating region authoring; they are not asserted ForestPack equations.

An optional flow brush uses an explicitly integrated exposure model and saved dab/time information. It is a different brush policy. Do not make the result depend accidentally on display frame rate.

## 7. Stroke resampling

Mouse events are not evenly spaced. Resample the accepted hit path in the paint domain at a configured fraction of effective brush diameter, default 0.15, with a maximum gap bound. Radius/strength interpolation is defined between samples.

When the pointer leaves the receiver, terminate the current connected sub-stroke. Do not draw a bridge from the last valid hit to an unrelated later surface. A receiver change starts another domain segment in the same user gesture transaction.

Canonical dabs, not raw UI frame timing, determine repeatable output. Save dabs when replay is required. Same dabs on the same canonical starting tiles must reproduce identical tile bytes.

## 8. Max Painter callback hazards

The official `IPainterCanvasInterface_V5` callback supplies world/local hit data, face/barycentric data, effective radius/strength, pressure, and stroke lifecycle callbacks. It warns that barycentric/face values may refer to an evaluated mesh at a different stack position. Radius and strength already incorporate brush modifiers such as pressure [S21].

Accordingly, the adapter must **not multiply pressure again** by default. It converts effective radius/strength once. It verifies the hit's evaluated-mesh fingerprint against the receiver snapshot. If they differ, resolve a fresh hit against the intended snapshot before recording a binding.

Interactive and update-on-mouse-up callback routes converge into the same canonical dab stream. Mirror input receives distinct sub-stroke/domain identities and is not processed twice accidentally.

## 9. Stroke state machine

```text
Idle
  -> BeginGesture
  -> CaptureBeforeTiles lazily
  -> AppendCanonicalDabs / UpdateWorkingTiles
  -> EndGesture -> CommitOneAuthoringTransaction
  -> or CancelGesture -> RestoreBeforeTiles
```

Working tiles use copy-on-write. On first modification of a tile, retain its before state. At commit, retain only changed before/after payloads or a lossless delta representation. Remove no-op tile changes.

The authoring transaction succeeds independently of whether a full plant population has finished rebuilding. A later population failure leaves the authored paint intact and reports that its output is not current.

## 10. Undo/Redo

One stroke is one Undo action. Never allocate one host RestoreObj per dab. Store authoritative tile changes, created/deleted tile identities, domain changes, and relevant parameters. Redo restores exact after bytes; it need not replay floating-point brush calculations.

Undo increments the current authoring revision, marks affected derived fields dirty, and invalidates stale jobs. It does not restore a cached pointer whose inputs no longer match.

Use Max's Hold/RestoreObj mechanisms through the host adapter and respect nested transactions [S22–S23]. The adapter owns host transaction boundaries; MAXScript and native code must not each create an independent competing Undo action for the same gesture.

Large strokes may exceed Undo memory budgets. Show a warning or use a supported compressed/out-of-core transaction representation before committing; never silently make only half the stroke undoable.

## 11. Current coverage versus historical editing

The specified core permits Undo/Redo and edits to current coverage. It does not promise arbitrary parameter edits to a stroke from six months earlier.

An optional `Editable Brush Path` area can preserve a procedural curve plus brush parameters as a separate authoring object. Editing that path recompiles its field. This is preferable to making every ordinary paint gesture permanently dependent on a replay of the entire history.

Checkpointing can bound replay for a full stroke-history tool. Checkpoints and operation logs require versioning and exact composition rules; adding the UI alone is not sufficient.

## 12. Contours and distances

Region Paint uses a saved marching-squares reconstruction with a deterministic saddle-case rule. The resulting piecewise-linear contour defines the hard region. This is an approximation to a user's continuous gesture but an unambiguous authority for geometric evaluation at the chosen resolution.

Select these CyrusV1 reconstruction conventions: samples equal to the threshold count as inside; edge crossings use linear interpolation; an edge with both endpoints equal to the threshold contributes no duplicate crossing. Resolve a four-crossing saddle by the bilinear cell-center value; a center exactly at the threshold uses the fixed lower-left-to-upper-right diagonal. Traverse extracted loops with region interior on the left, so outer boundaries and holes receive opposite orientations. Canonical sample addresses own shared tile-border values; tiles do not maintain divergent duplicate authority. A change near one tile border invalidates contour cells in adjacent tiles that share samples. These conventions define a particular piecewise-linear region, not an exact contour of a continuous brush.

Distance falloff caches can be truncated at the largest finite requested range. Their dirty support includes that range plus reconstruction/filter error. Unlimited distance queries require a broader index or conservative global invalidation.

Do not assume a one-tile halo handles every falloff range. Store the support bound on the field request.

## 13. Responsive publication

The brush cursor and working-coverage overlay are lightweight outputs and update before exact population completion. They display the current authored/working region, not a guessed subset of plants.

During a gesture, coalesce compute requests. Keep the last exact population visible. When an exact new result is ready, verify its scene, authoring, receiver, and dependency revisions before publishing it.

A newer stroke supersedes an old job. Cancellation is bounded between batches. The implementation must not queue hundreds of obsolete jobs while a pen moves rapidly.

## 14. Collision consequences

Coverage changes can be localized to affected candidate domains. Greedy collision acceptance can propagate beyond them. Initially rerun the full layer collision solve after reevaluating affected candidates.

Only enable exact localized occupancy after the old/new conflict-graph closure algorithm in chapter 11 passes randomized equivalence tests. A cached surrounding ring is not a proof of correctness.

## 15. Conversion and baking

Paint-to-spline is contour extraction at an explicit threshold and simplification tolerance. Preserve holes and multiple components. Report tiny regions removed by a user-selected cleanup threshold. Surface paint requires a projection or a surface-following curve export; a planar spline cannot losslessly represent arbitrary folded coverage.

Spline-to-paint is rasterization at the selected canonical resolution. Save the source relationship only for an explicitly linked procedural conversion. A baked conversion copies the result and becomes independent.

A brush stroke never silently converts the authored region into thousands of Max scene nodes.

## 16. Memory example

A 256×256 tile of 16-bit coverage has 131,072 bytes of raw samples, or 128 KiB, before metadata and compression. A fully covered 100×100 m square at 1 cm samples contains about 100 million samples and about 200 MB of raw coverage. Sparse tiling helps only where tiles are absent; it does not make a densely painted fine-resolution field free.

Store all-zero/all-one tiles compactly, compress inactive mixed tiles, and materialize working tiles on demand. Keep canonical bytes recoverable without GPU resources. Show estimated coverage and Undo memory before a resolution change.

## 17. Error recovery

Missing receiver: keep paint data and mark its binding unresolved. Changed topology: keep the old atlas frozen and require an explicit repair decision. Corrupted paint asset: fail that field with an actionable diagnostic and preserve the rest of the setup. Invalid radius: reject the dab, not the entire scene.

Save/open must preserve canonical tile bytes, transform/frame metadata, reconstruction version, and pending-orphan diagnostics. An empty plant output cannot be used to conclude that the paint itself is empty.

## 18. Required tests

Test add/erase ordering, repeated identical max dabs, soft brushes, pressure handling, different raw event rates producing the same canonical dabs, stroke cancellation, receiver switching, UV seams, stacked balconies, folded geometry, rigid movement, deformation, topology changes, tile borders, exact Undo bytes, interrupted builds, and save/open.

Compare short and long histories that produce identical current canonical tiles. Field evaluation should depend on current tiles and queried geometry, not replay history length. This is an acceptance requirement to measure, not a performance result claimed by this document.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S21]: https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_i_painter_canvas_interface___v5.html
[S22]: https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_hold.html
[S23]: https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_restore_obj.html
