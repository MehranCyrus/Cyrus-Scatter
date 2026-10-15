**For Cyrus Scatter, we need to understand Forest Pack as a connected procedural system—not simply reproduce its buttons.** An option is only fully understood when we know what data it changes, which other options affect it, when it is evaluated, what it invalidates, and what happens in difficult cases.

I have now reviewed the core rollout documentation, associated helper and material documentation, several detailed tutorials, and the release notes. The latest release entry I could verify is **ForestPack 9.4.3, dated September 8, 2026**. This matters because older tutorials do not describe the complete current feature set. [Itoosoft Documentation](https://docs.itoosoft.com/changelog/tags/forestpack)

One important distinction throughout this explanation:

**Descriptions of Forest Pack’s behavior are based on its documentation. Equations, data structures, and architecture recommendations are my proposed ways to implement comparable behavior—not claims that I have access to iToo’s private source code.** I have not run these features inside 3ds Max during this investigation.

# 1. The fundamental model: what a scattering system actually contains

My architectural reading is that the numerous controls become much easier to understand when separated into these responsibilities:

| Responsibility | Question it answers |
|---|---|
| Source definitions | What objects can appear? |
| Placement generation | Where are the possible placements? |
| Areas and spatial fields | Where is placement allowed, and how does it vary spatially? |
| Surface evaluation | Where does a placement land, and what is the surface like there? |
| Instance properties | Which source, orientation, size, color, and animation state does it receive? |
| Constraints | Does it violate spacing, boundaries, or other restrictions? |
| Artistic overrides | What has the artist explicitly changed? |
| Presentation and rendering | How is the result displayed and delivered to the renderer? |
| Dependencies and persistence | What updates, what stays stable, and what is saved? |

These are **conceptual responsibilities**, not a claim about Forest Pack’s exact internal execution order. Its public interface exposes corresponding systems through Geometry, Distribution, Areas, Surfaces, Transform, Items Editor, Camera, Material, Effects, Animation, Display, and General. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin)

For Cyrus, I would represent a generated placement conceptually as:

```text
Instance
    stable identity
    source identity
    originating area / generator
    surface binding
    position, orientation, scale
    randomization keys
    material / tint variation
    animation sample
    visibility and rejection state
    manual overrides
```

Notice what is missing: a requirement to create a separate 3ds Max scene node for every plant.

The placement record and the thing used to display or render it should be separate concepts.

**That separation is the foundation for adding many features without making every feature rebuild everything.**

---

# 2. Geometry: the source list is a selection system

Forest Pack’s Geometry list supports library assets and scene objects, with per-source probability, Color ID, scale-related controls, offsets, collision settings, and material handling. It also supports groups and linked hierarchies, with controls affecting whether their members behave together. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry)

## Probability means relative weight

Suppose our source weights are:

| Source | Weight |
|---|---:|
| Grass A | 60 |
| Grass B | 30 |
| Flowers | 10 |

The natural mathematical model is:

\[
P(k)=\frac{w_k}{\sum_j w_j}
\]

Here that produces 60%, 30%, and 10%.

But with weights 6, 3, and 1, the result is the same. The values do not need to sum to 100.

**These probabilities describe source selection—not necessarily the final visible proportions.**

For example, in our own implementation, a large flower asset might be rejected more often by spacing checks than a small grass asset. The accepted population would then differ from the original selection probabilities.

That distinction needs to appear in statistics and documentation.

## Disabled geometry can represent an empty outcome

A subtle documented behavior: disabling a Forest source does not necessarily remove its probability from the selection process. It can leave empty placements. An official fence tutorial uses this to create missing planks; lowering the disabled source’s probability reduces the gaps. [ITOOSOFT](https://www.itoosoft.com/tutorials/modernbarn3)

For Cyrus, I would explicitly distinguish:

**Remove from selection:** redistribute its probability among remaining sources.

**Keep as empty choice:** retain its selection weight but emit nothing.

Those are different artistic operations. A single ambiguous “Disable” checkbox can hide that difference.

## Source dimensions affect more than appearance

For an independently implemented system, changing source dimensions can affect:

- The visual footprint.
- Collision and boundary tests.
- Translation measured relative to object dimensions.
- Point-cloud or bounding-box previews.
- Whether a group should be treated as one placement.

Therefore, source replacement is not always a harmless mesh swap.

Replacing a 30-centimeter shrub with a four-meter tree might preserve candidate identities while still requiring placement constraints to be reevaluated.

## Groups need an explicit contract

Forest Pack’s **Keep Group Hierarchy** changes whether members share transforms and culling behavior or are treated separately. Linked children can also be included from a source hierarchy. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry)

For Cyrus, a bench with attached planters should generally remain an arrangement. A collection of unrelated tree variants should generally be a selection pool.

**“A collection of source objects” and “one compound source” must not be the same data type.**

---

# 3. Distribution: candidate generation comes before the final population

This is one of the most important concepts.

A placement generator answers:

> Where could an object exist?

It does not necessarily answer:

> Which objects will survive all subsequent rules?

## 3.1 Image distribution

