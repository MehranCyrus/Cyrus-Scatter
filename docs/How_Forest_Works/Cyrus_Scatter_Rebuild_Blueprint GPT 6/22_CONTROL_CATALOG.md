# 22 — Proposed control and command catalog

**301 controls/commands across 17 groups · Proposed CyrusV1 schema · Not a verified one-to-one ForestPack UI audit.**

## How to use this catalog

The feature families and terminology come from the uploaded research. Every default and hard-domain policy below is a **proposed Cyrus specification**, not an asserted ForestPack default or a claim about current Cyrus. A row is not proof that the feature has been implemented.

Parameter IDs are stable semantic names for the new command/schema layer, not existing Max ParamBlock numeric IDs. Bind them to the actual host persistence format only after the repository audit. Chapter links provide algorithms, precedence, error handling, and tests. Test IDs refer to chapter 20. A command has no persistent numeric default.

All numeric input rejects NaN/infinity. Positive excludes zero; nonnegative includes zero. Ordered intervals require minimum <= maximum. A UI may use convenient soft spinner limits but must preserve the hard domain and explicit resource guards. Lengths are stored in meters and displayed through host unit conversion. Defaults chosen for budgets/resolution are initial engineering choices requiring workload testing.

**Support rule:** every row is a build target. Renderer/proxy/host-dependent rows remain unavailable until their adapter is qualified. The catalog does not silently claim support for an untested product version.

## Setup and layer ownership

**Owner:** Setup / Layer. **Specification:** [01 — implementation chapter](01_PRODUCT_SCOPE_AND_BEHAVIOR.md). **Basis:** R0 §§1,7–8.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `setup.name` | Setup name | UTF-8 string | Cyrus Setup | Metadata / T36 | Display label; not an identity key. |
| `setup.profile` | Behavior profile | Versioned enum | CyrusV1 | All semantic stages / T38 | Locks evaluation semantics for existing scenes. |
| `setup.units` | Canonical units | Length/time profile | Meters / host-converted ticks | Capture and persistence / H05 | Convert at host boundaries; never infer from display units alone. |
| `setup.seed` | Global seed | Unsigned 64-bit integer | 42 | Random-dependent stages / T39 | Independent channels prevent unrelated random changes. |
| `setup.update_mode` | Update mode | Live / GestureEnd / Manual | Live | Scheduling / T37 | Changes when evaluation runs, not what the recipe means. |
| `setup.final_policy` | Final render policy | CurrentAuthority / ExplicitFrozen | CurrentAuthority | Render closure / R08 | Never silently use stale viewport data. |
| `setup.workers` | Worker budget | Auto or positive integer | Auto bounded pool | Scheduling only / T39 | Must not change canonical output. |
| `setup.cache_budget` | Derived CPU cache budget | Positive bytes | 4 GiB | Cache eviction / T38 | Budget is a proposed starting value, not a performance guarantee. |
| `setup.algorithm_version` | Algorithm version | Versioned read-only identifier | Saved at creation | All caches / T36 | Changing algorithms requires explicit compatibility handling. |
| `layer.enabled` | Layer enabled | Boolean | True | Population/output / T36 | Retain authored state when disabled. |
| `layer.name` | Layer name | UTF-8 string | Layer | Metadata / T36 | Renaming does not reseed. |
| `layer.source_set` | Source collection | UUID reference | Unbound | Source resolution / T04 | An empty assignment reports no eligible sources. |
| `layer.receiver_set` | Receiver collection | UUID reference | Unbound | Surface resolution / T10 | Receiver membership is separate from coverage. |
| `layer.priority` | Layer priority in shared occupancy | Signed integer | 0 | Occupancy / T23 | Used only by an explicitly combined collision domain. |
| `layer.update` | Update now | Command | No persistent default | Evaluation / T37 | Build the current committed recipe. |

## Source definitions

**Owner:** Source. **Specification:** [10 — implementation chapter](10_SOURCES_TRANSFORMS_AND_GROUPS.md). **Basis:** R0 §4; S07.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `source.name` | Source name | UTF-8 string | Asset display name | Metadata/matching / T09 | Name matching is opt-in; UUID remains authoritative. |
| `source.provider` | Source provider | Mesh / Compound / QualifiedProxy | Unbound mesh provider | Prototype and bounds / R02 | Provider advertises available geometry and renderer capabilities. |
| `source.weight` | Probability weight | Finite real >= 0 | 1 | Selection and occupancy / T04 | Relative weights normalize over the eligible subset. |
| `source.selection_state` | Selection state | Enabled / Empty / Excluded | Enabled | Selection / T04 | Empty keeps weight; Excluded renormalizes remaining sources. |
| `source.color_id` | Color/category ID | RGB data or integer label | White RGB | Species selection / T06 | Metric and matching policy are separately saved. |
| `source.base_scale` | Base XYZ scale | Finite positive vector | 1,1,1 | Transforms/bounds / T20 | Applied once before random/local multipliers. |
| `source.target_dimensions` | Target dimensions | Optional positive length vector | Disabled | Transforms/bounds / T20 | Zero source extents require a defined validation route. |
| `source.pivot_policy` | Source pivot | Original / BoundsBase / Custom | Original | Transforms / T20 | Normalization never mutates the source mesh in place. |
| `source.pivot_offset` | Custom pivot offset | Finite length vector | 0,0,0 | Transforms / T20 | Interpreted in declared source-local coordinates. |
| `source.z_offset` | Placement Z offset | Finite length | 0 m | Transforms/boundaries / T20 | Source-local up by default, not implicitly world Z. |
| `source.offset_frame` | Offset frame | Source / Surface / World | Source | Transforms / T20 | Determines direction of authored offsets. |
| `source.collision_radius` | Collision radius | Finite length >= 0 | Auto from chosen proxy | Occupancy / T22 | Separate from root exclusion and visual bounds. |
| `source.collision_center` | Collision center | Finite local length vector | Proxy center | Occupancy / T22 | Height offset moves the sphere; it does not enlarge it. |
| `source.root_radius` | Root-clearance radius | Finite length >= 0 | 0 m | Downstream fields / T23 | Explicit tree-to-groundcover influence. |
| `source.root_scale_policy` | Root-radius scale policy | FixedWorld / FollowScale | FixedWorld | Downstream fields / T23 | Avoids accidental canopy-size exclusions. |
| `source.material_policy` | Material assignment | Source / Override | Source | Material/output / R03 | An override does not change source geometry. |
| `source.material_override` | Override material | Host reference | Unbound | Material/output / R03 | Active only with Override policy. |
| `source.children` | Include children | Boolean | False | Compound snapshot / R01 | Do not ingest arbitrary descendants accidentally. |
| `source.group_mode` | Compound evaluation | Atomic / Expanded | Atomic | Transforms/occupancy / T22 | Expanded children receive separate identities and constraints. |
| `source.lod_set` | LOD alternatives | Ordered provider collection | Single original level | Representation / T32 | LOD selects supplied assets; it is not automatic decimation. |
| `source.replace` | Replace source asset | Command preserving SourceUUID | No persistent default | Source-dependent stages / T22 | Reevaluate bounds, constraints, and output capabilities. |
| `source.missing_policy` | Missing-source policy | Diagnostic / FailFinal | FailFinal | Output validation / T40 | Never substitute a random source or erase its weight silently. |

