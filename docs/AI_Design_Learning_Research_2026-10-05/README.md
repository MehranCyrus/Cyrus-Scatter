# Cyrus Scatter: design learning and MCP research

Research cutoff: **5 October 2026**. Status: **research and proposed implementation plan; no new ML system implemented**.

**Second pass completed:** official Houdini and Autodesk documentation was checked against the current source and plans. Start with [the second-pass report](16_SECOND_PASS_REPORT.md) for the resulting changes. The roadmap now includes explicit identity, artifact integrity, callback/worker-mode and feature-pipeline gates; runtime qualification remains outstanding.

The recommended system is a bounded design laboratory around the existing procedural engine: generate distinct, valid planting recipes; execute them reproducibly; let artists compare results; learn a conditional preference model; and use that model to suggest the next useful alternatives. An artist remains responsible for choosing the final design. A companion application should handle datasets, review, search and inference while Max owns scene evaluation and publication.

This is achievable in stages. The first useful product does not require training a large model. Curated recipes, meaningful variation, saved comparisons and retrieval can already reduce repetitive work. A small learned ranker is the first ML experiment. Reinforcement learning, a graph neural network and a large knowledge graph each need evidence that they solve a remaining problem better than simpler alternatives.

## Read in this order

| Document | Purpose |
| --- | --- |
| [01 — Recommendation and decisions](01_RECOMMENDATION.md) | What to build, what to defer, and why |
| [02 — Current code and evidence](02_CODEBASE_AUDIT.md) | Existing capabilities, source anchors, real boundaries and gaps |
| [03 — Artist workflow](03_ARTIST_WORKFLOW.md) | Generation, comparison, rejection, personal/studio preferences and corrections |
| [04 — References and spatial composition](04_REFERENCE_AND_COMPOSITION.md) | Turn visual intent into editable scene relationships and planting recipes |
| [05 — Candidate search and learning](05_SEARCH_AND_LEARNING.md) | Baselines, active learning, rankers, quality diversity, BO, DPO and RL |
| [06 — MCP capability roadmap](06_MCP_ROADMAP.md) | Typed tools, procedural policy, export, batch scope and compatibility |
| [07 — Architecture and graphs](07_ARCHITECTURE_AND_GRAPHS.md) | Processes, state machine, four graph roles and failure recovery |
| [08 — Data and evaluation](08_DATA_AND_EVALUATION.md) | Dataset contracts, provenance, split design, metrics and promotion gates |
| [09 — Diagnostics and performance](09_DIAGNOSTICS_AND_PERFORMANCE.md) | IR restart investigation, bounded logging, cache preservation and cost |
| [10 — Roadmap and work queue](10_ROADMAP.md) | Ordered delivery loops, acceptance criteria and stop conditions |
| [11 — Experiments](11_EXPERIMENTS.md) | Reproducible experiments that can disprove the recommendation |
| [12 — Research ledger](12_RESEARCH_LEDGER.md) | Primary sources, dates, reading depth, relevance and limitations |
| [13 — Requirements and open decisions](13_REQUIREMENTS_AND_DECISIONS.md) | Traceability back to the user's requirements |
| [14 — Houdini engineering lessons](14_HOUDINI_ENGINEERING_LESSONS.md) | Procedural stages, identity lifetimes, PDG and learning-task distinctions |
| [15 — Autodesk host contracts](15_AUTODESK_HOST_CONTRACTS.md) | Render phases, notifications, validity, lifecycle, threading and worker modes |
| [16 — Second-pass report](16_SECOND_PASS_REPORT.md) | What changed after rechecking the code and vendor documentation |
| [17 — Vendor source ledger](17_VENDOR_SOURCE_LEDGER.md) | 25 selected official documentation entries with version/reading limits |
| [Examples](examples/README.md) | Synthetic proposed records; not accepted production MCP requests |
| [Verification](evidence/README.md) | Source fingerprints, test receipt and documentation checks |

## What this research established

1. **The procedural engine is the right execution foundation.** Reuse its ordered layers, stable identities, Brush eligibility, spacing scopes, bounded refill and publication path. Learning should initially choose settings and spatial recipes.
2. **The newest local system is not fully controllable through MCP.** Nine public tools exist. Policy 3 inspection is implemented; the existing mutation schemas remain policies 1/2. Rendering, Brush authoring and training are outside that public API.
3. **Artist comparisons need a persistent dataset.** Current execution records explicitly do not grant training eligibility. Neither the operation journal nor the performance recorder is an artist preference database.
4. **Rendering reliability comes before large generation batches.** Production rendering has prior successful evidence, but the reported Corona interactive-render restart loop remains unresolved. It must not produce aesthetic labels or an uncontrolled batch workload.
5. **Recent research supports the direction, with limits.** GardenDesigner is unusually close to this domain; 2026 preference research strengthens the case for personal profiles, informative comparisons and careful evaluation. None proves that Cyrus can learn professional landscape composition from a few clicks.

## Scope and evidence rules

The reviewed checkout is `codex/floating-layer-editor-0.7.1`, HEAD `addccb492a88292529594de81c287cc26e5ffe98`, with substantial tracked and untracked local work. The generated script identifies UI **0.7.1**. The source inventory contains **488 files**; it is an inventory rather than a build certificate. See [the audit](02_CODEBASE_AUDIT.md).

Evidence is labelled throughout:

- **Source fact:** observed in the current source at the captured fingerprint.
- **Fresh result:** executed during this research. The existing offline MCP suite passed **66 tests in 8.15 seconds**.
- **Recorded result:** an earlier report/receipt, with its original environment and limitations.
- **Research finding:** a claim by a linked paper or official documentation; no reproduction implied.
- **Proposal / hypothesis:** a Cyrus design choice or experiment that remains to be implemented and tested.

No model was trained or benchmarked, no Max runtime test was performed in this research, and no production source, licensing implementation, installer, artist scene or profile was changed. The first pass created this package and added its documentation-index paragraph; the second pass amends the package and that paragraph. The 66-test result is from the first pass, not a new second-pass runtime test. No commit or push is part of this work.

This package adds a current synthesis to [the 4 October ML planning](../Artist_Style_ML_2026-10-04/README.md) and [the September MCP/ML roadmap](../AI_MCP_ML_Roadmap_2026-09-30/README.md). Historical measurements and reports retain their original meaning. Future papers after 5 October 2026 are outside this review.
