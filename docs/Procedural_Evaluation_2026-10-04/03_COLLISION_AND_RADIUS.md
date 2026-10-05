# 03 — Three collision scopes and effective point radii

Status: proposed contract. Here “collision” means spacing using simplified footprints. Exact plant-mesh intersection is outside this delivery.

## Choose one relationship for each pair

| Pair membership | Rule scope | Example |
| --- | --- | --- |
| Same set | Self-spacing | Red flower against another red flower in the same set |
| Different sets, same layer | Set-pair spacing | Blue flowers keep a margin around red flowers |
| Different layers | Layer-pair spacing | Ground cover keeps away from the tree layer |

Classify by stable ownership IDs. Resolve the explicit rule or its scope default **once**. Do not apply all three scopes to the same pair or add the same gap multiple times. A distinct site-boundary exclusion is a separate constraint, not another copy of a pair rule.

Rules are sparse overrides. A layer can supply a self default and a sibling-pair default; each set can override self-spacing, and selected sibling pairs can override their shared default. Cross-layer set-specific overrides are deferred to keep the first UI and contract manageable.

## Distance contract

For effective nonnegative radii `r_i`, `r_j`, a nonnegative relationship multiplier `k` and nonnegative extra gap `g`:

```text
minimumDistance(i, j) = k * (r_i + r_j) + g
reject an ordinary proposal when distanceMetric(i, j) < minimumDistance(i, j)
```

The equality boundary is accepted, matching the current native rule. Use squared double-precision distances with finite/range validation; define any future numerical tolerance in world units and use it consistently in solver, oracle and export validation.

Examples, using metres:

| Radii | Multiplier | Gap | Minimum centre distance |
| --- | ---: | ---: | ---: |
| 0.20 and 0.30 | 1.0 | 0.10 | 0.60 |
| 0.20 and 0.30 | 0.5 | 0.00 | 0.25 |
| 0.20 and 0.30 | 0.0 | 0.10 | 0.10 |

`k = 0` removes radius influence but does not remove an extra gap. A disabled rule permits that relationship to overlap. Negative gaps/radii are rejected in the first contract; reducing `k` provides deliberate overlap without ambiguous negative thresholds.

Radius and population are independent. Reducing radius admits closer proposals; it does not create new proposals unless the candidate stream/refill policy supplies them. Increasing radius can lower the final count.

## Deriving an instance's radius

Recommended new data flow:

```text
source radius policy -> transformed source radius -> instance override -> rule threshold
```

1. **Manual source radius** is the initial supported default and preserves existing artistic values. Zero is allowed and shown honestly.
2. **Follow scale** applies the effective source/instance scale exactly once. Reconcile the current source-offset transform convention before implementing this calculation.
3. **Per-instance override** is a sparse authored record keyed by owner namespace plus the resolved instance/Edit output ID. A candidate ID remains provenance; clones can share a candidate while having different output IDs and radii. Support either an explicit world-radius override or a multiplier with an unambiguous mode; do not multiply and override simultaneously.
4. The relationship multiplier changes spacing for that pair class without modifying source metadata, instance transform or render geometry.

Optional automatic radius estimation from source bounds can follow after these rules work. Its UI must say whether it estimates a horizontal disk or a 3D sphere and where its centre is. A canopy, trunk and full tilted tree have different useful footprints. A manually chosen artistic radius is not a proof that meshes cannot intersect.

Initially keep the centre at the final instance origin for compatibility. Any automatic enclosing radius must be measured around that origin. A bounding-box half-size around a different centre is not sufficient unless its centre offset is also transformed and used by the collision query.

For ordinary rotation plus scale without shear, multiplying a local enclosing sphere by the largest absolute scale is conservative. For an arbitrary linear transform `A`, a conservative sphere needs an upper bound on its operator norm. The current largest-row-length calculation alone is insufficient under shear. Either validate unsupported shear or implement and test a safe bound (for example, the Frobenius norm, which can overestimate). Do not introduce expensive per-point decomposition without profiling; source-level metadata and common transform classes should be reused.

No dense per-instance parameter table is necessary: derive default radii and store only overrides. Deleting an override restores inheritance. A topology/seed/source-namespace change that cannot preserve identity must report orphaned overrides instead of applying them to array indices.

## Coordinate metric

| Metric | Meaning | Limitation |
| --- | --- | --- |
| World XY | Ground-plan disk distance; height ignored | Separate floors can block each other; vertical surfaces may collapse in projection |
| World XYZ | Sphere/centre Euclidean distance | Opposite sides of a thin shell can be near; does not measure distance along a curved surface |
| Surface geodesic | Distance along receiver connectivity | Future research; requires its own topology and metric contract |

Curved Brush support does not make current collision geodesic. Expose XY/XYZ clearly. Later per-receiver/component isolation may be useful for multi-floor work, but it must be a deliberate rule option. Retain the actual pivot/centre convention in diagnostics; do not silently use a canopy centre in one scope and a stem anchor in another.

## Native solver extension

Extend the existing pure-data solver in [group_spacing.cpp](../../AminScatter/src/group_spacing.cpp), rather than moving point-pair loops into MAXScript.

Proposed solver inputs include positions, immutable IDs, effective radii, ownership, protected flags, ordered candidate ranges and normalized rules. Outputs include kept indices, rejection categories, blocker owner/ID where requested, protected conflicts and work counters. Keep the existing bridge available for old policy calls; a new typed bridge can adapt the richer result.

- Self-spacing must use variable radius sums, not only a fixed `withinDistance`.
- For each relevant rule, broad-phase reach must cover `k * (maxOwnRadius + maxBlockerRadius) + g`.
- The current 27-cell/9-cell neighborhood logic is safe only with a cell width bounding that reach. If width changes, derive the queried cell range; never keep a fixed neighborhood accidentally.
- Skip disabled or zero-reach checks safely. Validate coordinate/cell-index overflow and finite values before insertion.
- Insert ordinary proposals only after all applicable constraints pass. Rejected candidates never become blockers.
- Protected reservations are inserted separately and their violations are reported.
- Deduplicate reservations by stable instance ID, exclude the queried instance itself by ID, and count a protected override only once. Coincident positions with different IDs remain different instances.
- Use stable iteration order. Unordered hash iteration and worker completion order must not decide winners.

Uniform grids are a sensible first implementation because the repository already has them and an exhaustive oracle. Very different tree/grass radii can make a largest-radius grid inefficient. Measure neighbor visits and cell occupancy before introducing radius buckets, a hierarchy or a BVH. A new broad phase must return the same accepted IDs as the reference algorithm.

## Collision diagnostics

For each ordinary proposal record one terminal reason according to a fixed test order: invalid/binding, coverage/area, inter-layer, inter-set, self-spacing, cleanup, or target/work-limit state. More detailed “also violates” information may be optional and non-additive.

Protected conflicts are separate from removal counts. A protected plant may violate two rules but still contributes one placed instance. Diagnostic mode may retain a capped sample of pairs; production statistics should not allocate an unbounded graph of every possible collision.

## Compatibility mapping

For an old uniform self/sibling radius `R`, use fixed-distance compatibility behavior or an equivalent normalized rule yielding `2R`; do not substitute source radii and call it compatible. Old inter-layer footprint rules map to `k = 1`, their old gap and metric, with existing effective radii. Rules with footprint use disabled map to zero radii plus their gap.

New independent settings are activated through an explicit policy conversion with a previewable result and Undo. Existing scenes must not acquire new source-radius collision behavior merely by opening them in a newer build.
