# Research assignment: GPU computation for Cyrus Scatter vegetation interaction

Act as a senior research team covering GPU parallel algorithms, numerical geometry, constrained deformation, Windows graphics interoperability, Autodesk 3ds Max SDK engineering, and performance measurement.

Conduct a thorough, evidence-based technical investigation. Produce an implementable architectural recommendation, a reproducible validation program, and a ZIP of organized Markdown documents. This is research and design, not authorization to modify our production repository or claim delivery of a working Max plugin.

## 1. The decision we need

We develop **Cyrus Scatter**, a native C++ procedural scattering plugin for **3ds Max 2027 on Windows x64**. Artists scatter grass, flowers, bushes, trees, rocks, and architectural elements. A collider instance can be moved independently; nearby plant instances bend around it while their roots remain attached. We want substantially lower drag latency and greater scale.

We are willing to prioritize **NVIDIA/CUDA** and recommend NVIDIA hardware **if the evidence supports that decision**. Do not assume CUDA is inherently faster than OpenCL. Determine which approach best fits our actual workload, quality requirements, Max integration, engineering effort, and distribution constraints. A conclusion favoring CUDA, OpenCL, graphics shaders, a hybrid, or the existing CPU path is acceptable when justified.

The crucial distinction is between:

1. Millions of resident scatter instances with only a small neighborhood changing.
2. Many thousands of affected guides or plants changing together.
3. Millions of blades or vertices changing together.
4. Millions of detailed plant clumps changing together, potentially with hundreds of guides each.

Define these populations separately. Identify physically or economically impractical configurations rather than extrapolating unlimited performance.

## 2. Provided project baseline

Use these statements as **provided project facts**, not independently verified observations. You do not have access to our repository, installed Max, or GPU unless explicitly supplied. The companion `CURRENT_SYSTEM_CONTEXT.md` contains additional detail, verified local source locations, and evidence limits.

- Current scoped release: **0.87.4.3**, native interaction capability **11**, scene schema **63**. The present development target is Max 2027 only.
- The plugin uses native C++ for bulk numerical work and retained viewport data; generated MAXScript/managed code handles UI and bounded authored coordination.
- Each unique source is prepared once into shared geometry, guide chains, parent relationships, fixed anchors, foliage bindings, and source fingerprints. Preparation includes artist overrides. Instances reuse this data with individual transforms and sparse pose results.
- CPU spatial indexes find affected plants near both the old and new collider positions. Both published and independently edited collider transforms are considered. Unaffected results remain cached.
- A native CPU fitter queries closed collider meshes/proxies, bends contacting guides, preserves rooted attachments, and can perform expensive visible-surface refinement. Branches and attached foliage follow their assigned guides. A clear guide centerline alone does not prove clear leaf surfaces.
- This is currently **static/quasistatic contact fitting during edits**, not a time-integrated wind or rigid-body simulation. Leaving a collider restores the plant's rest state. Do not replace this behavior with a history-dependent simulation without explicitly discussing the difference.
- Contact gap controls bending clearance. Hide margin controls root-group exclusion separately. Hiding offers Inside solid and an explicit downward footprint mode, Under collider. Hiding removes a rooted group and its attachments; a failed solver must not silently remove geometry.
- Internal geometry calculations use metres and +Y up; Max uses its scene units and +Z up. Conversion occurs at explicit boundaries. Admitted instance transforms currently require positive uniform scale; arbitrary negative scale, nonuniform scale, and shear are not qualified support.
- Collision classification and fitting are CPU work today. The viewport uses public Max SDK retained custom render items, instanced triangle drawing, GPU buffers, and HLSL shaders. The existing draw path does **not** expose or use a raw Direct3D device or compute runtime.
- Current admissions include 1,000,000 instances per native interaction layout, 16,384 collider instances, 64 relevant colliders per plant, 4,096 transient instance overrides, and bounded memory/query work. These are safeguards, not demonstrated realtime capacities.
- The CPU executor is synchronous today. Workers operate on copied/owned numerical snapshots. Max scene API access and publication belong to the host thread. An asynchronous GPU scheduler would be a new subsystem requiring explicit lifetime and stale-result rules.
- One observed fixture contains 200 plant instances and one collider. Each source plant has 451 guides, 22,032 vertices, and 27,501 triangles. In one update only three nearby candidates were found, six guides were fitted, and 62 rooted groups were hidden. Native contact evaluation took about **4.05 ms** in that run. This is **not** input-to-present latency, full-frame time, a million-instance test, or a GPU benchmark.
- A separate 5,000-instance numerical test verifies one affected footprint neighborhood. It does not qualify 5,000 complex plants bending simultaneously. There is no existing CUDA/OpenCL interaction backend to benchmark.

## 3. Research discipline and evidence

Browse current primary sources: vendor documentation, Autodesk SDK documentation/samples, original papers, and source repositories. Verify publication dates, software/API versions, repository revisions, licenses, and hardware conditions. Blogs can explain a concept but should not be the only support for a consequential API or numerical claim.

For every important conclusion, distinguish:

- Verified public documentation or source.
- Provided project facts.
- Results actually executed in your environment.
- Analytical estimates with explicit assumptions.
- Proposed designs, hypotheses, and unknowns requiring local validation.

Never fabricate benchmarks, GPU access, successful compilation, Max testing, repository file contents, SDK methods, or download artifacts. Cite near each substantive sourced claim, with a full source ledger. If execution is unavailable, provide reproducible experiment specifications and mark them **not executed**.

Be especially strict about this distinction: **CUDA supports Direct3D interoperability** does not prove that **Max 2027's public SDK exposes the necessary resources with supported ownership and synchronization**.

## 4. Explain parallel execution for this exact problem

Give an accessible explanation followed by a precise technical design. Show where parallelism exists and where dependency or synchronization restricts it.

Investigate:

- Work decomposition by instance, guide, span, node, collision pair, triangle, vertex, and parent-depth level.
- Thread-per-node, warp/subgroup-per-guide, and block/workgroup-per-plant scheduling. Explain divergence for plants with very different sizes or contact complexity; do not assume one thread per whole plant is optimal.
- Independent rooted groups versus hierarchical branches. Compare level scheduling, Jacobi-style updates, Gauss-Seidel dependencies, graph coloring, and other justified schemes.
- Compact active lists, prefix scans, sorting, work queues, sparse updates, and deterministic ordering by stable IDs.
- SoA/AoSoA layouts and buffer schemas for shared sources, guides, bindings, transforms, collider instances, sparse poses, visibility masks, diagnostics, and candidate pairs.
- CPU/GPU division for small and large active neighborhoods, including dispatch overhead and a measured crossover threshold.
- Data residency: upload prepared source data once, update changed transforms and compact pose data, and avoid rebuilding the entire scene or transferring full meshes on every pointer event.

Provide a stage-by-stage dataflow diagram and pseudocode. Explain the complexity and byte counts in terms of total instances N, affected instances K, guides G, vertices V, collider count C, and contact-pair count P. Do not hide N×G or N×V storage behind the word “instancing.”

## 5. Compare architectures before choosing an API

Evaluate at least these alternatives separately:

1. Optimized CPU fitting and CPU deformation, retaining the present architecture.
2. CPU fitting with GPU vertex/normal deformation from compact guide poses using supported graphics shaders.
3. CPU neighborhood search with GPU guide/contact fitting and GPU deformation.
4. GPU neighborhood search, fitting, and deformation with persistent resident scene data.
5. A hybrid using simple GPU collision proxies or fields for interactive work, with explicitly defined refinement/verification.

For each, identify what stays on the CPU, what reaches the GPU, every transfer and synchronization point, expected quality, memory growth, implementation effort, recovery behavior, and actual Max integration requirements.

Distinguish deforming vertices in a vertex shader from solving collisions in compute kernels. Compare storing full per-instance deformed meshes with drawing shared source vertices while gathering individual guide poses. Preserve normals/tangents, UV seams, material IDs, whole-group visibility, root anchors, and branch attachments.

A CUDA/OpenCL solver is not required merely to move skinning into a graphics shader. Conversely, graphics instancing alone does not calculate physical contact. Explain both clearly.

## 6. CUDA versus OpenCL, with graphics compute as a relevant baseline

Compare CUDA and OpenCL on the **same NVIDIA GPU** with matched algorithms, precision, input sets, output quality, transfer policies, and reasonably comparable tuning effort. Separately discuss cross-vendor portability. Do not attribute an algorithmic improvement to an API brand.

Cover:

- Compilation/toolchains, debugging, profiling, deployment, runtime availability, driver requirements, and compatibility with the actual Max 2027 compiler/runtime matrix.
- Dispatch and synchronization overhead; streams/queues; command graphs where supported; sorting/scanning primitives; subgroup operations; memory allocation and pooling; reduction/atomic costs.
- FP32/FP64/mixed precision, fused operations, fast-math behavior, deterministic ordering, and consumer versus workstation/datacenter hardware differences.
- Graphics interoperability and resource lifetime restrictions in our host, not just standalone sample applications.
- NVIDIA-only support costs versus broader hardware support; distinguish “recommended” from “required.” A CPU fallback may still be valuable on unsupported devices.
- D3D11 compute or ordinary vertex-shader deformation as alternatives where they reduce integration friction. Discuss D3D12/Vulkan only when relevant and supported; do not assume the current Max viewport can be replaced or its device taken over.
- Whether CUDA libraries or developer tooling materially reduce our implementation risk even where raw kernel speeds are similar.

End with a weighted decision matrix. Include sensitivity to workload size and to interoperability being unavailable. State what benchmark or SDK finding would reverse your recommendation. Do not force a universal winner when the evidence supports a conditional decision.

## 7. Collision and guide-solving research

Investigate algorithms suitable for rooted vegetation, not simply unconstrained rigid bodies:

- Analytic spheres/capsules/boxes, convex hulls, compound trunk-and-root proxies, closed mesh BVHs, distance fields, sparse/narrow-band SDFs, and instance-space reuse of collider assets.
- Old/new neighborhood invalidation, BVH refit versus rebuild, spatial hashes/grids, and GPU broad phase. A local drag must not trigger an unnecessary full-scene index rebuild. Downward footprint bounds must not destroy horizontal spatial locality.
- Whole-segment/capsule contact, leaf thickness/width, foliage envelopes, signed point classification, reliable surface witnesses/normals, multiple contacts, and contacts missed by point-only sampling.
- PBD/XPBD, discrete elastic/Cosserat rods, projective dynamics, constrained quasistatic optimization, analytical bending/hinge approaches, and hair/cloth techniques where transferable. Explain which solve our current task and which introduce new time/state semantics.
- Parent/child attachments, fixed roots or root rings, branching topology, leaf orientation/twist, finite rotations, and strain limits.
- Exact mesh queries versus SDF approximation: voxel size, interpolation/gradient error, thin features, conservative offsets, occupancy ambiguity, field construction/update costs, and cache invalidation.
- Multiple colliders squeezing the same plant; infeasible fits; root penetration; broad leaves crossing a collider although their guide is clear; one-sided/open geometry; malformed solids.
- Fast drags, teleports, rotational/scale changes, temporal coherence, warm starts, popping/jitter, and whether swept/continuous queries are needed for the intended semantics. Do not claim endpoint quasistatic fitting supplies continuous collision detection.

Keep Contact gap and Hide margin independent, apply each clearance exactly once, and specify coordinate/scale conversion. If lower-quality interactive approximation is recommended, define its error, artist-visible status, and final refinement; never silently solve only a subset of blades and hide the rest as a performance shortcut.

## 8. Max 2027 integration is a feasibility gate

Research the actual public SDK and provide concrete, version-qualified evidence for each proposed access path:

- Current retained custom render items, IVirtualDevice, vertex/index/texture handles, HLSL material support, and the ability or inability to use compute-written resources.
- Whether public interfaces expose a compatible native D3D resource/device or supported shared-resource mechanism. Name the exact interfaces/methods/headers and restrictions when verified. If only older documentation is available, label it historical and list the required 2027 check.
- CUDA graphics registration versus external-memory/semaphore interoperability, and OpenCL graphics sharing where relevant. Explain resource creation flags, map/unmap or fence ownership, and restrictions on concurrent compute/draw access.
- Adapter/device identity, Windows LUID/UUID matching, multiple NVIDIA cards, an AMD/Intel display GPU plus a separate CUDA GPU, laptops/Optimus, and multi-monitor cases. Do not assume zero-copy sharing across adapters.
- The difference between interop possible in a standalone D3D application and interop supported inside Nitrous. Avoid unsupported pointer extraction, private APIs, and taking ownership of Max's graphics context.
- A fallback design if GPU solve results cannot be shared directly: compact guide-pose readback, CPU validation/deformation, or CPU solve plus supported shader deformation. Calculate what each fallback costs.
- Renderer/Bake/export consistency: GPU-only viewport geometry does not automatically become the geometry consumed by Arnold, V-Ray, Corona, other renderers, or exporters. Specify how final meshes/poses are materialized at requested times and what must be validated locally.

Provide a small **interop proof specification** as an early go/no-go gate, before a full GPU solver investment. Separate standalone compute proof, standalone graphics-sharing proof, supported in-Max proof, and renderer/export proof.

## 9. Asynchrony, state, and reliability

Design an event-to-result timeline for collider dragging:

- Copied snapshots, source fingerprints, stable IDs, geometry/transform revisions, and ownership of every CPU/GPU allocation.
- Coalescing pointer updates, discarding superseded requests, GPU work already in flight, bounded dispatches, and publishing only the newest complete valid successor.
- Preventing stale results after Undo/Redo, deleting an instance/owner, replacing a source, changing units, loading/resetting a scene, or shutting down Max.
- CPU host-thread boundaries versus worker threads and GPU commands; no scene SDK calls from compute kernels or arbitrary workers.
- Double/triple buffering with explicit peak memory, fences and retirement. Current synchronous workers do not establish asynchronous safety.
- Device loss/reset, Windows TDR, VRAM exhaustion, fragmented memory, allocation/kernel failures, unsupported devices, driver changes, headless sessions, remote desktop, and graphics-device recreation.
- Preserving the last complete result and artist recovery, reporting incomplete/approximate/stale state, and CPU fallback policy.
- Keeping GPU pointers, device handles, allocator state, and transient caches out of portable scene/recipe persistence. Define rebuild after reopen.

Do not turn unrelated animation, UI browsing, Wireframe toggles, or camera changes into new static collision solves or unchanged buffer uploads. View-dependent detail, if proposed, needs its own explicit ownership and error policy.

## 10. Numerical accuracy, memory, and hardware practicality

Analyze FP32/FP64/mixed precision against the CPU reference. Cover large architectural world coordinates, small stems, local rebasing, grazing contacts, parallel/coplanar triangles, zero-length spans, nearly singular transforms, unit changes, NaNs, and tolerance scaling.

Separate reproducibility from mathematical correctness and visual acceptance. Define invariants and tolerances for root drift, branch attachment, penetration, maximum edge strain, angular discontinuity, and rest restoration. Quantify any approximation rather than treating a guide-only collision test as full-surface proof.

Budget shared immutable geometry separately from active poses, candidate lists, BVHs/SDFs, renderer copies, graphics buffers, upload/readback buffers, scratch, queued generations, and retained history. Show practical lower-bound byte calculations for representative scenes. Unified memory is not automatically free of transfers or page faults. VRAM already used by Max and rendering must be considered.

Assess representative supported NVIDIA GPU generations and memory capacities using actual documentation. Do not recommend a particular expensive GPU or CUDA minimum merely because it is recent. Establish feature, architecture, driver, and compiler requirements from the chosen implementation and evidence. Discuss sharing one GPU between compute, the viewport, and GPU rendering.

## 11. Benchmark and validation plan

Provide a manageable core matrix plus stress extensions, not an impractical exhaustive cross product:

