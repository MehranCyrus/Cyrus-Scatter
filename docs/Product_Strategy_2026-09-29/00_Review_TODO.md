# CyrusScatter — strategy review to-do list

Started: 2026-09-29. Scope: research, source review, and documentation. No Git, no subagents, and no production code changes.

## Review and evidence

- [x] Inventory all existing documentation, source, build tools, and available test evidence.
- [x] Read the codebase, licensing, and performance documentation; identify overlap, stale claims, conflicts, and missing decisions.
- [x] Recheck implementation boundaries, persistence, generation, installation, viewport, rendering, Analyzer, and testing against source.
- [x] Verify current Autodesk guidance for 3ds Max 2027 and supported older hosts, SDK/toolchains, threading, deployment, security, viewport, rendering, and scene exchange.
- [x] Verify current Chaos guidance for Scatter, Corona, V-Ray, proxies, rendering, and production workflows; distinguish inspiration from integration guarantees.
- [x] Reconcile historical test reports with available artifacts and record what has and has not been proven.

## Product and engineering decisions

- [x] Define the intended users, strongest initial workflows, differentiated value, and explicit non-goals.
- [x] Assess current strengths and weaknesses candidly, with evidence and confidence levels.
- [x] Design a practical artist experience: onboarding, procedural controls, feedback, editing, recovery, presets, and troubleshooting.
- [x] Define architecture boundaries, data ownership, stable identity, versioning, and compatibility strategy.
- [x] Consolidate CPU, concurrency, optional GPU, viewport, memory, and render preparation priorities into one measured performance strategy.
- [x] Define renderer, studio, farm, asset, batch, interchange, and automation requirements.
- [x] Reconcile licensing and commercial plans with offline use, scene safety, rendering continuity, support, and release readiness.
- [x] Define quality gates, release operations, documentation ownership, and measurable product outcomes.
- [x] Prioritize improvements and experiments into a dependency-aware roadmap with acceptance criteria, stop rules, and a first implementation milestone.

## Deliverables and checks

- [x] Write the final strategy package with a clear reading order and references to the existing detailed specifications.
- [x] Create a source register, evidence ledger, decision register, risk register, and actionable backlog.
- [x] Update the main documentation index to explain which documents govern which decisions.
- [x] Validate local links, document consistency, source provenance, and the boundary between verified facts and proposals.
- [x] Prepare the final assessment, next steps, and remaining uncertainties for the user.

This checklist records work actually completed. Research findings are evidence, not permission to change the product or adopt a vendor.

## Completion record — 2026-09-29

Delivered 19 Markdown documents, including this checklist and the package index, plus evidence records. Seven existing native executables passed; two isolated generator runs reproduced production output; both MZPs passed integrity checks. Local links and unchanged source inputs were checked in the [validation report](evidence/document_validation.json).

Review completion does not mean the roadmap is implemented. Runtime renderer tests, older-host qualification, measured speedups and a real 32 GB workload envelope remain pending. Some vendor deep links were unavailable; those limits and the absence of a proven renderer/Points adapter API are recorded in the [source register](15_Research_Sources.md). The review was at subsystem level with targeted source tracing, not a formal line-by-line audit.
