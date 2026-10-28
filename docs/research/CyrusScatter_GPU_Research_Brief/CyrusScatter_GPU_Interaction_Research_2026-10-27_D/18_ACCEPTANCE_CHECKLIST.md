<!--
Researcher: A
Research date: 2026-10-27
Baseline: Cyrus Scatter 0.87.4.3 / native interaction capability 11 / scene schema 63
Scope: Research and architecture only; no production repository modification.
-->
# 18 — Acceptance checklist

## Evidence labels

- **[V] Verified public source** — official specification/vendor documentation, original paper, or inspected public repository listed below.
- **[P] Provided project fact** — supplied project context; not independently verified against the private repository.
- **[M] Provided measured observation** — reported by the supplied context and not reproduced here.
- **[E] Executed here** — artifact/hash/link/integrity work performed in this environment.
- **[A] Analytical estimate** — formula or byte count with explicit assumptions; not a benchmark.
- **[R] Recommendation / proposed design** — to be validated locally.
- **[U] Unresolved** — blocked on local source, SDK, Max, renderer, driver, or hardware evidence.

## Purpose

This checklist is a release-independent set of gates. A checked box requires attached evidence, not model confidence or an attractive demo. “GPU solver” includes CUDA/OpenCL or any compute backend; “GPU deformation” includes HLSL/shared-source display.

## Gate 0 — Scope and evidence

- [ ] Baseline product/capability/schema/host are recorded.
- [ ] Every test run records source/collider/fixture fingerprints and units.
- [ ] Verified public facts, provided project facts, executed results, estimates, proposals and unknowns are labelled separately.
- [ ] No private repository result is claimed without attached local evidence.
- [ ] No benchmark is inferred from vendor samples or one supplied 4.05 ms observation.
- [ ] Unsupported input classes and quality tiers are explicit.

## Gate 1 — CPU reference and workload

- [ ] Current CPU stage timings cover capture, query, fit, refinement, deformation, publication, upload/draw and input-to-present/Update.
- [ ] p50/p95/p99 and worst spikes are recorded with active counters.
- [ ] Production distributions of `N,K,G,S,V,C,P,I` are known.
- [ ] CPU memory includes published + successor + scratch + staging + history/output overlap.
- [ ] Independent visible triangle validation includes face interiors and containment.
- [ ] Root, length, frame, socket, source correspondence, bounds and rest restoration fixtures pass.
- [ ] Failure/cancel/stale work retains the last complete result.
- [ ] A measured bottleneck justifies the next GPU phase.

## Gate 2 — Source and canonical evaluator

- [ ] Source preparation is immutable and fingerprinted.
- [ ] Explicit roots, parents, guide frames, bindings and fixed parts survive instance reuse.
- [ ] Rest evaluation reconstructs supplied positions within declared tolerance.
- [ ] UV seams, render-vertex identity, topology and material IDs are preserved.
- [ ] Envelope coverage is audited and too-small envelopes reject.
- [ ] Quaternion sign and unsupported full-turn cases are tested.
- [ ] Normals/tangents have a declared supported policy and error gate.
- [ ] Exact bounds contain all visible evaluated vertices.
- [ ] Source edit invalidation is specified and tested.

## Gate 3 — Public Max GPU deformation

- [ ] Installed Max 2027 headers/samples identify every public method/header used.
- [ ] No private headers, COM downcasts or undocumented D3D pointer extraction.
- [ ] Two instances share immutable source buffers and display distinct poses.
- [ ] Structured pose/mask data is bounded and correctly indexed.
- [ ] Source buffers are not rebuilt for transform/pose-only edits.
- [ ] Mixed viewports, F3/style, resize and device recreation pass.
- [ ] Camera/selection do not trigger solves or unchanged uploads.
- [ ] Deformed bounds and culling pass.
- [ ] Picking/hit-testing uses the declared supported path and matches display.
- [ ] CPU canonical materialization matches viewport positions/normals within tolerance.

## Gate 4 — Collision and fitting correctness

- [ ] All relevant colliders are considered; no nearest-center shortcut.
- [ ] Old and new neighborhoods restore departed plants.
- [ ] Whole-segment/capsule contact detects crossings with endpoints outside.
- [ ] Visible blade/card edges and broad leaves are validated.
- [ ] Closed-solid containment is checked independently of surface crossings.
- [ ] Open/nonmanifold geometry has explicit surface/proxy/unsupported policy.
- [ ] Contact gap is applied exactly once.
- [ ] Hide margin/modes remain independent from bending clearance.
- [ ] Fixed roots never drift to make a solve pass.
- [ ] Narrow gaps, multiple obstacles, initial overlap and iteration failure report infeasible/unresolved status.
- [ ] Maximum strain/bend/frame validity are enforced.
- [ ] “Solver completed” and “quality achieved” are distinct statuses.

## Gate 5 — Matched GPU solver evidence

- [ ] CUDA and OpenCL use identical fixtures, equations, precision and quality.
- [ ] Same NVIDIA GPU/driver/power state is used.
- [ ] Comparable tuning effort and compiler flags are documented.
- [ ] Cold compile/JIT and warm cache are measured separately.
- [ ] H2D/D2H completed bytes/time and synchronization are included.
- [ ] Complete-path p50/p95/p99 is reported, not kernel-only timing.
- [ ] Crossover is measured by source/workload class.
- [ ] Exact CPU/independent validator passes all supported fixtures.
- [ ] Optional features/extensions are queried, not assumed.
- [ ] Memory pools, admission, cancellation and failure are bounded.
- [ ] GPU backend is rejected when typical work is below crossover or validation erases benefit.

