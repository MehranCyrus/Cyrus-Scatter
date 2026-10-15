# 11: Testing Roadmap

## 1. Purpose and scope

This document defines how Cyrus Scatter becomes trustworthy before feature parity is claimed. It extends `00_ARCHITECTURE.md` sections 1, 4, 7, 8, 10, 12, and 13. It covers core tests without Max, golden population hashes, determinism, property and fuzz testing, Max integration through MAXScript, performance measurement, Forest Lite comparison scenes, milestones M0 to M10, and the top technical risks.

The test strategy follows the architecture's central contract: an immutable `SceneSnapshot` enters pure C++20 stages S1 through S12, a `Population` is SoA and flags are not erased until S12, StableKey identity is independent of thread scheduling and density, and Max is confined to snapshot construction and adapters. Tests must therefore distinguish three outputs:

1. Authored state: parameters, references, geometry entryIds, areas, paint, overrides, ManualItems, Effects source, and `algoVersion`.
2. Procedural output: the canonical PublishedPopulation and its per-item channels.
3. View output: camera-dependent ViewMask and renderer payload.

A test that compares only a viewport image can miss identity changes, orphaned overrides, collision order changes, or a broken render payload. Every comparison scene exports structured channels and a metadata manifest before image comparison.

The comparison suite uses the evidence collected in the Forest notes, including the [distribution reference](https://docs.itoosoft.com/forestpack/forest-plugin/distribution), [areas reference](https://docs.itoosoft.com/forestpack/forest-plugin/areas), [surface reference](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces), [image mode reference](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode), [path mode reference](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode), [reference mode reference](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode), [display reference](https://docs.itoosoft.com/forestpack/forest-plugin/display), [Effects attributes](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/attributes), [Effects syntax](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/effects-syntax), and [Forest Tools export](https://docs.itoosoft.com/forestpack/instantiating-and-exporting/forest-tools). Forum and release-note observations about one-way Custom Edit, unstable Generate indices, deterministic exclusions, and approximate Max Items remain labeled [FP-OBS] in the comparison records.

Labels in this file have the architecture meaning: [FP-DOC] documented Forest behavior, [FP-OBS] observed behavior, [DESIGN] Cyrus decision, and [OPEN] requires Forest Lite or profiling before freezing.

## 2. Test pyramid and repository layout

```text
tests/
  core/
    keys_rng/ population/ boundary/ surface/ areas/ falloff/
    diversity/ transforms/ collisions/ effects/ editing/ io/
  golden/
    snapshots/ expected/ manifests/
  property/
  fuzz/
  max/
    scripts/ scenes/ expected/
  perf/
    recorded_snapshots/ results/ charts/
  forest_lite/
    scenes/ exports/ notes/
```

The bottom layer contains fast deterministic unit tests that run on every commit. The middle layer runs property tests, parser fuzzing, and golden snapshots on every merge request. Max integration and Forest Lite comparison scenes run in a nightly matrix across supported Max and Forest versions. Performance benchmarks run on pinned hardware and are tracked by commit, compiler, and algorithm version.

A test name includes stage, feature, and invariant, for example `S05_density_lowering_is_stable_subset`, `S09_collision_priority_smallest_size`, or `S10_override_orphan_after_seed_change`. Each test records the input snapshot hash, `algoVersion`, compiler, CPU feature set, worker count, and test data version. Expected output is never overwritten automatically.

## 3. Core unit tests without Max

### 3.1 Snapshot fixtures

Create a plain-data fixture builder that constructs a `SceneSnapshot` without Max headers. It should support surfaces, simple triangles and grids, spline loops and open splines, raster and analytic maps, geometry bounds, area programs, controllers represented as sampled curves, and reference transforms. The fixture format is JSON for small tests and a compact binary for large recorded snapshots. Every fixture includes units, coordinate frames, seed, algorithm version, and a human description.

Use small exact fixtures first:

* A 2 by 2 lattice over a unit square.
* A plane with known UVs and material IDs.
* Two overlapping include and exclude splines.
* A tilted plane with a known normal and altitude.
* Two geometry sources with different bounds and collision radii.
* A path with three straight segments and a known arc length.
* One reference object with two pivots and one triangle face.
* A 16 by 16 texture with explicit grayscale and RGB values.
* One linked Cyrus source with a versioned PublishedPopulation.

Each fixture has an expected row count, key list, positions, flags, and export hash. These are not substitutes for Forest comparisons. They pin Cyrus's own contracts so a refactor cannot silently change the intended behavior.

### 3.2 Identity and RNG

Unit test `StableKey` packing for every `GenKind`, boundary values of tile and pixel indices, layer values, and source IDs. Test that changing a UI order without changing entryId does not change the key. Test that changing an area entryId does change only the intended key namespace. Test collision resistance over at least ten million generated KeyParts and report collisions, though absence of collision is not a proof.

For StableRNG, test that the same seed, key, purpose, and algorithm version produce the same bits across platforms. Test purpose separation, integer range inclusivity, half-open real range, and no mutable counter. Run the same generator at one, two, four, eight, and 32 workers and compare raw values, not only final rows. Test that adding a random call with a new purpose does not change existing purposes.

### 3.3 Stage contracts

Each stage has a contract test that checks it only writes declared fields and flags. A debug build snapshots columns before a stage and asserts that undeclared writes did not occur. Stages must be idempotent when run twice on the same immutable inputs. A stage that consumes a checkpoint must produce the same output as a full run through that stage.

For every stage, test cancellation at chunk boundaries. Cancellation must leave no partially published population. Test a stale worker result arriving after a newer generation: the publish gate must reject it by `evalGeneration` and snapshot version.

### 3.4 Distribution and surfaces

Test lattice extents, map rotation, offset, tile indexing, threshold, density map probability, and Max Density safety limits. Verify the architecture rule that decreasing density is a stable subset when the same seed and candidates are used. Test path arc-length intervals, vertex mode, random position, tangent continuity, and offset on a closed path. Test reference pivot and face generation, barycentric coordinates, material filters, and degenerate triangles.

Surface tests use analytic planes, stepped meshes, and UV seams. Check XY drop direction, UV sampling, normals, slope angle, altitude, material ID, and miss behavior. Verify that generated position uses FL and source geometry uses SL. Include scenes at large coordinates to detect float precision errors and chunk-origin mistakes.

### 3.5 Areas, falloff, filters, and boundary

Unit test ordered area programs with include and exclude records, linked masks, object masks, Forest masks, paint masks, and surface masks. The area program must produce explicit nearest include and exclude distances. Test filters for slope, altitude, material ID, and open spline thickness. Test Point and Size boundary checks, Edge candidate marking, and no accidental row deletion before S12.

Falloff tests use monotone curves and analytic distance fields. For a monotone decreasing density curve, moving toward the boundary must not increase density. For a scale curve with Affect Height Only, X and Y must remain unchanged. Test include and exclude combinations separately and together. Test zero-width falloff, maximum falloff, inverted curve inputs, and distance values of infinity.

### 3.6 Model selection, clusters, collisions, transforms

Test probability normalization, disabled geometry gaps, color-ID nearest match, deterministic random selection, and sequence order. Cluster tests verify stable labels, characteristic size, roughness, blurry edge, and noise without asserting a private Voronoi implementation. Test that cluster output is deterministic and that changing an unrelated geometry entry does not reseed existing candidate selection unless the documented mode requires list order.

Collision tests use two and many spheres, equal and unequal radii, halo tiles, boundary cells, and candidates exactly tangent within epsilon. Verify the configured priority policy, especially the [OPEN] question of smallest or largest plant size. Test collisions in Image, Path, Reference, and Particle modes. Compare one-thread and N-thread conflict resolution.

Transform tests cover translation percentages, random rotation ranges in radians at the Effects boundary and degrees in UI input, scale locking, mirror, normal alignment, path follow, camera look-at, probability curves, and transform maps. Test every composition order with basis vectors and record the chosen order in the golden manifest.

### 3.7 Editing and Effects

Test procedural OverrideRecords by StableKey, delta and absolute transforms, model swaps by geometry entryId, hide and delete flags, tint, userID, and orphan behavior after density, seed, area, surface, and geometry changes. Test that an orphan is reapplied when its candidate returns. Test Freeze to manual, ManualItem IDs, Selection, Random, and Sequence creation, Z=0 defaults, Link to Surface, Place Items, path, pivot, and face tools.

Test S10's versioned selection handles and stale population rejection. Test one RestoreObj delta for a multi-item gesture, correct `Size()` reporting, cancel behavior, nested hold behavior, and redo after a procedural rebuild.

Effects tests cover lexer tokens, EBNF grammar, case-insensitive names, comments, semicolons, vector dot and cross, precedence, conditional laziness, all attribute bindings, read-only errors, deterministic random functions, texture and curve calls, spline calls, instruction budgets, and stack order. Fuzzing is described below.

## 4. Golden population hashes

A golden snapshot records a canonical sorted stream, not the in-memory vector order from workers. The sort key is tile index, StableKey value, and ManualId for manual rows, following 00 section 8. The manifest stores:

```json
{
  "fixture": "plane_density_v3",
  "algoVersion": 7,
  "seed": 1234,
  "snapshotHash": "...",
  "populationVersion": "...",
  "rowCount": 12000,
  "aliveCount": 8500,
  "channels": ["key", "pos", "normal", "geomId", "rot", "scale", "flags", "tintRGBA8"],
  "hashAlgorithm": "sha256",
  "floatEncoding": "ieee754-little-endian"
}
```

Hash fields in fixed binary encoding. Positions and vectors use the architecture's stored float representation after generation, while diagnostics may include double precision values separately. Quaternions are normalized and encoded in a fixed component order. Do not hash pointers, unordered map iteration, timestamps, thread counts, or cache addresses.

Golden updates require a reason, algorithm version bump, migration note, and review of changed channels. A compiler optimization or worker count change is never a valid reason to change a golden hash. If the algorithm intentionally changes, retain the previous expected output for old `algoVersion` scenes and run both paths until migration is removed.

Golden tests cover full pipelines and per-stage checkpoints. Per-stage hashes localize regressions: a distribution change should not appear as a collision regression. For large populations, store a full hash plus sampled row records at deterministic quantiles and the first and last keys. A hash alone cannot explain a mismatch.

## 5. Determinism and property testing

The required determinism matrix is worker counts 1, 2, 4, 8, 16, and the machine maximum, with viewport, render, and export modes. Every pair must produce the same canonical population hash for identical inputs. View masks are compared separately and are allowed to differ only when camera or display mode differs. Run with SIMD disabled and enabled. Run with cache warm and cold. Run after cancel and restart.

Properties include:

* Density monotonicity: if only a global density multiplier decreases, survivors at the lower value are a subset of survivors at the higher value.
* Seed locality: changing a seed changes random fields, but never produces duplicate StableKeys in one build.
* Area inclusion: an item outside all includes is never alive; an exclude cannot make an outside include item alive.
* Falloff monotonicity: monotone input curves yield monotone sampled factors along a monotone distance ramp.
* Transform identity: min equals max and map neutral values produce the base transform.
* Scale positivity: unless mirror is explicit, scale components remain nonnegative and finite.
* Collision safety: no pair of accepted spheres overlaps under the configured epsilon and priority rule.
* Override stability: an override applied twice is identical to one application and does not compound.
* Manual identity: deleting and recreating a manual item never reuses its ID.
* Effects purity: evaluating a program twice gives the same result and does not change source or parameters.
* Snapshot immutability: no stage writes through a const SceneSnapshot or cache input.

Use shrinking for failures. A failing 10M candidate property should shrink to the smallest area, number of items, or program that still fails, and save that fixture to the regression corpus.

## 6. Effects parser fuzzing

The parser fuzz target accepts arbitrary UTF-8 up to a fixed size, for example 64 KB, and must either produce a bounded diagnostic list or a valid bytecode program. It must never crash, hang, recurse without a limit, or execute a side effect. Fuzz separately the lexer, parser, type checker, and bytecode verifier. Seed the corpus with valid examples from every operator and attribute and invalid examples with unterminated comments, nested parentheses, malformed numbers, Unicode identifiers, huge exponents, duplicate assignments, wrong vector arity, and unknown attributes.

The bytecode verifier checks register bounds, opcode type signatures, jump targets if future control flow is added, instruction count, parameter handles, and writable binding permissions. Runtime fuzz inputs include NaN and infinity from samplers, missing objects, zero-length vectors, zero denominators, empty geometry lists, and all-hidden populations. The VM must fail closed according to `effectsErrorPolicy` and preserve prior field values when a write is invalid.

## 7. 3ds Max integration tests through MAXScript

Max tests run in a disposable scene under a scripted harness. The harness creates geometry, surfaces, splines, textures, Cyrus objects, and cameras, sets parameters, waits for evaluation completion, and exports channels. Each test saves a `.max` file and a JSON manifest so a failure can be reproduced interactively.

Required integration tests include:

1. Create and delete Cyrus objects, verify references and notifications.
2. Change a ParamBlock2 value and verify the narrow DirtyBits restart.
3. Edit a geometry list entry, reorder entries, delete an entry, and verify entryId behavior.
4. Enter item sub-object level, select by viewport and region, and use standard Move, Rotate, and Scale.
5. Undo and redo a multi-item gesture, delete, model swap, Re-Seed, Store Transform, Freeze, Attach, and Detach.
6. Link a manual item to a surface, deform the surface, and compare linked versus placed behavior.
7. Compile and run Effects with each parameter type and inspect diagnostics.
8. Run `cyrus.exportSnapshot` and compare channel names, coordinate-space metadata, and stable IDs.
9. Start a rebuild, change a parameter, cancel, and verify no stale result publishes.
10. Render with supported instancing and fallback GetRenderMesh, compare transforms and tint payload.

The MAXScript API must support a batch operation with one undo transaction. The test counts undo steps through Max's undo interface where available and checks that a batch does not send one dependency notification per item. Compatibility aliases are tested separately and emit deprecation warnings rather than changing semantics.

## 8. Performance benchmark harness

Benchmarks use recorded snapshots rather than live Max scenes. A snapshot contains baked surface acceleration, masks, maps, geometry bounds, effect samplers, and all parameter values. This removes scene evaluation noise and makes results comparable across commits. The harness runs warm cache and cold cache, one worker and full worker pool, and records wall time, CPU time, peak RSS, allocations, stage timings, row counts, cache hit rates, and cancellation latency.

Target numbers are [DESIGN] starting gates, not claims about Forest performance:

| Benchmark | Target on 16 cores | Measurement |
|---|---:|---|
| Stable RNG and key generation | 100M values/s | scalar and SIMD, identical bits |
| S1 1M lattice candidates | under 80 ms | no surface or maps |
| S2 surface resolve, 1M hits | under 150 ms | cached BVH |
| S3 area and filters, 1M rows | under 120 ms | cached masks |
| S4 to S5 falloff and density, 1M | under 100 ms | scalar curves and maps |
| S6 to S9 model, transform, collision, 1M | under 450 ms | representative geometry |
| S10 overrides, 10M sparse rows | under 250 ms | 1 percent overridden |
| Simple Effects, 10M rows | under 500 ms | three instructions |
| S12 compact and hash, 10M | under 200 ms | selected channels |
| Warm viewport rebuild, 1M | under 250 ms | from narrow checkpoint |
| Full render rebuild, 10M | under 4 s | recorded snapshot, no Max calls |
| Selection query, 10M rows | under 4 ms | warm spatial index |

Report scaling at 100K, 1M, 10M, and 30M candidates. A target miss is investigated by stage and memory bandwidth before relaxing the target. Do not optimize away flags or provenance needed for diagnostics. Streaming render evaluation may reduce memory at the expense of repeated stage work, so benchmark both retained and streamed modes.

## 9. Forest Lite comparison scene suite

Forest Lite is the behavioral oracle for questions that public documentation does not settle. Each scene is intentionally small, uses simple geometry, and exports both Cyrus and Forest data. Use the Forest UI or MAXScript `ForestPack.exportData` where available, for example:

```maxscript
Forest_pro.ForestPack.exportData "c:\\temp\\scene.xml" "index position rotation scale geomID size normal areaIncDistance areaExcDistance"
```

Channel spelling must be verified in the installed build. If a channel is unsupported, record that as a limitation rather than substituting a private field. For each scene, record Forest version, Lite or Pro, Max version, renderer, units, seed, object transform, list order, and every UI setting. Compare counts, positions, IDs when meaningful, selected geometry, scales, and images. The decision each scene settles is a Cyrus contract, not a claim about Forest source code.

### 9.1 Scene catalog

#### L01: Overlapping includes

Setup: create two overlapping closed spline includes over a plane, use a solid Image map, identical density, and place one geometry. Swap area order, then change one include to exclude. Export positions and area distances with `ForestPack.exportData`.

Measure: whether overlap duplicates candidates, whether area order changes density or only nearest distance, and whether an exclude above an include subtracts the overlap. Decision: area program order and duplicate suppression. This settles the [OPEN] area overlap and ordered include semantics.

#### L02: Exclude order

Setup: one large include, one smaller exclude, then reverse their list order. Repeat with two excludes and an exclude below the include.

Measure: row count, boundary distances, and exported positions. Decision: Cyrus's bottom-to-top program and documented requirement that excludes be above includes for expected subtraction. If Forest versions disagree, document version gates.

#### L03: Open spline Thickness

Setup: scatter on a plane inside an open spline shaped like a line, vary Thickness through zero, one, and a large value. Repeat with Force Open Splines enabled and disabled.

Measure: inside mask, edge distances, and whether thickness is full width or half width. Decision: the Thickness convention and open spline endpoint behavior. This is [OPEN] because public docs identify Thickness but not its exact geometric convention.

#### L04: Falloff curve direction and combination

Setup: one include and one exclude with independent density and scale falloffs. Use a visibly asymmetric curve with a marker at 25 percent and 75 percent. Test Affect Height Only and both boundaries at once.

Measure: density and scale against distance, curve direction, and whether include and exclude factors multiply, choose minimum, or apply sequentially. Decision: default falloff evaluation and combination policy.

#### L05: Collision priority and Smallest Plant Size

Setup: a dense grid of two geometries, one large and one small, with equal probability and overlapping collision spheres. If the installed UI exposes Smallest Plant Size, Largest Plant Size, or related collision modes, test each; otherwise test global Radius times per-geometry radius.

Measure: accepted keys, accepted geometry types, ordering, and radius behavior. Export collision radius if supported and inspect `size`. Decision: deterministic priority policy, including whether the smallest or largest plant survives. Mark unexposed labels UNKNOWN rather than fabricating semantics.

#### L06: Monotone density

Setup: one solid map, fixed seed, no collisions, then render at density 25, 50, 75, and 100 percent. Repeat with density-map grayscale ramp.

Measure: StableKey subsets and positions, not just counts. Decision: whether Cyrus guarantees monotone survivors. Forest's public material does not prove this property, so the scene records observed behavior and Cyrus still adopts the stable subset contract [DESIGN].

#### L07: Seed by XY

Setup: a large tiled map split into two areas, generate with one tile arrangement, then enlarge the bounds and regenerate with the same seed. Also move the object in FL while preserving candidate XY coordinates.

Measure: whether unchanged XY candidates retain transforms and geometry choices. Decision: whether Forest random values are effectively keyed by XY or by enumeration. Cyrus uses StableKey and records any divergence as intentional [DESIGN].

#### L08: Transform order

Setup: use a tilted surface, nonuniform scale, normal alignment, path follow, translation, mirror, and camera look-at in separate toggles and then together. Use basis-shaped geometry so each axis is visible.

Measure: final basis vectors and position for each combination. Decision: documented Cyrus composition order and compatibility preset if one Forest order is clear. This settles a major [OPEN] precedence question.

#### L09: Cluster shape

Setup: solid map with two or three geometry entries, clusters enabled. Sweep Size, Roughness, Blurry Edge, and Noise independently. Repeat at two seeds.

Measure: spatial autocorrelation, cluster region diameter, transition width, and selected geometry labels. Decision: Cyrus's abstract cluster algorithm and parameter meanings. Do not claim Voronoi equivalence unless the data supports it.

#### L10: Viewport Max Items default

Setup: large solid map with known candidate count. Record viewport display count and render count at the default Max Items, 0, half the estimate, and twice the estimate. Repeat with camera clipping and point cloud.

Measure: actual count distribution, rebuild time, and whether increasing the budget is a stable superset. Decision: Cyrus viewport budget default and approximation policy. Forest documents an approximate count for multithreading [FP-DOC].

#### L11: Lite versus Pro feature availability

Setup: open a matrix scene using Effects, Custom Edit, paint, Path, Reference, PFlow, Edge, Forest areas, animation, and Forest Color. Run in Lite and Pro editions with the same Max version.

Measure: UI presence, script interfaces, render behavior, and error messages. Decision: capability gating in Cyrus and documentation of features that cannot be compared in Lite.

#### L12: Custom Edit freeze behavior

Setup: generate items with collisions, delete and transform selected items, switch to Custom Edit, change areas and density, and switch back. Save before each transition.

Measure: survivor set, collision rejects, edit persistence, and whether areas reapply. Decision: Cyrus's explicit Freeze to manual and the warning model. This validates [FP-OBS] one-way behavior without adopting its data loss.

#### L13: Manual creation defaults and surface modes

Setup: create one item in empty space, one with a surface and Link to Surface, one with Place Items, and one using a face snap. Move and deform the surface.

Measure: initial Z, later motion, normal orientation, and whether free Z is allowed while linked. Decision: manual link versus place semantics and Z=0 default.

#### L14: Geometry list reorder and existing items

Setup: generate and manually edit a mixed geometry list. Add, reorder, disable, and delete list entries. Invoke Select By Type and Randomize after each change.

Measure: existing source assignment, Sequence future assignment, and missing source behavior. Decision: Cyrus entryId rules and explicit orphan behavior.

#### L15: Effects attribute units and write order

Setup: write position, rotation, scale, visible, geomID, tint, animation, random ranges, and userID in separate Effects. Use rotation values that distinguish radians and degrees. Stack two effects that write the same field.

Measure: exported values, visibility flags, final stack result, and error diagnostics for read-only fields. Decision: language units, writable mapping, and order.

#### L16: Effects random determinism

Setup: use `randomReal` and `randomInt` with named purposes across one and N worker threads, then add a new call site with a distinct purpose.

Measure: per-key values and changed channels. Decision: Cyrus StableRNG semantics and whether compatibility aliases need a legacy random mode.

#### L17: Path and Reference collision coverage

Setup: Path spacing, Reference face samples, and PFlow particles with overlapping collision radii. Run viewport collision preview on and off, then render.

Measure: count and accepted keys in each mode. Decision: whether the target Forest version supports collision consistently across modes, and how Cyrus gates preview.

#### L18: Edge trimming

Setup: place tall geometry straddling an area boundary with Point, Size, and Edge modes. Render in at least two supported renderers and inspect viewport preview.

Measure: whole-item culling versus per-element clipping, render-only behavior, and payload requirements. Decision: Edge flag and renderer adapter contract.

#### L19: Export channel semantics

Setup: enable random transforms, animation samples, tint, path and surface provenance, and area distances. Export with ForestPack.exportData channels `index`, `position`, `rotation`, `scale`, `geomID`, `size`, and any supported provenance fields.

Measure: units, index stability, pre or post random scale, and missing channels. Decision: Cyrus export schema and compatibility aliases.

#### L20: Animated sample and cache behavior

Setup: animate source geometry and the Cyrus object, use Follow Geometry, Random Samples, Random from Map, and Frame from Map. Scrub frames, render frame 0 and a later frame, then repeat after cache eviction if controllable.

Measure: sampled transforms, memory, rebuild time, and frame-to-frame identity. Decision: animation sample cache keys, invalidation, and performance limits.

#### L21: Forest area sphere versus mesh

Setup: use a source Forest with sparse and dense items as an area, compare Sphere and Mesh modes, and vary source scale.

Measure: exclusion shape, approximation error, and updates after upstream regeneration. Decision: Cyrus Forest-area sampler and cache invalidation.

#### L22: UV and map coordinate behavior

Setup: use a curved object with a known UV checker, compare XY and UV surface modes, built-in bitmap and Map input, units, pixels, and surface map channel.

Measure: candidate positions, map samples, and repeat period. Decision: map coordinate rules and S1 to S2 interface.

This suite is a supported comparison catalog, not an exhaustive population sweep. Scenes L01 to L22 cover every unresolved behavior identified in the architecture and research notes that materially affects the implementation order. If a new [OPEN] question appears in files 01 to 09, add a named scene before the corresponding milestone exits.

## 10. Milestone roadmap

The milestones follow the required build order. Each has a narrow scope, exit criteria that can be tested, and a demo scene. A milestone is not complete when the UI exists; it is complete when its core contract, Max adapter, diagnostics, and regression tests exist.

### M0: Services and test harness

Scope: StableKey, StableRNG, Vec and Quat types, DirtyBits, immutable SceneSnapshot skeleton, Population SoA, JobSystem, cancellation, hash exporter, SharedCacheRegistry skeleton, fixture loader, and recorded-snapshot benchmark harness.

Exit criteria: core builds without Max headers on supported compilers; one versus N thread RNG and empty pipeline hashes match; snapshots are immutable; cancellation cannot publish stale output; fixture and golden formats are versioned; CI runs unit tests and sanitizer builds.

Demo scene: `M0_identity_plane`, a 2 by 2 lattice exported with keys and hash.

### M1: Lattice, XY surfaces, and point cloud

Scope: S1 Image lattice, map sampler, XY projection, S2 plane and mesh hit, normals, UVW, material IDs, viewport point cloud adapter, and basic stats.

Exit criteria: one million candidates generated and resolved under target; stable density subset property passes; one and N thread golden hashes match; point cloud updates only after a new PublishedPopulation; large-coordinate fixture passes.

Demo scene: `M1_checker_plane`, a checker map on a plane with viewport point cloud and export.

### M2: Areas and boundary

Scope: S3 ordered include and exclude area program, spline and object masks, S8 Point and Size boundary, distance provenance, filters, and debug overlays.

Exit criteria: L01, L02, L03, L21, and L22 have recorded Forest observations; unit tests cover area order and thickness; masks are cached and invalidated; area flags and counts appear in Stats; Edge candidates are represented but not yet trimmed.

Demo scene: `M2_area_lab`, overlapping splines, object mask, material filter, and boundary overlay.

### M3: Geometry list and transforms

Scope: immutable geometry entryIds, source snapshots, S6 model choice, S7 transform composition, random maps and curves, mirror, and source bounds.

Exit criteria: geometry reorder does not change entryId references; probability and sequence tests pass; L08 and L14 produce a documented decision; transform golden channels are stable across threads; missing sources are diagnosed.

Demo scene: `M3_transform_rig`, axis-marked geometry with all transform controls.

### M4: Render instancing

Scope: S12 PublishedPopulation payload, RenderTimeInstancing provider, GetRenderMesh fallback, per-instance transform, geometry ID, animation sample placeholder, and render statistics.

Exit criteria: supported test renderer sees the correct number and transforms of instances; fallback matches instancing for a simple source; no Max scene calls occur on worker threads; render limit warnings are actionable; render export matches golden channels.

Demo scene: `M4_render_gallery`, mixed geometry, tint placeholder, and instancing versus baked fallback.

### M5: Falloff, object and forest areas, and filters

Scope: S4 boundary and altitude falloff, density and scale factors, Object and Forest raster masks, surface filters, map overrides per area, and monotone property tests.

Exit criteria: L04, L05, L06, L21, and L22 are recorded; falloff combination is frozen or explicitly versioned; Object and Forest masks have cache keys and invalidation; density lowering is a stable subset; scale to fit and Affect Height Only have golden tests.

Demo scene: `M5_falloff_masks`, nested include and exclude masks with heatmap overlays.

### M6: Collisions, clusters, and camera

Scope: S9 spatial hash and halo collision resolution, collision radius and height, cluster assignment, camera ViewMask, frustum, far clip, camera density, LOD, and viewport budgets.

Exit criteria: collision output is independent of worker count and tile order; L05, L09, L10, and L17 settle target-version policies; no accepted sphere overlaps; camera changes never reshuffle the population; Max Items is approximate and monotone by key where Cyrus promises it.

Demo scene: `M6_collision_camera`, dense mixed plants, cluster controls, camera clipping, LOD, and budget slider.

### M7: Paint and Custom Edit

Scope: paint strokes, coverage, OverrideRecords, ManualItems, item sub-object level, spatial selection, standard transforms, delete and model tools, manual creation, Store Transform, Freeze, Attach, Detach, and persistence chunks.

Exit criteria: L12, L13, L14, and L18 are recorded; all edit commands have undo and redo; orphan UI works after density, seed, area, and geometry changes; manual link and place modes pass; no edit relies on a generated array index; saved and reopened scenes preserve edits.

Demo scene: `M7_editing_studio`, generated trees with moved, hidden, deleted, frozen, linked, and orphaned items.

### M8: Path, Reference, PFlow, animation, and tint

Scope: S1 Path, Reference, and Particle generators, creation tools along paths, pivots and faces, animation samples, surface and element tint payload, and renderer material adapters.

Exit criteria: L17, L19, and L20 pass for the supported Forest target; path arc-length and reference barycentric tests are golden; animation cache is bounded and invalidated; tint is per instance and does not mutate source meshes; renderer compatibility is explicit.

Demo scene: `M8_sources_animation`, path rows, reference face samples, particle stream, animated leaves, and tint map.

### M9: Effects, library, bake, UV, and Edge

Scope: Effects lexer, parser, compiler, register VM, parameters, library browser, stacked effects, sandbox, deterministic random functions, bake adapter, UV maps, Edge render clipping, and export compatibility aliases.

Exit criteria: L15, L16, L18, L19, and L22 pass; parser fuzzing meets crash and time limits; Effects one and N thread hashes match; error policies prevent partial writes; bake output matches published transforms; Edge works in each supported renderer or is disabled with a clear message.

Demo scene: `M9_effects_bake`, a library of stacked effects driving scale, geometry, tint, animation, UV map, Edge, and a baked copy.

### M10: Hardening and compatibility release

Scope: full comparison matrix, migration tests across `algoVersion`, load and save corruption tests, benchmark gates, documentation, user diagnostics, and release qualification.

Exit criteria: all mandatory tests pass on supported Max and renderer matrix; all [OPEN] decisions have either a Forest Lite record or a documented Cyrus [DESIGN] decision; performance targets have a baseline; no known data-loss path in undo, save, rebuild, or orphan handling; deterministic hashes match across supported worker counts and SIMD modes.

Demo scene: `M10_parity_city`, a large production-like scene exercising every feature and export path with a captured baseline.

## 11. Risk register

| Rank | Technical risk | Impact | Mitigation and detection |
|---:|---|---|---|
| 1 | Stable identity changes when algorithm or list ordering changes | Manual edits attach to wrong items or become unusable | StableKey from KeyParts and immutable entryIds; golden key streams; bump algoVersion; orphan rather than fuzzy remap |
| 2 | Parallel collision or area evaluation is nondeterministic | Render nodes disagree and golden hashes drift | Tile halos, deterministic priority, canonical merge, one versus N thread matrix, race sanitizer |
| 3 | Max SDK sub-object transform hooks differ by version | Editing fails or corrupts transforms | Verify headers before coding; isolate adapter; MAX integration matrix; standard gizmo smoke scenes |
| 4 | Effects VM permits unsafe or unbounded work | Max hangs, crashes, or executes unintended operations | No loops or recursion in v1, instruction budget, verifier, no Max calls, fuzzing, sandboxed parameters |
| 5 | Forest behavior is underdocumented or version-specific | Apparent parity breaks across target versions | Label evidence, Forest Lite scenes, version manifest, explicit compatibility presets, never invent private semantics |
| 6 | Geometry list deletion or attach remap loses source references | Items render wrong or disappear | entryId references, missing-source diagnostics, name plus type matching, attach and reorder tests, undoable remap |
| 7 | Incremental checkpoints publish stale or partial populations | Viewport flicker, data loss, wrong render | immutable snapshots, evalGeneration gate, atomic publish, cancellation tests, keep previous population until complete |
| 8 | Memory use grows beyond practical limits at 10M items | Render failure or Max instability | SoA and chunk origins from 00, streaming render, provenance release at S12, RSS benchmarks, cache cap |
| 9 | Max scene and texture evaluation leaks onto worker threads | Deadlocks or random crashes | S0 snapshot and bake all map data, thread assertions, recorded snapshots, review Max adapter calls |
| 10 | Forest comparison exports have unstable or incomplete channels | Wrong compatibility decisions | Record exact Forest version and channel support, use `ForestPack.exportData`, compare multiple channels and images, mark unsupported fields UNKNOWN |

Additional risks include renderer-specific instancing, animated sample cache eviction, precision at huge coordinates, tangent discontinuities, and UI responsiveness during large rebuilds. They are covered by stage-specific tests and M8 or M10 qualification, but the top ten above gate the architecture.

## 12. Reporting and release gates

Every nightly report has four panels: correctness, determinism, performance, and compatibility. Correctness lists failed unit and property tests with minimized fixtures. Determinism lists hash pairs and the first differing channel. Performance compares stage medians and p95 against baseline, with CPU, RSS, and cache statistics. Compatibility links each Forest Lite scene to its export, screenshot, observed result, and Cyrus decision.

A regression is blocked when a golden hash changes without an algorithm version bump, a one versus N thread comparison differs, a parser fuzz target crashes or exceeds the timeout, undo or save loses authored records, or a renderer receives a different transform from the export. A performance regression over 10 percent requires investigation; a planned tradeoff must be recorded with a new target.

Forest Lite is a comparison tool, not a test oracle for private implementation. Where Forest's behavior is [FP-OBS] or [UNKNOWN], the report must say exactly what was measured and what Cyrus chooses. The result can settle an exposed user behavior without proving how Forest implements it.

## 13. Architecture feedback

This roadmap follows `00_ARCHITECTURE.md` and does not require a structural change. Two clarifications would improve execution: define the canonical serialization of PublishedPopulation hashes in 00, and add `D_MANUAL` to the DirtyBits examples. Also state that Forest Lite scenes are versioned evidence and may record compatibility presets rather than changing the core deterministic contract.

A further recommendation is to make the recorded-snapshot benchmark harness an M0 deliverable rather than a late optimization tool. Without it, stage boundaries, cache behavior, and determinism are too difficult to measure independently.


## 14. Fixture review, triage, and coverage accounting

Every comparison fixture has an owner, a creation script, an evidence classification, and a last verified date. The creation script must be deterministic and must not depend on the interactive state of a Max session. For a Forest fixture, save the `.max` file before export, after export, and after each parameter mutation that matters. Keep the original Forest XML export unchanged. Cyrus's import or comparison script may normalize coordinate spaces, but it must write the normalization rules beside the result, never silently in code.

When a comparison disagrees, triage in this order: coordinate system and units, source mesh and transform, candidate count and key set, area and surface flags, model selection, transform channels, collision flags, shading payload, and finally image appearance. This prevents a material mismatch from hiding a distribution mismatch. A discrepancy report includes the smallest scene that reproduces it, the first pipeline stage whose hash differs, and whether the discrepancy is a Forest mismatch, a Cyrus contract violation, or an unresolved [OPEN] behavior.

Coverage is tracked by stage and invariant, not merely line count. The matrix requires at least one unit test, one property test, one golden test, and one Max or Forest Lite test for every field that crosses a stage boundary. For example, `surfaceId` needs a surface fixture, a serialization check, a S2 golden channel, and an Effects read-only attribute test. Every DirtyBits group needs a test that identifies its first dirty stage and verifies that earlier checkpoints are reused. Every persistence chunk needs a round trip, truncated input, unknown-version, and unknown-field test.

Before M10, run a fault-injection pass. Force cache misses, allocation failures in the fixture harness, canceled jobs at every chunk boundary, deleted source nodes, invalid texture samplers, empty geometry lists, degenerate splines, and corrupted chunks. The expected result is a diagnostic and a safe prior publication, never a crash or a partially saved authored state. This pass is especially important because a scatter plugin is often evaluated while an artist is dragging a parameter or scrubbing animation, not only in a clean batch render.

