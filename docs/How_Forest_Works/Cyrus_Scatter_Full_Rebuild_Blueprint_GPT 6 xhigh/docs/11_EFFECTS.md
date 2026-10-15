# 11 — Extensible Effects engine, attribute API and safe evaluation

**[FP-DOC]** ForestPack Effects use mathematical expressions and expose readable/writable attributes plus numeric/object/controller/texture/curve parameters. Examples include stepped rotation, boundary look-at, lean, tint, repulsion and displacement. [Effects](https://docs.itoosoft.com/forestpack/forest-plugin/effects) · [Syntax](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/effects-syntax) · [Attributes](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/attributes) · [Functions](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/functions).

## 1. Two-stage implementation instead of starting with a complete language

**Stage A:** typed built-in modifiers (position, look-at, random rotation, tint, distance-to-spline, scale by slope) using core field services. **Stage B:** artist-facing expression engine exposing the same typed operations. This prevents a large scripting language from blocking core scattering performance and reliability.

## 2. What an Effect reads and writes

Typical read-only inputs: candidate/instance ID, original placement, source, surface normal/slope, UV, nearest include/exclude distances, path tangent/coordinate, linked scene-object transform, selected material/tint fields, camera context, particle metadata and time.

Possible outputs: position, rotation, scale, source ID, visibility, tint, animation sample, custom attributes. Some commercial attributes are writable, some read-only. Define a Cyrus-compatible attribute schema from scratch rather than assuming unrestricted write to every host object property.

## 3. Type system

Data types: `bool`, `int`, `float`, `double`, `vec2`, `vec3`, `color`, `quat`, `mat4`, `sceneUnit`, `angle`, source/area UUID, and optional values/errors. Require explicit angle unit conversions and distinguish positions from vectors. Reject unsafe implicit casts and division by zero or NaNs with predictable error behavior.

## 4. Effect declaration

```cpp
struct EffectDescriptor {
    Uuid effectId;
    String displayName;
    EvaluationStage stage;           // PreConstraint | PostConstraint | RenderOnly
    AttributeReadWriteSet access;
    SceneDependencySet dependencies; // receivers, curves, nodes, fields, time, camera
    InfluenceBound bounds;           // Finite(radius) | Global | Unknown
    bool deterministic;
    std::vector<UiParameterSchema> exposedParameters;
};
```

A tint-only Effect should report `WRITE_TINT`; changing its parameters invalidates shading results but not occupancy. Position/scale/source changes may require constraint reevaluation. Effects that depend on camera/time are declared so navigation/frame change propagates correctly.

## 5. Execution stages and rules

**Pre-constraint Effects** may change placement/source/transform before final collision/boundary. **Post-constraint Effects** may change tint/attributes safely, but positional writes must either trigger another constraint pass or be forbidden. **Render-only Effects** can change shader attributes/LOD without changing placement.

If a procedural modifier can read a property that earlier Effects write, preserve explicit ordering within the Effect stack. Cycles among computed fields are rejected unless the user chooses a finite, deterministic iteration policy.

## 6. Proposed expression pipeline

```text
Text editor
  -> tokenizer + parser
  -> typed AST
  -> semantic validation
  -> dependency/read-write extraction
  -> constant folding / bounded bytecode
  -> per-instance/vectorized evaluator
```

Do not execute arbitrary native user code or unrestricted host/MAXScript from worker threads. The expression VM should have whitelisted pure functions, bounded computational cost per item, no unbounded loops, no disk/network/system access, and clear diagnostics. Host scene-object parameters are captured as safe scalar/transform snapshots first.

For large populations, compile once per Effect revision; evaluate in contiguous batches with SIMD-friendly field operations where useful. Cache expensive spatial-query results in the item context and share between Effects.

## 7. Built-in functions and fields

Implement in this approximate priority:

| Function family | Examples | Required service |
|---|---|---|
| Math | clamp, lerp, smoothstep, min/max, dot/cross, atan2, noise | Numeric VM |
| Random | keyedRandom01, keyedRandomInt | Stable RNG |
| Spline | distanceToSpline, nearestPoint, tangentAtPath, insideRegion | Curve BVH/arc table |
| Surface | hitPosition, normal, altitude, slope, sampleMaterialId | Surface cache |
| Texture | sampleField, sampleColorMap | Field sampler |
| Curves | evaluateCurve, distributionSample | LUT/CDF evaluators |
| Object | worldPosition, transform, bounds | Immutable scene snapshot |
| Scatter | distanceToNearestItem, sourceWeight, occupancy mask | Spatial index, dependency graph |
| Camera | distanceToCamera, viewDirection, screenSize | Camera evaluator |

Use familiar names but don't claim exact Forest expression compatibility unless deliberately implemented and tested.

## 8. Artist parameters and UI

Support: numeric spinner with min/max/default and units, object picker (persistent reference), curve editor (versioned curve), texture/field picker, boolean, enum, color, grouped parameters and labels. A parameter schema should drive UI automatically, validate values, and produce typed change events so cache invalidation can be localized.

UI should show read/write summary, invalid references, stage, cost estimate and whether Effect triggers global regeneration.

## 9. Worked Effect A — shorter grass at a path

```text
Inputs: item.position, path.signedDistance, falloffCurve, minHeight
Output: item.scale.z
Algorithm:
  d = distanceToPath(item.position)
  t = clamp(d / falloffRange, 0, 1)
  heightMultiplier = lerp(minHeight, 1.0, curve(t))
  item.scale.z *= heightMultiplier
```

If only scale changes, collisions may still change depending on whether collision radius derives from scale. Consequently `WRITE_SCALE` must invalidate occupancy when collision is enabled and effective radius changes.

## 10. Worked Effect B — repulsion from object

```text
Inputs: item.position, object.center, radius, force, surface
Outputs: item.position, item.attachment
Algorithm:
  delta = item.xy - target.xy
  direction = normalized(delta) with stable fallback at zero
  w = smootherstep(clamp((radius-length(delta))/radius,0,1))
  item.xy += direction * force * w
  item.position = surface.Reproject(item.xy) // when required
```

**[FP-DOC]** ITOOSOFT's Repulsion sample explicitly re-queries surface height after lateral movement, demonstrating that re-projection can matter. [Repulsion example](https://docs.itoosoft.com/forestpack/forest-plugin/effects/effects-examples/repulsion). Our code is independent pseudocode. Reprojection failure must be handled (hide, retain previous binding or report), not silently produce ground-zero Z.

## 11. Worked Effect C — lean away from wall

Read nearest wall-point/normal within radius; derive bounded lean angle around axis perpendicular to horizontal away-direction, respecting surface orientation and source pivot. Require stable normal fallback at corners. Output a quaternion rotation. If the source's collision envelope changes with lean, rerun constraint evaluation or use a conservative shape.

## 12. Dependency hazards

| Effect | May invalidate |
|---|---|
| Tint by object | Shading; object transform dependency |
| Change source by slope | Source bounds, collision, materials, LOD |
| Scale by distance | Collision, camera LOD thresholds, boundary size check |
| Translate away from path | Surface projection, occupancy, area boundary |
| Hide by altitude | Accepted visibility; may free collision slots depending on stage |
| Camera-facing rotation | Viewport/render presentation, possibly bounds |
| Animation sample by map | Source sample cache and render export |

Define whether visibility happens **before** or **after** occupancy. If hidden items still reserve space, that's a different visual outcome than removing them before collision.

## 13. Error behavior and instrumentation

- Compile errors shown inline with row/column and explanation.
- Missing node/curve/texture reference retains authored config, disables Effect and reports missing reference.
- Runtime numeric exception emits safe fallback and counts invalid items; configurable per-Effect disable/warning threshold.
- Per-Effect CPU time and number of modified instances available in diagnostics.
- Prevent arbitrary host recursion, cyclic scatter dependencies and hangs from unbounded scripts.

## 14. Testing strategy

Unit tests for math/types/functions; deterministic keyed random across threads; AST validation and static dependency extraction; scene-object deletion; Effects order; no uncontrolled NaNs; property test that tint-only Effect doesn't change placement; camera dependencies; save/restore compiled source; million-instance batch performance.

For parity claims, build reference scenes for each documented Forest example; validate visual/output behavior but do not attempt to extract proprietary source code.
