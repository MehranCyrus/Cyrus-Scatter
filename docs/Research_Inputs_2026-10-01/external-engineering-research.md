# Cyrus Scatter — external engineering research and decision report

**Research date: 1 October 2026**  
**Purpose:** choose the smallest defensible improvements to performance and reliability for a Windows/3ds Max 2026–2027 scatter plugin.  
**Status:** completed external investigation, with explicitly unresolved host-integration questions. Not an implementation, runtime qualification, or new product benchmark.

## 0. Evidence boundary and how to use this report

The supplied independent-research brief is the governing task. The internal context snapshot and the earlier conversation were also visible. Consequently, this is an **externally grounded review, but not a blind independent review**. No claims of independence stronger than that are warranted. The separate Codex investigation has not been read or executed here.

This pass opened primary documentation and public implementations, compared conflicting sources, inspected the Bridson paper, and derived the simple performance models below. It did **not** inspect a current Cyrus repository, run 3ds Max, attach a Windows profiler, execute CUDA/OpenCL/DirectCompute, or reproduce historical project results. An ordinary Linux container was used to prepare the report and its ledgers. No production plugin source was changed.

Evidence labels used throughout:

| Label | Meaning in this package |
|---|---|
| **primary external documentation** | Opened Autodesk, Microsoft, NVIDIA, AMD, Khronos, vendor documentation, academic work, or author-maintained public implementation. It establishes a documented mechanism, not Cyrus performance. |
| **inference** | Our mathematical derivation, conditional engineering recommendation, or proposed experiment/threshold. |
| **unknown** | Requires the current source, installed SDK, actual host, hardware, renderer, or measurement. |
| **historical project-test report** | A statement in the uploaded dated snapshot about earlier tests; raw tests were not rerun here. |
| **user observation** | Reported FPS or perceived responsiveness without a controlled capture. |
| **direct project-source observation; local measured run** | **No new evidence of these kinds was produced for Cyrus in this pass.** |

Source IDs such as **[S05]** resolve to exact URLs, sections, versions, access dates, and limitations in `Sources.md` and `source_ledger.csv`. `claim_ledger.csv` links material conclusions to their evidence. This separation avoids promoting a recommendation into a verified implementation fact.

## 1. Decision brief: five consequential findings

### 1. Measure the remaining delay, not the most impressive kernel

A fast sampler cannot fix expensive scene evaluation, repeated script/native conversion, draw submission, render translation, or a delayed update request. A high FPS number cannot establish fast editing or rendering. Use separate measurements for unchanged-scene navigation, edit-to-result latency, complete rebuild, animation, and render preparation. CPU sampling, graphics timelines, and present-event capture answer different questions. **Recommendation: make a verified, instrumented baseline the next deliverable, before choosing another subsystem.** [S11–S17; inference]

### 2. Keeping efficient CPU batching is a legitimate end state

Autodesk exposes both retained display and GPU instancing interfaces. Availability is not a mandate to replace a small, correct, low-memory CPU-batched proxy path. Shared source geometry plus instance transforms becomes attractive when repeated geometry expansion, per-redraw submission, or memory duplication is the measured problem. More unique sources, rapidly changing topology, mapping overrides, and tiny populations can reduce that advantage. **Recommendation: retain the existing display path as the control and compare architectures with identical visible populations.** [S03–S06, S36; inference]

### 3. Optimized serial code and bounded joined work precede asynchronous architecture

Autodesk's reference/node evaluation restrictions prevent treating arbitrary host work as an ordinary parallel loop. Specific SDK callbacks do have documented threading requirements; therefore both “everything is thread-safe if locked” and “nothing in Max may be threaded” are wrong generalizations. Independent numerical work on owned input can be parallelized selectively. Persistent executors and asynchronous publication add lifetime, cancellation, memory, and Undo/Redo obligations. **Recommendation: optimize and coalesce first; parallelize measured independent ranges second; introduce asynchronous evaluation only to solve a remaining interaction problem.** [S01–S03, S29; inference]

### 4. GPU drawing and GPU calculation are separate decisions

Nitrous instancing accelerates viewport representation; it is not a scatter-compute backend or renderer interface. A GPU compute proposal must beat optimized CPU execution after packing, transfers, synchronization, readback, and publication. The strongest GPU experiment is initially a transfer-inclusive *rejection test*, not a port of the whole engine. **Recommendation: defer a shipped GPU compute backend unless one measured numerical stage survives that test and its correctness requirements.** [S04–S06, S17, S32–S34; inference]

### 5. Correctness and memory bounds are part of smoothness

A stale result, an invalid selection, a queue of obsolete rebuilds, or a memory-cap fallback can destroy responsiveness despite excellent median timing. The 32 GB qualification target requires measuring the entire host process and relevant GPU allocations, including overlapping generations and renderer load—not just one cache's payload. **Recommendation: every optimization needs an invalidation/lifetime contract, an output oracle, a fallback policy, and tail-latency/peak-memory evidence.** [Inference; owner requirements in independent brief, lines 16–20 and 84–92]

**Largest unknowns:** current critical path; existing cache validity guarantees; remaining proxy/full-mesh differences; source/material diversity; real working-set peaks; acceptable deterministic contract; current renderer translation interfaces; and actual Max 2026 runtime behavior. No evidence here identifies Cyrus's current dominant bottleneck.

## 2. Verified platform constraints and documentation conflicts

### 2.1 Host matrix

| Subject | Max 2026 | Max 2027 | Decision boundary |
|---|---|---|---|
| Build requirements | SDK table specifies VS 2022 17.8.3, v143, Windows SDK 10.0.19041.0, .NET 8 and Qt 6.5.3. [S07] | Official release notes establish C++20/.NET 10/Qt 6.8. A vendor blog reports v143/v14.38, VS 2022 17.14.13 and Qt 6.8.3. [S08,S09] | The 2027 conceptual requirements endpoint was inaccessible. Confirm the exact installed SDK/sample project toolset before pinning or changing build tools. |
| Viewport instancing | Public namespace and class documentation exists. [S04] | Public counterpart and InstanceData documentation exists. [S05,S06] | Build and test each host. Similar API text is not binary compatibility or functional qualification. |
| Legacy graphics | No new conclusion about all legacy paths in this review. | DirectX 9 removal is explicit in release notes. [S08] | Do not invest in a DX9 path for 2027. A GraphicsWindow callback is not synonymous with the removed DX9 driver. |
| Threading | Reference/node evaluation restriction explicitly documented. [S01] | Specific Deformer callbacks explicitly require thread safety. [S02] | Check each actual callback/API contract; use the conservative host boundary until a more permissive guarantee is verified. |
| TBB | SDK page says Max itself uses TBB 2021.12, and its sample requires 2021.12.0. [S07] | Exact loaded/runtime build remains unknown. | Do not select a runtime from a different Autodesk project's dependency table. |

A newer IDE does not itself authorize a new compiler, ABI, Qt, or runtime configuration. Treat the **installed target SDK and tested package manifest** as the build contract. Do not claim 2026 support because a 2026-format scene was opened in 2027.

### 2.2 Conflicts that materially narrow recommendations

**2027 SDK blog:** its claim that .NET 8 was already end-of-life in July 2026 conflicts with Microsoft's support page, which lists support through November 2026. The native toolset statement may still be correct, but deserves installed-SDK confirmation rather than blind trust. [S09,S10]

**TBB dependency tables:** the public Autodesk USD build page lists an older TBB dependency than the Max 2026 SDK's stated host runtime. That can describe different components; it does not prove either all components share a runtime or that injecting a new one is safe. [S07,S30]

**tyFlow GPU inventory:** the performance FAQ says no other simulation components use the GPU beyond its listed OpenCL cases, while the requirements and operator pages describe additional CUDA features. Use the FAQ's bounded warning about transfer costs, not its exhaustive feature list as a current product specification. [S37–S39,S42]

**UVW wording:** tyCache warns that its mapping overrides can disable instancing. Autodesk's InstanceData nevertheless supports a restricted form that assigns one UVW coordinate to an entire channel for each instance. Those are not interchangeable mapping capabilities. Neither “all overrides work” nor “the API has no UVW support” is justified. [S06,S36]

**SYCL on Windows:** Codeplay's versioned NVIDIA 2025.2 guide explicitly includes Windows and a tested Windows configuration. Reject outdated blanket Linux-only claims. This still does not establish a validated Windows/Max/cross-vendor deployment for Cyrus. [S34]

## 3. Measure artist-visible performance correctly

### 3.1 Five workloads, not one score

