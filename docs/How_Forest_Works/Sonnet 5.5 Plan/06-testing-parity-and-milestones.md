# Cyrus Scatter — Rebuild Blueprint

## 06 · Testing, Parity Verification and Milestone Plans

This file turns the design into **proof**. It has three parts: (A) automated tests that keep the engine correct, (B) the behavioral reference suite that settles every **[Test]** item against a licensed copy of the reference product, and (C) milestone task lists with acceptance criteria.

---

## Part A — Automated test strategy

### A.1 Test pyramid

| Level | Runs where | What it protects |
|---|---|---|
| **Unit** (core library) | CI, no 3ds Max | Math, samplers, id/RNG, spatial structures |
| **Property / determinism** | CI, no 3ds Max | Incremental == full, thread-count independence, seed stability |
| **Golden point-set** | CI, no 3ds Max | Known scenes produce known populations (within tolerance) |
| **Integration (Max)** | Max-hosted runner | Snapshot, undo, save/load, viewport, painting |
| **Renderer smoke** | Max + renderer | Instancing, tint, cutout, IPR updates per backend |
| **Performance** | Fixed hardware | Regression thresholds per stage |
| **Fuzz / sanitizers** | CI nightly | Crashes on degenerate input; data races |

Because `cyrus_core` has no Max dependency (file 01 §1), levels 1–3 and 7 run on any build machine.

### A.2 Unit tests (representative)

| Area | Test |
|---|---|
| `Random01` | Uniformity (chi-square over 10⁷ draws); channel independence (correlation ≈ 0); stability (golden values for fixed inputs) |
| Weighted pick | Empirical frequencies match `w/Σw` within tolerance; weights 6/3/1 ≡ 60/30/10; empty slot retains its share |
| `CurveSampler` | Sampled histogram matches curve shape; discrete-angle curve (0°, 90°, 270°) yields only those angles within bin width; zero curve falls back to uniform |
| Arc-length path | Spacing error < 1e-3 relative on tight curves; seams on closed splines; offset curve behavior documented |
| Triangle sampling | `RandomInTriangle` uniform (area-weighted bins) |
| Image tiling | Pixel (ix,iy) ↔ `mod` mapping across tile borders; X/Y Units halving quadruples candidate count |
| Point/Size boundary | Known footprints vs polygon edges |
| Distance fields | Polyline distance vs brute force; EDT vs brute force |
| Spatial hash | Neighbor queries equal brute force for random radii |
| Raster mask | Pixel width = extent/resolution; target-error → resolution mapping |
| Clusters | Candidate **count unchanged** when only Size changes; species patch scale ∝ Size |
| Falloff | Curve endpoints; non-monotonic curves; invert; affect=0 disables |
| Surface | Multi-hit counts for stacked planes; slope = 0° flat, 90° wall; UV barycentric round trip |

### A.3 Property tests (the correctness backbone)

Generate random scenes and random edit sequences; assert invariants.

| ID | Property | How |
|---|---|---|
| **PR-1** | **Incremental equals full.** After any sequence of edits, the incrementally updated accepted set equals a fresh full rebuild (ids, transforms, sources) | Random edits: paint strokes, spline moves, radius changes, source weights, seeds; compare buffers bitwise or within 1e-6 |
| **PR-2** | **Thread independence.** Same output with 1, 4, 32 threads | Run and diff |
| **PR-3** | **Stage isolation.** Changing a tint parameter changes **only** tint outputs; positions, ids, collisions unchanged | Diff buffers; assert recompute counters for stages 3–12 are zero |
| **PR-4** | **Seed stability.** Adding a source changes only source choice (and downstream footprint-dependent results), not rotation/scale randoms of unchanged candidates | Diff by id |
| **PR-5** | **Slider stability.** Increasing density-map density only adds items (superset by id) before collisions | Compare id sets |
| **PR-6** | **Tile independence.** Result is identical regardless of tile size (within the halo rule) | Re-run with tile sizes 8/16/64 m |
| **PR-7** | **Cycle safety.** Assigning a dependency that creates a cycle is refused and leaves the scene unchanged | Random dependency graphs |
| **PR-8** | **Round trip.** Save → load → regenerate equals the original | Serialize all settings, overrides, paint authoring |
| **PR-9** | **Undo exactness.** Undo/redo of any command restores settings, paint coverage and overrides exactly | Randomized command sequences |
| **PR-10** | **Stale-result safety.** A late result from an old revision is never published | Inject delays in workers |

> A fast local update that disagrees with a full rebuild is a correctness bug, not an optimization (file 00 §3, principle 6).

### A.4 Performance tests

