# Cyrus Scatter — Rebuild Blueprint

## 00 · Overview, Principles, Scope and Roadmap

This is the first of seven documents. Together they explain **how to build a Forest-Pack-class scattering system from scratch**, what it should look like internally, and in what order to build it. Read this file first; it tells you how the others fit together.

| File | What it covers |
|---|---|
| `00-overview-and-roadmap.md` | Vision, principles, parity-vs-improvement, scope tiers, roadmap, risks, open decisions |
| `01-architecture-and-data-model.md` | Layers, core data types, stable identity, randomness, pipeline, invalidation, tiling, threading, persistence |
| `02-placement-engine.md` | Sources, distribution providers, surfaces, areas, paint, falloffs, boundaries, collisions |
| `03-transforms-editing-effects.md` | Transforms, probability curves, overrides / item editing, effects language, materials, animation |
| `04-viewport-rendering-performance.md` | Viewport, point cloud, render backends, camera, LOD, memory budgets, 3ds Max SDK constraints |
| `05-product-tools-and-ui.md` | Rollout-by-rollout UI, debug views, presets, sets, lister, libraries, utilities |
| `06-testing-parity-and-milestones.md` | Behavioral reference suite, automated tests, benchmarks, milestone task lists |

---

## 1. How to read the evidence tags

Every behavioral statement is tagged so you always know how much to trust it.

| Tag | Meaning |
|---|---|
| **[Doc]** | Stated in iToo's official documentation, which I read directly (Image Mode, Areas, Surface, Transform, Items Editor, Display, Animation pages and the 9.4.x changelog). |
| **[Doc\*]** | Stated in your two research notes, but **not** independently verified by me. Verify before depending on it. (Examples: Effects attribute names, Camera rollout details, Reference/Path mode details, 9.4.1 features.) |
| **[Inf]** | A reasonable inference from documented behavior. Probably right, not guaranteed. |
| **[Prop]** | A design **I propose for Cyrus**. It is not a claim about how Forest Pack works. |
| **[Test]** | Unknown. Must be answered by a controlled experiment (see file 06) before you finalize the behavior. |

Nothing here comes from Forest Pack's source code. Everything is built from public documentation, observable behavior, and original engineering.

---

## 2. What we are building

**Cyrus Scatter** is a procedural instancing system for 3ds Max. Given source objects (trees, grass, rocks, props), surfaces to place them on, and regions that say where they may appear, it generates very large populations (hundreds of thousands to millions of instances), keeps them editable and stable as the artist iterates, previews them interactively, and hands them to the renderer without duplicating geometry.

It has four deliverable layers:

1. **Core library** — a host-independent C++ engine: placement, constraints, randomness, caching, invalidation. No 3ds Max headers. Fully unit-testable and runnable from a command line.
2. **3ds Max host layer** — scene objects, parameter blocks, undo, viewport drawing, painting, snapshotting scene data into the core.
3. **Render backends** — one adapter per renderer that turns the core's accepted-instance buffer into native instances, materials and per-instance data.
4. **Product layer** — UI rollouts, libraries/presets, shared sets, manager (lister), diagnostics, documentation.

The most important structural decision is that layers 1 and 3 never depend on each other directly. The engine produces **data**; backends **consume** data.

---

## 3. Design principles (the rules every later decision must obey)

