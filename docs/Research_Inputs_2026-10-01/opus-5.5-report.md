# Cyrus Scatter: Independent External Engineering Research (Prompt 02)

Research pass executed 1 October 2026. Independent of the codebase investigation (Prompt 01): no repository, no running 3ds Max, and the internal "Project Context" file was deliberately withheld from this pass, as START HERE requires. Only the owner background inside Prompt 02 was used.

Companion files: `claim_source_ledger.csv` (115 claims, stable IDs `CL-<track>-nn`) and `decision_experiment_ledger.csv` (37 options/experiments, IDs `DX-<track>-nn`). Track codes: MQ measurement and qualification, AL algorithms, CC concurrency, VP viewport, GP GPU compute.

Evidence labels used throughout (shared with the Codex report): direct project-source observation; local measured run; historical project-test report; primary external documentation; user observation; inference; unknown. This pass has no basis for the first three. Every project-specific statement here is therefore a hypothesis with a test attached.

**Capability limits of this pass.** Executed by ClickUp Brain with live web access (not GPT-6 Pro), split across five parallel research agents, one per track, then merged by the parent. The parent re-opened three load-bearing Autodesk pages to verify them (SDK version macros, `IMainThreadTaskManager`, `InstanceDisplayGeometry`); the rest of the ledger is agent-verified only and is marked that way in the `parent_check` column. No standalone numeric experiments were run. One model's second pass is not independent verification.

---

## 1. Decision brief

**Verdict: don't add GPU compute, don't add a persistent thread pool, and don't trust FPS readouts yet. The next move is a measurement harness, then one like-for-like viewport experiment against Autodesk's documented viewport-instancing API, with the current CPU-batched path kept as a permanent fallback.**

### The five most consequential findings

1. **Max's own FPS number can't settle any performance claim.** Autodesk documents that `viewport.GetFPS()` is stale unless Show Statistics is on, and that with Adaptive Degradation enabled it reports the *goal* FPS, not actual FPS [CL-MQ-03, CL-MQ-02]. A 23 to 150 FPS observation can't be interpreted without the degradation state, display mode, viewport size and displayed counts. The fix is cheap: present-to-present timing from PresentMon [CL-MQ-15], ETW/WPR traces [CL-MQ-07], and plugin markers. PIX is the wrong primary GPU timer here, because Nitrous is documented as DirectX 11 [CL-MQ-04, CL-GP-01] and PIX's D3D11 timing captures show "almost no GPU work" [CL-MQ-08]. On NVIDIA, use Nsight Systems, which documents DX11 [CL-MQ-13].

2. **Autodesk ships a documented, viewport-only GPU instancing path for both 2026 and 2027. It's the most credible next viewport step, with constraints that could kill it.** `MaxSDK::Graphics::ViewportInstancing::InstanceDisplayGeometry` with `InstanceData`, driven from `IObjectDisplay2::UpdatePerNodeItems` via `GenerateInstances` [CL-VP-02, CL-VP-04, CL-VP-05, CL-VP-07]. It keeps one source mesh plus per-instance matrices, colors, viewport materials and limited UVW overrides. The constraints: `UpdateInstanceData` can't change instance count, source vertex count or data layout [CL-VP-07]. Per-instance viewport materials are creation-only, and Max reorders instances by material [CL-VP-08]. High Quality mode needs full position, normal, UV, tangent and bitangent streams [CL-VP-09]. `CreateInstanceData` can fail when the instance data doesn't fit in GPU memory [CL-VP-18]. And nothing documented gives you per-instance picking [CL-VP-11]. This is "investigate", not "adopt".

3. **3ds Max isn't thread-safe, and that caps the concurrency design.** Reference and node evaluation are single-threaded in both 2026 and 2027 [CL-CC-01, CL-CC-02]. MAXScript and pymxs are main-thread only [CL-CC-03], and Animatable create/delete and Hold operations belong on the main thread [CL-CC-05]. The safe ceiling is: snapshot on the main thread, then run a bounded synchronous fork/join over owned arrays, then publish on the main thread. For asynchronous publication there is a real documented API, `IMainThreadTaskManager::PostTask(MainThreadTask*)` [CL-CC-08, CL-CC-09]. Its pump cadence and shutdown behavior aren't documented, so async work stays deferred until lifecycle stress tests pass. Max itself uses TBB 2021.12 in both versions [CL-CC-11, CL-CC-12]. Shipping a different TBB/oneTBB runtime into the process is a deployment risk, and two pools can oversubscribe each other [CL-CC-16, CL-CC-17].

