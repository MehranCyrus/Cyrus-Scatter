# 01 — Executive decision

[Index](00_README.md) · [Max feasibility gate](07_MAX_2027_INTEROP_FEASIBILITY.md) · [Prototype plan](13_PHASED_IMPLEMENTATION_PLAN.md)

## Recommendation

**Researcher A recommends a staged hybrid: retain optimized CPU fitting for small active neighborhoods; first prototype shared-source GPU deformation using completed guide poses through supported Max HLSL inputs; add a separate optional GPU fitter only after a quality-equivalent, complete-pipeline benchmark shows a worthwhile large-active-work benefit.**

If that compute stage is justified and NVIDIA support is acceptable, **CUDA is the first prototype candidate for engineering-cost reasons**, particularly its primitives and diagnostic tools. It is not established to be intrinsically faster than OpenCL. Compare both on the same NVIDIA hardware with matched algorithms, accuracy, contact completeness and transfer policies. Prefer OpenCL if the matched result or a real cross-vendor requirement outweighs CUDA's tooling advantage. Prefer D3D11 compute if its supported in-Max resource/context path proves materially simpler. Preserve CPU fallback in every case.

This is **[D — a proposal]**, not a measured speed ranking. No GPU backend, Max plugin, shader, benchmark, installer, or renderer pass was executed for this research. The package contains current primary-source findings, bounded designs and a falsifiable validation program.

## What the evidence changes

