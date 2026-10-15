# 11 — Collisions, spacing, and exact incremental solving

**Status: proposed Cyrus algorithms. Research basis: R0 §2.4 and §8.3.**

## 1. Choose the solver's meaning

Collision filtering is an acceptance rule, not physical simulation. The initial Cyrus solver creates a deterministic nonoverlapping subset under configured proxy tests. It does not promise maximum packing density, globally optimal composition, or relaxation dynamics.

ForestPack documents virtual sphere-based collision checks [R0 §2.4; S02]. That supports a comparable proxy test, not a claim about its private winner-selection algorithm.

## 2. Collision proxy

Each candidate has a transformed proxy center and size. For sphere mode:

```text
center = finalTransform * sourceLocalCollisionCenter
radius = sourceRadius * globalRadiusMultiplier * scaleBound
```

For diagonal nonuniform scale, a conservative bound is the largest absolute scale component. For arbitrary affine shear, use a valid upper bound on the linear transform's largest singular value. Never use the smallest component and claim conservative separation.

`Collision height` changes the local proxy center. It is not the same as increasing radius. Ground-cover exclusion radius is separate from same-layer collision radius.

Two spheres conflict when `squaredDistance(ci,cj) < (ri + rj + clearance)^2`, where the radii and clearance are lengths in the same frame. Tangency is allowed by default. Numeric tolerance is part of the saved profile, not chosen ad hoc per worker.

## 3. Pair policies

A source-pair table can enable or disable collisions or add pair-specific clearance. Make it symmetric for the default same-layer solver. A directed “grass avoids trees” relationship belongs in the dependency/field system, not an accidentally asymmetric sphere test.

Optional planar-circle mode measures distance in the chosen ground frame. Full 3D sphere mode respects vertical separation. The artist must choose which problem is being solved on stacked terraces.

## 4. Deterministic reference solver

Define a total priority order independent of input enumeration and task completion:

```text
pinned tier first
then user priority tier
then stable collision-priority random key
then canonical candidate key as final tie-break
```

Pinned objects are explicit obstacles. Conflicting pins remain accepted with a diagnostic because they represent deliberate manual work. Ordinary candidates are accepted only when they do not conflict with any accepted earlier object.

```python
accepted = all_valid_pins
for c in sorted(ordinary_candidates, key=total_priority):
    if not any(conflicts(c, a) for a in accepted):
        accepted.add(c)
    else:
        record_rejection(c)
```

The naïve implementation is the correctness oracle for small fixtures. Its quadratic cost is acceptable in tests, not as the only production path.

## 5. Accelerated full solver

Keep the same priority order and replace only the search for conflicting accepted proxies. A spatial hash/grid can work for moderate radius variation. A BVH or hierarchical index can handle large and small proxies more effectively.

Grid insertion/query must cover every cell intersected by the proxy's AABB. A giant tree cannot be checked only in the center cell. Cap pathological cell expansion and route large proxies through a separate conservative index. Both routes use the same narrow-phase predicate.

The accelerated result must match the naïve oracle exactly for accepted IDs. Different broad-phase order must not change the winner: the candidate is rejected if **any** accepted conflict exists, regardless of which conflict is encountered first.

Rejection diagnostics can select the lowest-priority-key blocker for deterministic reporting rather than whichever grid bucket happened to be traversed first.

## 6. Why fixed-radius incremental updates fail

Consider candidates A, B, C, D, E, F in a line, with each conflicting only with its immediate neighbors. Greedy evaluation accepts A, C, E. Removing A can accept B, D, F. Extending the line extends the consequence arbitrarily far.

This refutes the claim that a brush radius plus maximum collision radius is always sufficient to update the accepted subset exactly. It is sufficient to find local geometric edges, not to bound acceptance propagation.

The initial CyrusV1 path therefore performs a full layer collision solve after updating affected candidate geometry. This is a valid baseline while other stages are already incremental.

## 7. Exact incremental strategy: old/new conflict components

Let `G_old` and `G_new` be graphs of occupancy-eligible candidates and pins. An edge means the pair conflicts under the old or new state respectively. Include rejected candidates as graph vertices: they may become accepted after an edit.

Construct the union relation over old and new states. Seed the affected set with every added, removed, moved, resized, reprioritized, reclassified, or eligibility-changed vertex. A globally changed pair rule seeds all potentially affected vertices or triggers a full solve.

