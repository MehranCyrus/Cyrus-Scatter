# Distribution, fallback, and artist workflow

**Status: P. No installer, native backend or production UI was changed in this research.**

## Preserve the artist's model

Artists should continue choosing a layer role, preparing original source models, assigning/reviewing meaningful leaf/stem/fixed regions, and moving collider instances. CPU/GPU selection should not introduce a second preparation workflow or require manually managing pose buffers.

Keep Contact gap, Hide margin, hide mode and preview percentage as distinct controls with the current ownership semantics. A lower preview percentage changes visible detail; it must never mean “only this percentage of stems may react.” A solver budget failure should identify the problem and retain the last result, not be presented as a random thinning setting.

## Proposed backend UX

Default to Auto only after qualification. Auto selects from supported CPU, shader-deformation and optional compute paths using actual capability/adapter checks and measured batch thresholds. Provide a diagnostic override for comparison, not a long list of CUDA/OpenCL internals in the main artist panel.

Useful short statuses are: Ready, Updating, Last complete result retained, CPU fallback, Source needs preparation, Unsupported transform, and Resource budget exceeded. Detailed diagnostics may show active plants/guides, result age, stage times, peak bytes, selected adapter/backend and fallback reason. Avoid silently changing geometric quality to preserve an advertised frame rate.

## Portable scene data

Save authored preparation/overrides, geometry fingerprints, stable identities and interaction settings. Treat device pointers, driver cache blobs, transient pose pages and graphics handles as derived caches. A scene should open on a CPU-only workstation without losing the authored feature; it may rebuild the appropriate derived data.

If optional GPU approximation changes the final shape within an accepted tolerance, record that policy/version. For deterministic deliverables, use a declared authoritative final evaluation rather than whichever backend happened to be available during the last preview.

## Runtime packaging

Pin compiler/toolkit, target architectures, kernel source/binary identities and supported driver requirements. Distinguish the development toolkit from customer runtime dependencies. Do not make end users install the full toolkit or rely on a globally configured `CUDA_PATH` for ordinary operation.

Compare precompiled cubins with a PTX fallback versus controlled JIT. Cache only under an owned user/cache location with a key covering source/kernel options, backend/compiler, architecture and relevant driver policy. Compile outside the drag path. A cache miss must not look like an unexplained frozen viewport.

Load optional compute modules defensively so a missing runtime or unsupported adapter does not prevent the base plugin from loading. Ensure DLL search paths cannot select a stale unrelated toolkit/runtime accidentally. Inventory every redistributed component, verify its version-specific redistribution permissions, and preserve required third-party notices. NVIDIA CUDA Samples, CUDA runtime components, Warp dependencies and Autodesk SDK files do not share one universal license.

The current research ZIP contains original probe source/results only. It redistributes no CUDA/OpenCL runtime, Max SDK, upstream engine tree or compiled plugin.

## CPU fallback must be coherent

Fallback can occur for missing capability, adapter mismatch, insufficient budget, kernel failure, invalid result or device recreation. It must use the same captured semantic revision and publish a complete geometry/mask/bounds set. Do not show GPU poses from one settings revision and CPU hiding from another.

After device removal, old GPU allocations are unusable. Rebuild a valid SDK/CPU representation from authoritative snapshots rather than claiming the old GPU frame is retained. Repeated failures should disable the faulty accelerator for the session with a clear reason and explicit retry control in diagnostics.

## Render and delivery boundaries

Preview acceleration does not automatically accelerate the renderer. Bake/export/conversion must receive a correct CPU mesh or a separately qualified renderer integration. Renderer version, material/normal behavior, motion blur and displacement are separate acceptance surfaces. Never turn preview LOD into final-render geometry loss without an explicit artist setting.

Current development/qualification scope is Max 2027 only. A later authorized release must include the repository's matched native/script MZP, archive/payload identity checks and artist installation instructions. Historical requests for Max 2024/2026 installers do not qualify a new GPU backend there. This research does not choose a new plugin version or install anything into the user's Max profile.
