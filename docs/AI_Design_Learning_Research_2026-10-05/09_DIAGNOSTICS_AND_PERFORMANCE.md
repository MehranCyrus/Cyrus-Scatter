# Diagnostics, renderer stability and performance

## The immediate reliability issue

The [Autodesk second pass](15_AUTODESK_HOST_CONTRACTS.md) adds callback-phase, observer-lifecycle and worker-mode tests to this investigation. Existing `#preRender` setup is not proven invalid by restrictions on `#preRenderFrame`. Cache validity and the interval passed to `NotifyDependents` must be treated separately. Record evidence before changing either; the IR cause remains unresolved.

The user reports that production rendering works while Corona IR repeatedly refreshes. A read of the existing private-session log confirms **485 render-start markers between 12:03:04 and 12:06:23 on 5 October**, as written in the renderer's local timestamps. [Observation receipt](evidence/renderer_log_observation.json).

This is a read of existing evidence, not a new runtime reproduction. The initiating notification/callback has not been isolated. The log does not establish a licensing cause. Earlier successful production renders do not qualify interactive rendering.

The source contains several relevant paths: `CyrusPFKey`/`CyrusPFTickImpl` in [the generated script](../../AminScatter/scripts/AminScatterObject.ms), lines 4634 and 4741; procedural/container events around lines 3973–4008; retained publication and `NotifyDependents` in [point_display.cpp](../../AminScatter/src/point_display.cpp), lines 261–268. These are investigation points, not confirmed defects.

## A bounded IR investigation

Use a disposable scene and isolated profile with a verified matching script/DLL pair. Preserve the existing artist host. Record the original scene/render settings and reproduce one stable-camera IR interval before changing anything.

Trace one causal chain: input event → affected controller/leaf → invalidation reason → before/after input revision → evaluation/cache decision → publication epoch/digest → retained buffer upload → render bridge rebuild → IR stop/start or host notification.

Measure idle, camera-only motion, rollout browsing, source movement, spacing change, Brush edit and manual update separately. Correlate repeated render starts with publication changes and notifications. If epochs and transform digests remain unchanged while IR restarts, focus on display/notification paths. If geometry keys keep changing, identify the changing dependency before suppressing renderer refreshes.

Use controlled temporary diagnostics to isolate one mechanism at a time: render bridge scheduling, container dirty events, retained publication notifications and UI timers. Any disabling is a diagnostic condition, not a production fix. Compare enabled/disabled traces with the same camera/scene. A missing texture or map plugin is a separate recorded condition, not an automatic explanation for every restart.

Acceptance includes a stable idle render, expected update after one relevant edit, no missed geometry change, no stale exact output, and recovery after stop/restart. Define the idle interval and pass/time policy before the test. A proposed initial soak is ten minutes plus repeated relevant edits; qualify longer workloads before large batches.

## Existing logging and proposed additions

Current tools provide selected-controller performance snapshots, detailed edit traces and a bounded MCP operation journal. Build on them. Add a unified event vocabulary and correlation IDs instead of a second independent logger for each feature.

Proposed event fields: schema/version, monotonic timestamp and wall-clock timestamp, process/session ID, operation/study/candidate IDs, controller/layer/set IDs, publication epoch, event kind, reason, old/new dependency digest, cache result, elapsed duration, work counters and error code. Keep source/input hashes rather than full scene dumps by default.

Useful events include `input.changed`, `invalidation.requested`, `evaluation.started`, `cache.hit`, `stage.completed`, `publication.committed`, `publication.failed`, `display.uploaded`, `render.requested`, `render.completed`, `render.cancel_requested` and `scope.stale`. The names are proposed, not currently instrumented.

OpenTelemetry's correlation model is a useful reference for trace/span IDs and common resource context. Adopting compatible fields does not require deploying a collector or a distributed observability stack for the local pilot. [OpenTelemetry logs](https://opentelemetry.io/docs/specs/otel/logs/).

## Logging must not perturb the system

Use a bounded in-memory ring buffer and off-thread file serialization of copied data. Cap field sizes, disk usage and event rate; record dropped-event counts. Make verbose tracing an explicit diagnostic mode. Never call an evaluator just to populate a log message.

In current source, `procInputKey` invokes container refresh and a density watcher. Therefore a passive logger should observe keys/revisions already computed by the execution path, not poll `procInputKey` as though it were a pure read. Add coverage for the direct procedural invalidation path rather than relying exclusively on legacy wrappers.

Measure logging overhead in idle navigation, brush interaction, dense evaluation and rendering. Set the acceptance margin before the campaign using baseline variability. No universal negligible-overhead claim is justified without measurement. Failure to write a diagnostic file should degrade logging visibly rather than corrupt the scene transaction.

## Performance contracts for design learning

| Contract | Required behaviour |
| --- | --- |
| Camera/UI navigation | No placement regeneration or unchanged-buffer upload solely from browsing, except an explicitly documented relevant camera-dependent feature |
| Retained display | Preserve measured Mesh/Point Cloud behaviour and ownership; compare upload/build counters as well as timing |
| Host thread | Typed scene reads/writes and publication occur on the supported host thread; inference stays outside |
| Candidate work | Admit bounded samples/attempts/rounds/neighbor visits before work; report shortfall and limit outcomes |
| Memory | Bound simultaneously resident candidates, images, layout arrays, render state and model weights; count process RSS separately from GPU reservations |
| Cancel | Stop future work promptly; distinguish requested cancellation from confirmed completion/rollback |
| Metrics | Separate generation, render preparation, actual render, inference, serialization and UI presentation time |
| Cache | Reuse only when the exact relevant inputs match; do not reuse a stale image because the recipe name is unchanged |

Existing native ceilings are not a promise that every admitted scene is fast or memory-safe under all host conditions. In particular, candidate admission counts do not directly express byte size. Benchmark actual allocation and peak memory with realistic source meshes and renderer assets before raising limits.

## Multi-fidelity generation

Use cheap deterministic validation and geometry statistics first. Then capture consistent low-cost previews for valid candidates. Render only a smaller set of finalists under a fixed profile. Eventually learn a surrogate for expensive visual outcomes only if it predicts them on held-out candidates.

Do not compare a noisy low-pass render against a clean finalist and interpret the choice as pure planting preference. Store fidelity and, when comparing across fidelities for research, make that the explicit experiment. Use the same cameras/lighting/assets within a comparison.

Production rendering can be the initial batch path after a render-job contract is qualified. It is currently a local capability, not an existing public MCP render tool. IR remains a separate interactive requirement.

## Capacity planning without invented speed

Estimate `total_time = context_setup + sum(generation + capture/render + feature_extraction + serialization) + review_time`, adjusted for measured safe concurrency. Measure the terms on a pilot; do not assume perfect overlap.

Illustrative arithmetic only: 1,000 candidates at 20 seconds each require about 5.6 serial hours; at two minutes each they require about 33.3 hours. Two stored 1 MB images per candidate use about 2 GB before layouts, masks, scenes and backups. A 1,000-comparison review at 15 seconds per comparison consumes about 4.2 hours of artist attention. None of these rates is a Cyrus measurement.

The scarce resource may be artist attention rather than GPU throughput. Active selection, near-duplicate removal and good reference recipes should be evaluated before buying more generation capacity.

Preserve the distinction between synchronous redraw time and presented FPS. Do not convert a callback duration into a promise of unlimited frame rate. Include scene complexity, host/renderer state and measurement method in every performance report.