1. **Placement record ≠ displayed object.** An instance is a small row of data (id, source, transform, attributes). It is never required to be a 3ds Max node. This is what makes millions of instances possible and lets every output (viewport, picking, render, export) read the same truth.
2. **One shared pipeline, many providers.** Image, Path, Reference, Particle and imported-marker modes are *providers of candidates* feeding the same downstream stages (areas, surfaces, source selection, transforms, collisions, output). Never build a separate scatter engine per mode.
3. **Deterministic, keyed randomness.** Every random value is a pure function of `(seed, stable id, channel)`. No mutable global random stream. Changing tint must not change rotation; adding a source must not reshuffle positions. (Details: file 01 §4.)
4. **Provenance everywhere.** Each candidate remembers which generator and which area produced it, and each rejected candidate gets a reason code. This powers correct area semantics, the stats window, and a "why isn't there a plant here?" tool.
5. **Declared dependencies.** Every stage and every user-visible parameter declares what it reads and writes. The scheduler recomputes only what a change can affect. Changing a flower tint must never re-solve tree collisions.
6. **Incremental must equal full.** A fast local update that disagrees with a full rebuild is a **correctness bug**, not an optimization. This is enforced by automated property tests (file 06).
7. **Snapshot → compute → publish.** Workers never touch the live 3ds Max scene. They compute from immutable snapshots and publish atomically; stale results are discarded by revision check.
8. **Explicit semantics over ambiguous checkboxes.** "Disable" must say whether it *removes from selection* or *leaves an empty slot*. "Collection" must say whether it is a *selection pool* or a *compound arrangement*. Ambiguity in the UI becomes support tickets.
9. **Parity first, then improvement — and label which is which.** Reproduce artist-visible behavior of the reference product, then add improvements deliberately (section 4).
10. **Everything measurable.** Candidate counts, rejection counts per reason, per-stage times, cache hit rates, memory by category — exposed in a stats window from the first milestone.

---

## 4. Parity versus improvement

Several of the best ideas in your research notes are **not** things Forest Pack does. Mixing them up leads to wrong test expectations. This table separates them.

| Area | Reference behavior | Cyrus target | Type |
|---|---|---|---|
| Random seeding | Seeded from each item's **XY position**; stacked items share properties unless "Randomize Stacked" is on **[Doc]** | Seed from stable identity + channel; optional legacy XY-seed mode for parity experiments | Improvement + parity switch |
| Manual editing | Separate **Custom Edit** mode; switching warns about losing changes; **areas unavailable in Custom Edit** **[Doc]** | Sparse override layer on top of procedural generation; no mode switch needed | Improvement |
| Terrain change | Does **not** auto-update; user presses update (or ticks Auto); the surface table is shared across Forest objects **[Doc]** | Revision-tracked surface cache with automatic, incremental invalidation | Improvement |
| Viewport limit | "Max Items" adjusts the **density** of the distribution to stay under the cap **[Doc]** | Stable preview subset chosen by hash of id, so raising quality only *adds* instances | Improvement |
| Collisions | Scatter first, then delete colliding items using bounding spheres; stats warn when >50% discarded **[Doc]** | Same visible results, but order-independent deterministic winner rule; optional minimum-distance sampling to avoid wasted candidates | Parity + improvement |
| Areas | Processed bottom-to-top; an exclude only affects areas below it **[Doc]** | Same semantics, implemented as an ordered operation list (not one flattened mask) | Parity |
| Slope on XY | Not density-compensated; "Scale to Fit" scales item **width** with slope **[Doc]** | Same default; optional world-area density compensation | Parity + optional improvement |
| Boundary check | Point / Size / Edge; Edge is per-element, computed at render time, not previewed by default **[Doc]** | Same three modes; Edge requires renderer/material integration | Parity |
| Animation | Discrete sample start-frames (Count × Time Offset); some renderers fall back to Follow Geometry **[Doc]** | Same model, bounded sample cache keyed by (source, time sample) | Parity |
| Camera effects | Some options trigger rebuilds on viewport change **[Doc]** | Culling/LOD/camera density applied as **output-stage filters** with stable thresholds, no regeneration | Improvement |
| Diagnostics | Basic stats window with warnings **[Doc]** | Per-reason rejection counters, per-stage timers, provenance inspector | Improvement |

---

## 5. System at a glance

