# Document register

All paths below are included in the common ZIP. Read the synthesis first; use originals to inspect the underlying evidence and corrections.

## Consolidated research

| Document | What it answers |
| --- | --- |
| [01 Findings and recommendation](../vegetation-interaction/01-FINDINGS-AND-RECOMMENDATION.md) | What is feasible, the recommended first scope, and what remains unproven |
| [02 Artist workflow](../vegetation-interaction/02-ARTIST-WORKFLOW.md) | Preparation, controls, Update, failure, reset and accepted placements |
| [03 Source preparation](../vegetation-interaction/03-SOURCE-PREPARATION.md) | Roots, guide frames, binding, source suitability and reconstruction |
| [04 Collision and solvers](../vegetation-interaction/04-COLLISION-AND-SOLVERS.md) | Contact envelopes, neighborhoods, initialization and solver choices |
| [05 Architecture and output](../vegetation-interaction/05-ARCHITECTURE-AND-OUTPUT.md) | Ownership, invalidation, native boundaries, renderer and Bake delivery |
| [06 Houdini and tyFlow](../vegetation-interaction/06-HOUDINI-AND-TYFLOW.md) | Relevant workflows, recipe limitations and transferable ideas |
| [07 Validation plan](../vegetation-interaction/07-VALIDATION-PLAN.md) | Experiments, scene matrix, measurement and acceptance evidence |
| [08 Engineering guidelines](../vegetation-interaction/08-ENGINEERING-GUIDELINES.md) | Rules for bounded, deterministic, reviewable implementation |
| [09 Evidence and open questions](../vegetation-interaction/09-EVIDENCE-AND-OPEN-QUESTIONS.md) | Corrections, confidence and unresolved decisions |

Reading editions: [HTML](../vegetation-interaction/handbook.html) and [52-page PDF](../vegetation-interaction/handbook.pdf). These contain the synthesis; they do not replace the preserved source collection.

## Working guidelines and evidence

| File or collection | Purpose |
| --- | --- |
| [Asset audit](../vegetation-interaction/checklists/ASSET-AUDIT.md) | Inspect real assets before promising automatic preparation |
| [Validation matrix](../vegetation-interaction/checklists/VALIDATION-MATRIX.md) | 68 Pending cases; prototype tests must report their actual coverage |
| [Decision experiments](../vegetation-interaction/checklists/SOLVER-DECISION-EXPERIMENTS.md) | Eight Pending comparisons; no engine decision follows merely from report agreement |
| [Recipe comparison](../vegetation-interaction/checklists/RECIPE-COMPARISON.md) | Corrected workflow comparison |
| [Experiment record](../vegetation-interaction/checklists/experiment-record.json) | Exact build, input, initialization, measurements and limitations |
| [Primary sources](../vegetation-interaction/references/PRIMARY-SOURCES.md) | P01–P57 reference register and verification scope |
| [Original source register](../vegetation-interaction/sources/README.md) | R01–R14, provenance, relationships and exact preserved names |
| [Original manifest](../vegetation-interaction/sources/manifest.json) | Sizes and SHA-256 for all fourteen originals and six associated artifacts |
| [R11 evidence review](../vegetation-interaction/references/R11-evidence-review.json) | Source preparation archive and public topology checks |
| [R12 source review](../vegetation-interaction/references/R12-source-review.json) | Exact engine pin and inspected source boundary |
| [R13 evidence review](../vegetation-interaction/references/R13-evidence-review.json) | Reported native results, build profile and reproduction archive limits |
| [R14 evidence review](../vegetation-interaction/references/R14-evidence-review.json) | Final native/analytic records, callback and lifetime boundaries |
| [Library verification](../vegetation-interaction/VERIFICATION.md) | Documentation integrity and visual review; no solver qualification |

`sources/originals/` preserves every supplied HTML, Markdown, CSV and PDF file. `sources/evidence/` preserves the R11/R13/R14 archives and extracted result JSONs. Nothing in those archives has been promoted to a local execution receipt.

## Implementation packet

| Document | Purpose |
| --- | --- |
| [Workflow](WORKFLOW.md) | Three independent jobs and local integration gates |
| [Shared contract](SHARED-CONTRACT.md) | Normative units, status, lifetime, geometry and acceptance semantics |
| [Frozen C++ header](starter/include/cyrus_vegetation/prototype_v1.hpp) | Common declarations only |
| [Fixture catalog](fixtures/catalog.json) | Authored inputs, positive controls and required negative cases |
| [Prompt A](PROMPT-A-COLLISION.md) | Collision kernel and snapshot ownership |
| [Prompt B](PROMPT-B-FITTER.md) | Rooted static guide fitting |
| [Prompt C](PROMPT-C-DELIVERY-VALIDATION.md) | Ribbon evaluation and independent visible-surface validator |
| [Return checklist](RETURN-CHECKLIST.md) | Source, build/test evidence and known limitations |
| [Return manifest template](return-manifest.template.json) | Machine-readable handback identity and file list |
| [Frozen-file manifest](FROZEN-FILES.json) | Hashes identifying the shared edition |

Recommended order for all implementers: this register → research 01/03/04/05/07/08/09 → shared contract → assigned prompt → fixtures. Read research 02 and 06 for artist intent and workflow context. Inspect the R11–R14 reviews and relevant originals before relying on their technical findings.

## Context snapshots in the ZIP

Selected repository files preserve direct research links: the engineering foundation, agent workflow, documentation policy, placement store, mesh display source, and PhysicsLab README/Jolt source/build script. They are read-only context, not an SDK, full checkout, or permission to modify unrelated systems. Their transitive includes and historical navigation may require the full repository. `CONTEXT-SNAPSHOT.json` records exact source hashes, branch, HEAD and the dirty-worktree scope at packaging time.
