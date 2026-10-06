# Houdini lessons for Cyrus procedural design and learning

Second pass: **5 October 2026**. These are selected official-documentation findings and proposed Cyrus contracts. No Houdini execution, performance comparison or feature port was performed. The live SideFX pages identify Houdini 22.0; that identifies the documentation consulted, not an installed or qualified Cyrus dependency. Source reading depth is recorded in the [vendor ledger](17_VENDOR_SOURCE_LEDGER.md).

## Preserve the useful separation of stages

Houdini exposes scattering, piece assignment, instance transforms and copying as distinct operations. Scatter and Align additionally distinguishes relaxation, overlap removal and constraints from other point populations. This is a useful comparison for our pipeline, but its moving-point relaxation is not Cyrus policy-3 deletion-only cleanup. [Scatter and Align](https://www.sidefx.com/docs/houdini/nodes/sop/scatteralign.html), [Attribute From Pieces](https://www.sidefx.com/docs/houdini/nodes/sop/attribfrompieces.html), [Copy to Points](https://www.sidefx.com/docs/houdini/nodes/sop/copytopoints.html).

**Cyrus proposal:** keep a compact, typed record at the existing stage boundaries. Do not create a new universal node engine just to imitate Houdini's interface.

| Stage | Record or invariant to expose | Reason |
| --- | --- | --- |
| Context | Receiver identity/version, units, source membership, ordered layer/set IDs | Reproduce the same input domain |
| Generation | Candidate key, sampling algorithm/version, seed/salt, requested population | Explain where a candidate originated |
| Eligibility | Brush/area/density decisions and reasons | Distinguish an excluded candidate from collision rejection |
| Source and transform | Stable asset reference, pivot frame, orientation, scale, artist Edit state | Resolve actual geometry before spacing |
| Radius and collisions | Effective radius, rule scope, blocker identity when available | Explain within-set, between-set and between-layer decisions independently |
| Cleanup/refill | Protected state, rejected/retained identity, bounded replacement attempt | Preserve artist edits and limit worst-case work |
| Publication | Complete output digest and epoch; previous valid publication on failure | Give display, renderer and export one result to identify |

The current [scatter header](../../AminScatter/include/scatter.h), lines 27–30 and 61–70, already contains stable-candidate controls, a pre-compaction candidate key and surface-anchor fields. Extend that foundation. The presence of fields alone does not establish every lifetime or persistence guarantee.

## Identity must survive named operations, not every possible edit

SideFX documents that randomized output ordering can change point numbers even when existing point positions remain the same. Its primitive seed attribute addresses another specific stability problem: primitive index changes. These are separate guarantees. [Scatter](https://www.sidefx.com/docs/houdini/nodes/sop/scatter.html).

**Cyrus proposal:** publish an identity-survival matrix and test it before training on correction pairs. A row offset, source slot, candidate ordinal, persistent source ID and published instance ID are not interchangeable.

| Operation | Intended data behaviour | Correspondence rule to qualify |
| --- | --- | --- |
| Sort gallery or browse layer settings | No scene mutation | Same publication and artifacts |
| Compact accepted candidates after rejection | Preserve surviving candidate keys | Never match by compacted array index |
| Rename a source | Preserve source registration/settings | Name is a label, not an asset key |
| Move a registered model outside/inside its container | Park/reactivate the same registration and its layer settings | Record membership revision; do not assume the resulting layouts remain identical |
| Delete/recreate a model with the same name | Explicitly new registration unless a supported relink is chosen | Never infer identity from a reused name/handle |
| Reorder layers or paint sets | Preserve layer/set IDs but recompute order-dependent outcomes | Same identity may have a different accepted/rejected outcome |
| Change seed, sampling method or receiver topology | Preserve only guarantees explicitly supplied by that algorithm | Unknown cross-generation correspondence stays unknown |
| Save/reload, clone or merge | Apply the declared persistence/clone policy | Test collisions and remapping of IDs; no silent aliasing |

These are acceptance targets, not a claim that all cases already pass. [E15](11_EXPERIMENTS.md#e15--identity-transform-and-surface-contracts) makes that distinction executable in a later loop.

The model-container rectangle is an **asset palette and membership control**. It is not the ground receiver or an include/exclude planting area. Keep source placement inside the palette separate from the authored source pivot/frame used to instantiate it. Container movement must not silently become a planting transform or erase parked settings. The current [procedural model](../../AminScatter/tools/ui/templates/procedural-model.ms), lines 21–48, already separates source IDs/radii, container settings, binding keys and membership caches; the new publication/API should explain those distinctions.

## Make transform and radius meanings explicit

Houdini's instancing attributes have defined precedence: `orient` is a quaternion, `pscale` is uniform scale, and a supplied transform matrix overrides several orientation/scale attributes. Scatter and Align also uses a normalized-source convention when interpreting `pscale` as a radius. Those conventions cannot be copied into Max without a conversion contract. [Instancing attributes](https://www.sidefx.com/docs/houdini/copy/instanceattrs.html), [Scatter and Align](https://www.sidefx.com/docs/houdini/nodes/sop/scatteralign.html).

**Cyrus proposal:** document the actual implementation order, then freeze round-trip fixtures for:

- Receiver-local and world-space positions; source-local pivot and source object transform.
- Surface-normal alignment, random XYZ rotation, nonuniform scale and post-generation Edit overrides.
- Source radius, instance radius multiplier, automatic/manual radius modes and effective collision radius.
- Reflected transforms, zero/singular transforms, parent transforms and units changes. Either support each explicitly or reject it without replacing a valid publication.

Do not use one learned `size` feature for plant geometry scale, collision spacing and ecological role. Store declared values and measured effective output. Do not round full-precision transform data for logging and then reuse it as an authoritative replay artifact.

The header's `clusterEnabled` is explicitly a **diversity assignment** control that does not move placements ([scatter.h](../../AminScatter/include/scatter.h), lines 46–55). A requested spatial clump, meadow drift or flower ribbon needs supported zones/Brush/placement controls. It must not be advertised as implemented merely because a setting contains the word “cluster.”

## Surface attachments have a topology contract

Attribute Interpolate can transfer values using a primitive number plus parametric coordinates, or explicit element indices and weights. Such addressing requires meaningful correspondence with the source elements. It is not automatic recovery from arbitrary remeshing. [Attribute Interpolate](https://www.sidefx.com/docs/houdini/nodes/sop/attribinterpolate.html).

**Source fact:** the current Brush host rejects a changed prepared shape/topology fingerprint when strokes exist, preserving those strokes and requesting resolution; it also checks singular receiver transforms. See [brush_host.cpp](../../AminScatter/src/brush_host.cpp), lines 119–142. That behaviour is safer than silently interpreting old anchors on a different surface.

**Plan amendment:** first qualify flat and curved **static** receiver bindings. Distinguish rigid receiver movement, changed vertex positions, reordered triangles and changed topology in tests. A future deformation/reprojection feature needs an explicit correspondence/rebind operation, confidence/error report and Undo. Do not extend the advertised Brush scope from this documentation analogy.

## A batch graph is not an artifact validator

Wedge provides a useful model for named parameter variations and hierarchical sweeps. Its selection option can also overwrite target parameters and trigger cooking. Our gallery should therefore separate card selection from explicit application into a scratch host. [Wedge](https://www.sidefx.com/docs/houdini/nodes/top/wedge.html).

TOP cooking documentation says intermediate result-file replacement/deletion does not automatically dirty dependent work. `WorkItem.invalidateCache()` offers an explicit recook mechanism. This reinforces the need for our own content validation at resume/export/review boundaries. [TOP cooking](https://www.sidefx.com/docs/houdini/tops/cooking.html), [WorkItem](https://www.sidefx.com/docs/houdini/tops/pdg/WorkItem.html).

Local Scheduler distinguishes scheduling slots from resources inside a task, and its options can classify certain killed tasks as successful. Wait for All can exclude failed inputs when configured to do so. A green scheduler node is therefore insufficient evidence for a complete candidate. [Local Scheduler](https://www.sidefx.com/docs/houdini/nodes/top/localscheduler.html), [Wait for All](https://www.sidefx.com/docs/houdini/nodes/top/waitforall.html).

**Proposed Cyrus completion predicate:** the attempt has a valid publication receipt; every required camera artifact exists and decodes; hashes and dimensions match; all artifacts name the expected candidate, publication, asset context and render profile; and the documented technical checks pass. Only then may it become reviewable. Artist approval is a later, independent event.

Use a declared required-view set per study. A missing detail view cannot be silently dropped while presenting the candidate as comparable to a fully rendered alternative. Join on immutable candidate/publication/view IDs, not filename patterns or completion order. On retry, preserve the attempt lineage and reject stale late-arriving outputs.

Bound work by attempted evaluations, replacement trials, render time, memory, disk, retries and review workload. A thousand recipes multiplied by five cameras is at least five thousand render jobs before retries. Estimate the complete expansion before admitting the batch. Do not introduce PDG or a distributed scheduler until the small existing state machine needs it.

## Three different learning tasks

SideFX's ML stages distinguish approximating a procedural function from learning an inverse. Its guidance also stresses consistent preprocessing and a separate test set; its overview permits external training. These support a broader engineering plan without making a learned model a replacement for procedural correctness. [ML stages](https://www.sidefx.com/docs/houdini/ml/stages.html), [ML overview](https://www.sidefx.com/docs/houdini/ml/overview.html).

| Cyrus task | Target data | First useful baseline | Constraint |
| --- | --- | --- | --- |
| Artist preference | Context-matched comparisons, ties and explicit acceptance | Retrieval and regularized pairwise ranker | Synthetic generation alone does not supply professional taste labels |
| Technical surrogate | Measured evaluation/render cost, accepted count, coverage or other defined output | Direct counters and simple regression | Prediction is advisory; exact feasibility checks remain authoritative |
| Inverse initializer | Desired spatial descriptors or confirmed reference intent → recipe proposals | Retrieve similar recipes, then bounded search | Many recipes can explain one image; return alternatives and verify them |

Technical surrogate data collection can accompany qualified P1/P2 runs. Train such a model only if measurement or search cost justifies it. It cannot teach aesthetic taste by calling faster renders “better.” The inverse track remains a P6 experiment; a reference image does not uniquely specify hidden geometry, scale or a planting recipe.

ONNX inference is a deployment option for a compatible model. The Houdini node expects compatible tensor inputs/outputs and has provider-specific execution choices; exporting a model does not define the full feature pipeline. [ONNX inference](https://www.sidefx.com/docs/houdini/nodes/sop/onnx.html). Cyrus should start with the simplest companion-process model and adopt ONNX only for a measured deployment benefit. See the feature-contract requirements in [the data plan](08_DATA_AND_EVALUATION.md#feature-and-inference-contract-second-pass).

## What to adopt and what to defer

Adopt explicit stage records, tested identity lifetimes, source-palette separation, bounded variation, artifact integrity and reproducible feature preparation. Preserve retained geometry and per-instance transforms; measure memory per source and per placement instead of expanding all geometry just for learning.

Defer a generic node editor, a Houdini dependency, automatic deformation rebinding, a new scene graph database, mandatory ONNX and learned scatter execution. Each would add a substantial contract without yet solving a demonstrated blocker. The updated [roadmap](10_ROADMAP.md) keeps the useful lessons in small implementation phases.