## Receiving surfaces

**Owner:** Layer / Receiver binding. **Specification:** [05 — implementation chapter](05_SURFACES_COORDINATES_AND_GEOMETRY.md). **Basis:** R0 §§3.4–3.5; S03.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `surface.mode` | Placement domain | Projected / UV / WorldArea | Projected | Enumeration/resolution / T11 | Each mode promises density in a different domain. |
| `surface.frame` | Projection frame | World / Setup / Receiver / Custom | Setup | Coordinates / T10 | Saved frame defines U,V,W axes. |
| `surface.hit_policy` | Projection hit policy | Nearest / Highest / Selected / All / Sheet | Nearest | Resolution / T10 | All hits expands candidates with receiver-aware IDs. |
| `surface.sheet` | Explicit sheet restriction | Optional sheet identity | None | Resolution / T10 | Needed to distinguish folded projected sheets where applicable. |
| `surface.ray_interval` | Projection depth interval | Finite min/max length | Derived from bounds plus margin | Resolution / T10 | No hit produces a diagnostic, not silent Z=0 placement. |
| `surface.planar_fallback` | Allow planar fallback | Boolean | False | Resolution / T11 | Explicit alternative when no receiver is assigned/hit. |
| `surface.as_include` | Use receiver as include | Boolean | False | Contribution program / T13 | Assigning terrain alone does not fill it in this default profile. |
| `surface.up_axis` | Reference up | Normalized vector/frame axis | Setup +Z | Slope/alignment / T11 | Independent of viewport orientation. |
| `surface.normal_kind` | Normal for slope | Geometric / Shading | Geometric | Eligibility / T11 | Shading edits do not change slope by default. |
| `surface.normal_blend` | Align up toward normal | Real 0..1 | 0 | Transforms / T20 | Zero is reference-up; one is normal-aligned. |
| `surface.down_up_mapping` | Forest-like direction mapping | Optional -100..100 | Disabled | Transforms / T20 | Compatibility mapping must be qualified, not assumed equivalent. |
| `surface.uv_channel` | Placement UV channel | Positive channel identifier | 1 | UV sampling / T12 | Missing/degenerate UVs have explicit failure behavior. |
| `surface.uv_overlap` | Overlapping UV policy | AllFaces / Priority | AllFaces | Enumeration / T12 | Geometric face identity distinguishes mapped overlaps. |
| `surface.uv_transform` | UV scale/offset/rotation | Finite affine mapping | Identity | UV sampling / T12 | Mapping edits invalidate only dependent stages. |
| `surface.material_ids` | Allowed face material IDs | Set of integer IDs | All | Eligibility / T09 | IDs refer to the evaluated snapshot. |
| `surface.slope_enabled` | Slope restriction | Boolean | False | Eligibility / T11 | Disabled retains configured range without applying it. |
| `surface.slope_range` | Slope interval | Ordered angles 0..180 degrees | 0..90 degrees | Eligibility / T11 | Inclusive endpoints; backface policy remains separate. |
| `surface.altitude_enabled` | Altitude restriction | Boolean | False | Eligibility / T18 | Altitude uses the saved axis and origin. |
| `surface.altitude_range` | Altitude interval | Ordered finite lengths | 0..100 m | Eligibility / T18 | An inverted interval is rejected. |
| `surface.altitude_density` | Altitude density curve | Normalized response curve | Constant 1 | Density / T18 | Separate from altitude scale. |
| `surface.altitude_scale` | Altitude scale curve | Nonnegative response curve | Constant 1 | Transforms / T18 | Can change footprints and collisions. |
| `surface.fit_slope` | Fit ground-cover footprint to slope | Boolean | False | Transforms/constraints / T20 | Approximate footprint policy, not density correction. |
| `surface.fit_max` | Maximum slope stretch | Real >= 1 | 4 | Transforms/constraints / T20 | Prevents divergent stretch near vertical surfaces. |
| `surface.auto_refresh` | Automatically refresh host surface | Boolean | True | Capture / H02 | Manual refresh is explicit and shows dirty state. |
| `surface.rebind` | Repair topology bindings | Bounded command | No persistent default | Bindings / T29 | Requires receiver, distance, and normal constraints with report. |

## Image and progressive density

