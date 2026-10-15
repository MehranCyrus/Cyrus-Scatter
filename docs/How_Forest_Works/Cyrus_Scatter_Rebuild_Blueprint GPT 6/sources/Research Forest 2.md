# ForestPack Deep Technical Study

Research for Cyrus Scatter · October 2026

Our objective is to understand ForestPack at three levels: what each feature does, how its controls interact, and how we could independently engineer equivalent functionality inside Cyrus Scatter.

I've located ITOOSOFT's official [ForestPack technical reference](https://docs.itoosoft.com/forestpack/forest-plugin). It covers considerably more than the introductory tutorial, including distribution algorithms, geometric exclusions, painting, surface placement, custom editing, procedural effects, renderer integration, and optimization.

One important distinction: ForestPack is proprietary software. Its documentation explains some algorithms explicitly, but doesn't reveal its entire C++ implementation. I'll distinguish:

- Documented behavior: What ITOOSOFT explicitly confirms.
- Engineering interpretation: What the documented behavior tells us about the underlying computation.
- Proposed implementation: How we could reproduce the functionality in Cyrus Scatter using our own algorithms and code.

## 1. Understanding ForestPack as a complete system

ForestPack is best understood as a collection of connected subsystems, not a single scatter algorithm.

Conceptual ForestPack system map

Geometry / Source Library

Trees, grass, rocks, source probabilities, materials

Distribution

Image, Path, Reference, Particles

Spatial Constraints

Surfaces, Areas, Masks, Falloffs

Population Evaluation

Species selection, clusters, collisions, transforms, effects

Viewport

Points, billboards, simplified meshes, caching

Rendering

Renderer-native instances, materials, LOD

This is an architectural interpretation of the public feature set, not ITOOSOFT's proprietary internal dependency graph.

ITOOSOFT's reference identifies four principal distribution modes—Image, Path, Reference, and Particle Flow—plus five area types: Spline, Object, Forest, Paint, and Surface. Each mode has different semantics, and several share the same geometry and transformation controls.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation

+1



This distinction matters enormously for development.

For example, a density mask determines whether an instance should be generated, a spline boundary determines where it is permitted, a terrain determines how it is placed in 3D, and a cluster algorithm determines which plant species occupies a location.

Treating those as independent, composable operations is the foundation of a scalable implementation.

### Important version update

The tutorial is an introduction, not a complete reference for the current product. As of October 13, 2026, the latest ForestPack release I found in the official changelog is 9.4.3, released September 8, 2026.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation

+1



Several developments matter for our study:

| Version | Important feature                                                  | Architectural implication                                            |
| ------- | ------------------------------------------------------------------ | -------------------------------------------------------------------- |
| 9.3.0   | Grayscale density maps, per-area random scaling, improved painting | More spatial controls can be shared across one population            |
| 9.3.5   | Collisions across Image, Path, Reference and Particle modes        | Collision evaluation can be shared between placement strategies      |
| 9.4.1   | RailClone segment integration, tagged geometry matching            | Scattering can consume externally generated placement points         |
| 9.4.1   | Portable Forest files containing geometry                          | Presets become portable scene assets, not just parameter collections |

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation

+2

That second feature is particularly revealing. A collision system originally associated with image-based scatter was extended to other distribution modes. It supports the engineering case for a common collision stage that operates on generated candidate instances, regardless of where those candidates came from.

The documentation also mixes references to older and newer ForestPack versions. We should not assume every historical setting has unchanged semantics in 9.4.x.

## 2. Distribution engines — how ForestPack decides where objects appear

This is the first major system we need to reproduce.

### 2.1 Image Mode: the central scatter generator

[Official Image Mode documentation](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode)

Image Mode is more specific than simply choosing random coordinates across a polygon.

ITOOSOFT describes a tiled distribution image in which pixels represent potential placement positions. The image is scaled to scene dimensions, and its placement pattern is repeated across the distribution area.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



The essential controls are:

| Control            | Exact purpose                                                        | Dependencies                 |
| ------------------ | -------------------------------------------------------------------- | ---------------------------- |
| Bitmap / Map       | Defines the spatial placement pattern                                | Distribution coordinates     |
| Use as Density Map | Interprets grayscale as continuously varying density                 | Image values                 |
| X/Y Units          | Sets the world-space dimensions of one map tile                      | Controls candidate frequency |
| X/Y Pixels         | Controls procedural map resolution independently of world dimensions | Procedural maps              |
| Map Channel        | Uses surface UV information for map alignment                        | Surface + UVs                |
| Fit to Scene       | Aligns a map using selected scene positions                          | Scene coordinates            |
| Lock Aspect Ratio  | Preserves map proportions                                            | X/Y Units                    |
| Offset             | Shifts the pattern                                                   | Map coordinates              |
| Rotation           | Rotates the pattern                                                  | Map coordinates              |
| Threshold          | Determines how image values affect acceptance                        | Bitmap/map values            |
| Max Density        | Caps potential placement positions                                   | Candidate generation         |
| Diversity          | Chooses source models                                                | Geometry List                |
| Collisions         | Rejects overlapping objects                                          | Source dimensions, radius    |

#### How a distribution image actually works

Consider a 100 × 100 pixel image.

Binary distribution map

On/off placement candidates

Grayscale density map

Continuous density variation

If that image represents 10 × 10 meters of terrain, its 10,000 pixels describe 10,000 potential positions per tile, before accepting or rejecting candidates.

That is a conceptual calculation based on the documented pixel-placement model, not a claim that all those positions will become plants.

In binary mode, the image establishes which potential positions are active.

In grayscale density mode, introduced in ForestPack 9.3, brightness modulates how many positions are accepted. Black represents minimum density and white maximum density.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



An independent implementation could evaluate:

\\[ P(\text{accept at }x,y)=\operatorname{clamp}(M(x,y),0,1) \\]

where \\(M\\) is the sampled density field.

This equation is a proposed implementation. It does not assert that ForestPack uses exactly that probability function internally.

#### Why X/Y Units are so important

Suppose a pattern contains 2,000 active candidates within a tile.

- At 10 × 10 meters, its nominal density is 20 candidates/m².
- At 5 × 5 meters, the same pattern produces 80 candidates/m².

Reducing both tile dimensions by half produces four times as many potential points per square meter.

This explains why increasing density through map scaling can become expensive very quickly.

ITOOSOFT documents another important inefficiency: using a sparse distribution image at an extremely small tile scale wastes work evaluating empty pixels. For dense grass, the recommended approach is to begin with a suitably dense map rather than compensating for a sparse one by excessive tiling.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



#### How I would engineer it

I would start with a generic candidate generator rather than making bitmaps the entire scattering architecture.

```

struct ScatterCandidate
{
    uint64_t stableId;
    Vec3 position;
    Vec3 normal;
    Vec2 uv;
    uint32_t receiverId;
    uint32_t triangleId;
    uint32_t regionId;
    float densityWeight;
};

struct DistributionContext
{
    uint64_t globalSeed;
    Bounds3 worldBounds;
    SurfaceSampler* surfaces;
    FieldEvaluator* fields;
};

class IDistributionGenerator
{
public:
    virtual void Generate(
        const DistributionContext& context,
        CandidateBuffer& output) const = 0;
};

```

Then implement individual generators such as `ImageDistribution`, `PathDistribution`, `ReferenceDistribution`, and `ParticleDistribution`.

The crucial point is that each generator produces the same candidate structure, making it possible to apply common source selection, filtering, collisions, and renderer output afterward.

### 2.2 Diversity: choosing which model occupies each position

ForestPack's Image Mode provides three important Diversity strategies.

Random: Select models according to their Geometry List probabilities.

Match Color ID: Compare distribution-map colors with the Color IDs assigned to geometry sources. Ordinary source probabilities are bypassed for this matching operation, although documented handling of identical Color IDs allows grouped source variations in supported versions.

Clusters: Spatially group similar models using Size, Roughness, Blurry Edge, and Noise.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation

+1



For weighted random selection, a straightforward implementation is:

\\[ P_i=\frac{w_i}{\sum\_{j=1}^{n}w_j} \\]

For example, consider three plant variations:

| Plant      | Weight | Selection probability |
| ---------- | ------ | --------------------- |
| Lavender A | 50     | 50%                   |
| Lavender B | 30     | 30%                   |
| Lavender C | 20     | 20%                   |

But there are two separate questions:

1. Does a plant exist at this position?
2. If a plant exists, which model should be selected?

The first is evaluated by distribution rules, density, areas, and related constraints. The second uses a source-selection strategy.

Keeping them separate prevents a common architecture mistake: changing source probabilities should not necessarily generate an entirely different set of placement positions.

### 2.3 Cluster controls explained

Clusters are particularly valuable for realistic landscapes.

| Parameter   | Visual behavior                           | Possible computational approach              |
| ----------- | ----------------------------------------- | -------------------------------------------- |
| Size        | Controls spatial extent of groups         | Cluster field frequency                      |
| Roughness   | Controls irregularity of cluster contours | Warp coordinates using noise                 |
| Blurry Edge | Mixes species at transitions              | Smooth interpolation between species weights |
| Noise       | Introduces out-of-cluster variation       | Blend clustered and random selections        |

The final column contains implementation suggestions, not confirmed ForestPack algorithms.

A good independent approach is to construct spatial weights for each species:

\\[ W_i(x,y)\geq0 \\]

Then normalize those weights:

\\[ P_i(x,y)=\frac{W_i(x,y)}{\sum_j W_j(x,y)} \\]

This produces spatially varying species probabilities.

For example, inside a lavender-dominant patch, lavender's weight might be high and ornamental grass's weight low. At the edge, the two weights could gradually converge.

That permits natural mixing without manually defining a separate scatter layer for every species.

A practical implementation could use low-frequency noise, Voronoi-like region assignment, and boundary smoothing. We would need controlled experiments against ForestPack to reproduce its particular visual behavior closely.

### 2.4 Collision checking: the hidden performance multiplier

ForestPack explicitly documents using virtual bounding spheres to identify colliding instances. It combines a source-specific Collision Radius with a global radius control and also exposes collision-height adjustment.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



For our engine, candidate rejection could use:

\\[ \\|c_i-c_j\\|^2 < (r_i+r_j)^2 \\]

where \\(c_i,c_j\\) are sphere centers and \\(r_i,r_j\\) their effective radii.

When this inequality is true, the two instances overlap under the sphere approximation.

A naïve algorithm comparing every object against every other object is quadratic:

\\[ O(N^2) \\]

That becomes unsuitable for hundreds of thousands of plants.

I would instead use a spatial hash or uniform grid. For each accepted candidate, we examine only instances occupying nearby grid cells. This can approach linear complexity for well-behaved distributions, although performance depends on radius variation and local density.

Why candidate rejection matters

## 100k

Generated candidates

## 60k

Collision rejects

## 40k

Final instances

Illustrative example, not measured ForestPack performance.

An artist may increase density and see virtually no additional plants because available space is already saturated. The engine, however, still has to process the rejected candidates.

ForestPack's documentation specifically warns about this and reports excessive collision rejection in its statistics.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



For Cyrus Scatter, we should also investigate minimum-distance sampling, rather than depending exclusively on generating excessive candidates and rejecting collisions afterward.

### 2.5 Path Mode: distribution along splines

[Official Path Mode reference](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode)

Path Mode behaves differently from Image Mode.

It supports regular spacing, placement at spline vertices, geometry sequencing, positional randomness, perpendicular offsets, and orientation following the spline.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



To implement regular spacing correctly, we need to understand arc length.

A curve parameter \\(t\\) is not necessarily proportional to physical distance. Evaluating a spline at equal parameter increments may produce uneven spacing.

For positions separated by a target distance \\(\Delta s\\), we want:

\\[ s_k=k\Delta s \\]

where \\(s_k\\) is accumulated distance along the curve.

A practical solution is to build a cumulative arc-length table, then invert it to evaluate positions along the spline.

The individual controls would work as follows:

| Control             | Implementation behavior                                           |
| ------------------- | ----------------------------------------------------------------- |
| Spacing             | Samples curve by physical distance                                |
| In Vertex Positions | Uses spline knots instead of distance sampling                    |
| Random Position     | Adds controlled variation to positions along the path             |
| Spline Offset       | Moves samples laterally along the curve's perpendicular direction |
| Follow Path         | Calculates orientation from tangent direction                     |
| Sequence            | Cycles through source IDs in Geometry List order                  |
| Random              | Chooses source IDs randomly                                       |

A subtle issue: along a curved path, the offset curve does not have the same arc length as the original curve. If we add spacing and offset controls, we need to define which curve supplies the spacing measurement.

The documentation confirms the user-facing controls, but does not specify all of these numerical details.

### 2.6 Reference Mode: replacing authored markers

[Official Reference Mode documentation](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode)

Reference Mode is useful when positions are already defined by another program, such as AutoCAD or an architectural layout.

ForestPack supports one item per reference pivot, placement using polygon faces, multiple items per face, source matching by name or regular expression, and inheritance of orientation and scale.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



Its placement source isn't a random field. It is an existing collection of reference objects or geometric elements.

The important options are:

- Pivot: Uses reference-object pivots as instance locations.
- Mesh Faces: Derives positions from individual polygon faces.
- Items Per Face: Generates multiple items for each selected face.
- Randomize Position: Replaces regular within-face placement with randomized positions.
- Align / Scale: Inherit compatible source transforms.
- Match Geometry by Name / Regex: Determine the scatter source using reference names.

For random sampling inside a triangle, a mathematically correct approach uses barycentric coordinates, adjusted to avoid concentrating points near one vertex. Merely choosing two uniformly random barycentric coordinates without correcting their distribution would produce incorrect sampling.

Because placement is tied to reference geometry, a good implementation must also track source changes and preserve deterministic IDs.

### 2.7 Particle Flow and RailClone input

Two additional methods broaden the system considerably.

Particle Flow Mode obtains positions, orientations, and scale from PFlow particles and allows specific particle events to be included. Animated particle sources retain a live connection.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



RailClone integration, added in ForestPack 9.4.1, creates ForestPack items from exported RailClone segments. It transfers segment position, rotation, scale, and wireframe color, supports geometry matching through tags, and leaves segment deformation behind.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



This gives us a very useful design direction: distribution should be an interchangeable source of candidate transforms, not a monolithic feature tied to density maps.

## 3. Areas, surfaces, painting, and falloffs

This is probably the most important subsystem for Cyrus Scatter because it determines whether artists can control planting precisely without losing procedural flexibility.

### 3.1 Why ForestPack uses an ordered Area List

ForestPack supports five area types and processes the list from bottom to top. Each entry can contribute a region, subtract an existing region, or provide other spatial constraints, depending on its type.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



Imagine these three operations:

Example: ordered landscape operations

1

Include the complete garden

2

Exclude the winding pedestrian path

3

Include a special planting bed above the exclusion

The third operation can introduce a new population in an area that the earlier exclusion cleared. Therefore, a universal binary mask isn't sufficient to reproduce every behavior.

A better model is a sequence of operations on population contributions:

```
Garden Include
    -> generate candidates inside Garden

Path Exclude
    -> remove eligible candidates inside Path

SpecialBed Include
    -> generate candidates inside SpecialBed
```

This also explains ITOOSOFT's warning against overlapping Include areas: they can independently contribute instances that occupy similar locations.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



For Cyrus Scatter, I would represent each area as a typed operation with its own parameters, and evaluate the ordered stack instead of flattening all areas into one mask.

### 3.2 The five area types in detail

| Area type | Purpose                                                   | Important parameters                   | Engineering representation      |
| --------- | --------------------------------------------------------- | -------------------------------------- | ------------------------------- |
| Spline    | Closed regions or open strips                             | Include/Exclude, Thickness, Force Open | 2D polygon or distance to curve |
| Object    | Remove instances intersecting buildings or other geometry | Top Limit, Resolution, Scale           | Projected exclusion mask        |
| Forest    | Use instances from another scatter as exclusions          | Sphere/Mesh, Resolution, Scale         | Generated occupancy field       |
| Paint     | Artist-painted include/exclude regions                    | Brush size, pressure, erase, falloff   | Editable region field           |
| Surface   | Receiving geometry and optionally a distribution region   | XY/UV, direction, altitude, slope      | Surface acceleration data       |

The listed implementation representations are my suggestions. The official documentation describes object and Forest exclusions using raster masks and documents the surface-placement modes.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation

+1



#### Spline Areas

Closed splines define a region. Open splines use `Thickness` to create a distribution band on either side of the curve.

A closed spline can also be forced to behave like an open path. This is useful for placing grass or rocks around the outline of an architectural element.

Two independent calculations are needed:

1. Inside test: Is the candidate inside the boundary?
2. Distance test: How far is the candidate from the boundary?

The inside test controls eligibility. The distance test drives falloffs.

For a point \\(p\\) and curve \\(C\\), boundary distance can be defined as:

\\[ d(p,C)=\min\_{q\in C}\\|p-q\\| \\]

Efficiently evaluating this against many spline segments requires spatial indexing, particularly if the scene contains thousands of points or complex splines.

#### Object Areas

This feature is especially interesting because ITOOSOFT actually documents an optimization technique.

ForestPack projects object geometry along world Z and creates a black-and-white bitmap for the exclusion. Its default exclusion-map resolution is 512 pixels. `Top Limit` restricts which geometry participates, and `Scale` expands or contracts the exclusion influence.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



Instead of repeatedly checking whether every blade of grass intersects a complex building, the system can sample a precomputed mask.

That makes object exclusions much cheaper during population generation, but introduces an accuracy trade-off.

A high-resolution mask captures thin outlines more accurately but costs more memory and processing. A low-resolution mask is faster but can produce visibly inaccurate boundaries.

For Cyrus Scatter, I would use adaptive world-space resolution or tiled masks rather than assuming one fixed bitmap resolution is appropriate for every scene.

#### Forest Areas

A Forest Area can exclude instances using another ForestPack object.

The documentation provides two shapes:

- `Sphere` uses fast virtual bounding spheres.
- `Mesh` uses more accurate geometry evaluation at higher computational cost.

The resulting exclusion can also have a falloff, meaning one vegetation population can influence another.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



For example, large trees can create exclusion regions around their trunks, which then control the density of ground cover.

This is more powerful than a conventional collision option because it introduces relationships between scatter objects.

In Cyrus Scatter, I would model that explicitly:

```
Tree Scatter
    └── generated positions / footprints
             ↓
        Grass Exclusion Field
             ↓
        Grass Scatter
```

If trees move, dependent grass regions become dirty.

This dependency also means we must detect cycles. Grass should not depend on trees that depend on the same grass population in a way that produces endless regeneration.

### 3.3 Paint Areas: what the brush really needs to do

[Official Paint Area documentation](https://docs.itoosoft.com/forestpack/forest-plugin/areas)

ForestPack's painting workflow offers add, erase, brush-size adjustment, tablet pressure sensitivity, falloff preview, and Paint-to-Spline conversion in both directions. In the documented workflow, a receiving Surface in XY mode supplies placement while the unrestricted Surface inclusion is disabled, so the painted region defines where generation occurs.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



For our implementation, there are three layers of work:

Input layer

The 3ds Max viewport reports cursor hits, surface coordinates, pressure, brush radius, and stroke events.

Region layer

Each stroke edits the underlying spatial region. It should not directly require creating thousands of scene nodes.

Population layer

The scatter engine recomputes only the candidates affected by the changed region.

A possible internal data structure:

```

struct BrushSample
{
    Vec3 worldPosition;
    float radius;
    float strength;
    float pressure;
};

struct PaintStroke
{
    uint64_t strokeId;
    uint32_t receiverId;
    PaintOperation operation; // Add or Erase
    std::vector<BrushSample> samples;
    Bounds3 affectedBounds;
};

```

There are two serious representation strategies.

| Approach                  | Strength                                                        | Weakness                                                     |
| ------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------ |
| Vector strokes / contours | Editable curves, scalable resolution, natural spline conversion | Cost can increase with stroke history and contour complexity |
| Tiled raster masks        | Fast field evaluation, local updates, compact sampling          | Resolution limits and additional work for spline conversion  |

My preferred direction would be a hybrid system: editable stroke records for Undo/Redo, compact per-tile coverage data for evaluation, and optional contour extraction when the artist explicitly converts a painted region to a spline.

That is a proposed Cyrus Scatter architecture. ForestPack's public documentation does not reveal whether it uses that same storage model.

### 3.4 Surface projection is a separate subsystem

This is a distinction we should preserve very carefully.

A scatter position might be generated in 2D, but the receiving surface determines its final 3D position and orientation.

ForestPack documents two principal surface modes:

XY Mode: Generate positions in the Forest object's local XY plane, then project onto the surface along its local Z direction.

UV Mode: Use the surface's texture-coordinate space, enabling distributions over shapes such as curved objects and spheres when their UV mapping is appropriate.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



XY projection

Positions projected onto terrain

UV distribution

Pattern follows mapped surface coordinates

XY projection is simple and useful for landscapes, but it becomes ambiguous when several surfaces overlap vertically: bridges, balconies, stacked floors, and overhangs are typical examples.

UV distribution handles different shapes, but UV seams, distortion, mirrored islands, and overlapping UVs create new problems.

In our engine, a surface sample should retain at least the receiver identity, face identity, barycentric position, UV coordinates, world-space normal, and position. This gives us the information needed to rebuild transforms when receiving geometry changes.

### 3.5 Altitude, slope, and direction controls

The Surface rollout also exposes:

| Parameter         | Effect                                                       |
| ----------------- | ------------------------------------------------------------ |
| Direction         | Controls how instance orientation relates to surface normals |
| Scale to Fit      | Adjusts footprint scaling on sloped surfaces in XY mode      |
| Altitude Range    | Restricts placement by height                                |
| Altitude Falloff  | Varies density and scale across a height interval            |
| Slope Angle Range | Restricts placement according to terrain inclination         |
| UV Transform      | Adjusts distribution mapping in UV mode                      |

ForestPack's `Direction` scale is documented as −100 for Down, 0 for normal-aligned, and +100 for Up. `Scale to Fit` requires normal alignment and is unavailable in UV mode.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



For terrain slope, a basic implementation can derive the angle from the surface normal \\(n\\) and the world-up vector \\(u\\):

\\[ \theta=\cos^{-1}(\operatorname{clamp}(n\cdot u,-1,1)) \\]

An upward-facing horizontal surface gives approximately zero degrees, while a vertical surface gives approximately 90 degrees.

But the implementation must specify whether we use world up, the Forest object's local up, or a user-defined axis. That is important for rotated environments.

### 3.6 Falloffs should be treated as general-purpose spatial fields

ForestPack has separate falloff curves for density and scale, with distinct inclusion and exclusion ranges. It also supports inverted curves and Affect Height Only, which changes vertical scale while leaving the footprint untouched.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



I would not implement falloffs as logic duplicated inside every Area type.

Instead, build a general scalar-field evaluation system:

\\[ F(p)=\operatorname{Curve}\left( \operatorname{clamp}\left(\frac{d(p)}{R},0,1\right) \right) \\]

Here:

- \\(d(p)\\) is distance to the relevant boundary.
- \\(R\\) is falloff range.
- `Curve` is a user-edited response curve.

This value could drive density, scale, source weights, color variation, or custom effects.

For example:

\\[ D\_{\text{effective}}(p)=D_0\cdot F_D(p) \\]

\\[ S_z(p)=S\_{z,0}\cdot F_S(p) \\]

with separate density and scale curves \\(F_D\\) and \\(F_S\\).

That architecture makes it much easier to introduce new artist controls without inventing another distribution algorithm each time.

## 4. Source geometry, transformation, and individual editing

### 4.1 The Geometry List is more than a list of meshes

[Official Geometry rollout reference](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry)

ForestPack's source system supports geometry objects, renderer-specific proxies and procedurals, billboards, groups, hierarchies, and even certain non-geometric objects supported by compatible renderers.

Each Geometry List entry has properties that influence not only appearance, but also placement and selection.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



| Source property          | Role in the system                                              |
| ------------------------ | --------------------------------------------------------------- |
| Name                     | User-facing identity and certain reference-matching workflows   |
| Custom Object / Template | Determines which object is instanced                            |
| Probability              | Relative likelihood of source selection                         |
| Disabled                 | Preserves a selection slot while producing no rendered geometry |
| Color ID                 | Assigns a source to colors in source-selection maps             |
| Collision Radius         | Influences spacing and geometric exclusion calculations         |
| Scale / Dimensions       | Determines source size before additional transformations        |
| Z Offset                 | Moves the source relative to the placement position             |
| Material                 | Determines the assigned renderer material                       |
| Include Children         | Includes hierarchical components                                |
| Keep Group Hierarchy     | Treats grouped components together for transforms and culling   |

One small feature has an important consequence: Disabled source entries create intentional gaps.

For example, suppose a distribution generates 10,000 candidate positions and a disabled entry receives 20% of the source-selection weight. Under weighted random selection, approximately 2,000 candidates may intentionally produce no geometry.

That is not equivalent to rejecting 20% of candidates before selecting source models, especially if the remaining models have different collision radii or cluster behavior.

I would preserve an explicit `None` or `Disabled` source type in Cyrus Scatter rather than removing disabled sources from the probability calculation.

### 4.2 Group instances introduce a second level of structure

ForestPack can scatter grouped geometry, such as several flowers arranged into one designed clump.

An important option is `Keep Group Hierarchy`.

When enabled, grouped elements are transformed and culled together. When disabled, individual group components can receive separate transforms and be processed independently for relevant operations.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



For our system, the representation could be:

```
Scatter Source: Flower Clump
    Local child A: Purple flower
    Local child B: Grass
    Local child C: Small flower
```

There are two ways to instance this:

Atomic group: One parent transform multiplies each child's local transform.

Expanded group: Children become independently evaluated items.

This affects collision testing, surface alignment, bounds, LOD, selection, memory use, and render-instance counts.

I would start with atomic groups and add child-level evaluation as a separate, deliberately designed capability.

### 4.3 Random transforms use several overlapping control systems

[Official Transform reference](https://docs.itoosoft.com/forestpack/forest-plugin/transform)

ForestPack's Transform rollout includes random translation, rotation, and scale; probability curves; maps; probability maps; and mirroring.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



A critical distinction is that these are different kinds of randomness.

| Control            | What it changes                                       |
| ------------------ | ----------------------------------------------------- |
| Source probability | Which model is chosen                                 |
| Rotation range     | Allowed angles                                        |
| Scale range        | Allowed sizes                                         |
| Probability curve  | How frequently particular transform values are chosen |
| Transform map      | Which transform value is assigned spatially           |
| Probability map    | How strongly randomization affects an item            |
| Random seed        | Reproducible random sequence                          |

Consider random Z rotation from 0° to 360°.

With a uniform distribution, every angle is equally likely.

But an architectural object such as a bench may need only four principal orientations: 0°, 90°, 180°, and 270°.

A probability curve can concentrate samples around those angles. The documented system supports even discrete-orientation patterns using transform probability curves.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



A robust random-value sampler needs to sample from the curve's cumulative distribution, rather than simply evaluating a curve at a uniformly distributed value. Those produce different statistical distributions.

For Cyrus Scatter, I would build a reusable probability-curve sampler and cache its cumulative distribution table.

### 4.4 Transformation maps need a generic field interface

ForestPack uses texture maps to control transformations.

A grayscale map can map black and white to the minimum and maximum values. For scale, an RGB map can control three axes independently: red for X, green for Y, blue for Z.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



A reusable engineering interface might be:

```
float EvaluateScalarField(
    const Vec3& worldPosition,
    const Vec2& uv,
    const FieldContext& context);
```

It could sample a bitmap, procedural texture, vertex attribute, slope field, distance field, or painted mask.

Then scale evaluation becomes a composition of operations:

\\[ S\_{\text{final}} = S\_{\text{source}} \odot S\_{\text{global}} \odot S\_{\text{area}} \odot S\_{\text{random}} \odot S\_{\text{falloff}} \\]

Here, \\(\odot\\) denotes component-wise multiplication. This is a proposed model; ForestPack doesn't publish an authoritative internal transform-evaluation order.

There is an important behavioral detail from the documentation: ForestPack applies random translation after initial distribution placement, so sufficiently large random offsets can move an object outside its original area boundary.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



For Cyrus Scatter, I would explicitly offer two choices:

- Check before randomization: Preserve the sampled region, allowing objects to extend outside it.
- Check after randomization: Enforce the final transformed placement against the region.

A third, geometry-aware boundary mode could check the transformed footprint instead of just the pivot.

### 4.5 The three boundary-checking modes

ForestPack distinguishes:

| Mode  | Behavior                                                 | Main trade-off                                             |
| ----- | -------------------------------------------------------- | ---------------------------------------------------------- |
| Point | Checks the instance pivot                                | Fast, but geometry may cross the boundary                  |
| Size  | Uses object size and collision radius                    | Avoids some overlaps, but can create an uneven edge        |
| Edge  | Tests sub-elements for boundary inclusion at render time | Cleaner visual transitions, more specialized and expensive |

The Edge feature isn't necessarily polygon clipping. ITOOSOFT describes evaluating geometry elements, with support that depends on the renderer and, in cases such as Arnold or Corona, use of the Forest Edge opacity/cutout map.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



This is an example of a feature whose logic is shared across the scattering engine and renderer material system. We cannot reproduce it fully by modifying candidate positions alone.

### 4.6 Custom Edit is a different editing model

[Official Item Editor reference](https://docs.itoosoft.com/forestpack/forest-plugin/item-editor)

ForestPack has separate Generate and Custom Edit modes.

Custom Edit supports manual placement, transform editing, model replacement, randomizing selected source types, reseeding transforms, selecting by source type, storing random transforms, and attaching or detaching Forest objects.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



`Store Transform` is especially interesting. It can preserve random transforms as explicit item properties, useful when attaching populations from other Forest objects.

For our own implementation, I would improve the interaction model further by storing manual edits as sparse overrides, rather than requiring a complete mode switch.

A possible structure:

```

struct InstanceOverride
{
    uint64_t stableInstanceId;

    bool isDeleted = false;
    bool hasTransform = false;
    bool hasSourceOverride = false;

    Mat4 editedTransform;
    uint32_t sourceId = 0;
};

struct ManualItem
{
    uint64_t uniqueId;
    uint32_t sourceId;
    Mat4 transform;
};

```

These two types solve different problems:

- An override modifies an instance generated procedurally.
- A manual item exists independently of candidate generation.

The difficult part is preserving the identity of a procedural instance when its surroundings change. Identifying an instance only by its array index would be fragile, because insertion or deletion may reorder the array.

Instead, I would use deterministic IDs derived from the generator, area, spatial tile, and candidate identity.

For example, changing the color of one tree should not invalidate the identities of all other trees.

This system would require clear conflict rules when a manually edited instance is later rejected by new density or exclusion settings.

## 5. Rendering, visibility, materials, and animation

A scattering system is incomplete if it generates objects correctly but cannot display, edit, and render them efficiently.

ForestPack has several distinct mechanisms here.

### 5.1 Viewport representation versus real instance population

[Official Display rollout reference](https://docs.itoosoft.com/forestpack/forest-plugin/display)

ForestPack provides mesh, adaptive, proxy, and Point Cloud viewport representations.

Its Point Cloud preview has a documented default budget of approximately 250,000 points per Forest object, independent of the actual instance count. The GPU data is generally reused until the Forest object changes.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



This means three quantities must be kept separate:

| Quantity                | What it represents                                       |
| ----------------------- | -------------------------------------------------------- |
| Candidate count         | Positions examined by the distribution engine            |
| Accepted instance count | Objects that survive the generation rules                |
| Viewport display count  | Objects or points selected for interactive visualization |

Suppose a system produces 2 million accepted grass instances.

Displaying 2 million full grass meshes is unnecessary for ordinary viewport navigation. A point-cloud representation with a controlled point budget can communicate vegetation coverage at a fraction of the draw cost.

A proposed implementation would maintain:

```
Accepted Instance Buffer
     ├── Render Instance Stream
     ├── Viewport Point Buffer
     ├── Viewport Bounds / Proxy Buffer
     └── Selection Acceleration Structure
```

The important part is that the viewport buffer can change independently of the accepted instance buffer.

Camera movement should normally update visibility and drawing, not rerun the distribution algorithm.

### 5.2 Renderer-native instancing is essential

ForestPack's Geometry documentation lists support for meshes and compatible renderer-specific object types, including V-Ray proxies, Corona sources, Arnold procedurals, and others.

Its Display rollout distinguishes `Automatic` rendering, which delegates to renderer capabilities where possible, from `Meshes`, which builds combined mesh geometry.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation

+1



A renderer should ideally receive something conceptually similar to:

```
struct RenderInstance
{
    SourceHandle source;
    Matrix4 transform;
    MaterialHandle material;
    uint64_t instanceId;
    uint32_t animationSample;
    Vec3 tint;
};
```

A million instances should not imply a million duplicated mesh allocations or a million independently managed 3ds Max scene nodes.

For Cyrus Scatter, renderer integration should therefore be a separate backend, capable of translating common instance data into the appropriate renderer-specific representation.

The exact integration technique will depend on the 3ds Max and renderer SDK versions. A generic `GetRenderMesh` approach is not enough to guarantee memory-efficient native instancing.

### 5.3 Camera culling, density falloff, and LOD are three different things

[Official Camera rollout reference](https://docs.itoosoft.com/forestpack/forest-plugin/camera)

ForestPack offers field-of-view culling, camera expansion, far clipping, back offset, camera look-at orientation, distance-based density/scale falloffs, and LOD controls.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



These features look related in the UI, but behave differently:

Camera culling: Decides whether an instance needs to participate in rendering or generation for a camera.

Distance falloff: Changes the population density or scale based on distance from the camera.

LOD: Chooses which geometry representation of an existing object should be rendered.

For example, consider a forest covering a large mountain:

- Camera culling can remove distant off-camera regions.
- Density falloff can reduce vegetation counts with distance.
- LOD can replace detailed trees with lighter representations.
- Viewport Point Cloud can show a simplified interactive representation regardless of render quality.

Those should be independent controls.

#### Why camera margins matter

ITOOSOFT recommends using camera `Expand` and `Back Offset` to reduce sudden appearance or disappearance of geometry and shadows around the camera boundaries. Its documentation mentions 10–20% expansion as a frequently useful range.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



For animation, a static frustum test at each frame can still produce visible popping.

A better cinematic workflow could support a camera-motion envelope: calculate the union of camera-frustum coverage across a specified shot range, then generate the necessary population once for the shot.

That would be a Cyrus Scatter enhancement rather than a documented ForestPack feature.

### 5.4 Forest LOD has its own source hierarchy

[Official Forest LOD reference](https://docs.itoosoft.com/forestpack/forest-plugin/forest-lod)

ForestPack's LOD helper groups two or more geometry alternatives. It supports switching based on maximum camera distance or minimum screen size, optional different materials, and transition variation to reduce abrupt changes.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



Example LOD policy for one tree

Near

Full tree mesh

Middle

Reduced geometry

Far

Billboard / proxy

Illustrative LOD strategy; actual thresholds and assets are artist-defined.

A useful architecture is to make LOD part of the Source Library, rather than adding a different scatter for each LOD level.

The renderer backend would receive the selected level and the appropriate material.

### 5.5 Materials require per-instance data

[Official Material rollout reference](https://docs.itoosoft.com/forestpack/forest-plugin/material)

ForestPack provides tinting from gradients or maps, randomized tint strength, hue/saturation/brightness correction, and a Material Optimizer.

Its Forest Color map supports per-instance or per-element variation. These systems rely on compatible materials or shader integration; they aren't simply viewport wire colors.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation

+1



For Cyrus Scatter, I would maintain a separate attribute stream:

```
Instance ID
Source ID
Transform
Tint Color
Tint Strength
Random Material Index
Animation Offset
User Attributes
```

This allows one plant mesh to render with different leaf tones without duplicating the underlying mesh or creating a unique material for every plant.

It also lets material variation remain deterministic. If the random seed and instance identity are unchanged, leaf color should not change just because the camera moves.

### 5.6 Animation sampling

ForestPack documents four active animation methods:

| Method          | Behavior                                        | Example                           |
| --------------- | ----------------------------------------------- | --------------------------------- |
| Follow Geometry | Every instance follows source animation in sync | Synchronized moving objects       |
| Random Samples  | Randomly chooses from a set of timeline offsets | Trees with differing wind phases  |
| Random From Map | Map controls which sample is selected           | Regional variation in wind timing |
| Frames From Map | Map controls an absolute source frame           | Artistic animation-state control  |

These are in addition to the disabled/static mode.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



The most important implementation detail is memory.

ITOOSOFT documents a ForestPack 9 animation-sample cache with a default limit of approximately 10 GB, automatically discarding older samples rather than retaining everything indefinitely. It also warns that some renderers using older integration interfaces may not support every sampling mode.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



For our implementation, animation caches should be bounded and reusable by source/time sample.

For example, if 50,000 animated plants use only 20 distinct geometry samples, ideally we should cache those 20 samples rather than creating 50,000 independent animated meshes.

### 5.7 Legacy shadows are a lower-priority subsystem

ForestPack also documents a Shadows rollout, largely associated with billboard trees, including historically used XShadow and raytraced shadow planes. Several details refer to legacy renderers such as Scanline and Mental Ray.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



I would not make this a first-phase Cyrus Scatter priority.

For a modern archviz pipeline centered on actual vegetation meshes, Arnold, Corona, and V-Ray support, renderer-native shadows and instancing deserve attention before reproducing legacy billboard-shadow behavior.

## 6. Effects: ForestPack's procedural extension system

This is one of the most powerful systems in ForestPack, and potentially one of the most valuable to replicate after the core scatter engine is stable.

[Official Effects documentation](https://docs.itoosoft.com/forestpack/forest-plugin/effects)

ForestPack Effects allow artists to modify instance properties using expressions, mathematical functions, spline queries, surface queries, maps, and artist-exposed parameters.

In other words, Effects are not just another group of randomization settings. They provide a programmable layer for extending the scatter engine.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation

+1



### 6.1 What an Effect can actually modify

The official Attributes reference distinguishes writable and read-only properties.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



| Attribute                | Read/write? | What it enables                     |
| ------------------------ | ----------- | ----------------------------------- |
| `fpItem.position`        | Writable    | Move or offset instances            |
| `fpItem.rotation`        | Writable    | Override orientations               |
| `fpItem.scale`           | Writable    | Modify size                         |
| `fpItem.visible`         | Writable    | Hide individual instances           |
| `fpItem.geomID`          | Writable    | Change the selected source          |
| `fpItem.tintColor`       | Writable    | Procedural color variation          |
| `fpItem.animSample`      | Writable    | Control animation sample            |
| `fpItem.surfDirection`   | Writable    | Modify surface orientation behavior |
| `fpItem.surfNormal`      | Read-only   | Examine terrain normal              |
| `fpItem.surfSlope`       | Read-only   | React to terrain inclination        |
| `fpItem.areaIncDistance` | Read-only   | React to inclusion boundaries       |
| `fpItem.areaExcDistance` | Read-only   | React to exclusion boundaries       |
| `fpItem.distUVW`         | Read-only   | Access distribution-map coordinates |
| `fpItem.distPathPos`     | Read-only   | React to location along a path      |

This means an Effect can combine information from several systems at once.

For example: the artist might want plants to become shorter near the edge of a walkway, but only on slopes below 25 degrees, and to change to a different source model near a wall.

The Effects system exposes much of the information necessary to express such a rule.

### 6.2 Expressions can query scene geometry

ForestPack documents functions for evaluating surfaces and splines:

| Function             | Result                                |
| -------------------- | ------------------------------------- |
| `fpSurfaceHitZ`      | Surface projection height             |
| `fpSurfaceHitNormal` | Normal at surface projection          |
| `insideSpline`       | Whether a position is inside a spline |
| `distanceSpline`     | Distance to a spline                  |
| `nearestPosSpline`   | Nearest point on a spline             |
| `nearestTangSpline`  | Tangent near the closest spline point |
| `evaluateTexture`    | Sample an artist-selected texture     |
| `evaluateCurve`      | Evaluate a custom curve               |
| `fpRandomGeom`       | Select a random Geometry List source  |

These are documented functions, not guesses about the implementation.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



A particularly important design choice is allowing an effect to read distance-to-boundary and surface-normal data without requiring the effect author to implement those calculations themselves.

For Cyrus Scatter, these values should already exist as fields in the candidate evaluation context.

### 6.3 Artist-controlled parameters are part of the feature

ForestPack Effects support numeric, object, controller, texture, and curve parameters. These are exposed in the user interface so artists can modify an Effect without rewriting the expression.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



That means the feature is really a combination of:

```
Effect Definition
    ├── Mathematical expression
    ├── Exposed UI parameters
    ├── Scene object dependencies
    ├── Texture dependencies
    └── Evaluation outputs
```

For Cyrus Scatter, I would eventually introduce a node-based or expression-based procedural modifier system.

Potential artists' controls could include:

- Lean plants away from a wall.
- Orient flowers toward the sun.
- Increase vegetation density near a water source.
- Change tree species according to elevation.
- Create an ordered row of vehicles along a path.
- Add direction-dependent wind variation.

Those can all be described as evaluating spatial or environmental inputs and producing instance attributes.

### 6.4 The difficult part is determining when Effects run

Suppose an Effect changes the selected source model, and the new model has a larger collision radius.

Should collisions be recalculated?

Suppose an Effect moves an object beyond a spline boundary.

Should the boundary test be repeated?

Suppose an Effect changes scale after LOD selection.

Does LOD need to update?

These questions expose the danger of treating Effects as a final, arbitrary post-processing function.

For Cyrus Scatter, I would require each procedural modifier to declare what it reads and writes.

For example:

```
struct EffectDependencies
{
    bool readsSurface = false;
    bool readsAreaDistance = false;
    bool readsCamera = false;

    bool writesPosition = false;
    bool writesSource = false;
    bool writesScale = false;
    bool writesVisibility = false;
};
```

The engine can then determine which downstream stages need reevaluation.

If an Effect changes only tint, we shouldn't rebuild candidate positions or collisions.

If it changes position or collision radius, we may need more extensive recomputation.

The central architectural lesson: extensibility requires a dependency-aware evaluation system, not simply an expression parser.

## 7. The systems that connect multiple ForestPack objects

### 7.1 ForestSet: shared collections of scene inputs

[Official ForestSet documentation](https://docs.itoosoft.com/forestpack/forestset-plugin)

ForestSet allows a collection of scene objects to be reused as source geometry, surfaces, spline areas, reference objects, paths, and Particle Flow inputs.

It can also consume objects from scene layers and supports nested collections, subject to documented restrictions.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



Imagine a large architectural project containing five separate vegetation scatters.

All five depend on the same terrain and a set of architectural exclusion splines.

Without shared input collections, artists must repeatedly assign the same references.

With ForestSet-like functionality, the setup becomes:

```
Landscape Input Collection
    ├── Terrain mesh
    ├── Building exclusion splines
    ├── Pedestrian path splines
    └── Planting regions
           ↓
    Shared by multiple scatters
```

That is a workflow feature, but it also creates a shared dependency graph that an engine can exploit for caching.

For Cyrus Scatter, shared collection inputs should support dynamic scene-layer membership and explicit object lists. The system should also detect circular references before evaluation.

### 7.2 Presets, libraries, and portable assets

ForestPack distinguishes parameter presets from full library presets.

Its traditional parameter presets store settings while retaining relevant external scene references. Its Library Browser supports meshes, billboards, and complete configured Forest objects. More recent versions also provide additional portable asset functionality.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation

+1



I would design three levels of reusable content for Cyrus Scatter:

| Preset type             | What it stores                                                            |
| ----------------------- | ------------------------------------------------------------------------- |
| Settings preset         | Numeric values, curves, generator choices, probabilities                  |
| Source collection       | Models, material references, source metadata, variation                   |
| Complete scatter preset | Sources, areas, distribution settings, transforms, dependency definitions |

These should be versioned and support missing-asset recovery.

If a preset references five custom plant models stored on a network drive, the system should not silently substitute unrelated geometry because the user opens the scene on a different workstation.

### 7.3 General settings, diagnostics, and management

ForestPack also provides deterministic Random Seed, CPU thread settings, manual updates, statistics, error indicators, and a Forest Lister for managing multiple scatters.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation

+2



I think an advanced scatter tool should expose more than a final instance count.

For Cyrus Scatter, I would provide statistics such as:

| Statistic                 | Why artists and developers need it     |
| ------------------------- | -------------------------------------- |
| Candidates generated      | Shows the raw distribution workload    |
| Rejected by area          | Reveals masking and exclusion cost     |
| Rejected by collision     | Reveals oversampling                   |
| Accepted instances        | Actual population size                 |
| Surface query time        | Detects expensive receiver sampling    |
| Area evaluation time      | Detects complex splines and masks      |
| Collision evaluation time | Detects spatial-index bottlenecks      |
| Viewport upload time      | Detects GPU transfer overhead          |
| Cached tiles reused       | Shows incremental-update effectiveness |
| Peak temporary memory     | Helps diagnose large-scene instability |

ITOOSOFT already surfaces some generation statistics. The expanded breakdown above is my proposed development and artist-diagnostic feature.

## 8. How these systems connect internally — the proposed Cyrus Scatter architecture

This is where I would move from researching ForestPack to planning a complete independent implementation.

The most important decision is to avoid creating one giant `GenerateScatter()` function containing everything.

Instead, the engine should be organized around data dependencies and independently cacheable evaluation stages.

### 8.1 A more complete evaluation pipeline

Recommended logical pipeline

1

Input snapshots

Source geometry, terrain, splines, maps, object references

2

Spatial preparation

Mesh acceleration, path tables, area masks, paint tiles

3

Candidate generation

Image, Path, Reference, Particle, future generators

4

Surface resolution

Position, normal, UV, slope, elevation, material ID

5

Area evaluation

Ordered include/exclude contributions and falloffs

6

Source and transform evaluation

Species, clustering, randomization, effect attributes

7

Occupancy resolution

Collision testing, spacing, boundary policy

8

Manual overrides

Additions, deletions, transforms, explicit source changes

9

Instance cache

Stable final population with incremental changes

10

Output adapters

Viewport, selection, render instances, export

This is a logical model. Actual execution must allow selected stages to run earlier, later, or be revisited when required by dependencies. It is not a verified ForestPack internal pipeline.

The ordering is not entirely linear.

For example, collision detection needs to know the chosen source's effective radius, so source selection must happen first.

But an Effect that changes the chosen source might require collision resolution to run again.

Similarly, some boundary policies evaluate an instance pivot, while others require the final transformed geometry.

That's why the scheduler must understand what changed and what must be recomputed.

### 8.2 The dependency matrix

This is how I would initially define update propagation.

| User changes            | Recompute                                           | Usually reusable                                             |
| ----------------------- | --------------------------------------------------- | ------------------------------------------------------------ |
| Global density          | Candidate distribution, downstream population       | Source meshes, terrain acceleration                          |
| Source probability      | Source selection and dependent calculations         | Candidate positions                                          |
| Source tint             | Material instance attributes                        | Placement, collision                                         |
| Source collision radius | Collision neighborhood and dependent results        | Terrain acceleration                                         |
| Paint stroke            | Affected spatial tiles, neighboring collision zones | Unaffected tiles                                             |
| Spline boundary         | Relevant area fields and dependent tiles            | Unrelated scatter regions                                    |
| Terrain deformation     | Surface acceleration and affected placements        | Source library                                               |
| Camera movement         | Visibility / LOD / display                          | Stable population, unless camera-dependent rules are enabled |
| Manual object move      | Override and relevant occupancy checks              | Other instance transforms                                    |
| Random seed             | Random-dependent stages                             | Geometry and static surface acceleration                     |
| Display mode            | Viewport representation                             | Final population                                             |
| Material parameter      | Material evaluation                                 | Position and surface data                                    |

This matrix should be implemented as explicit dirty flags and dependency edges, rather than relying on a single global "scene changed" notification.

### 8.3 Spatial partitioning: the core performance strategy

I would divide large scatter regions into spatial tiles.

Consider a 200 × 200 meter terrain divided into 10 × 10 meter tiles.

That gives 400 tiles.

Each tile could retain:

```
struct ScatterTile
{
    TileKey key;

    uint64_t inputRevision;
    uint64_t surfaceRevision;
    uint64_t areaRevision;

    Bounds3 bounds;

    CandidateBuffer candidates;
    InstanceBuffer instances;

    bool distributionDirty;
    bool surfaceDirty;
    bool occupancyDirty;
    bool displayDirty;
};
```

Suppose an artist paints a 3-meter-radius patch.

Only tiles touched by the brush, their falloff influence, and any additional collision-neighbor region should need updates.

However, the tile boundary cannot be treated as a hard collision boundary. Otherwise plants generated on adjacent tiles may overlap.

I would handle this using a deterministic cross-tile occupancy procedure and a halo region around each tile.

The halo width would depend on maximum collision radius, boundary falloff, brush influence, and any post-placement translations.

Another complication is deterministic generation.

If changing one tile affects the order in which random numbers are consumed elsewhere, the entire distribution can visibly shuffle.

That must be avoided.

### 8.4 Stable randomness: use keyed sampling rather than a single mutable stream

A traditional random generator might work like this:

```
Set seed = 42

Generate candidate 1
Generate candidate 2
Generate candidate 3
...
```

If a candidate is inserted earlier in the sequence, later random values can shift.

For a procedural creative tool, that is undesirable.

I would use keyed random functions, conceptually:

\\[ R=\operatorname{HashRandom}( \text{globalSeed}, \text{generatorID}, \text{tileID}, \text{candidateID}, \text{channel} ) \\]

The `channel` can distinguish source choice, rotation, scale, tint, and animation offset.

For example:

```
float rotationRandom =
    Random01(globalSeed, stableId, RotationChannel);

float scaleRandom =
    Random01(globalSeed, stableId, ScaleChannel);

float tintRandom =
    Random01(globalSeed, stableId, TintChannel);
```

Now changing the number of source models does not automatically alter the rotation random values for every surviving candidate.

It is also important to track receiver identity. ForestPack documents an option called `Randomize Stacked`, because instances at identical XY positions may otherwise share random properties.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



For Cyrus Scatter, the receiver ID or surface-local identity can be included in the random key when different stacked surfaces require independent variation.

### 8.5 The painting update pipeline

For the particular surface-painting research we've been pursuing, I would investigate this sequence:

Receive a viewport stroke sample

Hit position, normal, pressure, radius, receiver

Update the painted coverage field

Modify only affected mask tiles

Mark affected scatter tiles dirty

Include falloff and collision neighborhoods

Regenerate affected candidates

Preserve stable IDs outside changed areas

Publish a new viewport snapshot

The brush cursor and painted-region overlay should be visually responsive without waiting for a complete new scatter population.

I would separate stroke responsiveness from scatter completion latency. A user should see where they are painting immediately, even if a dense population update takes longer.

This also makes asynchronous cancellation possible. If the artist keeps dragging the brush, outdated evaluation jobs can be superseded instead of piling up.

### 8.6 The relevant 3ds Max C++ interface

Autodesk documents `IPainterCanvasInterface_V5`, which provides callbacks for starting, updating, finishing, and cancelling paint strokes.

The paint callbacks provide useful data including hit position, normal, barycentric coordinates, face index, node, brush radius, strength, tablet pressure, and modifier keys.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://help.autodesk.com\&sz=32)

help.autodesk.com



This provides a concrete SDK avenue for a native Cyrus Scatter painting implementation.

However, Autodesk also explicitly cautions that the 3ds Max SDK is generally not thread-safe. Most scene operations should remain on the main thread, while independent computations can use worker threads.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://help.autodesk.com\&sz=32)

help.autodesk.com

+1



The threading structure I would investigate is:

```
Main thread:
    Read 3ds Max scene objects
    Capture immutable mesh/spline snapshots
    Receive brush callbacks
    Publish finished results to scene/viewport

Worker threads:
    Build independent acceleration structures
    Evaluate distribution fields
    Generate candidates
    Resolve collisions
    Build compact instance buffers

Main thread:
    Commit validated result snapshots
```

We must avoid having worker threads call arbitrary 3ds Max scene APIs. The fact that a C++ operation is computationally expensive does not automatically make calling it off-thread safe.

### 8.7 A shared Surface Cache should be owned above individual scatter layers

ForestPack explicitly documents internally caching receiving-surface information and sharing it among Forest objects using the same terrain.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



That makes it reasonable to design:

```
Cyrus Surface Cache
    Terrain A -> Prepared mesh / acceleration
    Terrain B -> Prepared mesh / acceleration
    Terrain C -> Prepared mesh / acceleration
                      ↓
              Multiple scatter layers
```

This could be integrated with Cyrus Surface Analyzer, provided the analyzer's data contract supplies the required positions, normals, face attributes, and acceleration structures.

For correctness, a cache must have explicit invalidation rules.

A topology change, vertex deformation, transform update, UV modification, or material-ID change may invalidate different portions of the cached information.

These should not all force identical rebuilds.

### 8.8 Performance is also about memory layout

With hundreds of thousands of instances, storing everything as heavyweight objects with many pointers can degrade cache locality and increase allocation costs.

I would investigate Structure of Arrays for hot evaluation paths:

```
struct InstanceBuffer
{
    std::vector<uint64_t> ids;

    std::vector<Vec3> positions;
    std::vector<Quat> rotations;
    std::vector<Vec3> scales;

    std::vector<uint32_t> sourceIds;
    std::vector<uint32_t> receiverIds;
};
```

This permits efficient sequential passes over only the required attributes.

For example, camera culling may need position and bounds without touching material data. Tint updates may only need IDs and color attributes.

A user-facing class hierarchy can remain object-oriented while the core evaluation engine uses compact contiguous buffers.

I'd also preserve old immutable output snapshots until a newly calculated result is ready, rather than letting the viewport read an instance array while worker threads are modifying it.

## 9. A complete practical example: building one architectural landscape

Let's apply these concepts to a scene resembling the tutorial's environment.

Imagine a modern residential building surrounded by grass, planted terraces, mature trees, ornamental shrubs, and a winding pedestrian path.

The objective is not to make five disconnected scattering systems. It is to create a landscape whose vegetation layers influence one another.

### Step 1 — Establish shared inputs

Create a shared source collection containing the terrain, path splines, planting-bed outlines, and building geometry.

Build or retrieve cached surface acceleration data.

At this stage, we should not generate any vegetation yet.

### Step 2 — Create the grass population

[Journal - Barr Build](https://images.openai.com/static-rsc-4/HegeR7hsrgQXalIABA3PdzKg_4LtuKnDQBTDvjDsu8r9IztXzwHxfksAlNAswduerPK2DvN7pGwTLb7nhtoXUVBMf64yAIkdapdPpLHlvRUa9trY_s_Zo342g75mkJUOuAI7htJujb9K06WjhAbnljqrfQ-V_Yjpxo_gcL4ILLc?purpose=inline)

Grass layer

Use a dense Image distribution, several grass variations, modest random rotation, slight scale variation, and an Include region covering the lawn.

Add a Path Exclude Area and a short scale falloff along its edge.

The grass should become shorter near the path without introducing an unnaturally sharp transition.

The dependency chain becomes:

```
Terrain + Lawn Region + Path
    -> Candidate positions
    -> Surface placement
    -> Path exclusion and falloff
    -> Grass source selection
    -> Scale variation
    -> Collision / output
```

### Step 3 — Create the mature trees

[10 Low-Maintenance Best Trees for a Beautiful & Easy-Care landscape Yard](https://images.openai.com/static-rsc-4/LP7jqWYq4RJ7_KBFee3N33E9YCrz9PNVBLcRaOdG3yAD7RELkK3bT-SaAuQppAI8zyM3F35Z_DfUcKpUlsgswcVveEHzVra36Pm7hPjn7oIlLsXUqGAcZ-uzjzbIm554ef1GspmHI0hdC20QMBerrL-MLaERtA6IkTuYBeeJcEM?purpose=inline)

Tree layer

Use several source variations, low overall density, species clustering, source-specific collision radii, and constraints for slopes and building clearances.

Unlike grass, the individual location of each tree matters to the architectural composition.

The artist may want to move several trees manually to improve important views.

This is where sparse manual overrides would provide value.

### Step 4 — Make grass react to trees

Now add the generated Tree Scatter as an exclusion source for the Grass Scatter.

The grass should become less dense around mature trunks while preserving some vegetation beneath the canopy, depending on the intended landscaping design.

We should not assume that a tree's full crown radius is the correct ground-cover exclusion radius. It may be preferable to use a configurable root-zone or trunk-zone footprint instead.

This is an example of why source occupancy and visual geometry bounds deserve separate controls.

### Step 5 — Add ornamental shrubs and flowers

[Z czym łączyć lawendę na tarasie i w ogrodzie? 5 kompozycji, które dają efekt „wow" | Gardenowo](https://images.openai.com/static-rsc-4/5ApS_bYKjTtYiaWqL_OI8SoMWl0zCfa5-clB6gWVV5HnvJF3JvbBFn0AkI95KfY-rgCfyzv1AgD13Zeigb3kWGYVtrLUenXdt8rN_QH8_uzVWwtgmugSS9rBPwUpV5gE7eTqvSgEnVVVA6PpxpPfcNv3FhAg7cbuGzSuicXaL3w?purpose=inline)

Shrub and flower layer

Use painted inclusion areas, clustered species selection, per-area model restrictions, and gradual density falloffs.

In one area, the designer paints lavender. In another, taller ornamental grasses dominate.

Instead of creating duplicate systems with completely separate generators, both can use the same distribution engine with different spatial rules and source-selection policies.

When a paint stroke changes, only the influenced tiles and dependent occupancy zones should need regeneration.

### Step 6 — Add rocks beside the path

Use a Path generator or an open-spline Area, depending on whether the intended result is a regular series of stones or a loosely scattered strip.

Apply randomized lateral offsets, limited rotation, different rock sources, and collision avoidance.

This distinction is important:

- For regularly spaced stepping stones, Path Mode is appropriate.
- For loose natural rock distribution along a boundary, an open-spline area combined with Image Mode is often more suitable.

### Step 7 — Art-direct the final composition

Move the trees obscuring the building's main entrance. Reduce dense flower patches near the camera. Replace repeated rocks that look too similar.

All these changes should remain editable without flattening the entire scatter to meshes.

### The resulting dependency graph

Terrain + Architectural Input Collection

Tree Scatter

Clusters + manual overrides

Path Geometry

Exclusions + edges

Grass Scatter

Influenced by trees and path

Flower Scatter

Painted planting regions

Rock Scatter

Open splines / paths

Shared Viewport + Renderer Outputs

One possible scene dependency arrangement; the flower and rock layers do not inherently depend on the grass layer unless that relationship is configured.

This is the kind of real production setup we should use to evaluate the engine. It exercises area operations, shared surfaces, overlapping influence, painting, per-source variation, manual edits, and renderer output in a single test scene.

## 10. How to discover ForestPack's undocumented behavior

Reading the documentation tells us what the controls are intended to do. It does not reveal every evaluation-order rule or numerical implementation detail.

To recreate functionality reliably, I would establish a behavioral reference suite in a licensed ForestPack installation.

Each test should use a very simple scene, fixed source meshes, a fixed random seed, and one changed parameter at a time.

| Test                          | Question we need to answer                                                           | Expected evidence                             |
| ----------------------------- | ------------------------------------------------------------------------------------ | --------------------------------------------- |
| 1. Distribution pixel mapping | Is placement always centered on a pixel, jittered, or modified by pattern settings?  | Known bitmap with visible candidate points    |
| 2. Grayscale density          | How does a gray value alter accepted candidate counts?                               | Measured populations at fixed density         |
| 3. Source probabilities       | Do positions remain stable when source weights change?                               | Before/after instance positions               |
| 4. Clusters                   | What exactly do Size, Roughness, Blurry Edge, and Noise influence?                   | Species maps from controlled parameter sweeps |
| 5. Ordered Areas              | How are candidates combined when includes and excludes overlap?                      | Three-region comparison scene                 |
| 6. Per-area overrides         | How do local models, map thresholds, and scaling interact with global controls?      | Same source with several areas                |
| 7. Collision ordering         | Does changing source scale or random translation affect collision results?           | Candidate and reject counts                   |
| 8. Boundary modes             | At which stage are Point, Size, and Edge policies evaluated?                         | Oversized objects along a simple spline       |
| 9. Paint representation       | How accurately does Paint-to-Spline conversion preserve complex regions?             | Hundreds of overlapping strokes               |
| 10. Stacked surfaces          | How do XY, UV, and Randomize Stacked interact?                                       | Two vertically separated receiver meshes      |
| 11. Camera changes            | Which camera settings rebuild the distribution rather than only changing visibility? | Build time and instance positions             |
| 12. Effects precedence        | What happens when Effects change source, scale, position, or visibility?             | Small-scene controlled comparisons            |

Some of these may already have partial answers in the documentation. The purpose of testing is to resolve the undocumented details, not replace authoritative descriptions with guesses.

For example, ITOOSOFT confirms Image Mode uses an internal virtual grid and counts both active and empty candidate positions toward its maximum-density limit. That tells us something important about its generation model, but it does not reveal the precise random generator or data structure.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation

+1



The same applies to object exclusions: the rasterization approach is documented, but exact raster filtering and cache invalidation details are not.

### A particularly useful reverse-engineering experiment

Create a flat 10 × 10 meter receiver, one visible cube source, and a tiny hand-authored distribution bitmap with a known arrangement of white and black pixels.

Disable transforms, collisions, clustering, and camera-dependent rules.

Measure the generated positions.

Then enable one setting at a time:

1. Change X/Y Units.
2. Add random translation.
3. Apply a closed-spline inclusion.
4. Enable Point boundary checking.
5. Change to Size boundary checking.
6. Enable collisions.
7. Add a second source with a different collision radius.

This can reveal important evaluation dependencies with a very small number of instances.

Repeat the same test in Cyrus Scatter and compare the results.

The goal should be behavioral equivalence, not necessarily identical pseudorandom numbers or exact internal algorithms.

## 11. Complete feature-coverage plan for Cyrus Scatter

To prevent the implementation from becoming an endless collection of isolated UI controls, I would maintain a compatibility matrix.

The following is the major-feature inventory derived from the official ForestPack reference, grouped by the engineering subsystem each feature requires.

| System                 | Functionality to implement                                                                    | Foundation required                 |
| ---------------------- | --------------------------------------------------------------------------------------------- | ----------------------------------- |
| Sources                | Multiple geometry sources, weights, disabled entries, Color IDs, groups, material overrides   | Source registry                     |
| Image Distribution     | Bitmaps, procedural maps, tiling, units, resolution, threshold, density maps, color selection | Candidate generator + field sampler |
| Path Distribution      | Spacing, vertices, sequencing, offsets, tangents                                              | Curve sampler                       |
| Reference Distribution | Object pivots, faces, name matching, transform inheritance                                    | Reference adapter                   |
| Particle Distribution  | Particle positions, orientation, scale, event filtering                                       | Particle adapter                    |
| Areas                  | Ordered include/exclude, spline, object, Forest, painted and surface areas                    | Spatial region evaluator            |
| Area Overrides         | Source subset, local density, local scale, map and threshold overrides                        | Parameter inheritance               |
| Falloffs               | Include/exclude distance, curves, inversion, density, scale, height-only                      | Distance fields                     |
| Surfaces               | XY/UV mapping, normals, slope, altitude, material IDs                                         | Surface sampler                     |
| Clusters               | Spatial source grouping, roughness, mixed edges, noise                                        | Species selection fields            |
| Collisions             | Global/per-source radii, collision height, rejection                                          | Spatial occupancy index             |
| Transforms             | XYZ movement, rotation, scaling, maps, probability curves, mirror                             | Deterministic transform evaluator   |
| Item Editing           | Place, move, rotate, replace, delete, reseed, attach/detach                                   | Persistent instance editing         |
| Camera                 | FOV, expand, back offset, clipping, distance falloffs                                         | Camera visibility evaluator         |
| LOD                    | Source alternatives, screen size, distance, material selection                                | LOD resolver                        |
| Viewport               | Point cloud, boxes, arrows, mesh, display limits, selection                                   | GPU viewport backend                |
| Rendering              | Native instances, source/proxy support, output limits                                         | Renderer adapters                   |
| Materials              | Instance tint, color-map variation, per-element variation                                     | Material attribute stream           |
| Animation              | Source playback, offsets, mapped samples, sample caching                                      | Time-dependent source cache         |
| Effects                | Expressions, fields, functions, scene references, user parameters                             | Attribute evaluation engine         |
| Collections            | Shared sources, references, surfaces, areas, scene-layer input                                | Dependency graph                    |
| Presets                | Saved settings, source libraries, full-scatter presets                                        | Serialization and asset management  |
| Diagnostics            | Counts, warnings, timers, cache status, failure reasons                                       | Instrumentation                     |

This represents the major functionality, not a verified one-to-one transcription of every historical UI spinner, checkbox, and menu item. A true control-level compatibility audit should track defaults, supported versions, valid ranges, combinations, and expected outcomes individually.

### What should come first?

I would divide the implementation into seven engineering milestones.

Milestone 1 — Engine foundations

Typed candidate and instance buffers, stable IDs, deterministic random channels, shared geometry caches, spatial tiling, dependency invalidation, and profiling.

Acceptance criterion: Generating and re-evaluating the same inputs produces deterministic results without unnecessary surface rebuilding.

Milestone 2 — Distribution and surfaces

Image, Path, and Reference generators; XY projection; UV projection; slope and altitude restrictions; multi-surface support.

Acceptance criterion: Each distribution mode produces repeatable positions and meaningful surface-aligned transforms across controlled test scenes.

Milestone 3 — Areas and painting

Ordered area operations, spline masks, object exclusions, Forest-driven exclusions, local overrides, curves, brush strokes, Undo/Redo, and local updates.

Acceptance criterion: Painting a small region does not invalidate unrelated areas, and area order produces predictable results.

Milestone 4 — Population intelligence

Weighted species selection, Color IDs, clustering, transforms, probability curves, collisions, boundary checking, source groups, and persistent manual overrides.

Acceptance criterion: Artists can create controlled natural variation and locally refine instances without destabilizing unrelated placements.

Milestone 5 — High-performance display and rendering

Point-cloud and proxy representations, camera culling, LOD, renderer-native instancing, material attributes, and source-specific output handling.

Acceptance criterion: Viewport navigation remains independent from full population regeneration in ordinary scenes.

Milestone 6 — Advanced procedural behavior

Effects expressions, scene-based parameters, cross-scatter dependencies, advanced source transformations, animation sample handling, and additional distribution adapters.

Acceptance criterion: Advanced rules are evaluated safely, deterministically, and with explicit dependency tracking.

Milestone 7 — Product completion

Preset management, shared collections, asset portability, diagnostics, documentation, UI consistency, renderer compatibility, and regression coverage.

Acceptance criterion: Complex scenes can be saved, reopened, shared, and reproduced reliably.

Although these are presented in sequence, I would build basic viewport display and render-instance output early enough to test every earlier milestone. The fifth milestone represents completing and optimizing those systems, not postponing all rendering work until then.

## 12. Five particularly revealing clues about ForestPack's engineering

After comparing the official feature descriptions, several details provide strong evidence about the kinds of engineering techniques that make ForestPack practical at large scene scales.

| Documented behavior                                        | What it reveals                                                    | Lesson for Cyrus Scatter               |
| ---------------------------------------------------------- | ------------------------------------------------------------------ | -------------------------------------- |
| Object exclusions are converted into projected masks       | Expensive geometry relationships can be precomputed                | Cache spatial queries                  |
| Receiving-surface data is shared among Forest objects      | Surface preparation is not necessarily owned by each scatter       | Share immutable receiver data          |
| Viewport Point Cloud buffers are cached on the GPU         | Display data can be independent of full scene geometry             | Separate visualization from generation |
| Animated geometry samples have a bounded memory cache      | Instance count and geometry-sample count are different             | Reuse and evict samples intelligently  |
| Effects can modify position, source, scale, and visibility | The procedural system exposes instance attributes for modification | Make evaluation stages composable      |

All five behaviors are described in ITOOSOFT's technical documentation. They are strong architectural clues, but not a disclosure of its exact C++ classes or implementation.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation

+4



### An especially interesting discovery: the Repulsion Effect

ITOOSOFT publishes a Repulsion Effect that moves instances away from a target object.

After moving an instance in XY, the expression explicitly queries the receiving surface again to update its Z position.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.itoosoft.com\&sz=32)

Reference & Documentation



Conceptually:

```
Vec2 away = Normalize(item.xy - target.xy);

float influence = EvaluateRepulsionFalloff(
    Distance(item.xy, target.xy)
);

item.xy += away * influence * strength;

item.z = surface.SampleHeight(item.xy);
```

This tells us something important: when an Effect moves an item laterally, surface re-projection may need to be explicitly requested.

It supports the idea that instance transformations and surface sampling are not always automatically coupled after every modification.

We shouldn't conclude that ForestPack internally uses this exact C++ sequence, but it is a valuable behavioral detail to reproduce and test.

## 13. Official documentation to study systematically

These are the references I would use to build a control-by-control specification.

| Topic                                      | Primary reference                                                                                                                          |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Product-wide feature hierarchy             | [ForestPack Plugin Reference](https://docs.itoosoft.com/forestpack/forest-plugin)                                                          |
| Sources, weights, groups, materials        | [Geometry Rollout](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry)                                                        |
| Candidate generation, diversity, collision | [Image Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode)                                                   |
| Areas, painting, exclusions, falloffs      | [Areas Rollout](https://docs.itoosoft.com/forestpack/forest-plugin/areas)                                                                  |
| XY/UV, normals, slope, altitude            | [Surface Rollout](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces)                                                             |
| Translation, rotation, scale, random maps  | [Transform Rollout](https://docs.itoosoft.com/forestpack/forest-plugin/transform)                                                          |
| Individual item editing                    | [Items Editor](https://docs.itoosoft.com/forestpack/forest-plugin/item-editor)                                                             |
| Camera optimization                        | [Camera Rollout](https://docs.itoosoft.com/forestpack/forest-plugin/camera)                                                                |
| Procedural expressions and functions       | [Effects System](https://docs.itoosoft.com/forestpack/forest-plugin/effects)                                                               |
| Viewport and renderer modes                | [Display Rollout](https://docs.itoosoft.com/forestpack/forest-plugin/display)                                                              |
| LOD                                        | [Forest LOD](https://docs.itoosoft.com/forestpack/forest-plugin/forest-lod)                                                                |
| Performance recommendations                | [Rendering Best Practice](https://docs.itoosoft.com/forestpack/rendering/rendering-best-practice)                                          |
| Native painting integration                | [Autodesk Painter SDK](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_i_painter_canvas_interface___v5.html) |

The next level of research should turn these into a precise control specification. Each control should record its default, parameter range, applicable distribution modes, dependencies, evaluation consequences, version-specific behavior, and an independent implementation design.

That is how we move from understanding the features to being able to reproduce them reliably.

## Final assessment

I think we now have a solid architectural understanding of ForestPack's principal systems, but this is not yet proof of feature-by-feature parity, nor a complete reading of every historical release note, scripting reference, or undocumented behavior. Those require further targeted tests.

The most important realization is that ForestPack's functionality is built around connections:

- Areas control populations, but also provide distance data to Effects.
- Sources determine appearance, but also influence probability, collisions, and LOD.
- Surfaces provide placement, but can be shared and cached across multiple scatters.
- Painting edits regions, which modify procedural populations.
- Camera controls affect rendering, but can also affect population evaluation and cache performance.
- Effects connect almost all of these through per-instance attributes.

For Cyrus Scatter, I would not start by copying ForestPack's UI control by control. I would start by building the shared computational foundations—spatial fields, candidate generators, deterministic instance data, surface caches, area operations, and dependency-aware updates—and then implement controls on top of those foundations.

That gives us a path to reproduce ForestPack's established functionality while designing something better in areas such as incremental painting, persistent manual overrides, transparent performance diagnostics, and artist-directed composition.

The highest-value next technical study is the complete Area + Paint + Surface interaction system. It's where the greatest number of controls intersect, where performance can become difficult, and where a good architecture can unlock much of the remaining feature set without repeatedly rewriting the engine.