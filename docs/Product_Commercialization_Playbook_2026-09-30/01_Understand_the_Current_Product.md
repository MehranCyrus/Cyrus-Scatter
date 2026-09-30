# Stage 01 — Understand the current product

## Goal

Be able to explain Cyrus Scatter in a minute, identify the delivered build, and open its two main tools. Suggested first session: 20–30 minutes.

## Why this matters

You will later explain the product to the owner, testers and customers. Start with what exists and what you have observed.

## What we currently know

**VERIFIED IN SOURCE:** Cyrus Scatter is a procedural object-placement plugin for 3ds Max. MAXScript stores settings and presents the UI; C++ generates transforms, applies several rules, analyzes suitable surfaces, and draws cached previews. **Cyrus Scatter Edit** adds manual instance changes. Final rendering currently prepares transient PFlow structures.

| Part | What you need to understand | Current evidence |
|---|---|---|
| Scatter | Surface + sources + layer settings produce placements | Native engine and UI inspected |
| Layers | Up to ten layers; source/rule settings per layer | Source limit and factories |
| CS Edit | Move/rotate/scale/clone/delete with saved edit records | Native implementation; current broad manual qualification pending |
| Surface Analyzer | Suitable open planar elements → boundaries, paths, points and Street Side data | Core/script inspected; native tests exist |
| Preview | Point Cloud, Proxy and Mesh; budgets limit display | Source and limited smoke evidence |
| Rendering | Automatic final render constructs PFlow transport | Code exists; renderer/IR qualification pending |
| Licensing | Commercial policy and future architecture | PROPOSED; no implemented LicenseCore/provider |
| Performance upgrades | Threading, OpenCL and later transport experiments | PROPOSED |

**VERIFIED BY TEST:** retained results report seven native suites passed on 2026-09-29 and a Max 2027.1 batch smoke passed on 2026-09-28. This review checked matching artifacts/hashes, without rerunning Max. The smoke exercised an empty edit stack, not the entire manual editing workflow.

Delivered package labels are Scatter **0.59** and Analyzer **0.14** for **Max 2027**. The tested host was **2027.1 / 29.1.0.11426**. Source build configuration accepts 2026/2027; 2024/2025 ports and full required 2024–2027 qualification remain unfinished. Version labels elsewhere differ; record package identity and do not infer a new commercial version.

Read the [current evidence ledger](../Product_Strategy_2026-09-29/02_Current_System_and_Evidence.md) and [installation guide](../Max_2027_Installation.md). Use [the architecture overview](../CyrusScatter_Complete_Codebase_Documentation_2026-09-27/01_System_Overview.md) only if you need more detail.

## My tasks

- [ ] Write down the environment and package details below.
- [ ] Read the two short references above.
- [ ] Open Max and find **Create > Geometry > Cyrus**.
- [ ] Confirm whether **Cyrus Scatter** and **Surface Analyzer** appear.
- [ ] Explain the roles of Scatter, Analyzer, CS Edit, preview and rendering in your own words.
- [ ] List three things you have personally seen, separately from things you only read.

## Engineering / Codex tasks

- [ ] Resolve missing-module or startup errors if your first load fails.
- [ ] Confirm loaded native/script identity; propose a clearer version/diagnostics display in the existing Baseline and Trust milestone.
- [ ] Preserve current schemas/Class IDs when later implementation begins.

## Boss / Product-owner decisions

No approval is needed to understand the internal build. Record possible target users for discussion in Stage 05. Commercial terms, vendor and price can wait until Stage 09.

## Step-by-step procedure

1. Open Max's About information and record the full version/build. In Render Setup record the selected renderer/build, or UNKNOWN.
2. Locate [Scatter MZP](../../dist/CyrusScatter-0.59-Max2027.mzp) and [Analyzer MZP](../../dist/CyrusSurfaceAnalyzer-0.14-Max2027.mzp). Record their names; do not run the loose legacy installer scripts.
3. If already installed and working, continue. If not, use **Scripting > Run Script** for the matching MZPs and restart Max as described in Stage 02.
4. Find the **Cyrus** category. Do not start with an existing client scene.
5. Write: “Cyrus helps [user] place [objects] on [surfaces], apply [rules], make [edits], and prepare [output].” Use this as a draft, not public copy.
6. Add a first progress-log entry with your next action: the basic scatter test.

## Evidence to collect

Environment record:

| Field | Your entry |
|---|---|
| Date / operator | — |
| Max year / full update/build | — |
| Windows version | — |
| CPU / RAM / GPU | — |
| Renderer / exact build | UNKNOWN |
| Scatter package / hash or native ID | — |
| Analyzer package / hash or native ID | — |
| Installed script/module paths, if known | — |
| First screenshot path | — |

Your explanation: **[write here]**

Questions to clarify after first use: **[write here]**

## Status table

| Item | Status | Notes |
|---|---|---|
| Cyrus Scatter appears | NOT TESTED | — |
| Surface Analyzer appears | NOT TESTED | — |
| Package identity recorded | NOT TESTED | — |
| I can explain the workflow | NOT TESTED | — |

## Completion criteria

You can identify your build/environment and explain the modules. Loading problems are recorded with an actionable error. If the tool cannot load, engineering must resolve that before dependent Max tests; documentation and scope review can continue.

## Do not do yet

Do not choose a provider, promise support, decide price, build the website, or learn every advanced setting before your first scatter.

## Optional / later

Read native API/persistence details when preparing a specific engineering assignment.

## Next stage

[Stage 02 — Manual product walkthrough](02_Manual_Product_Walkthrough.md).