**Owner:** Generator. **Specification:** [07 — implementation chapter](07_DISTRIBUTION_AND_SPECIES_SELECTION.md). **Basis:** R0 §2; S02.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `distribution.kind` | Generator mode | Image / Progressive / Path / Reference / Particle / External | Image | Enumeration / T01 | Structural changes have identity-epoch consequences. |
| `image.field` | Distribution image/map | Field reference | Solid 1 | Eligibility / T01 | Data interpretation is separate from source selection. |
| `image.interpretation` | Image interpretation | Binary / Density | Binary | Eligibility / T02 | Binary threshold and probabilistic density are distinct. |
| `image.units` | Physical pattern dimensions | Positive XY lengths | 10,10 m | Enumeration / T01 | Scaling the pattern moves samples and changes raw density. |
| `image.resolution` | Procedural sample dimensions | Positive integer pair | 128,128 | Enumeration / T01 | Bitmap mode uses image dimensions; structural edit warning. |
| `image.aspect_lock` | Lock aspect ratio | Boolean | True | Enumeration / T01 | The X dimension is authoritative in this proposal. |
| `image.offset` | Pattern offset | Finite XY lengths | 0,0 m | Enumeration / T03 | Moves sample positions; not just the density texture. |
| `image.rotation` | Pattern rotation | Finite angle | 0 degrees | Enumeration / T01 | Rotation occurs in the saved generator frame. |
| `image.threshold` | Binary threshold | Real 0..1 | 0.5 | Eligibility / T01 | Equality is accepted in this profile. |
| `image.wrap` | Image wrap | Repeat / Clamp / Mirror / Border | Repeat | Field evaluation / T03 | Negative coordinates use mathematical floor. |
| `image.filter` | Scalar sampling filter | Nearest / Bilinear | Nearest for binary | Field evaluation / T01 | Saved semantic setting, not an invisible preview override. |
| `image.jitter` | Within-cell jitter | XY fractions 0..1 | 0,0 | Enumeration / T01 | Separate random channels and explicit evaluation timing. |
| `image.map_channel` | Field mapping channel | Optional integer channel | Use generator coordinates | Field sampling / T12 | Do not confuse surface UV placement with map sampling. |
| `image.fit` | Fit pattern to bounds | Command | No persistent default | Pattern transform / T01 | Writes explicit size/offset values. |
| `image.gizmo` | Show pattern gizmo | Boolean | True | Viewport only / T31 | No population change. |
| `distribution.density_probability` | Density probability | Real 0..1 | 1 | Eligibility / T02 | Stable thinning within an unchanged candidate universe. |
| `distribution.candidate_cap` | Candidate safety cap | Positive integer | 10000000 | Enumeration guard / T40 | Reports virtual/evaluated counts; no silent truncation. |
| `progressive.cell_size` | Progressive domain cell size | Positive length | 1 m | Enumeration / T02 | Structural domain setting, independent of cache page size. |
| `progressive.capacity` | Samples per domain cell | Positive integer | 64 | Enumeration / T02 | Increasing appends ranks; artistic probability remains separate. |
| `distribution.count_mode` | Count semantics | Candidates / FillAccepted | Candidates | Enumeration/constraints / T40 | FillAccepted is a bounded search with explicit failure. |
| `distribution.target_count` | Requested count | Nonnegative integer | 1000 | Enumeration / T40 | Only active in count-driven mode. |
| `distribution.attempt_cap` | Fill attempt cap | Positive integer | 100000 | Enumeration guard / T40 | Prevents endless retries in saturated regions. |

## Path, reference, particles, external providers

**Owner:** Generator. **Specification:** [07 — implementation chapter](07_DISTRIBUTION_AND_SPECIES_SELECTION.md). **Basis:** R0 §§2.5–2.7; S04–S06.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `path.curves` | Path inputs | Curve collection | Unbound | Preparation / T07 | Each curve has persistent identity. |
| `path.mode` | Path sampling | Spacing / Vertices / FitCount | Spacing | Enumeration / T08 | Modes have different endpoint and identity rules. |
| `path.spacing` | Spacing distance | Positive length | 1 m | Enumeration / T07 | Measured by arc length, not raw spline parameter. |
| `path.start_offset` | Start offset | Nonnegative length | 0 m | Enumeration / T08 | Does not duplicate a closed seam endpoint. |
| `path.end_offset` | End offset | Nonnegative length | 0 m | Enumeration / T08 | Open-path endpoint rule remains explicit. |
| `path.lateral_offset` | Lateral offset | Finite length | 0 m | Transforms / T08 | Default spacing remains measured on centerline. |
| `path.offset_metric` | Offset spacing metric | Centerline / ReparameterizedOffset | Centerline | Preparation / T07 | Two different curves can have different lengths. |
| `path.follow` | Follow tangent | Boolean | True | Transforms / T08 | Uses stable transported frames for 3D curves. |
| `path.along_jitter` | Along-path randomness | Nonnegative length | 0 m | Enumeration/transform / T08 | Separate from lateral randomness. |
| `path.lateral_jitter` | Lateral randomness | Nonnegative length | 0 m | Transforms / T08 | Can require final boundary/projection checks. |
| `path.source_mode` | Path source ordering | Weighted / Sequence | Weighted | Source selection / T08 | Sequence consumes explicit authored order. |
| `path.arc_tolerance` | Arc-length tolerance | Positive length | 0.001 m | Preparation / T07 | Saved numerical quality, not a hidden speed knob. |
| `reference.mode` | Reference samples | Pivots / Faces / WorldArea | Pivots | Enumeration / T09 | Items per face does not imply uniform area density. |
| `reference.items_per_face` | Items per face | Positive integer | 1 | Enumeration / T09 | Face topology epoch participates in identity. |
| `reference.random_position` | Randomize within faces | Boolean | True | Enumeration / T09 | Uniform triangle sampling uses corrected barycentrics. |
| `reference.inherit_rotation` | Inherit reference orientation | Boolean | True | Transforms / T20 | Independent from scale inheritance. |
| `reference.inherit_scale` | Inherit reference scale | Boolean | True | Transforms / T20 | Shear is preserved only through a declared supported route. |
| `reference.match` | Source name matching | Off / Exact / Regex | Off | Source selection / T09 | Regex evaluation is bounded. |
| `reference.match_case` | Case-sensitive matching | Boolean | False | Source selection / T09 | Normalization policy is saved. |
| `particle.system` | Particle input system | Host reference | Unbound | Capture / T09 | Input is not the PFlow output transport. |
| `particle.events` | Included events | Event identity set | All selected-system events | Enumeration / T09 | Stable birth IDs must be qualified by the adapter. |
| `particle.inherit` | Particle inherited attributes | Position/orientation/scale flags | All supported | Transforms / T09 | Unsupported attributes are reported explicitly. |
| `external.provider` | External candidate adapter | Qualified provider identifier | Unbound | Capture / T40 | Live vendor integration requires a verified API contract. |
| `external.tag_matching` | External source-tag matching | Off / Exact tag | Exact tag | Source selection / T09 | Missing/ambiguous tags use explicit failure policy. |

## Species variation and clustering

**Owner:** Layer / Area contribution. **Specification:** [07 — implementation chapter](07_DISTRIBUTION_AND_SPECIES_SELECTION.md). **Basis:** R0 §§2.2–2.3.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `species.mode` | Species selection | Weighted / ColorID / Clustered | Weighted | Source selection / T04 | Selection changes do not regenerate raw positions. |
| `species.color_metric` | Color distance metric | Declared RGB / ExactLabel | Linear RGB Euclidean | Source selection / T06 | Cyrus policy, not asserted ForestPack implementation. |
| `species.equal_id` | Shared Color-ID handling | WeightedWithinID / FirstCanonical | WeightedWithinID | Source selection / T06 | Tie handling is deterministic. |
| `cluster.size` | Cluster size | Positive length | 5 m | Species field / T06 | Changes spatial patch scale, not candidate density. |
| `cluster.roughness` | Boundary roughness | Real 0..1 | 0.3 | Species field / T06 | Bounded coordinate warp of the species field. |
| `cluster.edge_mix` | Edge mixing | Real 0..1 | 0.2 | Species field / T06 | Blends site/species probabilities near transitions. |
| `cluster.outliers` | Out-of-cluster noise | Real 0..1 | 0.05 | Species field / T06 | Blends with the base species distribution. |
| `cluster.seed_salt` | Cluster variation salt | Unsigned integer | 0 | Species field / T06 | Separate from transform/tint randomness. |

