# Cyrus Scatter: external performance research

**My conclusion is to preserve the gains already achieved, measure the remaining bottleneck in the current build, and make retained viewport rendering, additional threading, and GPU computation earn their complexity through controlled experiments.**

The updated context changes the priorities. It reports that native boundary preparation, narrowly bounded parallel work, prepared proxy batches, and held-input reuse already exist. Those should no longer appear on a roadmap as entirely missing features. It also says full-mesh display follows a different path and that retained Nitrous instancing and asynchronous editing have not shipped. These are statements from your supplied snapshot, not newly verified source observations. REFERENCE - Project Context

The research deliverables are ready:

**:chatgpt-content-reference{index="26"}[Complete engineering research report](sandbox:/mnt/data/Cyrus_External_Engineering_Research.md)**  
**Cyrus_External_Research_2026-10-01.zip[Full package: report, source/claim ledgers, decision ledger, experiments, and Codex handoff](sandbox:/mnt/data/Cyrus_External_Research_2026-10-01.zip)**  
**:chatgpt-content-reference{index="28"}[Three architecture-discriminating experiments](sandbox:/mnt/data/cyrus_independent_research/Three_Experiments.md)**

The package includes 42 source records, 41 claim records, six shortlisted decisions, and three experiment specifications. Research is dated **1 October 2026**. This was an external investigation—not a fresh repository audit or Max benchmark. Because the earlier discussion and internal context were already visible, it was not a blind independent review.

## 1. The next performance target must come from the complete artist operation

The most consequential question is no longer simply:

> “Can the scatter calculation become faster?”

It is:

> **“After the recent optimizations, what still determines how long the artist waits?”**

I would measure five workloads independently:

| Workflow | Primary measurement | What the result should distinguish |
|---|---|---|
| **Navigate without editing** | Presented frame intervals and navigation latency | Display preparation, submission, GPU execution, and unrelated scene costs. |
| **Change a parameter or edit instances** | Input to the latest correct visible result | Scheduling, host evaluation, calculation, conversion, and publication. |
| **Rebuild the complete scatter** | Request to committed exact output | Preparation costs versus numerical work and output handling. |
| **Animate or scrub time** | Correct frame evaluation and presentation | Reusable data versus genuinely time-dependent work. |
| **Start or update rendering** | Request to renderer-ready scene | Scatter evaluation versus transport, source preparation, and renderer work. |

These are proposed measurement boundaries, not claims that every category is currently slow.

### Why a spectacular kernel result can disappoint

For an illustrative serial operation, suppose one numerical stage occupies **20%** of the total time. Making that stage **10 times faster** produces:

\[
\text{Overall speedup}
=
\frac{1}{0.8+0.2/10}
\approx 1.22
\]

Even eliminating that stage entirely would cap the improvement at **1.25 times**. This is an application of Amdahl’s law—not a Cyrus measurement. NVIDIA’s performance guidance explicitly emphasizes both whole-application limits and data-transfer costs. [NVIDIA Docs](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html)

The same caution applies to viewport measurements. Your snapshot distinguishes scripted navigation-step timing from completed-frame FPS, and identifies the approximately **23-to-150 FPS** demo result as an uncontrolled observation involving an older loaded package. It is encouraging evidence, but not a controlled product-wide multiplier. REFERENCE - Project Context

### Use complementary tools rather than one FPS overlay

Visual Studio’s CPU Usage profiler supports native C++ sampling and attaching to an existing process. It can identify expensive stacks and modules, but does not by itself establish GPU completion or input-to-visible latency. [Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/profiling/cpu-usage?view=visualstudio)

Windows ETW tools and PresentMon provide complementary scheduling and presentation evidence. They still need correlation with the plugin’s own request, generation, and commit markers. [Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/direct2d/profiling-directx-applications)

