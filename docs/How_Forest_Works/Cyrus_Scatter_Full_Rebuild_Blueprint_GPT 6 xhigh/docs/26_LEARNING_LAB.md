# 26 — Guided engineering course: learn the entire scattering system by building it

> **Audience:** developer and technical artist implementing Cyrus Scatter, not merely an end user operating ForestPack. This is a sequence of **small independent prototypes and observable experiments**. The course is derived from the attached research and this handbook; wherever ForestPack behavior is not directly documented, use the reference test procedure rather than assuming the suggested algorithm is proprietary ForestPack behavior.

## What “understanding a feature” must mean

For every control, be able to answer: (1) what the artist intends, (2) its input units and coordinate frame, (3) what instance attribute or population it changes, (4) when it runs, (5) whether results change when neighboring options change, (6) the invalidated caches, (7) save/Undo/thread implications, (8) observed reference evidence, and (9) error/unsupported behavior. Record answers using `templates/FEATURE_SPEC_TEMPLATE.md`.

Start with a standalone C++ test harness producing CSV positions and visualizable debug geometry. Add 3ds Max host integration only after mathematical behavior is deterministic. This avoids confusing SDK or renderer faults with algorithmic errors.

## Module 01 — Candidate identity and deterministic randomness

**Read:** [03](03_DATA_MODEL.md), [05](05_DISTRIBUTION.md), [25](25_CORE_API_ALGORITHMS.md).

Build a simple grid generator (e.g., 100 x 100 candidates). Give each candidate an ID from stable generator identity plus grid coordinates; derive separate random channels for density, source, rotation, scale, and tint.

**Exercise:** Generate 10,000 positions; change tint settings and confirm rotations are byte-identical; adjust density from 0.25 to 0.5 with collision disabled and confirm that the original accepted IDs are a subset of the new set. Repeat with a different tile traversal order. **Pass** only if outputs are identical in canonical order.

**What this does not prove:** arbitrary changes to pattern size or receiver topology can invalidate candidate identities, and collision outcomes need not remain monotonic.

## Module 02 — Image distribution and map sampling

**Read:** [05](05_DISTRIBUTION.md), [18](18_FEATURE_CATALOG.md).

Create a repeating 2D pattern with world-size controls, rotation, translation, pixel-center sampling, binary thresholding and grayscale stochastic acceptance. Separate map *evaluation* from *candidate reservoir construction*.

**Exercise:** Fix map resolution, halve both world dimensions, and show the expected fourfold potential-candidate density in a large uniformly covered region. Add a checkerboard and verify transform orientation. Test non-square maps, filtering, UV mappings and rotated grids. Count generated, rejected and accepted candidates separately.

**Questions:** Are samples at pixel centers? How do negative tile coordinates work? What is the map's linear/sRGB policy? Which map-related settings rebuild candidates versus update acceptance only?

## Module 03 — Surface sampling in XY and UV

**Read:** [07](07_SURFACES.md), [03](03_DATA_MODEL.md).

Prepare immutable meshes with face IDs, transforms, normals, UVs and acceleration structures. Implement raycast placement with an explicit multi-hit policy. Implement UV-triangle lookup using barycentric interpolation and declare handling of overlaps/seams.

**Exercise:** Scatter on a plane, a 60-degree slope, a sphere, two stacked planes, mirrored UVs, and UV islands of unequal area. Measure surface-area density versus XY/UV density. Deform the mesh and verify which bindings survive; rebuild deliberately on topology changes.

**Pass:** correct miss reporting, stable receiver attribution, no implicit placement at origin and no worker access to live `INode` geometry.

## Module 04 — Paths and external reference candidates

**Read:** [05](05_DISTRIBUTION.md), [24](24_INTERACTION_MATRIX.md).

Build an arc-length table for cubic splines, then sample evenly by physical distance. Add vertices-only, position jitter, lateral offsets, tangent-based orientation and ordered source sequences. Separately read reference pivots and reference triangle samples into the same `CandidateRecord` interface.

