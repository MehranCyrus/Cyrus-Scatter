# Current work and acceptance

This is the single maintained Scatter work list. Update it in place when a finding is resolved. The [dated 0.75 checklist](System_Qualification_0.75_2026-10-09/CHECKLIST.md) records the completed audit; an old unchecked roadmap item is not automatically a current defect or an instruction to implement it.

## Next engineering work

| ID | Status and problem | Acceptance needed |
| --- | --- | --- |
| B01 | Open observation: retained-buffer assertion failed after a mixed UI/legacy sequence; clean and isolated playback pass | Reproduce the sequence with preparation/publication/upload counters, distinguish initial realization from unchanged reuse, then fix the demonstrated cause |
| B02 | Fixed within [0.76 receiver stability](Receiver_Stability_0.76_2026-10-10/README.md): receiver-local IDs/streams and caches; Density 20→21 preserves all 10,000 original matrices/models, Fixed Total preserves 9,524 survivors | Retain explicit limits for caps, local Relax changes and shared acceptance; first rebuild of older combined-sampler scenes is not placement-preserving. Arbitrary topology/deformation correspondence and incremental GPU updates are separate work |
| B03 | Fixed within the [courtyard fix campaign](Courtyard_Fixes_0.75_2026-10-10/README.md): Proxy now uses retained instanced geometry; equal-count Sphere synchronous redraw improved 938→116 ms median, with stable Mesh/Points | Continue physical viewport, device-loss and sustained-session qualification; synchronous redraw is not presented FPS |
| B04 | Vector A selected and integrated into [0.78](Vector_Brush_0.78_2026-10-10/README.md); stroke replay/tint backend removed; border feedback and density/scale feather curves implemented | Physical mouse/tablet acceptance, sustained heavy assets, total/Undo peak memory and beyond-projection surface methods remain open. Scripted timings are not presented FPS |
| B05 | Unresolved historical observation: first cold physical container Move/Undo lost history | Fresh pointer gesture with preceding Undo entries, cancel, Undo/Redo and exact source/group transforms; scripted movement passes alone do not close it |
| B06 | Closed by explicit product decision: no older model-set/stroke conversion. Schema 55 requires new setups; old formats are rejected | Preserve original scene files with their matching historical build |
| B07 | Historical BR-01 belongs to the retired stroke format. Current vector payload has its own geometry/unit and quantization bounds | Extended tiny/huge-unit scenes remain a separate vector qualification gate; no claim that the historical defect was repaired |
| B08 | Geometry stress remains underqualified | Exhaustive-reference projection and extreme-radius collision witnesses, cleanup/refill/protected combinations, bounded work and failure retention |
| B09 | Diagnostics failure coverage is incomplete | Full/unwritable/damaged storage and secondary export-cleanup failures preserve the primary error; reporting remains passive and bounded |
| B10 | Current painting/editor help, schema and capability catalog reconciled with vector ownership; duplicate discarded popup definitions removed | Continued review of unrelated older terminology can proceed independently |
| B11 | Cold viewport realization remains expensive: courtyard cold Update measured 16.6 seconds in 0.75 and 17.2 seconds in 0.76 despite removing repeated root work | Separate cold preparation, Max redraw and retained realization across fresh processes; preserve atomic publication and Manual/Live contracts |

## Final artist and release gates

- [ ] Physical all-control, picker, graph, keyboard, docking, DPI and tablet walkthrough against the current [control register](System_Qualification_0.75_2026-10-09/CONTROL_REGISTER.md).
- [ ] Long sessions and representative heavy plant/material/proxy assets; complete material fidelity rather than merely a successful render.
- [ ] Sustained floating/docked IR, intended additional renderers, device/session lifecycle and deployment/upgrade/recovery tests.
- [ ] Max 2026 physical/DPI and renderer acceptance. Bounded button/callback, native layout and playback runtime checks are covered by 0.78.1; they do not certify all renderer behavior.
- [ ] Explicit supported platform/renderer matrix and a matching reproducible delivery before 1.0.

## Recently closed within bounded tests

- [x] 0.78.1 Start Brush first-tick failure: reordered the status function binding; button/session/callback regression covers main and floating editors. Responsive radio groups and color swatches now fit their native bounds. [Both-host evidence and limits](Brush_Start_0.78.1_2026-10-10/README.md).

- [x] 0.78 vector integration: canonical regions, feather curves, clipped large-brush feedback, independent copies, save/reopen, Undo/Redo, passive area inspection and receiver-cache reuse. [Exact scope and measurements](Vector_Brush_0.78_2026-10-10/README.md). Physical input and heavy scenes remain B04 gates. The pre-0.78 sphere-paint and stroke-history checks below describe the retired method, not current vector support.
- [x] Receiver membership stability: Density and Fixed Total, rename/reorder/remove/restore, save/reopen, plane/sphere paint, Edit clones/radii/protected zero-quota inputs, Manual/Live and receiver-local cache reuse. [Research, exact results and transition limits](Receiver_Stability_0.76_2026-10-10/README.md).
- [x] 0.76 Brush aggregate count limits and contiguous face indexing: the real 8-million-link boundary, overflow retention and Undo/Redo recovery pass in Max; 1,000-stroke save/reopen passes. Full playback and courtyard fingerprints/cache reuse remain stable. [Exact evidence and limits](Brush_Scaling_0.76_2026-10-10/README.md).
- [x] Retained Proxy drawing, one root refresh per explicit Update, Analyzer revision reuse, and stale-Analyzer guards including immediate edits/save/reopen/merge. [Final matched-build results](Courtyard_Fixes_0.75_2026-10-10/README.md): 84 focused host checks, 942 playback assertions, native/Python regressions and Corona geometry smoke passed.
- [x] Manual pending edits no longer publish after unrelated Undo/Redo in the tested scenario.
- [x] Layer-owned receivers and optional receiver-bound Paint Areas; plane/sphere, inactive targets, shared models and coverage union.
- [x] Layout accessibility, paired transform fields and radio-caption overlap correction.
- [x] Current scripted feature campaign, 942 Scatter/Analyzer playback assertions and clean Corona lifecycle. See [exact scope and failed runs](System_Qualification_0.75_2026-10-09/README.md); these are not physical all-control certification.

Historical gates were reconciled from the [unified roadmap](Unified_System_0.73_2026-10-06/ROADMAP.md), [7 October review](Status_0.73_And_Website_2026-10-07/ROADMAP.md), [0.75 consolidation](Consolidation_0.75_2026-10-09/README.md) and [current audit findings](System_Qualification_0.75_2026-10-09/FINDINGS.md). BR-01, export failure handling and projection/radius stress are carried forward explicitly rather than lost during cleanup.

MCP expansion, learning and commercial licensing are separate workstreams. Their existing component contracts remain; research proposals and website work are outside this cleanup and do not authorize additional implementation.

The [courtyard design study](Courtyard_Study_0.75_2026-10-09/README.md) records layer-local paint preparation, one erase taking about 754 ms, and the ten-layer design limit. The [subsequent fixes](Courtyard_Fixes_0.75_2026-10-10/README.md) address Proxy drawing and stale Analyzer visibility and distinguish cold Update, forced warm Update and unchanged cached reads. B04 and the physical artist gates remain open; B02 now has bounded receiver-stability evidence.