Measure per stage on fixed scenes (below). Track in CI and fail on regressions beyond a threshold:
- Cold build time and **peak temporary memory**.
- Warm update time for: tint change, one-source weight change, 3 m paint stroke, spline vertex move, terrain deformation of a small patch.
- Viewport upload bytes/time; render export time (per backend).
- Collision rejection throughput (candidates/s).

**Benchmark scenes.**

| Scene | Contents | Stresses |
|---|---|---|
| **Lawn** | 10 km² flat plane, 50 M candidates dense map, single grass source | Candidate generation, collisions, memory |
| **Hills** | Heightfield 5 M triangles, trees + grass + rocks | Surface queries, slope/altitude, area stack |
| **Garden** (file 06 §B.4) | Slope, path, trees, grass, painted flowers, rock corridor, manual tree override | Cross-feature interaction |
| **Stack** | Two vertically separated surfaces | Multi-hit, ids, randomize-stacked parity |
| **Painter** | 500 overlapping strokes | Paint history cost, tile cache |
| **Anim** | 50 k animated plants, 20 samples | Source-state cache |

### A.5 Fuzz and sanitizer targets

Degenerate meshes (zero-area triangles, NaN vertices), huge/tiny scales, empty source list, one source with weight 0, reversed splines, self-intersecting splines, maps with NaN, 0×0 distribution tile, enormous X/Y Units, millions of areas. Run AddressSanitizer/UBSan and ThreadSanitizer on core nightly.

---

## Part B — Behavioral reference suite (parity verification)

**Purpose.** Reading documentation tells you what a control is *for*. It does not reveal evaluation order or numerical details. These experiments, run **in a legitimately licensed copy of the reference product**, settle every **[Test]** item. Run the same scene in Cyrus and compare.