**Exercise:** Use straight and curved splines of identical length; test open/closed seam, sharp corners and reversed winding. Move one reference marker and show its assigned source/rotation remain stable if its identity is stable. Test whether a topology edit invalidates face-derived IDs.

## Module 05 — Areas are ordered, not additive masks

**Read:** [06](06_AREAS_FIELDS.md), [24](24_INTERACTION_MATRIX.md).

Represent inclusions as candidate contributions with provenance. Process the area stack in declared bottom-to-top order and have each exclusion operate only on contributions already present. Implement nested polygon contours and open spline corridors as different region constructors.

**Exercise:** Include garden → Exclude road → Include flower bed. Reorder entries and show the difference. Enable two overlapping Includes and demonstrate duplicate candidates or the explicit Cyrus deduplication policy. Repeat with linked area definitions and different local responses.

**Pass:** reference-order semantics preserved without flattening area history into one un-ordered Boolean mask.

## Module 06 — Signed distance, falloff and local overrides

**Read:** [06](06_AREAS_FIELDS.md), [09](09_SOURCES_VARIATION.md).

Build field inputs for boundary distance and curve response. Use the same sampled distance to drive independent density, X/Y/Z scale, source probability and height-only behavior. Specify precedence rules for multiple influences: replace, multiply, max, min or ordered contribution.

**Exercise:** One path with a 1 m grass-density fade and a 0.3 m grass-height fade; show four distinct outputs: none, density only, scale only, both. Change the spline and verify affected cached regions update.

## Module 07 — Real Paint Areas with Undo

**Read:** [08](08_PAINT_ENGINE.md), [13](13_3DSMAX_INTEGRATION.md), [04](04_EVALUATION_CACHING.md).

Create pointer/tablet stroke samples; snap surface hit data on the main thread; store authoring transactions with Add/Erase semantics; compile coverage into spatial tiles; display a brush and coverage overlay independently from generated plants.

**Exercise:** Make 1,000 strokes in the same region, paint and erase repeatedly, undo 100 transactions and redo 100. Compare compiled coverage to authoritative stroke replay. Test 1 m brush size across different viewport zooms. Test strokes over two stacked receiver surfaces.

**Pass:** stroke interaction stays responsive; Undo/Redo restores identical authoring state and generated result; cancellation does not publish stale jobs.

## Module 08 — Sources, clusters and transform statistics

**Read:** [09](09_SOURCES_VARIATION.md), [03](03_DATA_MODEL.md).

Build weighted categorical sampling with a deliberate disabled/empty source choice. Implement color-ID selection separately. Prototype a stable spatial cluster field and invert a piecewise-integrated PDF for artist-edited probability curves.

**Exercise:** Select 100,000 models from weights 6:3:1 and verify frequencies statistically; disable one slot and verify intended holes rather than redistributing its weight. Change cluster size and observe spatial correlation separately from overall density. Verify rotation/scale maps and their coordinate spaces.

**Pass:** no conflation of source probability, population density, or transform probability.

## Module 09 — Occupancy and collision propagation

**Read:** [10](10_CONSTRAINTS_MANUAL_EDITS.md), [04](04_EVALUATION_CACHING.md).

Start with a full deterministic collision solver using a uniform grid or BVH. Define center height, source-dependent radius, winner ordering and whether boundary checking occurs before or after transforms. Only then attempt incremental solving.

**Exercise:** Insert one extra candidate near a tile seam and compare incremental output against a full rebuild. Build adversarial chains where one accepted/rejected item changes the fate of its neighbor and then the next neighbor. If the incremental solver cannot demonstrate equivalence, fall back to full recompute for the affected dependency component.

**Pass:** final accepted IDs and transforms match a full rebuild under a declared deterministic order; no collision escape through tile borders.

## Module 10 — Persistent individual edits (CS Edit)

**Read:** [10](10_CONSTRAINTS_MANUAL_EDITS.md), [20](20_SERIALIZATION_AND_ASSETS.md).

Store sparse transform/source/delete overrides keyed by stable instance identity and separate persistent manual additions. Define orphan policies; never silently discard edits when an underlying generator or receiver changes.

