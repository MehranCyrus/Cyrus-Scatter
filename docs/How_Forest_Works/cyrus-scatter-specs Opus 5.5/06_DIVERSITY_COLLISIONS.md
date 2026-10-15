# 06: Diversity and collisions

## 1. Purpose and scope

This specification defines S6 model selection and S9 collision culling. It also defines the GeometryTable that makes model choice stable despite UI list reordering, random probability normalization, disabled gap items, per-area subsets, Sequence mode, Match Color ID on Map, and Clusters. S9 resolves virtual collision spheres after S7 has produced final transforms and scale. It supports the documented global Radius multiplied by per-item Collision Radius, Collision Height, viewport preview, and a Cyrus policy for the observed Smallest Plant Size behavior.

The stage order is the one fixed by 00_ARCHITECTURE.md: S6 runs after S5 density, S7 runs transforms, S8 checks boundaries, and S9 resolves collisions. Do not move collision into S1 just because a lattice has a convenient neighbor relation. Radius depends on the chosen geometry and final scale, and tiled spatial-hash resolution must see candidates from adjacent tiles.

This document extends 00's `Population`, `StageContext`, `IStage`, `GeometryTable`, `ItemFlags`, `SharedCacheRegistry`, and DirtyBits. The core contains no Max headers. Max geometry, mesh dimensions, material colors, and source metadata are converted by S0 into immutable `GeometrySnapshot` records.

## 2. Forest behavior to match

[FP-DOC] Geometry-list Probability values drive Random diversity. Values are normalized internally when their sum is greater than 100 percent. A disabled item still consumes its portion of the selection distribution and creates a gap. See [Add Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry).

[FP-DOC] Image diversity offers Random, Match Color ID on Map, and Clusters. Match Color ID chooses the closest Geometry List Color ID, ignores Probability, and exposes Noise. A disabled item with a matching color is the documented way to create holes in this mode. See [Image Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode).

[FP-DOC] Clusters expose Size in scene units, Roughness from smooth to rough, Blurry Edge from sharp to blurred, and Noise for random item substitutions. The documentation describes grouping same-type items, but does not disclose its private field or partition algorithm.

[FP-DOC] Image mode collision uses virtual bounding spheres. The sphere size is the product of the global distribution Radius and per-geometry Collision Radius, both percentages of item size. Collision Height offsets the sphere center along Z. Reference mode exposes equivalent Enable, Radius, Height, and Preview on Viewport controls. See [Image Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode), [Reference Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode), and [Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry).

[FP-OBS] The tutorial and UI material use a Smallest Plant Size collision option in some versions or workflows. The current public reference does not define those exact labels. We implement it as a deterministic priority and radius policy, label it as observed, and keep a version switch for Forest Lite comparison.

