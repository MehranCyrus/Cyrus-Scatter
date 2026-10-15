# Cyrus Scatter: Build Specification

A complete, implementation-level design for rebuilding the Forest Pack feature set as **Cyrus Scatter**, a C++ plugin for Autodesk 3ds Max. Written to be read *before* coding: each file explains what to build, how it works, why it's designed that way, and how it connects to everything else.

Companion to the ClickUp guide "Forest Pack, Decoded: A Replicator's Guide for Cyrus Scatter", which explains Forest Pack's behavior. These files explain how *we* build it.

---

## The system in one picture

```text
   3ds Max scene                                   3ds Max outputs
 (surfaces, splines,                             (Nitrous viewport,
  paint, sources, camera)                          renderers, bake)
        |                                                 ^
        v                                                 |
 [L4 Max adapter] params, references, UI, edit modes      |
        |                                                 |
 [L3 Snapshot builder]  main thread, time t               |
        |  immutable SceneSnapshot                        |
        v                                                 |
 [L2 Core engine, no Max headers, multithreaded]          |
   S1 Generate  -> S2 Surface -> S3 Areas -> S4 Falloff   |
   -> S5 Density -> S6 Model -> S7 Transform              |
   -> S8 Boundary -> S9 Collisions -> S10 Edits/Effects   |
   -> S11 Shading payload -> S12 Publish                  |
        |  immutable PublishedPopulation (versioned)      |
        v                                                 |
   V  View pass per camera: frustum, LOD, budgets --------+
 [L1 Output adapters] viewport instancing, point cloud,
                      render-time instancing, bake, export
```

Three rules hold it together:
1. **The core never touches Max.** Everything is snapshotted first. That's what makes it testable, thread-safe and fast.
2. **Every random value is `hash(seed, stableKey, purpose)`.** No shared random streams. Results never depend on thread count, evaluation order, or unrelated edits.
3. **Populations are outputs, never saved truth.** The truth is parameters, references, paint strokes, overrides and manual items.

---

## Files

| # | File | What it covers | Stages |
|---|---|---|---|
| 00 | [00_ARCHITECTURE.md](00_ARCHITECTURE.md) | Master design: layers, core types, pipeline contract, threading, caches, persistence, **decisions log** | all |
| 01 | [01_CORE_SERVICES.md](01_CORE_SERVICES.md) | StableRNG and keys, surface BVH, 2D boundary service, raster masks, spatial hash and deterministic collisions, map sampler, job system, cache registry, math | services |
| 02 | [02_PLUGIN_SHELL.md](02_PLUGIN_SHELL.md) | GeomObject plugin, ParamBlock2 layout, references and notifications, snapshot builder, create modes, Geometry List, library and presets, UI, save/load/undo | S0 |
| 03 | [03_GENERATORS.md](03_GENERATORS.md) | Image-mode pixel lattice, distribution map library, density thinning, Path, Reference, Particle Flow, manual items | S1, S5 |
| 04 | [04_SURFACES_AREAS.md](04_SURFACES_AREAS.md) | Surfaces (XY/UV, Direction, slope/altitude/MatID), the ordered Area Program, every area type, boundary checks | S2, S3, S8 |
| 05 | [05_FALLOFF_PAINT.md](05_FALLOFF_PAINT.md) | Density/scale falloff, curves, multi-area combination, Paint Areas on the existing Cyrus stroke engine | S4, S5, paint |
| 06 | [06_DIVERSITY_COLLISIONS.md](06_DIVERSITY_COLLISIONS.md) | Geometry table, probability, Color ID matching, Clusters, collisions and priority policies | S6, S9 |
| 07 | [07_TRANSFORMS_ANIM_MATERIAL.md](07_TRANSFORMS_ANIM_MATERIAL.md) | Transform composition, random ranges, probability curves, transform maps, animation samples, tint, Cyrus Color shading math | S7, S11 |
| 08 | [08_CAMERA_DISPLAY.md](08_CAMERA_DISPLAY.md) | View pass, camera culling and falloff, LOD, viewport modes, point cloud, budgets, Nitrous, hit testing, debug overlays | V, viewport |
| 09 | [09_RENDER.md](09_RENDER.md) | Render-time instancing, per-instance data, aggregate mesh fallback, Edge mode, renderer adapters, bake tool, export | render |
| 10 | [10_EDITING_SCRIPTING.md](10_EDITING_SCRIPTING.md) | Custom Edit with stable overrides and manual items, undo, Effects language and VM, MAXScript interface | S10 |
| 11 | [11_TESTING_ROADMAP.md](11_TESTING_ROADMAP.md) | Test strategy, determinism, golden hashes, benchmarks, Forest Lite comparison scenes, milestones M0 to M10, risk register | all |

---

## How to read this

**To understand the system** (first pass, about 2 hours): 00 fully, then the first three sections of each feature file (purpose, Forest behavior, parameters). That gives you the whole map.

**To start coding**: 00 again, then 01 and 11 together (services plus the M0 test harness), then follow the milestone order in 11: 03 and 04 (lattice, surfaces, areas), 08 (point cloud so you can see results), 06 and 07, 09, 05, 10.

**Labels used everywhere**:
- `[FP-DOC]` Forest Pack behavior documented by iToo (we match it on purpose)
- `[FP-OBS]` Forest behavior seen in tutorials or forum replies (match it, verify in Forest Lite first)
- `[DESIGN]` our decision, not a claim about Forest internals
- `[OPEN]` needs a Forest Lite test scene or profiling before it's frozen (11 lists one test per open item)

**If two files disagree**, 00 wins, and its section 15 "Decisions log" records every cross-file resolution (for example D1: overlapping Include areas union, and lattice keys belong to distribution frames, not areas).

---

## The milestone path (from 11)

| Milestone | You can demo |
|---|---|
| M0 | Services, test harness, recorded-snapshot benchmarks, determinism checks |
| M1 | Lattice scatter on an XY surface, point cloud viewport |
| M2 | Ordered include/exclude areas, Point/Size boundary |
| M3 | Geometry List and randomized transforms |
| M4 | Native render instancing |
| M5 | Falloff, Object/Forest areas, slope/altitude/MatID filters |
| M6 | Collisions, clusters, camera culling |
| M7 | Paint Areas and Custom Edit with stable overrides |
| M8 | Path, Reference, PFlow, animation samples, tint |
| M9 | Effects, library/presets, bake tool, UV mode, Edge mode |
| M10 | Hardening and compatibility release |

---

## Honest limits

- Forest Pack's private internals (hashes, exact stage order, collision priority, cluster algorithm, falloff combination) aren't public. Where these specs need them, they make an explicit `[DESIGN]` choice and mark it `[OPEN]` for comparison against Forest Lite.
- 3ds Max SDK class and method names were checked against Autodesk's online docs where possible. Exact signatures vary by Max version: verify against your SDK headers before relying on any signature.
- Performance targets are design goals, not measurements. The M0 benchmark harness exists to replace them with real numbers.
