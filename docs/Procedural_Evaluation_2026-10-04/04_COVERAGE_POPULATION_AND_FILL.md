# 04 — Coverage, population and the two fill behaviors

Status: proposed next-policy behavior. These concepts need separate names because they answer different artist questions.

## Coverage is permission; population supplies candidates

A Brush document defines a field on the receiver: paint increases permission, erase reduces it, and stroke history remains editable. An area mask further limits the domain. Source assignment chooses the asset. Collision and cleanup decide which proposals survive.

Coverage dots visualize the field or its samples. Plant centres visualize accepted instance origins. Point Cloud uses potentially many geometry samples per plant. None of these counts should be silently substituted for another.

Retain surface-anchored strokes as the authoritative Brush representation. An optional grayscale map is a derived import/export representation requiring a declared UV/projection mapping and resolution. Saving a bitmap does not solve arbitrary curved-surface correspondence or topology changes. Do not replace existing Brush storage merely to make masks look like black/white paint.

## Overlapping paint is not necessarily colliding plants

Two sets can paint the same region yet have no plant pair closer than its minimum distance. Conversely, two non-overlapping paint regions can place plants near their shared boundary that violate spacing.

Keep these decisions independent:

| Control | Question answered |
| --- | --- |
| Coverage composition | May both sets generate proposals in this location? |
| Pair spacing | May these two actual instances be this close? |
| Population | How many proposals/desired accepted plants should be considered? |
| Fill policy | Should we use gaps or try replacements after rejection? |

Default overlapping paint to **Coexist**. Optional **Earlier coverage wins** suppresses later coverage independently of whether the earlier set places any plants. This is an explicit advanced mask operation, not a replacement for instance collision.

For a selected earlier-set collection with clamped fields `M_s(x)`, a proposed conservative coverage union is `U(x) = max_s M_s(x)`. A remaining-coverage field is `M_base(x) * (1 - U(x))`. This defines soft-mask behavior; alternative union operators must be versioned choices. It does not describe the existing Brush's internal stroke-compositing algorithm, which remains unchanged.

For the first Background contract, `M_s` is the normalized authored Brush field clipped by the owner's Area domain, with Whole surface using that Area domain. Population shares/counts and accepted plants do not define it. Additional density/falloff interactions must be declared explicitly by the adapter; see [11](11_OPTION_CONTRACTS.md).

## Population modes

### Existing candidate budget

Preserve the current mode and label it accurately: a layer budget is divided among enabled sets before coverage and collision. This mode is predictable, bounded and useful. A final count lower than the requested budget is expected.

### New accepted target with replenishment

The artist specifies a desired final count. Set weights allocate target shares, using deterministic largest remainders. Each set may request additional candidate ordinals within explicit attempt/memory limits. Spacing, coverage, cleanup and protected edits can still prevent the target.

Use a persistent allocation tie-break key, not the collision/UI ordering. Largest-remainder allocation does not guarantee that every set's share increases when the total increases: weights `[1500,1500,900,500,500,200]` yield `[7,7,4,3,3,1]` at 25 and `[8,8,5,2,2,1]` at 26. Document this composition tradeoff. Candidate-stream prefix stability is not a promise of monotone allocated or accepted counts. Changing the allocation method later requires a policy version.

Do not transfer a flower set's unfilled quota to grass implicitly. Redistribution would change the composition and is a separate future policy. Similarly, a background role does not secretly bypass the layer budget. The first version uses the same explicit share allocation; independent per-set count overrides can be added later with a clearly specified aggregate limit.

Protected instances count toward a set's target. If protected instances alone exceed it, preserve them and report an over-target condition; do not delete authored work to hit a number.

This requires a validated protected-input adapter when quotas shrink; it is not current CS Edit behavior for every base-signature change. A zero share stops ordinary generation. In the new accepted-target contract, valid protected plants can remain and report excess; disabling the set removes its participation entirely. Keep old semantics until that adapter and its quota-zero fixtures pass.

Define a target as accepted planting slots, with renderable instances reported separately. Explicit Point rows can be accepted slots without meshes. Intentional Empty source choices are different: the current pipeline removes them before shared spacing. Refilling those choices would undo their intentional gaps. For the first accepted-target delivery, reject enabled weighted Empty sources in that mode with an explanation to use candidate-budget mode; preserve their existing behavior there. Supporting target replenishment plus intentional empty-slot quotas needs its own contract, not silent substitution.

### Density

Retain legacy density semantics on the legacy policy. For a future density target, declare the denominator:

- Receiver surface area is different from projected XY area.
- Covered area is different from available space after plant exclusions.
- Expected density is different from guaranteed accepted density after collision.

A proposed new density target is `round(densityPerSquareMetre * eligibleWeightedSurfaceArea)`, allocated under explicit set policy. Computing that area on a curved painted surface requires a deterministic integration/sampling method and an error estimate. Do not label a rough estimate exact. Implement count targets first; qualify the density-target extension separately.

## Fill behavior A: background fill

Purpose: grass or ground cover occupies appropriate remaining parts of a design.

Designate a set as Background and evaluate it after the explicitly referenced ordinary sets. Show that order in the UI; do not create a hidden second evaluation order. Restrict fill references to earlier items, so the artist cannot accidentally create a cycle.

Offer two distinct domain interpretations:

1. **Between accepted plants**: generate in the background's own coverage and avoid the referenced accepted plants using the relevant spacing rules. The background's own radius is part of clearance. This allows growth between plants inside another set's painted region.
2. **Outside painted coverage**: use the coverage complement described above, then apply ordinary spacing as well. Empty but painted foreground areas remain reserved by intent.