Forest Pack’s documented image-based model uses pixels as potential positions. In the traditional interpretation, white pixels produce placements and black pixels do not. Physical map size controls how that pattern occupies the scene. [ITOOSOFT](https://www.itoosoft.com/tutorials/basic)

The controls belong to different categories:

| Category | Meaning |
|---|---|
| Physical map dimensions | How large the repeating pattern is in scene units |
| Sampling resolution | How many potential positions the pattern provides |
| Offset and rotation | Where the pattern is situated |
| Threshold | How image values are accepted in threshold-based evaluation |
| Mapping coordinates | Which coordinates are used to evaluate the map |

Forest Pack distinguishes physical X/Y Units from procedural-map X/Y Pixels; bitmap resolution supplies its own pixel dimensions. Its candidate-density limit also counts potential positions that may ultimately produce nothing. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode)

### Why “density” can be misleading

Consider this simplified implementation model:

\[
\rho_{\text{candidate}}
\approx
\frac{P_xP_y}{U_xU_y}
\]

Here \(P_x,P_y\) are sample counts and \(U_x,U_y\) are physical tile dimensions.

If we halve both physical dimensions while retaining the same sample grid, candidate density becomes approximately four times larger.

That is a mathematical consequence of this model, not a measured Forest benchmark.

It explains why these should be separate concepts in Cyrus:

**Pattern size, candidate density, and accepted population.**

An artist may want larger patches without more plants, or more plants without smaller patches.

## 3.2 Binary masking versus grayscale density

ForestPack 9.3 introduced **Use as Density Map**, allowing grayscale values to control density rather than using the image only as a simple mask. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/whats-new/forest-pack-9-3)

A feasible implementation would assign every candidate a repeatable random value \(u_i\):

\[
\text{accept candidate }i
\quad\text{when}\quad
u_i < D(x_i)
\]

where \(D(x_i)\) is density between zero and one.

A value of 0.25 would then retain approximately one-quarter of candidates over a sufficiently large sample.

The important engineering detail is to **reuse the same \(u_i\)** when density changes. Otherwise, moving a density slider can reshuffle the entire population.

This improves stability at the candidate-selection stage. Later collision filtering can still change which instances survive.

## 3.3 Random species selection versus Color ID matching

Forest Pack’s **Match Color ID** chooses geometry according to the closest source color and ignores normal geometry probabilities. Its Random mode uses the probability system. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode)

These are fundamentally different selection rules.

A proposed Cyrus interface should distinguish:

```text
Density field:
    Should something exist here?

Species field:
    Which source should appear here?

Transform field:
    How should that source be transformed?
```

One texture can supply data for multiple purposes, but the semantics should remain explicit.

A red region used for species selection must not silently mean “high density” unless that is the configured operation.

## 3.4 Clustering

Forest Pack exposes controls for cluster size, boundary roughness, edge blending, and noise. These control spatial grouping of source types. [ITOOSOFT](https://www.itoosoft.com/tutorials/automatic-clustering)

The distinction is between:

**Independent variation:** each candidate chooses a species without a shared neighborhood pattern.

**Spatially correlated variation:** nearby candidates tend to choose related species.

A feasible implementation could construct a spatial species field, then sample it at candidate positions. Noise functions, cellular regions, or other field constructions are possible approaches; the documentation does not establish which private algorithm Forest Pack uses.

For Cyrus, I would define the controls by their visual consequences:

- **Size:** change the scale of species patches.
- **Roughness:** disturb their boundaries.
- **Mixing:** allow neighboring species to overlap near transitions.
- **Noise:** introduce occasional exceptions inside dominant patches.

The key is that **cluster size should not accidentally become another population-density control**.

---

# 4. Other distribution modes are different input providers

These modes should not be implemented as unrelated scatter engines. My recommendation is to make them providers of placement records with a common downstream representation.

## Path distribution

Forest Pack’s Path mode supports spline-based placement using spacing or vertices, source sequencing, offsets, positional variation, and orientation following the path. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode)

For an implementation, the difficult part is not creating points on a spline. It is defining *which* points.

Even spacing requires spacing by **distance along the curve**, rather than simply taking equal steps in the spline’s parameter.

A robust path provider needs rules for closed seams, endpoints, sharp corners, multiple splines, orientation, and whether jitter follows the path or moves away from it.

This is appropriate for repeated lamps or fence posts.

It is different from filling a band around a spline with irregular rocks.

## Reference distribution

Reference mode can derive placements from scene objects and their faces, inherit transforms, filter by material IDs, and match geometry by names. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode)

Its artistic purpose is:

> Preserve an externally authored layout while replacing or enriching its objects.

For Cyrus, stable identity should therefore derive from the referenced object and its placement identity—not from its current position alone.

Moving a CAD marker should move its associated tree, not create an unrelated tree with a new random appearance.

Face-derived identities need additional care: topology edits can change face indices.

## Particle Flow distribution

Forest Pack can consume Particle Flow particles and selected events, with inherited alignment and scale. Effects can access particle-related information. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/particle-flow-mode)

This is **Particle Flow as an input**.

That must be kept conceptually separate from using Particle Flow as an output or render-transport mechanism in another plugin.

