# Scatter interactions — garden investigation and implementation plan

26 October 2026. **Current correction: [0.87.2](DELIVERY_0872.md), Max 2027 only.** [Artist guide](ARTIST_GUIDE_0872.md), [qualification](QUALIFICATION_0872.json) and [ownership/acceptance plan](IMPLEMENTATION_0872.md). Fixes explicit SI preparation handling, reviewed Arthropodium roots/branches/folded leaves and source-bound lightweight tree colliders. The [0.87.1 small-scene investigation](SMALL_SCENE_FINDINGS_20261026.md) is preserved as the before-state.

25 October 2026. **0.87.0 is implemented as a scoped Max 2027 artist trial.** Start with the [delivery and remaining limits](DELIVERY_0870.md), [artist workflow](ARTIST_GUIDE_0870.md), [qualification manifest](QUALIFICATION_0870.json) and [execution/issue history](EXECUTION_0870.md). Documents 01–06 and the original investigation retain their pre-integration intake and proposal status; their old gaps are not the current delivery ledger. Broader physics, renderer and natural-bending acceptance remains separate.

The intended workflow is practical: mark the stone layer as an obstacle, prepare each distinct plant source once, and bend only nearby plant instances. Keep the reusable source rig separate from each instance's pose. Covered roots, nearby queries and visible surface clearance require separate decisions.

## Reading order

| Document | Purpose |
|---|---|
| [01 — Scene and assets](01_SCENE_AND_ASSETS.md) | Provided rocks, selected library models, preparation intake and scene reconstruction |
| [02 — Current system](02_CURRENT_SYSTEM.md) | Verified source map, existing capabilities, integration gaps and evidence limits |
| [03 — Integration architecture](03_INTEGRATION_ARCHITECTURE.md) | Ownership, source reuse, transforms, spatial queries, pose delivery, invalidation and resource budgets |
| [04 — Artist workflow](04_ARTIST_WORKFLOW.md) | Proposed Interactions panel, simple defaults, optional controls and clear status |
| [05 — Implementation sequence](05_IMPLEMENTATION_SEQUENCE.md) | Dependency-ordered work packages, exit criteria and scope boundaries |
| [06 — Validation matrix](06_VALIDATION_MATRIX.md) | Required correctness, performance, interaction and delivery acceptance |
| [Investigation results](INVESTIGATION_RESULTS.md) | Exact final runs, measured results, failed attempts and remaining qualification |
| [Decisions and open questions](DECISIONS_AND_OPEN_QUESTIONS.md) | Recommended defaults, alternatives and decisions still needing measurement |

## Working artifacts

- [Approved generated reference](../../../CyrusVegetationLab/experiments/garden-reference/garden-contact-reference-v1.png): an AI concept, not a Max render or implementation proof.
- [Reproducible investigation scripts](../../../CyrusVegetationLab/experiments/garden-contact/): owned Max launcher, asset intake, scene builder and offline spatial probe.
- [Final baseline scene](../../../build/garden-baseline-host-20261025-03/Cyrus_Garden_Baseline_Max2027.max): existing Scatter with static rock-footprint masks; no automatic rock bending.
- [Max baseline receipt](../../../build/garden-baseline-host-20261025-03/receipt.json), [scene metrics](../../../build/garden-baseline-host-20261025-03/scene-report.json), [spatial probe](../../../build/garden-baseline-host-20261025-03/spatial-probe.json).
- [Original asset hashes](ROCK_INPUTS.json), [OBJ structure](ROCK_OBJ_INSPECTION.json), [preparation intake](PREPARATION_INTAKE.json), [startup identity](STARTUP_IDENTITY.json).

Build artifacts and `.max` files are local ignored outputs. Source assets remain in their original locations. They are referenced, not repackaged for external distribution.

## Original first-delivery recommendation — retained proposal

Implement an **Interactions** foundation with prepared-source capabilities, stable per-placement identity, a native nearby-instance index, reversible root suppression and a bounded pose publication inlet. Start with supported lavender/geranium sources and explicit sphere/box proxies. Add the grass blade profile and qualified rock-mesh contact before calling the full garden workflow complete. Treat the tree as a static obstacle first.

The garden is a useful integration fixture because its hard parts are independent: flat grass topology, many shared instances, uneven stone geometry, wide foliage, rendering unique poses and responsive restoration after moving an obstacle away. Fast single-plant fitting alone does not settle those boundaries.

Existing [foundation contracts](../../ENGINEERING_FOUNDATION.md), [historical pre-integration delivery](../edit-instances/DELIVERY_08692.md), [independent preparation lab](../../../CyrusVegetationLab/experiments/stem-live/GUIDE_031.md) and [original A/B/C handoff](../../research/vegetation-core-handoff/README.md) retain their own status. This plan does not supersede their source identities or qualify untested behavior.
