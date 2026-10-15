# 01 — Product scope, parity definition and system requirements

## 1. Define what "fully rebuild" means

The requested outcome is an **artist-directed, procedural, 3ds Max-native scattering system** capable of independently reproducing the *workflows and behaviors* documented for ForestPack's principal scatter features, plus selected improvements. It is not a byte-for-byte clone of its algorithms, file formats, shaders or UX.

Scope categories:

| Category | Requirements | Priority |
|---|---|---|
| Core Forest-type scatter | Geometry list; image/path/reference/particle inputs; area stack; surfaces; source choice; transforms; collisions; falloffs | P0/P1 |
| Art direction | Painted include/exclude areas, spline boundaries, local region overrides, manual editing, grouping, linked regions | P0/P1 |
| Runtime scale | Shared geometry data, multi-threaded evaluation, deterministic caching, GPU-friendly preview, native instancing | P0 |
| Output | Viewport, selection, Arnold/Corona/V-Ray via verified adapters; LOD, camera limits, coloring, animation | P1/P2 |
| Procedural extensions | Effects, user parameters, reusable fields, inter-scatter references | P2 |
| Workflow ecosystem | Scene manager, presets/libraries, exports, migration, scripts and diagnostics | P1/P2 |
| Beyond core scatter | Ivy/growth tools, legacy billboard shadows, RailClone-specific protocol, niche non-geometry scene types | P3, explicit projects |

`P0` = prerequisite foundation; `P1` = complete everyday landscape workflows; `P2` = advanced parity; `P3` = specialized/legacy extensions.

## 2. Functional parity levels

A control is not done merely because a UI widget exists. Assign one of:

- **L0 — Documented:** intent/semantics recorded with public source and version.
- **L1 — Operable:** behavior implemented in an isolated test.
- **L2 — Interoperable:** combinations with neighboring controls behave consistently.
- **L3 — Durable:** save/load, Undo/Redo, scene clone, reference deletion, and asset failure handled.
- **L4 — Scalable:** validated on reference scenes with measured timing, memory, correctness and output parity.
- **L5 — Production verified:** shipped/adopted on supported Max/render-engine versions with regression coverage.

Never use a binary "feature implemented" status in the tracker. Include `parityLevel`, `evidence`, `targetVersion`, `knownDifferences`, and `testIds`.

## 3. Representative artist stories

1. Artist drags six grass variants into the source list, paints a lawn, and gets deterministic live preview.
2. Artist excludes a curved path, makes grass shorter at the border, then moves the path; only affected plants change.
3. Artist creates four splines, each with a different source subset and density; reordering areas changes coverage predictably.
4. Artist puts trees on a steep terrain and uses slope/altitude filters, preserving correct axes and world units.
5. Artist changes species probabilities without unintentionally reshuffling all surviving candidate positions.
6. Artist manually adjusts twenty hero trees and can later change global density without silently losing edits.
7. Artist references CAD markers, resizes/repositions them, and sees source instancing update while preserving marker-based identity.
8. Artist uses one tree population to influence the grass underneath it, with explicit one-way dependency and cycle detection.
9. Artist navigates a multimillion-instance environment without camera movement forcing a full scatter rebuild unless requested.
10. Artist exports a render with source tint, renderer-native instances and correct asset bindings after reopening the scene.

## 4. Correctness requirements

**C-01 Determinism:** Same normalized input data, schema version, engine version, and seeds => identical accepted-instance IDs/attributes within declared floating-point tolerances. Thread count must not change semantic results.

**C-02 Stable edits:** ID retention policy documented for density, transform, source change, path resampling, tile boundaries, mesh deformation/topology change and random-seed changes.

**C-03 Spatial correctness:** ordered inclusions/exclusions, local overrides, falloffs, XY/UV surface projection and collision radius behavior have golden fixtures.

**C-04 Complete transactions:** a paint drag, group edit, bulk source replacement and preset load each form coherent reversible Undo units.

**C-05 Persistence:** orphan scene-node references, missing sources, unknown schema fields, corrupt external caches and incompatible plugin versions do not silently destroy authored data.

**C-06 Render integrity:** preview limitations are distinguished from render limitations; renderer support is capability-based, with warnings for degradation.

**C-07 Safe threading:** 3ds Max scene object access follows verified SDK restrictions; workers receive owned snapshots rather than dereference `INode*` or mutable `Mesh*`.

## 5. Nonfunctional requirements (proposed targets, to calibrate)

Do **not** confuse targets with existing performance. Establish baseline on a specified workstation and scene package before setting release criteria.

| Measure | Initial aspirational gate | Measurement condition |
|---|---|---|
| UI brush cursor | Responsive to display refresh, independently of rebuild | Main-thread UI trace |
| Incremental paint preview | P95 under ~100 ms for small patches on representative scene | 200 strokes, warm caches, target workstation |
| Viewport navigation | No candidate regeneration for pure camera orbit when no camera-dependent controls | Dirty-stage counters |
| 1M accepted records | Bounded memory, no per-instance Max nodes | Peak RSS/working set and GPU allocations |
| Save/reopen | Byte-equivalent authored intent; deterministic reevaluation | Round-trip fixtures |
| Incremental correctness | Same semantic state as full rebuild | Differential comparison across seeds |
| Engine fault behavior | Cancellation, fallback and graceful errors without corrupting scene | Fault injection |

The 100 ms target is **proposed**, not guaranteed. Benchmark actual complexity and adjust after initial prototypes.

## 6. Compatibility policy

Maintain a support matrix indexed by:

- 3ds Max version and corresponding SDK/toolset
- Render engine and version (Arnold, Corona, V-Ray, default host render path)
- Distribution mode (Image/Path/Reference/PFlow/external)
- Area type (Spline/Object/Scatter/Paint/Surface/Linked)
- Surface mode (XY/UV), coordinate space and transformation
- Renderer-dependent boundary/material/animation features
- Device capability (viewport graphics API/GPU limits)

A feature can be `native`, `supported-with-fallback`, `render-only`, `preview-only`, `unsupported`, or `unverified` for any combination.

**[FP-DOC]** ForestPack documents area restrictions in UV mode, render-specific Edge treatment, mode-specific camera behavior, and renderer limitations for sampled animation. Do not flatten these into one global support checkbox.

## 7. Decision policy for matching ForestPack

- Reproduce artist-visible semantics when documented and useful.
- Prefer a clearer implementation over internal imitation when internal details are unknown.
- When ForestPack documentation conflicts across historical versions, record versions and run reference tests.
- Avoid copying ForestPack UI assets, names/branding that could confuse product identity, copyrighted library content or proprietary code.
- Mark an intentional Cyrus improvement as a **difference**, not undisclosed parity. Example: persistent manual overrides improve on the documented Generate/Custom Edit switching model.

## 8. What we must audit before touching existing Cyrus code

Collect module map; C++/MAXScript interfaces; current scatter data store; existing source/area/paint APIs; scene serialization format; threading assumptions; render backends; CS Edit integration; Cyrus Surface Analyzer integration; performance profiles; tests; customer scene compatibility. This document cannot assert those details because the current repository was **not inspected**.

## Deliverable from this chapter

A versioned backlog where every requirement has an owner, references, design decision, implementation status, parity level, regression tests and supported combinations. Continue with `02_ARCHITECTURE.md`.