| Workload | Start / finish boundary to record | Important additional observations |
|---|---|---|
| Navigation without edits | Known camera-input sequence to presentation events of the affected viewport | No generation unless a camera-dependent feature explicitly requires it; per-frame CPU/GPU work; p95/p99 frame intervals; displayed population. |
| Parameter or local edit | Event received to first correct committed result and its identified presentation | Separately record acknowledgment, optional stale preview, latest exact result, debounce delay, canceled work, and selection behavior. |
| Full rebuild | Explicit invalidation/request to complete correct result | Extraction, preparation, native work, conversion, publication, peak memory; cold and warm inputs. |
| Animation | Frame request to correct evaluated/displayed frame, with time/sample identity | Sequential playback and random/reverse jumps, deforming sources, motion-sample consistency, work retained across frames. |
| Final/interactive rendering | Render start or edit to translation complete, then first renderer update | Separate host translation, renderer acceleration preparation, and image rendering. Cancellation and source restoration belong in the test. |

These boundaries are proposed instrumentation, not claims about current Cyrus internals. For true physical input-to-photon latency, external input/display measurement or correctly supported instrumentation is necessary. A software event-to-present proxy is useful but must be named accurately.

A viewport FPS overlay, elapsed time around a synchronous redraw call, and GPU-completed work are not the same measurement. A redraw may submit work and return while the GPU continues. Multiple viewports, passes, swap chains and desktop composition also need identification in a capture. [S13–S15; interpretation is inference]

### 3.2 Amdahl and critical paths

For an operation with serially attributable fraction `f` improved by factor `k`:

`whole-operation speedup = 1 / ((1 - f) + f/k)`

With `f=0.20` and `k=10`, the benefit is approximately **1.22×**, with an infinite-kernel-speed limit of **1.25×**. These are mathematical examples, not measurements. The serial model is useful only when the fractions describe the same operation and boundary. [S17]

CPU preparation and GPU drawing can overlap across frames. In a simplified steady pipeline, throughput is limited by the slower stage, while individual-response latency also includes queueing and dependencies. Do **not** add all CPU-thread durations, GPU durations and wait intervals into a fictitious total. Record the actual event chain and timeline. An optimization may improve throughput yet leave a queued interaction feeling late.

Frame time is `1000/FPS` milliseconds only for the corresponding rate statistic; averaging FPS values is not equivalent to averaging frame times. Report medians and tail intervals plus raw samples. Use independent capture runs as experimental units, not thousands of correlated frames from one run as thousands of independent experiments. Record throttling, window focus, power policy, renderer activity, display size, style, vsync and adaptive degradation. [Inference]

### 3.3 Practical Windows toolchain

| Tool | Supported route / evidence | What it can establish | What it cannot establish alone |
|---|---|---|---|
| Visual Studio CPU Usage | Performance Profiler with running-process targeting; native C++ sampling; Release build plus matching symbols. [S11] | Hot stacks, active CPU contribution, modules and threads. | Exact native call counts, waits, GPU completion, or input-to-visible latency. |
| VSDiagnostics CLI | Documented `/attach:<pid>` with an installed collector configuration. [S12] | Repeatable native profiling sessions where collector/edition supports the chosen analysis. | Automatic availability of every collector on every workstation. |
| WPR/WPA and GPUView | ETW capture around an already running application. [S13] | CPU scheduling, waits, allocations where enabled, graphics queue relationships. | Attributing every driver event to a scatter feature without correlation markers. |
| PresentMon | Process-filtered present capture; archive raw output, version and chosen swap chain. [S14] | Presentation cadence and documented supported metrics. | All Max redraw callbacks or physical input latency; fields requiring application markers may be absent. |
| Nsight Systems | Supported launch/trace configuration for the installed release; documented Windows D3D tracing and WDDM views. [S15] | D3D11 CPU API timing and queue context; documented D3D12 GPU workload correlation. | Treating an API duration as a GPU duration, or assuming attach/injection works in every Max/plugin combination. |
| AMD RGP | Documented supported explicit graphics/compute APIs and RDNA configurations. [S16] | Detailed profiling for a compatible backend. | Profiling a Direct3D11 viewport: RGP explicitly excludes D3D11. |

Use WPR/CPU sampling as the low-commitment start. Validate that an instrumented and uninstrumented run have comparable behavior. Separate invasive allocation captures from headline timing. GPU debugger/profiler attachment to the particular Max version/driver remains an actual-host test; do not install a new drawing backend just to suit a profiler.

The developer should emit low-overhead timestamps and counters at event, extraction, preparation, numeric stage, publication, display, and render-translation boundaries. Record generation/revision identifiers, data counts, cache hit/miss reason, invalidation reason, bytes, and fallback/cancellation status. A profiler finds expensive code; these markers explain **why and how often** it ran.

## 4. CPU mathematics: select by the actual query and workload

The following decision table is an engineering interpretation of the cited mechanisms. It is not a description of algorithms currently used by Cyrus.

| Technique / scatter use | Simplest baseline and cost | When it can win | When it loses / correctness boundary | Measurement that decides |
|---|---|---|---|---|
| Prepared triangle/source weights | For a few sources, linear selection is simple; CDF construction is O(M), then binary search O(log M). Alias preprocessing permits O(1) draws. [S18] | Many repeated draws from unchanged weights. | Small source lists, frequently changing weights, preprocessing overhead. Alias and CDF can give different source IDs for the same random value. | Preparation plus all draws per revision, not isolated lookup; compare ordered IDs and frequency distribution separately. |
| Density rejection | Propose from the intended base distribution and reject by density. [S19] | Moderate acceptance, cheap tests, exact current behavior important. | Very sparse masks: expected attempts grow as 1/a under independent stable acceptance. Caps, greedy collisions and correlated constraints complicate that estimate. | Attempts and reject reason per accepted placement; map-preparation cost; achieved count and density bias. |
| Prepared boundary predicates | Precompute loop bounds, plane/basis, edges and hole membership data; baseline exact scan retained. | Repeated tests against unchanged complex boundaries. | Tiny loops, constantly edited curves, preparation bigger than reuse, cache invalidation errors. | Full preparation+query time, nested holes/self-intersections/edge classification oracle. |
| Uniform grid/spatial hash | Constant-size neighborhood when radius and occupancy are bounded; sparse hash avoids dense empty grid allocation. Bridson gives a specific fixed-radius example. [S23] | Nearby collision checks with comparable radii and fairly uniform density. | Strong clustering, huge radius variation, many candidates per cell, expensive hash probes; memory and order need control. | Cells visited, candidates tested, occupancy percentiles, build/update/query time and bytes. |
| BVH / AABB tree | Exact triangle loop O(T) per query is the correctness control; hierarchy pruning reduces tested primitives in favorable geometry. [S20,S21] | Many closest-point/ray queries against a reused mesh; boundary-segment distance against many segments. | Tiny workloads, pathological overlap/long slivers, frequent rebuilds; nearest-point and ray predicates differ. | Build/refit plus complete query batch, visited nodes/triangles, tie results, peak memory. |
| k-d tree for points | Scan small point sets; tree supports point-neighbor search. [S22] | Nearest-source/anchor/point queries on sufficiently stable nonuniform point sets. | Frequently moving sets, very small sets, highly skewed data, using vertex-nearest as triangle-nearest. | Build/update+queries and exact point-neighbor oracle with ties. |
| Poisson-disk generation | Fixed-radius active list and bounded candidate trials are a different sampler. [S23] | A deliberately specified blue-noise/minimum-spacing generation mode. | It does not preserve exact requested count, candidate order, RNG stream or existing placement IDs by default. Surface/geodesic and variable-radius versions require separate design. | Distribution/spacing/count quality AND time; old-scene compatibility cannot be replaced by visual similarity. |
| Jacobi-style relaxation | Read an old point set and write a new point set per iteration. | Independent point updates with shared read-only neighborhood data. | Switching from ordered in-place updates changes the mathematical iteration; projection and final acceptance may remain coupled. | Convergence quality, spacing violations, iteration count, ordered result parity and end-to-end time. |

### 4.1 A spatial index should earn its preparation and memory

Let additional preparation cost be `B`, exact scan cost/query be `q0`, indexed query cost be `q1`, and queries per validity interval be `Q`. Ignoring memory and if `q0>q1`, the index wins only when:

`Q > B / (q0 - q1)`

Measure those values for the **complete validity interval**. Reusing a tree across many redraws is irrelevant if no geometric query is needed on redraw. For deforming geometry, a refit may be cheaper than a rebuild but can produce worse bounds and longer traversal; measure total update plus queries. Do not invent a universal primitive-count switch.

An exact acceleration structure needs conservative bounds and unchanged predicates. Equal-distance or equal-priority cases require an explicit stable tie rule, because traversal order usually changes. A tolerance-based tie scheme must itself be consistent; a non-transitive “almost equal” comparator can create ordering failures. [Inference, informed by S20,S21]

### 4.2 Sampling semantics: avoid a plausible-looking distribution change

Area-weighted triangle sampling followed by uniform barycentric sampling within the chosen triangle produces uniform area sampling in the chosen coordinate metric. This follows by multiplying triangle-selection probability by conditional per-triangle area density. Nonuniform transforms can change each triangle's relative area. Reuse of object-space weights is therefore not automatically correct for a world-area contract. [Mathematical inference]