For Cyrus, both could exist, but they should be different adapters connected to the same internal instance representation.

## RailClone integration

ForestPack 9.4.1 added RailClone segments as placement inputs through Reference mode. RailClone exports the relevant segments, and tags can map them to Forest geometry names. The documented integration requires RailClone 7.3.2 or later. [Itoosoft Documentation](https://docs.itoosoft.com/changelog/2026/06/17/forestpack-9_4_1)

The broader lesson is that a placement can originate from another procedural system while retaining meaningful identifiers and metadata.

**Do not reduce every external input to anonymous XYZ positions.**

---

# 5. Areas: an ordered spatial system, not just a collection of masks

Forest’s area types include splines, objects, other Forest objects, painted regions, and surfaces. Importantly, areas are evaluated **from the bottom of the list upward**, and an exclusion affects inclusion areas below it. [ITOOSOFT](https://www.itoosoft.com/tutorials/modernbarn1)

## Why order matters

Imagine this ordered stack:

```text
Top:       Include flower island
Middle:    Exclude path
Bottom:    Include garden
```

The path exclusion applies to the garden below it, not automatically to the later flower-island inclusion above it.

This means a universal expression such as:

```text
union(all includes) minus union(all excludes)
```

would not reproduce the documented behavior.

For Cyrus, each emitted candidate may need to retain **which inclusion area generated it**.

That provenance can determine which exclusions and local overrides apply.

## Surface assignment and surface inclusion are different

A receiving surface supplies geometric placement information. Its entry in the Areas list can also act as an inclusion source. Disabling that inclusion entry can stop the whole terrain from filling while retaining the terrain for placement under painted or spline-defined regions. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/areas)

This explains a common conceptual problem:

> “I painted a small region, so why is the entire terrain filled?”

The brush may be correct. Another inclusion source may still be active.

For Cyrus, the interface should separate **receiving geometry** from **coverage sources**.

## Spline interior versus spline corridor

Closed spline inclusion and a band around a spline serve different purposes. Forest’s **Force Open Splines** lets a closed spline behave as an open one, with thickness defining the surrounding band. [ITOOSOFT](https://www.itoosoft.com/tutorials/force-open-spline)

For our implementation, I would treat these as different region constructors:

```text
Closed polygon → interior region
Polyline + width → corridor region
Curve + interval → ordered placement sequence
```

The third belongs to Path distribution, not area filling.

## Object exclusions are not necessarily exact 3D collisions

Forest documents object exclusions as projected black-and-white bitmaps. Resolution controls accuracy, Scale adjusts the exclusion footprint, and Top Limit ignores geometry above a selected height. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/areas)

Top Limit is important for objects with overhangs: excluding by the whole building silhouette is not always equivalent to excluding its ground contact.

A mathematical consequence of rasterization is:

\[
\text{world-space pixel width}\approx \frac{W}{R}
\]

A 100-meter-wide footprint at 512 pixels has a pixel width of roughly 19.5 centimeters.

That is not a Forest accuracy measurement; it illustrates why one fixed resolution cannot guarantee equal accuracy for every scene scale.

For Cyrus, a quality control expressed as **target world-space error** could be more interpretable than a raw pixel count.

## Local area overrides

Forest supports restricting an area to selected source models and changing its distribution settings. Its newer controls also add per-area scale ranges. [ITOOSOFT](https://www.itoosoft.com/tutorials/modernbarn3)

For Cyrus, the essential design question is precedence:

> When an area supplies a local setting, does it replace, multiply, or otherwise modify the global setting?

Those are not interchangeable.

For example, a global scale of 1.2 combined multiplicatively with an area scale of 0.8 produces 0.96. Replacing the global value produces 0.8.

The public feature description is not enough to justify guessing every combination rule.

---

# 6. Falloff: one spatial measurement can drive several effects

Forest provides independent density and scale falloffs, with inclusion/exclusion ranges, editable curves, and inversion. Its track tutorial demonstrates using these controls to produce worn strips, contrasting stones, and vegetation transitions. [ITOOSOFT](https://www.itoosoft.com/tutorials/modernbarn2)

The common input is usually some measure of distance from a boundary.

A proposed implementation:

\[
t(x)=\operatorname{clamp}\left(\frac{d(x)}{R},0,1\right)
\]

\[
F(x)=f(t(x))
\]

Here \(d(x)\) is the chosen distance, \(R\) the range, and \(f\) the artist’s curve.

The same distance measurement can feed different outputs:

```text
distance to path
    → density multiplier
    → height multiplier
    → species transition
    → orientation influence
    → color variation
```

That is why a reusable spatial-query system is valuable.

## Density falloff and scale falloff are not equivalent

A density transition changes how many objects remain.

A scale transition changes the objects that remain.

Consider a planting bed near a path:

**Lower density:** fewer plants, with larger gaps.

**Lower uniform scale:** smaller plants in approximately the same arrangement.

**Lower height only:** shorter plants without narrowing their footprints.

Forest specifically provides an **Affect Height Only** option for scale falloff. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/areas)

For Cyrus, these should be tested independently and together. Combining them can change the visual character dramatically.

## The curve can describe more than a smooth edge

Our own curve could rise, fall, and rise again across the range.

That would allow bands or troughs rather than a simple fade.

The important implementation lesson is:

**Do not hard-code falloff as one linear formula and later bolt on a curve editor that cannot reproduce more complex profiles.**

Also, define what happens when multiple influences overlap. Multiplication, minimum, maximum, and ordered replacement produce different results.

---

# 7. Painting: separate authoring, evaluation, and display

Forest’s documented paint workflow includes include/exclude regions, paint and erase tools, brush sizing, pressure-sensitive sizing, and conversion between paint areas and splines. [ITOOSOFT](https://www.itoosoft.com/tutorials/modernbarn2)

That establishes user-visible capabilities.

It does **not** establish the current private storage format, cache architecture, or Undo implementation.

For Cyrus, I would separate painting into three systems.

## 7.1 Authoring representation

This stores the artist’s editable intent.

A possible representation includes stroke samples, brush radius, operation, receiver binding, and ordering. Another implementation could store editable boundaries or a raster field.

The correct choice depends on the editing contract.

Questions that must be answered include:

> Can an old stroke’s width be changed?

> Does paint follow a deforming receiver?

> Can the result survive topology changes?

> Does erasing remove authored coverage or merely hide current plants?

These decisions should come before performance optimization.

## 7.2 Evaluation representation

This answers queries such as:

```text
coverage at this point
distance to the painted boundary
which paint region owns this point
which local settings apply here
```

It need not be identical to the authoring representation.

For example, editable strokes could remain authoritative while compiled tiles accelerate coverage queries.

The critical requirement is that the compiled result matches the authoritative evaluator within the declared tolerance.

## 7.3 Display representation

The visible brush overlay and the visible plants should be independently displayable.

Otherwise, a plant rejected by spacing can look like missing paint.

For debugging, I would want four distinguishable views:

```text
Authored coverage
Generated candidates
Accepted instances
Displayed preview subset
```

An error at one stage should not masquerade as an error at another.

## Why history length matters

Suppose every mouse move evaluates every historical stroke for every preview point.

Even if the visible region is unchanged, the cost can rise as history grows.

My proposed improvement is not automatically “replace strokes with a bitmap.” It is:

**Keep the chosen editable authority, but maintain incremental current-result caches where they are beneficial.**

Dirty regions must include the brush footprint and any falloff influence. Collision filtering can require additional work beyond that region.

A locally edited mask does not guarantee a purely local accepted-instance update.

---

# 8. Surfaces: coordinate systems determine what “evenly scattered” means

Forest supports XY and UV surface modes, multiple receiving surfaces, alignment controls, altitude and slope restrictions, and terrain-data refresh behavior. XY mode projects placements along the Forest object’s local Z direction; UV mode uses surface mapping coordinates. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces)

## XY projection

This is naturally suited to terrain-like placement.

A candidate starts in a reference plane and is projected onto geometry.

But equal density in that plane is not equal density per square meter of a steep receiving surface.

For a simple, single-valued sloped surface:

\[
\rho_{\text{surface}}
=
\rho_{\text{projected}}\left|\mathbf n\cdot\mathbf z\right|
\]

At a 60-degree slope, this model produces half as many placements per actual surface area as on horizontal ground.

That is geometric reasoning, not a claim about all of Forest’s compensations or special cases.

## UV placement

UV coordinates make other surface orientations accessible, but introduce a different question:

> Do equal areas in UV space correspond to equal areas on the actual mesh?

Not necessarily.

A proposed surface-aware implementation can account for the mapping’s local area distortion. Without such compensation, stretched UV islands can produce uneven world-space density.

Therefore, Cyrus should distinguish:

**Uniform in projection space.**

**Uniform in UV space.**

**Uniform per actual surface area.**

Those are different promises.

## Normal alignment, altitude, and slope

Forest exposes orientation relative to the surface, altitude-based controls, slope limits, and a slope-fitting scale option with mode-specific behavior. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces)

For our implementation, the surface query should return more than a hit position:

```text
position
normal
surface identity
triangle / face identity
barycentric binding
UV coordinates
material ID
```

That one query result can support placement, texture sampling, slope filtering, alignment, painting attachment, and later reevaluation.

## Modern UV behavior differs from older tutorials

ForestPack 8 added area projection along selectable axes for UV surfaces. Therefore, older statements that areas categorically cannot work with UV surfaces are outdated. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/whats-new/forest-pack-8)

