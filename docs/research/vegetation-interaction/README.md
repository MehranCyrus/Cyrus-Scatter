# Vegetation interaction research library

**CyrusScatter | Consolidated 24 October 2026 | Research and proposed design**

This library organizes all fourteen original research files supplied in this conversation, including the final R14 study and R11/R13/R14 evidence packages. It turns their overlapping findings into a usable decision set while preserving every original, including earlier claims that need correction. Related formats/studies are not independent replications. It does not establish implemented vegetation contact, authorize development, or qualify a release.

**Recommended direction:** prototype a bounded, one-way static fit for prepared rooted grass against explicit fixed obstacles. Preserve accepted placements and source assets, solve all relevant contacts together, and prove the visible mesh through viewport, render and Bake before pursuing scale. Rigid settling and deformable leaf draping are separate workstreams.

Open the [reading edition](handbook.html) for navigation, or the [PDF handbook](handbook.pdf) for sharing. The numbered Markdown documents are the editable source of both editions. Original research remains in [sources/originals](sources/README.md).

## Document register

| Document | Purpose | Primary reader |
| --- | --- | --- |
| [01 Findings and recommendation](01-FINDINGS-AND-RECOMMENDATION.md) | Feasibility, scope, evidence strength and recommended first experiment | Product and engineering |
| [02 Artist workflow](02-ARTIST-WORKFLOW.md) | Preparation, controls, Update, Manual/Live, failure and reset behavior | Artist and product |
| [03 Source preparation](03-SOURCE-PREPARATION.md) | Representation tiers, roots, frames, bindings and source acceptance | Asset pipeline and geometry engineering |
| [04 Collision and solvers](04-COLLISION-AND-SOLVERS.md) | Neighborhoods, collision envelopes, initialization and numerical comparisons | Simulation engineering |
| [05 Architecture and output](05-ARCHITECTURE-AND-OUTPUT.md) | Current source boundaries, proposed data ownership, invalidation and geometry delivery | Plugin engineering |
| [06 Houdini and tyFlow](06-HOUDINI-AND-TYFLOW.md) | Corrected workflow comparison and how to use the latest recipes | Technical artist and research |
| [07 Validation plan](07-VALIDATION-PLAN.md) | Bounded prototype gates, scene matrix, measurements and evidence requirements | Engineering and QA |
| [08 Engineering guidelines](08-ENGINEERING-GUIDELINES.md) | Reviewable guidelines for a later authorized implementation | Implementer and reviewer |
| [09 Evidence and open questions](09-EVIDENCE-AND-OPEN-QUESTIONS.md) | Corrections, confidence, missing artifacts and unresolved choices | All readers |
| [Source register](sources/README.md) | Fourteen preserved originals, relationships, provenance, embedded evidence and hashes | Research and audit |
| [Verification receipt](VERIFICATION.md) | Checks performed on this documentation package and their limits | Handoff and maintenance |

All nine numbered documents have the same status: **consolidated research with explicitly proposed product/engineering choices**. Their statements about current source are separately scoped to the recorded working-tree snapshot. Existing repository contracts remain authoritative.

## Suggested reading paths

- Product discussion: 01, 02, 09.
- Asset preparation: 03, the asset audit template, then 07.
- Implementation planning: 01, 04, 05, 08, then 07.
- Vendor recipe reproduction: 06, R09/R10, then the experiment record template.

## Working files

| File | Use |
| --- | --- |
| [Validation matrix](checklists/VALIDATION-MATRIX.md) | Proposed tests with explicit pending status |
| [Solver decision experiments](checklists/SOLVER-DECISION-EXPERIMENTS.md) | Eight bounded Pending comparisons from R12, refined by R13/R14's report-local gates and mapped to the shared matrix |
| [Asset audit template](checklists/ASSET-AUDIT.md) | Record actual library suitability before promising automatic preparation |
| [Corrected recipe comparison](checklists/RECIPE-COMPARISON.md) | Short planning matrix; preserves the earlier supplied CSV separately |
| [Experiment record](checklists/experiment-record.json) | Capture exact versions, initialization, measurements and artifacts |
| [Primary reference register](references/PRIMARY-SOURCES.md) | External references and verification scope |
| [Repository snapshot](references/repository-snapshot.json) | Branch, HEAD and hashes of inspected local source |
| [Original manifest](sources/manifest.json) | Byte counts, SHA-256 hashes and original locations |
| [R11 evidence review](references/R11-evidence-review.json) | Archive integrity, supplied result records and independently recounted public topology |
| [R11 evidence archive](sources/evidence/CyrusScatter_Source_Preparation_Evidence.zip) | Exact embedded archive, including public assets, fixtures, scripts, license and reported checks |
| [R12 source review](references/R12-source-review.json) | Exact dependency pin, eleven checked local/public source hashes, findings and limits |
| [R13 evidence review](references/R13-evidence-review.json) | Reported headless results, archive/member checks, 48 local source-hash matches and execution limits |
| [R13 reproduction archive](sources/evidence/cyrus_jolt_reuse_reproduction.zip) | Exact embedded harness, build recipe, result records, source ledger, provenance and license; archived without execution |
| [R13 reported results](sources/evidence/cyrus_jolt_probe_results.json) | Exact embedded final JSON, identical to the archive member |
| [R14 evidence review](references/R14-evidence-review.json) | Reported native/analytic records, archive/provenance checks, 49 local source matches and precise limits |
| [R14 evidence archive](sources/evidence/R14/Cyrus_Collision_Research_Evidence.zip) | Exact final-study ZIP: code, logs, provenance, source excerpts, results and license; archived without execution |
| [R14 native results](sources/evidence/R14/harness_results.json) | Exact archive member copy; seven reported records in a distinct single-precision CPU profile |
| [R14 analytic results](sources/evidence/R14/analytic_results.json) | Exact archive member copy; nine fixture expectations/fifteen stored checks, separate from physics execution |

## Final submission and synthesis

R14 is incorporated into Chapters 01, 02, 04, 05 and 07-09. Its three-point rod, callback boundary, query-generation ownership and transient-ejection cases refine the same narrow recommendation: reuse suitable rigid/collision infrastructure, test an owned static response for prepared rooted guides, and compare alternatives only at equivalent visible acceptance. R13's tiny-scale, far-origin and rigid-residual observations retain their different build/evidence scope.

The research set now tracks 68 Pending validation cases and eight focused decision experiments. The smallest future commitment is a known-feasible guide/stone contact response with independent root angle, followed by width/two-stone checks and actual output parity. The authored viewport/render/Bake feasibility gate stays early. No production solver has been adopted or independently run here; the complete supplied research collection is organized and preserved.

## Maintenance and authority

The repository [engineering foundation](../../ENGINEERING_FOUNDATION.md), [agent workflow](../../AGENT_WORKFLOW.md) and [documentation policy](../../DOCUMENTATION.md) govern later engineering. This folder owns research synthesis, proposed interaction behavior and the experiment plan. It creates no parallel execution ledger and changes no release or roadmap status.

When another study arrives, preserve it under a new source ID, compare its claims against the correction register, and update only the affected chapters. Agreement among reports is not independent experimental confirmation. Keep proposed thresholds, authored examples, document inspections and executed tests distinguishable. Update the Markdown first and regenerate the reading editions using [the build script](tools/build_handbook.py).
