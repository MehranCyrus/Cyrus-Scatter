# Cyrus Scatter — Rebuild Blueprint

## 04 · Viewport, Rendering, Camera, LOD and Performance

Tags: **[Doc]** verified in iToo docs, **[Doc\*]** from your research notes (unverified), **[Inf]** inference, **[Prop]** my design, **[Test]** needs an experiment.

---

## 1. Principle: one population, many consumers

```
Published, immutable  shared_ptr<const InstanceBuffer>
        │
        ├── Viewport representation   (point cloud / boxes / proxy / mesh)
        ├── Picking structure         (hit-test subset + spatial index)
        ├── Render instance stream    (per backend)
        └── Export / bake             (to native Max instances or meshes)
```

Each consumer builds **its own derived data** from the same buffer. Changing the display mode rebuilds only the viewport view. Moving the viewport camera should normally **not** re-run placement. The only exceptions are camera-dependent rules the artist has switched on, and the system should always know *why* it rebuilt.

---

## 2. Three counts that must never be confused

| Quantity | Meaning |
|---|---|
| **Candidate count** | Positions the distribution engine examined |
| **Accepted instance count** | Items that survived all generation rules |
| **Displayed count** | Items or points chosen for interactive drawing or for the render stream after limits |

Show all three in the stats window. A fast viewport does not prove an efficient render export, and a small accepted count does not prove a cheap build (rejections cost time).

---

## 3. Viewport

### 3.1 Reference behavior [Doc]

- **Mesh / Adaptive / Proxy** modes. Proxies available: Planes, Pyramid, Box, Thin Box, Plant, Arrow. *Adaptive* switches automatically when face count exceeds a threshold (viewport builds simplified geometry above ~100,000 faces).
- **Point Cloud:** "ultra-fast" 3D preview. Default budget **250,000 points per object regardless of item count**; the **GPU buffer is only updated when the object changes** (cached otherwise); color by ID or from the material's Diffuse; random tint visible live; a "Shade" slider fakes lighting; tunables in an INI file (points per object, hit-test max points = 1000, selected-density 300%, unselected 100% in Custom Edit). Recommended not to use it with features that rebuild on viewport changes (e.g. camera "Enable on Viewport").
- **Max Items:** an approximate cap on items drawn; the engine **lowers the distribution density** to stay under it; 0 removes the limit (risk of crashing Max).
- **Manual Update**, **Disable Object**, **Freeze All** (freeze all Forest objects except when rendering).

### 3.2 Cyrus viewport design [Prop]

| Mode | Use | Implementation notes |
|---|---|---|
| **Point cloud** | Default for large scenes | One GPU vertex buffer of `(position, size, packed color)`; instanced point sprites; shader-faked shading |
| **Boxes / proxies** | Medium counts, shape cues | Instanced simple meshes in a GPU instance buffer |
| **Mesh** | Final-look preview for small counts | Instanced source meshes with per-instance transform |
| **Adaptive** | Automatic switch | Switch per tile by distance/face budget |

Specifics:

- **Retained GPU data.** Upload on change only; navigation redraws existing buffers.
- **Stable preview subset.** Choose displayed items with `Random01(seed, id, ChPreview) < q`. Raising quality *adds* instances; it never reshuffles the population. (This improves on the reference, which lowers distribution density **[Doc]**.)
- **Per-tile buffers.** Each tile owns its buffers; editing one tile updates only that tile's GPU data.
- **Picking.** A sub-sampled hit-test set (capped) with a spatial index; selected items drawn denser, as in the reference's Custom Edit **[Doc]**.
- **Camera-dependent options** (facing camera, view-dependent density) are flagged. If enabled they invalidate output prep, not placement (§6).
- **Overlays** independent of plants: authored coverage, generated candidates, accepted instances, displayed subset (file 05 §3). An error at one stage must not masquerade as another.
- **Viewport-only items** like non-geometry sources (lights) draw as marker dots, since drawing their original geometry caused problems with newer viewport versions **[Doc]** (9.3.4 fix).

---

## 4. Rendering

### 4.1 Reference behavior [Doc]