However, some individual combinations retain restrictions. They need feature-combination tests, not assumptions based on the presence of a UV checkbox.

---

# 9. Transform: values, probabilities, and spatial maps are different controls

Forest’s Transform system includes translation, rotation, scale, axis relationships, probability curves, and maps. Translation is expressed relative to source dimensions and may move an item outside its original region. Grayscale and RGB maps can control values, while Probability Map mode controls the strength of randomization. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/transform)

## A range is not a probability distribution

A scale range of 0.5–2.0 only defines the available interval.

It does not specify whether most objects should be small, large, or near the middle.

In a simple uniform implementation:

\[
s=s_{\min}+u(s_{\max}-s_{\min})
\]

To make large rocks rare, we need a nonuniform distribution.

One principled implementation uses a normalized probability-density curve, integrates it to a cumulative distribution, then samples its inverse.

This matters because simply evaluating an arbitrary graph at a random X value is not necessarily equivalent to treating that graph as a probability density.

Forest’s tutorial explicitly describes probability-curve height as relative likelihood across the configured range. [ITOOSOFT](https://www.itoosoft.com/tutorials/modernbarn2)

## Value map versus probability map

These two instructions differ:

> Set the rotation according to this texture.

> Allow more random rotation in bright parts of this texture.

In the first case, the map chooses a value.

In the second, it modulates variation.

For Cyrus, these should be named separately and previewed differently.

## Transform order is a behavior contract

Consider a boundary-adjacent plant.

If it is tested against the boundary and then translated, it can leave the region.

If it is translated and then tested, it may be rejected.

Similarly:

```text
choose scale → calculate collision footprint
```

is different from:

```text
calculate footprint → change scale afterward
```

A comparable implementation needs explicit ordering. Otherwise, two individually correct features produce incorrect combined behavior.

## Independent random streams

My recommendation is to derive randomness from stable identity plus a property-specific key:

```text
identity + "source"
identity + "rotation"
identity + "scale"
identity + "tint"
```

Then changing tint need not change rotation.

The seed remains an intentional control for generating another variation, rather than an accidental dependency connecting every parameter.

---

# 10. Boundaries and collisions: several different problems

These should not be grouped under one generic “avoid overlap” feature.

## 10.1 Instance-to-instance collision

Forest documents collision filtering using virtual bounding spheres, with source and global radius controls and an adjustable sphere height. Higher candidate density may mostly create additional rejected placements rather than a proportionally larger accepted population. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode)