For density sampling, selecting triangles by approximate average density and then applying the old rejection rule can unintentionally weight density twice. An importance proposal must account for its proposal probability and bounds. Zero-weight, negative/nonfinite-weight and near-zero-total cases need defined behavior. A cheaper texture resolution is an approximation, not a free optimization. Keep existing semantics unless a new sampling mode and scene-version policy are explicitly approved. [S19; inference]

For sequential spacing, parallel *testing* does not automatically permit parallel *acceptance*. Each accepted point affects later candidates. Preserve the candidate/random sequence and ordered acceptance unless the new distribution is a deliberate product change. Where an accepted candidate gets its identity also matters to local edits. [Inference]

### 4.3 Numerics, transforms and reproducibility

Shewchuk demonstrates adaptive robust orientation/incircle predicates. Use that idea selectively for near-boundary classifications, not as an excuse to make all geometry arithmetic arbitrary precision. CGAL explicitly warns about degenerate primitives in its AABB-tree setting. Exact signs do not make intersections, distances, projected coordinates or texture indices universally robust. [S21,S24]

Validate finite input, denominator conditioning, zero-area/duplicate triangles, singular transforms, very large coordinates and extreme aspect ratios. Prefer carrying already known barycentric/UV data to reconstructing it through a poorly conditioned inverse. A local origin may improve conditioning, but must preserve transforms and tolerances across stages. Radius, distance and boundary tolerances need meaningful scene-unit contracts, not unrelated epsilon constants. [Inference]

Normals require inverse-transpose treatment and normalization; mirrored transforms require an explicit handedness/winding policy. [S26] A separate often-missed issue is nearest-point distance under nonuniform scaling. For column-vector notation with linear transform A:

`world squared distance = (x-p)^T A^T A (x-p)`.

Ordinary object-space Euclidean nearest point minimizes a different metric unless the transform is a similarity. Reuse object-space BVHs only with correct bounds/metric handling, or query an appropriately prepared world-space representation. Max's matrix convention must be handled explicitly; the equation is mathematical notation, not Max API code. [Inference]

Counter-based generators such as Random123 make random integers a function of a key and counter rather than a shared mutable stream. [S25] They are promising for a *newly versioned* generation scheme keyed by seed/candidate/channel. They do not make replacement of a legacy RNG behavior-preserving, nor do deterministic integer draws guarantee identical floating-point layouts across compilers/devices.

Compiler reassociation, contractions/FMA and special-value handling can change results. [S27,S28] Distinguish three proposed contracts:

- **Exact-equivalence optimization:** same supported build/environment, ordered identities and agreed numeric representation unchanged. This is the default for a patch unless the existing product contract says otherwise.
- **Numerically equivalent backend:** identity/count/classification unchanged; explicitly justified tolerances for transforms; robust ambiguous-boundary policy. Requires owner approval and tests, not a blanket tolerance.
- **New distribution/version:** changed seeded layout or spacing semantics; old scenes retain a compatible evaluation route or explicit migration.

Do not promise cross-vendor, cross-compiler bitwise parity for unrestricted floating-point geometry. Equally, do not use that difficulty to excuse changed source IDs or missing instances.

### 4.4 Data layout and SIMD come after avoidable work

Use contiguous owned buffers and reserve/reuse temporary storage when profiles show allocation or memory traffic. Separate hot fields from cold metadata. A structure-of-arrays layout helps some coordinate kernels; an array of small records may be better when every operation reads the whole placement. Choose using the measured access pattern rather than fashion.

Arithmetic intensity is work per byte moved. A low-intensity transform loop may already be limited by memory bandwidth; adding threads/SIMD can stop helping while raising contention. Inspect compiler vectorization and generated code before hand-written intrinsics. Preserve scalar code and a supported ISA baseline, and treat FMA/fast-math changes as numerical changes requiring qualification. Avoid introducing a library solely to vectorize a small unmeasured loop. [S17,S27,S28; engineering inference]

## 5. Concurrency: protect the host boundary

### 5.1 What the documentation actually permits

The 2026 SDK explicitly describes reference and node evaluation as single-threaded. Materials/maps/atmospheric methods called during rendering have particular thread-safe obligations. Max 2027's Deformer::Map/MapNormal are further specific examples. Nitrous custom render items may execute separately and must be self-contained. These are API-specific rules, not a global scheduler guarantee. [S01–S03]

The conservative plugin boundary is: obtain host data in the permitted evaluation context; copy the needed numerical data into owned storage; compute only on that storage; return or publish through a supported host path. No worker may retain a borrowed MAXScript/GC value, evaluate a live node, send notifications, update UI, or use graphics resources simply because the algorithm itself is C++. A pure numeric operation on an SDK value type still needs its implementation checked for hidden host access. [Inference]

### 5.2 Choose the simplest execution model

| Model | Credible use | Cost and strongest argument against it | Decision rule |
|---|---|---|---|
| Optimized serial, coalesced events | Small/medium work, expensive host stages, already-responsive edits | Cannot remove a genuine long pure-compute stall | Default control; keep when latency target is met. |
| Bounded joined ranges | Independent per-candidate work with stable input/output slots | Startup, synchronization, bandwidth contention; caller still blocks | Adopt only past measured crossover, including launch/join overhead. |
| Persistent executor | Frequent independent work where worker startup is a material measured cost | Queueing, idle resources, shutdown/dependency deployment complexity | Do not add just because a thread pool is conventional. |
| Asynchronous snapshot/compute/commit | Long exact builds prevent UI interaction even after simpler fixes | Additional snapshots, stale-result control, cancellation, scene lifecycle, more complex rendering semantics | Require evidence that it improves event-to-correct-result behavior, not merely perceived activity. |

Use disjoint output ranges and ordered compaction, avoid a shared RNG, propagate exceptions to the owning operation, and join all workers on every error path. Limit total concurrent work across controllers, not only per-layer participant counts. A many-controller scene can multiply independently sensible limits into oversubscription. During IR, use a configurable conservative policy and measure foreground latency against renderer contention. [Inference]

oneTBB's task_arena offers bounded participation, but importing it does not remove host constraints. A local arena is preferable to changing a shared runtime's global policy. Verify exact headers/runtime, ownership and deployment. The SDK specifically documents a TBB version for Max 2026; the public USD project is not authoritative for the whole process. [S07,S29,S30]

Do not pin cores or force maximum threads as a default. Hybrid CPUs and NUMA can make placement/cache traffic matter, but affinity policies belong after traces demonstrate a problem. High CPU utilization is not an objective; low correct-result latency with bounded resources is.

### 5.3 Minimum contract for asynchronous publication

This is **pseudocode-level design**, not verified Max API code:

```text
Host-side request:
    capture owned input and (scene epoch, owner lifetime, revision, time, mode)
    retain the previous complete result
    replace obsolete pending work; enforce a global memory/work budget

Worker:
    read only owned immutable input
    write private output
    check cooperative cancellation at bounded work intervals
    report completion/error without touching the host

Supported host-side completion:
    validate epoch, owner, latest revision, time, and evaluation mode
    discard obsolete output without side effects
    atomically commit a complete valid result
    invalidate only required display/render representations
```

Undo/Redo changes revision and may invalidate identity; reset/load/merge can change scene epoch; node deletion ends an owner lifetime; plugin shutdown must prevent callbacks into unloaded code. A generation counter alone is insufficient if object IDs are reused or a new scene resets the counter. Canceled workers must release input and GPU resources, and shutdown must not wait indefinitely for a worker blocked on the host thread. [Inference]

Manual mode must remain Manual: a background event must not secretly commit a new procedural layout. Rendering needs an exact requested revision/time or an explicit failure policy; silently rendering the last viewport snapshot is unacceptable. A stale visual result can be a useful UI policy only when clearly identified and never published as current exact data.

Start by allowing at most one running and one latest pending request per controller, under a global limit. That is a proposed bound, not a universal architecture: one scene-wide scheduler may be simpler in a given codebase. Do not retain unbounded versions merely because garbage collection will eventually free them.

## 6. Viewport architecture and its real tradeoffs

### 6.1 Three distinct designs

| Design | Representation | Advantage | Cost / losing case |
|---|---|---|---|
| Prepared CPU batching | Owned prepared display data submitted in larger batches | Simple, testable, can preserve special coloring and small-proxy behavior | Per-redraw submission remains; expanded per-instance geometry may consume RAM. |
| Retained expanded geometry | Prepared aggregate/chunk meshes in managed viewport buffers | Removes repeated rebuilding/submission of unchanged data | Still duplicates geometry proportional to displayed instances; changing populations/topology may be expensive. |
| Retained shared geometry + GPU instance data | Source mesh/streams shared across compatible instances; separate transforms/attributes | Avoids expanded duplicates and enables appropriate buffer updates | Source/material diversity, unsupported overrides, selection integration, driver behavior and lifecycle increase complexity. |