- **Render Mode: Automatic** uses all the renderer's capabilities and creates instances, meshes or proxies according to the object type; **Meshes** builds **one combined mesh** containing every tree (useful, for example, when one Forest uses another as a sample).
- **No need to convert meshes to proxies**: the plugin uses native geometric shaders to create instances on the fly for compatible renderers.
- **Render Max Items / Max Faces:** default **1,000,000 items / 5 million faces**; when reached, an "F" icon is built instead of trees and the stats window warns. Max Faces is ignored in Automatic mode for instancing renderers.
- **Simplification Level:** reduces item count progressively without touching distribution parameters (0 = everything).
- **Hide Custom Objects before rendering:** hides the source objects so heavy originals are not rendered.
- Some renderers use an older integration interface and cannot honor every animation mode **[Doc]**.

### 4.2 The render backend interface [Prop]

```cpp
struct RenderCaps {
  bool nativeInstancing, perInstanceTint, perInstanceAnimation,
       edgeBoundary, lodSelection, proxySources, instanceIdPass;
};

class IRenderBackend {
public:
  virtual RenderCaps Capabilities() const = 0;
  virtual void Build(const InstanceBufferView&, const SourceTable&, const RenderSettings&) = 0;
  virtual void Update(const InstanceDelta&) = 0;     // incremental for IPR where supported
  virtual void Release() = 0;
};

struct RenderInstance {                // conceptual stream element
  SourceHandle source; Mat4 transform; MaterialHandle material;
  uint64_t instanceId; uint32_t animationSample; Vec3 tint; uint64_t boundaryMask;
};
```
A million instances must **not** mean a million duplicated mesh allocations or a million 3ds Max nodes. The exact technique depends on each renderer's and Max's SDK versions; a generic `GetRenderMesh` path is **not** enough for memory-efficient instancing — that is why it is only the fallback.

### 4.3 Backend roadmap

| Order | Backend | What it provides | Main risk |
|---|---|---|---|
| 1 | **Meshes (universal)** | One combined mesh for any renderer; vertex-color tint; Size boundary only | Memory scales with instances × source faces; respect max items/faces |
| 2 | **V-Ray** | Native instancing, proxies, Edge boundary natively (incl. proxies in Full Mesh preview, V-Ray 6+) **[Doc]**, per-instance data | SDK specifics per V-Ray version |
| 3 | **Corona** | Native instancing, per-instance tint through its mechanism, Edge via opacity/cutout map **[Doc]** | Per-instance attribute path |
| 4 | **Arnold** | Procedural/instancing path, Edge via opacity/cutout map **[Doc]** | Version coupling (reference added Arnold 7.5 support in 9.4.0 **[Doc]**) |
| 5+ | Others (e.g. Octane — the reference fixed camera-settings updates there in 9.4.3 **[Doc]**) | As needed | Variable |

**Before committing UI for any backend, build a one-day prototype that proves four things on that renderer:** (1) 1M instances of one mesh render without duplicating geometry; (2) a per-instance color reaches a shader; (3) an opacity cutout can be driven per element/instance; (4) IPR/viewport updates when the buffer changes. Record the results in the capability table.

### 4.4 Materials and per-instance data

See file 03 §2. Backends implement the "Cyrus Color" shader node using whatever per-instance data mechanism the renderer offers; capability flags tell the engine what is possible. Where unsupported, fall back to baked vertex colors (Meshes backend) and warn.

### 4.5 Edge boundary — what a backend must supply

Edge mode removes **individual elements** whose lowest vertex falls outside the area (an *element* = connected faces sharing a material ID **[Doc]**), producing clean borders without Boolean slicing. Requirements:

1. Core: per-instance `boundaryMask` computed from area coverage at each element's lowest world-space vertex (file 02 §F).
2. Backend: map `(instance, element) → visible?` into the renderer — natively (V-Ray) or through an opacity/cutout texture node (Corona/Arnold).
3. Viewport: not previewed by default; offer an explicit opt-in preview (the reference uses Ctrl-click **[Doc]**).

It cannot be replicated by adding only a CPU trim flag.