A basic sphere test in our implementation would be:

\[
\|c_i-c_j\| < r_i+r_j
\]

But that equation is only the narrow test. We must also decide:

**Which candidate wins?**

**Does scale change the radius?**

**Can one species overlap another?**

**Is clearance measured near the trunk, canopy, or whole asset?**

**Does processing order affect the result?**

A spatial index can reduce the number of pair tests, but it does not answer those semantic questions.

Current scope also matters: ForestPack 9.3.5 expanded collision checking to Path, Reference, and Particle Flow distribution modes. [Itoosoft Documentation](https://docs.itoosoft.com/changelog/2026/03/15/forestpack-9_3_5)

## 10.2 Cross-population exclusion

Using one scatter to exclude another expresses a directional relationship:

> Grass avoids these trees.

It does not necessarily mean:

> Trees and grass are solved together as one symmetric collision system.

Forest areas can derive exclusions from another Forest using sphere- or mesh-based representations. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/areas)

For Cyrus, a directed dependency is easier to reason about:

```text
Trees → exclusion field → Grass
```

A mutual dependency requires a separate solving policy or an explicit prohibition.

## 10.3 Point boundary versus size boundary

A pivot can be inside a region while the object extends outside it.

Forest’s Point mode tests the placement; Size mode considers its extent and removes the whole item when it violates the boundary. [ITOOSOFT](https://www.itoosoft.com/tutorials/modernbarn1)

For our implementation, a circle-like footprint may require a boundary distance at least as large as its radius.

That is not equivalent to checking only the center.

## 10.4 Edge mode

Forest Edge removes individual mesh elements according to a boundary test rather than slicing arbitrary triangles. Its element definition uses connected faces sharing a material ID. V-Ray provides native handling; Corona and Arnold use the Forest Edge map through the material’s opacity/cutout path. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-edge-map)

This explains why a grass patch can produce a clean edge without a geometric Boolean cut.

For Cyrus, comparable functionality would involve **both instance-side boundary information and renderer/material integration**.

It cannot be replicated by adding only a CPU “trim” flag.

---

# 11. Manual editing: procedural generation and persistent overrides are separate promises

Forest’s Items Editor distinguishes Generate from Custom Edit. It supports adding and manipulating items, changing sources, randomization operations, and storing transforms. The documentation warns about changes being lost when switching modes. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/item-editor)

Therefore:

**“The artist can move an instance” does not prove “that edit survives arbitrary procedural regeneration.”**

For Cyrus and CS Edit, I would explicitly model:

```text
Generated instance
    + transform override
    + source override
    + deletion marker
    + optional pinned state
```

Then define what happens under each operation.

If the artist moves one tree, increasing density could retain its override while adding new candidates.

Changing the seed might intentionally create different candidate identities.

Removing the receiving surface could leave the edit unbound.

Changing topology could invalidate its attachment.

These are not just implementation details. They determine whether artists trust the tool.

A particularly important choice is what to do with an **orphaned override**: an edit whose original generated item no longer exists.

Reasonable policies include preserving it as a manual item, keeping it inactive for possible recovery, or deleting it only after explicit confirmation.

The policy should be visible rather than accidental.

---

# 12. Materials and color variation form a separate subsystem

