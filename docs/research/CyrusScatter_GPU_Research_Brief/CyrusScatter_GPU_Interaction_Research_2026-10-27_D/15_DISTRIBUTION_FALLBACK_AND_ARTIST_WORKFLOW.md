<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 15 — Distribution, fallback and artist workflow

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed in [17_SOURCE_LEDGER.md](17_SOURCE_LEDGER.md).
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Distribution principle

GPU acceleration is optional. The core plugin, saved scene and CPU result path must load and function when CUDA, an OpenCL platform, a supported GPU or a compatible graphics-sharing path is absent.

## Backend packaging

### Recommended module split

```text
CyrusScatter core/plugin
  ├─ CPU reference and canonical evaluator (required)
  ├─ Max viewport HLSL path (matched host package)
  ├─ optional CUDA backend DLL
  └─ optional OpenCL backend DLL / ICD discovery
```

The core must not have an unconditional loader-time dependency on CUDA/OpenCL DLLs. Use a versioned optional backend interface and dynamic discovery. A backend failure becomes a capability status, not a plugin load failure.

### Capability handshake

```cpp
struct GpuBackendCapabilities {
    uint32_t abi_version;
    BackendKind kind;
    uint32_t device_count;
    FeatureBits features;
    PrecisionBits precision;
    InteropBits interop;
    char driver_version[64];
    char runtime_version[64];
};
```

The core checks ABI, evaluator/schema version, required features and device identity before any scene data is uploaded.

## CUDA runtime/toolkit considerations

**[V]** NVIDIA's toolkit EULA distinguishes redistributable components and development tools. **[S13]** The release process must use the toolkit's current redistributables list and conditions rather than copying arbitrary DLLs. The exact production toolkit should be pinned and tested with the Max 2027 compiler/CRT package.

Policy:

- compile kernels AOT for selected supported architectures plus a documented forward/JIT strategy if needed;
- detect driver/runtime compatibility before backend activation;
- do not require NVCC or developer tools on artist machines;
- record toolkit, driver, GPU architecture and kernel revision in diagnostics;
- keep license/notice files and installer entries reviewed by legal/release engineering.

## OpenCL runtime considerations

- The Khronos ICD loader can be shipped/reviewed separately, but a vendor OpenCL platform/runtime is still required.
- Enumerate platforms/devices and query every optional feature used.
- Treat `cl_khr_d3d11_sharing`, command buffers, mutable dispatch, subgroups and FP64 as optional.
- Build a portable baseline kernel variant; do not fail plugin startup if no platform exists.
- Record vendor/device/driver/OpenCL C/version/extensions in diagnostics.

## Shader/kernel compilation and caches

### Cache key

```text
backend ABI
+ kernel/evaluator source hash
+ compile options/quality/precision
+ device vendor and architecture
+ driver/runtime/compiler version
+ Max graphics device generation for host resources
```

### Cache rules

- use one program per feature/quality set, not per instance;
- atomically write cache files and validate hashes before load;
- bound disk size and age;
- invalidate after incompatible driver/runtime/kernel/schema change;
- report cold compile separately from warm use;
- a broken cache falls back to recompile or CPU, never scene failure;
- no device pointer or transient graphics handle is serialized in the scene.

## Installer and loading

Local release checks:

- plugin and optional DLL signatures;
- secure DLL search paths and versioned names;
- CPU-only clean machine;
- CUDA driver but no toolkit runtime package;
- OpenCL loader but no platform;
- unsupported/old driver;
- multiple installed backend versions;
- uninstall/repair and side-by-side matched Max packages;
- headless command-line/render node behavior;
- remote desktop and service accounts.

## Fallback ladder

1. **Exact CPU reference + current/CPU materialization.** Always available for admitted sources.
2. **CPU fit + HLSL shared-source deformation.** Preferred acceleration if Max proof passes.
3. **GPU fit + compact pose readback + HLSL/CPU delivery.** Safe optional solver path.
4. **Direct GPU sharing.** Only after public interop proof.
5. **Interactive proxy tier.** Explicit status; final Update must refine exactly.

Fallback preserves source, placements, roots, pose semantics and last complete publication. It may be slower; it must not silently reduce quality unless the artist selected an approximate mode.

## Artist workflow

### Preparation

1. Select a vegetation source and run/inspect **Prepare**.
2. Cyrus reports guides, roots, parent attachments, envelope coverage and unsupported geometry.
3. Artist corrects ambiguous roots/roles/guides/envelopes at source level.
4. Preparation is stored by immutable source fingerprint/revision and reused by all placements.

