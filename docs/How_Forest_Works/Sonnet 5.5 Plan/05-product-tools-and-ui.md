# Cyrus Scatter — Rebuild Blueprint

## 05 · Product Layer: UI, Debug Views, Presets, Sets, Lister and Utilities

This file covers what the artist touches. The engine in files 01–04 does the work; this layer makes it understandable, debuggable and portable. Tags: **[Doc]** verified in iToo docs, **[Doc\*]** from your research notes (unverified), **[Prop]** my design.

---

## 1. UI principles

1. **Name controls by their visual consequence**, not by internal mechanism. "Cluster size" changes the size of species patches; it must not secretly change density.
2. **No ambiguous checkboxes.** Where one control hides two behaviors (disable = remove vs empty slot; collection = pool vs compound), split it into two explicit choices.
3. **Show what is happening.** Every rollout has a way to see its effect: overlays, previews, counters.
4. **Show why things disappear.** Rejection reasons, per-area contributions and a point inspector make the system explainable.
5. **Never lose work silently.** Mode changes, orphaned overrides, missing assets and refused cycles always produce a visible, recoverable state.
6. **Parity-first layout.** Reference users should recognize the rollout order; improvements appear as clearly labeled additions.

---

## 2. Rollout-by-rollout specification

The reference exposes these rollouts: Geometry, Distribution, Areas, Surface, Transform, Items Editor, Camera, Material, Effects, Animation, Shadows (legacy), Display, General **[Doc]**. Cyrus mirrors the order, drops Shadows (Tier D), and adds a Diagnostics tab.

### 2.1 General

- Seed (the deliberate "new variation" control), thread count, update mode (auto/manual), freeze, **statistics window** button, preset menu, **identity mode** (Cell / Legacy XY) under an "Advanced" foldout.
- Warnings summary (collapsible): shows the same list as the stats window.

### 2.2 Geometry (Sources)

| Element | Behavior |
|---|---|
| Source list | Name, thumbnail, weight, Color ID swatch, collision radius %, kind, **empty-slot toggle** |
| Add from scene / library / multiple | Supports groups, hierarchies, proxies |
| Per-source: Z offset, material override, include children, group mode (**Compound** / **Pool**) | Group mode wording is explicit |
| "Disable" replaced by two commands | **Exclude from selection** (redistribute weight) and **Keep as empty choice** (retain weight, emit nothing) |
| LOD set creation | Wizard: pick 2+ alternatives and thresholds |
| Statistics column | Selected vs accepted count per source |

### 2.3 Distribution

- **Mode selector:** Image, Path, Reference, Particle, Imported markers, (later) Min-distance.
- **Image:** bitmap/map picker, Use-as-Density-Map, X/Y Units, X/Y Pixels, Map Channel, Fit to Scene, Lock Aspect, Offset, Rotation, Threshold, Max Density, gizmo corners; live "candidates / empty positions" readout.
- **Diversity:** Random, Match Color ID (+Noise), Clusters (Size, Roughness, Blurry Edge, Noise). Cluster preview: toggle a flat species-color overlay.
- **Collisions:** global radius %, height %, display of spheres; readout "x% discarded" with a >50% warning.
- **Path / Reference / Particle:** their own sub-panels; share the Geometry list and collisions.

### 2.4 Areas

- **Ordered list** (drag to reorder; top-of-list semantic stated plainly: "processed bottom to top").
- Add buttons: Spline, Object, Forest/Scatter, Paint, Linked, Surface.
- Per area: On, Name, Include/Exclude, type-specific properties (Thickness, Force Open, Separate Sub-Splines, Top Limit, Resolution or target error, Scale, Shape, Projection axis), **Select Models** subset, **Random Scale by Area**, **Override Distribution Map** (scale/threshold/map), Material IDs, Boundary mode (Point/Size/Edge), Falloff (density/scale, include/exclude range, curve editor, invert, affect strength, affect-height-only).
- **Inline warnings:** "Surface include is active together with other includes — the whole terrain will fill"; "Exclude must be above an Include to affect it" (computed, not guessed); "Overlapping includes".
- **Paint tools:** Paint, Erase, brush min/max, pressure sensitivity, brush size, preview falloff, convert to spline / back; Ctrl = erase, Alt = paint while painting **[Doc]** (reference behavior).

### 2.5 Surface

