# Practical lessons for Cyrus Scatter

These are research recommendations. No implementation, package, installation or future roadmap work is authorized by this report itself.

## Our existing architecture already uses the important display technique

Current source inspection establishes retained point and mesh display generations. In `AminScatter/src/point_display.cpp`, `sameLayers` and publication suppress replacing unchanged layer data; `PointItem::Realize` is readiness-gated. In `AminScatter/src/mesh_display.inc`, preparation creates shared geometry plus per-instance transform streams, and drawing calls `DrawInstanced`. Source fingerprints, input validity and failure state belong to our own model.

Forest's marker path supports this architectural direction. It does not demonstrate that Forest is faster, nor that copying its memory layout would improve Cyrus. Our acceptance contract remains stricter than a ready flag alone: navigation, selection and unrelated animation must leave placement builds and unchanged uploads stable; relevant Live dependencies rebuild; Manual pending edits wait; a failed successor retains the previous complete result.

| Topic | Current Cyrus evidence | Useful next investigation and acceptance |
|---|---|---|
| Display budgets | Template has `previewBudget`, `pointsPerPlant` and separate viewport fields; native paths retain buffers. | Measure total rendered points across layers against an explicit whole-object budget. Evaluate a separate hit-test budget. Navigation and selection must preserve build/upload counters. |
| Receiver preparation | Current native execution and input-validity code have explicit receiver/dependency responsibilities. | Profile projection before adding a shared receiver cache. If justified, demonstrate reuse across layers, bounded memory and invalidation on relevant geometry/transform changes. An R-tree type name is insufficient justification. |
| Collision and count semantics | `procedural.cpp` already has independent scopes, bounded attempts/repair and protected edits. | Report candidates, accepted, collision rejected, shown and requested counts separately. Validate mixed radii, Z offsets, touching boundaries, reproducibility and existing scope rules with an independent oracle. Forest's discard path is not a reason to remove our bounded refill. |
| UI context | Unified template binds layer settings and Manual/Live ownership; generated scripts have a declared source owner. | Explain disabled controls by active mode/edition/selection. Capture valid owners across callback rebuilds. Test natural selection and changing layers while controls are open. A Qt rewrite has no demonstrated benefit here. |
| Source animation | `input_validity.cpp` captures relevant source/controller/mesh/material validity. | If sampled animation is added, cache by source, evaluation context and time with a memory bound; test static navigation and source-only changes separately. Placement rebuilding must remain dependency-driven. |
| Distribution inputs | Current model already has layers, sources, receivers and ordered paint sets. | Add a path/reference/particle adapter only for a concrete artist requirement. Define deterministic placement IDs and ownership before mixing external positions with procedural regeneration. |
| Editable placements | Current stable IDs, source containers and edit preservation are existing contracts. | Investigate regeneration and source replacement behavior with a disposable scene. Keep edited-item survival explicit; Forest's toolbar does not reveal its internal identity guarantee. |

## Improvements worth prioritizing

The best immediate follow-up is **measurement and observability**: prove budget behavior and unchanged-upload behavior, then profile receiver projection and collision rejection in representative scenes. These investigations can find practical costs without redesigning the engine.

A second useful direction is artist-facing clarity: show why controls are inactive and distinguish requested population from accepted population and viewport representation. The screenshot demonstrates the scale of the problem; it does not establish that presenting every advanced field simultaneously is a good workflow.

Effects, clustering, camera culling and additional distribution adapters are separate product decisions. They can be implemented independently from published behavior and our own contracts when there is a concrete need. An arbitrary expression engine adds ordering, resource-bound and reproducibility questions; do not introduce one merely because Forest has it.

## What “reuse” means for this work

We can reuse the neutral research helpers and derive independently implemented strategies: spatial acceleration, retained buffer preparation, bounded caches, contextual controls and separated dependencies. The installed binaries provide observations and testable hypotheses. They do not provide an original source tree ready to merge into Cyrus. No vendor code, pseudocode or undocumented internal registration identity has been incorporated into the product.

Before comparative Max testing, reconcile the installed Cyrus script/native pair with the reviewed source. Earlier inventory found a 0.73-captioned installed script whose hash differed from the current generated script. The caption alone cannot qualify the pair. Any continuation should use an owned disposable profile/scene, record loaded module paths/hashes and avoid artist scenes.