**Exercise:** Manually move a foreground tree, increase grass density, modify another source weight, then save/reopen and Undo. Change tree seed and force the override to become orphaned; test deliberate retain-as-manual and disabled-pending-relink policies.

## Module 11 — Effects and explicit dependency stages

**Read:** [11](11_EFFECTS.md), [24](24_INTERACTION_MATRIX.md).

Implement a small typed field graph first (attribute reads, arithmetic, curve evaluation and approved scene queries). Add a declarative read/write manifest, stage constraints, cycle rejection, deterministic evaluation and a safe error mode. A general expression parser is optional at this stage.

**Exercise:** Make a distance-to-path effect change tint; verify zero distribution/surface work is invalidated. Then use an effect to change source scale and verify collision/LOD/bounds are marked dirty. Reject an invalid cycle involving mutually dependent scatters.

## Module 12 — Viewport, render, LOD and material attributes

**Read:** [12](12_OUTPUT_RENDERING.md), [19](19_RENDERER_ADAPTERS.md).

Create separate per-instance arrays for full accepted population, preview subset and renderer export; keep shared source geometry. Implement stable point-cloud previews, coarse culling, renderer capability negotiation, animated sample caching and per-instance material/tint attributes.

**Exercise:** Change preview quality from 20% to 50% and confirm IDs only increase (under the stable threshold policy). Orbit the viewport with static rules and confirm the distribution generator does not rerun. Compare a direct render-output checksum with results after save/reopen.

**Pass:** switching preview modes cannot change authoritative placement; rendering fallback is explicit rather than silently dropping unsupported features.

## Module 13 — Persistence, host events and recovery

**Read:** [13](13_3DSMAX_INTEGRATION.md), [20](20_SERIALIZATION_AND_ASSETS.md).

Implement versioned scene serialization and reference resolution. Exercise cloning, merging, XRef/source deletion, missing maps, changing units, 3ds Max scene Undo/Redo, and render during active scene edits. Ensure snapshot -> compute -> publish checks exact input revisions before commit.

**Exercise:** Save with populated caches and reopen after deleting all derived caches; the original authoring document must remain sufficient to rebuild identically. Simulate worker cancellation and deliberate stale completion order.

## Module 14 — Full landscape validation

**Read:** [17](17_IMPLEMENTATION_RECIPES.md), [15](15_TESTS_BENCHMARKS.md), [16](16_ROADMAP.md).

Build the tutorial-style scene: trees exclude grass around trunks; painted flowers form clustered beds; a path excludes grass but generates rocks along its corridor; a manually edited foreground tree stays fixed; the same terrain is shared across scatters. Change path, brush, source, slope, source tint, and camera independently.

**Pass:** outputs satisfy 50 interaction cases in [24](24_INTERACTION_MATRIX.md), survive save/reopen and Undo/Redo, and meet measured latency/memory budgets agreed for Cyrus's target machines. When comparing to ForestPack, record observed differences rather than forcing unsupported numerical equivalence.

## Suggested method for each module

1. Make a small **artist-intent card** showing the starting scene, action, and desired outcome.
2. Write a behavior contract, using the feature template.
3. Capture the official reference behavior or mark it unverified.
4. Write a minimal standalone numerical/geometry prototype with saved input data.
5. Write deterministic unit tests and failure tests.
6. Integrate with the 3ds Max host behind main-thread-safe snapshots.
7. Compare incremental output to full rebuild and record timing/memory before optimizing.
8. Put the decision, alternatives rejected, and evidence in [22](22_SOURCES_DECISION_LOG.md).

## Reading map for artists and programmers

For an **artist**, learn modules 02, 04, 05, 06, 07, 08, 10, 12 and 14 first, focusing on the intended visual consequences. For a **C++ developer**, start with 01, 03, 09, 11 and 13 because errors there can destabilize every later feature. For a **technical director**, prioritize scope, version capability policy, deterministic outputs, render parity and regression tests.

This is a learning and verification sequence, not evidence that ForestPack's private algorithms match the prototypes. The goal is to create a system with equivalent useful artist behaviors and explicit, testable engineering contracts.