Forest’s Material rollout controls tint and color adjustments, but those operations depend on compatible Forest Color or Forest Material integration. Its optimizer can insert the required map structure. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/material)

Forest Color provides variation by whole item or mesh element, alternative maps, tinting, and blending controls. “Element” is not synonymous with every individual face. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-color)

## Whole-item variation versus internal variation

These produce different looks:

```text
One tint per tree:
    each tree has a coherent overall color variation

One tint per leaf element:
    variation occurs inside the tree

Combination:
    coherent tree-level variation plus smaller internal differences
```

For Cyrus, I would maintain distinct stable identifiers for the item and its source elements.

## Random color versus spatial color

A random tint can vary neighboring objects independently.

A spatial field can create a dry yellow patch crossing many objects.

Those should not be confused.

A useful proposed combination is:

```text
base material
    × broad spatial variation
    × per-instance variation
    × per-element variation
```

The exact blend operation should be configurable; multiplication is only one possibility.

## Material wrapping must preserve existing behavior

Adding edge handling or tint should not discard existing leaf opacity, normal maps, or other shader inputs.

The current release notes even include a fix preventing the material optimizer from duplicating Forest Color already present in a map chain. [Itoosoft Documentation](https://docs.itoosoft.com/changelog/2026/09/08/forestpack-9_4_3)

For Cyrus, material operations should be designed to be **repeatable without repeatedly wrapping the same material**.

---

# 13. Animation: vary evaluated source states, not only transforms

Forest’s animation modes include synchronized geometry, randomized samples, map-driven sample selection, and map-driven frame selection. Renderer integration can restrict which modes are available. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/animation)

The distinction is:

**Time offset:**

\[
t_i=t_{\text{scene}}+\Delta t_i
\]

**Explicit frame selection:**

\[
t_i=g(M(x_i))
\]

The first preserves ongoing animation with different phases.

The second uses a field to select a source state.

For Cyrus, source geometry may therefore need a cache key such as:

```text
source identity + evaluated time sample + relevant source revision
```

Ten thousand instances sharing ten evaluated source states are a different memory problem from ten thousand unique deformed states.

That is why “supports animated scattering” is not one checkbox. It requires agreements between instance generation, source evaluation, caching, and renderer export.

Forest’s ordinary scatter-animation controls should also not be confused with generating wind deformation from scratch; ForestIvy has its own growth and wind-related functionality. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/animation)

---

# 14. Camera controls, density reduction, and LOD are separate optimizations

Forest’s Camera rollout includes field-of-view limiting, distance-related controls, look-at behavior, LOD-related settings, and camera-distance falloff. Its documentation warns about animation consequences when visibility or population changes. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/camera)

## Culling

Culling asks:

> Should this item participate in this output?

For a proposed renderer integration, an item outside the camera image can still matter through shadows or reflections. Therefore, camera-only removal needs a defined approximation policy.

## Density reduction

Density reduction asks:

> Can we represent this region with fewer instances?

It changes the population, not merely the complexity of each object.

## LOD

ForestLOD selects between supplied models/materials based on criteria such as distance or screen size, with transition variation. It is a selection helper, not simply an automatic mesh-decimation button. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/forest-lod)

For Cyrus:

```text
LOD:
    keep the placement, change its representation

Density reduction:
    remove some placements

Culling:
    exclude placements from a particular output
```

These can be combined, but their effects must be measured separately.

A tree remaining in place with a cheaper mesh is not equivalent to that tree disappearing.

---

# 15. Viewport and rendering should consume the same scene description differently

Forest exposes mesh, proxy, and point-cloud display modes, viewport item limits, manual-update controls, render limits, and different rendering representations. Viewport limits can make the displayed population differ from the final render. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/display)

ForestPack 9 also documents retained point-cloud GPU data, updated when the Forest object changes rather than unnecessarily uploaded during ordinary navigation. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/whats-new/forest-pack-9)

That is a concrete, publicly described implementation lesson.

## A proposed Cyrus separation

```text
Authoritative accepted instances
        ├── viewport representation
        ├── picking representation
        ├── renderer instance stream
        └── export / baking representation
```

Viewport navigation should not inherently require regenerating procedural placement.

However, a camera-dependent effect or camera-dependent population can legitimately create such a dependency. The system should know why.

## A stable preview subset

For an independently implemented preview, I would choose instances using a stable key:

\[
H(\text{instanceID}) < q
\]

Increasing preview quality then adds instances from the same population instead of reshuffling it.

This is a proposed design, not a claim about Forest’s sampling method.

## Instancing does not make memory free

Forest’s rendering guidance explains native instancing and notes that repeatedly used meshes do not always require proxies to obtain instancing benefits. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/rendering/rendering-best-practice)

A useful budgeting model for Cyrus is:

\[
M \approx
M_{\text{source states}}
+
M_{\text{instance records}}
+
M_{\text{spatial indexes}}
+
M_{\text{display/render caches}}
\]

Reducing source geometry may not fix a problem caused by excessive candidate records or duplicated caches.

Likewise, a fast viewport does not prove that render export is efficient.

---

# 16. Effects: programmable relationships between existing data