## Areas and local overrides

**Owner:** Area use / Definition. **Specification:** [08 — implementation chapter](08_ORDERED_AREAS_EXCLUSIONS_AND_BOUNDARIES.md). **Basis:** R0 §3; S01.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `area.enabled` | Area enabled | Boolean | True | Contribution program / T13 | Keeps definition and local values when off. |
| `area.operation` | Area operation | Include / Exclude / UnionRegion | Include | Contribution program / T14 | Independent includes and union regions are not interchangeable. |
| `area.definition` | Area type/reference | Spline / Object / Scatter / Paint / Surface / Linked | Unbound spline | Fields / T13 | Definition can be shared while responses remain local. |
| `area.order` | Execution order | Nonnegative integer position | Append as latest operation | Contribution program / T13 | UI explicitly shows bottom-to-top semantics. |
| `area.scope` | Exclusion scope | EarlierAll / SelectedContributions | EarlierAll | Eligibility / T13 | A later include can reintroduce placements. |
| `area.receiver_scope` | Receiver restriction | Optional receiver UUID set | Inherit layer | Resolution/eligibility / T10 | Prevents accidental cross-floor application. |
| `area.width` | Open-spline corridor width | Positive length | 1 m | Region construction / T15 | Full width; default round caps/joins. |
| `area.force_open` | Treat closed spline as corridor | Boolean | False | Region construction / T15 | Does not become interval-based Path distribution. |
| `area.fill_rule` | Closed-region fill rule | EvenOdd / StrictSimple | EvenOdd | Region construction / T15 | Holes/self-intersections have defined semantics. |
| `area.curve_tolerance` | Curve flattening tolerance | Positive length | 0.001 m | Region preparation / T15 | Included in field cache keys. |
| `area.top_limit` | Object exclusion top limit | Optional finite height | Disabled | Footprint preparation / T16 | Crossing triangles are clipped under CyrusV1. |
| `area.top_frame` | Top-limit coordinate policy | AbsoluteFrame / ObjectRelative | ObjectRelative | Footprint preparation / T16 | Makes overhang exclusion predictable. |
| `area.footprint_scale` | Scale exclusion footprint | Positive real | 1 | Field support / T16 | Different from dilation by a fixed distance. |
| `area.clearance` | Exclusion clearance | Nonnegative length | 0 m | Field/eligibility / T17 | Explicit dilation/clearance distance. |
| `area.texel_size` | Projected-mask target texel size | Positive length | 0.02 m | Field preparation / T16 | Displays world-space accuracy and estimated memory. |
| `area.scatter_shape` | Upstream scatter representation | Sphere / Footprint / QualifiedMesh | Sphere | Dependency field / T23 | Consumes upstream final edited population. |
| `area.models_enabled` | Use local source subset | Boolean | False | Selection / T04 | Empty enabled subset produces no sources. |
| `area.models` | Local source subset | Source UUID set | Empty | Selection / T04 | Only applied when local subset is enabled. |
| `area.density` | Local density multiplier | Finite real >= 0 | 1 | Eligibility / T18 | Multiplies global probability before final clamp. |
| `area.map_override` | Local distribution field override | Inherit / Field reference | Inherit | Eligibility / T13 | Replacement is distinct from multiplication. |
| `area.random_scale_override` | Local random scale range | Inherit / Positive min/max | Inherit | Transforms / T20 | Replaces the global random range. |
| `area.fixed_scale` | Local fixed XYZ multiplier | Positive vector | 1,1,1 | Transforms/constraints / T20 | Multiplies the resolved scale recipe. |
| `area.boundary_mode` | Boundary test | Point / Footprint / QualifiedElement | Point | Final gates/output / T17 | Capabilities and costs differ. |
| `area.boundary_timing` | Point-test stage | ResolvedSample / FinalPlacement | FinalPlacement | Final gates / T20 | Strict default differs from intentional post-placement leakage. |
| `area.convert` | Convert spline/paint | Bounded command | No persistent default | Authoring / T27 | Reports resolution, threshold, and approximation. |

## Paint authoring

