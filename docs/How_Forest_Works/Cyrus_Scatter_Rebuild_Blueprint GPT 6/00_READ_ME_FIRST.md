# CYRUS SCATTER — Complete rebuild blueprint

**Prepared for Amin / Cyrus Studio · October 13, 2026 · Blueprint 1.0 / proposed CyrusV1 behavior**

## What this package contains

This is a detailed plan for independently rebuilding the capabilities discussed in your ForestPack research as a coherent Cyrus Scatter system. It contains **26 chapters**, approximately **37,742 words in those chapters**, a **301-entry control/command catalog**, a build roadmap, test fixtures, and an executed mathematical reference suite.

It explains what each system owns, how its controls combine, the selected algorithms and data contracts, update rules, failure cases, persistence, host integration, and how to prove that an optimization preserves the result.

**This is a selected implementation design, not ForestPack's private source code and not a completed Max plugin.** It does not claim an exhaustive one-to-one audit of every historical ForestPack checkbox. It specifies the research's major feature families and clearly separates companion growth/legacy modules.

The original `Research Forest 2.md` is preserved unmodified in `sources/`. Chapter 25 records evidence, primary-source URLs, and deliberate refinements. Defaults in chapter 22 are **proposed Cyrus defaults**, not copied vendor values or verified existing Cyrus values.

## The system in one view

```text
ARTIST AUTHORING INSIDE 3DS MAX
    setup / layers / sources / receivers / ordered areas / paint / edits
                              |
                 commands + Undo + scene references
                              |
                   owned immutable input snapshots
                              |
HOST-INDEPENDENT NATIVE ENGINE
    geometry preparation + surfaces + fields + canonical placement providers
                              |
    eligibility -> species -> transforms -> edits -> final gates -> collisions
                              |
                    immutable final population
                       /        |        \
              viewport       render      selection / export
              and LOD        adapters    and diagnostics
                              |
                qualified Particle Flow / native renderer routes
```

The artist owns an editable recipe. The core owns a reproducible evaluation of that recipe. Outputs own representations, not competing definitions of where plants belong.

## The most important selected contracts

**Identity survives performance changes.** Canonical placement addresses are separate from worker partitions and cache tiles. Independent random channels prevent tint edits from changing rotation.

**Painting stores region intent.** Projected and surface-attached backends have separate promises. Canonical coverage, brush overlays, generated candidates, and accepted plants are independently inspectable.

**Optimized collisions must match the reference solve.** Start with a full deterministic solver. An old/new conflict-component update can be exact under stated assumptions; an arbitrary fixed halo cannot guarantee that.

**Manual edits have an explicit policy.** Constrained overrides obey procedural eligibility. Pins persist across coverage/density changes and occupy space before ordinary candidates. Orphan handling is visible.

**The viewport is not the final population.** Preview budgets, LOD, and presentation do not secretly change authoring. Final rendering evaluates current authority unless a deliberate frozen output was selected.

**Existing Cyrus integrations are audit targets, not automatic demolition targets.** Keep the C++/MAXScript division and qualify CS Edit, Surface Analyzer, persistent schemas, and Particle Flow transport against the new contracts. This task did not inspect or modify the repository.

## Choose a reading route

For the overall design, read **01 → 02 → 03 → 04 → 21**. This establishes scope, ownership, identities, evaluation, and build order.

For the most interconnected feature system, read **05 → 06 → 08 → 09 → 11 → 12**. This explains receiving surfaces, fields, areas, painting, exact collision behavior, and persistent editing.

For production output, read **13 → 14 → 15 → 17**. Renderer feasibility must be tested early, even though advanced output completion comes later.

For implementation tickets, use **22** for control IDs, its linked algorithm chapters, **20** for tests, and **21** for acceptance gates. Read **23** before changing a foundational policy. Read **25** before making a vendor-parity claim.

## Chapter index

