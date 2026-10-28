# 16. Open Questions and Exact Probes for Local Engineering (`Codex`)

Per `RESEARCH_PROMPT.md` §14, we did not inspect the private Cyrus Scatter repository (`AminScatter/`, `CyrusVegetationLab/`) or local 3ds Max 2027 SDK installation headers. Below are **10 concrete, surgical probes (`P1`–`P10`)** for the local engineering team or local coding agent (`Codex`). Each probe states the **exact file/header to inspect**, the **specific command or check to run**, **why it matters**, and **which architectural decision it unblocks**.

---

## 1. Summary Table of Local Probes and Blocked Decisions

| Probe ID | Target Location (SDK Header or Local Repo File) | Exact Question to Answer | Blocked Decision / Gate |
|---|---|---|---|
| **P1** | `maxsdk/include/Graphics/IVirtualDevice.h`, `IDevice.h`, `VertexBufferHandle.h`, `TextureHandle.h` | Do any public methods in the 3ds Max 2027 SDK return a raw `ID3D11Device*`, `ID3D11Buffer*`, `ID3D11Texture2D*`, or `ID3D11ShaderResourceView*`, or accept an externally created shared texture/buffer? | **Gate 2 (Path F0 Zero-Copy Interop vs Path F1/F2 `Lock`/`Unlock` Upload).** Note: Path F1/F2 is already viable without P1! |
| **P2** | `maxsdk/include/Graphics/TextureHandle.h` & `HLSLMaterialHandle.h` | What exact `TargetFormat` enum values and `Lock` / `WriteOnlyLockRectangle` methods does `TextureHandle` expose in Max 2027 for `DXGI_FORMAT_R32G32B32A32_FLOAT` (`float4`) textures bound to a Vertex Shader via `SetTextureParameter`? | **Gate 2 (`Prototype P-2` Pose Palette Texture vs Secondary Vertex Stream).** |
| **P3** | `AminScatter/src/mesh_display.inc` & `AminScatter/src/point_display.cpp` | How does the current instanced draw path pass per-instance transforms (`Stream 1` vertex buffer vs `TextureHandle` vs constant buffer batching), and how does it currently draw posed/deformed instances vs rest instances? | **Gate 2 (Merging Posed + Rest Instances into One Instanced Draw Call).** |
| **P4** | `AminScatter/src/interactions_engine.cpp` & `AminScatter/include/interactions_engine.h` | Where exactly does the successor snapshot copy retained pose maps and root-count maps (`CURRENT_SYSTEM_CONTEXT.md` §CPU boundaries), and how many microseconds does that copy take in the `4.05 ms` baseline fixture and at $N = 100{,}000$? | **Gate 1 ($O(K)$ Generational / Copy-on-Write Snapshot Fix).** |
| **P5** | `AminScatter/src/interactions_source.cpp` & `CyrusVegetationLab/core/fitter/` | What is the exact sub-stage timing breakdown inside the observed `4.05 ms` run ($N=200, K=3$, 6 fitted guides, 62 hidden groups) between: (a) root classification (`Inside solid` / `Under collider`), (b) primary guide fitting, (c) visible-surface foliage refinement, and (d) CPU vertex deformation? | **Gate 1 & Gate 4 (Confirming whether Surface Refinement or Guide Fitting dominates CPU time).** |
| **P6** | `AminScatter/include/interactions_source.h` & `CyrusVegetationLab/experiments/stem-live/` | What is the exact vertex-to-guide binding representation (`single guide + segment + paramT` vs multi-guide skinning weights, and how is segment twist/up-vector parameterized)? | **Gate 2 (`VSMain_CyrusPosePull` Exact Math Parity with CPU Deformation).** |
| **P7** | `AminScatter/src/interactions_geometry.cpp` & `AminScatter/include/interactions_geometry.h` | What is the exact node layout of the CPU collider BVH (`AABB + child indices` struct size, leaf triangle count, and whether inside/outside occupancy uses ray parity, pseudonormals, or winding numbers)? | **Gate 4 (Zero-Rebuild Upload of Existing CPU Collider BVH to GPU).** |
| **P8** | `AminScatter/src/interactions_source.cpp` | How does the current CPU visible-surface refinement step detect and resolve broad-leaf penetrations when the guide centerline is clear (does it test all $22{,}032$ vertices/triangles or a reduced witness set, and does it adjust guide node positions, twist, or individual vertex offsets)? | **Gate 5 (GPU Stage 5 Foliage Surface Refinement Design).** |
| **P9** | `AminScatter/src/interactions_render.cpp` | How are deformed instances currently materialized for offline renderers (Arnold, V-Ray, Corona) and Bake—via `GeomObject::GetRenderMesh`, `MaxSDK::RenderTimeInstancing`, or per-instance custom render meshes? | **Gate 3 (On-Demand Renderer Materialization from `CompactPoseSnapshot`).** |
| **P10** | `AminScatter/src/interactions_host.cpp` & `AminScatter/tools/ui/templates/interactions-authoring.ms` | How does the host currently capture collider transform changes during interactive viewport dragging (`NotifyRefChanged` / `REDRAW_VIEWS` callback / timer), and is it strictly synchronous per mouse-move tick? | **Gate 6 (Hooking the 3-Slot Async Coordinator & Pointer-Move Coalescing).** |