- Surface list (simple meshes), Add/Add multiple/Get From Forest-equivalent ("Use surfaces of…"), update button + **Auto-update (default on)**.
- Mode XY / UV, UV transform (UV mode), projection axis, Direction (−100…+100), Scale to Fit (XY; disables Direction), Altitude range with falloff curves, Slope range, Material-ID filter.
- **Uniformity mode** (Cyrus addition): Projection / UV / World-area.

### 2.6 Transform

- Translation, Rotation, Scale (XYZ, lock aspect), Probability curves, Maps (grayscale / color map), Probability map, Mirroring, "Check boundary before/after translation".
- A small distribution preview under each curve showing histogram of sampled values from a stable test seed.

### 2.7 Items Editor (Overrides)

- Always-available edit tools (no mode switch): Select by type, Randomize source, Reset size, Re-seed, Store transform, Add (Model / Random / Sequence), Attach, Detach, Consolidate list.
- **Overrides panel:** counts of overrides, manual items, **orphans**, with policies (keep as manual / keep inactive / delete after confirm).
- **Compatibility button:** "Convert to Custom Edit-style baked items" for artists who want the reference workflow.

### 2.8 Camera

- Enable (render/viewport), FOV culling, Expand %, Back offset, Far clip, Facing camera, Distance falloffs (density, scale), LOD enable.
- Clear labels: *Culling*, *Density reduction*, *LOD* grouped separately. A line states whether each option is **output-stage** (no rebuild) or **camera-dependent** (rebuild).
- **Shot envelope** (Cyrus addition): frame range for union-frustum generation.

### 2.9 Material

- Tint (gradient/map), randomization strength, HSB correction, element vs instance mode, spatial field binding, **Optimize Materials** (idempotent; reports "n materials already optimized, skipped").

### 2.10 Effects

- Effect list with enable toggles; expression editor with syntax highlighting, error markers and **live dependency readout** ("reads: surface.slope, area.distInclude · writes: scale · slot: Pre"); auto-generated parameter UI; preset library of example effects.

### 2.11 Animation

- Mode (Disabled / Follow Geometry / Random Samples / Random From Map / Frames From Map), Count, Time Offset, Start/End, map slot, "Animate only at render time", cache budget and resident samples readout, renderer-capability warning.

### 2.12 Display

- Viewport: Mesh / Adaptive / Proxy (shape picker) / Point Cloud; point density (local and global), point size, shading; **Max viewport items** (stable subset).
- Render: Automatic / Meshes; **Simplification level**; Max items / Max faces; Hide source objects; manual update; disable; freeze.

### 2.13 Diagnostics (Cyrus addition)

- Stats table, per-stage timers, memory by category, cache hit rates, **Why-not-here inspector**, reason-code histogram, export log.

---

## 3. Debug views (four views that must never be confused)

Toggle independently so an error at one stage cannot masquerade as an error at another **[Prop]**:

| View | Shows |
|---|---|
| **Authored coverage** | Painted regions, spline interiors/corridors, exclusion masks, falloff gradients |
| **Generated candidates** | Every candidate position, colored by reason status (accepted / rejected + reason) |
| **Accepted instances** | The final population as points |
| **Displayed subset** | What the viewport actually draws after the preview cap |

Without these, a plant rejected by spacing looks like missing paint, and a preview cap looks like a generation bug.

**Point inspector.** Click a world point or an instance:
```
Instance 0x9F…A1  (Image, cell 1284,-317, receiver Terrain_A, hit 0)
Source: Birch B   selected-by: weighted  (u=0.41)
Generated by area: "Garden" (order 2)
Falloff: density 0.82, scale 0.9
Overrides: none
Status: Accepted
```
or for an empty point: `Candidate 0xC3… rejected: CollisionLost vs instance 0x5A… (distance 0.42 m < r 0.55 m)`.

---

## 4. Shared sets (collections of scene inputs)

### 4.1 Reference [Doc\*]

A set is a reusable container of scene objects used as source geometry, surfaces, spline areas, reference objects, paths or particle inputs; it can consume scene layers and supports nested collections with restrictions. In Geometry use **it chooses one member**; in surface and spline uses it consumes the **whole collection**.

### 4.2 Cyrus design [Prop]

Do not build one generic container whose behavior changes invisibly. Provide **role-specific sets** over one implementation:

| Set type | Role | Semantics |
|---|---|---|
| **Variation set** | Source pool | Chooses one member (weighted) |
| **Receiver set** | Surfaces | Consumes all members |
| **Region set** | Spline/paint areas | Consumes all members |
| **Marker set** | Reference inputs | Consumes all members |
| **Compound** | Arrangement | One source made of several parts |