### 4.6 Render-time limits and simplification [Prop]

- Limits: max items and max faces with a visible placeholder (a labeled marker) and a stats warning when exceeded.
- **Simplification level `k`:** keep an instance iff `Random01(seed, id, ChPreview) < 2^-k` so levels nest and are stable.
- **Hide source objects** option, plus detection of "sources used by scatter but visible in scene" as a warning.
- Memory model for budgeting (§9) before build: warn if the predicted memory exceeds a user threshold.

### 4.7 Instancing is not free

Native instancing avoids duplicated geometry **[Doc]** but still costs per-instance records, acceleration structures in the renderer, and per-instance data streams. Budget all of them (§9).

---

## 5. Camera controls

### 5.1 Reference [Doc\*] — verify on the Camera page

Field-of-view limiting, **Expand** and **Back Offset** margins (10–20% expansion often useful to avoid popping of geometry and shadows at frame edges), far clipping, look-at / **facing camera** orientation (disables random rotation **[Doc]**), distance-based density and scale falloffs, LOD settings, and a warning that population/visibility changes can cause animation problems. The viewport option "Enable on Viewport" triggers rebuilds on view change **[Doc]**.

### 5.2 Three different optimizations (never merge them)

| Feature | Question it answers | Effect |
|---|---|---|
| **Culling** | Should this item participate in this output? | Removes items from an output; shadows and reflections may still need off-screen items, so the policy must be explicit |
| **Density reduction** | Can this region use fewer instances? | Changes the **population** |
| **LOD** | Which representation should this item use? | Keeps the **placement**, changes its mesh/material |

A tree remaining with a cheaper mesh is not the same as the tree disappearing. They can be combined, but measure each separately.

### 5.3 Cyrus approach: output-stage filters, stable thresholds [Prop]

- Implement culling, distance density falloff and LOD **after** the accepted buffer exists (stage 14), using stable per-instance random values:
  - Distance thinning: keep iff `Random01(seed,id,ChPreview) < f(distance)`.
  - LOD transition jitter: `threshold × (1 + jitter·(Random01(...,ChLodJitter) − 0.5))` so levels do not switch in a visible wave.
- Because they do not regenerate placement, camera movement does not rebuild collisions. Collision-aware thinning (thin *before* solving, so survivors can fill gaps) is an optional mode with a stated cost and a camera-dependent flag.
- **Margin controls:** frustum expansion and back offset, defaulting to ~15%, with a note on shadow-casting off-screen geometry.
- **Camera-motion envelope for shots [Prop; not in the reference]:** union of frustum coverage over the shot's frame range; generate/stream that population once. Eliminates popping across an animation.
- **Facing-camera** (billboard-like orientation) is applied at output prep.

---

## 6. LOD

### 6.1 Reference [Doc\*]

A helper groups two or more alternatives (geometry and optional materials), switching by **maximum camera distance** or **minimum screen size**, with transition variation to reduce abrupt changes. It is a **selection helper**, not automatic mesh decimation.

### 6.2 Cyrus [Prop]

- A **LOD set** is a source kind containing ordered levels `[ {source, material, maxDistance | minScreenPixels} ]`.
- Selection stage in output prep:
```cpp
int SelectLevel(const LodSet& s, float distance, float screenPx, float jitter01) {
  for (int i = 0; i < s.levels.size(); ++i) {
    float t = s.useScreenSize ? s.levels[i].minScreenPx * (1 + s.jitter*(jitter01-0.5f))
                              : s.levels[i].maxDist     * (1 + s.jitter*(jitter01-0.5f));
    if (s.useScreenSize ? screenPx >= t : distance <= t) return i;
  }
  return s.levels.size() - 1;
}
```
- LOD is part of the **source library**, not a separate scatter per level.
- Collision radius and boundary footprint use the **base** level (so LOD changes never alter placement).
- Backend receives the chosen level and its material; instancing groups by `(level, source)`.

---

## 7. Display limits, freeze and update control