The first may remain the best long-term proxy implementation. The second is not automatically equivalent to GPU instancing. None makes generation or final rendering faster by definition. Autodesk documents the relevant retained and viewport-instancing mechanisms. [S03–S06; comparison and recommendation are inference]

For a hypothetical unindexed six-triangle proxy with 28 bytes per vertex, expanding 100,000 copies is 50.4 MB before metadata/allocator overhead. An assumed 64-byte per-instance record is 6.4 MB plus shared source geometry. **Those are illustrative representation sizes, not actual Nitrous or Cyrus layouts.** HQ streams, indexing, multiple views and CPU/GPU copies change the real values. The useful question is whether memory scales with **instances×geometry** or **shared geometry+instances**, not whether one arbitrary format is fastest.

### 6.2 Verified Nitrous API details to carry into a spike

The relevant namespace is `MaxSDK::Graphics::ViewportInstancing`; `InstanceDisplayGeometry` extends `IRenderGeometry`. The 2026/2027 pages document viewport-only instancing and the `optimesh.lib` dependency. `CreateInstanceData` precedes `UpdateInstanceData`; updates cannot introduce channels, change instance count, or change source vertex count. High Quality requires positions, normals, four UV streams, tangents and bitangents even when some are not otherwise used. [S04,S05]

`InstanceData` additionally distinguishes node-relative and world-space transforms. With separate position/orientation/scale arrays, updates must provide all three. Material assignments are creation-time data and sorting can reorder internal instance data. Its UVW override is a single coordinate for a whole channel per instance, not arbitrary independent mesh UVs. [S06]

**Consequences for a prototype (inference):** keep stable application instance IDs separate from buffer order; define per-source/material grouping; rebuild the right group on population changes; do not fake spare instances with zero scale without testing bounds, selection and shading. Source deformation and topology changes need explicit update/recreate tests. More source groups may mean more buffers/batches and preparation cost.

A native object/display adapter may be needed around a scripted controller, but its exact integration cannot be inferred from the existence of the namespace. Verify a target-SDK sample through a minimal object first. Do not assume a GraphicsWindow redraw callback can call the new API as a drop-in replacement. [Unknown integration; inference]

### 6.3 Required display responsibilities beyond drawing triangles

A viable retained path must cover aggregate/per-instance bounds, viewport and object visibility, selection/highlight/sub-object hit testing, wireframe/edged-face states, multiple simultaneous views, Standard and High Quality, material conversion, colors and UV channels, mirrored/nonuniform transforms, source deformation, and source deletion/replacement. Picking may require a separate CPU broad phase or an approved host hit-test path. It is not free merely because the GPU draws many copies. [Proposed qualification]

Keep viewport resources in the SDK-supported ownership/lifetime system. Custom render items must not reach back to mutable scene data while drawing; Autodesk explicitly warns they can run independently. Reuse prepared display data across passes rather than consulting the scene inside every Display. Test resource recreation/device changes in the supported callback model; the exact release/reset sequence for the hybrid plugin remains a local SDK question. [S03; inference]

### 6.4 Display quality policies are product choices, not parity-preserving speedups

Points, simple proxies, full meshes and sprites serve different visual tasks. Sprites can lower primitive cost but change silhouette, lighting and picking expectations; very large point/sprite populations can still be limited by screen coverage and blending. Select by projected size and task, not by assuming every sphere is a full mesh. [Inference]

Culling and LOD may help, but CPU culling also costs work. Small batches or a mostly visible scene may lose. Use stable IDs for deterministic viewport subsets and hysteresis for LOD thresholds; prioritize selected instances. Separate benchmark runs with identical populations/representations from explicitly reduced-detail interactive modes. Do not label hiding more instances as an algorithm speedup. [Inference]

A viewport frustum rule is not a safe final-render rule: offscreen geometry can affect shadows and reflections. Chaos documents that camera clipping changes those effects, and that simultaneously resident LOD meshes can increase RAM. [S35] No broad claim that “LOD always saves memory” is appropriate.

## 7. GPU computation: optional, stage-specific, and measured end to end

### 7.1 Cost model and plausible work

For a synchronous CPU-visible result, measure:

`T_gpu_path = host extraction + packing + allocation/amortization + upload + dispatch + kernel + necessary synchronization + readback + publication`

Subtract only overlap actually visible in a trace; do not subtract a theoretical overlap twice. Persistent device data can reduce repeat transfers only while its validity and ownership remain correct. A host thread may still block preparing geometry or publishing results. GPU rendering/viewport contention and VRAM headroom are part of the comparison. NVIDIA explicitly emphasizes transfer reduction and conditional asynchronous overlap. [S17; model is inference]

Candidates worth considering *after profiling* include large batches of independent closest-point/proximity queries against reused geometry, high-arithmetic mask/noise evaluation, or independent updates in a correctly defined iterative method. Very cheap transforms may be transfer-bound unless their results remain GPU-resident for a verified consumer. Greedy acceptance, deeply irregular traversal, changing topology and host texture evaluation are harder candidates. No candidate is presumed to be Cyrus's current hotspot. [Inference; tyWetmap is a documented proximity-query precedent, S39]

### 7.2 Backend comparison without a multi-backend commitment

| Option | Practical case | Main cost / objection | Current recommendation |
|---|---|---|---|
| Optimized CPU | All supported machines, modest batches, CPU consumers, tight parity | Limited by serial dependencies or bandwidth on some large problems | Baseline and default fallback. |
| CUDA | A worthwhile NVIDIA workload and team competence; diagnostic tooling | NVIDIA-only deployment, transfers/VRAM contention, separate numerical/runtime qualification | Consider one isolated experiment only after a numerical workload is selected. |
| D3D11 DirectCompute | Windows HLSL work on devices that expose required features | CPU-visible results still need synchronization/readback; device sharing with Max unverified; double support optional | Plausible cross-vendor spike, not an automatic consequence of Nitrous usage. [S33] |
| OpenCL | Simple portable kernels with explicit device/capability checks | ICD/driver behavior, build/runtime variation, optional features and separate interoperability checks | Plausible only when validated on actual target devices; an OpenCL version number is insufficient. [S32] |
| SYCL/DPC++ | Existing expertise and a justified C++ compute toolchain | Adds compiler/backend/runtime deployment and qualification; no demonstrated need here | Defer. Windows NVIDIA support exists in the examined version, so rejection is about cost/need, not impossibility. [S34] |

Do not add all four, a general GPU abstraction, or an engine dependency in anticipation of hypothetical portability. Choose at most one experimental backend based on the qualified user hardware and actual kernel. A separate device/context may be simplest but increases copies/resources; zero-copy or shared buffers require a verified Max/driver/API contract. This review establishes **no such zero-copy contract**.

Before shipping any optional backend, pin compatible compiler, driver minimums and redistributable components; verify the actual license notices for those exact versions; inventory loaded DLLs alongside renderers; and ensure the plugin still loads and evaluates via its qualified CPU path when acceleration is absent or disabled. Do not overwrite host/renderer runtime DLLs. Cross-DLL allocations must follow a consistent ownership contract. [S31; proposed deployment gates]

### 7.3 The smallest GPU rejection experiment

Extract a representative immutable numeric input/output contract from a measured CPU hotspot. First implement only real packing, required allocation/upload, minimal dispatch, completion, and required-size readback/publication. Validate and record every transferred byte. This is not a kernel benchmark: it estimates an **optimistic host-visible GPU-path floor** for that dataflow.

If that floor already consumes the candidate CPU stage's budget—or cannot produce worthwhile complete-operation improvement—stop before porting the algorithm. Passing the floor test does not prove a benefit. Only then implement one correct kernel and compare with the best qualified serial/bounded-CPU path, including cold start and an active viewport/renderer. [Inference; experiment E03]

Do not assume an identity-copy kernel faithfully models a bandwidth-heavy or branchy real kernel. It is deliberately an optimistic rejection screen; include the actual required data sizes and memory allocations, then confirm with the real candidate if it passes.

## 8. Production case studies: useful mechanisms, bounded conclusions

### Case A — tyCache: GPU instancing buys something and gives something up

The documentation describes shared GPU display rather than constructing a per-particle combined mesh. It also explains why ordinary mesh modifiers on the tyCache object are not visible in that mode and why particular mapping overrides can force a much larger mesh representation. [S36]

**Transfer to Cyrus:** identify which source/channel combinations share geometry and retain a supported fallback for others. Include selection, modifiers, mapping and population changes in the comparison. **Cannot infer:** tyFlow's private buffer layout, scheduler, exact speedup, or renderer architecture. Do not copy its UI option and expect identical performance.

### Case B — tyFlow compute: acceleration is not one universal switch

