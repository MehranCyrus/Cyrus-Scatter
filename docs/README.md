# Cyrus Scatter documentation

## Current engineering work and navigation

Start with the [heavy-scene viewport findings and next implementation](Heavy_Scene_Viewport_2026-10-02/README.md). The current product candidate is Scatter 0.62 / Analyzer 0.14; the retained-point work is a tested private prototype awaiting production integration. The [root guide](../README.md) maps the codebase, while [workspace organization](Workspace_Organization.md) explains what is backed up in Git and where local scenes, packages and scratch output live.

The [original research briefs](Research_Briefs_2026-10-01/README.md), [local codebase report](Codebase_Research_2026-10-01/REPORT.md) and [supplied external reports](Research_Inputs_2026-10-01/README.md) are preserved together with their provenance. Their consolidated conclusions are in [knowledge and decisions](Heavy_Scene_Viewport_2026-10-02/KNOWLEDGE.md). Earlier dated strategy and measurement packages below remain historical references, with their original scope and limits.

## Start here: current product and engineering strategy

[Product strategy — 2026-09-29](Product_Strategy_2026-09-29/README.md) is the current guide for priorities, product direction, and verification status. It brings together the codebase review, performance work, licensing policy, artist workflows, renderer/studio requirements, and current Autodesk/Chaos research.

Read the [executive assessment](Product_Strategy_2026-09-29/01_Executive_Assessment.md), then the [master roadmap](Product_Strategy_2026-09-29/11_Master_Roadmap_and_Backlog.md). [Baseline and Trust](Product_Strategy_2026-09-29/12_First_Implementation_Milestone.md) defines reproducible scenes, diagnostics, source-risk investigation and host/renderer qualification. Subsequent measured implementation work is recorded below; the dated strategy remains its planning reference.

The strategy package distinguishes source findings, completed tests, vendor capabilities, and proposed work. Its [evidence ledger](Product_Strategy_2026-09-29/02_Current_System_and_Evidence.md) records the current limits; its [documentation governance](Product_Strategy_2026-09-29/14_Documentation_Governance.md) reconciles older statements without rewriting historical reference packages.

## Personal product commercialization playbook

[Commercialization playbook — 2026-09-30](Product_Commercialization_Playbook_2026-09-30/README.md) provides 16 practical stages for understanding the installed build, recording manual results, choosing product scope, preparing licensing, qualifying support, producing demos/media, and preparing beta, pricing and launch. Start with [Stage 01](Product_Commercialization_Playbook_2026-09-30/01_Understand_the_Current_Product.md) and use its [master checklist](Product_Commercialization_Playbook_2026-09-30/00_Master_Checklist.md) and [progress log](Product_Commercialization_Playbook_2026-09-30/99_Progress_Log.md).

This is an operational layer under the governing product strategy above. Its [repository review and exact deliverables](Product_Commercialization_Playbook_2026-09-30/98_Repository_Review_and_Deliverables.md) distinguish current source, retained tests, fresh package checks and proposed work. Creating the playbook does not qualify the product or approve a licensing provider, price, public claim or launch.

## Future AI-assisted design research

[AI, MCP and ML roadmap — 2026-09-30](AI_MCP_ML_Roadmap_2026-09-30/README.md) evaluates reference-assisted scatter design against the current codebase and current primary sources. It defines a provider-neutral automation API, five proposed MCP tools, a bounded general-model prototype, versioned data examples, ten experiments and a phased implementation backlog.

This is a future product/technology research track under the governing strategy. No AI/MCP system, custom model, telemetry or production change is implemented by this package. Start with its [executive judgment](AI_MCP_ML_Roadmap_2026-09-30/00_Executive_Summary.md) and [current automation audit](AI_MCP_ML_Roadmap_2026-09-30/01_Current_Cyrus_Automation_Audit.md); the existing Baseline and Trust milestone, commercialization playbook and performance roadmap retain their roles.

## Install the Max 2027 test build

See [Max 2027 installation and quick start](Max_2027_Installation.md) for the compiled MZP installers, usage steps, build commands and exact verification status. The current **0.62 viewport performance candidate** defers layer synchronization during held input. Its [second-round results and next renderer plan](Viewport_Performance_Round2_2026-10-01.md) record 33.1% less scatter callback time and 9.1% less total step wall time in a controlled held-input comparison. It includes the [0.61 proxy batching improvement](Viewport_Performance_Implementation_2026-10-01.md) and [0.60 CPU implementation](Performance_Implementation_2026-10-01.md); the CPU build's [upgrade test](Performance_Upgrade_Test_2026-10-01.md) and [artist editing retest](Performance_Artist_Retest_2026-10-01.md) remain historical evidence. Broader interactive editing, Undo and Corona qualification remain open.

The separate [Max 2026 review handoff](handoffs/max2026/README.md) documents the local folder with version-specific Scatter 0.62 and Analyzer 0.14 installers, a self-contained demo saved in Max 2026 format, and a drawing comparison helper. Its SDK build and nine native suites passed. The demo and helper were checked in Max 2027; Max 2026 installation and runtime confirmation remain pending.

## Detailed performance specification

