# 01 — Product scope and behavioral contract

**Cyrus Scatter rebuild blueprint · Proposed specification v0.1 · 13 October 2026**

## 1. What we are rebuilding

Build an independently implemented, artist-directed scattering system for 3ds Max. Its feature scope comes from the supplied *ForestPack Deep Technical Study*: sources, Image/Path/Reference/Particle distribution, ordered areas, painting, surfaces, falloffs, clustering, transformations, spacing, boundaries, local edits, display, rendering, materials, animation, Effects, shared collections, and reusable presets. The original study is preserved in `sources/Research Forest 2.md` [R0, §§1–13].

The objective is functional capability and understandable interactions, not identical private code, identical random layouts, copied assets, or a duplicate interface. A ForestPack feature name describes the research target. A **Cyrus decision** describes how the rebuilt system will behave. They are not interchangeable.

This package is a proposed implementation specification, not a current-code audit. No Cyrus repository was read for this task, no Max scene was changed, and no renderer integration was exercised. Existing Cyrus architecture described in project context—native C++, MAXScript orchestration, a persistent controller, Surface Analyzer, CS Edit, and Particle Flow render transport—is treated as an integration constraint to investigate, not proof that any current code implements this design.

## 2. Three levels of completion

**Capability parity** means the artist can solve the same category of problem. A curved planted strip, a species patch, or an individually moved tree should be expressible.

**Behavioral compatibility** means a named operation reproduces a measured rule: ordering, units, filtering, projection, persistence, and difficult combinations. Compatibility can be claimed only for an identified product version and test fixture.

**Numerical identity** means matching every position or random choice. This is not a general objective. A different deterministic generator can provide equivalent capability without identical samples.

Do not use an attractive screenshot as evidence for the latter two levels. Conversely, do not reject an otherwise useful design merely because its random tree arrangement differs.

## 3. Scope tiers without silently dropping features

| Tier | Included work | Completion rule |
|---|---|---|
| Foundation | Host-independent engine, identities, coordinates, snapshots, reference evaluator, persistence, cancellation | Deterministic fixtures and save/load tests |
| Core authoring | Sources, Image/Path/Reference generators, XY and UV placement, areas, paint, transforms, collisions, editing | Documented controls and combination tests |
| Production output | Retained viewport, picking, PFlow bridge, qualified renderer adapters, materials, LOD, animation | Per-host/per-renderer capability evidence |
| Advanced relationships | Effects, collections, linked fields, external generators, portability, automation | Dependency and recovery tests |
| Companion scope | Ivy/growth, legacy billboard shadows, baking utilities, scene lister | Explicitly separate modules; see chapter 26 |

A tier is sequencing, not permission to describe unimplemented features as supported. Every feature remains visible in the control catalog and release matrix.

## 4. Proposed product model

A **Scatter Setup** is one persistent scene-level controller. It owns layers, links, asset assignments, and shared settings. A **Layer** owns one procedural population recipe. It references source collections, a receiver set, distribution settings, and an ordered area program. A **Paint Set** owns editable coverage independent of the current plants. An **Instance Edit Set** owns sparse overrides and independent manual items.

A source mesh does not belong to a paint stroke. A camera does not own the authoritative population. A renderer does not decide candidate identity. These ownership boundaries keep scene changes comprehensible.

Separate collections by role:

- A source-choice collection contains alternatives.
- A compound source contains components that form one arrangement.
- A receiver collection contains meshes that can receive placements.
- A region collection contains area definitions.

The same Max nodes may be referenced by several roles, but the roles are explicit in the data and UI.

## 5. The five artist promises

### Predictability

Changing tint must not reshuffle locations. Reordering a list for display must not silently reseed a layer. Geometry changes may legitimately alter collisions; the UI explains that dependency.

### Durable intention

Paint describes coverage. A manual override describes an edit to an identified candidate. Neither is thrown away merely because preview quality changes. A topology change can invalidate an attachment; report it rather than inventing a new attachment silently.

### Honest interaction

Brush feedback is separate from exact population completion. During recomputation, show the last complete population and an “Updating” state. Do not label a partial or stale population as final.

### Reproducible outputs

Saving and reopening the same authoritative state under the same engine/version/profile reproduces the same canonical accepted IDs. Rendering uses that state, not whatever subset happens to be visible in a viewport.

### Explainable cost

Expose candidate counts, gate rejections, collision rejections, cache use, stage timings, and output cost. An increase in candidates is not presented as an increase in plants.

## 6. Behavior selected now

| Issue | Proposed Cyrus default |
|---|---|
| Area order | Bottom-to-top contribution program; an exclusion affects earlier contributions only |
| Overlapping includes | Independent contributions; duplicates are possible and visible; optional union mode is a separate operation |
| Default brush | Receiver-scoped projected region paint; canonical fixed-resolution coverage tiles |
| Curved/deforming paint | Separate surface-attached backend, not a silent interpretation of XY paint |
| Collision reference | Deterministic globally ordered greedy acceptance with explicit pinned obstacles |
| Incremental collisions | Full collision solve first; exact old/new dependency closure before enabling local optimization |
| Edited procedural item | Constrained override unless explicitly pinned |
| Pinned item | Bypasses procedural coverage/density, occupies space before ordinary candidates; invalid bindings still reported |
| Renderer fallback | Explicit bounded fallback, never automatic unlimited mesh expansion |
| Unknown map/API behavior | Unsupported or main-thread-only until a capability test establishes a safe route |
| Candidate identity | Semantic sampling address; never worker index, cache tile, array position, or pointer |
| Undo | One authoring transaction per stroke/edit gesture; caches are derived and not authored state |

ForestPack documents bottom-to-top area processing; its exact paint and transform combinations still require version-specific testing [S01]. The rest of this table is a **Cyrus design decision**, not a disclosure of ForestPack internals.

## 7. Compatibility policy

Use `behaviorProfile = CyrusV1` as the default. A future compatibility profile must name measured differences, not promise broad “Forest mode.” Examples are a specific translation/boundary order or a particular projected-image sampling convention.

A profile is part of the recipe and cache keys. Loading a recipe never silently switches profiles when the engine updates. New defaults apply to new recipes, not existing scenes.

Existing Cyrus scenes retain their original engine/version until explicitly converted. Rebuilding the implementation does not justify changing a client's completed planting layout on load.

## 8. Invalid input policy

The command layer rejects NaN, infinity, invalid dimensions, negative weights, and unsupported enum combinations before scheduling work. Empty source lists, zero total weight, missing receivers, and degenerate regions produce explicit states rather than crashes.

An absent source asset is not an intentional `Empty` source. Preserve the missing source's identity and show a diagnostic proxy; do not redistribute its weight or substitute a random asset.

Choose conservative behavior for destructive ambiguity. Unresolved topology attachments become inactive or retain an explicitly labeled frozen position according to the saved policy. Never rebind them merely to hide a warning.

## 9. How to read the rest

Chapters 02–04 define architecture, data, and execution. Chapters 05–12 define the placement and authoring systems. Chapters 13–18 explain output, integration, and interaction. Chapters 19–24 turn the design into tests, implementation work, control specifications, and production scenarios. Chapter 25 records sources and evidence limits; chapter 26 bounds companion features.

Defaults in this package are **proposed Cyrus values**. They are not asserted ForestPack defaults and do not constitute a verified inventory of every historical ForestPack control.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S01]: https://docs.itoosoft.com/forestpack/forest-plugin/areas
