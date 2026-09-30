# Cyrus Scatter documentation

## Start here: current product and engineering strategy

[Product strategy — 2026-09-29](Product_Strategy_2026-09-29/README.md) is the current guide for priorities, product direction, and verification status. It brings together the codebase review, performance work, licensing policy, artist workflows, renderer/studio requirements, and current Autodesk/Chaos research.

Read the [executive assessment](Product_Strategy_2026-09-29/01_Executive_Assessment.md), then the [master roadmap](Product_Strategy_2026-09-29/11_Master_Roadmap_and_Backlog.md). The next coding assignment is [Baseline and Trust](Product_Strategy_2026-09-29/12_First_Implementation_Milestone.md): reproducible scenes, diagnostics, investigation of concrete source risks, and an initial measured host/renderer baseline.

The strategy package distinguishes source findings, completed tests, vendor capabilities, and proposed work. Its [evidence ledger](Product_Strategy_2026-09-29/02_Current_System_and_Evidence.md) records the current limits; its [documentation governance](Product_Strategy_2026-09-29/14_Documentation_Governance.md) reconciles older statements without rewriting historical reference packages.

## Personal product commercialization playbook

[Commercialization playbook — 2026-09-30](Product_Commercialization_Playbook_2026-09-30/README.md) provides 16 practical stages for understanding the installed build, recording manual results, choosing product scope, preparing licensing, qualifying support, producing demos/media, and preparing beta, pricing and launch. Start with [Stage 01](Product_Commercialization_Playbook_2026-09-30/01_Understand_the_Current_Product.md) and use its [master checklist](Product_Commercialization_Playbook_2026-09-30/00_Master_Checklist.md) and [progress log](Product_Commercialization_Playbook_2026-09-30/99_Progress_Log.md).

This is an operational layer under the governing product strategy above. Its [repository review and exact deliverables](Product_Commercialization_Playbook_2026-09-30/98_Repository_Review_and_Deliverables.md) distinguish current source, retained tests, fresh package checks and proposed work. Creating the playbook does not qualify the product or approve a licensing provider, price, public claim or launch.

## Future AI-assisted design research

[AI, MCP and ML roadmap — 2026-09-30](AI_MCP_ML_Roadmap_2026-09-30/README.md) evaluates reference-assisted scatter design against the current codebase and current primary sources. It defines a provider-neutral automation API, five proposed MCP tools, a bounded general-model prototype, versioned data examples, ten experiments and a phased implementation backlog.

This is a future product/technology research track under the governing strategy. No AI/MCP system, custom model, telemetry or production change is implemented by this package. Start with its [executive judgment](AI_MCP_ML_Roadmap_2026-09-30/00_Executive_Summary.md) and [current automation audit](AI_MCP_ML_Roadmap_2026-09-30/01_Current_Cyrus_Automation_Audit.md); the existing Baseline and Trust milestone, commercialization playbook and performance roadmap retain their roles.

## Install the Max 2027 test build

See [Max 2027 installation and quick start](Max_2027_Installation.md) for the compiled MZP installers, usage steps, build commands and exact verification status. This subsequent compatibility build passed native tests and a Max 2027.1 batch smoke test. The dated documentation packages below preserve their original audit/planning status; performance optimizations remain planned work.

## Detailed performance specification

[Performance roadmap — 2026-09-28](Performance_Roadmap_2026-09-28/README.md) supplies detailed performance contracts and experiments under the current master roadmap. It covers scatter/editing, viewport, Surface Analyzer, render preparation, CPU algorithms, multithreading, optional OpenCL, Max 2024–2027 qualification, and the requested 32 GB RAM minimum.

Use its [backlog and gates](Performance_Roadmap_2026-09-28/07_Implementation_Backlog_and_Gates.md) for technical detail and the [manual test runbook](Performance_Roadmap_2026-09-28/08_Manual_Test_Runbook.md) for future test builds. Current progress and implementation order are reconciled in the new master roadmap. [Results and decisions](Performance_Roadmap_2026-09-28/09_Results_and_Decisions.md) currently contains no comparative performance results.

## Reference packages

1. [Complete codebase documentation](CyrusScatter_Complete_Codebase_Documentation_2026-09-27/README.md) — the 2026-09-27 source reference for Scatter, Analyzer, generated UI, rendering, installation, persistence and tests. The newer performance audit records relevant corrections and implementation priorities.
2. [Licensing implementation package](CyrusScatter_Licensing_Implementation_Package_2026-09-27/README.md) — proposed licensing policy, integration, provider experiments and release work. Apply the newer [licensing policy reconciliation](Product_Strategy_2026-09-29/09_Licensing_and_Commercial_Strategy.md) before implementation. Keep enforcement changes separate from performance comparisons.
3. [Original performance engineering research](Cyrus%20Scatter%20Performance%20Engineering%20Report.md) — preserved background research. Use the performance roadmap for coding guidance; its audit explains corrections, and its sources document replaces reliance on exported chat citation tokens or unavailable sandbox attachments.

The roadmap and licensing package describe proposed work, not completed features. The original documentation pass did not build or run the project. The subsequent Max 2027 compatibility work is recorded in the installation guide above. Other host ports, speedups, CPU threading and GPU support still require implementation and qualification.

The two older reference packages have their own `MANIFEST.md` and `diagrams/` directories. The performance package has a navigation table, an inline dependency diagram and `source_snapshot.json` with SHA-256 fingerprints for its local source baseline.
