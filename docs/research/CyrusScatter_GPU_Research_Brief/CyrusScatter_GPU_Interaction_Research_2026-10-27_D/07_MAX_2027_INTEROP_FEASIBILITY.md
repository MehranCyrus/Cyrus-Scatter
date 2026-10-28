<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 07 — Max 2027 interoperability feasibility

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Feasibility conclusion

**[U] Direct compute-to-Nitrous resource interoperability is not established by the public evidence reviewed.**

The verified public Max SDK pages show:

- **[V]** `ICustomRenderItem` with separate realization, display and hit-test phases **[S04]**;
- **[V]** `DrawContext::GetVirtualDevice()`, with documentation warning clients not to store the virtual device **[S07]**;
- **[V]** `IVirtualDevice` retained vertex/index stream handling, instanced draw, output streams and UAV target binding/clear operations **[S05]**;
- **[V]** `HLSLMaterialHandle` custom shader sources, typed parameter setters and a buffer parameter using a graphics handle **[S06]**.

The inspected pages do **not** document:

- an `ID3D11Device*` or `ID3D11DeviceContext*` accessor;
- a general compute-shader dispatch method;
- conversion from Max graphics handles to native D3D resources;
- supported CUDA/OpenCL registration of Max-owned buffers;
- ownership/fence rules for a third-party compute runtime writing those buffers.

This negative result is scoped: absence from the inspected pages is not proof that no supported 2027 interface exists. It makes the installed SDK header/sample probe mandatory.

## Why standalone interop evidence is insufficient

### CUDA D3D11

**[V]** CUDA exposes D3D11 resource registration/external-resource examples. NVIDIA's sample creates its own `ID3D11Device`, buffers/textures and synchronization objects, registers or imports those native resources, maps/writes them, then returns ownership for D3D rendering. **[S10, S14]**

### OpenCL D3D11

**[V]** `cl_khr_d3d11_sharing` requires a context associated with an actual `ID3D11Device*`, wraps actual `ID3D11Buffer`/texture objects, and requires explicit acquire/release before OpenCL and D3D use. **[S21–S22]**

### Max

**[P]** The current Cyrus viewport uses public retained handles and custom HLSL, and does not introduce a raw Direct3D device. Therefore:

```text
CUDA/OpenCL can interoperate with D3D11 resources
            ≠
Max 2027 publicly exposes compatible resources and ownership
```

## Feasible data paths

### Path M1 — supported Max HLSL material and pose buffer

```text
CPU solver → compact pose buffer → Max graphics handle → HLSL vertex deformation
```

- Lowest integration risk.
- No CUDA/OpenCL dependency.
- Requires proving buffer creation/update/indexing/capacity and lifecycle through public Max APIs.
- CPU canonical materialization remains renderer/Bake truth.

**Recommendation:** first proof.

### Path M2 — GPU solver with compact pose readback

```text
CUDA/OpenCL solver → D2H compact changed-guide poses → Max supported graphics upload → HLSL draw
```

- Does not require sharing Max resources with compute.
- Readback volume is proportional to changed guides, not vertices.
- Adds one completed readback and CPU publication step.
- Often the best fallback if fitting is expensive and direct sharing is unavailable.

### Path M3 — CPU solver plus compute-written separate application-owned resource

```text
CPU pose → application-owned D3D/CUDA/OpenCL resource → import/copy to Max supported handle
```

- Requires a documented import/copy API. None was verified publicly.
- A CPU copy or staging upload may erase the expected benefit.

### Path M4 — direct compute write into Max-owned buffer

```text
CUDA/OpenCL/D3D compute → Max render buffer → Nitrous draw
```

- Best theoretical transfer path.
- Highest ownership/device/synchronization risk.
- Forbidden until the installed SDK proves a supported route and the host tolerates device recreation, multiple viewports and render-GPU contention.

### Path M5 — unique CPU materialization

```text
CPU solver/evaluator → deformed CPU meshes → current supported viewport/render paths
```

- Existing-style fallback and correctness reference.
- Expensive at large `K×V` but fully independent of graphics interop.

## Public API probe checklist

The local engineer must search the installed Max 2027 SDK—not online snippets—for exact declarations and supported samples.

