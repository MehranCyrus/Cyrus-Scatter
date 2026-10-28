# 15 — Distribution, fallback, and artist workflow

[Index](00_README.md) · [Decision](01_EXECUTIVE_DECISION.md) · [Source ledger](17_SOURCE_LEDGER.md)

Researcher A · 27 October 2026. **Deployment architecture below is proposed.** No Windows installer, dependency scan, driver absence test, CUDA/OpenCL binary, Max startup, signing, or renderer pass was executed. Vendor terms and API capabilities were researched; the final binary inventory must be produced by the local release build.

## Ship an optional backend without making the CPU plugin optional

The core Max plugin must load and retain its CPU functionality when a compute runtime, compatible device, or driver is absent. This requires controlling the entire import graph, not simply catching an exception around the first CUDA call.

**Proposed modules:** keep the existing Max-facing module built with the qualified Autodesk toolchain. Put CUDA or OpenCL code in a separately loaded optional numerical DLL. Expose a small versioned C ABI for capability enumeration, immutable snapshot upload, bounded job submission, status polling, copied result acquisition, cancellation request, and explicit shutdown. Pass opaque handles and fixed-width scalars/arrays with length and structure-size fields. The backend owns its allocations; results use caller-owned buffers or an explicit backend release function. No Max pointers, `std::vector`, exceptions, GPU pointers, or CRT heap ownership cross the interface. Transform/unit conventions and source/session revisions are explicit values, not ambient state.

This boundary limits compiler coupling; it does not prove that an unsupported compiler combination is safe. The current CUDA Windows table, Autodesk requirements and provided local MSVC 14.38 observation need the precise local checks in [04](04_CUDA_OPENCL_AND_GRAPHICS_COMPUTE.md) and [07](07_MAX_2027_INTEROP_FEASIBILITY.md). Microsoft's binary-compatibility guidance imposes linker, redistributable and `/GL`/`/LTCG` restrictions even within supported MSVC families. Avoid cross-module whole-program optimization across independently qualified toolsets. [API02](17_SOURCE_LEDGER.md#api02) [API28](17_SOURCE_LEDGER.md#api28)

### Startup and loading sequence

1. Load the core plugin and its normal CPU dependencies. Initialize no GPU runtime in `DllMain` or static/global constructors.
2. After host initialization, read the user/backend policy and probe optional modules from an installation-owned absolute path.
3. Resolve the exported ABI entry point; check ABI version/size and backend identity before invoking it.
4. Enumerate devices and inspect capabilities without changing the scene. Record API/runtime/driver versions, memory, architecture, display/compute adapter identity and sharing support.
5. Create context/queues/pools only when the backend is admitted. A small self-test checks buffer operations and error reporting; full geometric qualification remains a separate test suite.
6. Reconstruct GPU caches from immutable CPU source snapshots. Begin using the backend only after a complete supported job passes publication checks.

Microsoft documents DLL search-order risks and the use of explicit paths/restricted search options. `LoadLibraryExW` can fail because a dependency is absent even when the requested DLL exists. Its flags must also constrain dependency resolution; a full path to the top DLL alone is not the complete policy. Use an application-owned private dependency directory and documented system-directory loading for driver-provided components; do not rely on an artist's current directory or `PATH`. [API24](17_SOURCE_LEDGER.md#api24) [API25](17_SOURCE_LEDGER.md#api25)

**Proposed implementation rule:** do not change Max's process-wide DLL search policy or overwrite a loader installed by another product. Load only expected names from trusted locations, record file versions/hashes, and reject ABI mismatch. Delay loading is acceptable only if all dependency failures are handled and no unguarded static initializer touches that module. A truly optional backend has no mandatory CUDA/OpenCL/NVRTC import in the core plugin or its compulsory dependency chain. Verify using the produced binary's import/dependency report.

