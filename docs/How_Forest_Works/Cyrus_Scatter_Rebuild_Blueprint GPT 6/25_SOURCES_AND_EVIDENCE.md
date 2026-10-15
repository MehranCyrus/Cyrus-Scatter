# 25 — Sources, evidence, and provenance

**Evidence checked for this package: October 13, 2026. Proposed-design version: CyrusV1 blueprint 1.0.**

## 1. What the package is based on

The requested basis is the supplied **ForestPack Deep Technical Study**, filename `Research Forest 2.md`, identified as **R0** throughout these chapters. Its objective is to understand feature behavior, interactions, and independently implementable equivalents. Its distinction between documented behavior, engineering interpretation, and proposed implementation is retained here.

The original has been copied byte-for-byte to [sources/Research Forest 2.md](sources/Research%20Forest%202.md). Its SHA-256 is:

```text
3c31c0e70ab6b8ed6fe4664516ad4a49c94b75a0b5a24f7ab2ea4582869ab013
```

The copy preserves its wording, including its own uncertainties, historical claims, citation formatting, and proposals. It has not been silently edited to agree with this blueprint. The copied document's broken favicon-style references are original content, not a replacement for the source registry below.

**R0 is not source code.** It does not establish ForestPack's complete private implementation, and it does not establish the state of the current Cyrus repository.

## 2. How evidence labels work

| Label | Meaning | What it does not mean |
|---|---|---|
| R0 section reference | Supplied research supports the feature family, terminology, or discussion | Its proposed algorithms are vendor internals |
| S01–S28 | A specific primary-source entry in the registry below | Every line of an entire chapter comes from that page |
| Proposed Cyrus design | An original selected behavior, architecture, algorithm, default, or test obligation | Implemented, benchmarked, or exactly identical to ForestPack |
| Executed reference check | The included Python function/test ran in this environment | Max, C++, geometry SDK, GPU, renderer, or production validation |
| Unresolved / qualification gate | External evidence or runtime experiment is still needed | Permission to guess an SDK interface or hide a limitation |

Most implementation detail in these chapters is an **independent proposal**. A chapter can cite a documented feature and then select a different, explicitly named Cyrus behavior. That is particularly important for stable overrides, painting authority, exact incremental collisions, and final-render freshness.

## 3. Mapping the supplied research to the rebuilt specification

| R0 section | Preserved subject | Blueprint chapters | Added specification |
|---|---|---|---|
| 1 — complete system | Connected subsystems | 01–04 | Ownership, immutable snapshots, semantic stages, versioning |
| 2 — distribution | Image, Path, Reference, particles, diversity | 07, 10–11, 14 | Canonical addresses, coordinate contracts, selected collision solver |
| 3 — areas/surfaces/paint/falloff | Region and receiving-surface distinction | 05–09 | Exact ordered contributions, canonical paint, bindings, error policies |
| 4 — sources/transforms/editing | Source properties and refinement | 03, 10–12 | Stable identity and explicit pinned/constrained edit semantics |
| 5 — outputs/materials/animation | Separate population and presentation | 13–15 | Adapter qualification, secondary-ray caveats, sample lifetime |
| 6 — Effects | Programmable property relationships | 06, 16 | Typed staged execution, bounded queries, dependency declarations |
| 7 — shared systems | Collections, presets, diagnostics | 17–18 | Versioned schemas, safe imports, commands and transaction rules |
| 8 — proposed architecture | Shared preparation and caches | 02–04, 09, 11, 17 | Revision fingerprints, exactness conditions, host boundaries |
| 9 — worked environment | Related grass/tree/flower/rock layers | 24 | Explicit revision scenarios and expected surviving intent |
| 10 — behavioral experiments | Controlled fixtures | 20 | Fixture IDs, statistical tests, scope of actual execution |
| 11 — coverage/milestones | Full product implementation plan | 21–22, 26 | 301 proposed controls/commands, dependencies and gates |
| 12–13 — clues/references | Documented mechanisms and research limits | 23, 25 | Decision register, evidence registry, unresolved version/ABI questions |

## 4. Explicit refinements, not hidden corrections

Chapter 23 records the selected departures from R0. The most consequential are: cache partitions are not instance identity; a collision halo is not sufficient to guarantee a local greedy result; occupancy-relevant edits run before occupancy; ordinary paint is defined by current canonical tiles rather than compulsory history replay; an independent Empty probability can sometimes be factored into a survival gate and conditional source choice.

These are original mathematical/design analyses. They do not claim that ForestPack uses the proposed replacement algorithms. The exact collision proposal is limited to the documented solver assumptions in chapter 11 and the executable reference; a different solver must supply its own proof/test obligations.

## 5. Primary-source registry

“Read” means the page body was retrieved for this work. It does not mean every product version or option combination was executed. Page titles and URLs are included so the evidence remains usable outside the chat.

