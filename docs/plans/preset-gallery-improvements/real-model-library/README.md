# Cyrus Scatter real-model library

**Historical planning brief · 19 October 2026 · original Max 2027 scope**

**Current status:** the artist later chose individual models as the default library. The 96-model content revision 0.86.7 and current three-host plugin delivery are recorded in the [execution ledger](../../improvement-program/PROGRESS.md#real-model-library-planning). The 24 presets below remain an expansion proposal; this brief does not authorize resuming it or choosing its old proposed version.

Build a useful collection of planting presets from the prepared plant assets,
using Cyrus Scatter to author, save, reload and render the delivered results.
Start with eight representative pilots, then expand to 24 distinct presets.
Replace the eight bundled demonstration presets after their replacements qualify.

This is a plan for future implementation. Creating these documents does not
change plugin code, remove presets, modify assets or qualify a new delivery.
The starting delivery is [0.86.6](../DELIVERY_0866.md); recheck the current
repository and loaded build before work. Documentation alone does not change
the version. Follow the [version policy](../../../Release_Versioning.md) for
any later delivery; do not infer a new version from this plan.

## Start here

| Document | Purpose |
| --- | --- |
| **This guideline** | Scope, source evidence, working rules and AI handoff |
| [Preset catalog](PRESETS.md) | The 24 proposed presets, compositions and pilot selection |
| [Roadmap](ROADMAP.md) | Ordered milestones, dependencies and exit criteria |
| [Validation checklist](VALIDATION.md) | Required checks, failure behavior and evidence records |
| [Execution ledger](../../improvement-program/PROGRESS.md#real-model-library-planning) | Sole maintained execution status for this workstream |

Share this directory with the implementation AI. The project-wide roadmap
remains in the execution ledger; this directory specifies one bounded workstream.
RL milestone IDs and RP preset IDs are local planning identifiers, not release
numbers or new P/I/PG/N phases.

## Source collection

Local asset root:

```text
F:\Cursor\_Cyrus_Apps\CyrusScatter\Test Scene\Plant Library - Organized 2026-10-19
```

| Source | Use |
| --- | --- |
| [Catalog](../../../../Test%20Scene/Plant%20Library%20-%20Organized%202026-10-19/00%20Catalog/index.html) | Browse prepared assets and actual previews |
| [Preparation summary](../../../../Test%20Scene/Plant%20Library%20-%20Organized%202026-10-19/00%20Catalog/CORONA-ALL-ASSETS.txt) | Conversion scope and explicit limits |
| [Prepared-file records](../../../../Test%20Scene/Plant%20Library%20-%20Organized%202026-10-19/00%20Catalog/CORONA-ALL-ASSETS.json) | Final paths, SHA-256, geometry records and material notes |
| [Host validation records](../../../../Test%20Scene/Plant%20Library%20-%20Organized%202026-10-19/00%20Catalog/CORONA-ALL-VALIDATION.json) | Recorded Max reopen, materials and dependencies |
| [Catalog inventory](../../../../Test%20Scene/Plant%20Library%20-%20Organized%202026-10-19/00%20Catalog/inventory.json) | Categories, dimensions, source names and variants |

These are ignored local assets, not files delivered by a Git checkout. Resolve
the actual root on another workstation. Read JSON as UTF-8; non-ASCII names such
as `Blätter` must retain their exact spelling. Inspect final files and preparation
records together: some inventory fields still describe earlier material versions.

### What the read-only analysis established

The 19 October analysis checked the prepared files against their existing
receipts and inspected current Library source. It did not run a new Max campaign.

| Observation | Scope and implication |
| --- | --- |
| 104 prepared files matched their recorded SHA-256 hashes | Includes collections and variants, not 104 unique plants |
| 104 JPEG previews were readable at 640 × 640 | Preparation records identify Corona renders; representative images were visually inspected |
| All 888 recorded texture/proxy paths existed inside the library | Local resolution does not establish relocation or clean-machine success |
| Catalog local links resolved | Browser/file navigation is distinct from plugin import |
| 41 entries exceeded the current portable vertex or face limit in recorded geometry | Large-model support requires an explicit measured approach |
| Three entries used Corona proxies | Glossy Abelia 06 and Lavender 01/05 require qualified proxy handling |
| 27 entries contained Forest Color and/or Forest Edge maps | Additional shader availability or a verified authored replacement must be addressed |
| 35 referenced images exceeded 4096 pixels on an edge | The current portable image bounds cannot represent them unchanged |
| Eight entries contained multiple geometry objects | Distinguish assemblies from collections of independent plants |
| 26 inventory material labels still said Standardmaterial | Final validation identified Corona materials; refresh metadata before relying on it |
| Prepared scenes totaled approximately 9 GiB | Prefer reusable assets and optional content packs over a monolithic installer |

Prepared leaves include 26 assets normalized to a 20 cm longest edge. Palm
variants retain an approximately tenfold physical size difference. These are
documented authoring choices that need deliberate product defaults.

This table is a dated analysis summary. Recheck affected files before changes;
historical preparation passes do not qualify Cyrus preset loading or scattering.

## Product decisions

### Models and recipes have different roles

**Model records** identify reusable plants, their geometry/materials, physical
dimensions, dependencies and variants. **Recipes** describe planting composition,
layers, distribution, spacing and intended use. A collection file must not become
one accidental giant plant, and a trunk/foliage assembly must not scatter as
separate unrelated objects.

Reuse the existing source and library workflow where it supports this distinction.
A separate model-browser redesign is not a prerequisite for the pilot. Keep
source bindings and metadata usable while avoiding unrelated UI expansion.

### Preserve appearance and portability

Retain UV/data channels, material IDs, two-sided behavior, opacity, color-space
intent, normal strength and authored material graphs. Any simplification, map bake
or proxy conversion needs a separately identified derivative, recorded limitations
and a visual comparison. Keep original files unchanged.

Material texture coordinates belong to the model. Density channels and Paint
requirements belong to the planting/receiving surface. Never confuse those two
owners or require authoring-scene channel 2 accidentally.

Ordinary presets should bind to the artist's chosen compatible surfaces without
inheriting source terrain, object names, saved Paint or world-altitude assumptions.
Deliberate path, channel or Paint requirements must be visible before loading.
Demo terrain is optional demonstration content, separately identified.

### A small number of distinct presets is the target

The [catalog](PRESETS.md) proposes 24 different artistic uses. Source variations
belong inside those presets where useful. Seed, amount or a small scale change
alone does not justify another catalog card. No quantity target overrides quality.

### Content and delivery remain bounded

Use a modest default collection and separately installable large packs where the
qualified package architecture supports them. Deduplicate by verified content and
identity, not filename alone. Record per-asset source and redistribution status;
assets without established distribution permission remain private development
inputs and cannot enter a shared deliverable.

Do not modify artist profiles, reset their scenes or restart their Max processes.
Use owned disposable Max 2027 scenes/profiles. Protect unrelated work and existing
changes. No Git push, public upload or artist installation is part of this
documentation task.

## Integration gate

The current portable adapter is a closed data graph for static standalone meshes,
Standard/Blinn materials and PNG maps. It does not import arbitrary `.max` scenes
or arbitrary renderer graphs. Relevant current sources:

- [Asset authoring template](../../../../AminScatter/tools/ui/templates/assets.ms)
- [Mesh admission and storage](../../../../AminScatter/include/asset_mesh.h)
- [Package bounds and ownership](../../../../AminScatter/include/asset_package.h)
- [Graph validation](../../../../AminScatter/src/asset_package.cpp)
- [Current artist workflow](../ARTIST_WORKFLOW.md)

At planning time, portable meshes allow at most 100,000 vertices and 100,000 faces;
images allow dimensions up to 4096 and an aggregate 16 Mpixels of map instances.
Payload limits include 32 MiB per file and 256 MiB per package. These are package
limits, not a statement that all larger scene models cannot scatter normally.

Before expanding support, define source/assembly identity, material/proxy lifetime,
dependency invalidation, persistent storage, peak memory, Undo and rollback.
Follow [the foundation](../../../ENGINEERING_FOUNDATION.md), especially F01,
F04–F11 and the native-language boundary. Host API access stays on the host thread;
workers use copied data. Do not remove limits without measured replacement bounds.

A ready preset must load its actual assets through the supported Library path.
Do not substitute primitives, drop unsupported maps, hand-edit a success flag or
present a manual merge as proof of portable package support. If an adapter blocks
one family, record the gap and continue independent preparation of other families.

## Handoff to the implementation AI

> Read this guideline, PRESETS.md, ROADMAP.md and VALIDATION.md, then the repository
> startup instructions. Check the current source/build and prepared asset hashes.
> Follow RL01–RL07 in order, establishing the real-asset import/export path before
> bulk recipe production. Author with Cyrus Scatter in owned Max 2027 scenes.
> Deliver eight qualified pilots before expanding to 24 useful presets. Render
> previews from freshly loaded saved packages. Preserve source assets and personal
> recipes. Retire the eight bundled demonstrations only after replacement acceptance.
> Update the execution ledger with exact evidence, unresolved cases and the next
> step; do not turn preparation reports into unexecuted pass claims. Follow the
> current user's implementation and delivery authorization throughout.

**First implementation result:** a reconciled asset manifest, a capability/gap
matrix for the eight pilots and a concrete qualified import/export approach.