[FP-DOC] Forest warns when more than 50 percent of candidates are discarded by collisions. Current release notes say collision checking was extended to Path, Reference, and PFlow in 9.3.5. See [9.3.5 release](https://www.itoosoft.com/blog/forestpack-935-released). This is target-version evidence, not proof of behavior in all older releases.

[UNKNOWN] The public documentation does not specify collision priority, exact cluster algorithm, cross-Forest pairwise collision, perceptual color space, or the exact semantics of Smallest Plant Size. The choices below are deliberate Cyrus designs and are tested against Forest Lite without being presented as private Forest implementation facts.

## 3. Parameters

The internal percentage representation is 0 to 1. A scene-unit value is stored in system units. Dirty groups follow 00's naming. Changes to geometry dimensions or collision radius invalidate S6 through S12 because model selection and final sphere size can change.

| UI name | Internal name | Type | Default | Range and units | Rollout | DirtyBits group | Notes |
|---|---|---|---|---|---|---|---|
| Diversity mode | `diversity.mode` | enum | Random | Random, Sequence, MatchColorID, Clusters | Diversity | `D_GEOM_LIST` or `D_DIST_MAP` | S6 policy. |
| Geometry list | `geometry.entries` | entry list | empty | GeometryTable entries | Geometry | `D_GEOM_LIST` | Immutable entry IDs, separate UI order. |
| Probability | `geometry.probability` | float | equal weights | 0 to 1 | Geometry | `D_GEOM_LIST` | Normalized at evaluation. Disabled entries retain mass. |
| Disabled | `geometry.disabled` | bool | false | on or off | Geometry | `D_GEOM_LIST` | Selection gap, not deletion. |
| Color ID | `geometry.colorId` | Color3f | neutral gray | RGB or project color | Geometry | `D_GEOM_LIST` | Used by Match Color ID. |
| Select Models | `area.selectModels` | subset of entry IDs | all | GeometryTable IDs | Area | `D_AREA_GEOM(areaId)` | Applied before probabilities. |
| Sequence mode | `diversity.sequence` | enum | UI order | UI order, stable ID order | Diversity | `D_GEOM_LIST` | Explicitly authored sequence basis. |
| Color space | `diversity.colorSpace` | enum | OKLab | sRGB, linear RGB, OKLab, CIE Lab | Diversity | `D_DIST_MAP` | [DESIGN] OKLab default for nearest color. |
| Color Noise | `diversity.colorNoise` | float | 0 | 0 to 1 | Diversity | `D_DIST_MAP` | Probability of alternate color choice. |
| Cluster Size | `clusters.size` | double | 2000 | greater than 0 scene units | Diversity | `D_DIST_MAP` | [FP-OBS] Tutorial scale. |
| Roughness | `clusters.roughness` | float | 0.5 | 0 to 1 | Diversity | `D_DIST_MAP` | 0 smooth, 1 rough. |
| Blurry Edge | `clusters.blurryEdge` | float | 0.25 | 0 to 1 | Diversity | `D_DIST_MAP` | Blend width relative to cell size. |
| Cluster Noise | `clusters.noise` | float | 0.05 | 0 to 1 | Diversity | `D_DIST_MAP` | Substitution probability. |
| Cluster seed | `clusters.seed` | u64 | object seed | any | Diversity | `D_DIST_MAP` | Stable field seed. |
| Collision Enable | `collision.enabled` | bool | false | on or off | Collisions | `D_COLLISION` | Render default may force on in Render mode. |
| Global Radius | `collision.radius` | float | 1.0 | 0 to 1 | Collisions | `D_COLLISION` | Percentage multiplier. |
| Collision Height | `collision.height` | float | 0 | -2 to 2 item heights | Collisions | `D_COLLISION` | Sphere center offset relative to item height. |
| Per-item Collision Radius | `geometry.collisionRadius` | float | 1.0 | 0 to 1 | Geometry | `D_GEOM_LIST` | Multiplies global Radius. |
| Radius basis | `collision.basis` | enum | Max dimension | width, height, diagonal, bounding sphere | Collisions | `D_COLLISION` | [DESIGN] Explicit to avoid source ambiguity. |
| Smallest Plant Size | `collision.policy` | enum | Hash | Hash, Lattice, LargestFirst, SmallestFirst | Collisions | `D_COLLISION` | Observed label mapped to priority policy. |
| Preview on Viewport | `collision.previewViewport` | bool | false | on or off | Collisions | `D_COLLISION` | Avoids expensive viewport rebuild by default. |
| Cross-object collisions | `collision.crossObject` | bool | false | on or off | Collisions | `D_COLLISION` | [DESIGN] Requires registry snapshot. |
| Collision warning | `collision.warnDiscarded` | bool | true | on or off | Diagnostics | `D_COLLISION` | Warn when discarded fraction exceeds 50 percent. |

## 4. Data structures

```cpp
struct GeometrySnapshot {
    u32 entryId;                 // authored immutable ID
    std::string name;
    Bounds3d localBounds;
    Vec3d pivot;
    float width, height, depth;
    float collisionRadius;       // normalized UI multiplier
    Color3f colorId;              // authored Color ID
    bool disabled;
    u32 sourceVersion;
};

struct GeometryTable {
    std::vector<GeometrySnapshot> byIndex;
    std::unordered_map<u32, u16> indexByEntryId;
    std::vector<u16> sequenceOrder;
    AliasTable randomAlias;
    u64 tableVersion;
};

struct AreaModelSubset {
    std::vector<u16> tableIndices;
    AliasTable alias;
    std::vector<u16> sequence;
    u64 version;
};

struct CollisionSphere {
    Vec3d center;
    double radius;
    u64 priority;
};

struct CollisionStats {
    u64 considered, accepted, discarded;
    u64 broadTests, narrowTests;
    u64 crossTileTests;
    double maxRadius;
};
```

The GeometryTable is rebuilt in S6 preparation from authored entry IDs and the current scene snapshots. `Population.geomId` receives a table index, as required by 00, while overrides retain the authored entry ID. A disabled table entry is still present and receives a valid table index. Its chosen candidate is not set to `F_CULL_DENSITY`; it is selected as an intentional gap and remains distinguishable in diagnostics.

### 4.1 GeometryTable resolution

Resolve entries in this order:

1. Read the authored UI order and immutable `entryId`.
2. Resolve each source to a `GeometrySnapshot` in S0, including dimensions and collision metadata.
3. Remove missing entries from the selectable set only if they are invalid; retain a gap record and diagnostic so indices do not silently shift during an evaluation.
4. Build `indexByEntryId` and `sequenceOrder`.
5. For each area, resolve `Select Models` entry IDs to table indices. Missing IDs are ignored with a warning. If the subset is empty, the area produces gaps rather than falling back to all models.
6. Build a normalized alias table for random selection and a cumulative table for debugging and very small subsets.

The GeometryTable's order is not the same as UI order. A model list reorder changes the explicit Sequence order if the user selected UI order, but Random selection is keyed by authored entry identity and the normalized subset. The default Random policy preserves selection probabilities across harmless UI reorder. If a source's dimensions change, its radius changes, but its entry ID and key remain.

## 5. Random diversity and Sequence

### 5.1 Probability normalization and disabled gaps

For a selection set `S`, let `w_i = max(0, probability_i)` for every entry, including disabled entries. If `sum(w) = 0`, use equal mass for all entries in `S`, including disabled entries, and issue a diagnostic. Otherwise normalize `p_i = w_i / sum(w)`. This matches the documented normalization when probabilities exceed 100 percent and preserves the meaning of a disabled entry as an intentional blank.

If an area subset contains three models with weights 0.6, 0.3, and 0.1, and the third is disabled, 10 percent of selected candidates become gaps. If the disabled row is removed instead, visual density changes, which is not acceptable. The UI should show both effective geometry probability and gap probability.

Use Vose's alias method for large tables. A cumulative table is simpler for tiny area subsets and is useful as a cross-check. Both consume one stable uniform `u`:

```cpp
u32 chooseAlias(const AliasTable& a, StableKey key) {
    float u = stable01(key, Purpose::ModelSelection);
    float v = stable01(key, Purpose::ModelSelection, 1);
    u32 col = min(u32(u * a.n), a.n - 1);
    return v < a.prob[col] ? col : a.alias[col];
}
```

Build the alias table with deterministic index order. If a weight is NaN, clamp it to zero and count it. If an entry is disabled, return its index and set a `selectedGap` stat. Never consume a variable number of random values per item, since that would make adding a model reshuffle unrelated candidates.

### 5.2 Per-area Select Models

S3 records the candidate's `areaIndex`. S6 resolves that area to an `AreaModelSubset`. The subset is an allow-list of immutable entry IDs, not UI array positions. Random normalization happens after subsetting. Thus an area with models Oak 70 and Pine 30 can exclude Pine without leaving a hidden 30 percent blank unless the user deliberately includes a disabled gap entry.

For linked areas, resolve the local override after link inheritance. An empty explicit subset means no models, while an unset subset means all GeometryTable entries. This distinction prevents a user clearing a list from accidentally re-enabling every model.

### 5.3 Sequence mode

Sequence is deterministic cycling, not weighted random choice. The default sequence list is the selected subset in UI order. An optional Stable ID sequence sorts by immutable entry ID for projects that must survive UI reorder. Candidate sequence ordinal is:

```text
ordinal = sourceSequenceBase + candidateOrdinalWithinSource
index = sequence[ordinal mod sequence.size]
```

For Image mode, use `(tileY, tileX, pixelY, pixelX)` as the candidate ordinal, not the worker append order. For Path, use path source order and sample index. For Reference, use reference node order, face index, and face sample. For particles, sort by stable particle ID before assigning an ordinal. A disabled sequence item makes a gap. Sequence ignores Probability, but S6 still reports the configured probabilities to avoid a misleading UI.

## 6. Match Color ID on Map

In this mode each surviving candidate has a map color sample from S1. The map is not converted to grayscale for selection. Geometry probabilities are ignored. For every candidate, choose the geometry entry whose Color ID is nearest in the selected color space. If the chosen entry is disabled, retain a gap. If two colors tie, choose the lower immutable entry ID, not floating point iteration order.

[DESIGN] Convert colors from source sRGB to linear RGB, then to OKLab by default. OKLab has a more perceptually uniform distance than RGB for this nearest-color operation and is robust for saturated vegetation colors. Preserve a compatibility option for direct RGB, because Forest's public docs do not specify its color-space conversion. Distance is squared Euclidean in the chosen space. For alpha, ignore alpha unless a map channel mode explicitly requests it.

A color index can accelerate large tables. A GeometryTable normally has few entries, so a linear scan is clearer and makes ties easy. For 256 or more entries, build a deterministic k-d tree with entry ID tie breaks.

### 6.1 Color Noise

Noise should change the chosen model without making the base color classifier unstable. Let `n` be the configured Noise amount. Draw `r = stable01(key, Purpose::ColorNoise)`. If `r >= n`, use the nearest entry. Otherwise choose among the nearest `k` entries with inverse-distance weights, including a zero-distance exact match as dominant. A disabled entry remains a possible gap. This gives Noise 0 exact color matching and Noise 1 a controlled local alternative rather than a wholly unrelated tree.

```cpp
u16 matchColor(const Color3f c, const ColorTable& t, StableKey key, float noise) {
    auto nearest = t.kNearest(toColorSpace(c), 4);
    if (stable01(key, Purpose::ColorNoise) >= noise) return nearest[0].index;
    float u = stable01(key, Purpose::ColorNoise, 1);
    return weightedPick(nearest, inverseDistanceWeights(nearest), u);
}
```

Keep the original map color in the candidate sidecar for Effects and Stats. Match Color ID is a model assignment and therefore happens in S6 after S5 density. A map that creates density and color can use separate channel or sampler instances so grayscale and RGB semantics are explicit.

## 7. Clusters

### 7.1 Design choice

[DESIGN] Implement Clusters with jittered Voronoi cells, domain warp for Roughness, border-distance blending for Blurry Edge, and stable noise substitution. This is a concrete spatial-field abstraction rather than a claim that Forest uses Voronoi. It has three useful properties: characteristic region size is easy to control in scene units, the boundary is explicit for blur, and each candidate's output depends only on its position and stable key. It also avoids a flood-fill over all candidates, which would be expensive and unstable when candidates are culled or tiled.

Clusters require more than one selectable geometry entry. With one active entry, select it directly and report that cluster parameters have no visual effect. Disabled entries may serve as a cluster gap type, but the default cluster seed set excludes disabled entries when assigning base cluster labels unless the user includes a gap intentionally.

### 7.2 Field construction

Let `L = max(Size, epsilon)` be the desired cell size in scene units. Transform each candidate FL position into a cluster coordinate plane. For a 2D Image lattice use FL XY; for a Path use path arc length and signed offset; for Reference and Particle use FL XY unless an area surface explicitly supplies a local tangent plane. Cluster cells are evaluated in the same spatial frame as the candidate positions, so clusters do not change when worker tiles change.

At integer cell coordinate `(i,j)`, create one jittered site:

```text
site(i,j) = L * (i + 0.5 + qx * jitter, j + 0.5 + qy * jitter)
```

where `qx,qy` are stable values in `[-0.5,0.5]` from the cluster seed and cell coordinate. Jitter magnitude is `0.45 * Roughness`. For candidate coordinate `p`, evaluate a domain warp:

```text
w(p) = p + Roughness * 0.35 * L * vec2(noise(p/L*0.7), noise(p/L*0.7 + 31.7))
```

The nearest site label `c0` and second nearest distance `d1,d2` are found from the 3 by 3 neighboring cells. The border measure is:

```text
edge = clamp01((d2 - d1) / max(BlurryEdge * L, epsilon));
```

`edge=0` at a cell border and `edge=1` well inside a cell. To avoid a visibly uniform choice inside a cell, assign each cell a base model with a stable hash over `(clusterSeed, cellI, cellJ, subset version)`. The base model uses a cumulative or alias pick over the selectable subset. Probability weights therefore control how frequently cluster cells receive each type, while spatial continuity comes from the cell label.

Roughness affects site displacement and warp amplitude. At zero, the cells are regular but still seeded from a fixed lattice. At one, boundaries become irregular while cell sizes remain bounded. Blurry Edge blends the base cell model with the nearest competing cell model. Noise then performs candidate-level substitution.

### 7.3 Cluster assignment algorithm

```cpp
ClusterChoice chooseCluster(const Candidate& c, const ClusterParams& p,
                            const AreaModelSubset& subset) {
    Vec2 q = clusterPlane(c);                 // FL XY or local area plane
    Vec2 qw = domainWarp(q, p.roughness, p.seed);
    CellPair cells = nearestTwoJitteredSites(qw, p.size, p.roughness, p.seed);

    u16 a = modelForCell(cells.nearest.cell, subset, p.seed);
    u16 b = modelForCell(cells.second.cell, subset, p.seed);
    float blend = smoothstep(0.0f, 1.0f,
       clamp01((cells.second.distance - cells.nearest.distance) /
               max(p.blurryEdge * p.size, epsilon)));

    u16 chosen = a;
    if (blend < 1.0f && a != b) {
        float r = stable01(c.key, Purpose::ClusterEdge);
        chosen = r < blend ? a : b;
    }

    if (stable01(c.key, Purpose::ClusterNoise) < p.noise)
        chosen = chooseAlias(subset.alias, c.key.withCounter(1));
    return {chosen, cells.nearest.cell, blend};
}
```

The edge interpolation orientation above treats the nearest cell as dominant away from a border and gives the neighboring label a chance near the border. Implementers should write a one-dimensional two-cell test to confirm the visual convention. A disabled model returned by a cell remains a gap; substitution may select it if its authored mass is present.

`modelForCell` uses one stable random value per cell, not one per candidate. That is the critical cluster property. Candidate-level `ClusterEdge` and `ClusterNoise` use the candidate key and therefore remain stable when unrelated candidates are added. If a map threshold removes candidates, neighboring labels do not change.

Cluster cells are not generated as population entries. They are a pure field query with a small tile-local cache keyed by `(clusterSeed, cellX, cellY, subsetVersion)`. A candidate crossing a Cyrus job tile evaluates exactly the same cell because the domain coordinates are absolute in the selected cluster frame. For a path, use a path local coordinate and include path ID in the field seed to avoid unrelated paths sharing a boundary.

### 7.4 Ordering with probabilities and density

S5 density runs before S6 clustering, so density removes candidates without changing cell labels. Cell model assignment reads normalized probabilities at S6. This means changing a probability can change a whole cluster label, while changing density only removes members of the existing cluster. That is intentional and should be documented in the UI.

Clusters do not bypass per-area Select Models. First resolve the area subset, then build or retrieve its cell choices. If two areas overlap, each candidate retains its originating area and samples that area's field. A later Exclude does not cause a cell to be re-partitioned.

Collision runs after S7 and can remove the densest parts of a cluster. It must not reassign the candidate to another model after removal. This preserves the user's selected cluster pattern and makes Stats explainable. If the user wants a fill after collisions, they can increase density or change Size, not rely on a hidden second pass.

## 8. Collision model

### 8.1 Sphere radius

For a selected GeometrySnapshot `g`, compute a source size according to `collision.basis`. The default uses the maximum local dimension after global and per-item scales. A more faithful sphere basis can use the source bounding sphere. The collision radius is:

```text
r = globalRadius * g.collisionRadius * sourceSize * finalScaleMagnitude
center = finalPosition + surfaceUp * (collisionHeight * itemHeight)
```

`globalRadius` and `g.collisionRadius` are percentages represented as 0 to 1. If source size is zero, use a minimum radius of `epsilon` and count a degenerate item. Height is relative to the item height and follows the final surface or transform up axis, not always world Z. This matters for slopes.

[FP-DOC] The global and per-item multipliers are both percentages of item size and are multiplied. The public controls do not prove a particular size basis, so Cyrus exposes the basis and keeps it in the collision cache key.

A sphere does not imply exact mesh intersection. It is intentionally a cheap conservative broad approximation. Boundary S8 and collision S9 therefore have different statistics: a candidate may pass the point boundary and fail a sphere collision.

### 8.2 Priority policies

A collision resolver greedily accepts candidates in a deterministic priority order. It rejects a candidate if its sphere overlaps any previously accepted sphere. Available policies:

* **Hash:** priority is `stable64(key, CollisionPriority)`, ascending. This is the neutral default and avoids favoring map scan direction.
* **Lattice:** priority is tile Y, tile X, pixel Y, pixel X, then layer. This is useful for compatibility scenes that expect scan order.
* **Largest First:** sort by radius descending, then StableKey. This preserves large plants at the expense of small neighbors.
* **Smallest First:** sort by radius ascending, then StableKey. This is our [FP-OBS] Smallest Plant Size interpretation: small plants are granted priority and the collision sphere policy uses each item's actual radius. It does not mean that every plant is resized to the smallest item's radius.

Expose the policy instead of burying it. A future Forest Lite test can select the closest behavior. StableKey is always the final tie break. Sorting is done within and across tiles using deterministic key order; no worker completion order may affect acceptance.

### 8.3 Tiled spatial hash and halos

00 section 8 requires tiled deterministic collision resolution. Use a two-phase scheme:

1. Compute each sphere's cell range in a global spatial hash with cell size `C = max(maxRadius, epsilon)`. Insert a candidate into every overlapped cell.
2. Generate tile-local candidate lists with a halo of `maxRadius`. Sort each list by the selected priority.
3. In phase one, each tile produces provisional accepted candidates while testing all neighboring hash cells in its halo.
4. In phase two, resolve cross-tile conflicts by the global priority order. A candidate loses if any higher-priority accepted sphere overlaps it, even if that accepted sphere originated in another tile.
5. Publish `F_CULL_COLLISION` only after phase two. Merge in tile index then key order.

A simpler correctness-first implementation can perform one global ordered pass over hash buckets after all tile jobs build the index. This uses more memory but is easier to validate. The optimized version uses owner tiles and a conflict list. Every overlap pair is assigned to the tile of the lexicographically smaller owner index, and the pair is evaluated once.

```cpp
for (CandidateId id : candidatesInPriorityOrder) {
    if (!alive(id)) continue;
    bool overlap = false;
    for (Cell c : cellsFor(sphere[id]))
      for (CandidateId other : hash[c])
        if (accepted(other) && intersects(sphere[id], sphere[other])) {
            overlap = true; break;
        }
    if (overlap) markCullCollision(id);
    else accepted(id) = true;
}
```

The pseudocode is semantically global. A parallel implementation must ensure that a candidate cannot be accepted before every higher-priority candidate in its halo has been decided. Use priority waves or conflict components for this. Do not let two neighboring tiles accept independently and patch afterward: that can leave overlapping survivors.

The spatial hash key uses floor division for negative coordinates. A sphere exactly on a cell boundary is inserted into both cells with an epsilon expansion. Narrow phase uses squared double distance and `distanceSquared < (rA + rB)^2`; equality is non-overlap so touching spheres can coexist. Use a scale-aware epsilon only for numerical noise, not for a visible gap.

### 8.4 Preview and cross-object collisions

[FP-DOC] Reference controls include Preview on Viewport. [DESIGN] When Preview is off, viewport V uses no collision cull, but Render always runs collision if Enable is on. A viewport toggle can force S9 and show the same result as render, with a warning about rebuild time. Preview state is not part of the authored population; it selects whether V requests an S9 checkpoint.

[DESIGN] Cross-object collisions are optional and off by default. When enabled, a Cyrus object requests immutable published collision proxies from the `SharedCacheRegistry` or a dependency snapshot. Each proxy contains StableKey, world sphere, radius, source object ID, and publication version. Build one global spatial hash per evaluation group and use object ID as an additional tie break. Do not infer cross-object collisions from a Forest Area: public notes say Forest areas are exclusion fields, not proof of pairwise collision. Cross-object mode must detect dependency cycles and stale population versions.

A cross-object collision can make a render depend on evaluation order unless all participating populations are frozen first. Therefore S9 cross-object evaluation is a render barrier: gather populations, compute a group snapshot, then resolve. If an upstream population is unavailable, disable cross-object collision for that frame and emit a diagnostic rather than using a partial result.

## 9. Interactions and statistics

### 9.1 Stage order

The intended order is:

1. S1 generates candidates.
2. S2 and S3 resolve surfaces and area filters.
3. S4 computes falloff.
4. S5 density thins with stable scores.
5. S6 selects a geometry or intentional gap.
6. S7 applies final transform and scale.
7. S8 performs boundary checks.
8. S9 computes radii and collision culls.

The order is required by dependencies. Choosing a model before collisions makes per-item radius meaningful. Running collisions before S7 ignores random scale and path/reference alignment. Running clusters after collision can make the surviving pattern depend on rejection, which is visually and deterministically undesirable.

A disabled item selected by S6 is not passed to collision because it has no geometry and no sphere. It remains counted as a selected gap. A disabled model does not reserve space unless the user enables `collision.gapsReserveSpace` as a future design option. Probability and color match happen before clusters only in the sense that they define the selectable subset; Clusters itself owns the cell-level selection. Match Color ID and Clusters are mutually exclusive UI modes.

### 9.2 Stats

S6 reports:

* candidates entering diversity,
* active area subset size,
* probability sum before and after normalization,
* selected count per GeometryTable entry,
* disabled gap count,
* color distance mean and maximum,
* color-noise substitutions,
* cluster cell count, edge blends, and noise substitutions.

S9 reports:

* candidates entering collision,
* accepted spheres,
* discarded spheres, including fraction,
* broad hash inserts and pair tests,
* narrow overlaps,
* cross-tile conflicts,
* mean and maximum radius,
* counts by priority policy and geometry entry,
* viewport-preview versus render execution time.

Warn when `discarded / considered > 0.5`, matching the documented Forest warning. Also warn when the candidate count is zero because all selected models are disabled, which otherwise looks like a collision failure. Stats are deterministic and keyed by stage checkpoint version.

## 10. Pipeline integration, dirty bits, and caches

S6 consumes `D_GEOM_LIST`, `D_DIST_MAP`, and per-area subset bits. A GeometryTable checkpoint is cached per object and depends on source node version, dimensions, material color ID, entry IDs, and order. A probability edit rebuilds alias tables but does not invalidate S1 through S5. A Color ID edit invalidates S6 only in Random mode? It invalidates Match Color ID and any viewport color display in all modes; use the narrower downstream checkpoint when possible.

S9 consumes `D_COLLISION`, `D_GEOM_LIST` for dimensions and radii, and S7 transform outputs. A collision Radius, Height, or priority edit starts at S9. A geometry source dimension edit starts at S6 because it can change model selection metadata and S8/S9. A transform or random scale edit starts at S7. Cross-object mode adds the upstream population version to the cache key.

The collision hash is per evaluation and can be reused between viewport and render if the population version, transforms, radii, and collision policy match. Preview state itself does not alter the immutable population when the feature is disabled; it simply omits the S9 cull bit in a viewport ViewMask.

Worker jobs build private hash buckets or append collision records. Global resolution follows the deterministic policy. Cancellation is allowed for viewport evaluation, but a cancelled result is never published as a partially culled population. Render evaluations run to completion.

## 11. 3ds Max integration

The Geometry rollout uses a reorderable list backed by immutable entry IDs. Each row has Disable, Probability, Color ID, and Collision Radius. S0 extracts source bounds and material metadata from meshes, groups, billboards, proxies, and Forest LOD nodes. For a source whose dimensions are animated, the GeometryTable cache key includes time or an animation sample version.

The Diversity rollout has Random, Sequence, Match Color ID, and Clusters radio buttons. Per-area Select Models is a checklist using entry IDs. The map preview can display the sampled color IDs and cluster cells, with a deterministic legend. The collision rollout provides Enable, Radius, Height, Preview on Viewport, and the explicit priority policy. If Forest Lite tests indicate a Smallest Plant Size compatibility need, label the chosen policy in the UI as a compatibility preset rather than implying a private algorithm.

Notifications from a geometry source, probability, Color ID, or list order mark the precise DirtyBit. Max scene access is restricted to S0. The worker path receives only `GeometrySnapshot`, `GeometryTable`, and scalar parameters. Save the authored IDs, policies, seeds, and algorithm version in ParamBlock2 or versioned chunks; never save the resolved alias table or collision hash as truth.

## 12. Edge cases and failure modes

* **Empty GeometryTable:** S6 marks candidates as gaps and emits a diagnostic; no crash.
* **All weights zero:** equal weights are used, including disabled entries, with a warning.
* **Probability NaN or negative:** clamp to zero and count the correction.
* **Missing area subset entries:** ignore missing IDs; an explicitly empty subset means gaps.
* **Color tie:** lower immutable entry ID wins.
* **Missing map color:** use neutral gray only if map policy says fallback; otherwise gap and diagnostic.
* **One cluster model:** select it directly; cluster controls are inert.
* **Tiny Cluster Size:** clamp to a minimum related to scene precision and warn.
* **Huge Cluster Size:** evaluate only needed neighboring cells; do not allocate a whole grid.
* **Degenerate source bounds:** use epsilon radius and report source.
* **Negative scale:** S7 should encode mirror separately; collision radius uses absolute scale.
* **Zero collision radius:** accept without hash insertion, but still count the candidate.
* **NaN center or radius:** cull as invalid and set a diagnostic flag, never insert into the hash.
* **Sphere on a tile edge:** halo insertion and epsilon expansion ensure exactly one conflict decision.
* **More than 50 percent discarded:** issue the warning once per evaluation, with per-area detail.
* **Cross-object stale version:** abort cross-object mode for that frame rather than mixing snapshots.
* **Disabled selected model:** count gap, do not reserve collision space.

## 13. Performance targets

[DESIGN] Build a GeometryTable and alias table for 1,000 entries in under 1 ms. Assign Random diversity to 1 million candidates in under 20 ms on one worker group after the table is cached. A linear color match for 32 entries should remain under 30 ms per million candidates; use a color index only after profiling.

[DESIGN] For 1 million collision candidates with average radius lower than the spatial cell size, target fewer than 20 million broad hash pair tests and under 250 ms on 16 cores. Memory should be under 64 bytes per collision record plus hash overhead, with a streaming mode for render. Avoid a cell size based only on average radius: a single huge tree otherwise causes enormous neighbor lists. Use maximum radius per evaluation or a two-level hash for outliers.

The largest traps are unstable sort comparators, duplicate pair testing at tile boundaries, using source dimensions before final scale, and rebuilding cluster cells per candidate. Unit-test floor hashing, priority transitivity, and exact merge order. Profile cluster field queries and cache the nine or 25 neighboring cells per tile when candidate density is high.

## 13.1 Numerical robustness and viewport interaction

Collision arithmetic uses double precision even though published transforms may be float. Before hashing, subtract the per-chunk origin described in 00 section 3, then add it back only for render output. This prevents a scene at a large world coordinate from losing a millimeter-scale overlap to float quantization. Radius values are clamped to finite nonnegative doubles. A radius larger than the configured hard maximum is still legal as a policy input, but the job planner uses a coarse fallback bucket and reports that it may be expensive.

Use a strict total ordering for every comparator: compare the primary policy value, then area entry ID, then StableKey. Never compare floating point priorities with an epsilon inside a sort comparator because nontransitivity can produce different orders on standard library implementations. Convert Hash priorities to integers before sorting. For largest and smallest policies, quantize no values: compare the exact double radius, then identity. This makes equal geometry sizes deterministic.

The collision stage reads the viewport's `ViewMask` only for diagnostics and display policy. It must not use camera visibility to decide collision winners. A candidate hidden by a far clip still reserves no viewport draw slot, but a render-visible neighbor must produce the same S9 result whether the camera is close or far. This preserves 00's rule that view-dependent data lives in `ViewMask`, never in the population. If ViewMask requests camera density, the density factor is applied in V after S9, not by deleting a sphere during collision.

Viewport preview has two modes. With Preview off, V displays the published population with collision flags ignored in its optional diagnostic overlay, while render uses the collision checkpoint. With Preview on, the background evaluator runs S9 and publishes a new population version only when complete. A stale preview result can remain visible temporarily, but its version must be checked against `PopulationVersion`; do not combine a new ViewMask with an old collision population. The Stats panel marks the displayed result as `preview pending` or `render exact`.

When the viewport budget adds the global density multiplier in S5, it changes which spheres arrive at S9. The collision result is therefore not guaranteed to be a subset of the render result under a different budget, even though density acceptance itself is monotone. This is expected: a newly admitted candidate can win a collision under Hash or Largest First. To make this visible, report both pre-collision and post-collision counts and never describe viewport collision counts as a render estimate. Render uses the hard render budget from 00 and should warn if that budget clips before S9.

## 14. Tests and Forest Lite scenes

### Unit tests

1. Probability weights normalize to one above and below 100 percent.
2. Disabled entries retain their configured probability and produce gaps.
3. Alias and cumulative selection agree for a fixed set of hash values.
4. Reordering UI rows preserves Random selection but changes UI-order Sequence only.
5. Area subsets normalize only selected entries.
6. Color matching is stable, ties use entry ID, and OKLab differs predictably from RGB.
7. Color Noise zero is exact nearest color; one remains within the configured nearest set.
8. Cluster cells are unchanged by worker tiling and candidate removal.
9. Cluster Size, Roughness, Blurry Edge, and Noise each change only their intended field.
10. Collision priority policies produce the expected winner in a two-sphere overlap.
11. Hash and lattice policies are identical for one worker and many workers.
12. A sphere crossing a tile boundary is tested once and culled consistently.
13. Height changes only the sphere center, not its radius.
14. Radius equals global times per-item times source size times final scale.
15. Warning triggers at strictly more than 50 percent discarded.
16. Cross-object mode is invariant to object evaluation order after snapshot barrier.

### Golden compatibility scenes

* Three geometry entries with probabilities 60, 30, 10, with the third disabled.
* Two overlapping areas with different Select Models subsets.
* A color-ID gradient map with exact and near colors, including a disabled color.
* Cluster Size 2000 scene units, Roughness 0, 0.5, and 1, with each Blurry Edge and Noise endpoint.
* Full lattice with mixed small and large source bounds, testing all priority policies.
* Path, Reference, and Particle sources with collision enabled and viewport preview on and off.
* A sphere overlap crossing four core job tiles and negative coordinates.
* A cross-object scene where one upstream object updates between viewport and render.

Forest Lite comparisons must record the Forest version, renderer, map, geometry sizes, and whether collision preview is active. Match documented probability normalization, disabled gaps, color matching, cluster controls, and warning behavior first. Treat exact cluster boundaries and collision winners as [OPEN] until observed.

## 15. Open questions

* [OPEN] Does Forest normalize probabilities over disabled entries exactly as documented in all diversity modes?
* [OPEN] Which color space and distance does Match Color ID use, and how does it treat alpha and color management?
* [OPEN] Is Color Noise a nearest-neighbor perturbation, a pixel perturbation, or a random model replacement?
* [OPEN] What field or partition algorithm produces Forest Clusters, and does Size represent a diameter, cell side, or another measure?
* [OPEN] What exactly does Smallest Plant Size mean in the target UI/version?
* [OPEN] Is collision priority map scan, random, largest first, or another policy?
* [OPEN] Are collisions symmetric across separate Forest nodes, or only through Forest Area exclusion?
* [OPEN] Are Path, Reference, and PFlow collision controls available before 9.3.5, and which releases need gating?

## 16. Architecture feedback

00 says S6 writes `geomId` and S9 writes collision flags, which this document follows. It does not define a geometry source metadata table or a collision sidecar, so this specification adds `GeometryTable`, `AreaModelSubset`, and `CollisionSphere` as stage-local core records. The proposed cross-object collision mode is deliberately optional and does not change 00's default dependency model. The observed Smallest Plant Size label is represented as a selectable priority policy rather than silently changing the core collision contract.
