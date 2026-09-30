# 01 — Current Cyrus automation audit

**Status: VERIFIED IN CURRENT CODE unless a row explicitly states a proposal or uncertainty.**
Review date: 2026-09-30. Method: targeted source tracing, relevant documentation review and retained-test inspection. This is not exhaustive runtime or security certification.

## Current architecture

~~~mermaid
flowchart TD
  G["UI generator stages and templates"] --> S["Generated MAXScript controller and rollouts"]
  S --> B["Max bridge: nodes, meshes, maps, arrays"]
  B --> N["Native scatter, spacing, falloff and orientation"]
  N --> P["Transforms and source indices"]
  P --> E["CS Edit modifier stack"]
  E --> V["Native point and geometry preview"]
  E --> R["MAXScript PFlow render transport"]
  A["Surface Analyzer script and native engine"] --> S
  S --> C["Scene parameter blocks and references"]
  E --> D["Native edit save/load chunks"]
~~~

Sources: [controller](../../AminScatter/scripts/AminScatterObject.ms), [generator](../../AminScatter/tools/ui/generate.cjs), [native header](../../AminScatter/include/scatter.h), [bridge](../../AminScatter/src/max_bridge.cpp), [Analyzer script](../../CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms), [PFlow template](../../AminScatter/tools/ui/templates/pflow.ms).

There is no stable provider-neutral automation API or MCP server in the inspected product source. Low-level scriptability is substantial; safe agent automation still requires a new boundary.

## Operation inventory

Anchors below are source symbols and approximate lines in this review's hash snapshot. Names are more durable than line numbers. The current-behavior column is **VERIFIED IN CURRENT CODE**; recommendations in the automation-assessment column are **PROPOSED**.

| Area / current entry point | Current behavior | Automation assessment |
| --- | --- | --- |
| Controller creation / `AminScatterObject` | Scripted geometry plugin; persistent parameters and node references | Scriptable; new owned-controller command and preflight needed |
| Layers / `newLayer` ~11258, `removeLayer` ~11272 | Up to ten layers, several parallel arrays, seed offsets and blocker-index remapping | Wrap atomically; layer numbers/names are not stable IDs |
| Layer copy / `AminScatterCopyLayer` | Copies declared layer fields/tabs | Not a qualified duplicate-layer API; define reference and edit ownership |
| Surfaces / rollout `addSurface` ~151 | UI-local helper; controller has `surface` and `surfaceNodes` | Extract headless domain helper; do not automate button clicks |
| Sources / rollout `addSource` ~277 and removal ~357 | References plus weights, colors, radii, forward axes, scale, offsets and placeholder flags | Centralize add/remove/swap; raw tab assignment risks misalignment |
| Source eligibility / `usableSource` ~10800 | Basic validity and exclusion of scatter/surface nodes | Not proof of usable evaluated mesh or supported proxy behavior |
| Count/density/seed / `placements` ~11059 | Density converts scene units to square metres; bridge caps count at 100,000 | Expose explicit count-or-density union, cap status and reproducibility scope |
| Source weights / `assignWeight` ~10625 | Clamps weights; maintains a parallel array | Validate nonnegative finite values, effective sum and source identity |
| Source diversity / `scatter.cpp` ~170–211 | Spatially correlated source assignment; positions come from the scatter process | Name `source_assignment` explicitly; not a plant-clump position generator |
| Texture density | Controller samples a map into a 128×128 grid; bridge supports a bounded grid and requires UV1 | UV/projection and texture evaluation need separate qualification; no arbitrary file paths |
| Include/exclude areas | Closed shape regions use world-XY projection | Pivot eligibility is not full mesh-footprint clearance; reject unsupported terrain in MVP |
| Edge rows / `edge_border.inc` | Specialized boundary sampling, corners and offsets | Later typed endpoint; density/count semantics differ from random population |
| Falloff / `boundary_falloff.inc` | Boundary/area-based density and scale effects, side controls | Later curve schema and explicit units; do not expose graph-editor callbacks |
| Collision/relax / `spacing.inc` | Radius-based filtering and relaxation | Approximate footprints; rerun final constraint checks after later transforms/edits |
| Orientation / `orientation.inc` | Boundary orientation, source axes and offsets | Order-sensitive; typed enums and coordinate tests required |
| Transform variation | Per-axis rotation/scale/movement, normal alignment and projected movement | MVP restricts to uniform scale/yaw; mirrored, nonuniform and moved cases need tests |
| Point/geometry previews | Native cached drawing, sampling, geometry limits | Query distinct emitted/displayed/sample counts, never infer true count from pixels |
| Update modes / `updateMode`, `invalidateLive`, preview checks | Scatter defaults to mode 2 (real time); mode 1 is manual, with an initial-build exception. Analyzer defaults to manual; its live mode polls on a 250 ms timer | Coalesce changes and restore the selected update policy; real time does not mean worker-thread computation |
| Analyzer / `runAnalysis` ~201 | Evaluates planar mesh elements; returns boundaries, paths, points, area and revision | Useful structured input; readiness and freshness must be explicit |
| CS Edit | Native transform/delete/clone state and GUIDs for copied entries | Script selection uses visible row numbers; stable external edit identity is missing |
| Render / PFlow template | Builds temporary transport, callbacks and Corona IR polling | Exclude render tools from MVP; lifecycle and ownership require independent qualification |
| Persistence | Scripted parameter blocks, references and native edit chunks | Version the new API separately; no scene-schema migration in this research task |