Different documented solvers use CUDA or OpenCL, with different CPU fallbacks. A more specific operator page describes CUDA BVH proximity work. The GPU rollout also provides a slower compatibility mode for a documented cuBLAS problem and warns that transfers can make small simulations slower. [S37,S39,S42]

**Transfer:** choose a kernel-specific backend with a real failure mode and fallback, and measure the crossover. **Cannot infer:** that Cyrus needs all the same libraries, or that every operation in this product uses GPU computation. The older broad FAQ's inventory conflicts with more specific pages; its transfer warning is corroborative, not a current complete feature specification. [S38]

### Case C — Chaos Scatter: representation and rendered effects matter

Chaos explains that instancing avoids repeated source meshes but not all per-instance memory, and that loading multiple LOD assets can increase RAM. It recommends asset-level clumps in appropriate vegetation workflows and documents the visibility cost of camera clipping. [S35]

**Transfer:** separate authoring granularity from display/render granularity; evaluate clumps as an explicit content workflow, not a silent density rewrite. Test reflected/shadow visibility. **Cannot infer:** Chaos's private placement algorithm, cache ownership, or relative performance against Cyrus.

### Case D — Max/Nitrous and cross-plugin dependencies

Autodesk's retained display design separates preparation from repeated display; its host-specific requirements also demonstrate why “use the newest library” is not a deployment strategy. The public USD plugin dependency guidance is informative but cannot override target-host SDK requirements. [S03,S07,S30]

**Transfer:** follow supported data lifetime and build constraints, while keeping independent numerical code testable. **Cannot infer:** that every host plugin may use the same thread pool, Python packages, allocator, renderer interface, or build toolchain interchangeably.

## 9. Ranked shortlist and explicit non-goals

The ranking is a **sequence for investigation**, not a claim about the current bottleneck or a requirement to implement all six options. Benefits are unknown until measured. All adoption thresholds below are proposed decision criteria, not observed performance. Agree on them before reading candidate results.

### D01 — Demand-driven work with explicit validity (broadly applicable now)

**Workflow/hypothesis:** orbiting, changing a display control, or editing one layer triggers avoidable preparation/generation elsewhere. **Evidence:** the separation of display preparation and repeated display is documented [S03]; whether Cyrus duplicates work is unknown. **Smallest change:** instrument causes, coalesce equivalent requests and reuse an existing valid result; keep synchronous execution. Do not begin by building a general dependency-graph framework.

**Cost:** low to medium code change; retained inputs/results increase memory and require validity by geometry, transforms, time, maps and mode. **Failure modes:** stale results, missed dependent layers, Manual-mode changes. **Simpler alternative/objection:** leave the current invalidation intact if its cost is negligible or dependencies cannot yet be represented safely. **Test:** E01 mutation/no-op traces plus fresh exact rebuild oracle. **Proposed gate:** eliminate proven redundant generation and show useful response improvement beyond noise, without a missed update; reject on any validity defect. **Confidence:** high in the principle, unknown benefit. **Reverse recommendation:** traces show preparation/generation already absent from these interactions.

### D02 — Selective prepared geometry and data-local exact kernels (broadly applicable now, only at measured hotspots)

**Workflow/hypothesis:** costly surface queries, masks or sampling preparation dominate exact updates. **Evidence:** query/build mechanisms and numerical constraints [S18–S28]. **Smallest change:** retain a linear reference; prepare the repeated predicate/index once per valid input, use owned contiguous buffers and preserve candidate/tie order.

**Cost:** medium algorithm/test effort; O(primitives/points) index memory and build/refit cost. **Failure modes:** slivers, bad bounds, holes, world/object metric mismatch, identity changes. **Alternative/objection:** a vectorized or cache-friendly scan can beat an index for small/changing workloads. **Test:** E03 CPU stage with small/large/static/edited geometry and exact oracle; include preparation in timings. **Proposed gate:** a measured net win on the targeted operation and no materially slower small-scene path; choose crossover from measurements, not an arbitrary count. **Confidence:** high conditional opportunity; size of gain unknown. **Reverse:** preparation or memory dominates, or the current stage is already efficient.

### D03 — Retained viewport representation, optionally true instancing (investigate after profiling)

**Workflow/hypothesis:** unchanged-scene navigation remains draw-submission or geometry-memory bound. **Evidence:** documented retained/instanced paths and restrictions [S03–S06,S36]. **Smallest change:** one target-host prototype for one declared representation; compare existing CPU batches, retained expanded chunks and shared instancing. Extend only the winning eligible path, retaining fallback.

**Cost:** medium to high integration/qualification; GPU streams plus CPU state; shared instancing reduces duplicate geometry in suitable cases but many sources/materials and topology changes add cost. **Failures:** invisible HQ geometry, incorrect selection/order, UV/mirror differences, resource lifetime/device changes. **Alternative/objection:** keep CPU batches; a small proxy workload may already be fast enough. **Test:** E02. **Proposed gate:** at least 20% lower p95 navigation interval on the target bottleneck, or at least 30% lower measured display working set with no meaningful response regression, with full correctness. These margins reflect added subsystem cost and are negotiable before testing. **Confidence:** high API availability, medium project suitability. **Reverse:** controlled comparisons show no meaningful benefit or unacceptable compatibility cost.

### D04 — Bounded synchronous numeric parallelism (investigate after profiling)

**Workflow/hypothesis:** independent numeric work dominates an update after avoidable work is removed. **Evidence:** host restrictions and arena controls [S01,S02,S29]; eligibility in Cyrus unknown. **Smallest change:** a serial fallback plus disjoint ranges joined before return, using current infrastructure if available. Preserve RNG/ordered acceptance and propagate exceptions.

**Cost:** low/medium with existing workers; higher with a new runtime; launch/join/scratch memory, bandwidth and renderer contention. **Failures:** oversubscription across controllers, false sharing, order changes, hidden host calls. **Alternative/objection:** serial SIMD/preparation fixes may be faster and simpler. **Test:** E03 participant/grain sweep including renderer load and small inputs. **Proposed gate:** material complete-update improvement, unchanged outputs and no significant tail-latency penalty; small jobs stay serial. **Confidence:** medium conditional. **Reverse:** scaling saturates quickly or host/transfer work dominates.

### D05 — Asynchronous snapshot/compute/commit (defer unless synchronous interaction still fails)

**Workflow/hypothesis:** a necessary long pure-compute update blocks manipulation after D01/D02/D04. **Evidence:** host and display lifetime requirements [S01–S03]; scheduling design is inference. **Smallest change:** one bounded latest-request flow, old complete preview retained, host-side checked commit; not a general job system.

**Cost:** high lifecycle/test cost, simultaneous input/output generations, cancellation/shutdown complexity. **Failures:** stale publication, deadlock, callback into deleted owner, wrong frame rendered, Undo/Redo identity drift. **Alternative/objection:** coalescing, explicit manual update, or cheaper declared interactive display can solve the user problem without concurrency. **Test:** E01 lifetime/mutation extension after a synchronous trace demonstrates need. **Proposed gate:** responsive input plus no worse latest-exact-result latency, bounded memory and zero stale commits under adversarial event sequences. **Confidence:** high on required safeguards, unknown need. **Reverse:** simpler modes meet the interaction target or host extraction remains the blocking stage.

### D06 — One optional GPU compute kernel (defer)

**Workflow/hypothesis:** a large independent numeric stage remains dominant and device-resident reuse is plausible. **Evidence:** transfer constraints, capability/deployment differences and documented proximity-query precedent [S17,S32–S34,S39]. **Smallest change:** E03 transfer-floor probe on one backend, then one real kernel only if the floor passes. No backend abstraction required initially.

**Cost:** high development/driver/VRAM/numerical support cost; CPU fallback retained. **Failures:** no crossover, resource contention, different boundary decisions, unsupported device, allocation/driver failures. **Alternative/objection:** exact bounded CPU with prepared queries; kernel speed may disappear in the full operation. **Proposed gate:** around 30% lower full eligible-operation latency on the declared target, no significant small-scene/IR regression, adequate 32 GB/VRAM behavior and agreed parity. This higher hurdle reflects added support cost. **Confidence:** high in the rejection test, low that adoption is justified today. **Reverse:** measured large end-to-end benefit on real workflows with acceptable deployment and output contracts.

### Do not build yet, or reject outright

**Defer:** a permanent executor just to avoid hypothetical thread startup; asynchronous scene evaluation before ownership exists; a new renderer-instance backend without verified Chaos SDK access and translation profiling; general adaptive sampling that changes legacy layouts; hand-written SIMD before compiler/profile evidence; automatic LOD beyond declared display-quality modes.

**Reject as presently framed:** GPU-first rewrite; four compute backends; forced maximum core usage/affinity; workers evaluating live Max nodes or GC values without documented support; assuming a mutex makes arbitrary host APIs safe; unbounded caches/queued generations; silent camera culling in final render; changing seeds/identity to hide nondeterminism; reporting kernel/viewport-step timing as whole-product FPS.

