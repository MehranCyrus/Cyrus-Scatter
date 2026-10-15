# 24 — Detailed control-interaction and evaluation-precedence matrix

The most difficult part of a ForestPack-class scatter engine is not creating individual controls; it is defining their **composition**. This is an explicit matrix of interactions requiring implementation contracts and tests. Where ForestPack publishes a behavior, a source is named; otherwise the result is an independent Cyrus policy to select/verify.

## 1. Evaluation stage vocabulary

| Symbol | Stage | Typical output |
|---|---|---|
| G | Generator | Candidate anchors and base coordinates |
| S | Surface | World hit, normal, UV, attachment |
| A | Area | Eligibility, per-area contribution, boundary distances |
| D | Density | Probability/threshold rejection |
| Q | Source Choice | Species/geometry ID or intentional empty |
| T | Transform | Random translation, orientation, scale |
| E | Effects | Attribute modifications (stage dependent) |
| B | Boundary | Pivot/size/element validity |
| C | Collision | Accepted/rejected population |
| M | Manual | Overrides, pins, explicit additions |
| O | Output | Camera, LOD, preview, renderer material/animation |

This notation is not one fixed order; for example, `A` can include generator-specific contributions and `E` can run before/after `C` depending on declared write sets. The planned scheduler constructs a graph from actual dependencies.

## 2. Paired-control interaction matrix

| ID | Controls combined | Central issue | Proposed safe behavior | Test |
|---|---|---|---|---|
| X-001 | Density + Source probability | Existence vs species | Independent keyed random channels | T-SRC-01 |
| X-002 | Density + Collisions | More candidates, limited survivors | Separate stats and deterministic winner | T-COL-01 |
| X-003 | Source probability + Collision radius | Species affects acceptance | Choose source before shape/collision | T-COL-02 |
| X-004 | Color ID + Probability | Which rule wins | Color ID overrides normal weights in matching mode [FP-DOC] | T-SEL-03 |
| X-005 | Clusters + Density | Cluster patch size shouldn't implicitly mean count | Spatial species field independent of candidate positions | T-CL-04 |
| X-006 | Clusters + Area Source Subset | Dominant source may be disabled locally | Re-normalize only allowed eligible sources | T-CL-05 |
| X-007 | Image map + UV surface | Mapping domain interpretation | Explicit UV mapper/channel | T-UV-01 |
| X-008 | UV placement + Area projection axis | Which space defines region | Area uses declared projection axis [FP-DOC] | T-UV-02 |
| X-009 | UV mode + Paint Area | Published restrictions vary by context | Mark specific combo support, test target version | T-UV-03 |
| X-010 | XY receiver + Spline Include | Surface vs coverage | Receiver active, unrestricted Surface Include off | T-AREA-04 |
| X-011 | Ordered Include + Exclude | Exclude only previous contributions | Stack evaluated bottom-to-top [FP-DOC] | T-AREA-05 |
| X-012 | Exclude + later Include | Reintroduction after exclusion | Preserve later Include contribution | T-AREA-06 |
| X-013 | Two overlapping Includes | Double generation/overlap | Preserve unless explicit dedup policy | T-AREA-07 |
| X-014 | Local source selection + Global weights | Local pool normalized how? | Typed inherit/filter/override | T-AREA-08 |
| X-015 | Local density + Global density | Multiply or replace? | Explicit combiner; commercial rule to verify | T-AREA-09 |
| X-016 | Local scale + Global scale | Transform precedence | Chosen multiplication/replace policy | T-TRANS-10 |
| X-017 | Exclusion + Density Falloff | Density near edge | Distance field drives candidate acceptance | T-FALL-11 |
| X-018 | Exclusion + Scale Falloff | Height/size near edge | Separate scale curve | T-FALL-12 |
| X-019 | Height-only + Source radius | XY collision footprint should not shrink due to height-only | Separate effective height and footprint | T-FALL-13 |
| X-020 | Invert curve + Other areas | Border band can re-add population | Area-specific ordered field | T-FALL-14 |
| X-021 | Open spline + Path generator | Band vs evenly spaced series | Different provider types | T-PATH-15 |
| X-022 | Force Open + Closed loop | Corner/seam definition | Open-corridor boundary with explicit cap rule | T-PATH-16 |
| X-023 | Random translation + Area boundary | Can leave region after test | Parity mode may allow overflow [FP-DOC] | T-TRANS-17 |
| X-024 | Source scale + Collision radius | Radius grows/shrinks? | Recompute shape from evaluated transform | T-COL-18 |
| X-025 | Random scale + Size boundary | Footprint changes | Boundary after effective bounds | T-BOUND-19 |
| X-026 | Effect moves item + Surface hit | Z/normal may become stale | Reproject if requested/required | T-FX-20 |
| X-027 | Effect moves item + Collision | Previously valid placement can overlap | Effects before occupancy or revalidate | T-FX-21 |
| X-028 | Effect hides item + Collision | Does hidden reserve occupancy? | Stage-specific choice explicit | T-FX-22 |
| X-029 | Effect changes source + Transform | New source may have different pivot/dimensions | Recompute dependent transform/bounds | T-FX-23 |
| X-030 | Effect tint + Geometry | Color shouldn't rebuild positions | Shading-only dirty set | T-FX-24 |
| X-031 | Camera LOD + Source animation | LOD source sample state different | Resolve LOD and time per output | T-OUT-25 |
| X-032 | Camera density + Render visibility | Camera motion can change candidates | Explicit camera dependency; warned | T-CAM-26 |
| X-033 | Preview max items + Final render | Preview may omit instances | Final accepted population unaffected | T-VP-27 |
| X-034 | Edge trimming + Shader opacity | Existing cutouts must survive | Idempotent material integration | T-EDGE-28 |
| X-035 | Manual pin + Collision | Pin may overlap generated neighbor | Pin-priority or explicit overlap override | T-EDIT-29 |
| X-036 | Manual pin + Area Exclude | Does exclusion hide pin? | Preserve intent, warn/rebind policy | T-EDIT-30 |
| X-037 | Density + Manual overrides | Candidate identity may persist | Keep keyed candidate IDs/tombstones | T-EDIT-31 |
| X-038 | Seed change + Manual overrides | Candidate identity policy | Persist stable anchors, explicit remap | T-EDIT-32 |
| X-039 | Receiver topology change + Paint | Surface anchor invalid | Orphan/rebind; don't silently move | T-SURF-33 |
| X-040 | Receiver UV change + Paint | UV masks change mapping | UV revision invalidation | T-SURF-34 |
| X-041 | Stacked XY receivers + Random Seed | Identical XY may have identical random | Receiver-ID salted randomize-stacked option [FP-DOC] | T-SURF-35 |
| X-042 | Tree Exclude Grass + Tree moves | Downstream update | One-way dependency and spatial mask invalidation | T-GRAPH-36 |
| X-043 | Tree ↔ Grass mutual reference | Cycle | Error/frozen-input policy | T-GRAPH-37 |
| X-044 | Asset absent + Manual replacement | Preserve source binding and edits | Missing-source placeholder/orphan info | T-SAVE-38 |
| X-045 | Preset load + Scene references | External links may not be part of preset | Preset scope declared and previewed | T-SAVE-39 |
| X-046 | Undo paint + Pending job | Old result can overwrite Undo | Job token/revision check | T-THREAD-40 |
| X-047 | Render cancellation + Cache eviction | Use-after-free source handles | Renderer owns sample buffers until done | T-RND-41 |
| X-048 | Group source + Boundary Edge | Element definition differs by grouping | Explicit child/element semantics | T-RND-42 |
| X-049 | Path sequence + Disabled source | Intentional empty slots in source sequence | Define empty item behavior, test | T-PATH-43 |
| X-050 | Source tint + Per-element tint | Color-level composition order | Typed blend policy with stable IDs | T-MAT-44 |