---

## 2. Detailed Probe Instructions for Local Execution

### Probe P1 & P2: Inspect 3ds Max 2027 `MaxSDK::Graphics` Headers
- **Action:** Run the following search in the local Max 2027 SDK `include/Graphics/` directory:
  ```powershell
  Select-String -Path "$MaxSdkDir\include\Graphics\*.h" -Pattern "ID3D11|Native|GetDevice|Lock|SetTextureParameter|SetBufferParameter|TargetFormat|BufferUsage"
  ```
- **What to record:**
  1. The exact method signatures on `MaxSDK::Graphics::TextureHandle` (specifically `Initialize`, `Lock` / `WriteOnlyLockRectangle`, and whether `TargetFormatR32G32B32A32Float` supports dynamic CPU writes).
  2. Whether `HLSLMaterialHandle` supports `SetBufferParameter` (binding a `Buffer` SRV to a vertex shader) in addition to `SetTextureParameter`.
  3. Whether any class in `MaxSDK::Graphics` exposes an underlying `ID3D11Device*` or `ID3D11Resource*`.

### Probe P3: Inspect `AminScatter/src/mesh_display.inc` and `point_display.cpp`
- **Action:** Inspect the vertex stream format (`MaterialRequiredStreams`) and HLSL vertex shader in `AminScatter/src/mesh_display.inc`, and check how `PointDisplay` currently handles instances whose `interactions_source` pose is non-rest.
- **Why it matters:** If `point_display.cpp` currently extracts a separate unique `Mesh` or separate `VertexBufferHandle` for each posed plant, replacing that with a single shared-source `VertexBufferHandle` + per-instance `poseHeaderTexelOffset` attribute in the instance stream will immediately unify rest and posed drawing into a single instanced draw call.

### Probe P4 & P5: Micro-Timestamp the `4.05 ms` Baseline Fixture (`0.87.4.3`)
- **Action:** In `AminScatter/src/interactions_engine.cpp` and `AminScatter/src/interactions_source.cpp`, place five `std::chrono::steady_clock` timestamps around the `200 plants + 1 collider` test fixture (`3 nearby candidates, 6 fitted guides, 62 hidden groups`):
  - `T1`: Old/new spatial index query (`interactions_engine.cpp`),
  - `T2`: Successor retained pose-map / root-count map copy (`interactions_engine.cpp`),
  - `T3`: Root exclusion (`Inside solid` / `Under collider` on $3 \times 451$ groups),
  - `T4`: Primary guide fitting ($6$ guides),
  - `T5`: Visible-surface foliage refinement & mesh deformation (`22,032` vertices / `27,501` triangles).
- **Why it matters:**
  - If `T5` (surface check + mesh deformation of $22{,}032$ vertices) accounts for $>70\%$ of the `4.05 ms` runtime, then **Gate 2 (SM5 Vertex Shader Deformation) + precomputed foliage envelope radii** will eliminate the majority of the cost even before Gate 4!
  - If `T2` (successor map copying) grows linearly with $N$ or $K_{\text{retained}}$, fixing `T2` in Gate 1 is mandatory before any GPU benchmark is meaningful.

### Probe P6, P7 & P8: Extract Exact Mathematical Contracts for Single-Source `fit_core.h`
- **Action:** Inspect:
  1. `AminScatter/include/interactions_source.h`: exact struct fields of prepared guide nodes, parent-child bindings, and foliage vertex bindings.
  2. `AminScatter/src/interactions_geometry.cpp`: exact inside/outside test and closest-point query used on closed collider meshes.
  3. `AminScatter/src/interactions_source.cpp`: exact objective/projection loop used to fit guides and refine visible surfaces.
- **Why it matters:** Allows translating the production CPU fitter's inner loop line-for-line into a shared `__host__ __device__` header so the CUDA kernel and CPU fallback execute the **exact same algorithm**.
