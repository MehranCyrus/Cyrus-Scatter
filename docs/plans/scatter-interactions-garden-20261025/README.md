# Scatter interactions — garden investigation and implementation plan

**Current editor delivery: [0.87.4 Source Preparation Editor](../source-preparation-editor-20261026/DELIVERY_0874.md), Max 2027 only.** [Artist workflow](../source-preparation-editor-20261026/ARTIST_WORKFLOW_0874.md), [decisions and exact scope](../source-preparation-editor-20261026/IMPLEMENTATION_0874.md). The original research and broader matrix retain their planning status; the preceding patch below keeps its original qualification.

**Preceding tested patch: [0.87.3.2 source controls and broad-leaf contact](DELIVERY_08732.md), Max 2027 only.** [Artist workflow](ARTIST_WORKFLOW_08732.md), [ownership/geometry plan](PLAN_08732.md), [exact qualification](QUALIFICATION_08732.json). Source + / remove, primary preparation settings, 22-pixel inline swatches and elevated broad-leaf crown preparation pass scoped checks; actual surface proof closes a reproduced triangle-only crossing. Native Interactions 7 / schema 61.

26 October 2026. **Preceding tested correction: [0.87.3.1 preparation fix](PREPARATION_FIX_08731.md), Max 2027 only.** [Qualification](QUALIFICATION_PREPARATION_FIX_08731.json). Reproduced ParamBlock2 staging failure is corrected; scoped Prepare/settings/contact/Undo/persistence checks pass.

26 October 2026. **Original build-only revision: [0.87.3.1 complete stem contact](DELIVERY_08731.md), Max 2027 only.** [Artist workflow](ARTIST_WORKFLOW_08731.md), [implementation contract](IMPLEMENTATION_08731.md). User-requested code/package delivery; native and host tests are deferred. Native Interactions 6 / schema 61.

26 October 2026. **Preceding revision: [0.87.3 source workflow and contact repair](DELIVERY_WORKFLOW_0873.md), Max 2027 only.** [Artist workflow](ARTIST_WORKFLOW_0873.md), [implementation contract](WORKFLOW_REPAIR_0873.md). One role control, original-source guide review, automatic updates, full preview range and bounded visible-geometry refinement use native Interactions 5 / schema 61. Exact qualification and remaining acceptance are in the delivery.

26 October 2026. **Earlier revision: [0.87.3 plant preparation expansion](DELIVERY_0873_EXPANSION.md), Max 2027 only.** [Preparation/limits](ARTIST_GUIDE_0873_EXPANSION.md), [qualification](QUALIFICATION_0873_EXPANSION.json). Ten supplied plant sources prepare in those scoped tests; later code is qualified separately.

26 October 2026. **Preceding correction: [0.87.2](DELIVERY_0872.md), Max 2027 only.** [Artist guide](ARTIST_GUIDE_0872.md), [qualification](QUALIFICATION_0872.json) and [ownership/acceptance plan](IMPLEMENTATION_0872.md). Fixes explicit SI preparation handling, reviewed Arthropodium roots/branches/folded leaves and source-bound lightweight tree colliders. The [0.87.1 small-scene investigation](SMALL_SCENE_FINDINGS_20261026.md) is preserved as the before-state.

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