**Owner:** Paint Set / Gesture. **Specification:** [09 — implementation chapter](09_PAINTING_AUTHORING_UNDO_AND_INCREMENTAL_UPDATES.md). **Basis:** R0 §3.3; S21.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `paint.mode` | Paint semantics | Region / DensityField | Region | Field reconstruction / T26 | Coverage and density are different outputs. |
| `paint.backend` | Paint coordinate backend | Projected / SurfaceAttached | Projected | Authoring/bindings / T29 | No silent deformation-following claim for projected paint. |
| `paint.receiver_mode` | Brush receiver scope | FrontSelected / ThroughSelected | FrontSelected | Hit/dab routing / H02 | Stacked surfaces remain distinct by default. |
| `paint.frame_binding` | Projected frame binding | World / Setup / Receiver | Receiver | Coordinates / T29 | Receiver-local paint follows rigid transforms. |
| `paint.radius` | Brush radius | Positive length | 0.5 m | Dab construction / H01 | Use effective SDK radius once. |
| `paint.strength` | Brush strength | Real 0..1 | 1 | Tile edits / T26 | SDK effective strength already includes configured pressure. |
| `paint.hardness` | Brush hardness | Real 0..1 | 0.8 | Kernel / T26 | Defines interior plateau and boundary ramp. |
| `paint.spacing` | Dab spacing fraction of diameter | Real > 0 and <= 1 | 0.15 | Resampling / T26 | Canonical dabs decouple output from raw event rate. |
| `paint.operation` | Brush operation | Add / Erase | Add | Tile edits / T26 | Default max/min composition, not implicit cumulative flow. |
| `paint.flow_mode` | Exposure mode | NonAccumulating / IntegratedFlow | NonAccumulating | Tile edits / T26 | Flow is a separately versioned operation. |
| `paint.pressure_radius` | Pressure controls radius | Boolean | True in host brush setup | Input normalization / H01 | Do not multiply callback radius by pressure again. |
| `paint.pressure_strength` | Pressure controls strength | Boolean | False in host brush setup | Input normalization / H01 | Effective callback value is authoritative. |
| `paint.cell_size` | Canonical projected cell size | Positive length | 0.02 m | Authoring representation / T27 | Changing it is explicit resampling with Undo. |
| `paint.tile_edge` | Storage tile edge samples | Positive supported integer | 256 | Storage only / T27 | Changing partitioning must preserve canonical sample coordinates. |
| `paint.quantization` | Coverage precision | Versioned unsigned 16-bit | U16 | Authoring representation / T26 | Fixed rounding/complement rule required. |
| `paint.threshold` | Region extraction threshold | Real strictly between 0 and 1 | 0.5 | Contours / T27 | Not automatically applied to DensityField mode. |
| `paint.contour_policy` | Contour reconstruction | Versioned deterministic marching squares | CyrusContourV1 | Contours / T27 | Saddles and tile-border ties are specified. |
| `paint.overlay` | Show current coverage overlay | Boolean | True | Viewport only / T31 | Independent of accepted plants. |
| `paint.falloff_preview` | Show response overlay | Boolean | True | Viewport only / T31 | Displays authored field, not inferred plant density. |
| `paint.stroke_policy` | Population update during stroke | CoalescedLive / EndOnly | CoalescedLive | Scheduling / T37 | Obsolete jobs are cancelled or discarded. |
| `paint.surface_metric` | Surface brush distance | GraphDistance / TangentDiscApprox | GraphDistance | Surface neighborhood / T29 | Graph distance is not claimed exact continuous geodesic. |
| `paint.atlas_resolution` | Surface micro-grid resolution | Positive target length | 0.02 m at reference mesh | Authoring/bindings / T29 | Deformation may stretch effective texel size. |
| `paint.topology_policy` | Changed-topology response | InactiveAndReport / ExplicitFrozen | InactiveAndReport | Bindings / T29 | No silent nearest-surface repair. |
| `paint.to_spline` | Extract spline contour | Command with threshold/tolerance | No persistent default | Conversion / T27 | Can be lossy and must preserve/report holes. |
| `paint.history` | Historic stroke editing | CurrentTiles / SeparateEditablePath | CurrentTiles | Authoring contract / T28 | Ordinary queries do not replay arbitrary history. |

## Falloffs and field combination

**Owner:** Area response / Field. **Specification:** [06 — implementation chapter](06_FIELDS_MAPS_CURVES_AND_FALLOFFS.md). **Basis:** R0 §3.6.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `falloff.density_enabled` | Density falloff | Boolean | False | Eligibility / T18 | Changes survival probability, not source size. |
| `falloff.scale_enabled` | Scale falloff | Boolean | False | Transforms / T18 | Can change footprint and occupancy. |
| `falloff.include_range` | Inside inclusion range | Nonnegative length | 0.5 m | Distance/response / T18 | Zero is a hard boundary policy. |
| `falloff.exclude_range` | Outside exclusion range | Nonnegative length | 0.5 m | Distance/response / T18 | Excluded interior remains ineligible. |
| `falloff.density_curve` | Density response | Normalized curve | Linear 0 to 1 | Eligibility / T18 | Final probability is clamped to 0..1. |
| `falloff.scale_curve` | Scale response | Nonnegative curve | Linear 0 to 1 | Transforms / T18 | Output range is separate from density. |
| `falloff.invert` | Invert response value | Boolean | False | Response / T18 | Means 1-F, not reversing X coordinates. |
| `falloff.height_only` | Affect source-local height only | Boolean | False | Transforms / T18 | Local up is not necessarily world Z. |
| `field.combine` | Field combination | Multiply / Add / Min / Max / Replace | Multiply for density factors | Field evaluation / T18 | Combining area contributions remains a separate operation. |
| `field.domain` | Field coordinate domain | Declared frame/stage enum | Resolved surface position | Field sampling / T20 | No ambiguous changing meaning of current position. |

## Transform variation

**Owner:** Layer / Area / Source. **Specification:** [10 — implementation chapter](10_SOURCES_TRANSFORMS_AND_GROUPS.md). **Basis:** R0 §4.3–4.4; S08.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `transform.translate_enabled` | Random translation | Boolean | False | Transforms/final gates / T20 | Offsets can require reprojection and boundary reevaluation. |
| `transform.translation_mode` | Translation units | WorldLength / SourceRelative | WorldLength | Transforms / T20 | Percent dimensions are not interchangeable with meters. |
| `transform.translation_frame` | Translation frame | World / Surface / Path / Source | Surface | Transforms / T20 | Saved basis determines offset direction. |
| `transform.translation_min` | Minimum XYZ translation | Finite vector | 0,0,0 | Transforms / T20 | Each enabled axis has an independent channel. |
| `transform.translation_max` | Maximum XYZ translation | Finite vector >= min | 0,0,0 | Transforms / T20 | Invalid inverted intervals are rejected. |
| `transform.rotation_enabled` | Random rotation | Boolean | True | Transforms / T20 | Default variation is yaw only. |
| `transform.yaw_range` | Yaw interval | Finite angle interval | 0..360 degrees | Transforms / T20 | Rotates around declared local up. |
| `transform.pitch_range` | Pitch interval | Finite angle interval | 0..0 degrees | Transforms / T20 | No hidden tilt by default. |
| `transform.roll_range` | Roll interval | Finite angle interval | 0..0 degrees | Transforms / T20 | Euler order is saved by profile. |
| `transform.rotation_distribution` | Rotation sampling | Uniform / PDFCurve / DiscreteAtoms | Uniform | Sampling / T19 | Response curves and probability densities differ. |
| `transform.rotation_values` | Discrete orientation values | Weighted angle list | 0,90,180,270 degrees | Sampling / T19 | Active only for discrete mode. |
| `transform.scale_enabled` | Random scale | Boolean | False | Transforms/occupancy / T20 | Retain source scale when disabled. |
| `transform.scale_mode` | Scale axis relationship | Uniform / XYLinked / Independent | Uniform | Sampling / T20 | Axis linking intentionally shares sampled values. |
| `transform.scale_min` | Minimum scale | Positive scalar/vector | 1 | Transforms / T20 | Zero is not a hidden disabled state. |
| `transform.scale_max` | Maximum scale | Positive value >= min | 1 | Transforms / T20 | Final footprint follows actual scale. |
| `transform.scale_distribution` | Scale probability distribution | Uniform / PDFCurve | Uniform | Sampling / T19 | CDF is normalized and validated. |
| `transform.value_map` | Transform value map | Optional field reference | None | Transforms / T20 | Directly maps values into configured ranges. |
| `transform.probability_map` | Variation-strength map | Optional normalized field | None | Transforms / T20 | Blends from neutral to sampled variation. |
| `transform.reproject` | Reproject moved placements | Boolean | True when lateral translation enabled | Surface/final gates / T20 | Updates binding/normal, not only Z. |
| `transform.mirror` | Mirror axes | Explicit axis flags/probabilities | Off | Transforms/output / R01 | Requires handedness/normal handling. |
| `transform.seed_salts` | Property random salts | Unsigned values by channel | 0 | Selected random stages / T39 | Changing rotation salt does not alter tint. |

## Collision and spacing

**Owner:** Layer / Occupancy domain. **Specification:** [11 — implementation chapter](11_COLLISIONS_SPACING_AND_EXACT_INCREMENTAL_SOLVING.md). **Basis:** R0 §2.4.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `collision.enabled` | Collision filtering | Boolean | False | Occupancy / T22 | Enabled policy selects a subset, not physical simulation. |
| `collision.shape` | Proxy relation | Sphere3D / CircleInFrame / QualifiedFootprint | Sphere3D | Occupancy / T22 | Vertical separation differs by mode. |
| `collision.multiplier` | Global radius multiplier | Finite real >= 0 | 1 | Occupancy / T22 | Combines with source proxy and transform bound. |
| `collision.clearance` | Additional pair clearance | Nonnegative length | 0 m | Occupancy / T22 | Tangency is allowed under the default strict overlap test. |
| `collision.pairs` | Source-pair collision rules | Symmetric matrix | All pairs enabled | Occupancy / T23 | Directed ecological exclusion is a different feature. |
| `collision.priority` | User priority tiers | Integer per source/layer | 0 | Occupancy / T23 | Stable key breaks ties independently of worker order. |
| `collision.solver` | Solver policy | DeterministicGreedy / QualifiedAlternative | DeterministicGreedy | Occupancy / T21 | No maximum-packing guarantee. |
| `collision.incremental` | Incremental method | Full / ExactUnionClosure | Full until qualified | Occupancy / T23 | Never fixed-halo approximation by default. |
| `collision.closure_limit` | Closure fallback threshold | Fraction 0..1 | 0.3 | Performance only / T23 | Exceeding it runs full solve without changing result. |
| `collision.grid_cell` | Broad-phase cell size | Auto or positive length | Auto | Performance only / T22 | Must not affect accepted IDs. |
| `collision.motion_clearance` | Use motion-envelope proxy | Boolean | False | Occupancy / T33 | More conservative and more expensive than static placement. |
| `spacing.relaxation` | Relaxation solver | Off / Explicit iterative mode | Off | Separate solver / T23 | Requires deterministic steps, bounds, and termination. |
| `spacing.iteration_cap` | Relaxation iteration cap | Positive integer | 20 when enabled | Separate solver / T40 | Bounded behavior, not an infinite retry loop. |

## Manual editing

**Owner:** Edit Set / Selected instance. **Specification:** [12 — implementation chapter](12_MANUAL_EDITING_AND_CS_EDIT.md). **Basis:** R0 §4.6; S09.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `edit.policy` | Override constraint policy | Constrained / Pinned | Constrained | Edits/final gates / T24 | Pinning explicitly bypasses procedural coverage/density. |
| `edit.transform_mode` | Stored transform space | AbsoluteWorld / ReceiverLocal / LocalDelta | LocalDelta | Edits / T24 | Different response to upstream changes. |
| `edit.source` | Source replacement override | Optional SourceUUID | None | Edits/occupancy / T24 | Larger source can change neighbors. |
| `edit.delete` | Delete selected generated items | Tombstone command | No persistent default | Eligibility/occupancy / T25 | Does not erase paint or source assets. |
| `edit.place` | Place independent manual item | Command with source/binding | No persistent default | Manual population / T24 | Exists independently of generator enumeration. |
| `edit.pin` | Pin selected items | Command | No persistent default | Priority/occupancy / T24 | Conflicting pins remain with diagnostics. |
| `edit.pin_exclusions` | Pins respect hard exclusions | Boolean | False | Final gates / T24 | Stricter optional policy, never silently enabled. |
| `edit.surface_link` | Follow receiver binding | Boolean | True for attached items | Binding/transform / T29 | Topology changes require explicit repair policy. |
| `edit.reproject` | Place or repair on surface | Bounded command | No persistent default | Binding / T29 | Different from persistent surface-link setting. |
| `edit.randomize` | Reseed selected properties | Command with channel mask | No persistent default | Selected attributes / T39 | Does not reseed unrelated channels. |
| `edit.store_transform` | Store resolved transform | Command with explicit space | No persistent default | Authoring / T24 | Freezes selected procedural components intentionally. |
| `edit.select_scope` | Selection population | Displayed / AllAccepted | Displayed | Picking / H07 | AllAccepted route can use CPU spatial queries. |
| `edit.orphan_policy` | Orphaned override handling | KeepInactive / ExplicitConvert / DeleteCommand | KeepInactive | Persistence / T25 | No automatic nearest-candidate reassignment. |
| `edit.attach` | Attach populations | Command with remapping policy | No persistent default | Authoring/references / T36 | Source and ID remapping must be atomic. |
| `edit.detach` | Detach selected items | ManualLayer / ProceduralSubset / MaxBake | ManualLayer | Authoring/export / T36 | Different editability and memory contracts. |

## Viewport and picking

**Owner:** Setup / View. **Specification:** [13 — implementation chapter](13_VIEWPORT_PICKING_CAMERA_AND_LOD.md). **Basis:** R0 §5.1; S10,S24.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `viewport.mode` | Display representation | Points / Arrows / Bounds / PointCloud / Mesh | PointCloud | Viewport only / T31 | Does not change final population. |
| `viewport.percentage` | Preview population fraction | Real 0..1 | 0.1 | Viewport subset / T31 | Nested stable subsets when increased. |
| `viewport.item_budget` | Displayed instance budget | Nonnegative integer | 100000 | Viewport subset / T31 | Selected-item exceptions are reported. |
| `viewport.point_budget` | Total point budget | Nonnegative integer | 250000 | Point representation / H07 | Separate from instance count; proposed Cyrus starting value. |
| `viewport.selected_detail` | Boost selected detail | Boolean | True | Viewport only / H07 | Selection does not mutate source or recipe. |
| `viewport.show_bounds` | Show source/proxy bounds | Boolean | False | Viewport only / H07 | Useful for occupancy debugging. |
| `viewport.show_fields` | Show field overlay | Boolean | False | Viewport only / T31 | Can display coverage even when plants are rejected. |
| `viewport.show_rejected` | Show rejected candidate diagnostics | Boolean | False | Debug output / T22 | Bounded sampling avoids huge debug buffers. |
| `viewport.pick_mode` | Pick accuracy | Proxy / QualifiedMesh / GPUId | Proxy | Picking / H07 | Accuracy/capability is explicit. |
| `viewport.cull` | Per-view culling | Boolean | True | Representation only / T31 | Not final-render existence culling. |
| `viewport.retained` | Retain reusable display resources | Boolean | True | Resource policy / H07 | Resource lifetime follows host graphics contract. |
| `viewport.refresh` | Refresh display representation | Command | No persistent default | Viewport only / H07 | Does not force placement rebuilding unless inputs changed. |

