# 15 — Distribution, fallback and the artist workflow

[Contents](00_README.md) · [API comparison](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md) · [Lifetimes](08_ASYNC_PUBLICATION_AND_LIFETIMES.md) · [Acceptance](18_ACCEPTANCE_CHECKLIST.md)

**Recommendation — proposed:** distribute the established CPU-capable plugin independently of an optional compute backend. A missing CUDA/OpenCL runtime, unsuitable adapter or rejected GPU profile must leave Cyrus loadable and its CPU behavior available. GPU enablement is a capability and quality decision after initialization, not a compulsory dependency of the primary Max plugin DLL.

No installer, signed binary, Windows backend or Max plugin was built in this investigation. This chapter specifies a deployable design and the evidence to collect locally.

## 1. Package boundaries and minimum requirements

| Component | Proposed delivery | Required local qualification |
|---|---|---|
| Main Max plugin | Existing native host/core and public retained-display path; no unconditional CUDA/OpenCL import in this DLL or its mandatory dependencies | Inspect PE imports with `dumpbin /DEPENDENTS` and `/IMPORTS`; launch with compute packages absent. Test scene open, existing CPU fit, viewport, renderer and Bake. |
| Optional CUDA backend | Private versioned backend directory; explicit versioned C ABI for owned arrays/handles; release memory through the allocating module | Selected CUDA runtime/Driver API strategy, exact compiler/CRT, adapter capability, driver, graphics bridge and coexistence with renderer CUDA users |
| Optional OpenCL backend | Private backend plus allowed loader dependency; discover vendor implementations at runtime | Platform/device profile, compiler/IL availability, extension functions, driver version, precision and local-size limits |
| HLSL deformation | Fixed evaluator shaders in the supported Max material/resource path, with versioned schema | Shader creation, pose lookup, bounds, Wireframe, multiple viewports, renderer-independent CPU evaluator |
| Portable scene/library data | Sources, fingerprints, stable IDs, authored bindings and settings; optional versioned completed pose data under a separate portable contract | Never persist GPU addresses, CUDA/OpenCL objects, allocator state, fences or adapter handles |

**Proposed initial compute profile:** native Windows x64, C++20, positive uniform transforms, FP32 local state with defined CPU double boundaries, and Turing/SM75 or later **if built with CUDA 13.x**. That architecture floor follows CUDA 13's removal of offline compilation/library support for Maxwell, Pascal and Volta; the algorithm itself does not require Turing. A separate 12.x build for older hardware would add maintenance and needs a business case. CPU/HLSL use does not require CUDA at all. [C05](17_SOURCE_LEDGER.md#c05)

This is a candidate compiler target range, not a qualified product support promise. Include a Turing test device if that generation becomes the advertised minimum; chapter 09's representative memory tiers alone do not test it.

