# CyrusScatter — product and engineering strategy

<!-- CURRENT_SYSTEM_2026-10-05 -->

Historical product strategy. Use the [0.72 implementation/delivery campaign](../Integrated_UI_0.72_2026-10-06/README.md), [current comparative R&D findings](../TyFlow_CyrusScatter_RnD_2026-10-06/FINDINGS_AND_ROADMAP.md) and the [architecture/extension baseline](../Current_System_2026-10-05/README.md) for implemented status and next loops. Research benefits and estimates in this dated package remain hypotheses unless linked to later evidence.

**Review date: 2026-09-29. Status: recommended governing plan; implementation remains gated by evidence.**

## My assessment

Cyrus has a credible technical foundation and an unusually useful combination of procedural placement, boundary analysis, street layout, and persistent manual editing. It is ready for a disciplined product-development cycle. It is not yet proven as a production-ready commercial plugin across the requested hosts and renderers.

The opportunity is **precise environment layout that survives revisions and production handoff**. Faster computation supports that promise. Reliability, understandable controls, useful presets, and predictable rendering make artists return to the tool.

## Read these first

1. [Executive assessment](01_Executive_Assessment.md) — what is strong, what is missing, and the recommended direction.
2. [Master roadmap](11_Master_Roadmap_and_Backlog.md) — one implementation order and measurable gates.
3. [First implementation milestone](12_First_Implementation_Milestone.md) — the next concrete coding assignment.

## Complete document map

| Document | Purpose |
|---|---|
| [00 — Review to-do list](00_Review_TODO.md) | Requested checklist and completion record |
| [01 — Executive assessment](01_Executive_Assessment.md) | Product judgment and allocation of effort |
| [02 — Current system and evidence](02_Current_System_and_Evidence.md) | Architecture, verification status, source findings, corrections |
| [03 — Positioning and workflows](03_Product_Positioning_and_Workflows.md) | Intended users, differentiation, competitive context |
| [04 — Artist experience and features](04_Artist_Experience_and_Feature_Priorities.md) | Practical UX and feature specifications |
| [05 — Architecture and scene contracts](05_Architecture_and_Scene_Contracts.md) | Ownership, identity, evaluation, compatibility, failure handling |
| [06 — Autodesk and host strategy](06_Max_2024_2027_and_Autodesk_Opportunities.md) | Older hosts, 2027 foundations, 2027.2 opportunities |
| [07 — Performance and resources](07_Performance_and_Resource_Strategy.md) | CPU, threading, GPU, viewport, memory, measurements |
| [08 — Rendering and studios](08_Renderers_Assets_and_Studio_Pipelines.md) | Renderer adapters, proxies, farms, assets, batch, USD |
| [09 — Licensing and business](09_Licensing_and_Commercial_Strategy.md) | Commercial scope, continuity, policy conflicts, operations |
| [10 — Quality and releases](10_Quality_Qualification_and_Release.md) | Test matrix, release gates, deployment, recovery |
| [11 — Master roadmap](11_Master_Roadmap_and_Backlog.md) | Dependencies, priorities, acceptance, stop rules |
| [12 — First milestone](12_First_Implementation_Milestone.md) | Work packages and deliverables for the next coding cycle |
| [13 — Decisions and risks](13_Decisions_Risks_and_Open_Questions.md) | Decision status, uncertainties, severity, owners |
| [14 — Documentation governance](14_Documentation_Governance.md) | Which package governs what; stale-document reconciliation |
| [15 — Research sources](15_Research_Sources.md) | Dated primary sources, findings, retrieval limits |
| [16 — Beta and product validation](16_Beta_and_Product_Validation.md) | How to prove usefulness and adoption |
| [17 — Experiment briefs](17_Experiment_Briefs.md) | Bounded prototypes with go/no-go criteria |

## How this relates to the existing documents

This package governs **priorities, product scope, and current status**. The [performance package](../Performance_Roadmap_2026-09-28/README.md) remains the detailed algorithm/benchmark specification. The [current licensing plan](../licensing/README.md) governs licensing architecture, policy decisions and implementation; the September package is historical reference. The [codebase package](../CyrusScatter_Complete_Codebase_Documentation_2026-09-27/README.md) is a dated architecture reference. The [installation guide](../Max_2027_Installation.md) describes the delivered test build.

Do not implement every idea in these documents. Complete the current milestone, collect evidence, and use the next gate to select work. Existing documents were preserved; this review does not silently rewrite their historical manifests.

## Evidence added in this review

- [198-file input inventory and SHA-256 hashes](evidence/review_input_inventory.json).
- [Two isolated generator runs](evidence/generator_check.json), both byte-identical to production output.
- [Seven existing Release test executables rerun successfully](evidence/native_test_rerun.json).
- [Both delivered MZP packages rechecked](evidence/package_check.json), with valid ZIP contents and payload hashes.
- [Archived prior runtime evidence](evidence/prior_runtime_evidence.json), preserving the earlier smoke and CTest material.
- [Documentation and source-integrity validation](evidence/document_validation.json), covering local link targets, Markdown fences, and unchanged review inputs.

These checks do not establish render compatibility, speedups, interactive UI quality, or the 32 GB envelope. The prior Max 2027.1 batch smoke log was reviewed; Max was not launched again for this strategy review. No Git, subagents, product-source edits, account creation, purchases, or host upgrades were used.

## Evidence vocabulary

**Verified-source** means source supports the statement. **Verified-test** identifies an actual test and its limits. **Vendor-documented** describes an external capability, not Cyrus compatibility. **Proposed** is a recommendation. **Hypothesis** requires an experiment. **Pending** means evidence is missing. These distinctions apply throughout this package.
