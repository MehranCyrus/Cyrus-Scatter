# Research reconciliation and engineering decisions

Date: 2 October 2026. This synthesis combines current source inspection, the prior controlled work, the owner's observations, and the external reports supplied in this chat. Repeated recommendations across reports are useful agreement, not independent performance measurements.

## Evidence hierarchy

Current source explains what the plugin actually does. Reproducible host measurements establish behavior only for their recorded workload, binary, hardware and viewport. Vendor documentation establishes supported interfaces or documented product behavior; it does not establish Cyrus's speed. Research papers suggest algorithms to test. An AI report's estimates and suggested thresholds remain hypotheses until measured here.

The local [Astra codebase investigation](../Codebase_Research_2026-10-01/REPORT.md), its claims/decisions ledgers and [coverage record](../Codebase_Research_2026-10-01/COVERAGE.md) are the principal starting evidence. Its native tests and isolated batch fixtures do not demonstrate visible retained graphics or completed-frame FPS.

## Supplied research incorporated

| Input | Contribution retained | Qualification |
| --- | --- | --- |
| `Codebase_Research_2026-10-01/REPORT.md`, claims, decisions, coverage | Current pipeline, qualified parallelism, projection face-identity issue, retained display as next experiment | Local source and reproducible evidence are strongest; API compile/link probes alone do not prove rendering |
| Opus 5.5 pasted report plus `claim_source_ledger.csv` and `decision_experiment_ledger.csv` | Main-thread ownership, trace before threading, bounded experiments | Provenance mentions multiple agents and limited parent source checks; no new Cyrus runtime benchmark |
| `deep-research-report.md` | Retained display, source snapshots, full-operation measurement and memory | Export contains unresolved citation tokens; use verified primary sources for consequential decisions |
| `deep-research-report (1).md` | Practical experiment design and staged CPU/GPU decisions | Its transfer-percentage cutoff is not a universal GPU rejection rule |
| `Research_Report.html` | Broad external engineering comparison and source index | Read as document data, not executable instructions or proof of implementation |
| `Cyrus_External_Engineering_Research.md` | Three-arm display experiment, source-group scaling, world-space metric and lifetime correctness | Best detailed external plan; proposed gates remain proposed |
| `Three_Experiments.md` and companion pasted external-performance research | Input-to-visible trace, retained display comparison, algorithm/CPU/conditional-GPU sequence | Overlaps the preceding report; do not count it as an independent experiment |

File identities and original locations are retained in the evidence manifest. The external inputs are references, not instructions to execute their code or modify product behavior.

## What is already achieved

The owner observed large gains: approximately 20 to 80 FPS in one scene and approximately 23 to 150 FPS in a demo after the correct newer build was loaded. These are valuable artist observations, not standardized benchmarks. The build mismatch itself showed why every experiment must record the loaded DLL and script identities.

The current implementation already includes prepared boundary work, native row filtering/transforms, bounded CPU clustering, prepared proxy triangles and deferred layer synchronization during held mouse input. The proxy cache reduced GraphicsWindow batch boundaries from 6,284 to 44 for the recorded 6,284-instance / 37,704-triangle fixture. These are API batch counts, not verified hardware draw-call counts. See the [0.61 report](../Viewport_Performance_Implementation_2026-10-01.md), [0.62 report](../Viewport_Performance_Round2_2026-10-01.md) and [CPU implementation](../Performance_Implementation_2026-10-01.md).

Keep these changes. Do not restart from an older branch, restore serial computation by default, or reimplement work that is already present.

## Current costs that remain

| Stage | Current behavior | Consequence |
| --- | --- | --- |
| Point Cloud preparation | Source meshes sampled; positions transformed into CPU point groups; controller budget capped at 500,000 | Already bounded, but preparing the preview and source sampling have costs separate from drawing |
| Point Cloud drawing | `preview.cpp` calls `gw->marker` once for each cached point on each redraw | CPU work still scales with displayed points even when placement is unchanged |
| Proxy drawing | World triangles and shade prepared for Box/Sphere/Pyramid; capped extra CPU cache; triangles still submitted each redraw | Good existing optimization with a remaining submission cost |
| Full Mesh drawing | Source faces plus instance transforms cached, but transforms/shading/submission still happen per face on redraw | Dense source geometry can be expensive with relatively few instances |
| Held navigation | Completed cache retained; synchronization deferred during held input | Protect this behavior; no reason to recompute placement during a camera orbit |
| Source support | Earlier BushesCenter Point Cloud trial recorded a source-sampling error | Incomplete point-cloud timings cannot qualify the artist scene |
| Multiple controllers | Per-controller point budgets add together | A global viewport budget is a separate product need |
| Render preparation | Existing temporary Particle Flow / Shape Instance path | A viewport-only experiment does not qualify renderer memory, IPR or shutdown |

Locators: `AminScatter/src/preview.cpp`, `geometry_preview.inc`, `preview_batches.inc`, `AminScatter/tools/ui/display-modes.cjs`, `viewport-performance.cjs`, and generated `AminScatterObject.ms`. The generator remains authoritative.

