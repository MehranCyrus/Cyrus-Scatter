# 26 — Companion features: growth, billboards, baking, and scene management

**Status: bounded extension design. These are separate modules, not claimed completed core features.**

## 1. Why this chapter exists

The supplied research focuses on the scatter engine and identifies legacy billboard shadows as lower priority [R0 §5.7]. Earlier project discussion also mentioned ForestIvy and utilities. A request to rebuild “all” should not silently merge plant generation, rendering utilities, and scattering into one unbounded task.

The official ForestIvy overview establishes a distinct growth-oriented product area [S28]. The following is an independent extension design, not a reverse-engineered ForestIvy algorithm or complete control audit.

## 2. Ivy/growth module

Inputs are seed/guide curves, receiving geometry, growth directions, branch rules, random seed, and stop conditions. Output is a persistent branch graph plus leaf-placement candidates and optional branch geometry.

A feasible first solver advances growth tips in bounded steps. Each tip combines guide attraction, surface adhesion, gravity, directional persistence, and deterministic perturbation. It queries nearby surfaces through the shared surface service, checks self/obstacle clearance, and terminates on maximum length, age, invalid support, or exhausted growth budget.

Branch events create child tip identities derived from parent branch ID and branch rank. Do not identify branches by the current vector index. Save generated topology or a versioned reproducible growth recipe according to the selected editability contract.

This is a procedural artistic growth model, not a biological simulation. Define step size, attachment radius, branch probability, taper, maximum branch count, collision policy, and guide influence in a separate schema before implementation.

## 3. Leaf layers and wind

Leaf placements consume the branch graph as an external candidate provider. They can reuse source selection, transforms, materials, LOD, and render adapters. Branch-local coordinates provide attachment and orientation.

Wind deformation requires a separate time-dependent source/branch deformation model. Phase-offset scattering only varies existing animation; it does not create wind. A simple initial wind model can bend branches using bounded hierarchical angular responses, with root constraints and deterministic spatial phase. Its visual quality and stability require dedicated fixtures.

Growth edits may change topology and invalidate leaf/branch edits. Preserve stable branch identities where possible and report orphans rather than promising arbitrary topology-stable editing.

## 4. Billboards and legacy shadows

Modern billboard support can be a source/LOD representation with a pivot, texture, orientation policy, and renderer-native shadows. Define whether the card faces the camera, rotates only around world up, or follows another axis.

Legacy renderer-specific shadow-plane behavior is a separate compatibility project. Do not advertise historical Mental Ray/Scanline parity without an actual target environment and tests. Keep it in the feature backlog with an explicit status rather than pretending native mesh shadows reproduce every legacy option.

## 5. Scene lister

A scene manager lists setups/layers, enabled state, update mode, authoritative/result revisions, counts, memory, missing assets, and output capability status. Bulk actions issue validated commands in grouped Undo transactions.

Filtering by collection, source, receiver, or dirty state helps large projects. A lister must not evaluate every source mesh merely to display a name/count; use current cached statistics with a visible revision label.

## 6. Baking and export utilities

Provide separate routes for standard Max instances, combined meshes, manual-only Cyrus layers, and neutral instance/asset manifests. Estimate size before conversion, preserve material/source mappings, and support cancellation/rollback.

Baked outputs lose some procedural relationships by definition. The UI reports which relationships are frozen. A utility does not silently delete the original setup after conversion.

## 7. Qualification

Growth requires guide/adhesion/self-intersection/termination tests. Wind requires deformation and motion-bound tests. Billboards require facing, alpha, shadow, and LOD tests. Baking requires transform/material/persistence tests. Scene management requires command/Undo consistency tests.

These modules can share infrastructure but should have independent release gates and evidence records.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S28]: https://docs.itoosoft.com/forestpack/forest-ivy/forest-ivy-overview