Detailed native sources: [scatter](../../AminScatter/src/scatter.cpp), [spacing](../../AminScatter/src/spacing.inc), [edge rows](../../AminScatter/src/edge_border.inc), [falloff](../../AminScatter/src/boundary_falloff.inc), [orientation](../../AminScatter/src/orientation.inc), [preview](../../AminScatter/src/preview.cpp), [geometry preview](../../AminScatter/src/geometry_preview.inc), [Analyzer engine](../../CyrusSurfaceAnalyzer/src/analyzer.cpp), [Analyzer elements](../../CyrusSurfaceAnalyzer/src/elements.cpp).

“UI-local helper” means business logic currently lives inside a rollout. Many underlying parameters are script-accessible. It does not mean the feature is inherently impossible to automate.

## Findings that determine the architecture

### A-01 — Inspection is not consistently read-only

`layerEntries` (~11228) synchronizes layer surfaces, checks Analyzer changes and edit-stack keys, and can refresh previews. `allStatus` (~11298) calls it. `CyrusEditStackKey` (~10275) can set modifier active layers. `placements` updates counters and invokes edit application.

**PROPOSED:** `scene.get_context` must read a bounded snapshot through a purpose-built path. Do not implement it by calling these convenience functions. Test parameters, revisions, selection, undo depth and preview counters before/after inspection.

### A-02 — Scene ownership is ambiguous in some paths

`CyrusEditApplyLayer` (~10282) obtains dependent nodes and chooses the first owner. A controller used by multiple scene nodes needs an explicit policy.

**PROPOSED:** require one supported owner in the prototype; reject ambiguous instancing. Model-supplied object names never determine authority.

### A-03 — Layer/source/instance identity is insufficient for durable automation

Layers use positions in arrays. Source row references change when sources are removed. CS Edit preserves internal identities but `cyrusEditSelect` accepts 1-based indices in a visible list. Base edit identity also depends on generation ordering/signature.

**PROPOSED:** session-scoped opaque IDs tied to scene epoch, revision, owner and generation. Reopening/resetting a scene invalidates prototype IDs. Durable saved IDs and mappings require a later migration decision, not a hidden field added during this task.

### A-04 — Existing undo blocks are not a transaction contract

Creation/removal and several edit operations have undo handling. Other parameter writes and refresh/transport work have different side effects. Native edit transform primitives do not establish a complete outer agent transaction.

**PROPOSED:** one validated candidate application, one undoable unit, explicit parameter/reference snapshots, owned-object tracking and failure injection. Never hold an undo transaction open during model/network work. See [04](04_MCP_and_Automation_Architecture.md).

### A-05 — Preview/error state must be made truthful

`refreshPreview` (~11151) clears the cache before attempting regeneration; exceptions can leave empty display state and `dirty=false`. Existing error strings and nine-value cache snapshots are not a structured API or persistent checkpoint.

**PROPOSED:** last-valid state with explicit stale/error flags, typed errors, published generation IDs and no false success on zero rows. A genuinely valid empty layout must remain distinguishable from failure.

### A-06 — Analyzer output is useful but not universally applicable

