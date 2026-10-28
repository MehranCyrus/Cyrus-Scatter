# 02 — Requirements and the supplied system

[Index](00_README.md) · [Decision](01_EXECUTIVE_DECISION.md) · [Parallel design](03_PARALLELISM_AND_DATA_LAYOUT.md)

## Evidence boundary

**[P — provided project facts]** This chapter transcribes and interprets the supplied brief and context. It is not a repository audit. The supplied files are preserved byte for byte under [inputs](inputs/README.md); their four content hashes match the supplied manifest. The research environment did not contain an installed Max host, the production repository, a qualified CUDA/OpenCL device, or the Windows SDK. Existing research and old implementation work were not treated as new qualification evidence. [PROJ01](17_SOURCE_LEDGER.md#proj01) [PROJ02](17_SOURCE_LEDGER.md#proj02)

The target is **Cyrus Scatter 0.87.4.3, capability 11, schema 63, Max 2027 / Windows x64**. No version change, scene migration, production rewrite, installer release, or additional Max-host support is authorized by this study.

## Behavior that acceleration must preserve

| Requirement | Current supplied behavior | Design obligation |
|---|---|---|
| Prepared source reuse | Shared geometry, guide chains, hierarchy, roots, bindings, fixed parts and fingerprint; artist corrections retained | Upload/cache once per source revision; never extract guides again per placement or drag |
| Static interaction | Collider edits produce a fitted successor; leaving restores rest | No accumulated velocity, time-step history or persistent XPBD multipliers in the authoritative static answer |
| Local invalidation | Old/new collider neighborhoods; published and independently edited transforms | Include previously affected/restored plants; preserve horizontal locality of footprint exclusion |
| Root semantics | Fixed attachment; attached branches/foliage follow prepared ownership | Positional root constraints and root-frame constraints remain distinct |
| Contact gap | Clearance used by contact fitting | Convert once to local metres; apply once in each equivalent query formulation |
| Hide margin | Separate root-group exclusion expansion | Never use failed contact fitting as permission to hide vegetation |
| Inside solid / Under collider | Solid root classification versus explicit downward footprint exclusion | Separate query types and bounds; a floating obstacle may hide in footprint mode |
| Failed successor | Retain preceding complete publication | No partial pose/visibility/material publication presented as complete |
| Units and transforms | Metres, +Y internally; scene units, +Z in Max; positive uniform instance scale | Explicit conversions, determinant/scale checks, no implied mirrored/sheared/nonuniform support |
| Display | Retained custom render items, instanced triangles, HLSL SM5; F3/style does not refit/reupload unchanged geometry | Keep drawing separate from collision solving; no scene calls inside kernels or drawing callbacks |
| Host/thread boundary | CPU jobs use owned numerical snapshots, dynamically scheduled and joined synchronously | GPU asynchrony is a new subsystem; it cannot inherit safety from a synchronous executor |
| Delivery | Separate preview, renderer, Bake and export paths | All consume one accepted pose/evaluator contract, with separately qualified host adapters |

These facts, including the distinction between sparse pose storage and later unique preview/render geometry, come only from the supplied context. [PROJ02](17_SOURCE_LEDGER.md#proj02)

## Existing numbers: what they establish

**[P]** The supplied delivery reports 61 native tests and a scoped host campaign. One source has 451 guides, 22,032 vertices and 27,501 triangles. One update in a 200-plant/one-collider scene found three candidates, fitted six guides and hid 62 rooted groups; native contact evaluation was approximately 4.05 ms. A separate one-plant double-precision audit checked 23,497 visible triangles, reported zero penetrating vertex pairs, zero touching triangle pairs and zero root-anchor error, with maximum checked stem-edge change about 9.145%. Those are coordinator observations, not measurements repeated by Researcher A. [PROJ02](17_SOURCE_LEDGER.md#proj02)

The 9.145% number is a checked **visible stem-edge change**, not a known guide-span constraint tolerance. The audit does not establish all-scene validity, GPU accuracy, p95 drag time, renderer equivalence, or feasibility for every contact configuration. The 5,000-instance numerical footprint test checks one affected neighborhood, not 5,000 complex plants solving together. The raised-collider counts distinguish the two hide modes; they do not characterize solver scaling.

**[P]** Current admission ceilings are 1,000,000 instances per interaction layout, 16,384 collider instances, 64 relevant colliders per plant, and 4,096 transient overrides, alongside other work/memory/source limits. They are safeguards. Large automatic CPU batches may use up to eight participants under the present policy. Successor construction copies retained pose/root-count maps, so large retained-state cost can remain even with a small affected set. [PROJ02](17_SOURCE_LEDGER.md#proj02)

**[D — proposal]** Profile map-copy/publication, preparation, source capture, geometry refinement and uploads before attributing latency to the numerical fitter. Preserve those admission ceilings until each replacement has its own measured memory/work guard.

## Four populations that require different answers

Define `N` resident placements, `K` placements needing reconsideration this request, `R` placements with retained non-rest state, `G_s` guides in source `s`, `A` guides actually solved, `Q` nodes actually solved, and `V_d` vertices drawn/materialized. `K` includes restoration and exclusion changes, not only bends. Root-group count need not equal guide count. `R` can exceed `K` substantially.

| Population | Relevant scaling | Consequence |
|---|---|---|
| One million resident, ten nearby changing | Resident transform/index data scale with `N`; solver with `A,Q,P`; retained pose with `R` | CPU neighborhood plus sparse poses may already be appropriate; do not dispatch `N×G` work |
| Thousands of detailed plants active | `A` can approach `K×451`; hierarchical depth and contact pairs matter | Batched GPU fitting may earn its integration cost; measure quality-equivalent crossover |
| Millions of simple blades or vertices | Small `G_s` or small vertex output can be regular and parallel | Skinning/deformation may dominate; a graphics shader can help without a compute solver |
| Millions of detailed 451-guide clumps active | Hundreds of millions of guides, billions of nodes/vertices | Explicitly reject ordinary all-active materialization assumptions; budget and admit a smaller requested operation |

The last row is not equivalent to the first. With the **hypothetical** eight nodes per guide and 32-byte node pose used in [09](09_MEMORY_PRECISION_AND_HARDWARE.md), one million fully posed 451-guide clumps require 115.456 GB for one node-pose version alone. This is arithmetic, not a measured allocation or capacity claim.

## Scope exclusions

**[D]** No new guide extraction, plant rigging, growth, self-collision, wind simulation, rigid settling, distributed renderer, public web demo, or general GPU framework is needed for the first prototype. Imported prepared sources, stable guide/attachment identities and the existing CPU reference define its input. Procedural deletion/reseeding is not a performance fallback.

## Decisions the supplied context does not settle

**[U — unresolved]** Actual display adapter, CUDA device, available VRAM, PCIe topology, Max patch level, intended renderer/version, precise guide node counts, current peak retained-map overhead, surface-audit cost, root-frame modes, deformation equations and exact host compiler compatibility must be supplied or probed locally. The precise probes and the decisions they block are in [16](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md). None is filled with a guessed repository implementation.