**[V] Max has a concrete public native-device candidate.** The 2027 SDK documents `ID3D11GraphicsWindow::GetDevice()`, raw buffer factory methods and a public interface ID. `IVirtualDevice` also documents UAV/stream-output operations. Therefore a blanket “Max has no public D3D access” conclusion would be false. Successful acquisition from the current retained Nitrous path, resource bridging, synchronization, lifetime and reset behavior remain **[U] unresolved**; `SmartHandle::GetPointer()` is marked internal and cannot justify pointer extraction. [MAX03](17_SOURCE_LEDGER.md#max03) [MAX11](17_SOURCE_LEDGER.md#max11) [MAX12](17_SOURCE_LEDGER.md#max12)

**[P] The current product's sparse work is already much smaller than its scene population.** The supplied 200-plant example considered three nearby candidates and fitted six guides; its approximately 4.05 ms observation covers native contact evaluation only. The context also identifies retained-map copying and visible-surface refinement as costs to profile. It does not establish the capacity to fit a million active instances. [PROJ02](17_SOURCE_LEDGER.md#proj02)

**[E/X] Compact poses are useful but not unlimited.** With the hypothetical eight nodes per guide and a 32-byte node record, 10,000 fully posed clumps with 451 guides each need 1.15456 GB for node poses alone; one million need 115.456 GB. Full position/normal output for one million copies of the supplied 22,032-vertex source is 528.768 GB, before renderer and other data. One million simple blades with one guide each, in the same eight-node model, need 256 MB of poses. These are executed arithmetic results under explicit assumptions, not measured allocations or realtime capacities. [09](09_MEMORY_PRECISION_AND_HARDWARE.md)

**[V] Current tools do not eliminate product-specific work.** Warp's capsule-BVH operation enumerates candidates using inflated bounds; it is not exact whole-span mesh contact. TressFX's inspected shader contains point-based contact and follow-hair behavior, with temporal simulation assumptions. Jolt's public 5.6.0 experimental GPU hair is a separate system with limited environmental shapes. These can inform implementation without supplying Cyrus's binding, static semantics, visible-leaf correctness or Max delivery. [COL17](17_SOURCE_LEDGER.md#col17) [COL22](17_SOURCE_LEDGER.md#col22) [COL26](17_SOURCE_LEDGER.md#col26)

## Five architectures compared before selecting an API

All rows are **[D/E] design analyses**. “Quality” assumes the same final constraint/visible-surface contract; no row earns correctness merely through its execution device.

| Architecture | CPU work | GPU work and transfers | Synchronization / memory | Quality and recovery | Max requirement / effort |
|---|---|---|---|---|---|
| A1 optimized CPU fit + CPU deformation | Capture, neighborhoods, fit, refinement, evaluator, publication | Existing draw; upload changed materialized vertices/normals and transforms | Existing joins/publication; output scales with changed/retained vertices | Closest to supplied behavior; preserve old result on failure | Existing public path; lowest new integration effort; investigate map-copy/refinement/upload costs |
| A2 CPU fit + shader deformation | Same fit/refinement; canonical poses and final CPU materializer | Upload compact poses/masks; vertex shader gathers shared geometry; no solver compute runtime | Completed CPU pose→retained upload→draw; source+pose storage, repeated shader work per pass | Exact if evaluator/normals/pass rules match; CPU geometry fallback | Prove pose fetch, whole-group clipping, normals, bounds, picking and final delivery; preferred first prototype |
| A3 CPU neighborhood + GPU fit + GPU deformation | Capture/index/admission; exact or mixed final validation; publication | Resident sources/colliders, compact work upload; solve and deform; compact readback if needed | Optional direct bridge or GPU→CPU→Max round trip; queue/fences plus sparse poses/scratch | Equal accepted quality only after complete checks; CPU fallback for unsupported/uncertain cases | New compute module and async service; raw-resource bridge optional if readback wins |
| A4 GPU neighborhood + fit + deformation | Host revisions/capture and final delivery | Resident placement/index + all fitting/deformation; transformed-index updates; final validation data | More persistent state and GPU rebuild/refit/sort; difficult stale-result and memory recovery | No inherent correctness advantage over A3 | Largest implementation scope; justified only if measured CPU index cost dominates large changes |
| A5 GPU conservative proxies/fields + refinement | Author/admit proxies, exact refine/audit, final publication | Field/proxy upload once; approximate/search fitting; final readback/refinement | Field construction/residency and two-quality result lanes; error+coverage metadata | Conservative envelope may overbend; uncertified result explicitly Approximate, never silently final | Useful optional accelerator where total cost wins; thin/inside/band cases are a separate gate |

No architecture reduces preparation to “one thread per plant.” Parallel scheduling, parent depth, contacts and memory accounting are in [03](03_PARALLELISM_AND_DATA_LAYOUT.md); exact versus approximate geometry is in [05](05_COLLISION_AND_GUIDE_SOLVING.md).

## Weighted architecture decision matrix

**[D] Scores are declared engineering judgments on a 1–5 scale, not benchmarks or probabilities.** Higher is better. Weights reflect the immediate sparse-edit product and prioritize total integration and maintenance cost. Hard quality, supported-interface and memory gates take precedence over any score. A2's scores assume its narrow parity gate succeeds; otherwise remove it and retain A1.

| Criterion / weight | A1 CPU | A2 CPU+shader | A3 local CPU+GPU fit | A4 full GPU | A5 proxy+refine |
|---|---:|---:|---:|---:|---:|
| Continuity with current quality contract — 25% | 5 | 5 | 3 | 3 | 3 |
| Integration and maintenance cost — 25% | 5 | 4 | 2 | 1 | 2 |
| Sparse-edit suitability — 15% | 5 | 5 | 2 | 2 | 3 |
| Large-active acceleration potential — 15% | 2 | 3 | 5 | 5 | 5 |
| Memory/residency economy — 10% | 3 | 5 | 4 | 4 | 4 |
| Hardware/deployment reach — 10% | 5 | 5 | 2 | 2 | 2 |
| Weighted score / 5 | **4.35** | **4.45** | **2.90** | **2.65** | **3.05** |

The 0.10 difference between A1 and A2 is deliberately modest: measurement may erase it. A5's slightly higher total than A3 comes from its more favorable sparse-edit judgment; both have an integration and maintenance score of 2/5. This does not establish that A5 is faster. Its proxy error policy must still pass the acceptance gates. Large-active acceleration entries represent potential, not achieved latency.

**Sensitivity:** if fitting rather than deformation dominates large active regions, A2's acceleration score falls and A3 deserves the next prototype. If host capture or map copies dominate, both GPU paths lose value. If public shader delivery fails, A2 is removed. If direct interop is unavailable, A3/A5 must be scored using actual compact readback, validation and upload costs; if those erase the win, stop them. A4 needs independent evidence that CPU neighborhood search is the bottleneck, rather than fitting or output.

## Weighted API matrix for an optional solver

**[D]** This second matrix applies only after the workload justifies compute. It uses the same 5-point judgment scale. All candidates must first pass the fixed quality tests. Interop is scored equally low until locally proved; the table does not establish a working Max path.

| Criterion / weight | CUDA | OpenCL | D3D11 compute |
|---|---:|---:|---:|
| Reusable primitives / diagnosis — 25% | 5 | 3 | 2 |
| Ability to express chosen qualified algorithm — 20% | 5 | 5 | 5 |
| Currently unproved Max bridge — 20% | 2 | 2 | 2 |
| Cross-vendor Windows reach — 15% | 1 | 5 | 4 |
| Optional deployment/runtime burden — 10% | 3 | 3 | 4 |
| Implementation convenience for this prototype — 10% | 5 | 3 | 2 |
| Weighted score / 5 | **3.60** | **3.50** | **3.10** |

These scores explain why CUDA is a first experiment, not a predetermined winner. Increasing portability from 15% to 30% while reducing primitives/tooling from 25% to 10% produces scores of CUDA 3.00, OpenCL 3.80 and D3D11 compute 3.40. If a supported D3D11 bridge earns 5 while external API bridges score 1, the original weights yield CUDA 3.40, OpenCL 3.30 and D3D11 compute 3.70. If mandatory FP64 or another unsupported feature blocks a backend, remove it regardless of score. Arithmetic is reproducible in [analysis](analysis/README.md).

**[V] Version-qualified research inputs** include CUDA 13.4 Update 2 / CCCL 3.4.3 and OpenCL specification 3.1.2. The base OpenCL command-buffer extension was ratified as version 1.0.0 in September 2026, but actual NVIDIA and other driver support must be queried. The official Max 2027 compiler matrix and CUDA's literal compiler table leave an exact compiler combination to qualify. These findings change the prototype and deployment checks; they do not change the quality criteria or establish a speed advantage. [API01](17_SOURCE_LEDGER.md#api01) [API05](17_SOURCE_LEDGER.md#api05) [API06](17_SOURCE_LEDGER.md#api06) [API02](17_SOURCE_LEDGER.md#api02) [MAX01](17_SOURCE_LEDGER.md#max01)

## The smallest next prototype and decisive falsifiers

Build a tiny **two-instance authored-pose display experiment** plus stage instrumentation. It must preserve normals/tangents, UV seams, whole-group visibility, picking, bounds and CPU render/Bake output. Separately probe the public D3D11 interface and documented lifetime. No collision port is needed to settle either question. Then use a fake delayed backend to validate generation and lifetime behavior before real asynchronous kernels.

Only move to a bounded GPU static fitter when profiles show a large enough `A, Q, P` workload. Compare exact whole-span queries, initialization from rest, root-position/root-frame semantics, rest curvature, length and complete visible geometry. There is no measured crossover threshold in this report. [10](10_BENCHMARK_AND_VALIDATION_PLAN.md) defines how to obtain one and the proposed improvement rule.

Reject the GPU route if it requires private Max resource extraction, loses contact completeness, cannot bound memory/work, silently substitutes a history-dependent simulation, or wins kernel time while losing completed input-to-present latency. Reject claims of universal renderer support until exact renderer/build paths are tested.

**Highest-risk unresolved integration question:** can the chosen public Max 2027 path consume completed pose/compute data with supported ownership, synchronization, device-recreation handling and consistent final geometry delivery? The raw device declaration makes this a concrete experiment; it is not the answer to the experiment.
