# 12 — Papers and reusable implementations

[Index](00_README.md) · [Decision](01_EXECUTIVE_DECISION.md) · [Source ledger](17_SOURCE_LEDGER.md)

**Researcher A • 27 October 2026.** This chapter records public evidence and a reuse decision. No listed library was built, executed, benchmarked, integrated with Max, or licensed for a Cyrus release in this research environment. A visible repository license is evidence of stated terms; production adoption still requires checking the exact selected files, notices, dependencies and binary distribution.

## 1. Adoption recommendation

**Proposed:** use original papers to specify a small bounded static algorithm; use existing libraries to accelerate a **standalone numerical prototype** where that saves time; retain ownership of Cyrus's source/preparation contract, contact completeness, visible-surface verification and host publication. Avoid bringing a whole dynamic hair or rigid-body engine into the first experiment. A library is valuable only if its integration, correctness qualification and maintenance cost is lower than implementing the narrow missing primitive.

The most immediately useful reusable pieces are scan/sort primitives covered in [04](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md), a query backend such as Warp or a native CUDA BVH library, and small constraint/frame formulas with independently verified fixtures. GPU wind and guide-follow examples are good deformation/scheduling references but do not establish contact correctness.

## 2. Original research: what transfers and what does not

| Work, date and precise location | Transferable idea | Limitation / reuse decision | Performance evidence treatment |
|---|---|---|---|
| Müller et al., *Position Based Dynamics*, VRIPHYS 2006 author PDF; journal version 2007, solver/projection section [COL01](17_SOURCE_LEDGER.md#col01) | Direct position corrections and fixed particles | Reimplement selected local projections with current Cyrus invariants. A finite PBD pass is not exact simultaneous feasibility | No original timing imported as a Cyrus estimate |
| Macklin et al., *XPBD*, MIG, 10 Oct 2016, §4 and Eq.18 [COL02](17_SOURCE_LEDGER.md#col02) | Compliance and multiplier accumulation derived from elastic energies | Dynamic time-step derivation; explicit static objective is needed for this product. Finite iteration residual remains | No claim that stiffness wording guarantees complete convergence at any iteration count |
| Bergou et al., *Discrete Elastic Rods*, TOG 27(3), Aug 2008, framed-curve/parallel-transport and constraint sections [COL03](17_SOURCE_LEDGER.md#col03) | Rest curvature, twist, material frame and inextensibility | Original model has dynamic centerline and quasistatic twist; not a GPU forest/contact/binding package | Quantitative paper validation supports model design, not Max latency |
| Kugelstadt & Schömer, *Position and Orientation Based Cosserat Rods*, SCA 2016, §6, stretch/shear Eq.37 and bend/twist Eq.40 [COL04](17_SOURCE_LEDGER.md#col04) | Quaternion and position correction operators | Reimplement or audit isolated formulas; normalization, branch topology, finite rotation convention and contact remain | Paper relative-speed claim is not transferred to Cyrus |
| Deul et al., *Direct Position-Based Solver for Stiff Rods*, CGF 37(6), 2018, Newton/direct tree solve [COL05](17_SOURCE_LEDGER.md#col05) | Solve acyclic coupled rod structure rather than propagating corrections one edge per pass | Comparator for long or branched assets; active contacts and Max delivery remain outside the structural solve | No use of paper's speedup ratio in architecture scoring |
| Bouaziz et al., *Projective Dynamics*, TOG 33(4), 2014, local/global energy minimization [COL06](17_SOURCE_LEDGER.md#col06) | Factorizable structural system with local projection steps | More promising when many instances share topology and weights; changed constraints can invalidate reusable numerical structure | Original scene DoF/iteration timings are not our workload |
| Macklin et al., *Unified Particle Physics for Real-Time Applications*, TOG 33(4), 27 Jul 2014, §4 parallel SOR [COL09](17_SOURCE_LEDGER.md#col09) | Constraint averaging, gather/scatter and parallel particle decomposition | Particle proxy and fixed-radius assumptions differ from full-width rooted plants | Do not equate particle count to blades, clumps or triangles |
| Müller et al., *Fast Simulation of Inextensible Hair and Fur*, VRIPHYS 2012, follow-the-leader construction [COL10](17_SOURCE_LEDGER.md#col10) | Efficient length restoration along rooted chains | Useful operator/initial guess; does not certify multiple-obstacle and broad-leaf contact after the length pass | One-iteration hair inextensibility claim is not an all-constraints plant guarantee |
| Macklin et al., *Small Steps in Physics Simulation*, SCA, 26–28 Jul 2019 [COL11](17_SOURCE_LEDGER.md#col11) | Dynamic substeps can improve error versus many iterations of one large step | Reserve for future Animate/dynamic study. Current fresh-rest static fit has no physical visual step to subdivide | Do not import the cloth figure's frame timings |
| Macklin et al., *Local Optimization for Robust Signed Distance Field Collision*, 2020, continuous element search [COL07](17_SOURCE_LEDGER.md#col07) | Search edges/faces against a field rather than testing vertices only | Reimplement bounded search with a declared completeness/error policy. Local optimization alone may miss other minima | No claim of universal exact distance or global guarantee |
| Karras, *Maximizing Parallelism in Construction of BVHs, Octrees and k-d Trees*, HPG 2012, §4 [COL08](17_SOURCE_LEDGER.md#col08) | Morton sorting, binary radix tree and parallel bottom-up bounds | Consider only after profiling rebuilding/refitting at actual change rate. Stable IDs resolve duplicate-key ordering | Paper used CUDA 4.0, GTX 480, 2.8 GHz Core i7, Windows 7 and 30-bit Morton keys; historical conditions, not a present benchmark |
| Li et al., *Incremental Potential Contact*, SIGGRAPH 2020 [COL12](17_SOURCE_LEDGER.md#col12) | Barrier/contact accuracy and collision-safe trajectory methodology | Correctness reference; not a small static initial-penetration fitter. Assumptions and complete CCD are essential to claimed guarantees | No throughput copied; all Cyrus claims await tests |
| Wang et al., *Computation of Rotation Minimizing Frames*, TOG 27(1), March 2008 [COL13](17_SOURCE_LEDGER.md#col13) | Stable frame transport through zero-curvature regions | Reimplement transport with explicit degeneracy handling and retained authored twist | Hosting path 2016 does not change publication date |
| Zioma, *GPU-Generated Procedural Wind Animations for Trees*, GPU Gems 3, 2007, §§6.2–6.3 [COL14](17_SOURCE_LEDGER.md#col14) | Shader deformation and hierarchy/instance economy | Phenomenological wind; useful draw-path pattern, not collision solving or proof of leaf clearance | No old graphics throughput extrapolation |

The paper licenses generally permit reading and citation, not indiscriminate bundling of paper PDFs, sample assets or unrelated source. No third-party source tree, paper PDF or proprietary asset is included in this return archive.

## 3. Repository/version register and inspection limits

“Pin verified” means the full commit was observed in a primary repository page. It does not mean all files at that commit were fetched. “Rolling source inspected” means the named public file body was readable, but a matching immutable checkout was not obtained. These distinctions prevent a version label from standing in for a source audit.

| Candidate | Verified version/pin and exact inspected location | License/dependencies observed | Proposed adoption and remaining qualification |
|---|---|---|---|
| NVIDIA Warp | v1.18.0 release 5 Oct 2026, `f2eaed82d8d03b37bf1014cc975954067fefcf16`; release/config/version diff. v1.17.0 spatial-query introduction at `f4c57f26f1e3936a89afd283e39fcabf6d548dc7`. Generated capsule/winding query docs and C++ workflow docs inspected; `warp/native/mesh.h` and `bvh.h` exact-tag bodies were not retrievable here [COL15–19](17_SOURCE_LEDGER.md#col15), [COL37](17_SOURCE_LEDGER.md#col37) | Apache 2.0 for Warp; README separately identifies libmathdx under NVIDIA terms and other dependencies. Python 3.10+ authoring; default 1.18 Linux/Windows wheels use CUDA 13.4, R580+, Turing+; `+cu12` wheels alternative | Strong numerical-prototype candidate. Native delivery possible through documented AOT routes; do not mandate embedded Python. Audit selected generated/native dependencies and frozen versions before production |
| AMD TressFX standalone | Public latest release 4.1.0, 24 Jan 2020, `ba0bdacdfb964e38522fda812bf23169bc5fa603`. Current `src/Shaders/TressFXSimulation.hlsl` body inspected; release tree lists that path and `src/TressFX/TressFXSDFCollision.cpp`, but exact-tag shader equivalence was not established [COL20–25](17_SOURCE_LEDGER.md#col20), [COL41](17_SOURCE_LEDGER.md#col41) | MIT declared by AMD; inspected shader carries permissive notice. Cauldron, DX12/Vulkan, DXC and sample dependencies; 4.1 sample historically VS 2017/2019, SM6 | Reuse scheduling ideas or isolated audited code. Do not import sample renderer, history-based dynamics, first-two-vertex pinning or point-based contact as Cyrus semantics |
| AMD TressFX 5.0 UE patches | AMD current page distinguishes UE 4.26/4.27 and UE 5.4 variants. Access requires registered Unreal developer repository access; patch code/commit not inspected [COL24](17_SOURCE_LEDGER.md#col24) | Separate Unreal patch/code/access terms; not established by standalone MIT alone | Useful maintained product lead; not an available drop-in native Max dependency |
| Jolt Physics GPU hair | Public 5.6.0, 11 Jul 2026, `e77f175595e64cb44218cc9d9d56fc365ad0e36a`; release and version commit inspected. Hair header/source body not retrieved [COL26–27](17_SOURCE_LEDGER.md#col26), [COL40](17_SOURCE_LEDGER.md#col40) | Public Jolt project MIT; GPU interface DX12/Vulkan/Metal/CPU-compute options documented in release | Experimental comparator only. Hair collision supports hulls/compounds, guide/follow hairs and velocity-grid hair interaction. This study did not inspect any private PhysicsLab pin |
| PhysX | Version-qualified 5.6.1 GPU Simulation documentation inspected, including `PxSceneFlag::eENABLE_GPU_DYNAMICS`, `PxBroadPhaseType::eGPU`, context manager and DirectGPUAPI [COL28](17_SOURCE_LEDGER.md#col28) | Full selected source/binary dependency license not audited in this chapter | API capability evidence only; no whole-engine adoption recommendation. GPU rigid-body support is not a prepared vegetation contract |
| PositionBasedDynamics | Rolling `PositionBasedDynamics/PositionBasedElasticRods.h` declaration body, README and LICENSE inspected. Exact master commit could not be resolved through available retrieval; pin remains **unresolved** [COL29–30](17_SOURCE_LEDGER.md#col29), [COL39](17_SOURCE_LEDGER.md#col39) | MIT; Eigen, JSON, pybind, Discregrid and demo-only dependencies listed. Upstream README tests old toolchains, not Max 2027 | Useful CPU numerical reference; no direct CUDA recompilation claim. Freeze commit and isolate rod routines before reuse; whole project not production-approved |
| OpenVDB/NanoVDB | Official docs list 13.2.0, 26 Oct 2026; generated `nanovdb/NanoVDB.h` body identifies 13.2.0. GitHub release index retrieved still lists 13.1.0, 16 Sep 2026 at `e26f5a569201d3236e0c30580572101022d3d754`; exact 13.2 release commit unavailable [COL31–34](17_SOURCE_LEDGER.md#col31), [COL38](17_SOURCE_LEDGER.md#col38) | Current root LICENSE and NanoVDB header Apache 2.0. Lightweight core separate from optional CUDA/IO/build tools | Candidate static collider-field container. Resolve current tag/pin before reuse; do not treat cached release index as proof 13.2 does not exist |
| NVIDIA cuBQL | Current README/API overview inspected; full latest commit and implementation file bodies not resolved [COL35](17_SOURCE_LEDGER.md#col35) | Apache 2.0 stated; mostly header-only CUDA/C++, with separate `3rdParty.txt` requiring audit | Promising native BVH alternative; remains an evaluation lead, not approved dependency. Local audit must pin commit and inspect traversal/stack/overflow semantics |
| Discregrid | Current README and `CubicLagrangeDiscreteGrid` usage inspected; exact commit/body not resolved [COL36](17_SOURCE_LEDGER.md#col36) | MIT declared; OpenMP/Eigen-based CPU field construction and TriangleMeshDistance components | Offline field/reference candidate; cubic interpolation requires its own error assessment. No claim that cubic samples obey the trilinear bound in 05 |

### Inspectable details that materially affect the decision

**Warp:** Capsule-BVH traversal enumerates candidates, while sphere–mesh queries have a triangle-level filter. Closed-solid sign queries need their own admission/result checks. Thus Warp reduces query infrastructure work but Cyrus still needs whole-segment narrow phase, all relevant contacts, root-conflict handling and complete visible-element validation. A direct C++ AOT route is documented: `warp/examples/cpp/00_cubin_launch` loads generated CUBIN through the CUDA Driver API; `01_source_include` includes generated CUDA. `warp/native/aot.h` supports generated types. Native APIs and graph formats have no cross-release compatibility guarantee; pin matching headers, modules and runtime. The external-compilation APIs are experimental. [COL17–19](17_SOURCE_LEDGER.md#col17), [COL37](17_SOURCE_LEDGER.md#col37)

**TressFX:** In the readable shader, `LocalShapeConstraints` iterates serially along each strand. `LengthConstriantsWindAndCollision`—including the upstream spelling—uses vertex-level work and alternating edge updates. `ResolveCapsuleCollisions` receives one current vertex and a prior position; it is not a whole-current-span query. `UpdateFollowHairVertices` offsets follow hairs from guides, which does not independently collide those follow hairs or a plant's broad polygon leaves. These are directly inspectable reasons to reuse the scheduling concepts while redesigning contact and visible geometry checks. [COL22](17_SOURCE_LEDGER.md#col22)

**PositionBasedDynamics:** The inspected rod header exposes `PositionBasedCosseratRods::solve_StretchShearConstraint` and `solve_BendTwistConstraint`, including endpoint inverse masses, quaternion weights, rest length and rest Darboux information. It also describes a tree node representation for the stiff-rod direct solver. The types contain Eigen and host containers; a GPU port is an algorithm/data-layout project, not a compiler switch. [COL30](17_SOURCE_LEDGER.md#col30)

**NanoVDB:** The inspected header documents a compact linearized grid, 32-byte buffer alignment and per-thread `ReadAccessor` requirements; accessors cache state and must not be shared across threads or copied CPU↔GPU. Current release notes also clarify that tools can build new grids with changed topology, despite older FAQ shorthand calling the core static. Immutable per-collider field snapshots fit this model. A field's compact container does not bound discretization/sign error. [COL33](17_SOURCE_LEDGER.md#col33), [COL31](17_SOURCE_LEDGER.md#col31), [COL38](17_SOURCE_LEDGER.md#col38)

## 4. What to reuse, reimplement and defer

| Component | Recommendation | Why / test needed |
|---|---|---|
| Scan, compaction, sorting and reductions | Reuse pinned vendor primitives where license/toolchain qualified | Mature infrastructure; verify deterministic key order, scratch sizes and asynchronous lifetime |
| CPU gold-standard fixture queries | Keep independent of GPU implementation | Shared code bugs must not make both answers look correct |
| Analytic sphere/box/capsule kernels | Reimplement small explicit formulas | Small enough to audit; test inside, tangent, whole-span and zero-length cases |
| Triangle BVH build/traversal | Evaluate Warp/native library before custom implementation | Significant engineering surface; exact narrow phase and completeness policy still owned by Cyrus |
| Rod projection/frame operators | Reimplement documented mathematics or copy narrowly with full notices | Fits prepared-source ABI; require positive controls, signs, rest-shape and length tests |
| Cubic/sparse field construction | Use a separate offline/prototype tool if beneficial | Avoid growing first runtime dependency set; validate error and rebuild rules |
| Dynamic hair engine integration | Defer | Wrong time/history semantics and renderer/asset assumptions for immediate static operation |
| Full IPC/large nonlinear solver | Keep as reference or later comparator | Larger implementation cost; useful if simple bounded methods cannot satisfy exact-contact requirements |
| Self-collision, wind, inertia and rigid settling | Out of immediate scope | Changes state, collision and lifecycle requirements; do not charge or credit them in present benchmark |

## 5. Reproducible source audit before adoption

**Proposed, not executed:** local engineers should create a small dependency evidence folder for each selected candidate. Record the upstream URL, full SHA/tag, retrieval date, exact file list, file hashes, license/NOTICE files, submodule SHAs, build dependencies, build flags and generated-code inputs. Use `git rev-parse HEAD` and `git submodule status --recursive` on the real checkout. Search the selected code for fixed stack sizes, unchecked append counters, unsupported transforms, float casts, normalized-zero gradients, atomics and implicit default-stream operations. Compile a standalone CPU/GPU query fixture before touching Max.

For Warp, additionally audit the 1.18 AOT examples, selected `warp/native/` headers and any libmathdx linkage. For TressFX, compare the retrieved release shader with the frozen checkout and inspect both `TressFXSimulation.hlsl` and `TressFXSDFCollision.hlsl`; the latter source body was unavailable in this research environment, so no hidden details are asserted. For PBD, freeze the previously unresolved master commit and inspect implementations corresponding to the verified header declarations. For NanoVDB, resolve 13.2's release/tag discrepancy and review the current IO overflow fix if serialized grids will ever be accepted. For cuBQL, inspect real builder/traversal source after pinning rather than relying on README promises.

No upstream reported speedup, frame time or maximum particle count enters the recommendation as measured Cyrus performance. The fair comparison remains the fixed-input, fixed-quality program in [10](10_BENCHMARK_AND_VALIDATION_PLAN.md).

## 6. CUDA, OpenCL primitives and sample source audit


The hashes below are **release commit identities verified through public release/commit pages**. They are not local checkout hashes. Local direct network retrieval was blocked; some GitHub pinned file views also failed. The ledger differentiates live source inspection, exact commit-diff inspection, release metadata, and unavailable file contents. Nothing here was compiled.

| Repository and proposed pin | Inspected scope and exact locations | Reuse decision and limits |
|---|---|---|
| NVIDIA CUDA samples, `v13.4`, `5443602d89ed99aede2e4b7bf329daddeadb320e` | Release commit/tree, current `README.md`, current `LICENSE`, `cpp/5_Domain_Specific/README.md`; documented directories `cpp/5_Domain_Specific/simpleD3D11`, `simpleD3D11Texture`, `simpleD3D12`, and `cpp/3_CUDA_Features/simpleCudaGraphs` | Standalone API proof references. Registration/external-memory behavior is grounded in API docs; full pinned sample implementation files were unavailable, so no line-by-line review or successful build is claimed. [API40](17_SOURCE_LEDGER.md#api40) [API41](17_SOURCE_LEDGER.md#api41) [API43](17_SOURCE_LEDGER.md#api43) |
| NVIDIA CCCL, `v3.4.3`, `5fb1013e3c6f72877a2ebd30f54fe5158d64eec4` | Release/commit, current README/LICENSE, and actual live `cub/cub/device/device_radix_sort.cuh` functions/documentation; pinned file retrieval unavailable | Reuse maintained scan/select/sort primitives after exact-pin build/validation. It supplies data-parallel infrastructure, not collision, root constraints or Max ownership. [API08](17_SOURCE_LEDGER.md#api08) [API09](17_SOURCE_LEDGER.md#api09) [API11](17_SOURCE_LEDGER.md#api11) [API50](17_SOURCE_LEDGER.md#api50) |
| Khronos OpenCL SDK, `v2026.05.29`, `e26922bdf54eaa9fcc31fe1f91d21b8d2bd6970f` | Release/commit and current README/build metadata; pinned sample implementations unavailable | Use the headers/loader/build organization and selected samples as API scaffolding. No inspected sample is asserted to be a production vegetation scan, solver or Max sharing path. [API44](17_SOURCE_LEDGER.md#api44) [API45](17_SOURCE_LEDGER.md#api45) [API46](17_SOURCE_LEDGER.md#api46) |
| Khronos OpenCL ICD Loader, `v2026.05.29`, `b7bd2803acc779c03d96588e9ca9e9568a18698a` | Current README plus **exact commit diff** in `loader/icd.c`, `loader/icd.h`, `loader/windows/icd_windows.c`, `loader/linux/icd_linux.c`, `loader/cllayerinfo.c` | Reuse official dispatch loader if a private loader is needed; it is not a vendor implementation or compiler. The exact Windows diff changes deinitialization to distinguish process termination from explicit library unload. This illustrates real lifetime code, not permission to unload a busy compute backend. [API47](17_SOURCE_LEDGER.md#api47) [API48](17_SOURCE_LEDGER.md#api48) [API49](17_SOURCE_LEDGER.md#api49) |

### What was learned from actual inspected code

**Live CUB radix-sort source:** `DeviceRadixSort::SortPairs` exposes scratch sizing and dispatch through stream/environment policy. The inspected stability, non-overlap and numeric rules inform the proposed contact-key pipeline in [04](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md). This observation applies to the retrieved live file, not automatically to every release. [API11](17_SOURCE_LEDGER.md#api11)

**Pinned ICD loader diff:** `khrIcdDeinitialize` gains an `unloadLibraries` argument; unloading vendor/layer libraries is conditional on it. Windows `DllMain` passes the decision derived from its reserved pointer on process detach. The source demonstrates why runtime lifetime handling must be designed alongside plugin lifecycle. It does not eliminate Cyrus's need to retire events, resources and worker callbacks before explicit shutdown. [API48](17_SOURCE_LEDGER.md#api48)

**Limits:** direct read attempts for the full pinned CUDA D3D sample, pinned CUB file and SDK sample implementations did not succeed. Release documentation and live code are sufficient to choose a prototype lead but insufficient for a source audit or license sign-off of those exact implementations. Do not cite inaccessible lines or report “tested sample.”

### License and maintenance observations

CUDA samples' live license is BSD 3-Clause and points to CUDA licensing; the current README expressly cautions that samples are not a performance-validation suite. CCCL's live license inventory distinguishes CUB BSD terms, Thrust Apache terms with exceptions, libcu++ Apache/LLVM exceptions and additional third-party licenses. OpenCL SDK/loader metadata identifies Apache-2.0, with dependency licenses still requiring inventory. Preserve exact-checkout notices and inspect file-level licenses when incorporating code. [API40](17_SOURCE_LEDGER.md#api40) [API42](17_SOURCE_LEDGER.md#api42) [API10](17_SOURCE_LEDGER.md#api10) [API46](17_SOURCE_LEDGER.md#api46) [API47](17_SOURCE_LEDGER.md#api47)

All four have 2026 release evidence. That establishes recent public activity, not response-time guarantees or freedom from bugs. Freeze tested versions; do not track `main` in a shipping plugin. Update by rerunning numerical, lifetime, deployment and performance gates. The moving CUB source viewed for this report is explicitly not the shipping pin.

### Reproducible local source follow-up — not executed here

Run the following in a disposable review folder with network access. Commands intentionally stop after inspection setup; they do not install anything into Max or vendor files into the production tree.

```sh
git clone https://github.com/NVIDIA/cuda-samples.git cuda-samples-review
git -C cuda-samples-review checkout --detach 5443602d89ed99aede2e4b7bf329daddeadb320e
git -C cuda-samples-review rev-parse HEAD
git -C cuda-samples-review ls-tree -r --name-only HEAD cpp/5_Domain_Specific/simpleD3D11
git -C cuda-samples-review ls-tree -r --name-only HEAD cpp/3_CUDA_Features/simpleCudaGraphs

git clone https://github.com/NVIDIA/cccl.git cccl-review
git -C cccl-review checkout --detach 5fb1013e3c6f72877a2ebd30f54fe5158d64eec4
git -C cccl-review rev-parse HEAD
git -C cccl-review show HEAD:cub/cub/device/device_radix_sort.cuh
git -C cccl-review show HEAD:LICENSE

git clone https://github.com/KhronosGroup/OpenCL-SDK.git opencl-sdk-review
git -C opencl-sdk-review checkout --detach e26922bdf54eaa9fcc31fe1f91d21b8d2bd6970f
git -C opencl-sdk-review rev-parse HEAD
git -C opencl-sdk-review submodule status --recursive

git clone https://github.com/KhronosGroup/OpenCL-ICD-Loader.git opencl-loader-review
git -C opencl-loader-review checkout --detach b7bd2803acc779c03d96588e9ca9e9568a18698a
git -C opencl-loader-review show HEAD:loader/windows/icd_windows.c
```

After reading each pinned README/CMake/license, record recursive submodule identities and choose supported build commands for the exact installed compiler. Build and run a standalone numerical/interop smoke test before a Max test. Archive source file hashes, compiler output and result logs. Never turn a failed retrieval in this report into an assertion that the repository lacks the feature.

