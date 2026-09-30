# AI-assisted scatter: research and roadmap

**Date: 2026-09-30. Status: PROPOSED future product/technology research track.**

**Recommendation:** give reference-assisted design a gated place in Cyrus's roadmap. Build reliable automation first; test a general multimodal model and curated examples before considering custom ML. No AI capability was implemented or qualified by this documentation task.

The [Product Strategy](../Product_Strategy_2026-09-29/README.md) remains the governing strategy. Its [Baseline and Trust milestone](../Product_Strategy_2026-09-29/12_First_Implementation_Milestone.md), the [commercialization playbook](../Product_Commercialization_Playbook_2026-09-30/README.md), and the [performance roadmap](../Performance_Roadmap_2026-09-28/README.md) retain their existing roles. AI research does not establish launch readiness, licensing policy, performance gains, or support for additional Max versions.

## Read by decision

| Document | Decision it supports |
| --- | --- |
| [README — Navigation and manifest](README.md) | Evidence labels, task status and exact deliverables |
| [00 — Executive summary](00_Executive_Summary.md) | Whether to pursue this direction; smallest worthwhile prototype |
| [01 — Current automation audit](01_Current_Cyrus_Automation_Audit.md) | What the source exposes and what needs engineering |
| [02 — Product vision and boundaries](02_AI_Product_Vision_and_Boundaries.md) | Artist value, limits, differentiation |
| [03 — GPT/Astra versus specialized ML](03_GPT_Astra_vs_Specialized_ML.md) | Capability classification and options A–E |
| [04 — MCP and automation architecture](04_MCP_and_Automation_Architecture.md) | Process boundaries, host safety, identity and transactions |
| [05 — MCP tools](05_MCP_Tool_Design.md) | First five tools and later endpoint families |
| [06 — Structured contracts](06_Structured_Design_Plan_Schema.md) | Versioned data, units, constraints, six JSON examples |
| [07 — Execution and feedback](07_Agent_Execution_and_Feedback_Loop.md) | Bounded iteration, approval, recovery, stopping |
| [08 — Data strategy](08_Data_and_Training_Strategy.md) | What to collect, permissions, meaningful dataset sizes |
| [09 — Artist corrections](09_Artist_Corrections_and_Learning.md) | Interpreting edits without inventing preferences |
| [10 — ML options](10_ML_Options_and_Experiments.md) | Narrow targets, model families, ML readiness checklist |
| [11 — Evaluation](11_Evaluation_and_Benchmarks.md) | Ten experiment briefs, metrics and release gates |
| [12 — Security and privacy](12_Security_Privacy_and_Studio_Constraints.md) | Scene authority, data movement and studio restrictions |
| [13 — Performance and infrastructure](13_Performance_and_Infrastructure.md) | Resource budgets, deployment modes, future ML operations |
| [14 — Product UX](14_Product_UX_and_Workflow.md) | A practical artist workflow and visible controls |
| [15 — Phased implementation roadmap](15_Phased_Implementation_Roadmap.md) | Ordered backlog, owners, dependencies and acceptance |
| [16 — Decisions, risks and sources](16_Risks_Decisions_and_Open_Questions.md) | Open decisions, research provenance, requirement coverage |

## Evidence language

Use these labels at the claim or section level:

- **VERIFIED IN CURRENT CODE:** inspected source behavior; does not imply runtime qualification.
- **VERIFIED BY TEST:** identify the exact recorded test and date; historical results are not fresh runs.
- **PROPOSED:** a contract, decision, implementation task or target that does not exist yet.
- **RESEARCH HYPOTHESIS:** a plausible benefit requiring a comparison.
- **UNKNOWN:** available evidence does not establish the answer.
- **REQUIRES EXPERIMENT:** a specified observation or trial must resolve it.
- **FUTURE / OPTIONAL:** outside the initial prototype and not a dependency of core Cyrus use.

External documentation establishes vendor or research capabilities, not Cyrus behavior. Those claims are identified as **primary-source facts**, linked near the claim, and indexed in [16](16_Risks_Decisions_and_Open_Questions.md). Recommendations and numeric budgets are engineering proposals, not benchmark results.

## Work completed and work still pending

- [x] Read the supplied research specification line by line.
- [x] Trace the current controller, native engine, bridges, generator, layers, sources, constraints, previews, Analyzer, CS Edit, PFlow, persistence, packaging and tests.
- [x] Reconcile this proposal with the existing documentation hierarchy.
- [x] Research current official OpenAI, Autodesk, MCP and relevant ML sources.
- [x] Define the prototype, contracts, data strategy, ten experiments and phase backlog.
- [x] Create linked documentation and synthetic JSON fixtures.
- [ ] Build the automation API or MCP server.
- [ ] Run an AI model, collect artist results, train anything or qualify this workflow.

Documentation checks and preservation checks are recorded separately in [validation.json](evidence/validation.json). They do not make any unchecked implementation item complete.

## Exact package manifest

The navigation table lists all **18 Markdown files**, including this README. The additional **nine JSON files** are:

- [examples/scene_context.json](examples/scene_context.json)
- [examples/design_plan.json](examples/design_plan.json)
- [examples/tool_execution_log.json](examples/tool_execution_log.json)
- [examples/final_layout_state.json](examples/final_layout_state.json)
- [examples/artist_correction.json](examples/artist_correction.json)
- [examples/training_sample.json](examples/training_sample.json)
- [evidence/input_snapshot.json](evidence/input_snapshot.json)
- [evidence/source_register.json](evidence/source_register.json)
- [evidence/validation.json](evidence/validation.json)

The examples are **PROPOSED, synthetic, example-only fixtures**. Their successful-looking states illustrate a contract; they are not executions, measurements or training data collected from users. The baseline hashes cover 249 existing files: 101 files outside `docs/` and 148 files inside it. Build/distribution/cache directories were excluded.

Only [docs/README.md](../README.md) is updated outside this package. Historical packages, production source, generated scripts, scene schemas and ClassIDs remain unchanged. This task used no Git, subagents, production builds, Max sessions, model inference, training, telemetry or dependency installation.