## 10. Three experiments that can reject competing architectures

These are specifications for the local engineer, **not completed experiments**. Select only the branches justified by the preceding measurement.

### E01 — Where does one artist action actually spend time?

**Question:** is the remaining problem repeated work, scheduling, pure computation, drawing, or the host/renderer? Can coalescing and narrow reuse solve it without another execution architecture?

**Input:** one small scene, one representative production scene, and a stress scene chosen to expose many controllers/layers or an existing memory threshold. Keep assets/seed/build fixed. Include an unchanged camera orbit, one display-only change, one density change, one source-transform change, a small manual edit, a geometry/topology edit and one render/IR transition. Test Manual and live-update modes separately. A camera-dependent feature, if enabled, is a distinct condition.

**Baseline/control:** verify loaded native and script build identities, not only files on disk. Save exact scene hashes/settings and final ordered output. Run the current unmodified workflow. Diagnostic controls may freeze a known-correct result or disable one subsystem to attribute cost, but must be labeled ablations—not shipping speedup comparisons. If redundant work is observed, change only coalescing or a single cache validity path in an isolated branch.

**Measurements:** event receipt, scheduled start, extraction/preparation, numerical stages, script/native conversion, commit, redraw invocation, presentation correlation, render preparation; per-revision call counts and invalidation reasons; CPU thread time and wall time; peak private commit/resident memory, plugin cache bytes and GPU memory. Record what remains unobservable rather than substituting another metric.

**Correctness oracle:** exact committed instance/ID/source/transform output against an explicit fresh rebuild; invalidation dependency checks; correct Manual behavior; selection state and loaded-scene persistence. For scheduling changes, add rapid alternating edits, Undo/Redo, node deletion, reset/load and canceled render. A retained stale result must never be marked current. Validate first, then time without intrusive checks.

**Raw output:** `run_manifest.json`, `events.csv`, `stage_spans.csv`, `output_hashes.json`, profiler trace paths, viewport presentation CSV, memory samples, fallback/cancel records, scripts/input trace and source diff. Suggested span columns: run_id, event_id, owner_id, revision, time_sample, stage, thread_id, start_ns, end_ns, item_count, bytes, cause, result.

**Decision/stop:** if no-op/display interactions already avoid calculation, reject a generation-cache rewrite as their fix. If scheduling dominates, test coalescing before async. If host extraction dominates, stop numerical offload proposals until extraction is addressed. If draw/queue time dominates, proceed to E02. A mutation missed by caching rejects that candidate regardless of timing. Proposed responsiveness goal: acknowledge ordinary input within 50 ms and cached actions within 100 ms at p95 on the declared scene/hardware; these are design targets, not guaranteed platform limits.

### E02 — CPU batches, retained expanded geometry, or shared viewport instances?

**Question:** which display representation gives the best navigation, update cost, memory and compatibility for the actual workload?

**Input:** freeze a correct placement result so all variants draw the same transforms/IDs. Sweep displayed population through small, production and stress ranges, including just below/above every actual cache cap. Cross that with few repeated sources versus many unique sources, simple proxies versus detailed meshes, and one versus many controllers. Add material diversity, UV overrides, mirrored/nonuniform transforms, selected instances, a deforming source, and a changed instance count. Run Standard/HQ and multiple viewports in supported hosts. Test a 32 GB machine and the target GPU; test another vendor before making a cross-vendor claim.

**Variants:** A current correct CPU batch path; B minimal retained expanded chunks; C shared geometry with SDK viewport instances. B and C are isolated prototypes only. Do not build both fully if an earlier controlled result rejects one. Keep displayed geometry, coloring, visibility, viewport dimensions and quality equal. Run separate explicitly degraded-preview tests only after like-for-like tests.

**Measurements:** stable-scene frame/present intervals; CPU submission and preparation, GPU timeline if supported; initial build, warm orbit, one-instance transform edit, population change, source deformation/topology and material change; bounds/picking latency; peak and steady CPU/VRAM; resource counts before/after deletion/reset; multi-generation/cap fallback behavior. Plot cost against both instance count and source/group count—one axis is insufficient.

**Correctness oracle:** canonical drawn geometry/transform/color/channel data where accessible, independent hit-test selections and conservative bounds, deterministic fallback populations, and saved screenshots under fixed camera/lighting. Geometric equality is not necessarily pixel identity under a changed shader/driver path; investigate visible differences rather than letting broad image tolerances hide wrong normals/mapping. Final-render placements must be unchanged.

**Raw output:** manifest and variant feature flags, frozen input/result hashes, per-frame CSV, source/group/batch counts, CPU/VRAM allocation timeline, redraw and update timings, comparison captures, selection/bounds assertions, device/driver details and failures.

**Decision/stop:** use D03's proposed margin or a pre-agreed absolute frame-budget goal. Reject invisible HQ output, changed selection IDs, unbounded resources, silent degraded quality or cap-triggered population loss. Keep A if it meets target budgets and B/C do not earn their maintenance cost. Keep a specialized fast path plus fallback when only a clear eligibility subset wins. Do not extrapolate a six-layer proxy demo to detailed materials or render performance.

### E03 — Exact algorithm improvement, bounded CPU ranges, or GPU offload?

**Question:** does the eligible hotspot need a better algorithm, more CPU participants, a GPU, or none of these?

**Selection gate:** choose the largest *measured* owned-numeric stage from E01, not a fashionable kernel. Suitable candidates might be repeated proximity/closest-point queries or an independent per-point calculation. When no sufficiently large independent stage exists, record that finding and stop this experiment.

**Input:** export owned numeric snapshots with their input/output contract. Include small/medium/large point batches, low/high source mesh complexity, boundary holes/slivers, sparse acceptance where relevant, transformed geometry, changed inputs and unchanged reuse. Preserve seed/candidate order. Use actual exported datasets plus carefully labeled synthetic adversarial cases; do not call standalone timings Max benchmarks.

**Phase A — serial algorithm:** compare the current correct stage with a simple exact reference and a minimal prepared/indexed or allocation-reduced candidate. Count construction/refit cost, memory, tested primitives and queries. Apply the same predicates/tie order and compare outputs. If a changed distribution is required, stop treating it as an equivalent optimization.

**Phase B — bounded CPU:** compare serial to a small participant/grain sweep, including the caller and launch/join time. Preserve independent fixed output slots and any ordered final acceptance. Test one and many simultaneous controllers, foreground navigation and relevant active renderer modes. A persistent pool is a later branch only if thread startup materially dominates successful joined work.

**Phase C — GPU rejection floor:** only if a large eligible stage remains, implement the transfer/dispatch/readback floor from Section 7.3 for one justified backend. Include all required input/output bytes and synchronization with the actual CPU consumer; report cold allocation/context and warm reuse separately. If even the optimistic floor cannot meet the complete-operation target, reject GPU work. If it passes, one real kernel may be compared—not an entire engine port.

**Oracle:** exact IDs/counts/order and declared numeric parity; boundary/tie cases; independent geometric checks rather than only matching a possibly flawed baseline. CPU/GPU differences require the existing correctness contract or explicit approval of a narrower versioned one. Check failure/unsupported-device fallbacks and renderer coexistence before claiming adoption.

**Raw output:** immutable dataset metadata/hashes, build/compiler/FP flags, all stage timings, participants/grain, transfer bytes, buffer lifetimes, CPU/GPU memory, parity/error distributions, candidate reject reasons, and complete in-host eligible-operation timings after integration.

**Decision/stop:** prefer the smallest winner. Retain serial below a measured crossover. Require the D06 full-operation margin before shipping compute offload; passing a kernel-only comparison is insufficient. Reject any unsanctioned layout change, host access in workers, RAM/VRAM failure, significant interaction contention or unsupported deployment. A favorable synthetic kernel is justification for a real-scene test, not a product performance claim.

### Common trial discipline

Start with a short pilot to estimate variability and profiler overhead. Then choose enough paired repeated runs to resolve the pre-agreed decision margin; do not prescribe a magic number independent of noise. Alternate or randomize A/B order, include explicit cold and warmed states, keep raw trials, and use robust paired summaries/uncertainty. Set a time limit and minimum decision precision before collecting the final comparison; report inconclusive results instead of collecting until one wins.

Use p95 tails within sufficiently long captures, but report uncertainty across independent captures. Do not hide small-scene regressions in a grand average. As a proposed review flag, investigate regressions exceeding both 5% and 1 ms in an interaction; small absolute regressions may still matter for a tight frame budget, so that is not automatic permission. Require zero known correctness failures. Compare optimized Release builds using verified symbols; instrumentation overhead should be measured and kept out of the headline result.

## 11. Staged correctness, performance and qualification matrix