4. **GPU compute should be rejected at this stage, and there's a cheap test that would reverse that.** No Autodesk-documented compute-dispatch or Nitrous buffer-sharing contract was found [CL-GP-03]. Every transfer, sync and readback is real cost [CL-GP-05, CL-GP-06]. Poisson/spacing acceptance is order-dependent, while GPU atomics give atomicity but no stable order [CL-GP-17]. The renderer ecosystem also competes for the device (V-Ray GPU/OptiX, Vantage) [CL-GP-20, CL-GP-21]. Amdahl decides it: if the candidate kernel is under 20% of edit-to-visible latency, even an infinitely fast GPU kernel tops out at 1.25x end to end. If a probe is ever justified, the plausible first one is a private-buffer DirectCompute/D3D11 kernel [CL-GP-15], not CUDA, OpenCL, SYCL or Vulkan.

5. **Correctness contracts need writing down before any optimization changes numbers.** 2026 (R28, API 68) and 2027 (R29, API 70) are documented as binary-incompatible. The parent verified this directly [CL-AL-20, CL-MQ-20], so each host needs its own build *and* its own runtime qualification. `/fp:fast`, FMA contraction and thread-count-dependent reductions change last bits, and that can flip triangle selection, containment and spacing decisions [CL-AL-14, CL-AL-15, CL-AL-16]. Schedule-independent output needs keyed counter-based RNG [CL-AL-07] plus deterministic merge order. Viewport culling or LOD must never feed render instance data, because Chaos itself warns its camera clipping can drop reflections and shadows [CL-VP-15].

### Strongest broadly applicable advice
- Build the measurement harness first (DX-MQ-01) and record full run identity (DLL/script path and hash, scene hash, seed, viewport size and style, Adaptive Degradation state, displayed vs generated vs render counts).
- Keep CPU batching as a permanent fallback and baseline (DX-VP-02). Add an explicit representation ladder with budgets (DX-VP-03) and strict viewport/render separation (DX-VP-04).
- Keep serial optimized code as the default (DX-CC-01). Parallelize only owned snapshots, with a work cutoff and a deterministic merge.
- Use separate per-version builds and an ApplicationPlugins bundle with exact `SeriesMin`/`SeriesMax` (DX-MQ-04, DX-AL-09). Use versioned persistence and scripted-plugin migration (DX-MQ-05).