These are alternatives within Background fill. They are also independent of **Target replenishment**, the second user-requested fill behavior below.

Background references express intent and dependencies; they do not silently add a second spacing rule or radius. Between-plants mode resolves the ordinary applicable pair rule once. If the rule is disabled or its effective reach is zero, show **No clearance configured** rather than promising a buffer around those plants. Unreferenced enabled collision rules still apply.

Outside-coverage references use enabled owners' effective coverage, independently of whether they produced plants. Hidden owners still participate; disabled owners do not. An enabled zero-weight foreground may therefore reserve painted coverage intentionally. A referenced Whole surface domain can leave no background area, which needs a clear explanation. Validate references against order and ownership; do not silently reorder the design or form a cycle.

No occupancy texture is required for the initial between-plants mode: use native point/radius spatial queries. This avoids introducing raster resolution, UV distortion and image-cache synchronization into a problem already expressible by accepted positions.

A background cannot fill more area than its candidate budget permits. Its UI should explain low density as a population issue when appropriate. Removal by shared cleanup can release further holes; the bounded layer repair in [02](02_PROCEDURAL_PIPELINE.md) revisits them if enabled and budget allows.

## Fill behavior B: target replenishment

Purpose: attempt replacements when coverage/collision/cleanup leaves a set below its desired count. It is not a request to move or enlarge existing plants, nor a promise to tile every pixel.

Recommended deterministic loop:

1. Define a stable candidate stream per set and generation namespace.
2. Generate a bounded initial batch, evaluate coverage/assignment/transforms and solve in priority order.
3. Run union cleanup and inspect the cleaned counts.
4. Replay eligible cached candidates when cleanup releases blockers. Add the next ordinal batch only to underfilled sets if budget allows.
5. Recompute downstream consumers when a higher-priority accepted result changes.
6. End when targets are met, no further work is available, or a configured limit is reached.

Always enforce hard limits on total generated candidates, retained candidate memory and repair rounds. Use fixed candidate/round caps for repeatable completed output. Wall-clock limits are useful for cancellation or yielding a pending job, but should not silently select a different “complete” layout on a slower computer.

The logical initial prefix and extension schedule are fixed, versioned parts of this policy. Consume only the scheduled prefix even if a warm cache has a larger pool. The two-candidate design probe in [readiness evidence](evidence/readiness/contract-probes.json) shows that consuming all cached rows, or changing logical batch sizes, changes cleanup-suppression results. Physical thread partitions and cache eviction must leave the logical sequence unchanged. Caps and schedule values require the P3 experiment; they are not chosen by this document.

Stopping after many failed samples is not mathematical proof that no valid location exists. Report **attempt limit reached** or **candidate stream exhausted**, not “surface completely full,” unless a future algorithm actually proves that result.

The existing scatter core has a bounded extra-attempt path for some density/area settings. That is not the same as multi-set, post-collision, post-cleanup target replenishment. Do not simply multiply its loop limit and claim this feature is implemented.

## Identity and repeatability

Proposed candidate identity combines the owner namespace with a versioned generation binding and ordinal. Sampling uses an explicit sampling key/seed independent of collision order and owner UUIDs. This lets a copy retain the same recipe while receiving distinct owner IDs. Final instance identity also includes the CS Edit output identity so clones are independent. None of these identities is a compacted row number.

Random channels for location, asset selection, transform and coverage thresholds must depend on candidate ordinal/purpose rather than conditional RNG consumption. The current numerical probe retained 68 area-filtered candidate IDs/positions, but 66 had changed scale/orientation and 41 changed source assignments. Stable keys alone do not provide stable attributes. Implement improved channels under the new generator version; preserve legacy results.

Increasing an attempt limit should extend a candidate stream rather than redraw its prefix. This is a requirement to implement and test, not an assumption about every existing generation mode. Changing a receiver topology, distribution family or seed may create a new identity namespace. Expose that distinction to Edit and MCP consumers.

Area-weighted sampling should retain deterministic face identity mapping. The earlier research's projection face-identity concern remains relevant: an acceleration structure cannot return a remapped face index to an anchor system expecting the original indexed snapshot.

## Example scenarios

| Artist action | Expected new-policy behavior |
| --- | --- |
| Paint red and blue flowers over one another | Both masks can coexist; a set-pair rule controls actual plant spacing |
| Reduce Red–Blue multiplier | More cross-set proximity is permitted; Red–Red spacing is unchanged |
| Enable Grass between accepted flowers | Grass evaluates later and tests actual accepted flower footprints |
| Switch Grass to outside flower coverage | Painted flower regions exclude Grass even if the flowers underfill |
| Enable replenishment for sparse Blue flowers | Additional deterministic proposals are attempted, respecting all constraints |
| Erase a red stroke | Its procedural proposals disappear; affected later results can reuse freed locations |
| Hide Red in viewport | Red remains an output/collision participant; only display changes |
| Disable Red | Red stops contributing, its quota allocation/dependents are reconsidered |
| Make spacing impossible for the target | Valid underfilled output plus a reason and bounded work counters |

## Release boundaries

First deliver count-based candidate/target modes, two background interpretations, deterministic bounded replenishment, ordinary XY/XYZ spacing and existing static Brush scope. Automatic optimal packing, geodesic spacing, arbitrary animated/deforming receivers, iterative Relax for painted sets and learned density generation require separate qualification. They should not hold the basic procedural improvement hostage.