- Membership by explicit list **or** by scene layer (dynamic) **or** by selection set.
- **Cycle detection** before evaluation (a set containing a scatter that depends on the set).
- A set carries a revision; consumers re-run only affected tiles when it changes (file 01 §6.4).
- Manual **update** and **auto-update** options after layer changes (the reference added both in 9.3.3 **[Doc]**).

---

## 5. Linked areas and shared inputs

Linked areas (borrow an area from another scatter) let one master path or boundary drive many scatters while each keeps its **own response** **[Doc]**:

```
Shared path boundary (master)
   → grass exclusion with narrow transition
   → shrub exclusion with wide setback
   → flowers concentrated along the edge
```
The boundary is shared; the response is local (falloff stays local **[Doc]**). Moving the path updates every dependent scatter, but only the affected tiles. Not every area type can be linked as every operation (a linked Object area can only exclude **[Doc]**); enforce and message this in the UI.

---

## 6. Presets, libraries and portability

### 6.1 Reference [Doc / Doc\*]

A Library Browser holds meshes, billboards and **complete configured Forest objects**; parameter presets store settings but **not all external scene references**; recent versions add **portable files that contain geometry** **[Doc\*]**; update manager downloads content separately from the plugin **[Doc]**; relinking textures to the library path and a configurable assets folder (including network paths) were added in 9.3.3 **[Doc]**.

### 6.2 Cyrus: three distinct levels [Prop]

| Level | Contains | Used for |
|---|---|---|
| **Asset** | Geometry, materials, textures, LOD sets, proxies | Library items |
| **Recipe** | Distribution, source *list structure*, area *templates*, transform/effect settings, falloff curves — no scene refs | Reusable "look" |
| **Scene setup** | Recipe + actual scene references (splines, terrains, markers) | Full reproducibility in a project |

Requirements:
- **Versioned**, with migration.
- **Missing-asset recovery:** a preset referencing models on a network drive must never silently substitute unrelated geometry. Show a resolve dialog (relink, replace, ignore).
- **Portable package:** one file bundling geometry and textures with relative paths for handoff.
- **Texture relinking** option to the library path, with UNC conversion for network pipelines **[Doc]**.
- **Thumbnails** and tags; search by name/tag; a safe "preview without applying" mode.
- Content is **your own** (clean-room; file 00 §10).

---

## 7. Manager (Lister)

A scene-level table for managing many scatters at once **[Doc\*]**: list all scatter, set, LOD and plant-generation objects (the reference added Ivy/Set/LOD to its Lister in 9.4.0 **[Doc]**), with per-row toggles for viewport/render, display mode, density multipliers, seed, update state, **filter by layer or name**, bulk actions (freeze, disable, set display mode, set point density), and dependency view (who depends on whom; refused cycles flagged).

Add: a column for **memory** and **rebuild time**, and a "heaviest scatters" sort.

---

## 8. Utility tools

| Tool | Behavior | Notes |
|---|---|---|
| **Convert to native instances** | Bake accepted instances to standard Max instances/meshes for downstream workflows **[Doc\*]** | Warn on counts; chunk the operation; keep the scatter intact |
| **Convert paint ↔ spline** | See file 02 §E.4 | Undoable |
| **Bake overrides** | Freeze selected overrides into manual items | |
| **Merge/split scatter** | Attach/detach with consolidation of source lists | |
| **Re-seed copy** | Duplicate a scatter with a new `scatterGuid` | Intentionally changes look |
| **Statistics export** | CSV/JSON of counts, timings | For regression tracking |

---

## 9. Out-of-scope products (track separately)

- **Climbing-plant generator** (guided growth, branches, leaves, wind) **[Doc]** — separate product; build only after the scatter engine is stable.
- **Legacy shadow tools** (billboard shadows, scanline/mental-ray era) **[Doc\*]** — not part of a modern mesh-scatter pipeline; revisit only if customers need billboard sources.
- **Built-in billboard/template library** — Tier C at most.

---

## 10. Documentation and onboarding

- A "first scatter in 5 minutes" scene shipped with the product (own assets).
- **Per-control reference** pages generated from the behavior records in file 06 (purpose, inputs, units, combination rule, identity behavior, dependencies, persistence, viewport vs render, limits, evidence level).
- A **troubleshooting page** keyed to the stats warnings (">50% discarded", "whole terrain filled", "items outside the area after translation", "edge mode not showing in viewport").
- Version-aware notes where behavior differs between releases (for example UV-surface area support changed between major versions in the reference **[Doc]**).

Continue with `06-testing-parity-and-milestones.md`.