| Control | Behavior |
|---|---|
| Max viewport items | Via stable preview subset (not by changing density) |
| Max render items / faces | Hard limits with placeholder + warning |
| Manual update | Skip rebuilds until the user requests one; show a "dirty" indicator |
| Freeze all | Skip evaluation except for final render |
| Disable | Hide from viewport and render |
| Auto-update surfaces | On by default (reference: off **[Doc]**) |

---

## 8. Scalability and performance targets [Prop — calibrate against the reference on identical scenes]

| Scenario | Target |
|---|---|
| Change tint or preview % on a 1M-instance scatter | No re-solve; update within one frame to a few frames |
| Change one source weight | Re-select + downstream only; candidate/surface stages reused |
| Paint a 3 m radius patch | Affected tiles only; brush overlay instant; population updates asynchronously |
| Camera orbit with point cloud | Interactive frame rate independent of accepted count (bounded by 250k points default) |
| Cold build, 1M candidates | Parallel across tiles; report per-stage ms |
| Full rebuild vs incremental | Bitwise identical (enforced by tests) |

Always measure: input handling, coverage evaluation, candidate generation, surface queries, rejection, accepted-instance construction, GPU upload, picking, render export; and distinguish **cold build** from **warm update**.

---

## 9. Memory budget model

```
M ≈ M_source_states + M_instance_records + M_candidate_scratch + M_spatial_indexes
  + M_surface_cache + M_field_rasters + M_display_caches + M_render_streams
```

| Component | Typical driver | Controls |
|---|---|---|
| Source states | #distinct sources × animation samples | sample LRU, proxies |
| Instance records | accepted count × bytes/instance (≈ 50–80 B with core streams) | preview subset, simplification |
| Candidate scratch | tile candidate count | tile size, pooling |
| Spatial indexes | accepted count / radii | hash cell size |
| Surface cache | terrain triangles | shared cache |
| Field rasters | area extent / resolution | adaptive resolution, tiling |
| Display caches | points/instances drawn | point budget |
| Render streams | accepted count | backend capabilities |

Rules: reducing source geometry may not fix problems caused by excess candidates or duplicated caches; instancing does not make memory free; report **peak temporary memory** separately.

---

## 10. 3ds Max SDK constraints and conventions

| Topic | Guidance |
|---|---|
| **Threading** | The SDK is generally not thread-safe; read scene data and publish results on the main thread; compute on workers from snapshots **[Doc\*]** |
| **Painting** | Use the SDK painter interface for stroke start/update/finish/cancel with hit data **[Doc\*]** (confirm the exact interface in your SDK version) |
| **Parameters** | Param blocks with references, so scene references (splines, meshes, maps) notify on change and feed revision counters |
| **Undo** | Each user gesture is one command; heavy derived data is never on the undo stack |
| **Notifications** | Convert host change messages into revision bumps; do not recompute inside the notification |
| **Viewport drawing** | Use the platform's modern viewport drawing path; retain GPU buffers; confirm per Max version that custom draw hooks are valid |
| **Objects as sources** | Resolve at snapshot time to `(mesh, bbox, material, proxy info)`; do not hold live node pointers on workers |
| **File compatibility** | Version your chunk format (file 01 §10); handle missing plugins/maps gracefully |
| **Max version support** | Plan for new Max versions every year; keep the Max layer thin so ports are cheap (the reference added Max 2027 in 9.4.0 **[Doc]**) |

---

## 11. Diagnostics and statistics

Expose in the stats window and in a log:

- Candidates, accepted, **rejected per reason**, selected-vs-accepted per source.
- Per-stage times, tiles rebuilt vs reused, cache hit rates.
- Memory by category and peak temporary memory.
- GPU upload time and bytes.
- Warnings: no surface, no include area, candidate cap reached, >50% collision rejects, resolution too coarse for scale, renderer lacks capability, cycles refused.

Add a **"why isn't there a plant here?"** inspector: click a point, re-run the pipeline for that cell only, and show the first failing reason (`ExcludedByArea`, `CollisionLost` by which neighbor id, `SlopeLimit`, …). Reason codes are already stored (file 01 §2).

Continue with `05-product-tools-and-ui.md`.
