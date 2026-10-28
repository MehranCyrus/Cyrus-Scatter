# 09 — Memory, numerical precision and practical hardware

[Contents](00_README.md) · [Layouts](03_PARALLELISM_AND_DATA_LAYOUT.md) · [Executed arithmetic](optional/executed_checks.json)

## What the numbers mean

**E.** This chapter computes storage lower bounds for proposed representations. They are not measured allocations or throughput. **X.** The included Python program executed the arithmetic and ten analytic controls; it did not allocate these scene sizes, run a fitter, use a GPU, or measure performance. Decimal MB/GB/TB mean powers of 1,000; MiB/GiB mean powers of 1,024. Manufacturer capacities are reproduced as advertised GB, without pretending all bytes are available to Cyrus.

The detailed grass count is S: `G=451`, `V=22,032`, `T=27,501`. **Eight nodes per guide is an explicit hypothesis**, because the supplied context does not give that count. Proposed nodes occupy 32 B, delta-guide headers 16 B, mutable float position/normal/tangent output 40 B/vertex. More samples, double arrays, multiple influences, extra UVs or derivatives increase the budget.

## Separate resident, active and retained memory

| Allocation | Proposed expression | Notes |
|---|---|---|
| Resident transforms/IDs | `80N` | Numeric schema; a GPU SoA and CPU snapshot may each exist |
| Leaf bounds + illustrative binary index | `32N + 64N` | Separate leaf bounds and roughly two 32 B nodes per leaf; additional maps/scratch not included |
| Source geometry/bindings | `Σ(48V_s + 32V_s + 12T_s)` | Shared; render seams can increase `V_s` relative to logical topology |
| Rest guide frames | `32ΣQ_s` | Shared per source |
| Changed guide poses | `32Q_D + 16H_D + 16D` | Plus visibility, directories, allocator/page overhead |
| Per-instance guide directory | `4DG` if dense only for retained poses | `4NG` if incorrectly allocated for every instance |
| Candidate pairs | `16P` illustrative | Separate counts/sort scratch/contact outputs |
| Contact results | `64P_contact` illustrative | Normals, witnesses, IDs, status; precise layout to qualify |
| Unique graphics output | `40Σ_{posed}V_i` | UV/index can remain shared in viewport; renderer/Bake may duplicate more |
| CPU double audit positions | `24V_A` | Plus triangle acceleration, normals if evaluated and scratch |
| Old/new generations | Up to several mutable payloads | Sources can be shared; pages/read leases must actually prove the savings |

For the one hypothetical source, geometry + bindings + indices + rest frames + 64 B/guide metadata total **2,236,892 B**. This omits material textures, secondary channels, source audit geometry/BVH and allocator overhead. A shared source is small compared with millions of unique states, but not all assets have this source's complexity.

## Representative lower bounds

Assume `D=K` for illustration only; long editing sessions can retain many more changed instances.

| `N` resident | `K=D` | Changed guides/instance | Resident table+bounds+index | Poses, excluding masks/instance headers | Unique mutable vertex stream |
|---:|---:|---:|---:|---:|---:|
| 1,000 | 1 | 1 | 0.176 MB | 272 B | 0.88128 MB |
| 10,000 | 10 | 6 | 1.76 MB | 16,320 B | 8.8128 MB |
| 100,000 | 100 | 6 | 17.6 MB | 163,200 B | 88.128 MB |
| 1,000,000 | 10 | 6 | 176 MB | 16,320 B | 8.8128 MB |
| 1,000,000 | 1,000 | 451 | 176 MB | 122.672 MB | 881.28 MB |
| 1,000,000 | 10,000 | 451 | 176 MB | 1.22672 GB | 8.8128 GB |
| 1,000,000 | 1,000,000 | 451 | 176 MB | 122.672 GB | 881.28 GB |

The last row contains **451 million guides**, **3.608 billion hypothetical guide nodes**, **22.032 billion vertices**, and **27.501 billion triangles** before any display culling/LOD. One full node array alone is 115.456 GB. Triple guide-pose generations reach 368.016 GB before scratch and mirrors. It is not a practical interactive single-workstation target at this representation, even with a 96 GB GPU. A million *simple* blades is a different problem: one eight-node guide per blade needs 272 MB for these pose/header bytes, still plus resident metadata, contacts, drawing and generations.

Keeping an all-instance `uint32` guide directory costs **1.804 GB** for the detailed source, while one 64-bit entry costs **3.608 GB**. Actual C++ shared-pointer/container overhead was not inspected and must be measured locally. Sparse representations require genuinely sparse lookup directories as well as sparse node values.

For 10,000 fully active detailed clumps and 64 colliders, a dense span–collider product is `10,000×451×7×64 = 2,020,480,000` candidate pairs. At 16 B that is **32.32768 GB**, before contact results. Broad-phase pruning, streaming/chunking and count admission are mandatory; the fact that each plant admits 64 colliders does not imply its cross product is cheap.

## Transfer floors and fallbacks

