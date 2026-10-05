# Implementation report

## Result and scope

The 0.7 candidate adds a separate procedural evaluation policy to the existing plugin. Layers and paint sets keep their native Max panels, assets, Brush documents, transforms, include/exclude controls and display adapters. The new policy supplies explicit execution order, three independent spacing scopes, variable radii, bounded replenishment, background coverage composition, stable candidate randomness and a transaction around publication.

No new FPS improvement is claimed. Retained point/Mesh rendering and proxy construction are preserved in `point_display.cpp` and `preview.cpp`; the offline checker compares those files against the checkpoint. [Isolated Max testing](RUNTIME_REPORT.md) now verifies their publication integration and zero navigation rebuilds at 20,000 and 100,000 plants. High-count Proxy drawing remains slow in both the frozen 0.64 package and this candidate.

## What the artist can configure

| Control | Owner | Implemented behavior |
| --- | --- | --- |
| Move up/down | Layer Manager / Paint sets | Persisted order decides ordinary winners. Reordering does not change sampling salts or allocation tie order. |
| Candidate budget / Accepted target | Layer | Existing count/density supplies the layer budget, divided by enabled set weights. Accepted target requests replacement candidates within limits. |
| Attempt factor / Max rounds | Layer | At most 32 times the set quota, capped at 100,000 attempts per set; 1–16 rounds. Defaults: factor 8, eight rounds. |
| Retry cleanup gaps | Layer | Replay rejected candidates after union cleanup releases temporary blockers, within the same round bound. |
| This paint set spacing | Selected set | Inherits the old layer collision setting until explicitly overridden. Inheritance means fixed 3D distance `2 × collisionRadius`. |
| Default between sets | Layer | Separate sibling rule; conversion initializes it from the old within-layer collision distance. |
| Pair of paint sets | Sibling relationship | Explicit enabled/disabled override of the sibling default. |
| Pair of layers | Layer relationship | Explicit rule; absent layer pairs do not collide. Existing shared pair rules are mapped on conversion. |
| Radius factor / Extra gap / XY | Selected rule | `factor × (radius A + radius B) + gap`; exact equality is permitted. XY ignores height; 3D includes it. |
| Background mode and references | Selected set | Off, Outside painted coverage, Between plants, or both. Explicit references must be earlier sibling sets. |
| Selected CS Edit instance radii | Selected set / final instance ID | World radius or multiplier, including distinct clone IDs. Clear selected overrides or all overrides for the set. |
| Cached diagnostics | Set | Eligible pool, kept, protected, conflicts, three rejection scopes, cleanup removal, not consumed, attempts, shortfall, neighbor visits and publication epoch. |

The `Procedural / Rules` section names both the layer and selected set. Population, transforms, Area and cleanup remain layer settings; this does not add an independent copy of every control to each paint set. Legacy pair/priority controls are disabled in policy 3; their cleanup controls remain applicable. Point Relax and Boundary Relax remain paused where the new policy cannot preserve their movement semantics.

## Evaluation sequence

1. Resolve enabled owners, visible order and weighted quotas. Allocation ties use creation order independently of display/evaluation order.
2. Validate capabilities, references and work limits. Synchronize receiver/source correspondence metadata.
3. Prepare a bounded candidate pool per enabled set. Apply eligibility and procedural Brush coverage at the resolved support anchor; source lift/scale happens afterward.
4. Validate and apply CS Edit. Eligible moved/cloned instances become protected reservations; deleted or ineligible inputs do not reserve stale positions.
5. Compute effective per-instance radii. Resolve ordered layer, sibling and self constraints. Classify each pair in exactly one scope.
6. Clean the accepted union of each layer. Preserve protected edits. If enabled, retry space released by cleanup and extend underfilled candidate prefixes on the fixed schedule.
7. Stage all viewport caches and final accepted rows. Publish Edit selection state, cached statistics, display buffers and one new controller epoch after all stages succeed.

