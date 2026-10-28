# Phased implementation proposal

**Status: P — future work, requiring the user's implementation authorization.** Research identifiers `GP-R0`–`GP-R6` below are not existing project P/I/PG/N roadmap IDs or release numbers. This report does not authorize a version bump or release.

## GP-R0 — establish the actual bottleneck

**Work:** instrument current CPU-to-display stages with one revision ID. Capture small-contact and dense-contact fixtures, K=0 navigation, several retained-pose counts, and camera-only movement. Include old/new neighborhood work, retained-map copying, exact mesh refinement, materialization, upload, publication and presentation.

**Artifact:** raw samples, source/native/script/package identity, memory breakdown and a dominant-stage report. Use an owned Max 2027 profile and scene copies. Existing source correctness tests remain required; historical receipts are not new benchmark execution.

**Gate:** identify a material cost with enough parallel work and a realistic end-to-end gain. If CPU bookkeeping or broad-phase invalidation dominates, fix that within the existing native architecture first. If no hot deformation/fitting stage exists, stop GPU production work and retain this research.

## GP-R1 — public Max pose-buffer proof

**Work:** isolated plugin/sample using SDK-created buffers and `SetBufferParameter`, one simple mesh, a small pose page and a per-instance index. No production solver rewrite. Prove buffer type/usage, shader reads, updates, redraw/style switching and teardown.

**Artifact:** minimal source, build log, exact owned profile, video/screenshot plus numeric readback/control if supported, API/ownership diagram and failed attempts. A runtime failure is an informative outcome.

**Gate:** public API path works on Max 2027 without private casts, leaked host interfaces, or direct unsupported context access. If it fails, resolve with a supported alternative/vendor evidence; do not code a larger compute system around an assumed bridge.

## GP-R2 — exact CPU-pose / GPU-deformation preview

**Work:** port existing `posePoint`/direction/visibility semantics to the proven shader path. Keep CPU fitting unchanged. Share rest geometry; upload only relevant poses/masks; preserve existing simple/rest path. Add deformed bounds, coherent picking, UV/materials, Wireframe and multi-viewport behavior. Renderer/Bake/export use the CPU reference at the same revision.

**Artifact:** per-vertex/normal/visibility parity results across grass, broad fern, flower hierarchy and fixed trunk/leaf models; stage and presented-latency comparison; peak-memory/retirement report.

**Gate:** no guide participation limit or silent deletion, full preview can be shown, unchanged navigation uploads nothing, and meaningful measured end-to-end gain in the selected hotspot. If gains are lost to draw/overdraw, investigate explicit display LOD rather than accelerating an already cheap fitter.

## GP-R3 — bounded publication service, only if needed

**Work:** add the owner/revision/queue contract from [document 08](08_ASYNC_PUBLICATION_AND_LIFETIMES.md), initially with copied CPU packets if useful. Implement one in-flight plus coalesced latest target, complete-generation publication, safe retirement and exact final release. Measure bounded-lag versus strict-latest behavior under continuous drag.

**Artifact:** concurrency/failure campaign and queue-age distributions. No source pointers or Max API calls from workers.

**Gate:** Undo/reset/delete, settings changes, continuous input and shutdown are safe. No result starvation, unbounded generations, obsolete-owner callbacks or mixed masks/poses. Concurrency is justified by observed host stalls, not included as an unrelated rewrite.

## GP-R4 — optional CUDA fitting, compact output first

**Precondition:** fitting still dominates dense active work after GP-R2, and GP-R3 lifecycle requirements are met for asynchronous operation.

**Work:** copy a bounded active list into flat buffers. Implement analytic sphere/capsule/box contact, anchor constraints and independent root groups; then parent levels. Compare against CPU reference and independent analytic controls. Return compact poses/masks/status through a measured CPU bridge to the established shader path. Keep a CPU threshold for small jobs.

**Artifact:** CPU/CUDA/OpenCL matched solver fixtures, residual/quality distributions, transfers, queue age and full-frame behavior. CUDA can be the development candidate; the OpenCL comparator can remain a separate research executable.

**Gate:** actual contact-quality parity and end-to-end improvement. If compact readback is cheap, direct graphics sharing may be unnecessary. If it dominates, attempt the specific sharing route in GP-R5; do not assume full-vertex copyback numbers apply to compact poses.

## GP-R5 — general geometry and direct sharing, separately gated

**Work A:** mesh BVH/SDF or compound proxies only for workloads showing need. Establish sign, error, thin-feature behavior, attachment conflicts, whole-span and leaf-surface checks. Keep qualified exact final verification/fallback.

**Work B:** if measured transfers dominate and public Max integration is available, prototype adapter-matched compute/graphics resource ownership, registration, map/acquire, draw consumption, fences/events and retirement. Source-local SDFs and collision structures remain shared by geometry revision.

**Gate:** each subproject must earn its own result. A successful SDF kernel does not qualify graphics sharing; a shared buffer write does not qualify collision accuracy. Stop a route that depends on undocumented retained-handle internals.

## GP-R6 — qualification and product delivery

Run the selected path through the edge matrix, real Max scenes, hardware tiers, renderer/Bake/export, installer/runtime fallback, long sessions and failure recovery. Profile the same fixtures against the current CPU reference with identical visible populations/quality. Publish exact supported scope and remaining limitations.

Only after user authorization choose a version under the repository policy, update artist/engineering docs, and build a matched Max 2027 MZP from the qualified native/script pair. Separate SDK payloads for older Max hosts require explicit requested scope; this research does not expand support to 2024/2026.

## Scope and sequencing decisions

- Keep the preparation editor and authored classifications; GPU work consumes their results.
- Keep CPU broad phase until measurements identify a need for GPU pair generation.
- Keep static contact semantics. Wind/dynamics and two-way rigid coupling are future work with a separate time/cache contract.
- Avoid a generic backend framework, whole-language rewrite, or several shipping compute APIs in the first change.
- Treat full geometry LOD, texture/overdraw optimization and compute fitting as related but distinct performance topics.
- Preserve the current artist library/shared asset work and dirty tree; isolated research must not replace another task's changes.

Effort cannot be estimated responsibly from kernel size alone. Max public integration, material/normal/picking parity and lifecycle qualification are the high-risk parts. Each gate produces a concrete reviewable artifact before the next expansion.
