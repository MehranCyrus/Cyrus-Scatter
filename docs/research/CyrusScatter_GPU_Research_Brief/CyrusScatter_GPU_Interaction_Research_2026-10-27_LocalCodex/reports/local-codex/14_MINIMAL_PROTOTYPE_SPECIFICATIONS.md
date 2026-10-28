# Minimal prototype specifications

Each prototype answers one bounded question. A passing predecessor does not establish the next one's acceptance.

## RP-A — standalone deformation: executed

**Question:** can regular pose-driven vertex work execute efficiently on CUDA/OpenCL, and what happens when all output returns to the CPU?

**Included implementation:** [deformation_probe.cpp](prototype/deformation_probe.cpp). Four batches use one shared 4,096-vertex source and 512 pose nodes per instance, up to 1,024 instances. Both GPU paths and CPU paths compare against a double evaluator. Timing excludes static upload/JIT in the warm window and separately includes pose upload/full output readback.

**Observed:** all four cases passed numerical checks; larger kernel times were close between CUDA/OpenCL. The transfer-inclusive batch was much slower than device arithmetic. Exact results, build flags and source hash are included.

**Deliberately absent:** production material-frame spherical interpolation, full three-axis fixture diversity, normals, visibility, collisions, Max drawing and asynchronous lifetime tests. It is not a plugin feature implementation.

## RP-B — standalone D3D11 sharing: executed

**Question:** can this installed driver share owned D3D11 buffers with either runtime?

**Included implementation:** [interop_probe.cpp](prototype/interop_probe.cpp). Match DXGI adapter to CUDA, create feature-level-11.0 device/buffer, write 1,024 float4 values through CUDA, validate by D3D staging read. Repeat with the advertised OpenCL sharing variant and a separate buffer.

**Observed:** both passed; OpenCL selected `cl_nv_d3d11_sharing`.

**Deliberately absent:** Max-owned device/resources, retained render items, draw timing, state-cache integration, repeated allocate/resize cycles, failure injection and device recreation. Success is neither a “zero-copy” performance guarantee nor Max interoperability acceptance.

## RP-C — public Max buffer consumer: not executed

**Question:** can our retained HLSL shader read an SDK-owned pose buffer with supported API ownership?

**Fixture:** disposable Max 2027 profile, one isolated sample plugin/native payload, no artist scene edits. Procedural small mesh and two instances; an eight-float4 buffer changes one known transform. Use documented `VertexBufferHandle::Initialize` usage/data type and `HLSLMaterialHandle::SetBufferParameter`. Capture parameter reflection and shader diagnostics.

**Procedure:** initial read; change one page; redraw; orbit/pan; switch Wireframe/shaded; open second viewport; resize viewport; create/delete sample; close/reset scene; recreate GPU resources through supported lifecycle callbacks. Inspect exact object positions/bounds and resource counts.

**Acceptance:** shader values and instance indexing match independent expected coordinates, all API calls are public and permitted in their callbacks, no private casts, no uncontrolled host-context manipulation, no per-navigation source upload. Retain exact SDK/native/profile/log identities.

**Failure branch:** no working buffer path → investigate documented texture parameter or compact vertex/instance attributes as a bounded alternative, with measured limits. Do not claim a generic constant-buffer array scales to arbitrary guides; D3D11 constant-buffer limits and driver behavior must be checked for the actual route.

## RP-D — current deformation parity: not executed

**Question:** can RP-C reproduce the real source/pose contract?

Use copied preparation/pose snapshots for grass, broad fern, flower with child stems, and trunk/leaf source with fixed decoration. Evaluate CPU `posePoint`, `poseDirection` and visible faces at rest and under several known nontrivial poses, including root smoothing and parent attachments. Compare the GPU-evaluated coordinates using a controlled capture/readback mechanism separate from the timed display path.

Proposed initial tolerances: local position error no larger than `max(1e-6 m, 1e-6 × source extent)`, anchors within the capture/FP32 error budget, and normal angle error below 0.5° for the chosen normal model. These are prototype targets requiring review against renderer/scene requirements; they are not existing acceptance. Compare topology/material/UV/hidden-group identity exactly where applicable.

Measure one instance, many rest instances, sparse changed guides and dense poses. Track bytes and shader cost. Readback used for validation must not be mistaken for the intended production preview path.

## RP-E — analytic GPU guide fit: not executed

**Question:** does bounded parallel fitting improve the actual dominant stage while preserving rooted contact quality?

Inputs: flat immutable chains with explicit parent levels, rest lengths/frames, zero-mobility anchors, source-local analytic colliders, Contact gap, independent hide mode/margin, stable IDs and revision. Outputs: compact poses/masks, complete/outcome, iteration count, maximum constraint residual and overflow counters.

Start with deterministic independent chains and whole-span analytic sphere controls. Add rotated boxes and two colliders, then parent attachments. Do not start with arbitrary imported mesh sign/SDF construction. Compare CPU/GPU final shape, root drift, edge strain, minimum whole-span gap and independent visible leaf triangles. Include intentionally infeasible roots and iteration-budget failures.

Run CUDA and OpenCL research versions on the same GPU with equal math/iteration/quality policy. Benchmark compact pose return plus RP-C upload, not just kernel events. Every fitted guide must be represented; a false completion or dropped root group fails the experiment.

## RP-F — Max device/resource ownership: not executed

**Question:** if direct sharing is needed, what supported bridge reaches the retained display?

First compile a read-only adapter query using the installed public SDK and resolve its legacy header prerequisites. In an owned profile, query `D3D11_GRAPHICS_WINDOW_INTERFACE_ID` from the relevant graphics window, log interface presence/device adapter and borrowed lifetime, and avoid writes. Do not reconstruct interfaces from guessed vtables when headers are unavailable.

Only after that pass, establish a documented resource creation/consumption path. Use one tiny privately owned resource with explicit map/acquire and graphics handoff. Record an ownership timeline, required callbacks, state restoration and references. Add repeated updates, two views, resize, deletion and device recreation. A standalone RP-B rerun does not substitute for this experiment.

## RP-G — queue and recovery: not executed

Inject rapid input, supersession, settings/source revision change, Undo, reset/deletion, queue overflow, allocation failure and device-epoch loss. Use a controlled test backend to create late completions without hanging the GPU. Validate bounded memory, monotonic published samples, exact final target and no callbacks into invalid owners. Avoid deliberately triggering TDR in an artist session.

## Shared output format

Every run should save metadata plus per-sample CSV/JSON: source hashes, fixture/seed, requested/published revision, N/K/G/Q/P/V/T, CPU wall/worker times, GPU events, transfer bytes/times, allocation peaks, publication/present times, residuals, anchor drift, surface penetration, status/complete and fallback reason. Store failures and compiler options alongside successes. Never infer a successful host test from screenshots without matching payload and numeric evidence.