Forest Effects exposes mathematical expressions, readable and writable attributes, and user-facing parameters. Parameter types include numeric values, scene objects, controllers, textures, and curves. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/effects-syntax)

Its attribute interface exposes information about instances, distribution, surfaces, and other context. This tells us what information is available to the public effect system; it does not reveal the internal memory layout. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/attributes)

For Cyrus, the useful architectural target is not necessarily to implement a scripting language immediately.

It is to make these relationships possible:

```text
distance to spline → scale
path tangent → orientation
surface slope → source eligibility
artist curve → rotation distribution
camera distance → representation
```

A later expression system can expose those existing services.

The important rule is that an effect should declare what it changes.

A tint-only effect should not invalidate surface intersections.

An effect that moves or enlarges instances may require boundary and collision reevaluation.

Without that declaration, a flexible effects system can quietly become a source of stale caches or unnecessary rebuilds.

---

# 17. Shared sets, linked areas, and presets are dependency-management features

## ForestSet

ForestSet is a reusable container for scene inputs. A particularly important distinction is that its Geometry use can choose one member, whereas surface and spline uses consume the relevant collection. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forestset-plugin)

For Cyrus, that suggests role-specific collection interfaces rather than one generic “container” whose behavior changes invisibly.

A source-variation collection, receiver collection, and compound arrangement should be distinguishable.

## Linked areas

Forest supports sharing area definitions while retaining local common settings such as falloff. ForestPack 8’s documentation describes this as a way for one source setup to drive multiple dependent scatters. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/whats-new/forest-pack-8)

In Cyrus, that could mean:

```text
Shared path boundary
    → grass exclusion with a narrow transition
    → shrub exclusion with a wide setback
    → flowers concentrated along the edge
```

The boundary is shared; the response is not.

This is a powerful way to preserve design intent when the architect moves a path.

## Presets

Forest’s library distinguishes source assets from complete Forest presets. Its General rollout also describes parameter presets that do not carry all external scene references. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-library/library-browser)

For Cyrus, I would separate:

**Asset:** geometry and materials.

**Recipe:** distribution, sources, spatial behavior, and variation.

**Scene setup:** recipe plus actual scene references.

This separation makes portability, missing-asset handling, and updates much easier to define.

---

# 18. Additional product scope: tools that are not the core scatter algorithm

Forest Lister provides scene-level management of multiple Forest-related objects. Forest Tools can convert procedural populations to standard Max instances for downstream workflows. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-lister)

ForestIvy is a separate plant-generation system combining authored growth guidance, procedural branches, leaf layers, and related controls. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-ivy/forest-ivy-overview)

The Shadows rollout also contains billboard-oriented and legacy renderer functionality. That should not automatically receive the same priority as modern mesh scattering. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/shadows)

For Cyrus, I would track these as separate deliverables:

**Core scattering parity, renderer/material integration, scene-management utilities, asset-library workflows, and plant generation.**

Otherwise, “replicate Forest Pack” becomes an undefined scope that mixes several products and generations of functionality.

---

# 19. How I would organize the implementation for Cyrus

This is a proposed architecture, not an audit of the current Cyrus codebase.

## Shared services rather than one implementation per button

| Service | Features that can reuse it |
|---|---|
| Source registry | Variation, dimensions, grouping, LOD, animation samples |
| Placement providers | Image, path, reference, particle, external procedural inputs |
| Surface queries | Projection, normals, slope, UVs, material IDs, attachment |
| Spatial fields | Paint, inclusion, exclusions, falloff, local overrides |
| Deterministic randomization | Source, transform, tint, preview selection |
| Constraint solver | Spacing, boundary clearance, cross-layer relationships |
| Override store | Manual transforms, source replacements, deletion, pinning |
| Output adapters | Viewport, picking, renderer, baking |
| Dependency tracking | Incremental updates, shared inputs, cancellation |

This does not imply rewriting the existing engine.

I would first map existing Cyrus systems onto these responsibilities, identify missing contracts, and improve the parts that fail measurable workflows.

## Snapshot → compute → publish

My conservative execution design would be:

```text
Snapshot:
    capture required host-scene data
    capture settings and revision identifiers

Compute:
    operate on owned, immutable input data
    reuse valid stage caches
    produce a new result without mutating the displayed one

Publish:
    confirm that the input revisions are still current
    replace the relevant output atomically
    discard stale results
```

The crucial point is that an old calculation must not overwrite a newer brush stroke or parameter change.

## Dependency-aware invalidation

A proposed target:

| Change | Normally affected work |
|---|---|
| Tint range | Shading attributes and relevant previews |
| Preview percentage | Viewport subset |
| Source scale | Transforms, bounds, constraints, output |
| Receiver topology | Surface bindings and dependent calculations |
| Painted region | Coverage and affected placement evaluation |
| Collision radius | Constraint solution and outputs |
| Camera movement | Camera-dependent fields, culling, LOD |
| Seed | Randomized properties and dependent constraints |

“Normally” matters: custom effects or linked inputs can add dependencies.

The goal is not to skip necessary work. It is to make necessary work explicit.

## Local updates require careful constraint handling