The native evaluator operates on owned numeric data. Max node/mesh/Brush access and publication stay on the host thread. Existing clustered calculations can use their bounded CPU workers; no CUDA/OpenCL placement, asynchronous scene access or new GPU compute backend was introduced.

## Stable identity and randomness

Candidate ordinals are independent of compacted output position. Placement, transforms, source selection, axis scale, density and diversity use deterministic candidate channels under policy 3. Whole Scale and density falloff now have opt-in keyed paths too; their old index-based paths remain available to policies 1/2. Mask rejection cannot shift another candidate's source or transform draws.

Ownership IDs, sampling salts and visible order are distinct. Source/receiver reference registries keep stable IDs when a node is replaced and subsequently restored with Undo. Registries are bounded at 1,024 source and 128 receiver references per population. Placeholder entries use explicit slot keys. Copying a layer keeps its sampling recipe, gives it new owner identities, remaps internal set rules/background references, copies external layer rules and clears per-instance radius overrides because the copy has no corresponding copied CS Edit stack.

The Edit binding signature excludes ordinary count/quota, order, radius and coverage. It includes receiver correspondence and exact triangle-position hash, sampling and source/transform recipe. An edited input beyond a reduced ordinary quota can be reconstructed and validated. An erased input remains absent; moving an eligible protected plant outside coverage is a separate authored exception. Source/seed/receiver changes with unresolved bindings fail without silently attaching saved edits to different candidates.

Radius overrides carry the binding they were authored against. Resetting native Edit after changing the generator cannot silently reuse old overrides on new points. The artist can restore the old recipe or explicitly clear that set's radius overrides.

## Radius and protected-edit semantics

Source radius is spacing metadata, not mesh resizing or an exact geometry collision test. Follow Scale applies a conservative bound from the final transform's Gram matrix. This handles negative/nonuniform scale and shear and equals the largest axis scale for orthogonal bases. World overrides replace the resulting radius; multiplier overrides multiply it once.

Protected plants reserve their actual edited positions, including when their ordinary quota is zero. They survive spacing and cleanup conflicts; conflicts are reported. An ordinary candidate cannot displace an eligible protected instance. Two protected instances may therefore overlap or exceed an accepted target. Disabled owners supply no rows/reservations; hidden owners continue to participate in calculation and render.

## Coverage versus replenishment

Outside coverage evaluates `ownField × (1 − max(referencedFields))`, then applies the selected set's Brush density once. It uses the normalized authored field before plant occupancy and ignores referenced set share/count and display visibility. Disabled references cease contributing. A referenced Whole-surface set consumes its entire shared Area domain and can legitimately leave no available region.

The first implementation restricts outside-coverage references to earlier siblings on one receiver, so all participants share the layer's Area domain. Arbitrary cross-layer domains require a separate coordinate/domain adapter. Density maps and density falloffs affect candidate eligibility; they do not redefine the referenced authored Brush field. Area/Analyzer inclusion applies before composition. This is surface-anchor painting, not geodesic-distance painting.

Between plants uses the ordinary configured set rules. It adds no hidden distance rule. Turning its label off does not disable existing spacing rules. It validates that referenced pairs have an enabled, nonzero rule configuration; nonzero source radii are still necessary when the gap is zero and the rule uses radii.

Accepted target counts planting slots, including Point placeholders. Weighted Empty sources are rejected in this mode so intentional empty slots are not silently refilled; Candidate budget retains Empty behavior. Shortfall is diagnostic, not proof that a surface is mathematically full.

The fixed prefix starts at the quota and grows by `min(attemptLimit, max(prefix + 32, 2 × prefix))`. Warm cache suffixes cannot enter earlier rounds. Cleanup suppression is a bounded heuristic; it is not a maximum-packing solver or an iterative fixed-point cleanup guarantee.

## Cache and publication boundaries