## Camera and LOD

**Owner:** Output policy / Source LOD. **Specification:** [13 — implementation chapter](13_VIEWPORT_PICKING_CAMERA_AND_LOD.md). **Basis:** R0 §5.3–5.4; S11–S12.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `camera.binding` | Output camera | Viewport / Explicit camera | Explicit render camera at render | Output / T31 | Population dependencies are added only when enabled. |
| `camera.approx_cull` | Approximate render-camera culling | Boolean | False | Output existence / R06 | Off-camera secondary-ray effects can be lost. |
| `camera.expand` | Frustum expansion | Nonnegative fraction | 0.2 when culling enabled | Output / R06 | Margin is not proof of complete shadow/reflection safety. |
| `camera.back_offset` | Backward camera margin | Nonnegative length | 0 m | Output / R06 | Separate from near/far clipping. |
| `camera.far_limit` | Optional far cull distance | Positive length or disabled | Disabled | Output / R06 | A visibility approximation, not automatic quality preservation. |
| `camera.distance_density` | Camera-distance density | Optional normalized curve/range | Disabled | Eligibility/occupancy / T31 | Can change accepted population and collision winners. |
| `camera.distance_scale` | Camera-distance scale | Optional nonnegative curve/range | Disabled | Transforms/occupancy / T31 | Not interchangeable with LOD. |
| `camera.look_at` | Face camera orientation | Off / Full / UpAxisOnly | Off | Transforms or output policy / T32 | Stage must be declared because footprints may change. |
| `camera.shot_envelope` | Camera shot envelope | Off / SampledApprox / QualifiedBound | Off | Output preparation / R06 | Sampled frusta are not a continuous-motion proof. |
| `lod.metric` | LOD switch metric | Distance / ScreenSize | Distance | Representation / T32 | Orthographic and perspective projection differ. |
| `lod.thresholds` | LOD thresholds | Ordered positive values | User-supplied | Representation / T32 | Each level supplies an actual source alternative. |
| `lod.variation` | Threshold variation | Real 0..1 | 0 | Representation / T32 | Stable per-instance variation avoids simultaneous switches. |
| `lod.materials` | Per-LOD material override | Optional per-level references | Inherit source | Material/output / R03 | Material changes do not create a new logical instance. |
| `lod.hysteresis` | Stateful preview hysteresis | Boolean | False | Preview only / T32 | Final default remains stateless/reproducible. |
| `lod.crossfade` | Representation crossfade | Off / QualifiedAdapter | Off | Output / R03 | Can require two representations and shader support. |

## Materials, edge masking, and animation

**Owner:** Layer / Source / Output. **Specification:** [15 — implementation chapter](15_MATERIALS_EDGE_TRIMMING_AND_ANIMATION.md). **Basis:** R0 §§5.5–5.6; S13–S16.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `material.tint_enabled` | Instance tint | Boolean | False | Presentation / R03 | Requires a qualified material/user-data path. |
| `material.tint_color` | Tint color or field | Working-space color/field | White | Presentation / R03 | Color space and blend operation are saved. |
| `material.tint_strength` | Tint strength | Real 0..1 | 0 | Presentation / R03 | Separate from source material assignment. |
| `material.element_variation` | Per-element variation | Boolean | False | Source decomposition/shading / T34 | Element identity differs from face or whole instance. |
| `material.spatial_field` | Broad spatial appearance field | Optional color field | None | Presentation / R03 | Creates coherent variation across multiple instances. |
| `material.hsv` | Hue/saturation/value adjustments | Declared bounded adjustment vector | Neutral | Presentation / R03 | Not equivalent to arbitrary RGB multiplication. |
| `material.variant` | Material variant selection | Weighted variant collection | Original only | Output / R03 | May change prototype/material structure. |
| `material.edge_mode` | Element boundary route | Off / QualifiedNative / QualifiedOpacity | Off | Element/output / R04 | Not arbitrary triangle slicing. |
| `material.optimizer` | Optimize selected material graphs | Previewable command | No persistent default | Host transaction / R04 | Idempotent and preserves original opacity links. |
| `material.shared_policy` | Modify shared materials | CloneForSetup / ModifyShared | CloneForSetup | Host material edits / R03 | Avoids affecting unrelated scene objects silently. |
| `animation.mode` | Animation sample mode | Static / Follow / Offset / MapOffset / MapFrame | Static | Source samples / T33 | Phase variation is not wind generation. |
| `animation.static_time` | Static source time | Explicit tick/frame/seconds value | Creation scene time | Source samples / T33 | Units are stored with the value. |
| `animation.offsets` | Discrete offset samples | Time-value list | 0 only | Source samples / T33 | Stable per-instance sample assignment. |
| `animation.map` | Animation selection field | Optional scalar field | None | Source samples / T33 | Offset and absolute frame mapping are different. |
| `animation.range` | Source playback interval | Ordered time values | Source/scene configured range | Source samples / T33 | No implicit unit conversion when frame rate changes. |
| `animation.wrap` | Playback outside interval | Clamp / Loop | Clamp | Time mapping / T33 | Loop uses defined half-open interval and negative modulo. |
| `animation.cache_budget` | Source-sample memory budget | Positive bytes | 512 MiB within global budget | Cache policy / T38 | Active renderer samples are pinned against eviction. |
| `animation.motion_blur` | Motion samples | Off / QualifiedShutterSampling | Off | Renderer samples / R05 | Requires adapter capability, not just viewport animation. |
| `animation.topology` | Animated-topology policy | RejectIncompatible / QualifiedPerSample | RejectIncompatible | Elements/output / T34 | Do not reuse invalid first-frame element indices. |

## Effects, collections, presets, and automation

