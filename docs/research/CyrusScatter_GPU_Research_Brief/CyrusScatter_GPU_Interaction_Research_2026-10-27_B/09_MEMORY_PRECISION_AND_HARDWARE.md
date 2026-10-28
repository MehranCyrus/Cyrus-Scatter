# 09 — Memory, precision and practical hardware

[Index](00_README.md) · [Layouts](03_PARALLELISM_AND_DATA_LAYOUT.md) · [Validation](10_BENCHMARK_AND_VALIDATION_PLAN.md)

## Evidence and assumptions

**[X — executed]** The standard-library Python script [calculate_budgets.py](analysis/calculate_budgets.py) was run in the supplied Linux environment; [calculated_budgets.json](analysis/calculated_budgets.json) contains its actual output. It computes byte counts and binary32 spacing. It does not allocate the modeled scenes, measure bandwidth, run a GPU kernel, or evaluate Max.

**[E — analytical estimates]** The model uses the supplied 451 guides / 22,032 vertices / 27,501 triangles, but **eight nodes per guide is an invented scenario parameter**, not an observed property of that source. The number of render vertices after UV/normal seams is unknown; treating the supplied vertex count as the render count is a favorable lower model. Memory objects, allocator metadata, alignment, materials/textures, renderer copies and BVH nodes are extra. Decimal MB/GB are used below; JSON also reports binary GiB.

## Shared versus unique storage

Under the proposed [03](03_PARALLELISM_AND_DATA_LAYOUT.md) schema, one example source is:

`22,032×(48 rest-vertex + 32 binding) + 27,501×(12 index + 8 metadata) + 451×(32 guide-header + 8×48 rest-node) = 2,500,196 bytes`.

That approximately 2.50 MB shared-source model is encouraging, but does not include unique poses or deformed output.

| Population, if all are fully posed | Instance records at 80 B | Node poses at 451×8×32 B | Three pose versions | Position+normal output at 22,032×24 B |
|---|---:|---:|---:|---:|
| 1,000 clumps | 0.08 MB | 115.456 MB | 346.368 MB | 528.768 MB |
| 10,000 clumps | 0.8 MB | 1.15456 GB | 3.46368 GB | 5.28768 GB |
| 100,000 clumps | 8 MB | 11.5456 GB | 34.6368 GB | 52.8768 GB |
| 1,000,000 clumps | 80 MB | 115.456 GB | 346.368 GB | 528.768 GB |

The output column excludes copied topology, tangents, UVs and render acceleration. Topology can remain shared in some display paths; positions of differently deformed plants cannot all be represented by a single rigid instance transform. Three pose versions include accepted/work/retired data, not all scratch. A million fully active detailed clumps is therefore outside a sensible single-workstation interactive first release even before measuring arithmetic throughput.

By contrast, one million **simple one-guide blades**, each with eight nodes, would use 256 MB for one 32-byte/node pose version. One million total clumps with only ten fully posed clumps need about 1.155 MB of those node poses, plus instance/index and retained-state costs. Six changed guides total would require 1,536 pose bytes plus 96 bytes of 16-byte guide records in this model. These very different cases must never share a headline “million objects” performance claim.

## Hidden multiplicative costs

| Allocation pattern | Example consequence | Required policy |
|---|---|---|
| Dense guide lookup table for every resident clump | `1M×451×4 = 1.804 GB`, or 3.608 GB with 8-byte entries | Allocate sparse tables for posed instances, or two-level paged lookup with explicit worst case |
| Full rooted-group bitmask everywhere | Assuming one group per guide, `ceil(451/32)×4×1M = 60 MB` | Default-all-visible sentinel; count actual root groups |
| Eight collider candidates for every span | `10k×451×7×8×16 = 4.04096 GB` of naive span-pair records | Span-bound pruning; tiled enumeration; fail rather than silently truncate |
| Plant/collider candidates only | `10k×8×16 = 1.28 MB` | This does not include the subsequent span/triangle work |
| Many historical or queued results | Each retained version can retain its backing pages | One in-flight plus one coalesced pending request; bounded Undo/cache policy |
| Retained CPU maps copied on every update | Cost can scale with `R`, even if `K` is tiny | Profile; consider immutable page/path-copy or bounded delta-map designs, preserving publication atomicity |
| GPU rendering active on same device | Competition for VRAM, bandwidth and execution time | Measure under renderer contention and respect dynamic budgets |