This is a proposed risk-based matrix, not a list of completed tests. Expand the combinations around changed subsystems rather than mechanically testing an enormous Cartesian product.

| ID / stage | Workloads and failure modes | Required evidence / claim boundary |
|---|---|---|
| Q00 — identity and package | Clean profile/install; old/new DLL/script ambiguity; generated output; dependency search paths | Runtime-emitted native/script IDs plus loaded module paths, scene/build hashes, compiler/SDK/runtime manifest. Disk hashes alone cannot prove which script text was already executed. |
| Q01 — portable numerics | Sampling weights, source IDs, tie order, min spacing, transforms, serial/parallel parity | Reference/oracle output, property checks, sanitizer-supported native tests. Passing these does not establish Max integration. |
| Q02 — pathological geometry | Empty/zero/sliver/duplicate triangles, extreme coordinates, singular/mirrored/nonuniform transforms, nested holes, topology edits, nonfinite inputs | Defined reject/error behavior; robust classification; no out-of-bounds/nonfinite indexing; explicit scene-unit tolerances. |
| Q03 — interaction and lifetime | No-op, layer/display change, manual/local edit, live vs Manual, Undo/Redo, delete/clone/merge, load/reset, held/released input | Fresh-rebuild equivalence and identity preservation where promised; no stale commit; bounded cancellation/shutdown. |
| Q04 — actual viewport | Both target hosts; proxy/point/full mesh; Standard/HQ; selection, bounds, many sources/controllers, multi-view, changed count and geometry | Like-for-like data and visual comparison, p95/p99 frame/response, resource ownership and fallback logs. No renderer claim from this row. |
| Q05 — memory endurance |32 GB host; many unique sources; repeated edited generations; below/above caps; long sessions; allocation failure and renderer load | Whole-process commit/working set, plugin allocation counters, relevant VRAM, stable high-water behavior or explained retained memory; no growing orphan resources. A bounded cache payload is not a bounded process. |
| Q06 — animation | Sequential/reverse/random time jumps, animated transforms/deforming sources, changing populations, fractional render samples | Frame/time/revision correspondence, deterministic policy, correct motion data, no old-frame publication. |
| Q07 — renderer workflows | Exact installed Corona/V-Ray versions; final/IR; start/change/cancel/restart; missing sources; CPU/GPU contention where applicable; render-worker mode | Separate translation and renderer timing; exact render population, transforms/materials/motion; restored source flags/resources; no deadlocks. |
| Q08 — release hosts | Native build **and actual application run** on Max 2026 and 2027 with supported point releases | Save/reopen/clone/merge/Undo plus workflow suite on each host. A format downgrade/reopen in 2027 is not a 2026 application test. |
| Q09 — dependencies/devices | No dev-only DLLs; other plugins/renderers present; acceleration absent/disabled; target vendor plus another vendor when claimed; supported device recreation | Clean install/uninstall/coexistence, CPU fallback, loaded-library inventory, actionable errors and resource release. Device-reset fault injection only through a safe supported test approach. |

**Hardware staging:** first use the actual development machine for diagnosis, then a representative 32 GB machine for memory/latency qualification. Add a different CPU/core topology where scheduling changes, and a second GPU vendor where a cross-vendor graphics/compute claim is intended. Record exact driver/API/VRAM, not just model names. Do not require every compute backend on every device; only qualify the supported paths and their fallback.

**Beta claim limit:** “tested on these exact hosts, configurations, scenes and workflows, with these measured populations and known limitations.” Not “buttery smooth at any count,” “32 GB supported” based only on a cache cap, “GPU accelerated” without identifying drawing versus calculation, or “Corona/V-Ray compatible” based on portable tests. Changes to thread scheduling, serialization, resource ownership or renderer transport require relevant host requalification even when the point set is byte-identical. [Proposed release policy]

## 12. Focused handoff to the local Codex engineer

Work against the verified current repository and loaded package. Do not adopt old function locations or this conversation's earlier timings as the current baseline. Locate actual source structures by responsibility:

| Look for | Measure / verify | Do not assume |
|---|---|---|
| Invalidation, callbacks, timers and per-layer update routes | Event-to-stage counts, reasons, Manual/live behavior, independent/dependent layers | That every callback needs a rebuild, or that all redraw callbacks are redundant. |
| Host mesh/map/source extraction and script/native boundaries | Validity intervals, copied bytes, conversion/allocation time, ownership | That moving a loop to C++ removes host/marshalling cost. |
| Geometric predicates, acceleration structures and sampling streams | Query counts, preparation amortization, exact tie/acceptance/order, transforms | That a BVH is absent, or that a new sampler preserves seed identity. |
| Worker entry points and data types | Owned numeric ranges, joined lifetime, global participant count, exceptions | That SDK value types or borrowed script arrays are worker-safe. |
| Proxy/full-mesh/point display caches and submission routes | Eligible population, batch/source counts, caps/fallback, generations, draw/update time | That every display mode uses the same cache or GPU mechanism. |
| Picking, edit IDs and bounds | Small-selection cost, identity through clone/layer changes, representation mapping | That instancing solves hit testing or buffer index equals persistent ID. |
| Renderer population/transport and source-state restoration | Translation/IR timing, exact consumer data, cancellation and cleanup | That viewport instancing replaces renderer integration. |
| Packaging and runtime loading | Built-versus-loaded IDs, SDK/toolset/runtime DLLs, generated script integrity | That an installer/version string proves the tested binary/script was loaded. |

Return E01 first and nominate **one** next experiment branch. If a recommended improvement is already implemented and correct, mark the decision satisfied rather than reimplement it. For each disagreement with this report, attach stronger source evidence or a discriminating run, not another architectural opinion. Agreement between models is not independent verification.

## 13. Bounded reconciliation with the uploaded context snapshot

This section alone uses detailed supplied project orientation. **Evidence label: historical project-test report or user observation**, not verified current source.

The snapshot says the candidate is 0.62 and already has native preparation improvements, narrow joined clustering workers, coalesced redraw requests, prepared proxy batches and held-input reuse. It says full-mesh display remains different, added proxy payload has 16 MiB/cache and 64 MiB/process caps, and old generations can coexist until GC. It explicitly says retained Nitrous instances and asynchronous editing have not shipped. [Uploaded `REFERENCE - Project Context.txt`, lines 11–33]

Therefore earlier advice to “add batching/preparation/parallelism” may be partly obsolete. The correct next question is where the **post-change** critical path and memory crossover lie, including fallback and full-mesh behavior. This report does not certify those implementations or assume they are missing.

The snapshot's original scene distinguishes 52,143 generated placements from 6,284 displayed pyramid proxies and 37,704 displayed triangles. Its 88.10→30.16 ms navigation-step comparison is not completed-frame FPS. The reported 23→150 FPS synthetic comparison also involved an older-loaded-package mismatch and remains an uncontrolled observation. Do not assign the original scene's44-batch figure to that different demo. [Same supplied file, lines 35–44]

These reports justify investigating the new baseline, not demanding a rewrite of a path that may already be sufficient. The claimed Max 2026 build/native tests and a 2026-format file reopened in 2027 remain short of Max 2026 application qualification. [Same supplied file, lines 14 and 43]

## 14. Unresolved research and qualification questions

1. **Exact Max 2027 SDK/toolchain contract:** the conceptual requirements endpoint was inaccessible during this pass. Public APIs and release foundations were verified; exact build-tool/runtime details need the installed SDK and sample project. Do not derive all details from the vendor blog with a known support-date error.
2. **Hybrid retained-display lifecycle:** public API capability is established, but exact adapter, display ownership, hit testing and device recreation in this plugin need a minimal 2026/2027 host prototype. No supported zero-copy bridge to CUDA/OpenCL/DirectCompute was verified.
3. **Renderer integration contracts:** the Chaos V-Ray SDK/AppSDK pages opened during research did not yield readable implementation content. tyFlow documents separate interfaces, but that is not a full renderer SDK contract. A public supported Corona instance interface, appropriate access terms, motion samples and IR update rules remain unverified. Keep existing correct transport until these are resolved.
4. **Current project bottleneck and output contract:** no new source/runtime evidence here. E01 must establish them. Proposed numerical tolerances or different distribution modes require explicit product approval.
5. **Tool/driver attachment in actual Max:** vendor documentation supports profiling mechanisms, not every injection/attachment combination with Max and all installed renderers. Validate locally; use ETW/CPU traces if intrusive GPU capture fails.
6. **Deployment redistribution:** no new third-party runtime is selected. Before adopting one, verify that exact version's license/redistributables, DLL coexistence and target-machine support; no blanket licensing or compatibility conclusion is made here.

## Conclusion

The evidence supports a **measured hybrid strategy**: keep the simplest correct path, remove unnecessary work, prepare reused geometry carefully, use bounded numerical concurrency where it earns a net gain, and compare retained/shared viewport data only against a measured drawing or memory problem. Defer GPU compute and asynchronous infrastructure until their specific gates pass.

