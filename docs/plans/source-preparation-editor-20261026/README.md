# Source Preparation Editor

27 October 2026. The user has authorized implementation as **Scatter 0.87.4, Max 2027 only**. Start with the [artist workflow](ARTIST_WORKFLOW_0874.md), [implementation record](IMPLEMENTATION_0874.md) and [delivery/evidence](DELIVERY_0874.md). Documents 01–05 retain the original research and broader proposed acceptance; their unexecuted rows are not current qualification. The preceding [0.87.3.2 delivery](../scatter-interactions-garden-20261025/DELIVERY_08732.md) keeps its original identity.

## Recommended product

Keep **Prepare model** as the ordinary one-click workflow. Add an optional **Edit preparation…** button for difficult sources. It opens one floating window containing the original plant, selectable parts, inferred guides and a small set of corrections.

The artist selects a leaf, stem or decorative part and chooses what it should do:

| Choice | Result |
| --- | --- |
| **Bend** | Generate a guide for this supported leaf/stem and deform its geometry. |
| **Follow stem** | Keep a detail rigid while it follows the selected stem, such as a flower head. |
| **Keep fixed** | Retain the geometry in its rest position within the plant, such as a pot or decorative base. |
| **Automatic** | Remove the artist override and let preparation infer this part again. |

Changes automatically update the editor's preview. **Use preparation** saves one complete result to the selected source slot; **Cancel** discards the draft. There is no mandatory Analyze → Accept sequence. Every scattered instance using that slot reuses its prepared definition with its own placement and contact pose.

“Keep fixed” is relative to the plant: it still follows the plant's placement transform. It is not a world-space pin, an invisible collider, or removal from the rendered model. “Follow stem” is rigid attachment, not independent bending.

## First useful delivery

- A floating, resizable 3D editor with ordinary orbit/pan/zoom.
- Whole connected-piece selection by click, rectangle and selection brush; visible-only selection by default, isolate selection, and material-ID selection assistance.
- Bend / Follow stem / Keep fixed / Automatic assignments.
- Guide/root display, root-end correction, guide direction flip, existing guide-point adjustment and explicit parent/attachment picking.
- Automatic draft preparation and an optional private test sphere using the existing contact fitter.
- One atomic **Use preparation** action, Cancel, Undo/Redo and `.max` persistence.
- Native source-level computation and storage; shared definitions across instances, no per-instance analysis.

The first delivery selects **whole connected pieces**, not arbitrary portions of welded geometry. It can correct separate leaves and decorative components like the supplied fern. It must identify welded multi-leaf components honestly rather than pretending a region selection has separated them. Partial-face regions, blended transitions and freehand creation of entirely new guide networks are later stages.

## Read in this order

| Document | Purpose |
| --- | --- |
| [01 — Research and decisions](01_RESEARCH_AND_DECISIONS.md) | Current code, official reference workflows, feasibility, choices and limits. |
| [02 — Editor workflow and layout](02_EDITOR_WORKFLOW.md) | Window wireframe, buttons, selection behavior, examples and error messages. |
| [03 — Technical design](03_TECHNICAL_DESIGN.md) | Ownership, source bindings, native data, worker lifetime, Undo, persistence and performance. |
| [04 — Implementation plan](04_IMPLEMENTATION_PLAN.md) | Dependency-ordered work packages, affected files and exit criteria. |
| [05 — Validation matrix](05_VALIDATION_MATRIX.md) | Functional, geometry, lifecycle, performance and delivery checks. All new editor tests are pending. |
| [Source evidence](SOURCE_EVIDENCE.json) | Read-only inspection identities and research provenance; not a build receipt. |

## Boundaries and next step

The implementation uses native C++ with a modeless Win32 window and a dedicated Direct3D 11 viewer. Matching Qt development inputs were unavailable; the [implementation record](IMPLEMENTATION_0874.md) explains the revised boundary. Autodesk's extended-viewport APIs are not treated as an embeddable Nitrous viewport.

The editor can improve preparation reliability and avoid generating unnecessary guides. It does **not** promise automatic botanical understanding, remove render polygons, make impossible pinned-root contacts solvable, or add wind/tree physics. Existing contact-gap and covered-root behavior remain separate controls.

The original research proposed 0.88.0; the user subsequently selected **0.87.4**. Native Interactions 8, scene schema 62 and authored definition format 2 are the implementation boundaries. This task includes a Max 2027 MZP; older hosts, EXE creation, website publication and Git delivery are outside its scope.

The [delivery report](DELIVERY_0874.md) distinguishes the implemented editor and executed fern/grass checks from remaining lifecycle, scale and rendering qualification.
