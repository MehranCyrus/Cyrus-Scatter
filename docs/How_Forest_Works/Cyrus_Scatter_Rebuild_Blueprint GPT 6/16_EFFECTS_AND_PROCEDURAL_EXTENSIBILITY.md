# 16 — Effects and procedural extensibility

**Status: proposed Cyrus system. Research basis: R0 §6. Official anchors: S17, S27.**

## 1. Build reusable functions before a language

An Effects system is valuable because it composes existing data: distance to a path, surface slope, species, transform, color, and time. First implement those services as typed core functions. Then expose them through an expression or node layer.

ForestPack's public Effects reference distinguishes readable attributes, writable properties, and artist-exposed parameters [S17, S27]. It does not reveal the private scheduler or require Cyrus to copy its language syntax.

## 2. Effect definition

```text
EffectDefinition
    UUID / schema / algorithm version
    display name and description
    expression AST or typed node graph
    exposed parameter schema
    declared read dependencies
    declared write attributes
    stage
    finite/global influence contract
    capability requirements
```

A saved Effect instance binds parameters and scene references to that definition. The same definition can be reused with different values without duplicating code.

## 3. Stages and write restrictions

| Effect stage | Allowed outputs |
|---|---|
| Eligibility | Density multipliers and eligibility conditions |
| Placement | Source hints, position, orientation, scale, projection requests |
| Presentation | Tint, material variants, output attributes |
| Output | Qualified output visibility or LOD adjustments |

A presentation Effect cannot move instances after collisions. A placement Effect cannot read the final collision winner set unless it belongs to a separately defined solver. Reject these combinations at compile time.

Visibility has two meanings: removal from the logical population before constraints, and output-only hiding afterward. Use distinct attributes to avoid an invisible object unexpectedly continuing to block other placements.

## 4. Type system and units

Support scalar, integer, boolean, vector, color, source/category ID, curve reference, field reference, and scene-input handle. Add unit annotations for length, angle, time, and normalized values where practical.

Disallow implicit conversion of source IDs to array offsets. Access scene geometry only through prepared handles. Effects do not receive arbitrary host pointers.

## 5. Safe execution

Compile to a bounded interpreter or typed bytecode. The initial language has no file/network access, arbitrary host scripting, unrestricted allocation, or unbounded loops. Complex operations are provided by tested native functions with declared costs and dependencies.

Impose instruction and query budgets per batch. Invalid arithmetic produces a typed diagnostic and a defined fallback/rejection policy, not NaN transforms propagating into the renderer. Limit debug printing to selected candidate IDs or sampled diagnostics.

This is also important for presets imported from outside the studio: an Effect file is data for a constrained evaluator, not permission to execute arbitrary MAXScript.

## 6. Required function library

Provide mathematical operations, remapping/clamping, curve evaluation, deterministic random channels, source selection, surface reprojection, closest curve point/tangent, region membership, finite-range distances, texture/field sampling, and coordinate conversion.

Every query specifies its coordinate domain and stage. A function reading final position cannot be evaluated against stale pre-translation coordinates. A surface reprojection returns a new binding and validity status, not only a Z value.

## 7. Example: lean away from a wall

Bind a wall-distance field and a maximum influence distance. Query nearest wall direction within that range. Compute a bounded lean angle from the distance response and rotate around a stable local axis. Keep roots at the surface anchor. This Effect changes orientation and therefore may change a non-spherical footprint, requiring downstream boundary/collision reevaluation.

A sphere-only collision proxy might remain unchanged; dependency precision should follow actual proxy requirements, not blanket assumptions.

## 8. Example: repulsion with reprojection

A placement Effect offsets the proposed point away from a target. It then requests a surface hit on the allowed receiver set. If no hit exists, the configured policy rejects the candidate or permits free placement. The new position/binding feeds final boundaries and occupancy.

This avoids a common mistake: moving XY but retaining an unrelated old surface Z/normal. R0's discussion of a public repulsion example motivates this explicit reprojection contract without revealing ForestPack internals [R0 §12].

## 9. Example: species by elevation

Read altitude in the selected frame and map it to species weights. Select the source before footprints and collision checks. A larger high-altitude species can change accepted population even when candidates remain stable.

A color-only elevation Effect belongs later and does not affect occupancy. Similar-looking controls can therefore have different invalidation costs.

## 10. Compilation and caching

The compiler resolves parameter types, scene handles, required channels, read/write stages, and dependency cycles. Cache compiled bytecode under definition/version and parameter-structure fingerprints. Numeric parameter changes can reuse bytecode while invalidating outputs.

Constant-fold pure expressions. Fuse field requests where safe. Do not optimize away a declared dependency that can change at another time sample.

## 11. UI and authoring

Generated parameter controls show type, units, range, default, and current value. Scene references use object pickers; curves and maps use appropriate editors. A read/write summary tells the artist whether an Effect may change population, placement, or only appearance.

Effect presets include a description and one minimal demonstration fixture. “Fast” or “local” labels require measured evidence and finite-support analysis.

## 12. Tests

Reject an Effect writing scale after occupancy. Verify tint-only invalidation. Test divide-by-zero, missing references, excessive query budgets, cycle creation, world/local coordinate conversion, deterministic randomness, and parameter animation. Compare interpreted and optimized evaluation on the same canonical candidates.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S17]: https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/attributes
[S27]: https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/effects-syntax
