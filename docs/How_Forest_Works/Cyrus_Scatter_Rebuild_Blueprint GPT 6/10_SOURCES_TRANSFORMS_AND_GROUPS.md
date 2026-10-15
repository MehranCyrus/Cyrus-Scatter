# 10 — Sources, transforms, probability controls, and groups

**Status: proposed Cyrus implementation. Research basis: R0 §4. Official anchors: S07–S08.**

## 1. Source entries are persistent assets, not just node pointers

A source entry contains UUID, display name, source-provider reference, prototype revision, probability, selection state, category/Color ID, pivot policy, source-local transform, material policy, collision proxy, optional LOD set, and animation settings.

Source providers can represent a Max mesh snapshot, a compound arrangement, or a qualified renderer procedural/proxy. A proxy without CPU geometry may still have usable bounds; it may not support exact footprint or per-element operations. Capabilities are reported, not assumed.

ForestPack's Geometry reference exposes weighted sources, dimension-related settings, hierarchy behavior, and material-related options [S07]. Cyrus's storage and precedence below are independent decisions.

## 2. Three different selection states

**Enabled:** eligible source with its configured weight.

**Empty outcome:** eligible weighted choice that emits no geometry and occupies no space.

**Excluded from selection:** not in the weighted distribution; remaining weights renormalize.

A missing asset is none of these. Preserve the unresolved source and its weight so recovery does not unexpectedly redesign the population. Diagnostic rendering can show a labeled bound proxy.

Weights are finite and nonnegative. Negative input is rejected. A source with zero weight can remain available for manual placement and name matching according to the selected policy.

## 3. Geometry normalization

Do not modify source geometry in place to normalize it. Compute a source-local transform describing pivot correction, unit conversion, explicit size, and offsets. Cache reusable geometry in its original or canonical local space.

Dimensions can be authored as a uniform size multiplier or target dimensions. Nonuniform dimension overrides are separate from random scale. A zero source dimension cannot be used as a divisor; degenerate axes require an explicit rule or error.

A Z offset is in source-local up by default and is transformed with placement orientation. A world-up offset is a different control. This distinction matters on sloped receivers.

## 4. Bounds and occupancy

Visual bounds describe possible rendered geometry. Collision bounds describe placement separation. Root/trunk exclusion bounds describe relationships with other layers. They can differ.

A tree's canopy can be four meters wide while its grass-clearance radius is half a meter. Store those as independent proxy definitions rather than repeatedly adjusting one universal radius.

For an animated source, bounds must cover the selected sample or a declared motion envelope. A static first-frame bound is not sufficient for animated culling or collision policies that promise motion clearance.

## 5. Transform composition

Use an explicit transform recipe:

```text
resolved surface position
 -> source/receiver alignment frame
 -> source-local normalization
 -> inherited reference/path transform components
 -> random orientation and scale
 -> global and local fixed multipliers
 -> spatial response multipliers
 -> placement Effects
 -> constrained manual overrides
 -> optional final reprojection
 -> strict boundary and collision evaluation
```

The implementation uses one matrix convention defined in chapter 03. This textual order describes semantic responsibilities, not an instruction to multiply every matrix left-to-right without respecting that convention.

Separate full replacement from additive/delta overrides. A manual `AbsoluteWorldTransform` replaces procedural placement. A `LocalDelta` composes against it and therefore follows some upstream changes.

## 6. Translation

Expose world-unit translation and source-relative translation as different modes. Source-relative translation multiplies by source dimensions under a declared normalization stage. It is not an arbitrary percent of whatever bounding box is easiest to access.

Random XYZ values use separate channels. Axis linking intentionally reuses a value; independent axes do not. Translation direction can use world, surface tangent, path, or source-local frames.

A placement moved off its receiver can either remain free or request projection. Default constrained placement reprojects to its allowed receiver set when lateral translation is enabled. A missing final hit rejects the candidate or preserves an explicitly permitted free position. This must not depend on whether the viewport has recently refreshed.