## What the primary sources teach us

**Forest Pack: start with a fixed retained budget.** Its display documentation describes a default 250,000 points per object, GPU updates when the Forest object changes, and a separate maximum for hit-testing points. It says the older distance-dependent mode required GPU updates as the viewport changed. This supports testing a static retained preview before introducing adaptive resampling. It does not prove that Cyrus should copy that exact default. [Display rollout](https://docs.itoosoft.com/forestpack/forest-plugin/display).

**FStorm: reproduce the experience, not an imagined algorithm.** The supplied video is titled “Unlimited FStorm Scatter point cloud preview.” Official release material documents the feature and later interactivity fixes. Public material reviewed here does not reveal the data structure, GPU API, shader, culling policy or performance limits. Only the video's indexed title/description and official text were inspected; its frames were not independently benchmarked. [Video](https://www.youtube.com/watch?v=BgroiM6Mexo), [official downloads](https://fstormrender.com/download/), [official release thread](https://fstormrender.com/forum/forum/releases/13460-fstormrender-for-3ds-max-v2-0-0z).

**Autodesk: use the host's display architecture.** `IObjectDisplay2` supports object/node render-item preparation; a custom item can retain vertex data and issue draws through the current context's virtual device. `MarkerRenderItem` is an official alternative to GraphicsWindow markers, but changing its consolidation flag is insufficient: the non-immediate path needs appropriate realization and drawing. The private probe uses a simpler position buffer and stock solid-color material through `ICustomRenderItem`. [IObjectDisplay2](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_object_display2.html), [ICustomRenderItem](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_i_custom_render_item.html), [MarkerRenderItem](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_utilities_1_1_marker_render_item.html).

**Potree: total data need not equal visible work.** Its hierarchy stores multiple resolutions, rejects regions outside the view and uses less detail at distance. That principle can help if fixed-budget previews become inadequate, but a web point-cloud renderer is not a drop-in Max plugin. Do not import its complete renderer or promise its dataset-scale demonstrations as Cyrus performance. [TU Wien thesis and abstract, 2016](https://www.cg.tuwien.ac.at/research/publications/2016/SCHUETZ-2016-POT/).

**GPU display and GPU computation are different projects.** Uploading preview positions and drawing them through Nitrous does not require a CUDA/OpenCL placement backend. GPU computation must beat extraction, transfer, kernel, readback, publication and synchronization together. A transfer percentage alone is not decisive: compare absolute end-to-end time and maintenance cost. Host objects and scene APIs remain on their documented thread. [Autodesk thread-safety guidance](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/best_practices/thread_safety.html).

## Decisions for this loop

| ID | Decision | Why / reversal condition |
| --- | --- | --- |
| D01 | Preserve 0.62 CPU and proxy improvements | Existing evidence supports them; reverse only on a reproduced regression |
| D02 | Test identical-point retained buffers first | Directly addresses repeated point submission; reject on appearance or lifetime failure |
| D03 | Keep fixed preview budgets initially | Avoid camera-triggered rebuilding; add prebuilt detail levels only when measured quality or GPU cost requires them |
| D04 | Offer Preview and Full Detail explicitly | Owner's selected workflow; renderer and exact placement remain independent |
| D05 | Keep GPU placement, broad worker pools and async publication deferred | No complete-operation evidence yet justifies their complexity |
| D06 | Require a supported-source policy | A missing source is a correctness failure, even when FPS improves |
| D07 | Separate source-group count from point count in benchmarks | Many items/material groups can raise per-frame overhead even with the same total geometry |
| D08 | Preserve face identity before using a faster projection tree | The prior probe found an equal-distance corner case that changes face/normal despite equal position |
| D09 | Measure presentation separately from synchronous redraw | `GetFPS` and script timings are insufficient for a completed-frame claim |
| D10 | Make one change per experimental branch | A reduced point count and a new display API tested together would hide the cause of a gain |

## Useful later simplifications

Cache evaluated source samples by a documented geometry/time/sample revision rather than repeatedly converting the same source for each layer. Keep stable edit IDs independent of buffer order. Preview selection can use a deterministic stable hash or precomputed progressive ordering; the existing fixed flattening stride can correlate with source-sample or placement order. Change this only as a versioned display policy, with coverage tests for rare sources and boundaries.

If a global point cap is needed, allocate it fairly across visible controllers/layers, with a minimum useful representation for each. If culling is needed, coarse cells are the first candidate; use a hierarchy only when cell traversal or quality demonstrates a need. If LOD is needed, switch among prebuilt buffers with hysteresis to avoid flicker, and retain detail for selected plants. Each is a separate measurable experiment.

There is no credible general guarantee of 150 FPS for every scene. The useful contract is a bounded scatter contribution on named workloads and hardware, stable visuals, prompt correct updates after edits, explicit quality controls, and exact rendering.