| ID | Primary source | Retrieval status | Supported scope / qualification |
|---|---|---|---|
| S01 | [ForestPack — Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas) | Read | Area types, ordered behavior, exclusions, paint and falloff controls. Mixed-era XY/UV restrictions require target-build tests. |
| S02 | [ForestPack — Image distribution](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode) | Read | Distribution image controls, selection modes, candidate limits and collision behavior. Not a disclosure of the exact random generator. |
| S03 | [ForestPack — Surfaces](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces) | Read | Projection modes, normal/altitude/slope controls and prepared surface information. |
| S04 | [ForestPack — Path distribution](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode) | Read | Path input, spacing, vertices, source sequence and tangent-related behavior. |
| S05 | [ForestPack — Reference distribution](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode) | Read | Reference-object and face inputs, transform inheritance and source matching. |
| S06 | [ForestPack — Particle Flow distribution](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/particle-flow-mode) | Read | Particle Flow as a placement input. This does not establish the design of a Cyrus output transport. |
| S07 | [ForestPack — Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry) | Read | Source definitions, weights/empty outcomes, dimensions and group behavior. |
| S08 | [ForestPack — Transform](https://docs.itoosoft.com/forestpack/forest-plugin/transform) | Read | Transform controls, maps, probability controls and post-placement translation warning. |
| S09 | [ForestPack — Items Editor](https://docs.itoosoft.com/forestpack/forest-plugin/item-editor) | Read | Generate/Custom Edit controls. Does not establish persistent-override guarantees for arbitrary regeneration. |
| S10 | [ForestPack — Display](https://docs.itoosoft.com/forestpack/forest-plugin/display) | Read | Viewport and rendering representations, display limits and output distinctions. |
| S11 | [ForestPack — Camera](https://docs.itoosoft.com/forestpack/forest-plugin/camera) | Read | Camera-relative controls and their visible consequences. Not proof that primary-frustum removal is secondary-ray safe. |
| S12 | [ForestPack — Forest LOD](https://docs.itoosoft.com/forestpack/forest-plugin/forest-lod) | Read | Alternative-source selection by distance or screen size; not a general mesh-decimation algorithm. |
| S13 | [ForestPack — Material](https://docs.itoosoft.com/forestpack/forest-plugin/material) | Read | Tint controls and material integration responsibilities. |
| S14 | [ForestPack — Forest Color](https://docs.itoosoft.com/forestpack/forest-color) | Read | Whole-item and element-level material variation. |
| S15 | [ForestPack — Forest Edge](https://docs.itoosoft.com/forestpack/forest-edge-map) | Read | Element-based boundary behavior and renderer-dependent integration; not general polygon Boolean clipping. |
| S16 | [ForestPack — Animation](https://docs.itoosoft.com/forestpack/forest-plugin/animation) | Read | Source-time sampling modes and bounded geometry-sample caching. |
| S17 | [ForestPack — Effects attributes](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/attributes) | Read | Published readable/writable attributes; does not reveal internal memory layout or full private stage order. |
| S18 | [ForestPack — ForestSet](https://docs.itoosoft.com/forestpack/forestset-plugin) | Read | Reusable collections and role-dependent input behavior. |
| S19 | [Chaos — V-Ray for 3ds Max SDK documentation entry](https://documentation.chaos.com/space/VMAX/113575055) | Located; body unavailable | An official entry was located, but its usable implementation content was not retrieved. No adapter ABI or capability is inferred from it. |
| S20 | [Autodesk — 3ds Max API portal](https://aps.autodesk.com/developer/overview/3ds-max-api) | Read | Official SDK entry point. Not an API-by-API concurrency guarantee or renderer integration specification. |
| S21 | [Autodesk Max 2024 — IPainterCanvasInterface_V5](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_i_painter_canvas_interface___v5.html) | Read | Stroke lifecycle and hit data; effective radius/strength already include brush modifiers; evaluated-mesh binding warning. |
| S22 | [Autodesk Max 2024 — Hold](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_hold.html) | Read | Native Undo transaction interface. Integration still requires a real host test. |
| S23 | [Autodesk Max 2026 — RestoreObj](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_restore_obj.html) | Read | Restore/Redo lifecycle and repeated-call requirements. Verify against the actual shipping SDK before compilation. |
| S24 | [Autodesk Max 2024 — IObjectDisplay2](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_max_s_d_k_1_1_graphics_1_1_i_object_display2.html) | Read | Modern viewport display interface and shared/per-node preparation boundaries. |
| S25 | [Autodesk Max 2026 — MainThreadTaskManager](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/_main_thread_task_manager_8h.html) | Read | A documented route for posting tasks to the Max main thread in the cited SDK. Does not prove identical availability in Max 2024. |
| S26 | [ForestPack — Rendering best practice](https://docs.itoosoft.com/forestpack/rendering/rendering-best-practice) | Read | Renderer-oriented instancing and memory guidance. Not a measured Cyrus benchmark. |
| S27 | [ForestPack — Effects syntax](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/effects-syntax) | Read | Published expression and parameter concepts. Cyrus DSL/schema details remain an independent design. |
| S28 | [ForestPack — ForestIvy overview](https://docs.itoosoft.com/forestpack/forest-ivy/forest-ivy-overview) | Read | Companion growth product scope only; not an exhaustive Ivy control audit. |

## 6. Version boundaries

R0 records ForestPack release information from its own research date. This blueprint does not make feature behavior depend on an unverified claim that one particular release is currently latest. An implementation/parity project must record the installed ForestPack version used for every comparison fixture.

Likewise, Autodesk references above include both Max 2024 and Max 2026 documentation. A later API page is not proof of an identical signature or supported callback in an earlier SDK. Build and test against the exact selected headers, compiler toolset, renderer build, and host service pack. Record the qualified matrix in the product rather than generalizing from one configuration.

The conservative host-access policy in chapter 17 is a selected safety boundary, not a purported complete thread-safety table extracted from the API portal.

## 7. Unavailable evidence

No ForestPack private source code was accessed. The full tutorial narration and complete playback were not used as evidence for this package. The current Cyrus repository was not inspected or modified during this task. Exact Corona/V-Ray/Arnold integration routes and source/proxy support remain qualification work; the unreadable SDK entry S19 is not treated as technical proof.

Existing Cyrus integration names and the C++/MAXScript split come from project context. They identify audit targets, not verified current source contracts. No inference about current renderer versions is made from old project conversations.

## 8. What was actually executed

The standard-library Python reference script ran **12 check groups**, all passing in the saved report. It includes **240 spatial-grid-versus-naive collision comparisons** and **600 exact-incremental-versus-full collision comparisons**, plus deterministic sampling, paint arithmetic, curve sampling, ordered contributions, and boundary cases.

The results are in [examples/reference_validation.json](examples/reference_validation.json). The script is [examples/reference_oracle.py](examples/reference_oracle.py), with instructions in [examples/README.md](examples/README.md).

Its elapsed times are only timings of these tiny Python tests. They are not scatter benchmarks and cannot predict Max brush latency, GPU throughput, or renderer memory. Exact array restoration in the script is not evidence that a Max Hold/RestoreObj implementation works.

## 9. Evidence required before advertising parity

A parity claim needs a control-level record, a licensed reference fixture, an exact tested version, a comparison method, and observed results. Architectural similarity, a matching label, or a plausible equation is insufficient. The 301-entry catalog is a **build specification**, not a certified vendor-control transcription.

New research should update this registry and the relevant decision/test record. Do not replace an explicit unknown with an unreferenced assumption merely to close a ticket.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S01]: https://docs.itoosoft.com/forestpack/forest-plugin/areas
[S02]: https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode
[S03]: https://docs.itoosoft.com/forestpack/forest-plugin/surfaces
[S04]: https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode
[S05]: https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode
[S06]: https://docs.itoosoft.com/forestpack/forest-plugin/distribution/particle-flow-mode
[S07]: https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry
[S08]: https://docs.itoosoft.com/forestpack/forest-plugin/transform
[S09]: https://docs.itoosoft.com/forestpack/forest-plugin/item-editor
[S10]: https://docs.itoosoft.com/forestpack/forest-plugin/display
[S11]: https://docs.itoosoft.com/forestpack/forest-plugin/camera
[S12]: https://docs.itoosoft.com/forestpack/forest-plugin/forest-lod
[S13]: https://docs.itoosoft.com/forestpack/forest-plugin/material
[S14]: https://docs.itoosoft.com/forestpack/forest-color
[S15]: https://docs.itoosoft.com/forestpack/forest-edge-map
[S16]: https://docs.itoosoft.com/forestpack/forest-plugin/animation
[S17]: https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/attributes
[S18]: https://docs.itoosoft.com/forestpack/forestset-plugin
[S19]: https://documentation.chaos.com/space/VMAX/113575055
[S20]: https://aps.autodesk.com/developer/overview/3ds-max-api
[S21]: https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_i_painter_canvas_interface___v5.html
[S22]: https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_hold.html
[S23]: https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_restore_obj.html
[S24]: https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_max_s_d_k_1_1_graphics_1_1_i_object_display2.html
[S25]: https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/_main_thread_task_manager_8h.html
[S26]: https://docs.itoosoft.com/forestpack/rendering/rendering-best-practice
[S27]: https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/effects-syntax
[S28]: https://docs.itoosoft.com/forestpack/forest-ivy/forest-ivy-overview