**Owner:** Setup / Definition / Command layer. **Specification:** [16 — implementation chapter](16_EFFECTS_AND_PROCEDURAL_EXTENSIBILITY.md). **Basis:** R0 §§6–7.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `effect.enabled` | Effect enabled | Boolean | True | Declared stages / T30 | Saved parameters survive disabling. |
| `effect.stage` | Effect stage | Eligibility / Placement / Presentation / Output | Declared by definition | Plan validation / T30 | Illegal write stages are rejected. |
| `effect.parameters` | Exposed parameter values | Typed schema | Definition defaults | Declared stages / T30 | Types, units, limits, and references are validated. |
| `effect.dependencies` | Read/write dependency manifest | Typed read-only compiled data | Derived from definition | Scheduling / T30 | Unbounded influence cannot claim local invalidation. |
| `effect.query_budget` | Query/instruction budget | Positive integer bounds | Definition policy | Safety / T30 | Unbounded loops/arbitrary host execution are not allowed. |
| `effect.debug_candidate` | Debug candidate filter | Optional canonical ID | None | Diagnostics / T30 | Avoids printing millions of records. |
| `collection.role` | Collection role | Sources / Compound / Receivers / Regions / References | Explicit at creation | Input resolution / T35 | Role determines one-choice versus all-members semantics. |
| `collection.members` | Explicit members | UUID references | Empty | Input resolution / T35 | Canonical evaluation order is distinct from display order. |
| `collection.layer_query` | Dynamic scene-layer membership | Optional stable query | Disabled | Input dependencies / T35 | Membership changes invalidate dependent snapshots. |
| `collection.nested` | Nested collection links | UUID references | Empty | Dependency validation / T35 | Cycles rejected before evaluation. |
| `preset.kind` | Preset scope | Settings / Sources / CompleteRecipe | Settings | Persistence / T36 | External scene references are not guessed on import. |
| `preset.embed_assets` | Embed permitted assets | Boolean | False | Asset packaging / R08 | Rights and package-size limits must be respected. |
| `preset.missing_assets` | Missing-asset resolution | Explicit mappings/report | Report unresolved | Input/output / T40 | Never silently substitute geometry. |
| `automation.expected_revision` | Optimistic concurrency revision | Optional unsigned token | Required for mutating clients | Command validation / T37 | Stale writes return a conflict. |
| `automation.idempotency` | Command idempotency key | Unique string/UUID | Required for retryable writes | Command validation / T36 | Retries do not create duplicate layers/strokes. |
| `automation.dry_run` | Preview changes | Boolean per command | True for bulk destructive previews | Command validation / T40 | Returns scope/cost before authorized execution. |
| `automation.batch` | Grouped authoring transaction | Command collection | One transaction per requested gesture | Undo / H03 | Same core semantics as UI and CS Edit. |

## Diagnostics, export, and companion scope

**Owner:** Setup / Utility. **Specification:** [20 — implementation chapter](20_VERIFICATION_FIXTURES_AND_BENCHMARKS.md). **Basis:** R0 §§7,11; chapter 26 extensions.

| Parameter / command ID | Artist control | Type and valid domain | Proposed default | Invalidation / test | Meaning and important interaction |
|---|---|---|---|---|---|
| `diag.statistics` | Stage statistics | Read-only counters/timers | Enabled lightweight counters | Diagnostics / T38 | Counts include first rejection reasons and result revision. |
| `diag.explain` | Explain candidate/rebuild | Read-only command | On demand | Diagnostics / T22 | Returns provenance, fields, and invalidation reasons. |
| `diag.reference_compare` | Compare full and optimized result | Development command | Off in normal use | Verification / T23 | Reports canonical differences, not just total count. |
| `diag.export_fixture` | Export reproducible fixture | Command | Explicit destination | Verification / T36 | Includes version/profile/input fingerprints. |
| `export.mode` | Bake/export route | MaxInstances / Mesh / ManualLayer / Manifest | Manifest | Output / T40 | Different editability and memory consequences. |
| `export.limit` | Bake object/face safety limits | Positive count limits | Required per route | Output guard / T40 | No unlimited silent flattening. |
| `manager.scope` | Scene-lister filters | Setup/layer/source/dirty filters | All Cyrus setups | Management / H05 | Uses cached revision-labeled statistics. |
| `growth.enabled` | Companion growth system | Separate module capability | Unavailable until qualified | Companion fixtures | Not implied by ordinary scattering support. |
| `growth.guides` | Growth guide curves | Curve references | Unbound | Growth preparation | Separate branch graph and termination contract. |
| `growth.step` | Growth step length | Positive length | 0.05 m proposed extension | Growth solver | Approximation/quality setting with bounded work. |
| `growth.max_branches` | Growth branch budget | Positive integer | 1000 proposed extension | Growth solver | Prevents unbounded procedural expansion. |
| `wind.enabled` | Generated wind deformation | Separate qualified source module | Off | Animation/source geometry | Not the same as random source-frame offsets. |
| `billboard.facing` | Billboard orientation | Fixed / Camera / UpAxisCamera | UpAxisCamera | Representation | Legacy shadow-plane parity remains a separate target. |

## Coverage limits and completion tracking

This inventory operationalizes the major research scope and includes explicit Cyrus extensions. It does not establish every historical ForestPack control name, undocumented default, or vendor-specific integration. Maintain a separate compatibility column during implementation: Not started / Core tested / Host tested / Renderer qualified / Documented / Released. Record exact versions for the latter stages.

The machine-readable companion `examples/control_catalog.json` contains the same records for planning and validation. It is an initial specification dataset, not a ready-made Max UI generator or production schema implementation.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S01]: https://docs.itoosoft.com/forestpack/forest-plugin/areas
[S02]: https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode
[S03]: https://docs.itoosoft.com/forestpack/forest-plugin/surfaces
[S04]: https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode
[S06]: https://docs.itoosoft.com/forestpack/forest-plugin/distribution/particle-flow-mode
[S07]: https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry
[S08]: https://docs.itoosoft.com/forestpack/forest-plugin/transform
[S09]: https://docs.itoosoft.com/forestpack/forest-plugin/item-editor
[S10]: https://docs.itoosoft.com/forestpack/forest-plugin/display
[S11]: https://docs.itoosoft.com/forestpack/forest-plugin/camera
[S12]: https://docs.itoosoft.com/forestpack/forest-plugin/forest-lod
[S13]: https://docs.itoosoft.com/forestpack/forest-plugin/material
[S16]: https://docs.itoosoft.com/forestpack/forest-plugin/animation
[S21]: https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_i_painter_canvas_interface___v5.html
[S24]: https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_max_s_d_k_1_1_graphics_1_1_i_object_display2.html