- Immutable candidate/base results and prepared eligibility/Edit results are cached per set; the completed controller solve and display generation are cached separately.
- Rule/radius/order changes do not belong to the base candidate key. Presentation names, set visibility, rollout browsing and selection do not belong to calculation keys.
- Display mode/budget changes can rebuild retained display data from the last completed accepted rows without resampling.
- Explicit Manual updates have a controller-local revision. Edit changes in Manual mark pending data rather than forcing the old immediate-refresh path.
- A synchronous native transaction snapshots Edit maps. Failure restores them and clears derived prepared keys; binding signatures and the previous complete placement/display publication are retained.
- Full display caches are staged before publication. The old preview error path that erased a good cache is bypassed for policy 3.

This is not yet a general node graph, disk cache, streaming point-cloud engine or independent final-result cache for every dependency edge. A changed solve currently replays the ordered native spacing pass for the controller while reusing prepared candidate stages. Staged publication temporarily holds old and new display resources. Measure update latency and peak memory before adding finer-grained final-layer reuse or raising limits.

## Limits and compatibility

- Ten total stored populations, including Base/child sets; existing layer count/density limit 100,000 before allocation.
- At most 100,000 generated candidates per set and 1,000,000 admitted samples per controller. Protected clones count toward the native sample cap.
- At most 16 replay rounds. A native cap of 50,000,000 spacing neighbor predicates rejects pathological solves while keeping the last result. This is not a total wall-time limit on mesh extraction, projection, cleanup or display building.
- Random/Clusters assignment only for policy 3. Line Pattern/Analyzer assignment uses existing policies; Analyzer Area/falloff eligibility remains available.
- Static enrolled Brush surfaces and projected movement for painted/composed coverage. Topology changes require validation; stroke history is preserved.
- Adopt the saved scene's system units on reopen. Automatic rescaling into different system units is not supported for the combined Brush/Edit/radius state; the painted-surface guard preserves history and rejects the mismatch. The supported reopen path and recovery were tested in Max 2027.
- Background outside coverage is sibling-scoped in this candidate. Layer-to-layer spacing is implemented independently.
- No native policy conversion when the controller already contains CS Edit. Test on a separate setup without that stack; conversion must be explicit.
- Class IDs are unchanged; serialized MAXScript version advances to 52 for added parameters. Product version is 0.7.0; MCP plan/protocol and Analyzer versions are independent.

## MCP and future ML

The configuration query has an additive `procedural` section (`cyrus.procedural-configuration/1.0`) with ordered owners, rules, source entry IDs, background references, radius overrides and the last published epoch. Lengths in this export use metres. Read-only export does not trigger generation. Point/Empty/missing source entries no longer assume a mesh node exists during inspection.

Plan schemas 1/2 remain closed and select policies 1/2. Their apply path rejects overwriting a policy-3 controller. There is no new remote Brush/history/order/rule mutation contract. ML remains a future recipe proposer; this work neither trains a model nor interprets references or uploads data.

## Principal implementation locations

| Area | Files |
| --- | --- |
| Pure sampler / ordered solve | `AminScatter/src/scatter.cpp`, `procedural.cpp`, `group_spacing.cpp` |
| Keyed falloff / whole scale | `boundary_falloff.inc`, `boundary_falloff_bridge.inc`, `whole_scale_bridge.inc` |
| Max transport / radius bridge | `max_bridge.cpp`, `procedural_bridge.inc` |
| Edit transaction / selection / local revision | `cyrus_edit.cpp`, `cyrus_edit_stack.inc` |
| Composite coverage | `brush_host.cpp` |
| Persisted model / evaluation / native UI | `tools/ui/templates/procedural-{model,evaluation,ui}.ms` and `tools/ui/procedural-policy.cjs` |
| Generated plugin | `AminScatter/scripts/AminScatterObject.ms` — regenerate, do not hand edit |
| Read-only automation | `CyrusMCP/cyrus_mcp/procedural.py`, `max_host.py`, `settings.py` |
| Reproduction / Max fixtures and evidence collection | `tools/procedural_lab/` |

Changes remain local working-tree work. Unrelated licensing work and dated readiness evidence were preserved; no commit/push or artist-profile installation was performed. The subsequent authorized runtime phase and its integration fixes are documented in [RUNTIME_REPORT.md](RUNTIME_REPORT.md).
