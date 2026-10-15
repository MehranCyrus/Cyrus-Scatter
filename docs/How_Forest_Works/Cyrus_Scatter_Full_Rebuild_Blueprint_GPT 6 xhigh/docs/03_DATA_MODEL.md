# 03 — Canonical data model and identity contracts

> **[CYRUS-DESIGN]** Everything in this chapter is an independent schema recommendation. Do not serialize raw C++ object memory, raw 3ds Max pointer values or ephemeral cache indices. The current Cyrus file format has not been audited.

## 1. Divide data into four ownership classes

| Class | Examples | Authoritative? | Stored in .max/project? |
|---|---|---|---|
| Authoring model | Sources, regions, generator configs, brush strokes, Effects, edits | Yes | Yes |
| Scene bindings | External node identities, receiver references, material/map handles | Yes, with resolver | Yes, portable descriptor |
| Evaluation state | Candidates, rejected items, occupancy, surface interpolation | No | Optional validated cache only |
| Presentation state | Point cloud, GPU objects, selected preview density, renderer handles | No | No; rebuildable |

A key rule: the rendering adapter must never mutate authoring data while exporting a frame.

## 2. Proposed persistent hierarchy

```text
CyrusDocument
  docVersion, sceneGuid, settings, compatibility
  SourceLibrary[]                source UUIDs, material/geometry bindings
  InputCollections[]             linked scene node roles and filters
  ScatterObjects[]
    scatterUUID, enabled, name, seed, userSettings
    GeneratorSpec                kind-specific parameters
    ReceiverBindings[]           surface queries, channels, revisions
    AreaStack[]                  ordered operations with source provenance
    VariationPipeline           select / transform / color / animation
    ConstraintConfig            collision / boundary policy
    EffectStack[]                declared read/write signatures
    ManualLayer                 pins, overrides, added instances
    DisplayConfig / RenderConfig
  UserCurves / FieldAssets / SharedAreaDefinitions
  OrphanReferenceRegistry, migrationMetadata
```

Each persisted entity has `UUID`, `schemaVersion`, `displayName`, `enabled`, and a revision or content hash. Visual ordering is explicit, not accidentally inferred from storage index.

## 3. Identity model: four different IDs

Do not overload one ID for everything.

1. **Definition ID:** source, area, scatter, generator, layer, Effect, curve. Create stable UUID once; survive renames and list reordering.
2. **Candidate ID:** identity of a potential placement before source selection and collision. Derived deterministically from generator-specific anchors.
3. **Instance ID:** normally candidate ID + instance namespace; unique among manual and procedural items. Stays unchanged when replacing only source/transform.
4. **Attachment ID:** receiver identity + parameterization anchor (face+barycentric, UV+island+channel, reference object, path segment+arc parameter), with restoration policies.

Example identity generator:

```cpp
CandidateId MakeGridCandidateId(
    Uuid scatterId, Uuid generatorId,
    Int2 signedTileCoordinates,
    uint32_t localSampleOrdinal,
    uint32_t generationAlgorithmVersion);

CandidateId MakeReferenceCandidateId(
    Uuid scatterId, StableNodeId node,
    StableElementKey faceOrPivot,
    uint32_t sampleOrdinal);
```

### What is a stable anchor?

- **Image/map tiling:** tile coordinates and an invariant sample ordinal within the tile; map scale/rotation may change positions but can retain the same anchors by policy. Changes to image resolution or generator algorithm require an explicit remap/reset policy.
- **Path:** path UUID + contour/sub-spline identity + distance-index or knot GUID, depending on sampling mode. Changing spacing may change index identity; retain matchable manual overrides by nearest arclength only under explicit user-approved remapping.
- **Reference:** persistent scene-node identity + pivot/face attribute; do not derive from world position. Topology-changing face edits invalidate face-index anchors unless a correspondence algorithm succeeds.
- **Particle:** particle identity provided by source system when stable; otherwise time+emitter+index is **not** guaranteed stable across simulation edits and must be flagged.
- **Manual add:** random UUID created once and persisted. Never reuse a deleted item ID.

### Identity preservation policy matrix

| Operation | Candidate identity | Manual override | Expected result |
|---|---|---|---|
| Change tint | Retain | Retain | Only color changes |
| Change source weight | Retain | Retain | Source may change, placement identity persists |
| Increase density (fixed candidate reservoir) | Retain candidates | Retain | Additional candidates accepted where possible |
| Change global seed | IDs may remain, random channels change | Explicit keep/discard policy | Intentional variation |
| Move receiver vertices, unchanged topology | Retain face anchors | Re-project by barycentric coordinates | Objects follow surface |
| Change receiver topology | Best-effort mapping | Mark orphan on failure | Do not silently relocate |
| Change path spacing | Depends on anchor semantics | Explicit remap policy | May require warning |
| Delete source geometry node | Retain source UUID | Retain item metadata | Display missing-source state |
| Reorder area list | Candidate provenance retained; eligibility may change | Keep, orphan or suppress under configured policy | Re-evaluate impacted areas |

**Test rule:** stable IDs alone do not guarantee spatial stability. Greedy collision resolution and changes to the accepted set may change neighbor acceptance; record both candidate and final-instance correspondence.

## 4. Strongly typed spatial domains

Define coordinate-domain types rather than passing generic `Vec3` everywhere:

- `WorldPoint` in 3ds Max system units after normalizing coordinate handedness and transforms.
- `ScatterLocalPoint` in the scatter node's local reference frame.
- `ReceiverLocalPoint` in a particular evaluated mesh node's space.
- `UVPoint` plus map channel and UV island/face context.
- `PathCoordinate` = path/sub-spline ID + arclength in system units.
- `PixelCoordinate` = tile ID + integer raster coordinate.

Likewise use `Radians`, `Degrees`, `SceneUnits`, `Normalized01`, and `Percent`. Persist canonical physical values, not slider display text. Preserve nonuniform scale and mirrored transforms; explicitly state whether shear is supported, rejected, or baked.

## 5. Suggested source records

```cpp
struct SourceDefinition {
    Uuid id;
    SourceKind kind;                 // mesh, proxy, group, billboard, light, empty
    SceneReference sourceReference; // persistent scene binding, not INode*
    SourceAssetId externalAsset;
    float relativeWeight;
    Color4 colorId;
    Percent collisionRadius;
    Vec3 sourcePivotOffset;
    SourceDimensions dimensions;
    MaterialBinding material;
    bool allowMirror;
    GroupPolicy groupPolicy;
    LODDefinition optionalLods;
};
```

A disabled source used for intentional gaps should be an explicit `Empty` outcome or a source state that retains its weight. A UI disable-to-exclude-selection command should be distinct. Source `name` is display metadata, not an immutable identity; reference-name matching is a separate operator.

## 6. Candidate and intermediate records

```cpp
struct PlacementCandidate {
    CandidateId id;
    Uuid scatterId;
    Uuid generatorId;
    Uuid originAreaId;
    uint64_t stableRandomKey;
    GeneratorParametricLocation generatorLocation;
    Vec3 initialPosition;
    Vec3 optionalOrientationHint;
    SurfaceBinding optionalSurfaceBinding;
    float baseDensityWeight;
};

struct SurfaceSample {
    bool valid;
    StableNodeId receiver;
    uint32_t faceIndex;  // ephemeral unless topology is stable
    Vec3 barycentric;
    Vec2 uv;
    Vec3 worldPosition;
    Vec3 worldNormal;
    float slopeRadians;
    float worldAltitude;
    uint32_t materialId;
};

struct AcceptedInstance {
    InstanceId id;
    CandidateId candidate;
    SourceId source;
    CompactTransform transform;
    SurfaceBinding attachment;
    AttributeIndex attributes;
    uint32_t flags;
};
```

Keep separate rejected-candidate diagnostics by category instead of using "missing instance" as the only evidence of rejection. Record `AREA`, `DENSITY`, `SURFACE_MISS`, `SLOPE`, `ALTITUDE`, `COLLISION`, `BOUNDARY`, `SOURCE_EMPTY`, `EFFECT_HIDDEN`, `CAP_EXCEEDED` as traceable reasons.

## 7. The typed field contract

A field is not merely a bitmap. It is a value evaluator with coordinate, domain, sampling and dependency semantics.

```cpp
enum class FieldValueType { Scalar, Vec2, Vec3, Color, Bool, Category };

enum class FieldSpace { World, ScatterLocal, ReceiverUV, GeneratorUV, Path, ReceiverLocal };

struct FieldEvaluationContext {
    CandidateId id;
    Vec3 worldPosition;
    Vec2 surfaceUV;
    SurfaceSample surface;
    PathCoordinate optionalPath;
    TimeValueCanonical time;
    RandomContext random;
};

struct FieldResult<T> {
    bool valid;
    T value;
    FieldError error;
};
```

Each field exposes `Dependencies()` and optionally a conservative `AffectedBounds(change)`. Field types: constant, bitmap, host Texmap snapshot/evaluator, procedural noise, signed distance, curve remap, altitude, slope, paint tile, object projected mask, scatter occupancy, object distance, random, composite.

Important: Autodesk `Texmap` evaluation may depend on host-managed state; do not assume arbitrary material maps are safe to call from worker threads. Support host-time prebaking or main-thread sampled field adapters and declare resolution/error limitations.

## 8. Manual overrides and conflict states

```cpp
struct InstanceOverride {
    InstanceId target;
    Optional<SourceId> sourceReplacement;
    Optional<Mat4> absoluteTransform;
    Optional<Mat4> relativeTransform;
    bool suppressed;
    bool pinned;
    Optional<SurfaceBinding> reboundTo;
    OverrideOrphanPolicy orphanPolicy;
};
```

Distinguish `suppressed` from `not accepted due to constraints`. Manual Delete is an authored tombstone; density rejection is derived. Explicit `ManualInstance` records are not candidates, though they may choose to participate in occupancy constraints. Orphan overrides persist invisibly with a warning or become explicit manual instances under policy.

## 9. Efficient memory representation

Avoid `std::vector<Instance>` where every instance owns many heap allocations. Use tightly packed **Structure of Arrays** for hot passes: `id[]`, `position[]`, `rotation[]`, `scale[]`, `sourceId[]`, `receiverId[]`, `attributeIndex[]`. Immutable user-defined records can remain richer objects. Target 32/64-bit ID indices appropriately; never silently overflow with millions of candidates. Compress source/area IDs through per-snapshot lookup tables while preserving full UUIDs in authoring data.

Evaluate float precision over very large 3ds Max coordinates; use double precision in world-space geometry and spatial indexing where necessary, with camera-relative floats in GPU preview. Handle 3ds Max system unit conversion once at the host boundary.

## 10. Version and migration

Every serialized object must support: schema version, canonical units, deterministic default expansion, migration test, unknown-field preservation policy, reference loss and forward-version warning. See `20_SERIALIZATION_AND_ASSETS.md`.