| Chapter | File |
|---|---|
| 01 | [01 — Product scope and behavioral contract](01_PRODUCT_SCOPE_AND_BEHAVIOR.md) |
| 02 | [02 — System architecture and execution order](02_SYSTEM_ARCHITECTURE.md) |
| 03 | [03 — Data contracts, stable identity, and deterministic randomness](03_DATA_IDENTITY_AND_RANDOMNESS.md) |
| 04 | [04 — Evaluation, caching, concurrency, and incremental correctness](04_EVALUATION_CACHING_AND_CONCURRENCY.md) |
| 05 | [05 — Surfaces, coordinates, projection, and geometric queries](05_SURFACES_COORDINATES_AND_GEOMETRY.md) |
| 06 | [06 — Fields, maps, curves, and falloffs](06_FIELDS_MAPS_CURVES_AND_FALLOFFS.md) |
| 07 | [07 — Distribution generators and species selection](07_DISTRIBUTION_AND_SPECIES_SELECTION.md) |
| 08 | [08 — Ordered areas, exclusions, overrides, and boundaries](08_ORDERED_AREAS_EXCLUSIONS_AND_BOUNDARIES.md) |
| 09 | [09 — Painting: authoring, representation, Undo, and responsive updates](09_PAINTING_AUTHORING_UNDO_AND_INCREMENTAL_UPDATES.md) |
| 10 | [10 — Sources, transforms, probability controls, and groups](10_SOURCES_TRANSFORMS_AND_GROUPS.md) |
| 11 | [11 — Collisions, spacing, and exact incremental solving](11_COLLISIONS_SPACING_AND_EXACT_INCREMENTAL_SOLVING.md) |
| 12 | [12 — Manual editing, persistent overrides, and CS Edit integration](12_MANUAL_EDITING_AND_CS_EDIT.md) |
| 13 | [13 — Viewport, picking, camera policies, and LOD](13_VIEWPORT_PICKING_CAMERA_AND_LOD.md) |
| 14 | [14 — Renderer adapters and Particle Flow transport](14_RENDERER_AND_PARTICLE_FLOW_INTEGRATION.md) |
| 15 | [15 — Materials, element boundaries, and animation sampling](15_MATERIALS_EDGE_TRIMMING_AND_ANIMATION.md) |
| 16 | [16 — Effects and procedural extensibility](16_EFFECTS_AND_PROCEDURAL_EXTENSIBILITY.md) |
| 17 | [17 — Max host integration, persistence, collections, and assets](17_MAX_HOST_PERSISTENCE_COLLECTIONS_AND_ASSETS.md) |
| 18 | [18 — Artist UI, commands, and automation](18_ARTIST_UI_COMMANDS_AND_AUTOMATION.md) |
| 19 | [19 — Existing Cyrus integration and migration](19_EXISTING_CYRUS_INTEGRATION_AND_MIGRATION.md) |
| 20 | [20 — Verification fixtures, reference outputs, and benchmarks](20_VERIFICATION_FIXTURES_AND_BENCHMARKS.md) |
| 21 | [21 — Build roadmap and engineering handoff](21_BUILD_ROADMAP_AND_ENGINEERING_HANDOFF.md) |
| 22 | [22 — Proposed control and command catalog](22_CONTROL_CATALOG.md) |
| 23 | [23 — Decisions, risks, and unresolved evidence](23_DECISIONS_RISKS_AND_OPEN_QUESTIONS.md) |
| 24 | [24 — Worked production scenario: a terraced architectural garden](24_WORKED_PRODUCTION_SCENARIO.md) |
| 25 | [25 — Sources, evidence, and provenance](25_SOURCES_AND_EVIDENCE.md) |
| 26 | [26 — Companion features: growth, billboards, baking, and scene management](26_COMPANION_FEATURES_AND_SCOPE_EXTENSIONS.md) |

## Additional files

| File | Purpose |
|---|---|
| [examples/README.md](examples/README.md) | How to run and interpret the reference examples |
| [examples/reference_oracle.py](examples/reference_oracle.py) | Executable mathematical reference and checks |
| [examples/reference_validation.json](examples/reference_validation.json) | Saved actual execution results |
| [examples/control_catalog.json](examples/control_catalog.json) | The 301 proposed controls/commands as structured data |
| [examples/source_registry.json](examples/source_registry.json) | Source URLs and qualification status |
| [sources/Research Forest 2.md](sources/Research%20Forest%202.md) | Original uploaded research, unmodified |

A separate combined Markdown edition is delivered alongside the ZIP for reading or searching the chapters in one file. The ZIP is the self-contained modular package, including examples and the original research.

## What has been validated here

All **12** pure-Python reference check groups pass. That includes **240** grid-versus-naive collision comparisons and **600** incremental-versus-full comparisons, plus keyed randomness, ordered contributions, weighted selection, paint arithmetic, probability-curve sampling, and edge cases.

The original research copy has been byte-compared with the upload. The packaged chapter links, source references, control IDs, test-ID references, and Markdown fences are checked by the delivery validation.

**Not executed:** Max plugin builds, host Undo/save/load, real receiver painting, GPU display, renderer integration, farm rendering, or production performance benchmarks. Those are explicit milestones and fixtures, not hidden omissions presented as completed work.

## How to start the rebuild

Do not hand the whole book to a coding agent as one implementation request. Start with the M0 read-only repository inventory and renderer-transport feasibility check. Freeze the persistent IDs, coordinate conventions, and module interfaces. Then implement one vertical slice with a source, receiver, canonical placements, display, save/open, and a real qualified render.

Next add feature systems in the chapter 21 order, with the reference fixtures in place before incremental optimization. Every completed feature needs its own command behavior, invalidation rule, Undo/persistence treatment, supported-output status, and demonstrated tests.

A complete rebuild is the destination. A sequence of independently verifiable modules is how to reach it without losing the artist's scene intent.