Windows calls `DllMain` while holding the loader lock, including C++ global constructors invoked by the CRT. Loading other libraries, complex synchronization, worker startup/shutdown and GPU initialization belong outside it. Explicit shutdown must occur at the supported host lifecycle boundary; don't wait on arbitrary GPU work from process-detach handling. [API26](17_SOURCE_LEDGER.md#api26)

## What the installer may contain

The CUDA EULA retrieved for this research is updated 26 January 2026. Its license grant/distribution conditions and Attachment A distinguish redistributable components from development tools. It lists generic Windows names and permits applicable versioned filenames. This is evidence for a component inventory, not permission to redistribute every file in a Toolkit directory. [API29](17_SOURCE_LEDGER.md#api29)

| Component | Evidence and proposed treatment | Local release gate |
|---|---|---|
| Core Cyrus plugin | Existing product delivery; no new installer has been made here | CPU-only startup and unchanged scene loading on a machine without optional runtimes |
| CUDA runtime | EULA lists `cudart.dll`, `cudart_static.lib`, `cudadevrt.lib` with versioned-name qualification | Select dynamic or permitted static linking; record exact installed filename, file version, SHA-256 and transitive imports |
| CUDA driver | Provided by NVIDIA driver installation; Toolkit 13.1 onward no longer bundles a Windows display driver | Detect installed driver; provide a requirement/diagnostic. Do not copy driver DLLs from the research/build machine. [API01](17_SOURCE_LEDGER.md#api01) |
| NVRTC | EULA lists `nvrtc.h`, `nvrtc.dll`, `nvrtc-builtins.dll` | Omit for AOT-only design; if runtime compilation is chosen, inventory the actual matching versioned DLL pair and license |
| JIT linker | EULA lists generic Windows `libnvJitLink.dll`, `libnvJitLink.lib` | Omit unless a selected runtime-link workflow needs it; dependency inspection decides the actual versioned basename |
| CUB/Thrust/libcu++ | Header/source libraries in CCCL, with different component and third-party license terms | Preserve required notices/licenses for the exact source revision; don't label all of CCCL simply “BSD” or “Apache.” [API10](17_SOURCE_LEDGER.md#api10) |
| CUDA sample code | Current samples license is BSD 3-Clause with a CUDA EULA reference | Retain notices if code is reused; inspect the license at the exact checkout before shipping. Samples are not shipped wholesale. [API42](17_SOURCE_LEDGER.md#api42) |
| Khronos OpenCL loader | Apache-2.0 repository; exports/distributes calls to vendor implementations | A private loader may be built and shipped under its terms; it does **not** install a GPU implementation. Avoid replacing a system loader. [API47](17_SOURCE_LEDGER.md#api47) |
| OpenCL GPU implementation/compiler | Driver/vendor component, distinct from Khronos headers/loader | Query installed implementation. Khronos's loader license does not grant redistribution rights to vendor driver DLLs |
| MSVC runtime | Microsoft documents licensed redistribution paths | Use the qualified release CRT/redist version and architecture; don't bundle debug CRT. [API27](17_SOURCE_LEDGER.md#api27) |
| Nsight/Compute Sanitizer/nvcc/build tools | Development/test dependencies, not assumed artist dependencies | Do not include merely because they exist on the developer machine |

**Unresolved exact DLL names:** no CUDA Toolkit or Windows binaries are installed in this execution environment. Consequently there is no measured `dumpbin /DEPENDENTS` result and no honest list of the exact CUDA 13.4 DLL basenames that the final Cyrus build imports. Inventing names from an older Toolkit would defeat the requested deployment audit. The local release gate must produce `runtime_inventory.json` containing component, exact path basename, version, SHA-256, origin, license/redistributable clause, architecture, required/optional status and each importing module. Test that inventory in an isolated Windows/Max installation without the developer Toolkit on `PATH`.

**Proposed signing policy:** sign the installer and shipped first-party DLLs with the existing product identity, preserve vendor signatures where applicable, and verify update/rollback behavior. A signature does not supply redistribution rights, cure an unsupported dependency, or prove runtime compatibility. No new Max-specific mandatory signing rule is asserted by this research. Treat license review and dependency inventory as release work, rather than an artist-facing flow.

## AOT first; bounded JIT only where justified

For the first CUDA prototype, compile a small fixed kernel set ahead of time into architecture-specific cubins in a fat binary. Select architecture targets for hardware actually being qualified. Optionally include PTX as a deliberate forward-compatibility path, but test driver JIT and cold startup separately. Minor-version driver compatibility has limitations: newer PTX or features may require a newer driver. No nvcc or full Toolkit installation should be required on the artist machine for this AOT design. [API03](17_SOURCE_LEDGER.md#api03) [API04](17_SOURCE_LEDGER.md#api04)

The static vegetation problem needs per-source **data preparation**, not a unique program for every plant or blade. Use shared compiled kernels parameterized by guide counts, offsets, bindings and flags. A small number of bounded specialization buckets is a hypothesis to benchmark; generating unbounded code variants from arbitrary source geometry is rejected for the first implementation.

OpenCL supports building programs from source, intermediate language, or implementation-specific binaries, subject to device capabilities and build status. Build callbacks can execute asynchronously and require safe lifetime/thread handling. Cache compiler output only with a device/driver/compiler/options key and validate build logs/status; a binary generated for one environment is not a portable proof for another. [API07](17_SOURCE_LEDGER.md#api07)

**Proposed cold behavior:** request backend preparation after explicit source Prepare, scene-open idle time or an explicit GPU enable operation; display a bounded Preparing state and keep the CPU path available. Do not compile synchronously inside every collider-transform notification. Apply a compile timeout/task budget, a per-user disk-cache byte limit and a per-process resident-program cap. These limits are policy values to determine locally, not measured numbers in this report. Cancel queued compilation where possible; for an already running compiler, discard stale output without publishing it. A failed compiler invocation yields one diagnostic and a CPU fallback, not an endless retry loop.

### Four cache identities

| Cache | Required proposed key | Invalidated by |
|---|---|---|
| Program/module | Backend ABI, kernel source/build hash, compiler/toolkit version, flags including math policy, architecture/device feature set, driver version where compiled binaries depend on it | Code, ABI, compiler, flags, architecture/driver qualification change |
| Prepared source on GPU | Stable source fingerprint/revision, guide/binding revision, packed-layout version, units/frame policy | Source mesh/topology/UV/binding/root edit; incompatible layout or conversion change |
| Collider representation | Collider asset geometry revision, representation parameters/error bounds, build algorithm version | Geometry/proxy/field-resolution change; transform-only motion reuses instance-space geometry where valid |
| Completed pose | Source, plant identity/transform, collider set/revisions, contact settings, solver/quality version, session generation | Any relevant input change, Undo/Redo/session reset, unit policy change |

Do not reuse a prepared-source cache merely because a filename is unchanged. Do not bake device pointers into scene persistence. Scene files retain source/preparation identities, authored settings and portable completed data where the existing product supports it; GPU buffers, fences, context handles and allocator internals are rebuilt. Cache corruption is recoverable by discarding and regenerating one entry; checksum failure must not produce a partially trusted pose.

## Failure behavior and fallback

The policy is to preserve a complete, generation-qualified result. Fallback is a new complete computation or delivery path; it is not permission to publish a subset of plants or silently relax geometry constraints.

| Trigger | Proposed observable behavior | Recovery and test |
|---|---|---|
| No NVIDIA GPU / no CUDA driver | Plugin loads; CPU available; Auto reports CPU | Driver-absent install/start/open/save test |
| OpenCL loader exists but no implementation | Backend unavailable, CPU available | Enumerate empty platform/device list without crashing |
| Backend DLL/dependency/ABI failure | One actionable status containing module/API reason, not a modal dialog on every drag | Isolated missing/wrong-version DLL tests; keep core imports independent |
| Insufficient VRAM | Reject job before overcommit where possible; keep last complete result; use CPU or smaller admitted tiles | Inject allocation failures, account for queued/retained buffers and graphics memory |
| Device loss or graphics-device recreation | Mark GPU resources invalid, cancel queued publication, detach stale generation | Recreate after supported host notification; explicit retry or session fallback |
| Superseded drag/source edit/Undo | Discard result even if the kernel finished correctly | Newest complete input generation only; no stale output publication |
| Contact ambiguity, root infeasibility or budget exhaustion | Retain previous complete result; report cause and affected count/IDs | CPU exact/refinement path if admitted; otherwise explicit unresolved status |
| Backend repeated fault | Disable for the session; no infinite context-recreate loop | Explicit retry after recovery, export diagnostic report |
| Renderer/Bake requests final geometry | Request and materialize a complete current result under the agreed final policy | Same pose evaluator and independent mesh audit; no GPU viewport-only success flag |

Allocation and completion are asynchronous concerns: a failed enqueue can be immediate, while device execution errors may arrive at a later event/synchronization boundary. Treat success from submission as “accepted,” not “computed” or “validated.” The ownership/state rules are specified in [08](08_ASYNC_PUBLICATION_AND_LIFETIMES.md).

CUDA stream-ordered pools can reduce allocator synchronization, but still retain memory and need an explicit budget. Windows managed-memory behavior can lack demand paging and oversubscription and restrict CPU access during GPU work, depending on capabilities. Neither pooling nor Unified Memory makes VRAM limits or host transfers disappear. Prefer explicit resident source/collider storage and bounded staging for the initial backend. [API14](17_SOURCE_LEDGER.md#api14) [API16](17_SOURCE_LEDGER.md#api16)

## Minimal artist workflow

Preserve the existing **Prepare**, **Collider**, and **React** concepts. Prepared source geometry and authored binding decisions remain shared. The artist does not choose warp size, contact sort strategy, stream count or shader compiler flags.

| Control or status | Proposed behavior |
|---|---|
| Prepare | Validate source/guide/binding revisions, update shared preparation, optionally build admitted GPU cache; report unsupported source features before dragging |
| Collider | Select the obstacle source/proxy and existing exclusion behavior; keep Contact gap and Hide margin independent |
| React | Enable the existing static fitting behavior. Rest is restored after the collider leaves; no new physical history is introduced |
| Update / Auto / Manual | Update consumes the newest copied input snapshot; repeated intermediate edits are coalesced. Manual shows pending changes until requested |
| Backend preference in advanced settings | Auto, CPU, or a qualified GPU backend. Auto chooses a measured path; it does not change quality or hide unsupported plants |
| Quality choice, if approximation is shipped | A clearly named interactive preview versus final verified result, with stated limitations; never imply guide-only clearance proves visible leaf clearance |
| Compact status | Ready, Updating, Preparing GPU, Pending, CPU fallback, Approximate, or Failed with retained previous result |
| Details | Update ID, source revision, active plants/guides/contacts, budget use, error/residual category, backend/driver and fallback reason |

After moving a stone, query both the previous and new relevant neighborhoods, restore released plants from their immutable rest definitions, and compute the newly affected candidates. Only a complete newest successor publishes. The visible result may remain the last complete pose while a new one is pending; the UI should make this state legible. A solver failure must not delete/reseed vegetation or repurpose the artist's Hide setting.

During interaction, an optional proxy result may be shown only under an explicit approximation contract; a final render/Bake/export request must not silently consume an unverified approximation. The artifact must either complete the chosen final policy or report that it cannot do so. The intended production renderer remains a local integration question: support for one exporter or viewport path does not qualify Arnold, V-Ray, Corona or every renderer.

## Release acceptance

The first shipping gate requires: CPU-only clean startup; exact binary/license inventory; exact host/compiler/driver qualification; optional-module load failures handled; bounded cold preparation and cache invalidation; source immutability; stale-generation rejection; memory exhaustion/device reset tests; no scene-persisted GPU handles; and final renderer/Bake/export geometry equivalence under the agreed tolerances. This is a proposed release checklist. No item is reported passed by this research.