| Probe | Exact question | Pass evidence | Decision impact |
|---|---|---|---|
| graphics buffer creation | Can plugin code allocate structured/raw buffers with arbitrary element layout through public SDK? | compiling minimal plugin + documented methods | required for M1 |
| HLSL buffer binding | Can `HLSLMaterialHandle::SetBufferParameter` bind the created buffer in VS for instanced draws? | two-instance differing-pose render | required for M1 |
| update semantics | Can a subrange be updated without replacing immutable source buffers? | upload counters and buffer identity | drag latency and pooling |
| UAV/stream output | Can public interfaces write to/reuse a buffer in later draw? | official sample or supported plugin proof | may enable D3D-only compute-like path |
| compute dispatch | Is any public 2027 API documented for compute shader dispatch? | header + official documentation/sample | decides D3D compute path |
| native resource/device | Is there a supported native D3D resource/device accessor? | explicit public method and ownership documentation | decides direct CUDA/OpenCL sharing |
| synchronization | What fence/map/unmap rules apply between plugin updates and Nitrous draws? | official contract and fault-tested proof | required for M4 |
| adapter identity | Can the viewport adapter LUID be obtained publicly? | API and same-adapter test | multi-GPU safety |
| device recreation | What notification invalidates handles? | documented callback/lifecycle sample | recovery |

## Four-stage interop proof

### Gate I0 — standalone compute

**Input:** compact source/pose fixture.  
**Action:** evaluate deformation in CUDA/OpenCL/D3D compute without Max.  
**Pass:** numerical tolerances, memory/error handling, no performance claim needed.  
**Purpose:** isolate kernels and buffer schema.

### Gate I1 — standalone D3D11 sharing

**Input:** application-created D3D11 buffer on the intended adapter.  
**Action:** CUDA registration or OpenCL D3D11 acquire/write/release; D3D draw; adapter/LUID mismatch case.  
**Pass:** correct output, explicit synchronization, device-loss recovery.  
**Purpose:** proves vendor APIs, not Max.

### Gate I2 — supported in-Max proof

**Input:** installed Max 2027 SDK sample plugin and two prepared instances.  
**Action:** public-only buffer/HLSL path; then optional native-resource path only if explicitly supported. Test mixed viewports, F3, resize, device recreation, unload/reload.  
**Pass:** no private casts; correct output; no stale draw; no crash/resource leak; documented ownership.  
**Purpose:** decisive feasibility gate.

### Gate I3 — renderer/Bake/export

**Input:** same pose generation.  
**Action:** viewport display, selected production renderer, Max Bake and export/materialization.  
**Pass:** topology/UV/material/normal/bounds and vertex positions agree within declared tolerances.  
**Purpose:** prevents viewport-only feature delivery.

## Adapter/device identity

A robust implementation must explicitly handle:

- single NVIDIA GPU doing Max display, compute and GPU rendering;
- Intel/AMD display adapter with separate NVIDIA CUDA adapter;
- laptops with hybrid graphics/Optimus;
- multiple NVIDIA GPUs and multiple monitors;
- headless/remote desktop sessions;
- renderer selecting a different GPU than the viewport.

**[R]** Direct sharing is allowed only when the graphics and compute resources are on the same compatible adapter and the documented API confirms it. Otherwise use compact pose transfer through host memory. Never silently copy across adapters while claiming zero-copy.

## Ownership and synchronization rules

For any direct-share design, document a state machine such as:

```text
Nitrous-owned/readable
  → host-approved release/acquire
  → compute-owned/writable
  → compute fence complete
  → release to graphics
  → Nitrous-owned/readable
```

Concurrent unsynchronized compute and draw access is forbidden. Max handle lifetime, CUDA/OpenCL registration lifetime and scene/request generation are separate lifetimes.

## Renderer and Bake implications

- Viewport buffers are not automatically Arnold, V-Ray, Corona or exporter geometry.
- A renderer may request mesh data on a host thread and may have its own instancing/proxy contracts.
- Final pose must be materializable without reading private viewport resources.
- GPU rendering can contend for VRAM/compute on the same device and change latency distributions.
- Renderer qualification is per selected renderer/version; public generic Max mesh delivery is the initial fallback.

## Go/no-go rules

### Continue to HLSL pose deformation when

- M1 public buffer/HLSL proof passes;
- bounds and picking have a supported CPU path;
- same pose materializes for render/Bake;
- device recreation and fallback pass.

### Continue to direct compute sharing when

- a public documented native resource/device path exists;
- same-adapter identity and synchronization are proven;
- resource lifetime survives viewport/device events;
- the measured copy avoided is material to latency.

### Stop direct sharing when

- it requires private headers, COM downcasts, undocumented pointers or taking ownership of Nitrous;
- Max cannot guarantee resource/fence lifetime;
- multi-adapter or device-loss recovery is unsafe;
- compact readback/upload performs sufficiently well.

## Concrete fallback cost model

Let a changed guide pose be 48 bytes and `A_g` be changed guides:

```text
pose readback bytes ≈ 48 A_g + headers + hidden masks
full mesh readback bytes ≈ 24 K V  (position+normal lower bound)
```

For the supplied source, six changed guides are only 288 bytes before headers, while one full position+normal mesh is about 0.504 MiB. This difference makes compact pose readback a credible fallback even when zero-copy is unavailable.