Expand the set through **both old and new conflict neighbors** until it closes. This discovers the union-graph components touched by the change. Geometry that moved away still contributes old edges; geometry that moved into a region contributes new edges.

Within the closed affected set, rerun the full deterministic solver using new candidate states. Remove affected old accepted records and replace them with the new result. Unaffected accepted records remain unchanged because no old/new conflict edge crosses the component boundary.

This is an exact strategy for the specified local pairwise conflict relation and fixed total-order solver. It is not automatically valid for global relaxation, density normalization, nearest-N rules, or state-dependent pair relations.

## 8. Practical implementation of closure

It is not necessary to store every graph edge permanently. Keep spatial indices over **all occupancy-eligible old and new candidates**, not only accepted instances. During breadth-first closure, query possible neighbors in both states and evaluate exact conflicts.

The old state must retain removed/moved proxies long enough to discover old edges. The new state must include candidates previously rejected by collisions. If memory pressure prevents retaining sufficient old/new data, fall back to a full solve rather than inventing a partial result.

When closure exceeds a configured fraction of the layer or work budget, abandon local optimization and run the full solver. The threshold changes performance only; it must not alter acceptance.

Component computation can itself be expensive in dense scenes. Benchmark it against a full rebuild. An optimization that usually costs more should not be enabled merely because it is “incremental.”

## 9. Proof obligation in compact form

Assume the initial affected set includes every changed vertex and every endpoint of a changed edge. Its closure in the union graph leaves no conflict edge crossing to the unaffected set. Priorities and eligibility of unaffected vertices are unchanged. Greedy choices in disconnected components do not influence one another. Therefore reevaluating affected components under the new state preserves the global greedy result.

This proof depends on complete neighbor discovery and the selected pairwise solver. Test those assumptions. A missed large-radius broad-phase edge invalidates the proof.

## 10. Density stability has a limit

Before collisions, raising a stable density threshold retains a superset of candidates. After greedy collision filtering, it need not retain a superset of **accepted** instances: newly eligible higher-priority candidates can displace previously accepted ones.

State this in the UI and tests. Do not promise monotonic accepted populations merely because density thinning is monotonic.

For a different artist goal—keep existing placements and only fill gaps—offer an explicit history-dependent incremental-fill mode. That mode must save its accepted state and is not equivalent to a stateless procedural rebuild.

## 11. Relaxation and minimum-distance sampling

A relaxation solver moves candidates to improve spacing. It requires step size, iteration count, boundary projection, convergence/termination, deterministic update scheduling, and edited-instance constraints. It is a separate population operation, not an implementation detail of reject-only collisions.

Poisson/minimum-distance generation can reduce rejection waste. It changes the candidate process and may affect identity and distribution texture semantics. Introduce it as a generator/solver mode with its own behavior version rather than silently replacing image candidates.

Pinned objects must be obstacles in both modes. Unbounded iterative retries are forbidden.

## 12. Cross-layer interactions

For directed exclusion, upstream final positions export a field consumed by downstream generation. For true mutual spacing across layers, combine their candidates into one occupancy domain with stable layer/source priorities. This combined domain is solved and published coherently.

Do not emulate mutual collision by repeatedly rebuilding two mutually dependent layers until the viewport stops changing. Without convergence and ordering rules, that can oscillate.

## 13. Performance counters

Report occupancy candidate count, pins, accepted/rejected counts, narrow-phase tests, broad-phase candidates, index memory, closure size, full-solve fallbacks, and timings. Large candidate counts with little accepted growth indicate saturation.

Keep “candidate cap reached” separate from “packing saturated.” Increasing the cap can be pointless or harmful when nearly every new candidate collides.

## 14. Verification

Test a long conflict chain, variable radii, negative coordinates, giant proxies spanning many cells, tangency, duplicate centers, zero-radius proxies, moved pins, deleted blockers, source replacement, changed pair rules, and two disconnected components.

Randomized edits compare naïve full, accelerated full, and incremental results. Repeat under different input orders and index cell sizes. The included Python oracle demonstrates the chain counterexample and exact component strategy on small fixtures; it does not benchmark production complexity or establish Max integration.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S02]: https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode
