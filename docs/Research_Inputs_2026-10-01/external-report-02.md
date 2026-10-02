# Cyrus Scatter Independent Engineering Research — October 1, 2026

## Scope and decisive conclusions

**Execution boundary.** The uploaded independent-web brief requires two deliberately separate investigations: a codebase/runtime pass in Codex and a repository-independent external pass, with conclusions withheld from each other until both initial reports exist. fileciteturn0file0 The supplied Project Context explicitly says that its detailed implementation information should be kept out of the first external pass and that the local `F:\Cursor\_Cyrus_Apps\CyrusScatter` tree is not remotely accessible without a real connection. fileciteturn0file1 I therefore used the Project Context only to enforce that separation while conducting the external research below; its project-specific performance claims did **not** determine the external conclusions.

Only **Prompt 2** and the **Project Context** were available in this session; `01 - Codex GPT 6 Astra - Codebase Research.txt` and the CyrusScatter repository were not supplied here. Consequently, this report completes the **independent external research pass**, but it does **not** pretend that Prompt 1, current-source inspection, runtime identity checking, local 3ds Max measurements, or the final two-report reconciliation have occurred. That distinction matters because the external brief explicitly forbids diagnosing CyrusScatter’s actual bottleneck without local evidence. fileciteturn0file0

The strongest conclusion from the independent pass is conservative: **there is no present evidence for a production GPU-compute backend, a persistent asynchronous job system, a multi-backend abstraction, or a rewrite.** There *is* strong evidence for three narrower directions: make full-workflow measurements first; keep CPU computation on owned numeric data with Max access on the permitted thread; and, if viewport preparation/submission is still material after profiling, test Autodesk’s retained Nitrous instancing path as a small, reversible viewport experiment. Autodesk documents both the host-thread-safety constraint and a supported GPU-level viewport-instancing API in the target SDK generation. citeturn19search10turn14search3turn14search9

The five most consequential findings are:

| Finding | Evidence label | Decision |
|---|---|---|
| **The next optimization should be chosen from end-to-end phase attribution, not FPS, CPU utilization, or an isolated kernel timer.** Windows ETW/WPR can attribute CPU activity, while GPU timeline tools can establish whether GPU work overlaps CPU work; none alone equals artist-visible latency. citeturn18search0turn18search5turn18search4 | primary external documentation + inference | **Broadly applicable now** |
| **3ds Max host access is the hard boundary for concurrency.** Autodesk says the SDK is generally not thread-safe, and scene translation/update normally belongs on the main thread; reference/node evaluation is specifically documented as single-threaded. citeturn19search10turn19search0 | primary external documentation | **Broadly applicable now** |
| **Nitrous retained GPU instancing is real, supported, and separate from GPU computation.** `InstanceDisplayGeometry` exists in the 2026 and 2027 SDKs and carries shared geometry plus per-instance data; it is viewport instancing, not Max scene-node instancing and not renderer instancing. citeturn14search3turn14search5turn14search9 | primary external documentation | **Investigate after profiling** |
| **GPU compute is not justified by theoretical throughput.** NVIDIA itself instructs developers to include transfers and minimize host/device movement; tyFlow’s own production documentation reports cases where transfer/memory-bandwidth costs make GPU solving slower than CPU solving. citeturn15search0turn22view2 | primary external documentation | **Defer** |
| **Correctness and lifecycle qualification are currently more important than another speculative subsystem.** Numerical reassociation/FMA can alter boundary decisions, retained GPU resources can fail allocation, and renderer-visible culling cannot be treated as equivalent to viewport culling. citeturn16search0turn14search3turn21view0 | primary external documentation + inference | **Broadly applicable now** |

The largest unknowns are not questions the web can answer: what percentage of CyrusScatter’s **real edit-to-visible time** is Max evaluation, MAXScript/native marshalling, numeric placement, geometry preparation, draw submission, GPU execution, or repeated event scheduling; which exact code accesses Max-owned objects in or around worker regions; whether full-mesh viewport display is CPU-submit-bound or GPU-bound; how much work is invalidated by a typical edit; and whether Corona/V-Ray contention changes the crossover. Those remain `[unknown]` until source inspection and local measurement.

The owner-supplied “approximately 23 to 150 FPS” synthetic observation is therefore correctly treated only as `[user observation]`, exactly as the research brief directs; it cannot establish a general speedup, bottleneck, or production qualification claim. fileciteturn0file0

## Measurement and performance model

Performance must be divided by **workflow**, not reduced to one “scatter performance” number. The useful boundaries are navigation with no scatter mutation; edit-to-visible-result latency; explicit rebuild; animation/frame stepping; viewport display update; offline render preparation; and interactive-render update. Autodesk’s own rendering API reinforces that interactive rendering has different threading and update behavior from offline rendering, including calls that may occur away from the main thread even though Max access remains constrained. citeturn19search1turn19search10

For each workflow, record at least these phases where they exist:

**input/notification → Max scene evaluation → script/native marshalling → immutable snapshot construction → numeric scatter kernel → source/placement preparation → viewport cache update → graphics submission → GPU completion → visible/published result.**

The phase boundaries matter because parallel CPU work and GPU work can overlap. If, for example, CPU geometry preparation overlaps GPU execution from the previous frame, adding their timers produces a number larger than wall-clock latency. NVIDIA Nsight Systems explicitly exposes CPU ranges against GPU timelines for this reason. The correct artist-facing metric is the relevant **critical path**, while individual phase timers explain that path. citeturn18search4

**Amdahl’s law is a useful rejection tool.** For a fraction \(p\) of the complete operation accelerated by a factor \(s\),

\[
S_{\text{total}}=\frac{1}{(1-p)+p/s}.
\]

If the candidate kernel is only 30% of edit-to-visible latency, even making it infinitely fast caps the whole-operation speedup at about **1.43×**. If a kernel is 80% of the operation and becomes 10× faster, the total is about **3.57×**, not 10×. That is why a spectacular CUDA kernel timer or SIMD microbenchmark can still be a poor product investment. Amdahl’s foundational result is specifically about the serial remainder limiting overall parallel speedup. citeturn11search0

Likewise, **FPS should be converted mentally to frame time**. Approximately 23 FPS corresponds to 43.5 ms/frame, 60 FPS to 16.7 ms, and 150 FPS to 6.7 ms. A change from 23 to 150 FPS is therefore not “127 FPS of work removed”; it is roughly a 36.8 ms reduction in the observed frame interval under that particular uncontrolled setup. More importantly, a Max viewport FPS overlay does not establish which fraction came from CyrusScatter, how many callbacks occurred, whether CPU and GPU were synchronized, or whether an edit/rebuild path changed. This is why the user observation in the brief must remain separate from controlled measurements. fileciteturn0file0

**Recommended Windows measurement stack.** WPR/WPA is the best broad first layer: Microsoft describes WPR as ETW recording infrastructure and WPA as its analysis tool, while the CPU Analysis documentation explains that sampled CPU data is periodic and can miss very short work. Thus sampling identifies where CPU time accumulates, but explicit phase timestamps are still required for precise latency boundaries. citeturn18search0turn18search2turn18search5 Use high-resolution local timestamps around Cyrus-owned phase boundaries, while leaving ETW to answer “where did the process spend CPU time?” rather than instrumenting every inner loop.

For GPU diagnosis, tool choice should follow the actual graphics backend. Autodesk documents Direct3D 11 as the normal Nitrous display path in current 3ds Max. citeturn5search0 On NVIDIA, Nsight Systems can correlate CPU and GPU activity and traces D3D11/NVAPI activity; it is suitable for finding overlap, synchronization, and GPU occupancy, but it is NVIDIA-specific. citeturn18search4 Intel GPA supports DirectX on Windows and includes trace/frame-analysis facilities, with DirectX 11 support in its tooling. citeturn17search17turn17search15 AMD’s Radeon GPU Profiler itself currently targets DX12/Vulkan rather than DX11 graphics, but AMD’s GPUPerfAPI does expose performance counters for DirectX 11; therefore an AMD qualification plan should not blindly copy the NVIDIA capture workflow. citeturn17search11turn17search16

Profiling tools should be used diagnostically and benchmark runs should also be taken without heavy capture enabled, because instrumentation changes timing. `[inference]` A sensible evidence hierarchy is: controlled wall-clock artist workflow at the top; phase timestamps beneath it; CPU/GPU traces explaining those timings; and isolated kernels only for deciding how to improve an already-proven hot phase.

For repeated A/B comparisons, preserve the loaded DLL/script identity, scene/build hashes, seed, viewport resolution/style, displayed population, renderer state, camera, adaptive-degradation state, and measurement boundary. Alternate or randomize A/B order to avoid systematically giving one variant warmer caches. Keep cold and warm observations separate. Report raw observations plus median and variability; do not hide a 30% small-scene regression behind a large-scene average. These are proposed test controls rather than claims about the current code.

## Mathematics, CPU algorithms, and concurrency

The external evidence favors **algorithmic simplification before thread-count escalation**. In a scatter system, several superficially similar optimizations can silently change the product’s distribution, order, source assignment, point count, or boundary behavior. The acceptance oracle must therefore be defined before optimizing.

For **surface sampling**, the clean reference model is area-weighted triangle selection followed by uniform sampling within the chosen triangle. PBRT’s reference implementation samples triangle barycentric coordinates uniformly with respect to area and gives the surface PDF as inverse area. citeturn22view7 For a multi-triangle source, the triangle selector must itself be weighted by the relevant effective area/weight. Density maps or masks can then be interpreted either as rejection probabilities or as part of the weighting distribution, but those alternatives do not necessarily generate the same random sequence or accepted point order. `[inference]` Therefore “replace rejection with direct weighted sampling” is a **behavioral change unless proven equivalent under CyrusScatter’s current contract**.

For **spacing and proximity**, the choice should be workload-specific rather than ideological. A brute-force neighbor loop has essentially zero index-build cost and can win for small candidate populations. A uniform grid or spatial hash is the first structure to test when the exclusion radius is approximately fixed and candidate density is not pathologically skewed: nearby cells bound the set of possible conflicts and avoid comparing every point with every accepted point. Bridson’s classic Poisson-disk construction is a foundational example of using a background spatial grid to obtain efficient fixed-radius neighbor checks rather than unrestricted pairwise testing. citeturn4search8 For heterogeneous radii, static triangle/ray/closest-point workloads, or highly nonuniform data, a BVH can become more attractive, but its build cost, memory, topology invalidation, and small-N crossover must be measured. `[inference]` A k-d tree should not be added merely because it is conventional; it earns its place only if its particular query/update distribution wins the local comparison.

The most important semantic warning is that **changing the spacing algorithm can change the scatter**. A sequential dart-throwing policy whose acceptance of point \(i\) depends on all previously accepted points is order-dependent. Parallelizing acceptance by simply partitioning candidates can therefore produce a different accepted set even if every distance calculation is individually correct. `[inference]` A safe optimization can parallelize independent *queries* against a frozen set or parallelize preparation, but a dependency-bearing acceptance pass needs either the original ordering or an explicitly approved new distribution.

For boundaries, holes, nearly collinear edges, and extreme coordinates, the right goal is not “use doubles everywhere” or “add CGAL.” CGAL demonstrates the established middle ground: `Exact_predicates_inexact_constructions_kernel` uses exact predicates while allowing inexact constructions and documents that this is sufficient for many algorithms while being faster than fully exact constructions. citeturn22view6 That supports **targeted robust predicates** where a real boundary-classification defect exists; it does not justify importing CGAL wholesale. The simpler alternative is to preserve the existing algorithm and add a better-defined tolerance/predicate only at the failing decision.

Transform correctness also constrains optimization. Under a general nonuniform transform, normals are not transformed like position vectors; the inverse transpose is required to preserve the normal’s orthogonality relationship to the transformed tangent surface. citeturn22view8 Mirrored transforms additionally require an explicit handedness/orientation test. Any SIMD, packed-transform, or GPU version must be checked against mirrored and nonuniform-scale fixtures rather than only visually plausible positive-scale objects.

Floating-point compiler choices can also convert a “performance optimization” into a correctness change. Microsoft documents that `/fp:fast` permits reassociation and other transformations that can produce observably different results; FMA contraction can likewise differ bitwise from separate multiply/add operations. `/fp:precise` restricts those transformations substantially. citeturn16search0 For scatter boundaries, falloffs, source thresholds, or spacing comparisons, a one-ULP difference near a cutoff may change a Boolean decision and then cascade into a different ordered scatter. `[inference]` Consequently, blanket fast-math is a poor default. First identify code where numerical decisions are not externally visible, and retain explicit near-threshold fixtures.

A practical CPU optimization sequence is therefore:

| Technique | Scatter use case | Where it loses | Selection measurement |
|---|---|---|---|
| **Prepared immutable data / allocation reuse** | Repeated boundaries, source weights, transforms, geometry metadata | Little benefit if inputs change every candidate or preparation itself dominates | allocations, preparation time, full-operation time |
| **Simple serial loop** | Small candidate sets; dependency-bearing ordered work | Large independent numeric ranges | crossover sweep by candidate count |
| **Uniform grid / spatial hash** | Fixed or narrow-range spacing radius | Tiny N, extreme density skew, very large radius relative to domain | build + query + total accepted-set time |
| **BVH** | Reused static geometry for ray/closest/proximity queries | frequently changing geometry, tiny workloads | build amortization over actual query count |
| **Compiler auto-vectorization** | contiguous independent numeric filters | branch-heavy/indirect Max data, order-sensitive FP | vectorization report + whole-phase timing |
| **Explicit SIMD** | only after a proven arithmetic hotspot remains | maintenance cost, tails/alignment, FP-contract changes | improvement over already-vectorized compiler output |
| **Bounded parallel range** | large independent owned arrays | small workloads, sequential dependencies, renderer contention | full-operation crossover, not CPU utilization |

The concurrency boundary is unusually clear. Autodesk states that the Max SDK is generally not thread-safe and that scene translation/update must ordinarily execute on the main thread; its thread-safety guidance also calls out reference and node evaluation as single-threaded. citeturn19search10turn19search0 This strongly favors a three-stage design whenever concurrency is justified: **snapshot permitted host state → compute exclusively on plugin-owned plain data → publish on the permitted thread**. That architecture is an engineering inference from Autodesk’s restrictions, not an Autodesk-provided generic task API.

A **bounded synchronous parallel range** is materially simpler than an asynchronous subsystem. It keeps lifetime obvious: workers finish before the call returns; there is no stale generation to publish; Undo/Redo cannot race a computation that outlives its owning operation; and shutdown/cancellation is much smaller. `[inference]` Its rejection test is straightforward: if the parallel setup, partitioning, synchronization, cache pressure, or renderer competition makes artist-visible latency worse below a realistic workload size, remain serial there.

If oneTBB is considered, it should be treated as a **process-composition question**, not merely a convenient loop library. oneTBB’s `task_arena` explicitly supports limiting the number of participating threads. citeturn22view5 More importantly, oneTBB warns that multiple independent copies in one process can create oversubscription, cache/context-switching costs, and even undefined behavior when TBB objects cross runtime-copy boundaries. citeturn23search1 Autodesk’s 2026 SDK requirements state that 3ds Max itself uses TBB 2021.12. citeturn20search3 Therefore “bundle the newest TBB” is not a neutral decision. The simplest alternative is the existing serial or narrowly bounded implementation, and any TBB dependency should first prove that the loaded runtime identity, ABI, renderer coexistence, and deployment story are clean.

Higher total CPU utilization is not itself success. More workers may increase contention for memory bandwidth, host/render threads, caches, and hybrid-core scheduling while lengthening the single interaction the artist is waiting for. tyFlow’s public performance guidance itself cautions that its multithreaded simulation speedups become sublinear as memory bandwidth becomes a constraint. citeturn22view2 That product-specific observation is not evidence that Cyrus is bandwidth-bound; it is a useful warning against using Task Manager utilization as the optimization target.

A persistent asynchronous editing engine should therefore be **deferred**. It becomes rational only if local tracing shows that, after coalescing events and optimizing synchronous work, long computations still block interaction. Its minimum correctness contract would need immutable snapshots, generation IDs, cancellation, safe main-thread publication, stale-result suppression, and explicit behavior across Undo/Redo, node deletion, scene reset/load, plugin teardown, and application shutdown. `[inference]` Until that need is demonstrated, event coalescing plus bounded synchronous work is the simpler alternative.

## Viewport architecture and production case studies

The biggest externally documented opportunity is **not GPU computation; it is potentially better use of the GPU for drawing**.

Autodesk’s Nitrous object-display model is retained: plugins supply display data that can be retained and reused by the graphics system rather than reconstructing every primitive through legacy immediate drawing every frame. Autodesk preserves compatibility for older drawing paths, but its Nitrous documentation and modern object-display interfaces are designed around retained render items. citeturn5search11turn14search8 In 2027, `IObjectDisplay2` can provide different render items for different nodes and views, which is directly relevant to multiple viewports and per-view behavior. citeturn14search8turn14search16

The exact API most relevant to repeated scatter sources is `MaxSDK::Graphics::ViewportInstancing::InstanceDisplayGeometry`. Autodesk documents it in both the 2026 and 2027 SDK references. It combines normal render geometry with GPU instance data and supports per-instance matrices or decomposed transforms, colors, viewport materials, UV channels and vertex colors. Autodesk explicitly says matrices are the faster input compared with separately combining position/orientation/scale, and recommends update mode when the instance count and base geometry permit it. citeturn14search3turn14search9

This API’s semantics are important: it represents **many GPU-level viewport instances associated with one scene node**; it is not the same thing as creating thousands of 3ds Max instance nodes. citeturn14search5turn14search6 It is also unrelated to final-render instances unless a renderer-specific integration separately consumes equivalent source/transform data. A Cyrus viewport renderer could therefore become much faster without changing the renderer preparation path at all—and vice versa.

A useful conceptual comparison is:

**Expanded triangles:** source geometry is transformed or expanded into per-instance vertex data on the CPU, then the larger result is submitted.

**Shared source + instance data:** source geometry is retained once, while transforms and permitted per-instance attributes are updated. This can drastically reduce CPU geometry generation and transfer volume when the same detailed source is repeated many times, but it is less attractive when every instance has genuinely unique geometry or unsupported per-instance overrides. Autodesk’s instance API is specifically designed for the latter shared-geometry model. citeturn14search3turn14search5

It is not a free performance switch. `CreateInstanceData()` rebuilds the instance data and can fail when the GPU allocation is too large; `UpdateInstanceData()` is the cheaper path for compatible changes. citeturn14search3 A correct implementation therefore needs an invalidation/lifetime matrix: source topology changed; source deformation changed; instance count changed; only transforms changed; only colors/material data changed; node/view changed; resource allocation failed; device/display mode changed; scene reset or plugin shutdown occurred. A new cache without those rules is not an optimization—it is deferred correctness debt.

**tyFlow provides a useful documented mechanism case study, not a blueprint.** Its tyCache documentation says its Nitrous GPU-instancing mode avoids generating/combining per-particle display meshes and sends raw shared mesh data plus instances to the GPU. But it also documents concrete tradeoffs: object modifiers cannot act on nonexistent combined display mesh data, and some UV mapping overrides can defeat efficient instancing or require intentionally inaccurate viewport mapping to retain the fast path. citeturn22view0turn22view1 That is exactly the kind of constraint Cyrus should expect: retained instancing is compelling when the display contract fits it, not when fidelity requirements force each instance to become unique. Nothing in the public tyFlow documentation reveals its private scheduler, buffer management, or Cyrus-applicable performance numbers.

**Chaos Scatter provides a complementary renderer/memory case study.** Chaos documents that geometry instancing keeps repeated-geometry RAM cost low but does not make memory unbounded; extremely dense or geographically large scatters can still exhaust RAM. It also gives a practical example where scattering a clump rather than enormous numbers of individual blades materially lowers RAM usage. citeturn21view0 More importantly for architectural separation, Chaos warns that camera clipping may lower parsing/memory cost but can cause missing reflections or shadows. citeturn21view0 This is strong evidence that a viewport visibility optimization cannot simply be reused as a final-render culling rule. What is outside the camera can remain radiometrically relevant.

Thus the recommended viewport policy is layered rather than universal. **Points** are appropriate for huge populations where distribution is the information the artist needs. **Simple proxies** are appropriate where orientation/scale/rough volume matters. **Retained full-mesh instances** are appropriate when source fidelity matters and sources repeat. **CPU cached/batched drawing remains a legitimate long-term fallback** for unsupported styles/attributes, small populations, allocation failure, or cases where retained-resource churn erases the benefit. `[inference]` The product does not need one renderer for every display mode.

The external research therefore does **not** say “replace the current viewport.” It says: after phase profiling, test one retained-instancing path against an identical workload, behind a flag, while keeping the current implementation as correctness baseline and fallback.

## GPU computation decision

**Recommendation: do not add GPU computation at this product stage unless local profiling overturns the case.**

That decision is independent of whether GPU viewport drawing is worthwhile. GPU viewport instancing is an existing graphics mechanism for submitting repeated visual geometry; CUDA/OpenCL/DirectCompute/SYCL would move **scatter calculations** onto a compute device. These solve different problems and have different support burdens. Autodesk’s documented viewport-instancing APIs already let the GPU perform the repetitive draw-side work without Cyrus owning a compute backend. citeturn14search3turn14search5

A GPU-compute candidate must be evaluated as:

\[
T_{\text{GPU workflow}} =
T_{\text{host extraction}}+
T_{\text{packing/allocation}}+
T_{\text{upload}}+
T_{\text{dispatch}}+
T_{\text{kernel}}+
T_{\text{synchronization}}+
T_{\text{readback}}+
T_{\text{publication}},
\]

with overlap subtracted only where a trace demonstrates that it actually occurs. NVIDIA’s current CUDA best-practices guide makes the same fundamental point: host-device transfers are costly, should be minimized/batched, persistent device data is preferable when valid, and asynchronous transfer only helps under the necessary memory/device/stream conditions. citeturn15search0 Kernel timing alone is therefore insufficient evidence.

**CUDA** is the strongest first experimental backend only when an NVIDIA-only experiment is acceptable and a measured kernel is massive enough to justify transfer. It provides mature tooling and D3D11 resource interoperability APIs. CUDA 13.4 still exposes non-deprecated D3D11 resource-registration functionality, while the older context-association subset is explicitly deprecated. citeturn23search0turn23search3 The nuance is important: this does **not** prove that Autodesk exposes Nitrous-owned resources in a supported way to a scatter plugin. Without an Autodesk-supported device/resource ownership contract, viewport/CUDA interop should remain `[unknown]`, not an architecture assumption.

**OpenCL** has the attraction of cross-vendor reach, but OpenCL 3.0 deliberately makes substantial capabilities optional and requires applications to query what a platform/device actually supports. citeturn21view7 A single OpenCL source base therefore does not eliminate vendor-driver qualification. tyFlow is a real DCC example of selective OpenCL use rather than wholesale GPU conversion: its documentation says only particular solver work is GPU-accelerated, can fall back to CPU when GPU memory is insufficient, and may be slower on some GPU/hardware combinations because transfer and memory-bandwidth costs dominate. citeturn22view2 That is a useful production lesson precisely because it argues against “GPU everything.”

**DirectCompute** is structurally plausible because current Nitrous uses Direct3D 11 and D3D11 has compute shaders, but the critical issue is not whether DirectCompute exists—it is whether a Cyrus plugin can safely and supportably share the relevant Max graphics device/resources and synchronize without fighting Nitrous or renderers. That integration is not established by the sources reviewed here. `[unknown]` A private second D3D device would also lose much of the hoped-for zero-copy appeal. Therefore DirectCompute is not currently ahead of the CPU baseline.

**SYCL** remains a viable modern cross-vendor programming model in principle; Khronos’ registry lists the actively maintained SYCL 2020 specification, including revision 12 dated August 6, 2026. citeturn21view8 But SYCL does not turn vendor backends, runtime deployment, native interop, numerical differences, or 3ds Max lifecycle into nonissues. `[inference]` It should not be added merely to create an elegant abstraction before one compute workload has demonstrated product value.

The strongest argument **against GPU compute** is therefore not “GPUs are bad at scatter.” It is that no externally knowable fact establishes that Cyrus currently spends enough end-to-end time in a transferable, massively parallel, sufficiently regular kernel. Irregular BVH/geometry traversal, branch-heavy mask logic, order-dependent spacing, small edits, and frequent CPU publication can all reduce GPU advantage; a large independent arithmetic filter could do the opposite. The outcome is workload-dependent.

The smallest experiment capable of rejecting GPU compute quickly is consequently simple: take **one already-proven CPU hotspot operating only on owned POD-like arrays**, run the same semantic kernel on CPU and one GPU backend, sweep through realistic candidate sizes, and time extraction/packing/upload/kernel/sync/readback/publication separately and together. Do not add Nitrous interop, persistent cross-scene caches, multiple backends, or production packaging to this experiment.

My proposed—not measured—GPU stop conditions are deliberately demanding:

| Gate | Proposed rule |
|---|---|
| Kernel importance | Stop if the candidate kernel is **<50% of the target workflow** before GPU work. Amdahl’s bound is already unfavorable. |
| Transfer/sync burden | Stop if upload + synchronization + readback remain **≥50% of GPU-path time** at realistic large workloads. |
| Product benefit | Do not productize unless the complete artist operation improves **≥25% median** on a meaningful large workload and tail latency is not materially worse. |
| Correctness | Stop on unresolved count/order/source/tolerance changes outside an explicitly approved numerical contract. |
| Hardware | Stop if the intended 32 GB qualification class or plausible VRAM class falls back/pathologically degrades. |
| Deployment | Stop if a robust CPU fallback and clean driver/runtime packaging cannot be maintained. |
| Renderer contention | Stop if gains disappear or interactive/offline rendering suffers materially under concurrent use. |

These thresholds are **decision gates**, not measured facts.

## Ranked decisions and falsifiable experiments

The shortlist below intentionally rewards simpler alternatives and gives every added subsystem a way to fail.

| Rank | Option and status | Concrete workflow / hypothetical bottleneck | Simplest alternative | Strongest case against adoption | Confidence |
|---|---|---|---|---|---|
| **First** | **End-to-end instrumentation — broadly applicable now** | Any interaction; unknown attribution across host/script/native/draw/GPU | Keep current behavior and add minimal phase timing | Instrumentation can perturb the workload if overdone | **High** |
| **Second** | **Eliminate/precompute repeated CPU work — broadly applicable now** | Rebuild/edit where predicates, allocations or static data preparation repeat | Keep straightforward serial loop | More caching increases invalidation/memory complexity if input lifetime is unclear | **High** |
| **Third** | **Retained Nitrous instancing — investigate after profiling** | Repeated detailed sources where CPU geometry preparation/submission dominates viewport | Existing cached/batched CPU display | Gains may be small if GPU fill/vertex cost, Max overhead, or update churn is the true bottleneck | **Medium-high** |
| **Fourth** | **Bounded synchronous CPU parallelism — investigate after profiling** | Large independent numeric range that is host-free | Optimized serial loop | Startup/scheduling/cache/renderer contention can exceed saved compute | **Medium** |
| **Fifth** | **Spatial index for spacing/query hotspot — investigate after profiling** | Repeated neighbor/ray/proximity tests dominate | Brute force for small workloads | Build/update cost and behavior changes can erase benefit | **Medium** |
| — | **Persistent asynchronous engine — defer** | Long edit computation still blocks after simpler fixes | Event coalescing + synchronous work | Large lifetime/cancellation/Undo/reset complexity | **Low** |
| — | **GPU compute backend — defer** | Proven dominant transferable numeric kernel | Optimized CPU | Transfers, deployment, numerical and renderer contention costs | **Low-medium** |
| — | **Multi-GPU-backend abstraction — reject now** | No proven workflow | No abstraction | Multiplies maintenance before value exists | **High** |
| — | **Heavy robust-geometry dependency — defer** | Reproducible precision defect | Targeted predicate/tolerance correction | ABI/deployment/size burden without demonstrated defect | **High** |

The three highest-information local experiments are as follows.

**Experiment E-001 — phase-attributed full-workflow trace.** Use fixed-seed project scenes representing a genuinely small workload, normal production workload, heavy repeated-source workload, many-unique-source workload, mask/boundary-heavy workload, and one pathological geometry case. Run navigation without edits, parameter edit-to-visible, full rebuild, timeline stepping, production-render preparation, and interactive-render editing separately. Capture loaded DLL/script identities and hashes, scene/build hash, camera, viewport dimensions/style, display population, final population, adaptive-degradation state, renderer state, CPU/GPU/driver identity, and memory state. Use explicit phase timestamps plus WPR/WPA; add a vendor GPU trace only for diagnostic runs. Microsoft’s CPU sampling documentation explains why ETW sampling should complement rather than replace explicit latency boundaries. citeturn18search5

The correctness oracle for E-001 is the existing accepted behavior contract: ordered placement IDs/source identities, transforms, relevant numerical fields, display count, and render count, with explicit tolerances only where already permitted. Do paired A/B runs with order alternation/randomization, distinguish first/cold execution from warm steady-state, and retain every raw sample. The experiment rejects vague statements such as “GPU-bound,” “single-thread-bound,” or “MAXScript-bound” unless the trace actually supports them.

**Experiment E-002 — one retained viewport-instancing proof of concept.** Implement only one compatible repeated-geometry display mode behind an experimental flag using `IObjectDisplay2` plus `InstanceDisplayGeometry`; do not replace other viewport paths. Keep the exact same source geometry, instance transforms, displayed count, materials/colors where supported, camera and viewport style as the current baseline. Autodesk explicitly provides `CreateInstanceData()` and cheaper update mode for this purpose and documents allocation failure as a case the plugin must handle. citeturn14search3turn14search8

Measure CPU update/preparation time, full navigation frame time, GPU-completed frame time where obtainable, edit-to-visible latency, RAM/VRAM, and variability. Test unchanged count/changed transforms; changed count; source topology change; source deformation; mirrored/nonuniform transforms; per-instance colors/materials/UVs; multiple viewports; selection/hit testing; bounds; wireframe/standard/high-quality display; resource failure; scene reset/load; and shutdown. The current path remains the visual and behavioral baseline. A proposed gate is **≥20% full-frame or edit-to-visible improvement on a real bottlenecked workload**, with no unacceptable fidelity or lifecycle regressions. Otherwise, keep the simpler current CPU caching/batching path.

**Experiment E-003 — CPU architecture crossover shootout.** After E-001 identifies one numerical hotspot, compare only techniques relevant to that same semantic operation: baseline serial; prepared/reuse serial; an appropriate spatial index if queries dominate; then bounded parallel execution if iterations are independent. Sweep workload size, candidate acceptance ratio, density/skew and renderer contention. The point is to learn the crossover, not to make the parallel version win. Autodesk’s thread-safety rules mean the parallel variants must operate solely on plugin-owned data, without node/reference/MAXScript/graphics evaluation. citeturn19search10turn19search0

Use exact ordered-output comparison where current behavior requires it. For near-boundary numeric work, maintain dedicated adversarial fixtures and compare compiler FP settings before treating any result as equivalent; MSVC documents that `/fp:fast` can change results through reassociation/contraction. citeturn16search0 A proposed CPU-parallel gate is at least **20% end-to-end improvement on the large target case**, no more than **5% regression on normal small cases**, no material tail-latency deterioration, and exact/approved numerical parity. If it fails, serial remains the right implementation.

The **GPU quick-rejection experiment** is deliberately not in the first three. It becomes informative only after E-001/E-003 leaves a dominant, portable numeric kernel. Running it earlier would measure an arbitrarily chosen kernel rather than answer a product question.

## Qualification, ledgers, and Codex handoff

A supported scatter plugin needs substantially more evidence than a fast viewport capture. The following staged matrix is the minimum external recommendation.

| Qualification area | Required tests | Failure modes the tests are intended to expose | What a beta may **not** claim before passing |
|---|---|---|---|
| **Placement correctness** | fixed seeds; source weights; masks; holes; spacing boundaries; degenerates; extreme coordinates; mirrored/nonuniform transforms | changed point count/order/source identity; NaNs; tolerance drift; wrong normals | “equivalent output” |
| **Serial/parallel parity** | same controlled inputs across scheduling/grain/count boundaries | race, nondeterministic acceptance/reduction, schedule-dependent RNG | “deterministic parallel mode” |
| **Viewport fidelity** | points/proxies/full mesh; colors/materials/UV; multiple viewports; styles; selection/hit/bounds; topology/deformation | stale buffers, missing instances, attribute mismatch, invalid bounds | “fully compatible Nitrous display” |
| **Lifecycle** | new/open/save/reopen/reset/merge/clone; Undo/Redo; node/source deletion; repeated plugin operations; shutdown | stale pointers, invalid generations, resource leaks, wrong invalidation | “production stable” |
| **Animation** | changing transforms, sources, counts, topology and controllers over time | one-frame stale result, topology/motion mismatch, runaway rebuild | “animation qualified” |
| **Memory** | long editing session; repeated rebuilds; 32 GB machine; constrained VRAM; allocation failure | cache growth, old generations retained, fallback crash, thrashing | “32 GB supported” |
| **Host versions** | actual application runs under both Max 2026 and 2027, not merely compilation | SDK/ABI/load/runtime differences | “Max 2026 supported” from build success alone |
| **Corona/V-Ray** | production + interactive render; edits during IR; start/stop; material/source changes; reflections/shadows | renderer contention, stale render populations, render/viewport conflation | “Corona/V-Ray compatible” beyond tested modes |
| **Packaging** | clean machine install/uninstall, DLL/runtime identity, dependency coexistence, fallback without optional GPU tooling | wrong module loaded, ABI mismatch, missing redistributable, runtime collision | general release readiness |
| **Performance** | small/normal/large/pathological cases, cold/warm, renderer idle/contention, raw paired trials | optimization that wins only synthetic maximum or hides normal regression | generalized FPS multiplier |

Toolchain identity belongs in that matrix. Autodesk states that 3ds Max 2026 is an SDK-breaking release and lists VS 2022 17.8.3/v143, Windows SDK 10.0.19041.0, .NET Core 8 and Qt 6.5.3 for its 2026 SDK environment. citeturn19search5turn19search7 Autodesk’s August 2026 developer guidance for 2027 emphasizes the ABI-sensitive v14.38 MSVC toolset within the v143 family and Qt 6.8.3 even when using a newer IDE host. citeturn20search5 Therefore “compiled successfully” is not the same claim as “runtime qualified in that Max version.”

The supplied Project Context itself reinforces an important unresolved boundary: it says the Max 2026 build had native test success but that Max 2026 was not actually installed locally, and says production/interactive renderer qualification remained incomplete. Those statements are supplied project context, not independently observed source/runtime evidence in this report. fileciteturn0file1 They should be verified by the missing Codex/codebase pass rather than promoted into release claims.

Two reusable ledgers have been generated from this independent pass:

[Download the claim/source ledger — 26 source-backed claims](sandbox:/mnt/data/cyrus_scatter_external_claim_source_ledger_2026-10-01.csv)

[Download the decision/experiment ledger — decisions, experiments, gates and stop conditions](sandbox:/mnt/data/cyrus_scatter_external_decision_experiment_ledger_2026-10-01.csv)

The ledgers record stable IDs, evidence class, source and section, access/version information, applicability, confidence, contradictions/limits, validation needed, decision status, simplest alternatives, experiment IDs and rejection gates. Their role is reconciliation, not creation of a new knowledge-base subsystem.

For the eventual Codex handoff, the external researcher’s highest-priority questions are now precise:

| What Codex must establish from real source/runtime | Why it changes the external decision |
|---|---|
| **Exact current build and loaded runtime identity**: package, DLL, generated script, Max build, compiler/toolset, loaded dependency versions | Prevents comparing the wrong implementation and detects ABI/runtime mismatches |
| **Every Max/MaxScript/graphics access around worker code** | Determines whether current concurrency obeys Autodesk’s thread boundary |
| **Phase attribution for navigation, edit, rebuild, animation and render prep** | Chooses between CPU algorithm work, scheduling work and viewport work |
| **Current RNG/order/spacing/boundary contracts** | Determines which “optimizations” would silently change the product |
| **Current geometry-query structures and their invalidation** | Determines whether grid/BVH/preparation work is new, redundant or harmful |
| **Current viewport object/display API and data lifetime** | Determines whether retained Nitrous instancing is a meaningful next experiment |
| **How per-instance material/UV/color/source variation is represented** | Determines how often GPU instancing can remain instanced |
| **Cache ownership and invalidation across source edits, topology, GC/reset/shutdown** | Prevents adding a second cache without a lifetime contract |
| **Renderer preparation interfaces for Corona/V-Ray, separately from viewport drawing** | Prevents viewport optimizations being mistaken for render optimizations |
| **Actual RAM/VRAM high-water marks and fallback behavior** | Determines whether the proposed 32 GB target is credible |
| **Existing correctness fixtures and raw historical evidence** | Avoids rebuilding tests already present and reveals untested failure classes |

The Codex engineer should **not** adopt, merely because this report recommends investigating them, retained instancing, a spatial index, oneTBB, an asynchronous worker, a robust-predicate library, CUDA, OpenCL, DirectCompute, or SYCL. Each is conditional on a specific local observation. The external evidence establishes that these mechanisms exist and identifies their constraints; it does not establish that CyrusScatter needs them.

The first local implementation candidate is therefore deliberately conditional. **If E-001 shows that CPU viewport geometry preparation/submission remains a material share of navigation or edit-to-visible latency for repeated geometry, the smallest implementation experiment is one `IObjectDisplay2` + `InstanceDisplayGeometry` path for one compatible display representation behind a feature flag, with the current path retained as fallback and correctness oracle.** Autodesk directly supports the API in both target SDK generations and provides creation/update semantics suited to this narrow test. citeturn14search3turn14search8turn14search9 If profiling instead shows that numeric scatter computation dominates, this viewport experiment should be stopped before implementation and E-003 should select the CPU hotspot instead.

That conditionality is the central conclusion of the research. Agreement between an external model and a future codebase model would not make the proposal true. The decision should be made only when **external API evidence + actual source structure + local transfer-inclusive/whole-workflow measurement + correctness tests** agree. Until the missing `01 - Codex GPT 6 Astra - Codebase Research.txt` pass and real repository/runtime inspection are completed, the final cross-report reconciliation required by the original run order remains `[unknown]`, and no speculative production rewrite is justified. fileciteturn0file0