**E.** With an assumed completed effective transfer rate of 16 GB/s, ignoring fixed overhead, contention and staging:

| Payload for 1,000 fully posed detailed plants | Bytes | One-way arithmetic floor |
|---|---:|---:|
| Compact nodes + guide headers | 122,672,000 | 7.667 ms |
| Mutable float position/normal/tangent stream | 881,280,000 | 55.080 ms |

These are illustrative `bytes/rate` values, **not a claim that this system delivers 16 GB/s**. Pose readback followed by a comparable Max pose upload roughly doubles the byte traffic, before CPU validation. Source vertices, visibility/directories, PCIe topology and page-locked staging can add cost. By contrast, six changed guides under this hypothesis are only 1,632 B plus instance/mask metadata. That is why the measured active population determines the route.

Do not infer a usable transfer rate from the GPU's onboard GDDR bandwidth or PCIe generation alone. Measure completed transfers of the actual payload sizes, warm and cold, pageable and approved bounded staging buffers, while Max and the renderer compete for the GPU. Unified memory can cause page migrations/faults and does not remove these costs. [R08](17_SOURCE_LEDGER.md#r08)

## BVH and field budgets

An illustrative triangle BVH with about two 32 B nodes/triangle costs about `64T` before triangle/source data. A dense FP32 SDF needs:

| Grid | Scalar distance only | Excluded extras |
|---|---:|---|
| 256³ | 64 MiB | Occupancy validity, gradient, construction scratch |
| 512³ | 512 MiB | Same |
| 1024³ | 4 GiB | Same |

A stored float3 gradient can add three times the scalar bytes. Sparse/narrow-band grids save memory only when active voxel topology, build scratch, boundary validity and deep-interior classification are represented honestly. A rigid collider transform reuses its asset-space field; changing geometry or resolution invalidates it. Uniform scale changes local clearance and world field error; one field cannot retain the same world error bound at arbitrary scale without requalification.

**P.** Budget before snapshot duplication and dispatch: shared sources/colliders, retained CPU poses, GPU poses, renderer meshes, display resources, copy staging, candidate/sort/solver scratch, queued generations and retirement leases all count. Use checked 64-bit multiplication and reject before overflow. Memory claimed by JIT modules, driver allocators, libraries and Max must be reported separately from exactly instrumented Cyrus allocation counters.

Windows exposes process-local video memory budget/usage through `IDXGIAdapter3::QueryVideoMemoryInfo`; exceeding the budget can lead to paging/stutter. This is a dynamic process budget, not dedicated capacity minus one plugin's allocations. Coordinate with Max/renderer use, retain a configurable reserve, recheck before large work, and treat allocation failure as possible even after admission. [R02](17_SOURCE_LEDGER.md#r02)

## Precision policy

**P.** Retain double world transforms, perform world-to-plant/collider rebasing in double, then upload bounded local float coordinates. Use FP64 CPU reference/ambiguous feature refinement. Initial GPU kernels use ordinary FP32, no blanket fast-math, explicit FMA policy, finite checks and normal/transform conditioning guards. FP16 is not the default for contacts or guide frames. Compression requires a separate error budget.

Computed FP32 spacing at positive powers/representative values is:

| Coordinate magnitude in metres | Next representable spacing |
|---:|---:|
| 1 | 0.1192 µm |
| 10 | 0.9537 µm |
| 32 | 3.8147 µm |
| 100 | 7.6294 µm |
| 10,000 | 0.9765625 mm |
| 1,000,000 | 62.5 mm |

**X.** The included check loses a 1 mm offset when both values near 1,000,000 m are cast to float before subtracting; subtracting in double before conversion preserves it to the reported small rounding error. Rebasing cannot recover precision already lost in source capture or a host transform. Probe actual Max source/transform types and source-local capture; do not promise that double downstream arithmetic repairs an already rounded scene.