The best next action is **E01 on the verified current build**, followed by one selected E02/E03 branch. A result that says “the current batched path meets our target; keep it” is a successful engineering outcome.


## Compact source references

Exact sections, publication/access dates, versions and qualifications are in `source_ledger.csv` and `Sources.md`. All sources were accessed 1 October 2026.

- <a id="S01"></a> **S01:** [Autodesk Thread Safety](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/best_practices/thread_safety.html) — 3ds Max SDK 2026.
- <a id="S02"></a> **S02:** [Autodesk Deformer reference](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_deformer.html) — 3ds Max SDK 2027.
- <a id="S03"></a> **S03:** [Autodesk About RenderItem](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/3ds_max_sdk_features/viewports_and_graphics_windows/nitrous/about_renderitem.html) — 3ds Max SDK 2026.
- <a id="S04"></a> **S04:** [Autodesk ViewportInstancing namespace 2026](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/namespace_max_s_d_k_1_1_graphics_1_1_viewport_instancing.html) — 3ds Max SDK 2026.
- <a id="S05"></a> **S05:** [Autodesk ViewportInstancing namespace 2027](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/namespace_max_s_d_k_1_1_graphics_1_1_viewport_instancing.html) — 3ds Max SDK 2027.
- <a id="S06"></a> **S06:** [Autodesk InstanceData 2027](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/struct_max_s_d_k_1_1_graphics_1_1_viewport_instancing_1_1_instance_data.html) — 3ds Max SDK 2027.
- <a id="S07"></a> **S07:** [Autodesk SDK Requirements](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html) — 3ds Max SDK 2026.
- <a id="S08"></a> **S08:** [Autodesk What is New in 3ds Max 2027](https://help.autodesk.com/view/3DSMAX/2027/ENU/?guid=GUID-7CC2F041-F797-4DB9-B2F9-326AAB994F37) — 3ds Max 2027.
- <a id="S09"></a> **S09:** [Autodesk Developer Blog: 2027 SDK with VS 2026](https://blog.autodesk.io/setting-up-3ds-max-2027-sdk-development-with-visual-studio-2026/) — 3ds Max SDK 2027; vendor blog.
- <a id="S10"></a> **S10:** [Microsoft .NET releases and support](https://learn.microsoft.com/en-us/dotnet/core/releases-and-support) — .NET 8/9/10 support status.
- <a id="S11"></a> **S11:** [Microsoft Visual Studio CPU Usage](https://learn.microsoft.com/en-us/visualstudio/profiling/cpu-usage?view=visualstudio) — Visual Studio current online docs; VS 2022 covered.
- <a id="S12"></a> **S12:** [Microsoft diagnostics command-line profiling](https://learn.microsoft.com/en-us/visualstudio/profiling/profile-apps-from-command-line?view=visualstudio) — Visual Studio Diagnostics CLI.
- <a id="S13"></a> **S13:** [Microsoft Profiling DirectX applications](https://learn.microsoft.com/en-us/windows/win32/direct2d/profiling-directx-applications) — Windows ETW / DirectX profiling.
- <a id="S14"></a> **S14:** [Intel PresentMon console documentation](https://github.com/GameTechDev/PresentMon/blob/main/README-ConsoleApplication.md) — PresentMon main branch observed 2026-10-01.
- <a id="S15"></a> **S15:** [NVIDIA Nsight Systems User Guide](https://docs.nvidia.com/nsight-systems/UserGuide/index.html) — live documentation observed 2026-10-01.
- <a id="S16"></a> **S16:** [AMD Radeon GPU Profiler manual](https://gpuopen.com/manuals/rgp_manual/) — RGP 2.7 documentation.
- <a id="S17"></a> **S17:** [NVIDIA CUDA C++ Best Practices](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html) — live guide identifies release 13.4.
- <a id="S18"></a> **S18:** [PBRT fourth edition: Alias Method](https://pbr-book.org/4ed/Sampling_Algorithms/The_Alias_Method) — PBRT 4e.
- <a id="S19"></a> **S19:** [PBRT fourth edition: Rejection Method](https://pbr-book.org/4ed/Sampling_Algorithms/The_Rejection_Method) — PBRT 4e.
- <a id="S20"></a> **S20:** [PBRT fourth edition: BVHs](https://pbr-book.org/4ed/Primitives_and_Intersection_Acceleration/Bounding_Volume_Hierarchies) — PBRT 4e ray acceleration.
- <a id="S21"></a> **S21:** [CGAL AABB Tree manual](https://doc.cgal.org/latest/AABB_tree/index.html) — CGAL 6.2.1 served.
- <a id="S22"></a> **S22:** [CGAL Spatial Searching manual](https://doc.cgal.org/latest/Spatial_searching/index.html) — CGAL 6.2.1 served.
- <a id="S23"></a> **S23:** [Robert Bridson: Fast Poisson Disk Sampling in Arbitrary Dimensions](https://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph07-poissondisk.pdf) — SIGGRAPH 2007 sketch.
- <a id="S24"></a> **S24:** [Jonathan Shewchuk: robust predicates](https://www.cs.cmu.edu/~quake/robust.html) — foundational robust orientation/incircle predicates.
- <a id="S25"></a> **S25:** [D E Shaw Research Random123](https://github.com/DEShawResearch/random123) — public repository; paperSC11.
- <a id="S26"></a> **S26:** [PBRT Applying Transformations](https://pbr-book.org/4ed/Geometry_and_Transformations/Applying_Transformations) — PBRT 4e.
- <a id="S27"></a> **S27:** [Microsoft /fp floating-point behavior](https://learn.microsoft.com/en-us/cpp/build/reference/fp-specify-floating-point-behavior?view=msvc-170) — MSVC documentation; VS 2022 differences noted.
- <a id="S28"></a> **S28:** [NVIDIA Floating-Point Computation](https://docs.nvidia.com/cuda/cuda-programming-guide/05-appendices/mathematical-functions.html) — live CUDA Programming Guide.
- <a id="S29"></a> **S29:** [oneAPI task_arena specification](https://oneapi-spec.uxlfoundation.org/specifications/oneapi/v1.3-rev-1/elements/onetbb/source/task_scheduler/task_arena/task_arena_cls) — oneAPI 1.3-rev-1 / oneTBB API.
- <a id="S30"></a> **S30:** [Autodesk public 3dsmax-usd build instructions](https://github.com/Autodesk/3dsmax-usd/blob/dev/doc/build.md) — public dev branch observed 2026-10-01.
- <a id="S31"></a> **S31:** [Microsoft CRT across DLL boundaries](https://learn.microsoft.com/en-us/cpp/c-runtime-library/potential-errors-passing-crt-objects-across-dll-boundaries?view=msvc-170) — MSVC/Universal CRT.
- <a id="S32"></a> **S32:** [Khronos OpenCL specification](https://registry.khronos.org/OpenCL/specs/unified/html/OpenCL_API.html) — unified live specification includes3.0/3.1.
- <a id="S33"></a> **S33:** [Microsoft D3D11 Compute Shader overview](https://learn.microsoft.com/en-us/windows/win32/direct3d11/direct3d-11-advanced-stages-compute-shader) — D3D11 Shader Model 5.
- <a id="S34"></a> **S34:** [Codeplay oneAPI for NVIDIA installation](https://developer.codeplay.com/products/oneapi/nvidia/2025.2.0/guides/get-started-guide-nvidia-2.html) — oneAPI for NVIDIA 2025.2.0.
- <a id="S35"></a> **S35:** [Chaos Scatter performance and troubleshooting](https://support.chaos.com/hc/en-us/articles/4953457092625-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Performance-and-Troubleshooting) — Chaos Scatter/Corona support article.
- <a id="S36"></a> **S36:** [tyFlow tyCache documentation](https://docs.tyflow.com/tyflow_objects/tyCache/) — unversioned public tyCache docs.
- <a id="S37"></a> **S37:** [tyFlow system requirements](https://docs.tyflow.com/download/system_requirements/) — unversioned public requirements.
- <a id="S38"></a> **S38:** [tyFlow performance FAQ](https://docs.tyflow.com/faq/performance/) — unversioned FAQ.
- <a id="S39"></a> **S39:** [tyFlow tyWetmap modifier](https://docs.tyflow.com/tyflow_modifiers/tyWetmap/) — unversioned public operator doc.
- <a id="S40"></a> **S40:** [tyFlow Interfaces](https://docs.tyflow.com/tyflow_objects/tyFlow/interfaces/) — unversioned public operator doc.
- <a id="S41"></a> **S41:** [tyFlow Network Rendering](https://docs.tyflow.com/license/rendering/) — unversioned public product documentation.
- <a id="S42"></a> **S42:** [tyFlow GPU rollout](https://docs.tyflow.com/tyflow_objects/tyFlow/gpu/) — unversioned public operator doc.
