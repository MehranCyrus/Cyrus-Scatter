# Real-model library roadmap

**Sequence: asset audit → qualified asset path → eight pilots → 24 presets → replacement → delivery**

[Guideline](README.md) · [Preset catalog](PRESETS.md) · [Validation](VALIDATION.md)

This document defines milestones and exit criteria. Actual execution status belongs
only in the [execution ledger](../../improvement-program/PROGRESS.md#real-model-library-planning).
At creation, this is documentation only; no implementation or new host qualification
has started. Gate descriptions below are requirements, not recorded passes.

## Milestones

| ID | Milestone | Depends on | Exit criterion |
| --- | --- | --- | --- |
| RL01 | Reconcile assets and select pilot sources | Current source/build inspection | Verified manifest, pilot source shortlist and exact capability gaps |
| RL02 | Qualify the real-asset pipeline | RL01 | Representative assets preserve appearance and identity through supported save/load/reopen |
| RL03 | Author and qualify eight pilots | RL02 for each affected asset class | All eight pilot packages pass their mandatory validation and visual review |
| RL04 | Complete the 24-preset collection | RL03 | All 24 distinct recipes have exact-package evidence and documented requirements |
| RL05 | Qualify cross-scene behavior and cost | Begins in RL02; closes after RL04 | Required workflow/host matrix passes within stated bounds; failures recover safely |
| RL06 | Replace bundled demonstrations | RL04 and RL05 | New active catalog verified; eight old defaults retired without touching personal content |
| RL07 | Package and hand off | RL06 and applicable delivery authorization | Verified distributable content, receipts and installation/use instructions |

RL01 preparation and independent asset curation can continue while a specific
RL02 adapter is blocked. Do not label a milestone complete because its easy cases
passed. Small regression tests should accompany each change rather than waiting
until RL05.

## RL01 — Reconcile and select

1. Follow repository startup instructions; record branch, HEAD and existing changes.
2. Identify actual loaded script/native hashes in the owned Max 2027 profile.
3. Recheck final asset hashes, dependencies and the UTF-8 inventory against the
   preparation records. Correct stale material metadata without overwriting history.
4. Assign stable model identities and separate aliases, variants, complete collections
   and multipart plants. Select exact sources for the eight pilots.
5. Record real dimensions, pivots, UV channels, material classes, proxy paths,
   texture sizes and source/distribution status.
6. Produce a capability matrix: directly supported, needs preparation, needs an
   adapter, optional heavyweight content, or unavailable for distribution.

**Outputs:** reconciled companion manifest, selected pilot source list, capability
matrix and a concrete implementation approach. Do not reinterpret catalog entries
as a unique species count or assume a lower-resolution proxy exists.

## RL02 — Establish the asset path

Prove representative cases for Corona Physical/Legacy materials, Multi/Sub
materials, opacity/normal graphs, Forest-map dependencies, large meshes, proxy
files and multipart sources. Preserve intended UV/data channels and physical size.

Choose the smallest coherent approach supported by current code and measured cost.
An asset can use a preserved source graph or an explicitly authored derivative;
record which one and verify appearance. A proposed `.max` container or new material
adapter is an architectural decision requiring explicit dependency, persistence
and failure contracts, not a shortcut around the closed package format.

Before changes, define model/assembly identity, dependency ownership, invalidation,
Undo/Redo, retained/staged memory and cleanup on failure. Prefer native code for
bulk storage/computation; keep host access and publication on the host thread.
Edit authoritative templates/generators, not only generated MAXScript.

**Outputs:** qualified import/export route, exact supported classes, measured
bounds, meaningful regression tests, and recovery evidence. Do not merely raise
all resource limits or silently remove material features.

## RL03 — Deliver the eight pilots

Author RP01, RP05, RP08, RP12, RP16, RP19, RP22 and RP24 with the actual plugin.
Use the sequence **prepare → scatter → save package → fresh load → render → validate**.

Start with restrained density and measured previews, then adjust visual quality.
Pilot renders must show the saved package loaded in a fresh scene. Include close
detail and a wider view where needed; avoid framing that conceals floating roots,
card edges, missing maps or unwanted intersections.

**Outputs:** eight ready packages, model/recipe mapping, actual renders, per-preset
receipts and a clear pilot review. If a preset fails, retain it as draft/blocked
with the exact cause. Do not replace it silently with a placeholder.

## RL04 — Expand to 24

Use qualified assets and authoring patterns to complete the remaining 16 recipes.
Retain distinct composition and purpose. Reuse asset identities and verified bytes
where supported; do not independently duplicate huge collections for every recipe.

**Outputs:** the complete proposed catalog or an explicitly incomplete collection
with individually identified remaining cases. Each qualified entry must pass the
per-preset checks; a pilot family's success does not automatically qualify its siblings.

## RL05 — Close cross-scene and performance acceptance

Run [the validation matrix](VALIDATION.md). Account for units, receiver shapes,
surface transforms, repeated load, owner switching, source removal, Manual/Live,
Undo, save/reopen, moved assets, absent plugins and injected failures.

Set measured working budgets for each content tier. Record hardware, renderer,
exact source/package hashes, viewport representation, requested/accepted/shown
counts, cold/warm costs, memory and render settings. A successful small preview
does not establish production-scale render performance.

**Outputs:** cross-scene receipt, per-preset costs and limits, a supported
dependency matrix, and explicit unresolved artist/physical-input acceptance.
Fix failures and rerun affected tests before changing readiness labels.

## RL06 — Replace defaults safely

Retire only these bundled recipe identities from active default enumeration and
future distribution after the new collection passes:

| Existing title | Recipe UUID | Current source file |
| --- | --- | --- |
| Layered meadow | `e9d3b9f1-de8e-47b9-8e77-c172043ac01a` | `meadow.csrecipe.json` |
| Trees and understory | `9608f549-2132-4fbc-a93e-8c1d5b1de759` | `woodland.csrecipe.json` |
| Mountain planting | `d499d541-14c2-4fd6-9900-887f63144303` | `mountain.csrecipe.json` |
| Painted garden and spline borders | `68e28fee-6e72-4dd7-9f0d-3aebe8110ff0` | `borders.csrecipe.json` |
| Rectangular orchard | `8e1c6066-9775-4a1b-bbdb-4478e0f242c8` | `orchard.csrecipe.json` |
| Hexagonal hillside planting | `d4d6e61b-6d41-4ea5-b3cc-11606d60828e` | `hexagonal.csrecipe.json` |
| Four garden rooms | `42f6a31c-1e9e-4a10-8bef-60667aca32e2` | `42f6a31c-1e9e-4a10-8bef-60667aca32e2.csrecipe.json` |
| Valley moss and rocky crests | `2b0a6ec1-2638-415c-a511-13b6037c5c5e` | `2b0a6ec1-2638-415c-a511-13b6037c5c5e.csrecipe.json` |

Files are currently under `AminScatter/library`; revalidate UUIDs before mutation.
Preserve historical packages, receipts and source history outside active default
enumeration. Do not reuse old UUIDs for unrelated new compositions or delete users'
saved copies, personal collections, original models or scene-owned dependencies.

Reconcile the product inventory, default browser collections, thumbnails, installer
ownership, docs and tests. Test clean installation plus upgrade/repair enumeration:
old installer-owned defaults must not reappear, while user-modified/personal content
is preserved according to the installer contract. Do not perform broad folder deletion.

**Outputs:** verified default catalog replacement, preserved history, and clean/upgrade
receipts. New assets must remain available to previously saved scenes and Redo where
the qualified persistence contract requires them.

## RL07 — Package and hand off

Apply the current user's delivery scope and version policy. Assess plugin/script
and content changes separately; keep source, package and loaded identities matched.
Any new Scatter version delivered for testing needs its matching Max 2027 MZP.
If the delivery includes an EXE, qualify the exact embedded MZP as well. A content-only
pack must identify its minimum qualified plugin build and installation method.

Separate large optional content from the core installer where the tested architecture
allows it. Verify archive integrity, every payload hash, dependency persistence,
host/version guards and distribution eligibility. Keep private probes and artist
assets outside unrelated product packages.

**Outputs:** ready content/packages, integrity manifest, exact build and qualification
receipts, supported renderer/dependency requirements, known limitations and clear
user instructions. Do not install into or restart the artist's session.

## Completion definition

The workstream is complete when 24 distinct real-model recipes are qualified,
their required models/materials/dependencies survive supported lifecycle and
cross-scene workflows, the old bundled examples are retired safely, and the
authorized deliverables are verified and linked. If a dependency or rights issue
prevents a planned entry, report the exact unmet scope and a concrete alternative;
do not silently count a missing entry as complete.