FMA and evaluation order can change rounded answers even with IEEE arithmetic. Deterministic IDs, a fixed iteration count and sorted contacts do not imply mathematical correctness or CPU/GPU bitwise parity. Consumer, workstation and datacenter GPUs differ in FP64 throughput; do not infer it from memory size, price or AI TOPS. Measure the chosen precision kernel and keep exactness-sensitive work on the CPU where appropriate. [R01](17_SOURCE_LEDGER.md#r01)

## Proposed numerical gates

These are candidate **prototype quality profiles**, not claims that the current asset library meets them. Freeze per-fixture targets before tuning. A nominal 1 m synthetic ribbon profile uses:

| Invariant | Proposed threshold | Scope |
|---|---|---|
| Fixed CPU root/ring | Copy anchor values exactly; measured geometric drift ≤1 µm | GPU-delivered coordinates additionally include stated float conversion error |
| Parent/child attachment | ≤10 µm position; ≤0.1° relative orientation for a locked socket | Flexible socket rotation is a separate parameter |
| Surface penetration | Signed-distance penetration ≤20 µm; no proper edge/triangle crossings outside the explicitly classified tolerance band | Complete test including triangle interiors; crossing is a predicate, not a depth; uncertain predicates require refinement or failure |
| Contact-gap compliance | Clearance shortfall ≤20 µm | Gap added once; exact surface used for final acceptance |
| Guide edge strain | ≤0.5% for an explicitly inextensible synthetic profile | Not a universal limit on arbitrary triangulated leaf edges |
| CPU/GPU position parity | ≤20 µm per visible vertex | Also report max/p95 and image differences |
| Shading parity | ≤0.5° normal angle, tangent orthogonality residual ≤1e-4 | Same normal policy, not forced equality between different algorithms |
| Rest restoration | Default/rest source bytes on CPU; equivalent shader output within conversion tolerance | No accumulated warm-start bend |
| Frame continuity | No uncommanded sign flip; authored twist preserved | Source-specific curvature/angular sampling limits recorded |

The included R8 ribbon is 0.7 m tall, with eight nodes spaced 0.1 m apart. For its first proof use the same absolute thresholds above as an explicitly named near-metre profile; record this choice instead of pretending its height is 1 m. Scaling variants require their own frozen budgets.

**Combined clearance budget.** The 20 µm surface/gap threshold applies to the final delivered surface, not separately to each stage. If CPU validation permits a shortfall of `e_cpu` and the admitted shader/upload/transform deviation can move the surface by `e_delivery`, require `e_cpu + e_delivery ≤ 20 µm` (plus any separately unaccounted query/field error). For example, allocate 10 µm to validated CPU shortfall and 10 µm to delivery, or validate the actual delivered geometry. Passing independent 20 µm CPU-contact and 20 µm CPU/GPU-parity tests could otherwise permit 40 µm final shortfall. A bound on every corresponding vertex displacement bounds corresponding barycentric points of each unchanged triangle, but topology/sign ambiguities still require robust surface predicates. The numerical parity row is an upper ceiling, not an extra allowance outside this combined budget.

For other physical scales, derive tolerances from source length, minimum admitted feature radius, transform error and required clearance. A tolerance cannot be larger than the feature it is meant to protect. If a required tolerance is below the accumulated FP32/field error estimate, rebase more tightly, use higher precision/refinement, or mark unsupported. Do not merely increase epsilon until the GPU passes. The supplied 9.145% stem-edge observation is a separate S result, not a reason to call that source inextensible or to apply the synthetic 0.5% threshold retroactively.

Adversarial cases include parallel/coplanar triangles, grazing contact, a zero-length span, near-singular matrices, tiny geometry, NaNs and large coordinates. Uniform scale must be finite and positive; condition/physical-range admission is explicit. Nonuniform or mirrored transforms remain rejected until a separate qualified normal/distance/handedness contract exists.

## Hardware tiers to test, not purchase recommendations

| Documented representative device | Architecture / compute capability | Advertised memory | Why include it |
|---|---|---:|---|
| RTX 3060 | Ampere / 8.6 | 8 or 12 GB variants | Existing modest-capacity class; exact SKU matters |
| RTX 4070 / 4070 Ti SUPER | Ada / 8.9 | 12 / 16 GB | Midrange and constrained-memory comparison |
| RTX 5080 / 5090 | Blackwell / 12.0 | 16 / 32 GB | New architecture and higher-capacity consumer cases |
| RTX 6000 Ada | Ada / 8.9 | 48 GB | Capacity, professional deployment; not assumed special FP64 performance |
| RTX PRO 6000 Blackwell Workstation | Blackwell / 12.0 | 96 GB | Stress capacity reference, not required hardware |

Specifications are V, workload suitability is U. [R20](17_SOURCE_LEDGER.md#r20) [R21](17_SOURCE_LEDGER.md#r21) [R22](17_SOURCE_LEDGER.md#r22) [R23](17_SOURCE_LEDGER.md#r23) [R24](17_SOURCE_LEDGER.md#r24) [R25](17_SOURCE_LEDGER.md#r25) [R26](17_SOURCE_LEDGER.md#r26)

The table samples capacity/architecture tiers; it does not set the product minimum. CUDA 13's SM75/Turing compilation floor in [15](15_DISTRIBUTION_FALLBACK_AND_ARTIST_WORKFLOW.md) is a toolchain admission fact. Add an actual Turing device to the local matrix before claiming that generation is supported; compiling for it alone is insufficient qualification.

Choose a minimum from required kernels, compiler targets, exact toolkit/driver support, available device budget and validation. No ray-tracing core, tensor core, CUDA graph or latest GPU is intrinsically required for the first ribbon deformation. NVIDIA may become the **recommended acceleration platform** because of measured results and tooling; CPU remains a functional route on unsupported adapters. A separate CUDA GPU paired with an Intel/AMD display device needs explicit readback/copy routing and cannot inherit a same-adapter zero-copy assumption.

Sharing one GPU with GPU rendering can make a fast standalone solver slow or starved in Max. Benchmark viewport-only, active GPU render, multiple views and multi-monitor configurations. Reject all-active detailed populations that exceed admission arithmetic rather than extrapolating throughput indefinitely.