```
                    ┌───────────────────────────── 3ds Max host layer ─────────────────────────────┐
 Scene (nodes,      │  Snapshotter → immutable scene snapshot (meshes, splines, maps, camera, ...)   │
 meshes, splines,   │  Param blocks / UI / Undo / Paint tool / Viewport drawing / Picking            │
 maps, camera)      └──────────────┬──────────────────────────────────────────────▲─────────────────┘
                                   │ snapshot + settings revision                  │ publish (atomic)
                    ┌──────────────▼──────────────────────────────────────────────┴─────────────────┐
                    │                              CORE ENGINE (no Max headers)                       │
                    │                                                                                 │
                    │  Source Registry     Spatial Fields       Surface Cache       Override Store    │
                    │        │                  │                    │                    │          │
                    │  Providers ─► Candidates ─► Surface resolve ─► Area stack ─► Source select ─►   │
                    │  (Image/Path/   (SoA)        (BVH / UV idx)    (ordered ops)   (weights,        │
                    │   Reference/                                                    clusters)       │
                    │   Particle/                                                                     │
                    │   Imported)    ─► Transform ─► Effects(pre) ─► Boundary ─► Occupancy ─► Overrides│
                    │                                                (collisions)                     │
                    │                                    ─► Effects(post) ─► Accepted Instance Buffer │
                    └──────────────┬──────────────────────────────────────────────────────────────────┘
                                   │ read-only views of the Accepted Instance Buffer
        ┌──────────────┬───────────┴───────────┬──────────────────┬───────────────────┐
        ▼              ▼                       ▼                  ▼                   ▼
   Viewport       Picking / Edit        Render backend       Export / Bake      Statistics &
   (points,       (selection             (V-Ray, Corona,      (convert to        debug overlays
    boxes, mesh)   structures)           Arnold, Meshes)      Max instances)
```

---

## 6. Scope tiers

**Tier A — Core scattering (must exist for the product to be usable)**
Source list with weights and an explicit empty slot; Image distribution with tiling, threshold, density map, max-density guard; Random / Color-ID / Cluster diversity; surfaces in XY mode with slope, altitude, direction; ordered areas (spline, surface, object, forest, paint) with include/exclude; falloffs; Point/Size boundaries; sphere collisions; transform randomization with probability curves and maps; viewport point cloud + proxy + mesh; a "Meshes" render path that works in any renderer; statistics.

**Tier B — Production completeness**
UV surfaces; material-ID filtering; linked areas; per-area overrides (source subset, scale, distribution map); paint with undo and paint↔spline conversion; Path, Reference and Particle providers; override layer / item editor; renderer-native instancing for V-Ray, Corona, Arnold; tint and per-instance color; camera culling and LOD; animation modes; presets, sets, lister; Edge boundary mode.

**Tier C — Advanced**
Effects expression system; cross-scatter dependencies at scale; incremental tiled recompute; animation sample caching; camera-motion envelope for shots; portable scatter files with geometry; imported-marker adapters (e.g. exported linear-array segments).

**Tier D — Deliberately out of scope for now**
Procedural ivy/climbing-plant generation (a separate product in the reference suite **[Doc]**); legacy billboard-shadow machinery and obsolete renderer integrations (the reference documents these as legacy **[Doc\*]**). Track them as separate deliverables so "replicate Forest Pack" stays a defined scope rather than an open-ended one.

---

## 7. Roadmap summary

Full task lists are in file 06. The order is chosen so that **a complete, testable vertical slice exists early**, and every later milestone extends something already proven.

| # | Milestone | Outcome | Size |
|---|---|---|---|
| M0 | Recon & decisions | Audit existing Cyrus code against the architecture; decide SDK versions, renderers, targets | S |
| M1 | Core foundations | IDs, keyed RNG, SoA buffers, field interfaces, tile scheduler, stats, headless test harness | L |
| M2 | **Vertical slice** | Image distribution → XY surface → spline include/exclude → Point/Size boundary → sphere collisions → point-cloud viewport → "Meshes" render. First parity tests pass | L |
| M3 | Areas & surfaces complete | Ordered stack with provenance, object/forest/linked areas, falloffs, UV mode, slope/altitude/direction/scale-to-fit, material IDs, per-area overrides | XL |
| M4 | Painting & incremental updates | Paint areas, stroke pipeline, tiled coverage, undo, paint↔spline, dirty-tile recompute proven equal to full rebuild | XL |
| M5 | Population intelligence | Color-ID and cluster diversity, full transform system, probability curves, maps, override layer / item editor | L |
| M6 | Providers | Path, Reference, Particle, imported-marker adapters sharing the pipeline | L |
| M7 | Renderers & materials | Native instancing (V-Ray first), tint/color system, Edge mode, camera culling, LOD | XL |
| M8 | Effects & animation | Expression engine with dependency analysis; animation modes and sample cache | L |
| M9 | Product completion | Presets, sets, lister, libraries, diagnostics, docs, file-format compatibility, regression coverage | L |

