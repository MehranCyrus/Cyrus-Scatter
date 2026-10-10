# Unified procedural settings and source containers

> Historical implementation record. For the current product use [the documentation index](../README.md) and [backlog](../BACKLOG.md). Measurements and instructions below apply to their recorded build.

**Implemented successor:** [0.73 unified system](../Unified_System_0.73_2026-10-06/README.md) now records the actual ports, tests, packages and tradeoffs. This folder remains the pre-implementation requirements baseline; its planned checklist and 245-control register are not current status.

6 October 2026. **Requirements and implementation preparation; not an implemented cleanup or a new build.** This records the user's latest decisions after testing 0.72. The preparation pass changes documentation only and uses no computer-use tools.

## Intended result

One procedural calculation model, one organized set of settings, and source containers that behave as useful scene controls. The main Modify panel remains the primary editor; **Edit layer** opens the same settings in the optional popup. A container exposes that same model rather than creating another Scatter evaluator.

The user explicitly does not need compatibility with unpublished older development setups. Preserve useful features from those implementations by bringing them into the procedural model. Remove old evaluation policies, conversion buttons, duplicate settings and obsolete UI only after the required feature ports pass. Do not treat the word “legacy” as proof that a function is unused.

Old development scenes or MCP plans can become incompatible with the cleaned build. Existing scene files remain untouched; use disposable copies/new fixtures during implementation. Keep existing product class IDs and internal identifiers where still useful, rather than changing them merely for naming consistency. Historical receipts remain evidence of their original builds.

## Decisions gathered from the conversation

| Requirement | Result to deliver |
| --- | --- |
| Remove legacy/compatibility UI and calculation branches | Procedural is the default and sole supported evaluator. No “Enable Procedural” step for a new setup. |
| Bring old capabilities into the new model | Port Line Pattern/Analyzer source assignment and supported Relax behavior; consolidate spacing into the three explicit scopes. Account for the old MCP authoring capabilities before retiring their schemas. |
| Uniform settings | Explicit controller, layer, paint-set, source and instance ownership; layer defaults and a shared layer population remain declared. |
| Preserve performance | Keep stable candidate/source identities, relevant-input validity, preparation/publication caches, retained Mesh/Point Cloud, and bounded work. |
| Preserve Brush and artist edits | Keep independent editable stroke histories, flat/curved static-surface support, support anchors, protected edits, radius bindings, Undo and persistence. |
| Text beside source rectangles | A cached label identifies the container's role/owner and active/saved models. Shared ownership is stated accurately. |
| Selecting a rectangle shows Scatter properties | A Cyrus Source Container scene node exposes its linked controller/layer/set in Modify while the container stays selected and movable. |
| Rectangles act as movement groups | Moving a container carries its active managed sources. Moving a source out parks it and stops following; returning restores participation and the same per-owner settings. |
| Multiple containers | Global, layer and set pools remain available. A model can be used by several consumers, but has one physical movement owner. |
| No extra background calculations | UI selection/browsing and settled unrelated animation do not solve placements, rebuild Brush fields or upload unchanged buffers. Normal host drawing/callback receipt still costs work. |

## Read the implementation preparation in this order

1. [Capability ports and setting ownership](CAPABILITY_PORT_MAP.md).
2. [Source container behavior and implementation boundaries](SOURCE_CONTAINER_CONTRACT.md).
3. [Staged implementation checklist and acceptance tests](IMPLEMENTATION_CHECKLIST.md).
4. [All 245 current semantic controls and their planned dispositions](CONTROL_PORT_REGISTER.csv). This is a preparation inventory, not proof that the new controls exist.

The [0.72 baseline guide](../Integrated_UI_0.72_2026-10-06/README.md) describes what existed before this implementation. The [independent R&D findings](../TyFlow_CyrusScatter_RnD_2026-10-06/FINDINGS_AND_ROADMAP.md) remain unresolved findings/qualification gates; this design does not mark them fixed. This new decision supersedes earlier recommendations to preserve policies 1/2 and their schemas indefinitely. It does not silently authorize general MCP property execution, a trained ML system, or changes to licensing.

## Source facts that matter before deletion

| Current source fact | Evidence | Consequence |
| --- | --- | --- |
| New controllers still default to policy 2 | [planting-model.ms:2](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/planting-model.ms#L2) | Setting the default to procedural is part of implementation, not something already delivered. |
| Procedural rejects Line Pattern/Analyzer assignment | [procedural-evaluation.ms:46](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/procedural-evaluation.ms#L46), [logical-layers.ms:70](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/logical-layers.ms#L70) | Port the assignment/ownership contract before deleting the path that currently supports it. |
| Point Relax is deliberately gated off in procedural mode | [procedural-policy.cjs:85](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/procedural-policy.cjs#L85) | Removing a UI guard cannot make the algorithm safe with Brush, Edit and the ordered solver. |
| Procedural self-spacing still falls back to the old constant-radius default | [procedural-model.ms:207](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/procedural-model.ms#L207) | Replace the duplicate UI/data interpretation with a canonical rule; constant clearance remains expressible as factor 0 and gap 2 × old radius. |
| Containers currently accept ordinary, unmodified Rectangle splines | [source-containers.ms:21](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/source-containers.ms#L21) | A dedicated container node requires a new frame adapter and editor lifecycle, not a Scatter modifier attached to today's rectangle. |
| Registration retains source rows/settings while membership parks sources | [source-containers.ms:50](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/source-containers.ms#L50), [116](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/source-containers.ms#L116) | Preserve row/source identity and weights on boundary crossing; do not compact the source list. |
| Layer defaults currently synchronize declared fields into child sets | [logical-layers.ms:66](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/logical-layers.ms#L66) | Make ownership explicit without inventing independent child defaults or a second evaluator. |
| The generated script differs from its starting templates | [generate.cjs:117](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/generate.cjs#L117), [input-time.cjs:35](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/input-time.cjs#L35) | Review and test generator stages and generated output; template `currentTime` alone does not prove idle time invalidation. |
| MCP apply currently creates policy 1/2 controllers | [max_host.py:407](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/CyrusMCP/cyrus_mcp/max_host.py#L407), [procedural.py:70](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/CyrusMCP/cyrus_mcp/procedural.py#L70) | Explicitly port or gate authoring before retiring the legacy evaluator. The policy-3 draft compiler is offline preparation, not a host apply API. |

## Preparation identity and limits

Baseline: branch `codex/integrated-ui-0.72`, HEAD `01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2`. The current generated script SHA-256 is `77dadf0df9faabbba224de5c0602745c98302b1401e7a21368d5af0ba77f855b`. The [preparation snapshot](evidence/preparation-snapshot.json) inventories 559 non-document files and records pre-existing documentation changes. It is not a loaded-module or passing-test certificate.

Readiness means the requirements, known feature ports, dependency risks and test gates are recorded. The container-to-Modify adapter, transform transaction and Relax integration still require their first isolated implementation proofs. No production code, package, installation, scene, profile, commit or push is changed by this preparation. No Max/offline product tests are rerun for a documentation-only change; [documentation validation](evidence/validation.json) verifies links, the control register and preservation of the inventoried non-document files.
