# Cyrus Scatter: procedural evaluation implementation guide

4 October 2026 · Research and design proposal for **0.7 pre-release** · Initial source baseline: `e3518f8f87f3144d531f20afbb6790ce243f2cfc`; follow-up review: `53bfc5d1c76929958dbeb29f5d4c746b2321d0ac`

**Implementation follow-up:** the [0.7 implementation record](../Procedural_Implementation_0.7_2026-10-04/README.md) records the candidate built from this design. The subsequent [Max 2027 runtime report](../Procedural_Implementation_0.7_2026-10-04/RUNTIME_REPORT.md) covers completed isolated qualification and remaining release gates. The investigation/evidence below describes the earlier baseline and is preserved as historical research.

**Build on the existing engine: make ownership, execution order, spacing rules and cache dependencies explicit.** Preserve the current Brush data, stable candidate identities, protected artist edits and fast display paths. Implement the three independent collision scopes and the two fill behaviors before adding a general graph editor, GPU placement or ML.

This package answers how the plugin should behave, what already exists, what is missing, where implementation belongs and how to qualify it. It does **not** implement the proposal. No production source, installed plugin or Max scene was changed for this investigation. The follow-up [readiness review](10_READINESS_REVIEW.md) adds fresh pure-native/MCP tests and isolated probes. Those checks are not Max runtime qualification or a new FPS measurement.

## The intended experience

An artist creates a **Garden** layer containing **Red flowers**, **Blue flowers**, **Yellow flowers** and **Grass** sets. Each set owns its assets and coverage. The layer supplies shared defaults. The artist can:

- Set spacing inside Red flowers independently of spacing between Red and Blue.
- Let Grass grow close to flowers while keeping trees farther apart.
- Change a source's spacing radius or override an individual plant without resizing its geometry.
- Place Grass after the flower sets and fill available gaps, or restrict Grass to outside their painted coverage.
- Request replacement candidates when collisions reduce the population, subject to explicit work limits.
- Move, erase or disable a plant/set and have only the affected procedural results reconsidered.
- Navigate the viewport using the last completed display buffers; camera movement does not regenerate planting.

The same model applies to multiple ordered layers. Earlier ordinary results constrain later results. Authored, protected edits are explicit input constraints and may take precedence over this ordinary order.

## Decisions carried forward from the discussion

| Requirement | Contract in this proposal |
| --- | --- |
| Procedural, understandable top-to-bottom behavior | Persist layer order and set order; execute dependency stages in that precedence, with caching at useful boundaries |
| Three collision levels | Between layers; between sets in one layer; within one set |
| Adjustable point radius | Radius is data used by each applicable spacing rule, not another collision stage |
| Two fill behaviors | Background fill and target replenishment are separate controls and algorithms |
| Reusable data | Save authoring state and identities; reuse immutable evaluated buffers; optional disk snapshots come later |
| Keep performance already achieved | Retained Point Cloud/Mesh and cached Proxy drawing remain the display baseline |
| Artist control | Brush history, inclusion/exclusion, explicit order, protected edits, Undo and manual Update remain first-class |

The implementation details below are **recommended engineering choices**, not claims that the user has approved every new default. In particular, numeric refill limits need measurement before release. Existing scenes keep their current policy until explicitly converted.

## Read in this order

| Document | What it establishes |
| --- | --- |
| [01 — Current code and gaps](01_CURRENT_CODE_AND_GAPS.md) | Verified implementation, strengths, limitations and exact integration points |
| [02 — Procedural pipeline](02_PROCEDURAL_PIPELINE.md) | Ownership, dependency order, layer transactions, cleanup and publication |
| [03 — Collision and radius](03_COLLISION_AND_RADIUS.md) | Three scopes, radius formula, spatial metrics, protected edits and solver contract |
| [04 — Coverage, population and fill](04_COVERAGE_POPULATION_AND_FILL.md) | Paint overlap, candidate budgets, final targets, background fill and bounded replenishment |
| [05 — Cache and viewport](05_CACHE_AND_VIEWPORT.md) | Cache keys, invalidation matrix, memory, threading and display preservation |
| [06 — Data, UI, MCP and ML](06_DATA_UI_MCP_AND_ML.md) | Persistent schema, minimal controls, statistics, automation and future learning |
| [07 — Implementation roadmap](07_IMPLEMENTATION_ROADMAP.md) | Ordered coding tasks, dependencies, scope boundaries and release gates |
| [08 — Validation and experiments](08_VALIDATION_AND_EXPERIMENTS.md) | Numerical oracles, lifecycle scenarios, performance comparisons and acceptance criteria |
| [09 — Research and decisions](09_RESEARCH_AND_DECISIONS.md) | Primary sources, alternatives, remaining experiments and evidence limitations |
| [10 — Readiness review](10_READINESS_REVIEW.md) | Fresh checks, corrected assumptions, confidence and remaining qualification gates |
| [11 — Option contracts](11_OPTION_CONTRACTS.md) | Control ownership, Base versus child sets, switches, identity, eligibility and fill interactions |

Initial historical evidence: [source snapshot](evidence/source_snapshot.json), [documentation verification](evidence/verification.json). Follow-up evidence: [readiness campaign](evidence/readiness/README.md). Keep these scopes distinct from future implementation tests.

## What changes in our understanding

The current plugin is already procedural in important ways. It caches prepared populations and a completed result, preserves candidate keys, resolves accepted blockers and keeps display data separate. A rewrite would discard useful work.

However, three independent artist-facing collision scopes do not yet exist. Self-spacing and sibling-set spacing share one layer radius. Whole-controller cache keys remain broad. Paint weights allocate candidates before coverage; they do not promise a final population or refill. Current execution priorities are also not a reliable substitute for a visible, editable top-to-bottom order.

Adopting Houdini's dependency reasoning means knowing **which input invalidates which result**. It does not require calculating every stage on every change, saving every intermediate forever, or recreating Houdini's node editor.

The follow-up tightens identity/random-channel stability, support-anchor versus mesh-origin semantics, active Edit reservations, fixed logical refill schedules, policy dispatch and presentation-only cache inputs. The design is ready for P0–P2 implementation; refill quality/defaults and host integration still have explicit experiment gates.

## First coding delivery

Start with an opt-in policy that separates the three spacing scopes, carries effective radii through the existing native solver, exposes stable order and reports rejection reasons. Preserve current output under the existing policy. Prove the new rules with tiny fixtures before adding background fill and bounded refill; then narrow invalidation with measured cache counters.

The expected gain is more predictable planting, fewer unnecessary recalculations and clearer performance diagnostics. Unlimited density, zero drawing cost, exact mesh collision from spheres, and guaranteed full targets on impossible sites are not deliverables.

## Relationship to existing documents

This is the current proposal for the **next procedural evaluation policy**. It supplements the shipped [1.2 capability map](../Layers_First_2026-10-03/CAPABILITIES.md), the [1.1 planting-group implementation](../Planting_Groups_2026-10-03/REPORT.md), the [Brush design](../Brush_Tool_2026-10-02/README.md) and the [retained Mesh baseline](../Retained_Mesh_Preview_2026-10-02/README.md). Their dated measurements remain unchanged.

The separate [Artist Style ML guide](../Artist_Style_ML_2026-10-04/README.md) describes how a future design companion could propose recipes. This package defines how those recipes would be evaluated consistently. The procedural changes do not depend on ML.