Size is relative effort (S < M < L < XL), not calendar time, because team size is unknown.

**The vertical slice (M2) is the most important checkpoint.** If its architecture feels wrong, everything later gets more expensive. Do not start M3+ until the slice demonstrates: deterministic output, a correct incremental update for a single parameter change, and a working render path.

---

## 8. Reference product defaults to use as benchmark targets

These are documented defaults of the reference product. Use them to size your own limits and to build comparison scenes.

| Item | Reference value | Source |
|---|---|---|
| Image mode max candidate positions | 10 million (counts empty positions too) | **[Doc]** Image Mode |
| Distribution collision warning | Stats warn when >50% of items are discarded | **[Doc]** Image Mode |
| Object/Forest exclusion bitmap resolution | 512 px | **[Doc]** Areas |
| Viewport item cap | 500,000 items; adaptive display above 100,000 faces | **[Doc]** Image Mode |
| Point-cloud budget | 250,000 points per object, cached on GPU until the object changes | **[Doc]** Display |
| Render item / face cap | 1,000,000 items / 5 million faces (an "F" placeholder is built when exceeded) | **[Doc]** Display |
| Animation sample cache | ~10 GB, oldest samples evicted | **[Doc]** Animation |
| Latest release verified | 9.4.3, 2026-09-08 (fixes only) | **[Doc]** changelog |

---

## 9. Top risks

| Risk | Why it matters | Mitigation |
|---|---|---|
| **Renderer integration** | Native instancing, per-instance data and Edge cutout are separate SDK problems per renderer; the reference product uses renderer-native shaders **[Doc]** | Ship the universal "Meshes" backend first; add backends one at a time behind a capability interface; prototype each renderer's per-instance data path *before* committing UI |
| **3ds Max SDK threading** | The SDK is generally not thread-safe **[Doc\*]** | Snapshot-only workers; no scene calls off the main thread; thread-sanitizer CI |
| **Incremental correctness** | Greedy collision solving can propagate beyond an edit | Fixed-point local re-solve with expansion; property test comparing incremental to full rebuild |
| **Determinism across thread counts** | Parallel generation can change order and results | Priority from id hash, never from arrival order; test at 1/4/32 threads |
| **Paint history cost** | Evaluating every old stroke per preview point scales with history | Tiled coverage cache + stroke checkpointing; strokes remain only for undo |
| **UV distortion / seams** | Equal UV area ≠ equal world area | Explicit "uniform in UV" vs "uniform per area" modes; seam tests |
| **Scope creep** | "Replicate everything" blends several products and generations | Tier system above; separate deliverable tracking |
| **Unknown evaluation order** | Docs don't specify every ordering rule | Behavioral reference suite (file 06) before locking semantics |

---

## 10. Clean-room and legal notes

Observing behavior and writing your own implementation is normal engineering, but protect yourself:

- Read the reference product's license/EULA about reverse engineering and decompilation. **Do not decompile, disassemble or inspect binaries.** Use documentation, public tutorials, and black-box tests of a legitimately licensed copy.
- Write your own distribution maps, presets, library assets and icons. Do not copy the reference product's bundled content, UI artwork, or documentation text.
- Choose your own parameter and attribute names. Add compatibility aliases only after a legal review.
- Keep written notes separating **observed behavior** (allowed input) from **your implementation** (original work).

I am not a lawyer; have one review the EULA and your distribution plan.

---

## 11. Open decisions (answer these in M0)

1. **Existing codebase:** what already exists in Cyrus (engine, Surface Analyzer, CS Edit)? Which pieces map onto which layer?
2. **Target 3ds Max versions** and the matching SDK versions (the reference added Max 2027 support in 9.4.0 **[Doc]**).
3. **Renderers in priority order** (V-Ray, Corona, Arnold, others) and which versions.
4. **Persistence compatibility:** must scenes round-trip old Cyrus files?
5. **Identity mode default:** stable-cell identity (recommended) versus Forest-style XY seeding.
6. **Team and CI:** how many developers, which compilers, can CI run Max headless or only the core library?
7. **Legal review** of the reference product's license before behavioral testing begins.

Continue with `01-architecture-and-data-model.md`.