- Total instances: 1k, 10k, 100k, 1M; beyond the current limit is a future capability test, not current support.
- Affected instances: 1, 10, 100, 1k, 10k, and large-area/all-active cases where memory permits.
- Different guide counts, including simple blades and the supplied 451-guide grass; short versus long chains; branched plants; broad leaves; shared versus distinct source assets.
- Source complexity from simple assets through high-poly models; 1/8/64 relevant colliders and much larger global collider populations; moving one versus many colliders.
- Rest, sparse changed guides, many unique poses, hidden groups, multiple close obstacles, small and large clearances, warm and cold caches, initial GPU compilation, and changing collider/source geometry.

For every case specify seed, geometry/asset fingerprint, units, transforms, active-work counts, precision/quality, hardware/software/build flags, warm-up, repetition, and failure criteria. Keep test input/quality equal across implementations. Include the CPU fallback and failure-retention cases.

Measure separately:

1. Host capture/invalidation and neighborhood search.
2. Guide/contact solving and visible-surface refinement.
3. Vertex/normal deformation.
4. Upload/readback bytes and completed transfer time.
5. Synchronization, host publication, and GPU drawing.
6. Actual input-to-present latency and sustained presented frame rate.
7. CPU/VRAM peak, queued/history memory, cold cost, and recovery.

Report p50/p95/p99, worst spikes, convergence/failure rates, and correctness errors. Discuss 30/60/120 Hz budgets as targets, not claims. CUDA event timings alone are not Max drag latency; CPU command submission is not completed GPU work. Explain critical paths and overlapping work instead of naively adding or hiding timings.

Use appropriate vendor profilers and Windows/Max presentation instrumentation, with version-qualified instructions. If no hardware/Max execution is available, deliver benchmark specifications or minimal reproducible harnesses labeled **not executed**. No invented speedup ratios or linear extrapolation from one small case to millions.

## 12. Papers and reusable implementations

Find relevant original work on GPU constraint solving, PBD/XPBD, rods, GPU hair/cloth, vegetation contact/wind deformation, BVHs, SDF collision, and GPU deformation/instancing. Explain which part transfers to our problem and its limitations.

Inspect useful repositories and actual code paths. Candidate starting points include NVIDIA CUDA samples, NVIDIA Warp, GPU hair/cloth projects such as TressFX, Khronos OpenCL samples, and suitable BVH/distance-field implementations. These are search leads, not an assumption that any supplies a drop-in solution. Verify URLs, current/historical maintenance, exact files, commit IDs, licenses, redistribution terms, dependencies, and Max applicability.

For each useful source provide: reference/URL, date/version, relevant idea, exact algorithm or source location, reuse versus reimplementation recommendation, numerical assumptions, hardware/quality conditions behind performance claims, licensing implications, and evidence confidence. Distinguish GPU rigid-body support from our deformable rooted-guide solver. Do not assume Jolt/PhysX or another CPU library can be recompiled directly into a CUDA replacement.

## 13. Required recommendation and implementation gates

Deliver a decisive, conditional recommendation with alternatives and falsifiers. Propose the smallest high-value next prototype, followed by staged gates:

1. Confirm workload bottlenecks and CPU reference/correctness fixtures.
2. Prove supported Max graphics/data interoperability, or select a feasible fallback.
3. Test a narrow GPU deformation implementation against the existing guides, including normals, visibility and final geometry delivery.
4. Evaluate GPU collision/guide fitting only where measured costs justify it.
5. Test sparse large scenes and large active regions separately.
6. Qualify lifetimes, Undo, failure recovery, rendering/export and distribution.

Reorder these gates if evidence supports a better sequence. For every phase give inputs/outputs, ownership, interfaces, resource budgets, tests, measurable go/no-go criteria, rollback/fallback, and unresolved local checks. Provide pseudocode or small isolated kernel/interface examples where useful; label sketches versus actually compiled/executed code. Avoid speculative production code dumps or a generic GPU framework.

Specify a minimal artist workflow and diagnostics. Preserve simple Collider/React/Prepare controls; do not expose every kernel tuning choice in the main UI. Clarify what can safely be automatic, what is an explicit quality choice, and what an unsupported GPU experiences.