## 3. Example detailed interaction: Source selection × Collision × Area

**Setup:** one inclusion area, three species: A small grass, B large shrub, C empty source. Weight ratio 60:30:10. Candidate grid fixed.

Possible stage orders:

`G → A → D → Q → T → C` (source influences footprint and occupancy).

`G → A → C → Q → T` would run collisions without knowing whether an item is empty or large—making it impossible to reproduce source-dependent sphere radii without later correction. Choose first as initial Cyrus design.

Test procedure: change B weight while keeping candidate set and random selection channels fixed. Candidate positions remain unchanged. Source choices change, so collision acceptance may legitimately change. Report separate candidate, source-empty and collision-reject counts. Check manual overrides on IDs whose chosen source changed.

## 4. Example detailed interaction: Density falloff × Scale falloff × source-specific collision

**Setup:** shrubs near a curved path; density declines toward path; vertical scale declines; radius derived from source XY footprint.

- Evaluate path distance once and cache as reusable scalar.
- Density curve controls candidate acceptance using keyed threshold RNG.
- Height-only scale controls Z, not XY collision footprint.
- Uniform scale influences XY radius if enabled.
- Collision result can still affect density appearance near edge.

If falloff is inverted, an outer band may appear, but it should not reverse or bypass unrelated Area Include/Exclude precedence unexpectedly. Compare visual coverage map with accepted instances.

## 5. Example detailed interaction: Painting × Undo × asynchronous rebuild

**Timeline:** Stroke S1 begins; evaluator A starts. Stroke S2 begins; evaluator B starts. User hits Undo of S2. Evaluator A and B finish out of order.

Correctness policy: authoring model revision increments at each state transition. Publish occurs only if complete consumed snapshot revisions match the current model. The UI keeps its last valid result or displays a clearly labeled draft while waiting; no evaluator may overwrite undone state. Undo restores strokes/tiles and reschedules exactly relevant evaluation.

## 6. Interaction-test outcome schema

```yaml
id: X-027
controls: [FX.TranslatePosition, Collision.Enable]
referenceEvidence: unverified
cyrusPolicy: effect-pre-constraint
expectedDirtyStages: [effect, surfaceReproject, boundary, collision, final]
fixture: scene_fx_move_then_collision
assertions:
  - no accepted overlap under chosen sphere policy
  - incremental output equals full rebuild
  - surviving unaffected IDs retain random rotation
persistence: save_load_and_undo
rendererCheck: not_required
```

Every matrix entry must eventually become a fixture or explicit declared unsupported combination. Maintain the matrix as an evolving engineering specification, not static marketing content.