Use the smallest feature set needed by the first prototype: ordinary kernels, events and explicit buffers. Graphs and stream-ordered pools are optional optimizations, not baseline scene semantics. The research's inspected CUDA 13.4 documentation is a candidate development reference, not a user hardware requirement. Before release, select one installer/build pin and explicit SASS targets, record toolkit/compiler hashes and qualify the driver floor. Minor compatibility's R580 family floor must not be advertised as supporting every PTX or newly introduced interop feature. [C04](17_SOURCE_LEDGER.md#c04)

For OpenCL, define a capability record rather than “OpenCL supported”:

- Device/platform vendor, version and driver; device availability and compiler or accepted binary/IL route.
- FP32 and required integer operations; workgroup and local-memory limits; allocation size/alignment and global-memory admission.
- FP64 if any kernel requires it; subgroup and command-buffer capabilities only for optional optimized paths.
- Exact D3D11/external-sharing extensions and compatible device identity if sharing is enabled.

Query only enums valid for the reported API version, with documented extension fallbacks. A device that fails the chosen profile receives a reason and CPU selection. The current 3.1 specification does not upgrade an installed 3.0 driver. [C29](17_SOURCE_LEDGER.md#c29)

## 2. Loading without breaking the host

**Proposed sequence:**

1. Load the CPU plugin normally; do minimal work in `DllMain`. After host initialization, inventory available backend files and user policy.
2. Load the optional backend by an explicit trusted path using a restricted `LoadLibraryExW` search policy. Resolve a versioned entry point; reject a schema/ABI mismatch before passing arrays.
3. Perform device enumeration and bounded allocation/kernel sanity checks outside `DllMain` and Draw. Any failure becomes a recorded `Unavailable` reason; the CPU route remains selected.
4. Negotiate numeric and interop capabilities. If drawing uses another adapter or resource sharing fails, select compact pose readback or CPU fitting; do not guess an adapter by ordinal or name.
5. Activate only after output validation and host-boundary tests. Stop scheduling, retire work and destroy owned resources before backend unload. If safe draining is impossible after driver failure, disable further work and follow the host recovery policy; do not unload executable code still reachable by callbacks.

Microsoft documents loader-lock restrictions and recommends deferring substantial initialization. `LoadLibraryExW` fails when a module or dependency cannot be resolved; loading by full path alone does not automatically isolate every transitive dependency. Test backend load order with renderer plugins and another CUDA consumer already loaded. Do not globally rewrite Max's DLL search policy or ship replacement system drivers into the plugin directory. [C21](17_SOURCE_LEDGER.md#c21), [C22](17_SOURCE_LEDGER.md#c22)

Prefer a narrow ABI carrying POD descriptors, explicit byte lengths, schema versions and ownership functions; avoid passing STL containers, exceptions or host SDK objects into the compute module. This reduces cross-module ownership exposure but **does not prove Max ABI safety**. Inspect the installed SDK samples/property sheets and log compiler version, toolset path, CRT flags, iterator/debug settings and architecture. The supplied successful MSVC14.38.33130 build is project context, not this report's build. [C25](17_SOURCE_LEDGER.md#c25), [C26](17_SOURCE_LEDGER.md#c26)

A CUDA primary context is shared with the Runtime API; resetting it destroys resources potentially used by other modules. Do not call `cudaDeviceReset` or primary-context reset as ordinary Cyrus cleanup/recovery. Choose and document a scoped context policy, release only Cyrus ownership, preserve thread context state, and qualify simultaneous GPU rendering. Driver failure may prevent normal cleanup; CPU fallback is conditional on the host remaining operational. [C28](17_SOURCE_LEDGER.md#c28)

## 3. Redistribution inventory

| Dependency | Verified terms or boundary | Proposed package policy |
|---|---|---|
| CUDA Runtime | CUDA EULA Attachment A lists Windows `cudart.dll`, `cudart_static.lib`, `cudadevrt.lib` as redistributable components; grant is conditional | Choose static/dynamic runtime strategy deliberately, retain required notices, and list actual versioned files. Do not infer blanket toolkit redistribution. |
| NVRTC | Attachment A lists `nvrtc.h`, `nvrtc.dll`, `nvrtc-builtins.dll`; NVRTC is a runtime compilation library | Omit from the first AOT backend unless needed. If adopted, package the exact compatible runtime/builtins and license obligations. |
| NVCC / development tools / display driver | EULA allows distribution only of identified portions; developer tools are internal unless listed | Build on engineering machines. Do not require an artist to install the toolkit, and do not assume permission to bundle NVCC or a driver. Use the vendor driver installation route. |
| CUDA sample code | Inspected repository is BSD 3-Clause; toolkit EULA is separate | Keep source-specific notices when adapting a sample; do not copy the standalone application's device ownership into Max. |
| CCCL | CUB BSD 3-Clause; Thrust Apache 2.0 with exceptions; libcu++ Apache 2.0 with LLVM exceptions | Preserve selected component notices and audit transitive headers. Pin the release, not a moving branch. |
| Khronos SDK/ICD loader | Inspected SDK and loader are Apache 2.0 | Retain licenses/notices; audit submodules and optional sample dependencies. A loader is **not** a vendor OpenCL implementation. |
| Vendor OpenCL ICD | Not supplied by Khronos loader | Require a compatible installed vendor implementation; redistribution rights must be checked against that vendor/package. Do not copy a random `OpenCL.dll` from another computer. |
| Microsoft VC++ runtime | Microsoft permits redistributable deployment under Visual Studio licensing; runtime must be at least as recent as build tools and match architecture | Pin the selected x64 redistributable and installer detection; do not replace Max CRT files manually. |

Sources: [C19](17_SOURCE_LEDGER.md#c19), [C20](17_SOURCE_LEDGER.md#c20), [C11](17_SOURCE_LEDGER.md#c11), [C10](17_SOURCE_LEDGER.md#c10), [C12](17_SOURCE_LEDGER.md#c12), [C13](17_SOURCE_LEDGER.md#c13), [C23](17_SOURCE_LEDGER.md#c23). This is an engineering dependency inventory, not clearance of the final commercial package. Verify the precise license text shipped with each selected version before release.

**Proposed signing policy:** sign Cyrus backend/plugin binaries and installer, preserve vendor signatures, timestamp release signatures, and verify the installed package. Microsoft SignTool supports signing, timestamping and signature verification. Signing confirms publisher/integrity under its policy; it neither grants unsupported Nitrous resource access nor supplies a missing CUDA driver. Test corporate application-control and antivirus environments rather than presenting a signature as a compatibility proof. [C24](17_SOURCE_LEDGER.md#c24)

## 4. AOT, JIT and bounded caches

NVRTC can compile CUDA C++ source into GPU code without a GPU; executing the result still needs a supported device/driver. It is not necessary for a fixed evaluator and fitter. **First proposal: AOT kernels for a finite set of admitted architectures**, with a separately tested PTX fallback policy. Preserve cold costs in the benchmark even when the deployment normally caches them. [C20](17_SOURCE_LEDGER.md#c20)

OpenCL commonly builds source or accepted IL through the vendor implementation; its SDK `samples/core/binaries/main.cpp` demonstrates loading a cached binary, building when absent, and saving binary output. Reuse the pattern, not its filename as a production cache design. Vendor binary portability is not assumed. [C12](17_SOURCE_LEDGER.md#c12)

| Cache | Proposed key | Invalidation / bound |
|---|---|---|
| Device executable | Backend/kernel schema and code hash; compiler/toolkit and options; target architecture; driver/compiler identity where JIT/binary format requires it; precision profile | Byte and entry cap; atomic writes; failed-build log cap; reject corrupt/mismatched entries and rebuild once |
| Prepared GPU source | Source geometry/binding fingerprint, preparation/schema version, units/frame conversion, device session | Source/binding edits invalidate; transforms do not recompile kernels; LRU eviction only after read leases finish |
| Collider BVH/field | Geometry fingerprint; representation type; voxel size/band/error policy; source scale policy; device session | Rigid pose updates reuse shape data; topology/field settings rebuild; report construction cost |
| Graph/command buffer | Kernel variant, buffer schema, bucket capacities, dependency shape, precision and supported graph features | Bounded bucket count; data changes update inputs; incompatible topology/capacity changes rebuild |
| Completed pose | Relevant source/layout/collider/settings revisions; stable instance IDs; evaluator version | Never equate a cached executable with a valid pose; stale poses cannot publish |

**Proposed initial cache admission:** one compile in flight, at most 16 executable variants, at most 256 MiB on-disk compiled cache and 8 MiB diagnostic logs, with explicit eviction. These are conservative engineering starting limits, not measured required sizes. Compilation must not occur per instance, pointer event, camera or material change. Source data normally changes buffers, not program text. If a variant exceeds limits, use the unspecialized program or CPU path.

Prewarm after Prepare or idle time, with progress and cancellation of pending compile requests. If a vendor compiler cannot safely interrupt compilation, isolate that work as a bounded helper process where justified, or allow it to complete without publication; never terminate arbitrary Max threads. A cold compilation cannot block Draw. The final implementation must record actual compile/cache costs and revise these proposed limits from evidence.

## 5. Artist controls and states

Keep the existing **Collider / React / Prepare** model. The artist prepares a unique plant once, confirms its roots/branches/bindings, and reuses it. Moving a collider schedules fitting for the union of old and new neighborhoods, including independently edited transforms. When it leaves, the new result restores the source's rest geometry. Pending Manual placement changes remain subject to the existing Update contract.

| Artist control | Behavior |
|---|---|
| Prepare | Audit/rebuild shared source definition and fingerprint; show unsupported geometry/transform reasons; optional bounded kernel prewarm |
| Collider / React | Existing role selection; accelerator choice does not reinterpret authored roots, attachments or groups |
| Contact gap | Bending clearance in scene-visible units, converted once to internal metres |
| Hide margin + mode | Independent root exclusion: Inside solid or explicit Under collider; display the selected region |
| Quality | Default **Verified** publication. Optional **Interactive preview** only if its approximation/error policy has been qualified and final refinement is explicit |
| Update / Finish | Request the current complete successor; final verification/materialization before Bake/export or final output |
| Advanced diagnostics | Auto / CPU / qualified GPU, chosen adapter, memory/work caps, timings and failure reason; kernel block size stays out of the main UI |

**Proposed state language:** `Prepared`, `Updating`, `Verified`, `Preview—refinement pending`, `Previous result—update failed`, `CPU fallback`, `Preparation stale`, `Unsupported`. Distinguish a stale last complete pose from a completed approximate preview. Display progress or affected counts without claiming a truncated list is complete. A failed fit retains the preceding complete publication; it does not silently hide blades, move roots or substitute a coarser collision representation.

Automatic choices may select CPU/GPU from measured crossover and capability, coalesce events, reuse cached immutable inputs and retire unused resources. Automatic choices must preserve requested quality. An approximate solver, reduced visible-surface verification or omitted foliage contact is an explicit quality change, not an accelerator setting.

After moving a stone: show `Updating`; keep the previous complete view while work proceeds; publish only a complete successor matching current revisions; restore plants left behind; report infeasible roots/gaps with selectable diagnostics. If the GPU is unavailable, compute the same request on CPU when admitted. If both fail, retain the old result and explain the reason. F3/Wireframe, camera motion, selection and UI browsing must not trigger another static fit or upload unchanged pose data.

## 6. Release failure tests and fallback rule

Test missing backend DLL, missing runtime dependency, no vendor ICD, too-old driver, unsupported GPU/precision, rejected shared resource, different adapters, exhausted VRAM, corrupted cache, cold JIT, Undo during work, source replacement, owner deletion, Max reset/close, and renderer start during interaction. Record CPU startup and output behavior for every case; include recoverability when the graphics device itself is lost.

**Fallback rule — proposal:** a recoverable compute failure invalidates that successor and disables the failing GPU route for the session until an explicit retry or successful capability recheck. Re-run the newest request on CPU within the same admitted semantic/quality contract. Do not relabel incomplete GPU output as CPU-verified, continually thrash both backends, reset process-global CUDA state, or promise uninterrupted display after a host graphics-device failure. Use the detailed lifetime and retirement contract in [08](08_ASYNC_PUBLICATION_AND_LIFETIMES.md).
