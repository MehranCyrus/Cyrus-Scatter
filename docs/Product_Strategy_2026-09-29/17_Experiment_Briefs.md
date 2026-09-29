# 17 — Bounded experiment briefs

These briefs convert attractive ideas into answerable engineering questions. No experiment below is implemented by this review. Each preserves a baseline and ends with accept, revise or defer.

## X1 — First CPU optimization

**Question:** which measured repeated query/allocation dominates a flagship operation?

Choose one: prepared boundaries, exact projection index, Analyzer raster preparation, preview grouping, or a complete visibility cache. Use the actual production path. Compare total operation, preparation/query split, memory and small-workload crossover.

**Correctness:** same original face/segment ties, RNG consumption, order, thresholds, errors and edit fingerprints. Test degenerate/tilted/stacked geometry and invalid inputs.

**Go:** common performance gates pass and the change is maintainable. **Stop:** cost shifts elsewhere with negligible useful savings, or legacy identity cannot be retained. A losing index should not remain enabled merely because its asymptotic complexity looks better.

## X2 — Bounded CPU parallelism

**Question:** does one independent native stage benefit from controlled parallel work inside a loaded DCC process?

Prerequisites: X1 or equivalent optimized baseline, owned immutable data, pinned compatible executor. Compare serial and 1/2/4/higher participants at several grain sizes, idle and under renderer contention.

**Correctness:** disjoint outputs, fixed per-row arithmetic, ordered errors/compaction, no host calls on workers, clean join/reset/shutdown. Include executor initialization and dependency loading costs.

**Go:** whole operation improves above a measured crossover without harmful p95 or memory effects. **Stop:** thread/runtime conflicts, nondeterminism, or renderer interference outweigh gains.

## X3 — Max 2027.2 Point Instance transport

**Question:** can a supported Points/instance interface express current Cyrus output faithfully and prepare it more efficiently?

First discovery deliverable: exact runtime/SDK/sample availability and a capability table for source choice, affine transforms, IDs, materials, animation, lifecycle and target renderers. The overview pages are not sufficient API documentation.

Prototype one source, then several sources with mirrored/nonuniform transforms and edited results. Compare against PFlow on the same scene using count/matrix checks and fixed render images. Record preparation/translation/peak memory separately.

**Go:** required mappings are supported and the intended renderer combination wins meaningfully. **Stop:** unsupported transform/material/proxy semantics, uncertain cleanup, missing public API or no useful gain. Retain PFlow/other qualified output for 2024–2027.1 and unsupported renderers. Never change the saved authoring model merely to test transport.

## X4 — Retained viewport prototype

**Question:** does repeated GraphicsWindow submission dominate steady navigation after CPU cache work?

Use matching SDK samples to build a small retained display adapter around existing selected placements. Compare point/proxy/full modes at matched budgets, viewport resolution and camera path.

**Correctness:** stable selection, bounds, hit testing, source transforms/colors, occlusion, high DPI, device changes, reset and unload. Keep authoritative placements unchanged.

**Go:** navigation frame-time improves without unacceptable rebuild/memory cost. **Stop:** picking or device lifecycle remains unreliable, or draw submission was not dominant.

## X5 — OpenCL preview transforms

**Question:** does optional GPU compute beat the accepted threaded CPU path after all data movement?

Use the actual live point-preview selection and cap. Measure probe/startup/program build, unpack, upload, kernel, download, regroup, publish and draw. Cover changed/unchanged source data and renderer contention.

**Correctness:** same selected indices/group order. Any display tolerance has explicit world/screen bounds and cannot affect saved edits, picking or final output. Test unavailable runtime, build/allocation failure and a bounded memory policy.

**Go:** useful total gain on a documented workload/device range with clean CPU fallback. **Stop:** transfers dominate, a driver issue threatens host stability, or qualification cost is disproportionate. Cross-vendor claims require actual named devices.

## X6 — Field Helper input

**Question:** can artists use a host field to control a Cyrus rule predictably?

Begin with one scalar control and a documented host sampling path. Compare a simple known analytic field with the sampled result. Check space, units, bounds, transforms, animation/time, dependency invalidation and sample cost.

**Go:** rule values and updates are reliable, with a documented older-host strategy. **Stop:** no suitable public interface, uncontrolled shader/host thread access, or unacceptable sampling cost. An explicit baked approximation is a separate user choice.

## X7 — Static USD instance export

**Question:** can one named downstream application render an evaluated Cyrus snapshot faithfully?

Export prototype references and stable per-instance data with units/up axis and dependency paths. Test materials, transforms, negative scales and unsupported shear. Reimport or inspect against golden transforms; compare the chosen downstream render.

**Go:** the selected snapshot workflow passes and limitations are explicit. **Stop:** silent material/transform loss or reliance on unsupported proprietary proxy data. Live procedural round trip and animation are excluded from this first experiment.

## X8 — License policy prototype

**Question:** can one pure policy serve authoring, scene viewing and clean render workers without harming continuity?

Use a fake provider, explicit release metadata and a table covering no-license/trial/offline/perpetual/floating/outage states. Exercise maintenance boundaries, clock/device recovery, multiple modules/sessions and operation-scoped decisions.

**Go:** policy outcomes are understandable and all saved-scene/render cases preserve fidelity. **Stop:** offline promises conflict with expiry, runtime classification silently unlocks authoring, or one shared authority cannot be loaded consistently. Provider procurement follows this test, not the reverse.

## Common experiment record

Record task/owner/date, question, baseline and candidate hashes, fixture/environment, expected benefit, predeclared gates, raw samples, exact correctness result, resource/failure behavior, actual engineering effort and decision. A result marked deferred still counts as useful research when it prevents an expensive wrong turn.