### Largest unknowns
The actual critical-path breakdown for each scenario. Whether the current output contract is bitwise, statistical or tolerance-based. Whether the scripted/native hybrid structure can host `IObjectDisplay2` without breaking bounds, hit-test, selection and invalidation. Whether Corona and V-Ray consume `RenderTimeInstancingInterface` [CL-VP-12, CL-VP-13]. Device-loss and reset behavior for retained Nitrous resources. The exact 2026 native toolchain (the 2026 SDK requirements table couldn't be retrieved) and the .NET 8 vs .NET 10 baseline for the installed 2026 update [CL-MQ-19].

---

## 2. Comparison across tracks (established fact vs conditional advice)

### 2.1 Measurement model (Track A)

**Established:** Nitrous custom render items split `Realize()` (prepare, may run once per frame) from `Display()` (may run multiple times per frame) [CL-MQ-01]. The FPS overlay and `GetFPS` semantics are as described in finding 1. The 2026 command-line viewport options are `-vx11`, `-vxs` (WARP) and `-vx9`, with no DX12 Nitrous option documented [CL-MQ-05], and 2027 removes DX9 [CL-MQ-06]. Autodesk's `StopWatch` uses QPC and documents per-pair overhead [CL-MQ-26]. MAXScript `timeStamp()` is milliseconds since midnight and `timeGetTime()` wraps [CL-MQ-27]; use them only for coarse boundary timing.

**Model (inference):** separate five scenarios: navigation without edits, edit-to-visible, rebuild, animation throughput, and render prep. CPU and GPU intervals overlap, so the critical path is the longest dependent chain plus waits, not `CPU_ms + GPU_ms`. Summarize in frame *time*, never averaged FPS: report median, p95, p99, IQR, raw samples, and cold vs warm. Amdahl bound: `S_max = 1 / ((1-p) + p/k)`. A 10x kernel speedup on 50% of the critical path yields at most 1.82x; on 90% it yields at most 5.26x.

**What each tool proves** (all primary docs, see ledger):

| Tool | Proves | Doesn't prove |
|---|---|---|
| WPR/WPA (ETW) | CPU scheduling, waits, context switches, driver activity | Which scatter stage is slow, unless plugin emits markers |
| PresentMon | Present-to-present pacing, display latency per frame | Why a frame is slow; GPU metrics unreliable under HWS [CL-MQ-15] |
| VS profiler | Native hotspots (sampling: low overhead; instrumentation: exact counts, high overhead) [CL-MQ-09] | GPU execution, artist latency |
| Nsight Systems | Correlated CPU/GPU timeline on NVIDIA, DX11 and DX12 [CL-MQ-13] | Vendor-neutral behavior |
| VTune | CPU/threading/memory; GPU only on supported Intel graphics [CL-MQ-10] | NVIDIA/AMD GPU behavior |
| AMD uProf | AMD CPU microarchitecture on Windows | Windows GPU (listed unavailable) [CL-MQ-12] |
| Tracy | Instrumented CPU zones, locks, D3D11/12 GPU zones [CL-MQ-14] | Anything uninstrumented; adds overhead |
| PIX | D3D12 captures | Native D3D11 timing [CL-MQ-08] |

### 2.2 Algorithms and CPU math (Track B)

Decision rules, not a catalog:

- **Triangle selection:** prefix CDF plus binary search by default. Switch to an alias table only when one fixed distribution is sampled many times before invalidation [CL-AL-05, CL-AL-18]. Switching keeps the distribution but **not** the random-number consumption, sample sequence or instance identity.
- **Uniform point in triangle:** `s=sqrt(u0); b=(1-s, s(1-u1), s*u1)`. Naive barycentrics are biased [CL-AL-04]. Exclude zero-area triangles, and fail explicitly if all are degenerate.
- **Rejection by density/mask:** unbiased, but cost scales with the inverse of the acceptance rate. Thin, sparse or holed regions blow up the tail latency, so log the acceptance rate per layer [CL-AL-06].
- **Spacing:** Bridson grid dart throwing (cell size at most `r/sqrt(d)`, k attempts, O(N)) for a fixed radius in a Euclidean domain [CL-AL-01]. Use a sparse hash rather than a dense grid for large or offset extents. On folded meshes Euclidean spacing â‰  geodesic spacing, and projecting volume samples onto a surface biases blue noise [CL-AL-02]. Sample elimination [CL-AL-03] suits exact-count or progressive modes but changes which candidates survive. Lloyd relaxation moves points and must be an explicit quality mode, never a silent optimization.
- **Index choice:** pick by `T_build + Q*T_query + T_narrow` measured on real meshes. Use a direct loop for small N or few queries, and keep it as the oracle. Use a grid/hash for fixed-radius dynamic points, and a BVH for many triangle closest-point/ray queries against a stable mesh [CL-AL-11, CL-AL-19]. Defer k-d trees. Broadphase may give false positives, never false negatives.
- **Transforms:** normals use the inverse transpose. When `det<0`, flip normal or winding. For singular transforms, use an explicit policy [CL-AL-12].
- **Robustness:** Shewchuk adaptive predicates for near-degenerate orientation and containment signs [CL-AL-13]. They don't fix distances or reductions.
- **Reproducibility contract (proposal, not permission):** bitwise identical output for the same binary, ISA, machine and input. Across builds or devices: same counts and containment, spacing within tolerance, statistical distribution tests. Keep decision-critical code under `/fp:precise`, control contraction explicitly with `/fp:contract` [CL-AL-14, CL-AL-15], and use fixed-order reductions [CL-AL-16].
- **Layout and SIMD:** after algorithmic waste is removed. SoA helps large homogeneous scans, and MSVC auto-vectorization should come before intrinsics [CL-AL-17].

### 2.3 Concurrency in the host (Track C)

| Option | Status | Why |
|---|---|---|
| Serial optimized | **Default now** (DX-CC-01) | Zero lifecycle risk; small workloads usually lose to fork/join overhead |
| Bounded synchronous fork/join over owned snapshot | **Investigate after profiling** (DX-CC-02) | Only shape compatible with single-threaded evaluation [CL-CC-01]; needs cutoff, cap, per-range output, deterministic merge |
| Async snapshotâ†’computeâ†’`PostTask` publish with generation check | **Investigate after profiling** (DX-CC-04, DX-CC-05) | Documented marshal API exists [CL-CC-08]; stale results, Undo/Redo, reset, node deletion, shutdown all must invalidate [CL-CC-10] |
| Persistent executor | **Defer** (DX-CC-03) | DLL unload/scene reset/teardown obligations; startup savings rarely matter at these scales |
| Private oneTBB / OpenMP / PPL pool | **Defer/avoid** (DX-CC-06) | Max bundles TBB 2021.12; mixed pools oversubscribe [CL-CC-16, CL-CC-17, CL-CC-20] |
| Hybrid-core pinning, NUMA tuning | **Defer** (DX-CC-08) | Intel/Microsoft advise letting OS schedule [CL-CC-25, CL-CC-26] |

Renderer contention is a product constraint, not an edge case. Corona exposes "all but N" thread settings for final and interactive renders [CL-CC-23], and V-Ray defaults to all logical threads [CL-CC-24]. Higher CPU utilization can coexist with worse latency through shared cores, memory bandwidth, cache and thermal limits, so judge by wall time and p95/p99, never by utilization.

oneTBB detail if ever used: `parallel_deterministic_reduce` fixes split/join order, but it can still differ from a serial sum [CL-CC-21]. Exceptions are captured, pending work is cancelled, and the exception is rethrown on the caller [CL-CC-22]. Never publish partial output.

### 2.4 Viewport display (Track D)

Three different things that must not be conflated [CL-VP-04, CL-VP-12]:
- **Viewport GPU instances**: `InstanceDisplayGeometry`. One node, many drawn copies, viewport only.
- **Native Max instance nodes**: separate scene nodes with full scene semantics.
- **Renderer instances**: `MaxSDK::RenderTimeInstancing::RenderTimeInstancingInterface`. A renderer that supports it shouldn't call `GetRenderMesh()`, and plugins should still provide an aggregate-mesh fallback [CL-VP-13].

Retained instancing vs expanded per-instance triangles: instancing stores the source once and uploads a matrix per instance. `pMatrices` is preferred over position/orientation/scale [CL-VP-06]. Partial `UpdateInstanceData` suits transform-only edits [CL-VP-20]. Max doesn't own the arrays you pass and copies only colors and viewport materials [CL-VP-19]. Expansion (CPU batching) stays correct for deforming or unique sources, arbitrary per-vertex UVs, unsupported drivers and the instancing failure path. That makes CPU batching a legitimate long-term path, not legacy debt. Batch by source Ã— topology Ã— material streams Ã— display style, so one incompatible instance doesn't force the whole population into expansion.

Integration obligations the API doesn't cover: node bounds must enclose all displayed instances, and must be invalidated on source, mask, density, seed, time and visibility changes. `HitTest` and selection have to be designed explicitly [CL-VP-11]. Multiple viewports go through `UpdatePerViewItems`, which should return false when nothing changed [CL-VP-02]. Device change and resource release aren't specified by the reviewed docs [CL-VP-17].

### 2.5 GPU computation (Track E)

Transfer-inclusive crossover. With baseline `T0 = H + C_cpu` and GPU path `T_G = H' + U + A + L + C_gpu + S + R` (H' = remaining host work, U = upload, A = allocation, L = launch, C_gpu = kernel, S = sync, R = readback), the GPU wins only if `T_G < T0`. No universal launch, allocation or map cost exists, so measure them [CL-GP-07]. NVIDIA's PCIe figures (16 GB/s peak, about 12 GB/s pinned, Gen3) are illustrative, not this workstation [CL-GP-05].

| Backend | Position |
|---|---|
| Optimized CPU | Now; also mandatory fallback (DX-GP-01) |
| DirectCompute / D3D11, private buffers | Only plausible first probe, gated by Amdahl test (DX-GP-02) [CL-GP-15] |
| CUDA | NVIDIA-only comparison; runtime is redistributable per EULA Attachment A [CL-GP-11]; D3D11 interop registration is expensive and isn't an Autodesk contract [CL-GP-09, CL-GP-10] (DX-GP-03) |
| OpenCL | Not first: 3.x capability-based optional features, uneven Windows vendor coverage [CL-GP-12, CL-GP-13, CL-GP-14] (DX-GP-04) |
| SYCL / oneAPI | Not first: compiler/runtime/plugin deployment before a proven kernel [CL-GP-18] (DX-GP-05) |
| Vulkan compute | Defer: no Max/Nitrous path found (DX-GP-06) |

Kernel suitability: candidate generation and dense mask evaluation are the best shapes. Closest-point queries are plausible against a resident BVH. Spacing/collision acceptance is a poor shape (iterative, order-dependent). Procedural Max texmaps can't simply run in HLSL or CUDA. Publication stays on the host.

---

## 3. Case studies of documented production mechanisms

**Autodesk viewport instancing sample.** The SDK reference points to `MAXSDK/HOWTO/OBJECTS/VIEWPORTINSTANCE/INSTANCEOBJECT.CPP` and requires linking `optimesh.lib` [CL-VP-19]. This is the closest thing to an official reference design. Limitation: the docs cover data upload, not picking, device loss or hybrid scripted wrappers.

**tyFlow Display operator.** tyFlow documents Nitrous GPU instancing as one mesh plus a transform per particle, and warns that mapping overrides can defeat efficient instancing and cause "potentially enormous" resource usage. It offers Full / Ignore / Single-channel mapping-override modes [CL-VP-14]. Separately it offers a viewport-only, non-renderable Sprite mode for grains (tyFlow grains FAQ, https://docs.tyflow.com/faq/grains/ , agent-verified, not in ledger). Transfer: per-instance UV/material variety is the thing most likely to break instancing, so make it a user-visible tradeoff. Can't infer: tyFlow's internal buffers, batching or scheduler. Contradiction to test: Autodesk's 2026/2027 `InstanceData` documents per-instance UVW overrides for channels 1-8 [CL-VP-05]. tyFlow's restriction may reflect its own feature subset or an older API. Test the exact Cyrus UV need directly.

**Chaos Scatter (Corona/V-Ray).** Documents None/Dot/Box/Wire box/Full/Point cloud viewport modes, maximum instance and polygon limits, and adaptive full-to-box previews during interaction. It also documents camera clipping as a scene-parse/RAM optimization that can cause missing reflections and shadows [CL-VP-15]. Transfer: an explicit representation ladder with budgets, and a hard wall between viewport culling and render content. Can't infer: Chaos's private display engine, render-instance representation, or why its numbers are what they are.

**Renderers as neighbors.** Corona renders on the CPU, with interactive rendering also CPU, and GPU work goes via the Vantage Live Link [CL-GP-19]. V-Ray has CPU/CUDA/OptiX modes and warns that a single-GPU setup makes the UI sluggish [CL-GP-20]. Vantage uses up to two GPUs [CL-GP-21]. "The GPU is idle" is never a safe assumption.

---

## 4. Ranked shortlist and "do not build yet"

Full decision fields (simplest implementation, simpler alternative, strongest argument against, experiment, thresholds, confidence, reversal condition) are in `decision_experiment_ledger.csv`. Ranking:

| Rank | Option | Class | Strongest argument against | Reverses if |
|---|---|---|---|---|
| 1 | Measurement harness + run-identity manifest (DX-MQ-01) | Broadly applicable now | Instrumentation perturbs short frames | Overhead >2% median / >5% p95 after tuning; fall back to external ETW only |
| 2 | Representation ladder + budgets + viewport/render separation (DX-VP-03, DX-VP-04) | Broadly applicable now | Lower fidelity can surprise artists; more state | Sources always small enough for full display at target latency |
| 3 | Reproducibility contract: keyed counter RNG, fp policy, robust predicates, transform tests (DX-AL-02, -06, -07) | Broadly applicable now | May change legacy sequences/identities | Legacy sequence is contractual: keep legacy mode, add keyed mode explicitly |
| 4 | Per-version builds, ApplicationPlugins packaging, versioned persistence (DX-AL-09, DX-MQ-04, DX-MQ-05) | Broadly applicable now | Packaging work costs time | Never, for native binaries (documented incompatibility) |
| 5 | Retained geometry + `InstanceDisplayGeometry` prototype (DX-VP-01) | Investigate after profiling | Stream/material/picking/device-lifetime complexity | CPU batching matches it like-for-like, or required selection/UV semantics can't be kept |
| 6 | Bounded synchronous fork/join on owned snapshot (DX-CC-02) | Investigate after profiling | Overhead + renderer contention can erase gains | Large-case gain <10% or p95 UI worsens >5% |
| 7 | Grid/hash spacing broadphase; BVH for closest-point (DX-AL-03, DX-AL-05) | Investigate after profiling | Skewed density / frequent topology edits | Direct loop wins at real N and Q |

**Do not build yet:** GPU compute backend of any kind (DX-GP-02..06, DX-MQ-03). Multi-backend GPU abstraction. Persistent plugin executor (DX-CC-03). Asynchronous publication without lifecycle stress results (DX-CC-04). Private TBB/oneTBB/OpenMP runtime (DX-CC-06). Core pinning and NUMA tuning (DX-CC-08). `CustomRenderItemHandle` path (DX-VP-06). `RenderTimeInstancingInterface` until Corona/V-Ray support is confirmed per renderer (DX-VP-05). Alias tables, sample elimination, Lloyd relaxation and explicit SIMD until profiling points at them (DX-AL-01, -04, -08). Any cache without a written invalidation and lifetime contract.

**Simplify or remove first:** redundant redraw-triggered rebuilds (navigation must not rebuild unless the trace proves it should). Per-edit allocation (reuse owned scratch buffers tied to a revision). Per-view updates that return true when nothing changed [CL-VP-02].

---

## 5. Three most informative experiments

These were chosen to *discriminate between architectures*. They don't presume anything will be built. Thresholds are proposals, not measured facts. A difference only counts if it exceeds both 10% and the 95% bootstrap CI of paired trials.

### E1. Critical-path decomposition (decides CPU vs viewport vs GPU direction)
- **Input:** three scenes (small interactive; large dense proxy; mask/closest-point-heavy) plus one many-unique-sources scene. Fixed seeds, fixed viewport size and style, Adaptive Degradation **off** and logged.
- **Baseline:** current shipped build, identity verified by loaded module path + SHA-256 for DLL and scripts.
- **Measurement:** native QPC spans for extraction, packing, MAXScriptâ†”native boundary, compute kernels, geometry prep, display/realize, and publication. MAXScript boundary stamps. WPR trace. PresentMon CSV. Scenarios: navigation, edit-to-visible, rebuild, animation, render prep. Report cold and warm separately.
- **Controls:** uninstrumented run to quantify harness overhead. Order randomized across at least 2 interleaved A/B blocks, with warmups discarded.
- **Oracle:** generated/displayed/render counts plus an output hash identical with harness on and off.
- **Raw output:** per-span CSV (scenario, trial, frame, span, start, end, thread), PresentMon CSV, ETL, manifest JSON.
- **Decision use:** compute `p` per scenario. If the compute kernel `p < 0.20` everywhere, the GPU compute proposal is **rejected** (Amdahl ceiling â‰¤1.25x). If navigation frame time is dominated by draw submission/display, E2 is the priority. If edit-to-visible is dominated by host evaluation or marshalling, neither threads nor the GPU will help: fix invalidation first.
- **Stop:** harness overhead >2% median or >5% p95 that can't be reduced.

### E2. Like-for-like viewport A/B: CPU batching vs `InstanceDisplayGeometry`
- **Input:** a sweep of instance count {1k, 10k, 100k, 1M} Ã— source vertex count {8, 200, 5k} Ã— style {Standard, High Quality} Ã— {1, 4} viewports. Same transforms and colors in both arms.
- **Baseline:** current CPU-batched path. **Candidate:** minimal standalone native prototype following the SDK sample: `IObjectDisplay2`, `CreateInstanceData` with `pMatrices`, `UpdateInstanceData` for transform-only edits, CPU fallback on a `false` return.
- **Measurement:** PresentMon present-to-present frame time (median/p95/p99) on a scripted orbit path. CPU time in display callbacks. Create vs update cost. VRAM and RAM peak. Nsight Systems on NVIDIA for GPU completion.
- **Oracle:** image diff against the baseline at fixed camera frames (threshold agreed in advance, since non-pixel-identical rasterization is expected), plus matching counts and bounds.
- **Lifecycle probes:** instance count change, source topology change, material change, hide/unhide, viewport style switch, viewport add/remove, save/reload, Undo/Redo, forced `CreateInstanceData` failure.
- **Accept:** â‰¥25% p95 frame-time improvement on large cases, no small-case regression >5%, zero lifecycle failures. **Reject:** gains within noise, or required picking or UV semantics can't be preserved. **Stop:** any crash or stale-display defect in lifecycle probes that has no documented fix.

### E3. Owned-snapshot parallel parity and renderer contention
- **Input:** fixed immutable snapshots at small, medium and large candidate counts.
- **Arms:** serial; bounded fork/join at caps {2, 4, half logical, all-but-2}; grain sizes swept.
- **Contention conditions:** idle; Corona interactive running (default threads and "all but N"); V-Ray CPU render running.
- **Measurement:** wall time, p95/p99 main-thread stall, render time delta, cancellation latency, peak memory.
- **Oracle:** bitwise output equality across all thread counts and partitions (requires keyed RNG and deterministic merge). If the current contract is tolerance-based, use count/containment/spacing equality plus position tolerance.
- **Accept:** â‰¥20% wall gain on large, p95 UI stall no worse than +5%, render-time regression â‰¤5% under contention, zero parity failures. **Reject:** <10% gain, or any p95 regression >10%. **Stop:** any nondeterminism traced to the schedule.
- *Conditional E3b (only if E1 shows `p â‰¥ 0.5` for a regular dense kernel):* one private-buffer DirectCompute kernel, with end-to-end latency including all transfers. Continue only at â‰¥1.5x median end to end.

---

## 6. Staged qualification matrix and claim limits

| Stage | Must pass | What may be claimed |
|---|---|---|
| Alpha / smoke | Load/unload in each exact host build; create/delete; small scene display; basic edit; save/load; Undo/Redo; render start/stop with Corona | "Loads and runs the basic workflow on Max 2026.x / 2027.x build N with renderer R vN" |
| Functional beta | Smallâ†’large; repeated detailed meshes; many unique sources; degenerate/non-manifold/extreme-coordinate geometry; mask/density extremes; serial/parallel parity; numeric boundary corpus; mirrored/nonuniform/singular transforms; Manual and Real-time; animation; reset/merge/clone/XRef; old-scene load and scripted-plugin migration [CL-MQ-17, CL-MQ-18]; simulated allocation/device failure â†’ fallback | Feature correctness **for tested combinations only** |
| Performance beta | Harness runs per Â§5; cold/warm; long session (memory/VRAM growth); 32 GB machine at target scene sizes; Standard/HQ; Adaptive Degradation off *and* configured; Corona/V-Ray contention; raw distributions published | Measured bounds per scenario/build/hardware. **No** general FPS multiplier, **no** "faster than X" |
| Release candidate | Clean-machine install/upgrade/uninstall; per-version packages with exact SeriesMin/Max [CL-MQ-22, CL-MQ-23]; loaded-module hash manifest; DLL-collision tests [CL-MQ-24]; cancellation/shutdown mid-rebuild and mid-render; no open crash or data-loss defect | Support only for the tested host/update/renderer/hardware matrix |

A beta must **not** claim: support for an untested host version (build success â‰  runtime support), renderer compatibility inferred from viewport behavior, scalability beyond tested scene sizes, or FPS gains without a frame-time capture.

---

## 7. Ledgers

- `claim_source_ledger.csv`: id, claim, evidence_class, url, section, pub/update date, access date, version, applicability, confidence, contradictions, validation_needed, decision_status, parent_check.
- `decision_experiment_ledger.csv`: id, option, workflow_bottleneck, classification, simplest_impl, simpler_alternative, strongest_argument_against, experiment, thresholds, confidence, reversal_condition.

Notable contradictions recorded: tyFlow vs Autodesk on instanced UVW overrides (CL-VP-14 vs CL-VP-05). 2026 .NET 8 at release vs .NET 10 after security updates (CL-MQ-19). The 2027 SDK setup article title references VS2026 while its body specifies VS2022 17.14 / v143 (CL-MQ-21). Per-worker threshold proposals differed (20 to 50%); Â§5 harmonizes them.

---

## 8. Handoff to GPT-6 Astra (Codex)

**Find in the real source (structures, not assumed paths):**
1. Which display interface the plugin object exposes (`IObjectDisplay2` vs legacy `Display()`/`GraphicsWindow` calls vs GW caches), and where display data is built vs drawn.
2. Every worker-thread entry point, and proof that no `INode`, reference, paramblock, MAXScript value, Hold or graphics call is reachable from it. Where joins happen, and whether any thread outlives a call.
3. How randomness is drawn: a stateful stream vs keyed per logical ID, and whether thread partitioning can change consumption.
4. Compiler floating-point flags in each project configuration (`/fp:*`, `/fp:contract`, arch flags) per Max version.
5. Invalidation triggers: what causes a rebuild during pure navigation, and the cache key and lifetime of every cache.
6. `LibVersion()` / SDK macros per build. Package manifest `SeriesMin`/`SeriesMax`. Scripted plugin `classID`/`version`/`update` handlers.
7. Render path: `GetRenderMesh` aggregate vs any render-time instancing exposure, and whether any viewport budget or culling leaks into it.

**Measure:** E1 first, then E2 or E3 according to E1's `p` values. Always attach the identity manifest.

**Do not adopt from this report without local checks:** any claim about Cyrus's bottleneck (none is established here). The viewport-instancing recommendation, until E2 lifecycle probes pass in both hosts. Any threading change, until E3 parity passes. Any fp-flag or RNG change, until the current output contract is identified. The 2026 toolchain specifics. Every row marked "not independently re-opened by parent" in the claim ledger should be treated as single-source.

---

## Self-audit (applied before finalizing)
- Removed any claim about Cyrus internals. All project statements are conditional.
- Viewport, simulation and render kept separate (viewport instancing â‰  render instancing â‰  native instances).
- No invented API names: every named SDK symbol appears in a cited Autodesk page, and three were re-opened by the parent.
- Vendor comparisons cite each vendor's own docs. No performance claims transferred from tyFlow or Chaos.
- GPU advice is transfer-inclusive and gated. No multi-backend proposal.
- No weakening of the correctness contract: the proposed reproducibility contract is labeled a proposal.
- Narrowed: PIX demoted to diagnostic. Wikipedia replaced as the Amdahl source. Async and persistent pools moved to defer.

### Unresolved research list
Exact 2026 SDK native toolchain table. Pump cadence and shutdown semantics of the main-thread task queue. Notification-callback thread affinity. Device-loss handling for retained Nitrous resources. Per-instance picking with `InstanceDisplayGeometry`. Corona/V-Ray `RenderTimeInstancingInterface` support. AMD Windows OpenCL coverage for target SKUs. Whether a private DX12 path exists inside Nitrous (no public evidence).