The current supplied pose representation has a source-guide-indexed array **on a posed plant**. It does not establish that today’s plugin allocates a dense `N×G` table for every untouched instance. The dense rows above are worst-case design hazards, not accusations about unseen code. [PROJ02](17_SOURCE_LEDGER.md#proj02)

## Fallback transfer costs

**[E]** With no supported Max compute-resource bridge, read back `32Q + 16A + diagnostics + masks` bytes and upload compact poses through public graphics handles, if that shader path is qualified. CPU materialization instead requires roughly `24V_changed` position/normal bytes uploaded, with tangents/other changes extra. Full GPU mesh readback is usually the largest fallback.

For **node-pose bytes only** in the assumed example, a hypothetical **12 GB/s effective one-way link** gives transfer-only times of 0.096 ms for ten plants, 9.62 ms for 1,000 and 96.21 ms for 10,000. Including the 16-byte-per-guide directory gives approximately 0.10223 / 10.2227 / 102.227 ms respectively, before masks and diagnostics. This is `bytes/bandwidth`, not a measured PCIe rate. It excludes synchronization, packing, transfer setup, CPU validation, re-upload, driver scheduling and contention. Reading back and uploading the same size again is two transfers, even if the second uses another adapter. A sparse six-guide result is an entirely different transfer workload.

Use measured completed transfer time and byte counters to evaluate the readback fallback. If only a small error certificate can return, it still cannot replace the canonical CPU pose needed by the chosen render/Bake/export contract without an explicitly supported alternate consumer.

## Field and acceleration storage

For a dense field covering both endpoints, use `n=ceil(extent/h)+1` and declare the padded final bound; one scalar float costs `4n³`. All examples below divide evenly, so no partial cell is needed. [X/E]

| Cube extent / cell | Scalar float32 only | Scalar plus stored float3 gradient |
|---|---:|---:|
| 2 m / 1 cm | 32.482 MB | 129.930 MB |
| 2 m / 5 mm | 257.925 MB | 1.032 GB |
| 20 m / 1 cm | 32.048 GB | 128.192 GB |

Sparse/narrow-band storage can reduce occupied cells but adds tiles, indirection, sign/background conventions and construction costs. A clipped band with an unknown interior cannot certify a blade initially inside a solid. Keep fields in collider-asset space and reuse for rigid/uniform-scaled instances; geometry edits invalidate the field. The stored local cell/error stays fixed; uniform collider scale `s` multiplies its world error, while world clearance/radius are divided by `s` for a local query. See the conservative error analysis in [05](05_COLLISION_AND_GUIDE_SOLVING.md).

## Precision policy

**[V]** IEEE-format compliance does not ensure identical results after different reduction order or fused operations. NVIDIA documents CPU/GPU differences from FMA, associativity and compiler choices. [SYS12](17_SOURCE_LEDGER.md#sys12)

**[X/E]** Executed binary32 spacing calculations show:

| Coordinate magnitude in metres | Adjacent float spacing | Is a 1 mm offset retained when both absolute endpoints are cast to float? |
|---:|---:|---|
| 1 | 0.0000001192 m | Approximately |
| 10 | 0.0000009537 m | Approximately |
| 1,000 | 0.0000610352 m | Rounded to 0.0009765625 m |
| 100,000 | 0.0078125 m | No; rounds to zero difference |
| 1,000,000 | 0.0625 m | No; rounds to zero difference |

Subtracting the reference origin in CPU double **before** packing the local delta to float preserves the millimetre difference in this arithmetic example. It cannot restore detail already lost in Max’s source evaluation or an earlier float transform. Capture/canonical precision and renderer float delivery remain separate boundaries.

**[D]** Keep CPU transforms, unit conversion, reference geometry/audits and large-coordinate origin arithmetic in double. Rebase each plant/collider query into a bounded local frame. Use FP32 for the first GPU local solver/deformer experiment, no fast-math initially; upgrade sensitive predicates/reductions to FP64 or CPU robust queries only where error tests justify it. Consumer/workstation labels do not predict FP64 throughput; query and measure actual hardware. Test matched FP32 CPU for algorithm parity, the current CPU implementation for behavior, and an independent double reference/audit for accuracy. The supplied context does not establish that the entire current fitter/evaluator uses double.

Reject NaN/Inf, invalid frames, zero spans, nonpositive scales, and ill-conditioned transform input before upload. Use quantity- and constraint-scaled degeneracy thresholds: a length epsilon is distinct from a mobility or gradient-denominator threshold. Grazing/coplanar contact inside the error band is “uncertain/boundary,” not “clear.” Contact tolerances cannot be used as an extra artist gap or subtracted twice to disguise penetration.

## Proposed numerical gates, not current product tolerances

Let `Lref` be the characteristic guide length in metres for the tested asset, recorded with the fixture. Candidate strict-guide tests use the following starting values; the local team must accept or revise them **before** comparing backends.

| Quantity | Proposed admission/acceptance |
|---|---|
| Root / child attachment displacement | `≤ max(1e-6 m, 1e-6 Lref)` after complete evaluation |
| Guide span strain | `max |length/restLength−1| ≤ 1e-3` in strict-length fixtures; any intentionally elastic mode states its separate bound |
| Visible contact residual | Penetration/required-clearance deficit `≤ max(1e-5 m, 1e-5 Lref)` under declared double reference; uncertainty must be reported |
| Quaternion norm | Absolute norm error `≤1e-5` packed, renormalized before use; no zero quaternion |
| Tangent/frame alignment | Angular error `≤0.1°` in synthetic well-conditioned frames; twist/sign continuity tested separately |
| CPU/GPU deformed vertex difference | `≤max(1e-5 m,1e-5 Lref)` on shared accepted input poses; tighter independent exact-rest path |
| Normal angular difference | `≤0.5°` outside declared degenerate/singular faces; UV seam and tangent handedness exact categorical checks |
| Rest restoration | Exact shared-rest descriptor and unchanged IDs/bindings; renderer float positions within delivery precision |

These floors can be too large for microscopic assets. Such inputs need a tighter locally qualified double path or an explicit unsupported scale diagnostic; silently accepting a tolerance comparable to blade thickness is unacceptable. Require conservative total numerical/field error to be materially smaller than the requested clearance and minimum feature thickness; proposed admission target `error≤min(thickness,gap)/4` when both are positive. Include GPU evaluator deviation from the CPU-validated surface in that total error budget: checking a CPU mesh does not certify a different displayed surface without that allowance. A zero contact gap uses a separately declared boundary tolerance, not division by zero. Guide span strain and visible stem-edge strain are different quantities.

## Hardware selection and economic practicality

**[D]** Qualify existing target hardware first. The necessary baseline for the proposed graphics deformation lane is the actual supported Max2027 display path and SM5 resource behavior; for optional CUDA fitting, an admitted compute architecture, sufficient driver and memory, and matched display-device identity if sharing is used. OpenCL feature presence is discovered at runtime, not inferred from a vendor logo. Current API/version/hardware facts and redistribution constraints are in [04](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md) and [15](15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md).

Choose representative 8/12/16 GB, 24/32 GB and larger professional-memory classes only as **qualification tiers**, not a purchase recommendation. Large-memory hardware cannot rescue the 346 GB triple-pose example plus 529 GB expanded-output case. A separate compute GPU may isolate some compute work but adds pose transfers and has no assumed cross-adapter resource sharing. Multiple monitors and laptops may select a different display adapter after device recreation.

Budget against currently available process/device headroom, not nominal board capacity. `IDXGIAdapter3::QueryVideoMemoryInfo` exposes budget/usage on a qualified Windows adapter path; retain allocator and OS telemetry because driver/process overhead and other plugins consume memory. [SYS03](17_SOURCE_LEDGER.md#sys03) Unified or managed memory may migrate or page and therefore is not a substitute for explicit residency and bandwidth accounting; API-specific behavior is reviewed in [04](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md).

## Current documented hardware examples and feature floor


The current CUDA GPU table identifies Turing at compute capability 7.5, representative Ampere GeForce RTX 30 cards at 8.6, Ada GeForce RTX 40/RTX 6000 Ada at 8.9, and GeForce RTX 5090/RTX PRO 6000 Blackwell at 12.0. The capability number selects binary/features; it is not a speed ranking for a particular contact solver. [API30](17_SOURCE_LEDGER.md#api30)

For a CUDA 13.x AOT implementation using the currently documented nvcc architecture set, Turing is a practical compiler floor. This comes from the selected toolchain, not from rooted-vegetation mathematics. Supporting older GPUs could require a separately maintained earlier toolchain/backend. That support decision must include driver security/availability, compiler testing and installed audience, rather than quietly adding a legacy binary. [API03](17_SOURCE_LEDGER.md#api03)

| Representative hardware | Documented memory | Role in a proposed qualification set |
|---|---|---|
| GeForce RTX 3060 Ti / RTX 3060 | 3060 Ti 8 GB; 3060 has 12 GB **and 8 GB** versions | An existing lower-memory Ampere device exposes budget failures. Record exact SKU, not just “3060 = 12 GB.” [API32](17_SOURCE_LEDGER.md#api32) |
| GeForce RTX 4070 family | 4070 Ti SUPER 16 GB; 4070 Ti/SUPER/4070 12 GB | Existing Ada workstation test if available; provides a different architecture without making the newest generation mandatory. [API33](17_SOURCE_LEDGER.md#api33) |
| GeForce RTX 5090 | 32 GB GDDR7 | Optional high-memory consumer test; not a purchase recommendation. [API34](17_SOURCE_LEDGER.md#api34) |
| RTX PRO 6000 Blackwell workstation edition | 96 GB GDDR7 ECC; vendor specification lists 600 W maximum power | Upper memory/power example only. More VRAM does not prove a million detailed clumps can all change interactively. [API35](17_SOURCE_LEDGER.md#api35) |

**Proposed qualification:** start on available Ampere/Ada hardware and a constrained-memory device. Add a larger-memory device only if active-pose, collider, renderer and in-flight budgets justify it. Query exact device limits, runtime features and available graphics-memory budget. Avoid a fixed “must own an RTX 5090” rule before measurements. A card can meet the API feature floor and still be below the desired interaction performance tier.

Don't budget all nominal VRAM for Cyrus. Max viewport buffers, renderer textures/acceleration structures, other plugins, driver allocations, staging and old/in-flight/new results share the device. Configure an admission budget below observed available memory and expose graceful refusal/fallback. Record display resolution, number of viewports, renderer activity and power policy in the benchmark. A second compute GPU can add memory/throughput but may lose direct sharing with the display adapter; test the compact transfer bridge explicitly.

The CUDA capability appendix documents differences in limits/features across architectures. Exact FP64 throughput, atomic support, cache behavior and occupancy require the chosen GPU's specifications and measured kernel profile; no throughput extrapolation from architecture name is warranted. [API31](17_SOURCE_LEDGER.md#api31)

### Unified Memory is not a memory-budget escape

The current CUDA guide describes Windows/WSL/Tegra limitations for systems reporting `concurrentManagedAccess == 0`, including lack of demand paging/oversubscription and restrictions on CPU access during GPU activity. Query capabilities; do not assume Linux full-feature behavior inside Windows Max. [API16](17_SOURCE_LEDGER.md#api16)

**Proposed baseline:** explicitly allocated source/collider buffers, compact active work, preallocated scratch, pinned transfer staging only where beneficial, and complete accounting for pool retention. Measure copy, allocation and residency stalls separately. A “Unified Memory” alternative belongs in a later experiment with the same peak memory/admission rules, not in an initial promise of unlimited scale.