ForestPack documents that random translation can move items outside the original area [S08]. Cyrus's default strict boundary mode can differ; a compatibility profile records that distinction.

## 7. Rotation

Store angles in radians internally. UI values use degrees. Separate yaw about the chosen up axis from pitch/roll in the local frame. Default yaw is uniform 0–360 degrees; pitch/roll are zero unless enabled.

Euler order is saved and fixed for a given profile. Convert to quaternions for composition and interpolation. A path-follow orientation plus random yaw means rotation around the path-derived local up, not necessarily world Z.

Discrete orientations use a weighted list. A probability curve can approximate narrow preferences, but a four-direction bench layout should not require numerical spikes in a continuous curve.

## 8. Scale

Support uniform, linked XY plus independent Z, and independent XYZ modes. A lock is a relationship between sampled values, not a UI-only synchronization of displayed limits.

For uniform mode, sample one normalized value and map it through the scale distribution. For independent mode, use three channels. A probability map modulates variation strength; a value map directly chooses values. A source can provide per-axis base dimensions before these controls.

Reject nonfinite scales. Default positive scale excludes zero. Mirroring is an explicit signed-axis policy with correct winding/normal handling in each output adapter. Shear inherited from references is preserved only when the selected output path supports it.

## 9. Probability curves and maps

A probability-density curve uses CDF inversion described in chapter 06. A transform value map remaps scalar or RGB data into a range. A variation-strength map blends between a defined neutral transform and the sampled transform.

For scale, neutral is `(1,1,1)`. For translation and rotation offsets, neutral is zero. Interpolating absolute rotations requires a saved interpolation policy; componentwise degree interpolation across the 0/360 seam can be wrong.

Global, area, and source controls resolve through explicit inheritance. A local random range replaces the global random range; a local fixed scale multiplier multiplies it. Expose the resolved transform components in the inspector.

## 10. Compound sources

An atomic compound source stores child provider references and child-local transforms. One parent placement is generated. Child world transforms are derived from parent placement and child-local transforms. The compound has a configured occupancy proxy and a group-level LOD policy.

An expanded compound is a different feature: children become independently evaluated instances with parent/child identities. They may need separate receiver projection, collisions, or editing. Do not silently expand an atomic source when it is ungrouped in Max.

Retain stable child UUIDs for per-element tint and selection. Reordering components for UI presentation must not change their random colors. Removing a child invalidates its associated optional edits without shifting every subsequent child identity.

## 11. Source replacement

Replacing an asset preserves SourceUUID when the artist intentionally updates that asset definition. A separate `Add as new source` command creates a new UUID. Preserve existing source assignments under replacement, then reevaluate dimensions, footprints, animation, material capabilities, LOD, and affected constraints.

Replacing a shrub with a tree can legitimately reject neighboring instances. The operation reports those dependencies and can be undone. It is not merely a render-mesh swap.

## 12. Cache strategy

Cache geometry per source content/time sample, not per instance. Cache bounds and element decomposition separately where possible. Updating a source's probability does not require reevaluating its mesh. Updating its material tint does not require rebuilding the receiver BVH.

A material topology change can require a new renderer prototype even when the mesh is unchanged. A face material-ID edit can change element decomposition. Cache keys therefore include the exact data each derived result reads.

## 13. Tests

Use a cube with an off-center pivot, a tall tree with a small root proxy, a mirrored source, a sheared reference, an atomic flower arrangement, an expanded arrangement, and a missing proxy asset. Test world versus source-relative translation, local versus world offsets, path orientation, axis locks, deterministic random channels, source replacement, and material-only edits.

A source system is complete only when its placement, occupancy, display, and render interpretations agree about transforms and bounds.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S07]: https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry
[S08]: https://docs.itoosoft.com/forestpack/forest-plugin/transform