## Gate 6 — Interoperability

- [ ] Standalone CUDA/OpenCL D3D11 proofs pass with explicit ownership.
- [ ] Graphics/compute adapter identity is checked.
- [ ] Wrong-adapter and missing-extension cases fall back safely.
- [ ] In-Max direct sharing is attempted only through explicit public SDK support.
- [ ] Map/acquire/fence/release order is documented and fault tested.
- [ ] Concurrent unsynchronized compute/draw access is impossible.
- [ ] Device recreation invalidates registrations/resources safely.
- [ ] Direct sharing is compared against compact pose readback/upload.
- [ ] Direct sharing is rejected if complexity exceeds measured benefit.

## Gate 7 — Asynchrony and lifecycle

- [ ] Every request has scene/owner/placement/source/collider/settings/units/device revisions.
- [ ] One in-flight plus newest pending (or another explicit bound) is enforced.
- [ ] New input coalesces without unbounded snapshots/allocations.
- [ ] GPU completion callbacks use owned IDs, not scene pointers.
- [ ] Stale Undo/Redo/delete/source/scene/device results cannot publish.
- [ ] Partial buffers never become successful output.
- [ ] CPU/GPU buffers retire only after all fences/consumers complete.
- [ ] Shutdown/unload waits or retires safely without use-after-free.
- [ ] No GPU pointer/handle/cache state is persisted as scene truth.

## Gate 8 — Precision and memory

- [ ] metres/+Y and Max unit/+Z conversions are explicit and tested.
- [ ] local rebasing handles large world coordinates.
- [ ] tiny admitted assets and scale-relative tolerances are tested.
- [ ] NaN/Inf/degenerate/near-singular inputs fail atomically.
- [ ] positive uniform scale is correct; unsupported affine transforms diagnose.
- [ ] CPU/GPU comparison uses numerical/visual tolerances, not bitwise equality.
- [ ] shared sources, poses, contacts, scratch, staging, graphics, output and history are budgeted separately.
- [ ] peak includes old + successor + renderer/Bake copies.
- [ ] VRAM reserve accounts for Max and GPU rendering.
- [ ] allocation/fragmentation failure routes to chunk/fallback/last-good.

## Gate 9 — Renderer, Bake and export

- [ ] Selected production renderer/version is named.
- [ ] It receives the same complete pose generation as viewport.
- [ ] CPU canonical mesh preserves positions, topology, UVs, materials and declared normals/tangents.
- [ ] Hidden groups and source/placement identities are correct.
- [ ] Bake/export/reimport agrees within declared tolerance.
- [ ] GPU-only viewport resources are not required for scene portability.
- [ ] GPU renderer contention and VRAM peaks are measured.
- [ ] Renderer failure cannot corrupt the published interaction result.

## Gate 10 — Distribution and support

- [ ] CPU plugin loads on a clean machine without CUDA/OpenCL runtime.
- [ ] CUDA/OpenCL backend DLLs are optional and ABI-versioned.
- [ ] Toolkit/runtime/ICD redistributables and notices receive release/legal review.
- [ ] Exact Max compiler/CRT/toolkit combination builds and loads in CI.
- [ ] Shader/kernel cache key includes backend/device/driver/kernel/schema/options.
- [ ] Cache is atomic, bounded, invalidatable and recoverable.
- [ ] Missing runtime/device/extension/compile failure gives clear CPU fallback.
- [ ] TDR/device loss/VRAM failure preserves last-good and scene load.
- [ ] Installer/update/uninstall/headless/RDP cases are tested.
- [ ] Support logs include backend, device, driver, revisions, counts, bytes and failure witness.

## Gate 11 — Artist behavior

- [ ] Main UI exposes artistic quality/clearance/root/flexibility controls, not kernel tuning.
- [ ] Manual waits for Update and clearly shows Pending.
- [ ] Live reacts only to relevant dependencies and coalesces edits.
- [ ] Approximate interactive results are visibly labelled and require final refinement.
- [ ] Unresolved plants/contacts can be displayed with exact/conservative distinction.
- [ ] Moving/removing a stone restores rest state without regenerating placement IDs.
- [ ] Failure explains root/gap/source/budget/device cause and suggested correction.
- [ ] Reset restores rest pose through the existing population.
- [ ] Artist visual review accompanies numerical acceptance.

## Final decision record

Before production authorization, record:

```text
Selected architecture:
Qualified host/OS/compiler:
Qualified GPU/driver/backend:
Selected renderer/version:
Supported source and collider contracts:
Exact and approximate quality tiers:
Measured crossover ranges:
Peak CPU/VRAM budgets:
Known unsupported cases:
Fallback behavior:
Open issues accepted by product owner:
Evidence artifact hashes:
```

## Current research decision

- [x] Recommend CPU reference + public HLSL pose deformation as first GPU prototype.
- [x] Require Max 2027 public interoperability proof before direct sharing.
- [x] Require matched CUDA/OpenCL benchmark before choosing a solver API.
- [x] Keep compact pose readback as the principal no-zero-copy fallback.
- [x] Require canonical CPU renderer/Bake materialization initially.
- [ ] Production GPU backend authorized — **not authorized by this research package**.