For distribution, verify CUDA/OpenCL runtime and compiler redistributable terms, DLL loading behavior, supported host compiler/CRT combinations, signed installer implications, and plugin startup when the compute runtime or driver is absent. A GPU option should not accidentally prevent the existing CPU plugin from loading. Define cold JIT/AOT behavior, cache keys and invalidation across driver, GPU architecture, kernel, source, and settings changes; bound compilation/cache costs rather than compiling a unique program for every instance.

## 14. Deliverables: organized Markdown files and a real ZIP

Create a directory named `CyrusScatter_GPU_Interaction_Research_<YYYY-MM-DD>_<researcher-id>` containing at least:

```text
00_README.md
01_EXECUTIVE_DECISION.md
02_REQUIREMENTS_AND_CURRENT_SYSTEM.md
03_PARALLELISM_AND_DATA_LAYOUT.md
04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md
05_COLLISION_AND_GUIDE_SOLVING.md
06_GPU_DEFORMATION_AND_INSTANCING.md
07_MAX_2027_INTEROP_FEASIBILITY.md
08_ASYNC_PUBLICATION_AND_LIFETIMES.md
09_MEMORY_PRECISION_AND_HARDWARE.md
10_BENCHMARK_AND_VALIDATION_PLAN.md
11_EDGE_CASE_AND_FAILURE_MATRIX.md
12_PAPERS_AND_REUSABLE_IMPLEMENTATIONS.md
13_PHASED_IMPLEMENTATION_PLAN.md
14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md
15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md
16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md
17_SOURCE_LEDGER.md
18_ACCEPTANCE_CHECKLIST.md
RESEARCH_METADATA.json
MANIFEST.sha256
```

Use relative links between documents and diagrams where they clarify data flow or synchronization. Use tables for comparisons, memory budgets, edge cases and acceptance. Cover every requested decision without padding or duplicating chapters.

`11_EDGE_CASE_AND_FAILURE_MATRIX.md` must map each case to its trigger, expected behavior, algorithm hazard, mitigation, reproducible test, and whether it is supported, proposed, rejected, or unknown.

`16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md` must list precise source/SDK/host probes needed locally, explain why each matters, and identify which decisions remain blocked. Do not ask vaguely to “test performance.” Do not assume access to our files.

`RESEARCH_METADATA.json` must record research date/time, researcher/model identity if known, source cutoff/versions, baseline version, available CPU/GPU/Max tools, experiments actually executed, unexecuted proposals, limitations, and artifact inventory. Do not guess model or hardware identity.

`MANIFEST.sha256` must contain actual computed hashes of the included research documents and metadata, excluding itself. Verify local links, ZIP member paths, archive integrity and completeness. Include any runnable prototype source as a clearly separate optional folder with exact build/run instructions and execution status. Do not package large third-party trees, binaries, or proprietary assets unnecessarily.

Create and attach a **real downloadable ZIP** containing the document directory. End your response with a concise recommendation, the highest-risk unresolved integration question, and the ZIP download link. If your environment cannot create attachments, explicitly state that limitation and deliver the complete named files in another available form; never invent a ZIP link.

### Initial primary-source leads — verify current versions yourself

- NVIDIA CUDA platform: https://developer.nvidia.com/cuda
- CUDA best practices: https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html
- CUDA graphics/external-resource interoperability: https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/graphics-interop.html
- Khronos OpenCL: https://www.khronos.org/opencl/
- OpenCL specification registry: https://registry.khronos.org/OpenCL/
- CUDA samples: https://github.com/NVIDIA/cuda-samples
- NVIDIA Warp: https://github.com/NVIDIA/warp
- Khronos OpenCL SDK: https://github.com/KhronosGroup/OpenCL-SDK
- Autodesk developer material for Max 2027: https://blog.autodesk.io/whats-new-in-3ds-max-2027/
- Historical Nitrous low-level API documentation, **not proof of Max 2027 interop support**: https://help.autodesk.com/cloudhelp/2022/ENU/Max-Developer-Help/3ds_max_sdk_features/viewports_and_graphics_windows/nitrous/low-level_device_api.html

Research beyond these leads. The final result must let a local engineering team decide **what to prototype, why, how to validate it, and when to reject the approach**.