**Rules.**
- Tiny scenes, fixed source meshes, fixed seed, **one change at a time**.
- Goal is **behavioral equivalence**, not identical pseudorandom numbers or private algorithms.
- Record outcomes in a **behavior record** (B.3) and update the tag of the corresponding statement from **[Test]** to **[Doc]**/**[Obs]** (observed).
- Never decompile or inspect binaries (file 00 §10).

### B.1 The master experiment (smallest scene that reveals the most)

- A flat 10 × 10 m receiver.
- One cube source with known size.
- A tiny hand-authored distribution bitmap with a known white/black pattern.
- Disable transforms, collisions, clustering, camera rules.

Measure generated positions. Then enable **one at a time**:

1. Change X/Y Units.
2. Add random translation.
3. Add a closed-spline include.
4. Enable Point boundary.
5. Switch to Size boundary.
6. Enable collisions.
7. Add a second source with a different collision radius.

### B.2 Test catalog

| ID | Question | Method | Resolves |
|---|---|---|---|
| **P-01** | Is the random seed a function of XY position? (documented) What exactly is quantized? Does moving the Forest object / area / changing X/Y Units change the look of unmoved plants? | Place identical items; move area; shift origin; compare rotation/scale values per XY | Identity mode (file 01 §4) |
| **P-02** | Are items centered on pixels or jittered? | Known bitmap, record positions vs pixel centers | Image candidate jitter (file 02 §B.1) |
| **P-03** | How does a gray value change acceptance counts in density-map mode? | Uniform gray images at 10/25/50/75%; count items | Density mapping law |
| **P-04** | Do positions stay put when source weights change? | Before/after positions | Position/source separation |
| **P-05** | What do Size, Roughness, Blurry Edge, Noise do? Do probabilities affect cluster frequency? Does Size change counts? | Parameter sweeps; species maps | Cluster algorithm tuning |
| **P-06** | Ordered areas: which area owns overlapping includes? How do includes/excludes combine at different list positions? | Three-region scene: include, exclude, include above exclude; reorder | Area semantics (file 02 §D.2) |
| **P-07** | Per-area overrides: do local scale/model subset/map **replace** or **multiply** globals? | Same source in several areas | Precedence table |
| **P-08** | Collision order: do scale or random translation affect collisions? Which candidate wins? Does radius scale with item scale? | Candidate and reject counts under each change | Occupancy rules |
| **P-09** | When are Point, Size and Edge evaluated relative to translation and scale? | Oversized items along a spline | Boundary order |
| **P-10** | How accurate is paint → spline on complex regions? | 500 overlapping strokes → convert → compare area | Paint representation |
| **P-11** | Stacked surfaces: how do XY mode, UV mode and Randomize Stacked interact? | Two vertically separated meshes | Multi-hit ids |
| **P-12** | Which camera settings rebuild distribution vs only change visibility? | Time rebuilds; diff positions | Camera-dependent flags |
| **P-13** | Effects precedence: what happens when an effect changes source, scale, position or visibility? | Small controlled effects | Effects stage order |
| **P-14** | Slope reference axis (world Z vs Forest local Z) and slope in rotated objects | Rotate the Forest object | Slope parameterization |
| **P-15** | Direction −100…+100 mapping; Scale-to-Fit formula | Measure orientation and widths on known slopes | Orientation math |
| **P-16** | Falloff curve orientation, invert semantics, "Falloff Affect" blending, overlap policy for multiple influences | Single boundary with curve probes | Falloff law |
| **P-17** | Object-area "Top Limit" meaning; effect of resolution on accuracy | Overhanging object | Exclusion raster rules |
| **P-18** | Edge mode element test: lowest-Z vertex confirmed? Behavior with proxies, multiple materials | V-Ray scene with element materials | Edge algorithm |
| **P-19** | Translation as % of **scaled** width? Uses source or scaled size? | Scale + translation combo | Transform order |
| **P-20** | Probability map neutral value (what do black pixels give?) | Min/Max asymmetry | Prob-map law |
| **P-21** | Viewport Max Items effect on final render; does it change the population? | Compare render vs viewport | Preview/render separation |
| **P-22** | Animation sample interpolation in "Random From Map" | Known sample frames | Sample mapping |
| **P-23** | Effects attribute names and functions (verify the research list) | Read Effects docs + small tests | Update **[Doc\*]** → **[Doc]** |
| **P-24** | Camera rollout details (Expand, Back Offset, distance falloffs) | Read page + tests | Update **[Doc\*]** |

### B.3 Behavior record template (one per control)

| Field | What must be established |
|---|---|
| Purpose | The artistic problem it solves |
| Inputs | Geometry, maps, curves, lists, coordinates |
| Units | Scene units, %, degrees, normalized |
| Combination rule | Replace, multiply, add, filter, ordered |
| Identity behavior | What stays stable when inputs change |
| Dependencies | What invalidates it (file 01 §6) |
| Persistence | Save/load, undo/redo, clone, missing refs |
| Output differences | Viewport vs render vs export |
| Limits | Unsupported modes and renderer-specific behavior |
| Defaults / ranges | Defaults and valid ranges (from docs/observation) |
| Evidence | **[Doc]**, **[Obs]**, **[Inf]**, **[Prop]** |
| Cyrus implementation | Where it lives; test IDs |

### B.4 The garden integration scene (end-to-end test)

A sloped garden with a curved footpath, several trees, mixed grass, flowers, and a rock border.

- **Trees:** broad include region, weighted species, modest scale variation, spacing constraints, source-specific radii, slope and building-clearance limits.
- **Grass:** same terrain; lawn include; path exclude with short scale falloff; trees act as a **directed** exclusion (trunk-zone footprint, not whole canopy).
- **Flowers:** painted regions; clustered species; density falls toward one boundary while height stays unchanged (Affect Height Only equivalent).
- **Rocks:** open-spline corridor beside the path (irregular), not Path-mode spacing.
- **Foreground tree:** manual position override.

**Scripted checks:**

| Action | Expected |
|---|---|
| Change **only the flower tint** | No change to trees, rocks, path, surface bindings or collisions. Stage counters show only tint/output work |
| Move the shared path geometry | Grass exclusion and rock corridor update; flower paint remains; the foreground tree keeps its override unless a declared rule invalidates it |
| Increase tree density | Existing trees remain (superset by id before collisions); overrides survive |
| Change seed | New variation; orphan policy engages and is reported |
| Edit terrain slightly | Only affected tiles rebuild (with auto-update on) |
| Save → reopen → undo | Identical results (PR-8, PR-9) |

This scene checks the **connections between features**, which a button-by-button implementation misses.

### B.5 Coverage matrix (kept alive through development)

| System | Feature | Parity test(s) | Automated test(s) | Status |
|---|---|---|---|---|
| Sources | weights, empty slot, groups, Color IDs | P-04 | Unit, PR-4 | |
| Image | tiling, threshold, density, max density | P-02, P-03 | Unit, PR-5 | |
| Diversity | random, color ID, clusters | P-05 | Unit | |
| Path / Reference / Particle | spacing, faces, events | (add) | Unit | |
| Areas | ordered stack, linked, per-area overrides | P-06, P-07 | PR-1 | |
| Falloffs | curves, invert, affect | P-16 | Unit | |
| Surfaces | XY, UV, slope, altitude, direction, scale-to-fit | P-11, P-14, P-15 | Unit | |
| Paint | strokes, tiles, conversion | P-10 | PR-1, PR-9 | |
| Boundaries | Point/Size/Edge | P-09, P-18 | Unit, smoke | |
| Collisions | spheres, winner rule | P-08 | PR-1, PR-2, PR-6 | |
| Transforms | translation, rotation, scale, curves, maps | P-19, P-20 | Unit | |
| Overrides | edit, orphan, pin | — | PR-8, PR-9 | |
| Camera / LOD | culling, density, LOD | P-12, P-24 | Smoke | |
| Materials | tint, element, optimizer | — | Smoke | |
| Animation | modes, cache | P-22 | Unit | |
| Effects | expressions, deps | P-13, P-23 | Unit, PR-3 | |
| Display / Render | point cloud, limits, backends | P-21 | Perf, smoke | |

---

## Part C — Milestone task lists and acceptance criteria

Each milestone lists tasks, deliverables and a pass/fail acceptance test. Sizes are relative effort.

### M0 — Recon and decisions (S)

**Tasks**
1. Fill the "existing code → architecture" table (file 01 §12).
2. List missing contracts (stable ids, keyed RNG, snapshot boundary, dependency tracking) ranked by features blocked.
3. Decide open questions (file 00 §11): Max/SDK versions, renderers, compatibility, identity default, CI.
4. Legal review of the reference product's license; set up a clean-room notes folder.
5. Procure a licensed copy of the reference and renderers for testing.

**Accept when:** a written decision log exists and the vertical-slice scope is agreed.

### M1 — Core foundations (L)

**Tasks**
1. Core library skeleton, build system, CI, unit-test harness, headless command-line runner (JSON in → point set out).
2. `StableId`, `Mix64`, `Random01`, channels; golden tests.
3. SoA `CandidateBuffer` / `InstanceBuffer`; arena/pool allocators.
4. `IScalarField`, `Curve`, `CurveSampler`, distance-field utilities.
5. Revision counters, `StageKey`, stage cache, early cutoff.
6. Tile scheduler with halo; job system with cancellation and atomic publish.
7. `Stats` with per-reason counters and per-stage timers.
8. Serialization with schema version.

**Accept when:** PR-2 (thread independence), PR-8 (round trip), and RNG/CurveSampler unit tests pass on a toy generator.

### M2 — Vertical slice (L)

**Tasks**
1. Image provider (bitmap, tiling, threshold, X/Y Units, max-density guard).
2. Weighted source selection incl. empty slot.
3. XY surface projection with shared BVH/grid cache (single hit first).
4. One closed spline include + one exclude (ordered evaluation).
5. Point and Size boundary; sphere collisions with deterministic priority.
6. Max layer: scatter object, param block, snapshotter, publish; point-cloud viewport; "Meshes" render backend.
7. Stats window (candidates, accepted, rejects by reason).
8. Parity tests P-01…P-04, P-06, P-08, P-09 on the master experiment.

**Accept when:**
- Output is deterministic across runs and threads.
- Changing a tint-like parameter triggers **no** placement work (PR-3 on the slice).
- A single parameter change updates incrementally and equals a full rebuild (PR-1 on the slice).
- A scene renders in at least one renderer via Meshes.

*Do not start M3+ until this passes.*

### M3 — Areas and surfaces complete (XL)

**Tasks**
1. Full ordered area stack with provenance and dedupe rule (P-06).
2. Object-area raster with target-error resolution and EDT; Top Limit; Scale.
3. Forest-area exclusion (Sphere/Mesh); linked areas; separate sub-splines; force-open splines.
4. Falloff service (density/scale, include/exclude ranges, curves, invert, affect, height-only) (P-16).
5. Per-area overrides: model subset, random scale, distribution-map override; precedence table (P-07).
6. UV mode with UV index and compensation options; multi-hit; Randomize-Stacked-free ids (P-11).
7. Slope, altitude (with curves), direction, scale-to-fit, material-ID filter (P-14, P-15).
8. Surface cache invalidation granularity; auto-update.
9. Cycle detection for cross-object dependencies (PR-7).

**Accept when:** the garden scene's placement behavior (without paint/clusters) matches the reference within defined tolerances, and PR-1/PR-6 hold with areas enabled.

### M4 — Painting and incremental updates (XL)

**Tasks**
1. Authoring stroke list; tiled coverage evaluation; checkpointing.
2. Stroke pipeline (begin/update/end), pressure, erase, Ctrl/Alt modifiers, falloff preview.
3. Dirty-tile propagation including falloff and collision halo.
4. Fixed-point local re-solve for collisions.
5. Paint ↔ spline conversion (marching squares + simplification; rasterization).
6. Undo/redo per stroke; save/load of authoring data.
7. Overlay views (authored coverage vs candidates vs accepted vs displayed).

**Accept when:** PR-1 and PR-9 hold under random stroke sequences; a 3 m stroke on a large terrain updates only touched tiles; brush overlay remains responsive during regeneration.

### M5 — Population intelligence (L)

**Tasks**
1. Match Color ID diversity (+Noise, gaps via empty slot).
2. Cluster diversity (Voronoi + warp + blur + noise), tuned against P-05.
3. Full transform system: translation %, rotation/scale ranges, curves (CDF), grayscale and color maps, probability maps, mirroring, order contract.
4. Override layer and manual items; orphan policies; Items Editor tools.
5. Transform interaction tests (rotation vs facing camera, translation vs boundary).

**Accept when:** PR-4, PR-5 hold; artist can hand-edit a tree, change density and keep the edit; transform curve histograms match design.

### M6 — Providers (L)

**Tasks**
1. Path provider (arc-length table, vertices, sequence, offsets, tangent orientation).
2. Reference provider (pivot, faces, items per face, name/regex matching, inheritance, marker-stable ids).
3. Particle provider (events, live link).
4. Imported-marker interface (tags, ids).
5. Manual provider integration.
6. Collisions for all providers.

**Accept when:** each provider produces repeatable positions; moving a reference marker moves its item without changing its look; unit tests for arc-length and triangle sampling pass.

### M7 — Renderers and materials (XL)

**Tasks**
1. Prototype per renderer (the four proofs in file 04 §4.3) — **before** UI work.
2. V-Ray backend: native instancing, per-instance tint, Edge (incl. proxies where supported), IPR updates.
3. Corona backend; Arnold backend.
4. "Cyrus Color" shader node per renderer; idempotent Material Optimizer.
5. Boundary-mask stream and Edge integration.
6. Camera culling/density/LOD as output filters; LOD sets; facing camera; shot envelope.
7. Render limits, simplification level, hide-source option, placeholder markers.

**Accept when:** 1 M instances render without geometry duplication on each backend; tint and Edge are visible in render; moving the viewport camera does not trigger placement rebuilds.

### M8 — Effects and animation (L)

**Tasks**
1. Expression lexer/parser/typechecker/bytecode VM with block evaluation.
2. Attribute and function set (file 03 §4); parameter UI generation.
3. Dependency analysis; automatic slot placement; surface re-projection option.
4. Preset effects (edge shrink, lean from wall, elevation species, repulsion, wind phase).
5. Animation modes, sample table, bounded LRU source-state cache, renderer capability fallback.
6. P-13, P-22, P-23 parity tests.

**Accept when:** PR-3 holds for tint-only effects; a position-writing effect correctly triggers boundary and collision re-evaluation; 50 k animated plants share 20 samples within the memory cap.

### M9 — Product completion (L)

**Tasks**
1. Presets: asset / recipe / scene setup with versioning and missing-asset recovery.
2. Shared sets (variation / receiver / region / marker), layer membership, update modes.
3. Manager (lister) with memory/time columns and dependency view.
4. Library browser, portable packages, thumbnails/tags.
5. Utilities: convert to native instances, bake overrides, merge/split, re-seed copy, stats export.
6. Diagnostics: why-not-here inspector; warnings catalog.
7. Documentation generated from behavior records; sample scenes; troubleshooting guide.
8. File compatibility tests and migration; regression suite wired to CI.

**Accept when:** complex scenes save, reopen, share and reproduce reliably on another workstation; all P-tests marked resolved; coverage matrix (B.5) is complete.

---

## Dependency order (what must precede what)

```
M0 → M1 → M2 ──► M3 ──► M4 ──► M5 ──► M6
                 │                    
                 └──────────────► M7 (prototypes can start after M2; full backends after M3–M5)
M5 ─► M8 (needs transforms + overrides)      M3,M4,M5,M7,M8 ─► M9
```
Renderer **prototypes** should begin right after M2 to de-risk integration early, even though full backends land in M7.

---

## Final guidance

- **Reproduce the artist-visible behavior, define the difficult interactions explicitly, and prove that edits stay predictable as the scene grows.**
- Build the smaller set of reliable systems whose combinations produce the many options — stable identity, shared surface and field queries, explicit ordering and override rules, correct incremental updates, and separate viewport/render representations — rather than hundreds of independent checkboxes.
- If in doubt, write the **behavior record** first. If the record has a **[Test]** in it, run the experiment before you code.