Suppose a new candidate enters a small painted region and wins a collision test against a neighboring candidate.

Removing that neighbor may allow another candidate farther away to survive.

Therefore, a greedy collision solution can propagate beyond the original edit boundary.

A correct incremental solver needs a proven update rule, controlled partitions, or a fallback to wider recomputation.

**A fast local update that disagrees with a full rebuild is a correctness bug, not an optimization.**

---

# 20. A worked example: one garden, many connected options

Here is an original test scene I would use to teach and validate these relationships.

We have a sloped garden, a curved footpath, several trees, mixed grass, flowers, and a rock border.

**Trees** use a broad inclusion region, weighted species, modest scale variation, and spacing constraints.

**Grass** uses the same receiving terrain but a different coverage definition. The path excludes it. A tree-derived field reduces grass near trunks without necessarily excluding the whole canopy.

**Flowers** use painted regions. Their source mix is clustered. Density declines near one boundary while height remains unchanged.

**Rocks** occupy a corridor around the path rather than evenly spaced positions along it.

**A foreground tree** receives a manual position override.

Now change the path.

The intended result is not “rebuild everything.” It is:

The shared path geometry updates the grass exclusion and rock corridor. Their affected populations update. The independently authored flower paint remains. The foreground tree keeps its explicit edit unless a declared rule makes it invalid.

Then change only the flower tint.

No tree, rock, path, surface binding, or collision arrangement should change unless an explicit dependency requires it.

This scene tests the **connections between features**, which is exactly what a button-by-button implementation misses.

---

# 21. How to establish real feature parity

I would not mark a feature complete merely because a similar control exists.

Each feature needs a behavior record:

| Field | What must be established |
|---|---|
| Purpose | The artistic problem it solves |
| Inputs | Geometry, maps, curves, lists, coordinates |
| Units | Scene units, percentages, degrees, normalized values |
| Combination rule | Replace, multiply, add, filter, or ordered operation |
| Identity behavior | What remains stable when inputs change |
| Dependencies | Which changes invalidate its result |
| Persistence | Save/load, Undo/Redo, cloning, missing references |
| Output differences | Viewport, final render, export |
| Limitations | Unsupported modes and renderer-specific behavior |
| Evidence | Documentation, controlled observation, or implementation hypothesis |

## The most informative tests are combinations

For example:

| Test | What it reveals |
|---|---|
| Change density with a fixed seed | Candidate stability |
| Disable a weighted source | Empty outcome versus weight redistribution |
| Reorder inclusion and exclusion areas | Area evaluation semantics |
| Enlarge objects beside a boundary | Transform/boundary ordering |
| Change scale with collisions enabled | Footprint and rejection dependencies |
| Paint on stacked surfaces | Projection and receiver identity |
| Edit one instance, then regenerate | Persistence of artistic overrides |
| Reduce viewport quality | Preview/final separation |
| Apply a material operation twice | Whether wrapping is safely repeatable |
| Save, reopen, and Undo | Persistence and transaction correctness |

For performance, measure more than instance count:

**Input handling, coverage evaluation, candidate generation, surface queries, rejection, accepted-instance construction, GPU updates, picking, and render export.**

Forest itself exposes statistics and warnings, and its documentation explicitly distinguishes high candidate density from the final accepted population. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/general)

The benchmark should also distinguish a cold build from a warm update.

---

# 22. What the documentation tells us—and what it does not

We have public evidence for several implementation-relevant mechanisms: projected bitmap exclusions, sphere-based collision filtering, prepared surface information, element-based edge handling, and retained point-cloud GPU updates. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/forest-plugin/areas)

We do **not** have sufficient evidence to state its exact current:

- Paint storage and incremental evaluator.
- Collision acceleration structure and winner-selection algorithm.
- Cluster-generation algorithm.
- Thread scheduler and complete cache-invalidation graph.
- Persistent internal identity scheme.
- Complete ordering of every effect, filter, and renderer operation.

Those can be investigated through controlled external tests, but should not be invented from screenshots.

The manual itself also needs version-aware reading. For example, its paint shortcut descriptions conflict between pages, and older XY-only guidance appears alongside newer UV-area support. Exact shortcut assignments and mixed-mode edge cases should be checked in the target build rather than encoded from one paragraph. [Itoosoft Documentation](https://docs.itoosoft.com/forestpack/whats-new/forest-pack-9-3)

## My conclusion for Cyrus Scatter

**The main challenge is not implementing hundreds of independent options. It is building a smaller set of reliable systems whose combinations produce those options.**

The highest-value foundations are:

**Stable placement identity; reusable surface and spatial-field queries; explicit ordering and override rules; correct incremental updates; and separate viewport/render representations.**

With those foundations, features such as density falloff, species patches, local scale, path influence, painting, linked areas, and manual refinement can share infrastructure.

Without them, every new checkbox adds another special case—and eventually changing a flower color makes the entire garden recalculate.

The target I would use is:

> **Reproduce the artist-visible behavior, define the difficult interactions explicitly, and prove that edits remain predictable as the scene grows.**

That is the basis for genuine functional parity—and for making Cyrus more coherent than a literal copy of the interface.