The [heavy-scene viewport loop — 2026-10-02](Heavy_Scene_Viewport_2026-10-02/README.md) reconciles the supplied research, defines the requested Preview / Full Detail workflow, and implements a private retained-point experiment. Its [measured results](Heavy_Scene_Viewport_2026-10-02/RESULTS.md) show one million preview points at 3.813 ms median synchronous camera-step time versus 73.194 ms with current point submission, with a 3.305 ms disabled control. These are not completed-frame FPS or a packaged feature: point footprint, supported-source coverage and product lifecycle remain integration gates. Follow its [working checklist](Heavy_Scene_Viewport_2026-10-02/ROADMAP.md) and [implementation plan](Heavy_Scene_Viewport_2026-10-02/IMPLEMENTATION_PLAN.md) for the next loop.

For slow camera navigation, start with the [0.62 follow-up investigation](Viewport_Performance_Round2_2026-10-01.md), then the [0.61 implementation report](Viewport_Performance_Implementation_2026-10-01.md) and [original measured investigation](Viewport_Performance_Investigation_2026-10-01.md). Testing `SaveSelect 2.max` isolated per-instance drawing overhead with zero navigation rebuilds; batching reduces submission batches from 6,284 to 44 while preserving 37,704 proxy triangles. The follow-up removes repeated synchronization while dragging and evaluates retained display as future work. Reports retain raw evidence and qualification limits. Their wall-time measurements are not completed-frame FPS claims; 0.62 is a packaged local test candidate, not a fully qualified release.

For controllers that cannot be reselected, see the [selection investigation and diagnostic selector](Selection_Diagnosis_2026-10-01.md). Disabling the viewport filter restored selection in the artist's scene; the document separates that confirmed result from the remaining icon-geometry concern.

Measure installed builds with the [standalone performance baseline recorder](Performance_Baseline_Tool.md). It supplies a Max panel, explicit preview rebuild trials, independent process CPU/memory sampling, raw exports and guarded comparison reports. The first target is Max 2027 with the artist's Corona 15 scene; calculation comparisons and an exploratory candidate editing retest now exist, while repeatable interactive edge/Undo and renderer qualification remain required.

For shape-edit responsiveness, use [Detailed edit tracing](Performance_Edit_Tracing.md), including its one-time installer and named-edit workflow. The [detailed surface-edit reviews](Spline_Edit_Trace_2026-10-01.md) validate tracing, recover an earlier recorder marker-ID defect and identify expensive nested clover calculations and repeated rebuild activity. The [0.60 artist retest](Performance_Artist_Retest_2026-10-01.md) compares observed layer timings and identifies remaining repeated passes. These recordings capture direct Editable Poly boundary-edge changes; case labels do not affect tracing, and their exact manual edit recipes remain unspecified. Read the [first preview trial](Performance_Baseline_2026-10-01.md) and [passive spline-edit trial](Spline_Edit_Trial_2026-10-01.md) for the earlier artist-scene evidence. Full renderer qualification remains pending.

[Performance roadmap — 2026-09-28](Performance_Roadmap_2026-09-28/README.md) supplies detailed performance contracts and experiments under the current master roadmap. It covers scatter/editing, viewport, Surface Analyzer, render preparation, CPU algorithms, multithreading, optional OpenCL, Max 2024–2027 qualification, and the requested 32 GB RAM minimum.

Use its [backlog and gates](Performance_Roadmap_2026-09-28/07_Implementation_Backlog_and_Gates.md) for technical detail and the [manual test runbook](Performance_Roadmap_2026-09-28/08_Manual_Test_Runbook.md) for broader qualification. [Results and decisions](Performance_Roadmap_2026-09-28/09_Results_and_Decisions.md) links the October 1 comparisons and records which work is accepted for a local test build.

## Reference packages

1. [Complete codebase documentation](CyrusScatter_Complete_Codebase_Documentation_2026-09-27/README.md) — the 2026-09-27 source reference for Scatter, Analyzer, generated UI, rendering, installation, persistence and tests. The newer performance audit records relevant corrections and implementation priorities.
2. [Licensing implementation package](CyrusScatter_Licensing_Implementation_Package_2026-09-27/README.md) — proposed licensing policy, integration, provider experiments and release work. Apply the newer [licensing policy reconciliation](Product_Strategy_2026-09-29/09_Licensing_and_Commercial_Strategy.md) before implementation. Keep enforcement changes separate from performance comparisons.
3. [Original performance engineering research](Cyrus%20Scatter%20Performance%20Engineering%20Report.md) — preserved background research. Use the performance roadmap for coding guidance; its audit explains corrections, and its sources document replaces reliance on exported chat citation tokens or unavailable sandbox attachments.

The dated roadmap and licensing package describe their original proposed work. The original documentation pass did not build or run the project. Subsequent Max 2027 compatibility, performance measurements and the first bounded CPU implementation are recorded in the installation and implementation guides above. Max 2024–2026 runtime qualification, the 32 GB test floor, renderer qualification, asynchronous editing and GPU compute remain pending.

The two older reference packages have their own `MANIFEST.md` and `diagrams/` directories. The performance package has a navigation table, an inline dependency diagram and `source_snapshot.json` with SHA-256 fingerprints for its local source baseline.