### Interaction setup

1. Enable **React to Colliders** on the receiving layer/source policy.
2. Pick scene objects or another Scatter layer as collider owners.
3. Set meaningful controls only:
   - Contact gap;
   - Hide mode and Hide margin;
   - root orientation mode;
   - flexibility/shape preservation;
   - maximum bend/strain;
   - quality: Interactive / Final;
   - work/memory budget;
   - Manual or Live.
4. Optional backend preference remains in diagnostics/advanced settings, not the primary artistic workflow.

### Move a collider

- **Manual:** old result remains; layer shows `Pending`; Update runs the latest edit.
- **Live:** relevant transform events are coalesced; newest complete result publishes.
- old/new neighborhoods restore plants the collider left behind;
- camera, selection and wireframe changes do not recompute;
- failure keeps the last complete result and marks affected plants/unresolved contacts.

### Update

`Update` means:

1. capture the newest valid owned snapshots;
2. query affected old/new neighborhoods;
3. classify roots/hiding;
4. fit and validate;
5. publish a complete pose generation;
6. update viewport buffers/bounds;
7. retain CPU materialization capability for renderer/Bake.

It does **not** apply unrelated pending scatter population edits unless the existing product contract explicitly says so.

### Reset deformation

Remove retained interaction poses/hidden masks for the selected owner and restore rest geometry without regenerating placement IDs. If a live collider still intersects, the next relevant Live solve may reapply a pose.

## Minimal UI

### Main rollout

- `Enable interaction`
- `Colliders...`
- `Contact gap`
- `Hide mode: None / Inside solid / Under collider / Margin`
- `Hide margin`
- `Root orientation: Free / Soft / Clamped`
- `Flexibility`
- `Shape preservation`
- `Maximum bend/strain`
- `Quality: Interactive / Final`
- `Update` / `Reset`
- `Manual / Live`
- status line: `Ready / Pending / Solving / Approximate / Unresolved / CPU fallback`

### Diagnostic overlay

- affected plants/rooted groups;
- active guides and envelope width;
- collider witnesses/normals;
- hidden groups;
- unresolved exact versus conservative contacts;
- backend, active counts, transferred bytes and fallback reason;
- last complete result and current pending request serial.

Do not expose workgroup sizes, solver colors or kernel compilation options to ordinary artists.

## Artist-facing failures

| Failure | Message/action |
|---|---|
| root fixed inside stone | “Root cannot move and is outside the selected hide region.” Offer enlarge hide region/change obstacle/disable source group. |
| narrow infeasible gap | show both colliders, required and available clearance; keep old result |
| source envelope invalid | return to Prepare and highlight offending vertices/guide |
| source unsupported transform | identify nonuniform/mirror/shear and require collapse/approved preprocessing |
| over work/VRAM budget | report active counts and chosen fallback/chunking; no silent blade subset |
| GPU unavailable/fails | “GPU acceleration unavailable; using CPU.” Preserve quality/status. |
| approximate interactive result | visible `Approximate—Final Update required` state |
| final visible validation failed | mark exact offending triangle/obstacle where possible; no publish |

## Saved scene and reopen

Persist:

- authored settings and source/collider identities;
- source preparation/binding data or stable library reference and fingerprint;
- portable compact pose results only if existing scene contract chooses to retain them;
- quality/status and schema/capability versions.

Do not persist:

- CUDA/OpenCL objects, native D3D handles, pointers, fences, allocator blocks;
- driver binaries/JIT cache references as scene truth;
- device-specific buffer addresses.

On reopen, rebuild transient resources. If optional components are missing, materialize/use CPU fallback and report capability degradation.

## Recommended versus required hardware language

- **Required for core feature:** supported CPU/Max package and admitted source/geometry.
- **Recommended for optional acceleration:** a qualified GPU/driver/backend shown by the support matrix.
- **NVIDIA recommended:** only if CUDA backend passes and offers a meaningful complete-path advantage.
- **NVIDIA required:** only for that optional CUDA backend, never for loading/editing the scene through CPU fallback.

## Release stop conditions

Do not ship the accelerated tier when:

- runtime absence prevents plugin load;
- installer copies unreviewed toolkit components;
- cold JIT/cache is unbounded or per instance;
- backend/device failure loses the last complete result;
- approximate status is hidden;
- selected renderer/Bake cannot reproduce viewport pose;
- support cannot identify exact backend/device/revision/failure from logs.
