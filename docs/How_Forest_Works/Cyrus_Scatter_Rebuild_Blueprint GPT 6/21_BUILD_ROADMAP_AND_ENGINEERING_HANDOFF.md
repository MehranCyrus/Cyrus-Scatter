# 21 — Build roadmap and engineering handoff

**Status: proposed implementation plan. Milestones are acceptance gates, not time estimates.**

## 1. Start with a vertical slice

The first useful result is a tiny complete scatter that can be authored, evaluated, displayed, saved, reopened, and rendered through a known route. It is not a complete engine with no host/output integration.

Use a plane, one cube source, a deterministic image grid, one include region, and a minimal command. Confirm units, pivots, IDs, save/load, and prototype reuse. This exposes fundamental SDK/output issues before they are buried under painting and Effects.

## 2. Proposed source tree

```text
src/
  model/           recipe, parameters, identities, authoring transactions
  core/            generators, selection, transforms, reference evaluator
  spatial/         surfaces, curves, fields, regions, occupancy indices
  evaluation/      dependency compiler, caches, jobs, publication
  host/max/        version adapters, snapshots, references, persistence, Undo
  viewport/max/    display resources, picking, overlays
  transport/pflow/ instance transport
  renderers/       qualified renderer-specific modules
  tools/           analyzer/edit adapters, assets, scene management
scripts/           MAXScript UI and workflow wrappers
schemas/           parameter, recipe, preset, command definitions
tests/
  core/            deterministic and randomized fixtures
  max/             host integration scenes/scripts
  renderers/       per-version output qualification scenes
  benchmarks/      measured workloads and reports
docs/              approved specifications and decision records
```

These are proposed paths. Map them to the actual repository after the audit; do not create redundant competing modules solely to match the names.

## 3. Milestone gates

### M0 — Baseline and integration risk

Audit the current repository and saved scene format. Pin a host/compiler target. Build a trivial Max plugin and qualify a minimal existing/new output route with one shared source and several instances. Produce an exact capability matrix and a read-only migration map.

**Exit:** known toolchain, safe isolated binary installation, existing-scene preservation, and a demonstrated path from logical instances to one renderer. Unknown renderer APIs are recorded as blocked integrations, not fake stubs presented as working features.

### M1 — Pure model and reference engine

Implement UUIDs, canonical candidate keys, random channels, unit/matrix conventions, recipe validation, and a simple full evaluator. Add source weights/Empty, image-grid generation, basic transforms, and naïve collision fixtures.

**Exit:** T01–T05, T20–T22, and identity/metamorphic tests pass without Max. Candidate IDs are independent of worker/page order.

### M2 — Host authority and persistence

Connect commands, host references, snapshots, Save/Load, Undo, basic display, and one renderer/transport adapter. Add scene lifecycle cancellation and diagnostics.

**Exit:** H03–H06/H08 and a basic R01 fixture pass. A scene rebuilds identically after all derived caches are deleted.

### M3 — Distribution and surface services

Implement Image options, progressive density, Path, Reference, XY/multiple-hit projection, UV/world-area modes, slope, altitude, and stable surface binding. Build shared receiver/curve preparation.

**Exit:** T07–T12 plus coordinate and topology tests pass. A steep terrain's density is explained by its selected domain rather than hidden compensation.

### M4 — Fields and ordered areas

Implement field types, map classification, curves, signed distances, contribution programs, spline/object/scatter/surface regions, local overrides, and point/footprint boundaries.

**Exit:** T13–T19 pass, including a large footprint enclosing a small exclusion. Linked definitions and local responses remain separate.

### M5 — Painting

Implement canonical projected tiles, brush resampling, effective pressure handling, working overlays, exact Undo deltas, contour conversion, and coalesced update requests. Then add the separately specified surface-attached backend.

**Exit:** T26–T29 and H01–H03 pass. Long history does not force replay for current-field queries. Stacked and topology-changing fixtures have explicit behavior.

### M6 — Source detail and exact occupancy

Complete source providers, atomic groups, maps/probability transforms, collision pair policies, accelerated full solver, and source/footprint updates. Add exact incremental conflict closure only after full solver equivalence is established.

**Exit:** T20–T23 pass across random seeds, cell sizes, and edit sequences. Local-update fallbacks preserve exactness.

### M7 — Persistent editing

Implement constrained overrides, pins, tombstones, manual items, picking, CS Edit command integration, attach/detach, and orphan recovery.

**Exit:** T24–T25 and selection/persistence tests pass. Moving one tree and changing density gives the documented result under both constrained and pinned modes.

### M8 — Production display and renderer completion

Complete retained point/mesh/proxy views, stable budgets, LOD, camera policies, materials, element masking where qualified, animation samples, and headless/farm paths. Certify each renderer capability separately.

**Exit:** T31–T34, H07–H08, and required R01–R08 fixtures pass for each advertised target. Unsupported capabilities remain visibly unavailable.

### M9 — Effects, collections, libraries, automation

Implement staged typed Effects, shared role-based collections, dynamic membership, portable recipes/assets, diagnostics, bulk commands, and command-based automation.

**Exit:** T30/T35–T40 and command equivalence tests pass. Imported data cannot bypass validation or execute arbitrary code implicitly.

### M10 — Migration and product release

Run side-by-side conversion on representative studio scenes. Resolve intended differences, finalize artist documentation, package dependencies, and publish exact compatibility/limitations.

**Exit:** migrated scenes reopen, rebuild, render, and retain authoring intent. Benchmark reports identify actual hardware and scene workloads.

### M11 — Companion modules

Implement ivy/growth and legacy/baking utilities under chapter 26's independent contracts. They reuse fields/surfaces/outputs but do not delay correctness fixes in the core.

## 4. Parallel work that is safe

After schemas and contracts stabilize, separate workstreams can implement surface preparation, fields/areas, viewport, and renderer spikes. They share fixtures and versioned interfaces. Do not let teams independently choose incompatible coordinate, ID, or ownership conventions.

One owner controls semantic stage order and persistent schemas. An interface change includes migration and test updates in the same review.

## 5. Ticket template

```text
Feature/control IDs:
Artist problem:
Proposed behavior and non-goals:
Input/output contracts:
Data ownership and persistence:
Algorithm and error cases:
Dependencies and dirty propagation:
Host/renderer capability requirements:
Tests to add before implementation:
Performance measurements:
Migration impact:
Definition of done:
```

A ticket saying “add painting” is too large. A ticket saying “canonical projected tile add/erase with exact before/after Undo and T26/T27” is executable.

## 6. Coding-agent handoff

Use a bounded task prompt such as:

> Read the applicable blueprint chapters and inspect the actual repository. Report the existing contracts relevant to this ticket. Implement only the named milestone/ticket, preserving existing scene behavior. Add failing tests first where practical. Do not invent SDK/renderer interfaces or replace unresolved behavior with silent fallbacks. Keep host scene access in qualified adapters. Demonstrate the reference/full result before optimizing. Report changed files, tests run, tests not run, known limitations, and migration effects. Do not mark renderer or Max behavior tested unless it was executed in that environment.

The agent should receive specific chapter/control/test IDs, not the instruction to implement the entire package in one uncontrolled patch.

## 7. Definition of done for every feature

Its control is validated and documented; the core behavior is tested; its interactions are tested; Undo/save/load work; invalidation is defined; diagnostics identify failure; supported outputs are qualified; and a performance measurement exists for relevant workloads. A visible checkbox is not completion.