A specific compatibility trap: **AMD Radeon GPU Profiler does not support Direct3D 11 profiling.** Identify the active graphics backend before choosing the GPU tool. [AMD GPUOpen](https://gpuopen.com/manuals/rgp_manual/)

**My recommendation:** add a small set of timestamps, counters, and revision identifiers before another major subsystem. Record why work ran, not just how long it took.

Also, do not add CPU-thread time, GPU time, and waiting time together indiscriminately. Where work overlaps, the relevant measure is the actual dependency path from the artist’s action to the correct displayed result.

## 2. Better calculations often mean preparing less and asking cheaper questions

The mathematical research supports several useful techniques—but none is universally preferable.

The following are **conditional engineering choices**, not assertions about missing Cyrus functionality:

| Workload | Credible optimization | Where the simpler implementation can win |
|---|---|---|
| Many surface closest-point or ray queries | Reuse a suitable BVH/AABB hierarchy | Few queries, tiny meshes, or geometry changing so often that preparation dominates. |
| Repeated nearby-instance checks | Uniform grid or spatial hash with an appropriate neighborhood | Strongly varying radii, highly skewed occupancy, or very small populations. |
| Many draws from unchanged source weights | Prepared cumulative distribution or alias table | Few sources, few draws, or frequently changing weights. |
| Repeated boundary tests | Prepared planes, bounds, edges, and appropriate query acceleration | Tiny boundaries or edits that invalidate preparation before it is reused. |

BVH and AABB references establish useful acceleration mechanisms, but their construction and update costs must be included. A point-search tree is also not a substitute for exact nearest-triangle queries. [pbr-book.org](https://pbr-book.org/4ed/Primitives_and_Intersection_Acceleration/Bounding_Volume_Hierarchies)

For weighted selection, the alias method offers constant-time draws after preprocessing; that does not mean it beats a short source-list scan in a real complete update. [pbr-book.org](https://pbr-book.org/4ed/Sampling_Algorithms/The_Alias_Method)

### The right crossover is per valid input revision

For a proposed spatial index, let:

- \(B\) be its additional preparation cost;
- \(q_s\) be the scan cost per query;
- \(q_i\) be the indexed cost per query.

When \(q_s>q_i\), it becomes worthwhile only after:

\[
Q > \frac{B}{q_s-q_i}
\]

That is a decision model, not a threshold to hard-code without measurement.

An index that is valuable for a static terrain may be unattractive for a small deforming surface. Likewise, caching a prepared boundary is useful only when the invalidation policy notices every relevant change.

### Preserve the meaning of the result

This is the most important constraint on “better algorithms.”

**A statistically equivalent sampler is not necessarily a scene-compatible optimization.** Replacing one source-selection method with another can preserve probabilities while assigning different source IDs to the same seeded candidates. That distinction matters when artists have edited particular instances.

Similarly, Bridson’s Poisson-disk algorithm is a useful fixed-radius sampling method, but adopting it is not automatically an equivalent acceleration of an existing requested-count, ordered-generation workflow. Count, order, distribution, and identity may change. [Computer Science at UBC](https://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph07-poissondisk.pdf)

I would separate two classes of change:

**Equivalent optimization:** preserve the approved count, ordering, identities, geometric decisions, and numerical contract.

**New generation behavior:** explicitly version the algorithm or expose a new mode, with a migration policy for existing scenes.

The report also examines robust predicates, floating-point modes, deterministic random streams, and transformed geometry. Two particularly important safeguards are that normals require appropriate inverse-transpose handling, and compiler reassociation/FMA choices can affect boundary decisions. [pbr-book.org](https://pbr-book.org/4ed/Geometry_and_Transformations/Applying_Transformations)

My mathematical inference for the local tests is broader: **nonuniform scaling can change both relative surface areas and the closest-point metric.** An object-space cache must not silently substitute a different geometric problem for a world-space contract.

## 3. Keep CPU batching unless another viewport architecture proves better

**The existence of a modern GPU interface is not sufficient reason to replace a working display path.**

There are three architectures worth distinguishing:

| Architecture | What it retains | Main tradeoff |
|---|---|---|
| **Prepared CPU batches** | Prepared geometry submitted in larger groups | Relatively simple, but submission remains part of redraw work. |
| **Retained expanded geometry** | Combined/chunked geometry in viewport buffers | Can avoid repeated submission preparation, but still duplicates geometry across instances. |
| **Retained shared geometry with GPU instances** | Source geometry plus per-instance data | Can reduce duplication, but introduces grouping, update, appearance, selection, and resource-lifetime requirements. |

This is an engineering comparison. It does not identify the fastest option for your current scenes.

### Autodesk’s interface is real—and has meaningful restrictions

Viewport instancing is documented for both target SDKs. Autodesk explicitly distinguishes it from native scene-node instancing and final-render instancing. [Autodesk Help](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/namespace_max_s_d_k_1_1_graphics_1_1_viewport_instancing.html)

The documented update mode can reuse existing buffers, but it cannot arbitrarily change instance count, introduce previously absent instance data, or change the source geometry’s vertex count. High Quality viewports also have specified stream requirements, including streams that may be required even when a feature is not visibly used. [Autodesk Help](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/namespace_max_s_d_k_1_1_graphics_1_1_viewport_instancing.html)

The instance-data contract has additional material-sorting and mapping details. In particular, its restricted per-instance UVW capability should not be confused with arbitrary per-instance mesh mapping. [Autodesk Help](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/struct_max_s_d_k_1_1_graphics_1_1_viewport_instancing_1_1_instance_data.html)

Those constraints belong in the prototype’s acceptance tests—not in a later cleanup phase.

### What tyFlow demonstrates—and what it does not

tyCache documents Nitrous GPU instancing and also documents circumstances where modifier or mapping behavior changes the available representation. It is a useful production example of **capability-dependent display paths**.

It does not disclose enough to infer its private scheduler, exact memory structures, or the speed Cyrus would achieve by using the same public mechanism. [tyFlow Documentation](https://docs.tyflow.com/tyflow_objects/tyCache/)

### Memory scaling may be as important as FPS

Your context reports additional prepared-proxy limits of **16 MiB per cache and 64 MiB process-wide**, with a fallback that preserves the displayed population. It also says old cache generations can coexist before garbage collection. These are scoped payload limits, not total Max memory limits. REFERENCE - Project Context

That creates a useful test question:

> What happens to latency and total memory just below and just above the real cache limits?

A fallback may preserve correctness but become slower. That is not necessarily a defect; it needs to be characterized.

For the **32 GB qualification target**, I would measure whole-process memory, retained generations, source diversity, renderer load, and GPU allocations—not merely whether one allocation stays below a cap.

**My recommendation:** compare the three viewport representations using frozen, identical placements. Keep CPU batching wherever it meets the target. Introduce retained/shared instancing only for a demonstrated display or memory benefit.

## 4. Use bounded numerical concurrency before building an asynchronous engine

Autodesk documents reference and node evaluation as single-threaded. Specific rendering and deformation callbacks have their own thread-safety requirements, so neither “all Max calls are safe behind a mutex” nor “nothing in Max can be threaded” is a correct general rule. [Autodesk Help](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/best_practices/thread_safety.html)

Your snapshot already describes a deliberately narrow joined-worker path operating on owned numeric ranges. It does not describe a persistent executor or asynchronous publication system. REFERENCE - Project Context

I would not broaden that simply to increase CPU utilization.

### The progression I would use

Start with optimized serial work and event coalescing. Add bounded joined ranges where independent numerical work is demonstrably expensive. Consider a persistent executor only when worker startup is a material cost. Consider asynchronous publication only when necessary exact work still prevents acceptable interaction.

oneTBB provides mechanisms for bounded participation, but using it does not remove host constraints or resolve dependency coexistence automatically. Autodesk’s SDK documentation also identifies a specific TBB runtime for Max 2026; an unrelated component’s dependency table is not an authoritative inventory for the entire Max process. [oneAPI Specification](https://oneapi-spec.uxlfoundation.org/specifications/oneapi/v1.3-rev-1/elements/onetbb/source/task_scheduler/task_arena/task_arena_cls)

### Asynchronous work needs more than a generation counter

My proposed minimum design is:

```text
Permitted host context:
    Capture owned input and request identity.

Worker:
    Compute only on owned data.
    Support bounded cancellation.

Permitted host completion:
    Verify scene, owner, revision, time, and mode.
    Discard obsolete results.
    Commit one complete result.
```

This is a design proposal, not verified Max API code.

The local implementation must address Undo/Redo, node deletion, scene reset/load, shutdown, Manual mode, and rendering. A result can have the correct numeric revision but belong to a deleted object or an earlier scene.

Also, **keeping an old preview visible is not permission to render stale data**. I would require the renderer path to request an exact revision/time or follow an explicit failure policy.

The strongest argument against asynchronous architecture is that it may make the interface look active while leaving the latest correct result just as late—or later. The experiment should measure both.

## 5. Defer GPU computation until one workload passes a transfer-inclusive test

**GPU viewport drawing and GPU scatter calculation should remain separate decisions.**

NVIDIA’s guidance emphasizes minimizing host/device transfers and evaluating the complete application rather than kernel timing alone. [NVIDIA Docs](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html)

For a non-overlapped computation path, the relevant cost model is:

```text
Host extraction
+ preparation/packing
+ allocation where needed
+ upload
+ dispatch and computation
+ synchronization
+ required readback
+ host publication
```

Where stages overlap or data persists, the local engineer should measure that actual dependency graph—not automatically sum all timers or assume transfers disappear.

### Choose a backend only after choosing the workload

CUDA is a candidate for an explicitly NVIDIA-targeted optional path. OpenCL and DirectCompute are plausible alternatives where the required device capabilities and deployment fit. OpenCL version labels alone do not guarantee every needed feature; DirectCompute also has capability distinctions, including optional double-precision support in the documented D3D11 path. [Khronos Registry](https://registry.khronos.org/OpenCL/specs/3.0-unified/html/OpenCL_API.html)

SYCL should not be rejected using an outdated “no Windows support” assertion: Codeplay’s versioned NVIDIA guide documents Windows support. That still does not establish a suitable Max deployment or justify introducing another toolchain. [developer.codeplay.com](https://developer.codeplay.com/products/oneapi/nvidia/2025.2.0/guides/get-started-guide-nvidia-2.html)

I found a relevant concrete production mechanism: **tyWetmap documents optional CUDA acceleration for BVH proximity queries**. That makes a large independent geometry-query batch a credible experiment—not proof that Cyrus needs CUDA or would benefit from it. [tyFlow Documentation](https://docs.tyflow.com/tyflow_modifiers/tyWetmap/)

### The first GPU experiment should be capable of rejecting the idea cheaply

Before porting a real kernel, measure an optimistic floor for the transfers, synchronization, and required host-side handling.

If even that floor cannot meet the complete-operation target, stop.

If it passes, implement **one actual eligible kernel** and compare it against the improved CPU baseline, including renderer contention, memory pressure, unsupported devices, and fallback behavior.

Passing the floor test is not a GPU success. It only means the proposal has not yet been rejected.

## 6. Ranked decisions

These ranks describe **investigation priority**, not six features that must all be built.

| Priority | Decision | My position |
|---|---|---|
| **1** | Precise invalidation, event coalescing, and reuse | Broadly applicable now as an audit; add or change only what the current source and traces justify. |
| **2** | Prepared exact geometry queries and data-local numerical work | Investigate measured hotspots, including preparation and memory costs. |
| **3** | Retained viewport geometry/shared GPU instances | Compare against current CPU batches after identifying a display or memory problem. |
| **4** | Additional bounded numerical parallelism | Extend only where independence and complete-update benefit are demonstrated. |
| **5** | Asynchronous snapshot/compute/commit | Defer unless simpler synchronous behavior fails the interaction target. |
| **6** | Optional GPU computation | Defer until one transfer-inclusive workload shows a substantial net benefit. |

The ledgers record the simpler alternative, strongest objection, preconditions, failure modes, confidence, reversal evidence, and stop conditions for each.

**Do not build yet:** a complete native rewrite, a general-purpose job system, a multi-backend GPU abstraction, blanket fast-math changes, a replacement sampler that silently changes saved layouts, or a new renderer transport without verified renderer contracts and a measured need.

## 7. The three experiments I would give the local engineer

The complete specifications include inputs, controls, correctness oracles, raw output formats, and stop conditions.

### E01 — Identify the remaining critical path

Use the **verified current loaded DLL and script**, not only the installer filename.

Exercise navigation, display-only changes, density changes, source changes, local edits, topology changes, and render preparation across small, production, and stress scenes.

Record request, extraction, preparation, numerical work, conversion, commit, and presentation boundaries. Pair timings with cache-hit reasons, invalidation reasons, counts, and output hashes.

**Correctness oracle:** compare against a fresh exact rebuild and check identities, dependencies, Manual behavior, and scene-lifetime changes.

**Decision:**  
If display-only actions already avoid generation, reject a generation-cache rewrite as their fix. If scheduling dominates, try coalescing before async. If host extraction dominates, numerical GPU offload is not the immediate answer.

### E02 — Compare display architectures without changing quality

Freeze a correct placement result and compare current CPU batches, retained expanded geometry, and shared GPU instances.

Keep visible population, geometry, transforms, colors, viewport size, and style equivalent. Vary source diversity, detail, materials, selected instances, changed counts, deforming sources, multiple viewports, and memory-cap crossings.

**Correctness oracle:** canonical geometry/channel comparisons, bounds, picking, and visual captures—not FPS alone.

**Decision:**  
Adopt the smallest representation that produces a meaningful improvement without losing appearance, selection, or lifetime correctness. Keeping the current path is a valid outcome.

As a **proposed—not measured—gate**, I suggest investigating adoption around a 20% reduction in the relevant p95 navigation interval, or a 30% reduction in display working set without a meaningful response regression. Agree on the margins before testing.

### E03 — Compare better serial code, bounded CPU workers, and optional GPU work

Select one expensive owned-data stage from E01.

First compare the current/reference algorithm with an exact prepared alternative. Then test bounded joined work. Only afterward test the GPU transfer floor and, if justified, one real kernel.

Include preparation, worker startup/join, transfers, synchronization, publication, peak memory, and full host-visible update time.

**Correctness oracle:** agreed counts, ordered identities, tie behavior, finite values, and an independent geometry check where practical.

**Decision:**  
Stop when a simpler option meets the target. Reject any candidate that silently weakens the output contract. For a shipped GPU path, I propose a higher benefit hurdle—roughly 30% improvement in the complete eligible operation—because its support burden is larger.

These percentages are decision proposals, not universal engineering constants or predicted Cyrus gains.

## 8. What qualification must establish beyond high FPS

I would make release qualification answer four questions.

**Does it preserve the scene?**  
Test save/load, clone, merge, Undo/Redo, Manual and real-time behavior, deleted inputs, stale results, and shutdown.

**Does it preserve the intended result?**  
Test ordered outputs, numerical boundaries, holes, degenerate geometry, nonuniform/mirrored transforms, source changes, and serial/parallel parity under the approved contract.

**Does it remain usable under realistic resource pressure?**  
Test a 32 GB workstation, many controllers and unique sources, repeated edits, cache-limit crossings, long sessions, and renderer contention.

**Does it work in the actual claimed hosts and renderers?**  
Your snapshot explicitly says Max 2026 application testing has not occurred. Build success and reopening a downgraded scene in Max 2027 do not qualify Max 2026 runtime support. REFERENCE - Project Context REFERENCE - Project Context

Renderer testing also needs its own visibility policy. Chaos documents that camera clipping can affect reflections and shadows, and that keeping multiple LOD assets resident can increase memory. Viewport optimizations therefore cannot automatically be applied to final-render population or memory assumptions. [Chaos Help Center](https://support.chaos.com/hc/en-us/articles/4953457092625-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Performance-and-Troubleshooting)

For comparisons, use paired repeated runs, warmups, order reversal or randomization, raw samples, and separate cold/warm results. Report variability across independent captures; do not hide small-scene regressions inside a large-scene average.

## Final recommendation

**Start with E01 on the verified current build. Then choose one E02 or E03 branch—not a combined renderer, scheduler, and GPU rewrite.**

The largest unresolved issues are the current project’s measured critical path, the exact installed Max 2027 build contract, hybrid retained-display lifecycle behavior, and complete V-Ray/Corona integration contracts. Public viewport APIs were verified, but they do not establish renderer interoperability or a supported zero-copy compute path. The renderer SDK pages examined did not provide enough readable implementation detail to close those questions.

The updated context suggests that several relatively simple optimizations have already produced worthwhile gains. The next step should preserve that discipline:

> **Remove unnecessary work first. Make the remaining work cheaper second. Add a new subsystem only when the complete artist workflow—not an isolated kernel or attractive demo—proves that it is worth maintaining.**