The native engine rejects unsuitable topology and nonplanar elements. It uses raster-derived paths and modes. Script publication assigns output fields incrementally before the final revision update. Minimum point-count policy may relax spacing; it does not certify landscape design.

**PROPOSED:** publish a complete generation atomically; report relaxed policies, element eligibility and resolution. Do not mix boundaries from one generation with points from another.

### A-07 — Generation pipeline ordering matters

Controller order includes native generation, whole scale, Analyzer filters, falloff, source transforms, overlap handling, final cleanup, orientation and CS Edit. Later movement/edits can undermine earlier constraints. The basic-path predicate deserves the existing strategy's regression investigation.

**PROPOSED:** API eligibility checks plus final local geometric validation. Do not promise full-volume collision prevention merely because a radius control is enabled.

### A-08 — Render transport is outside a safe initial agent surface

PFlow construction records scene objects before/after and can claim all newly observed objects; unrelated callback-created nodes are an ownership risk. It clears/rebuilds transport and interacts with render/save callbacks and Corona IR.

**PROPOSED:** preserve the strategy's sentinel-node/failure tests before exposing renderer actions. Saving a scene can also trigger callbacks; a recovery feature must not assume save is side-effect-free.

## Native primitives: wrap or keep private

Potential typed internal building blocks include `aminScatterAdvanced`, surface-area queries, source sampling, overlap filtering, falloff/orientation primitives and `cyrusAnalyzeSurface`. Their current positional arrays and signatures are implementation interfaces.

Keep raw evaluation, arbitrary property setters, source-code strings, native pointers, GC cache values, raw edit opcodes, draw callbacks and PFlow script bodies private. `aminScatterPreviewPoints` can return a large point set; it is not an appropriate default model context export.

## Host and async boundaries

**Primary-source fact:** Autodesk's [Max 2027 Python threading guidance](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-Python/files/MAXDEV_Python_threading_html.html) explicitly forbids worker-thread `pymxs` calls and says `pymxs.mxstoken()` is deprecated and ineffective.

**PROPOSED:** Max scene access, evaluation, controller mutation and viewport capture remain on the host main thread. Network I/O, image encoding on copied pixels, inference and pure-data analysis belong in a companion process or appropriate workers. Copy plain data first; reject stale results before publication. A concrete supported main-thread dispatch mechanism remains an implementation spike.

## Versioning, builds and retained evidence

**VERIFIED IN CURRENT CODE:**

- Scatter scripted version 44 and ClassID `0x617d43a1/0x395c2e17`; Analyzer version 13 and ClassID `0x45a201c7/0x1829bc63`.
- CS Edit ClassID `0x43b612e9/0x578124cd`; legacy/current save chunk handling is in [storage](../../AminScatter/src/cyrus_edit_storage.inc).
- [Shared CMake](../../cmake/CyrusMaxSDK.cmake) implements Max 2026/2027 configurations, with C++17/20 respectively. Max 2024/2025 are requirements, not implemented build targets here.
- Package, CMake and UI version strings do not all agree. Runtime diagnostics need authoritative manifest identity before datasets or model comparisons are trustworthy.
- The generated controller must be changed through its generator stages/templates in future implementation.

The [build tool](../../tools/build_max.py) and installers package native modules, scripts and manifests per host. [Retained package checks](../Product_Commercialization_Playbook_2026-09-30/evidence/repository_checks.json) identify Scatter 0.59 and Analyzer 0.14 Max 2027 MZPs. Those are package identities, not matching CMake/UI version strings or a claim that a new build was tested in this task.

**VERIFIED BY TEST — historical scope:** [seven native executables](../Product_Strategy_2026-09-29/evidence/native_test_rerun.json) passed on 2026-09-29. [Retained Max evidence](../Product_Strategy_2026-09-29/evidence/prior_runtime_evidence.json) records a 2026-09-28 Max 2027.1 smoke run. Inspection of [the smoke script](../../tools/tests/max2027_smoke.ms) shows limited edit coverage and Analyzer execution rather than a comprehensive nonempty-output assertion. It contains no actual render, MCP, adversarial agent, atomic rollback or AI evaluation.

**UNKNOWN:** runtime behavior of the proposed interface, universal cross-host determinism and real-world artist benefit. This documentation task did not run those tests again.

