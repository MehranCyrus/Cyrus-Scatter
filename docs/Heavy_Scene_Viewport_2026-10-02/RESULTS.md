# First loop: retained point display measured in Max

**2 October 2026 — accept the drawing mechanism for product integration; do not package the prototype.** A private native implementation removed most of the repeated CPU cost of submitting an unchanged point cloud. At one million displayed preview points, median synchronous camera-step time fell from **73.194 ms to 3.813 ms**, against **3.305 ms** with both scatter draw paths disabled. The p95 result was **75.746 → 5.617 ms**. These are measured script-driven redraw timings, not completed-frame FPS.

The same positions and source colors were supplied to both drawing paths. The retained stock point-list rasterization produces finer pixels than GraphicsWindow's `POINT_MRKR`. This is a successful mechanism experiment, **not an equal-pixel quality result or a shipped product improvement**. Appearance, source support and controller lifecycle must pass before integration is packaged.

## What was coded

The [private probe](../../tools/performance/native_point_probe/README.md) adds a native helper that owns an immutable point snapshot and persistent Nitrous render items. Each contiguous color group has a float3 vertex buffer and Autodesk stock solid-color material. The host prepares and attaches the items; the item initializes its graphics resources once, then draws the existing buffer on subsequent camera moves. Both paths disable depth testing/writes for these overlay-style preview points.

There is no CUDA/OpenCL placement engine, custom graphics driver, octree, camera-dependent resampling or replacement scatter algorithm. The production native cache builds the point data used by both arms. The new code addresses **repeated CPU point submission**, the bottleneck identified in `AminScatter/src/preview.cpp`.

The experimental owner is transient, non-renderable and deliberately separate from installers. The production controller, generated UI, exact placement/edit data, render path and successful 0.62 work were preserved. The next loop should share a native immutable payload directly, avoiding this experiment's MAXScript diagnostic export and copy.

## Environment and method

| Item | Recorded configuration |
| --- | --- |
| Application | Interactive 3ds Max 2027.1, build 29.1.0.11426, private PID 5008 |
| Native builds | Matching Max 2026 and 2027 SDKs both compiled and linked successfully; application runtime tested only in 2027 |
| CPU / RAM | Ryzen 5 5600X, 6 cores / 12 logical processors; 102,986,215,424 physical bytes, approximately 95.9 GiB |
| GPU / driver | NVIDIA RTX 3090, 24 GiB, driver 610.47 |
| OS | Windows 11 Pro, 10.0.26300 |
| Viewport | Single perspective, 1302 × 750, Standard / Default Shading, Nitrous Direct3D 11; geometry degradation disabled in the private profile |
| Content | Procedural low-poly cone canopies sampled at 100 points per source; deterministic synthetic transform/source rows; no artist scene or heavy renderer materials |
| Arms | Disabled control; current `aminScatterDrawPreview` GraphicsWindow markers; private retained point buffers |
| Trials | Three repeats with reversed middle-repeat order; 12 warm-up camera steps; 120 measured steps per arm/repeat, or 240 in the presentation trial |

The six point/group cases contain 6,480 steps. Three fixed-budget population cases contain 3,240. A separate presentation trial contains 2,160: **11,880 accepted camera steps in total**. `analyze.py` verifies count, generation and fingerprint stability, real native draws during every retained trial, and no additional explicit buffer initialization/realization calls during unchanged navigation. Native owner prepare/update counters also stayed unchanged in those measured intervals.

The controlled metric includes `viewport.setTM`, `completeRedraw` and processing posted messages. It measures synchronous camera-step work in this fixture. It excludes full production controller integration and does not establish input-to-photon latency. Full redraw generated approximately two presentations per script step, so neither inverse step time nor inverse presentation interval is a reliable screen-FPS claim.

See [loaded modules](evidence/ready.json), [machine](evidence/machine.json), [input identities](evidence/input-identity.json), [binary identities](evidence/binary-identities.json) and [computed summaries including p99 and individual repeats](evidence/summary.json).

## Point count and source-group scaling

Values are **median / p95 milliseconds per camera step**; lower is better.

| Displayed points | Source groups | Disabled | Current GW | Retained |
| ---: | ---: | ---: | ---: | ---: |
| 25,000 | 3 | 3.592 / 5.752 | 5.295 / 7.077 | 3.373 / 5.240 |
| 100,000 | 3 | 3.116 / 5.176 | 10.356 / 11.797 | 3.650 / 5.580 |
| 250,000 | 3 | 3.524 / 5.252 | 19.619 / 21.229 | 3.141 / 5.290 |
| 500,000 | 3 | 3.514 / 5.128 | 34.559 / 36.991 | 3.696 / 6.001 |
| 1,000,000 | 3 | 3.305 / 5.394 | 73.194 / 75.746 | 3.813 / 5.617 |
| 500,000 | 32 | 3.677 / 5.833 | 43.754 / 45.774 | 3.811 / 5.847 |

The one-million-point case represents **10,000 synthetic placements**, each with 100 sampled points. It uses two native cache chunks because each production cache caps at 500,000 points. Concatenating those exports gives six contiguous retained draw groups despite three source types. The 32-source case changes sample seeds/colors for the same cone geometry; it tests grouping overhead, not 32 complex foliage assets.

Some retained medians fall slightly below the disabled control. That is measurement variation near the fixture's timing floor, not evidence that drawing points accelerates Max. The useful result is the large, repeatable separation from current per-point CPU submission as the point count grows.

## Growing stored population while holding visible work fixed

This is the test closest to the requested “calculate once” behavior. The exact synthetic transform/source table stays in memory, while the display contains a fixed 250,000-point preview.

| Stored placement rows | Disabled median / p95 | Current GW median / p95 | Retained median / p95 |
| ---: | ---: | ---: | ---: |
| 10,000 | 3.582 / 5.528 | 19.629 / 21.330 | 3.137 / 4.909 |
| 100,000 | 3.325 / 4.982 | 19.723 / 21.726 | 3.630 / 5.701 |
| 1,000,000 | 3.603 / 5.696 | 19.497 / 21.738 | 3.616 / 5.521 |

The stored population did not create a corresponding redraw cost in this isolated retained path. These are **one million data rows, not one million Max scene nodes or fully rendered trees**. At this ratio the preview cannot represent every plant individually. The test establishes separation of stored population and bounded display work; it does not qualify placement computation, editing, renderer preparation or visual coverage of rare plants.

For the one-million-row fixture, initial synthetic row/source preparation took 3,129.258 ms, the native bounded preview build 30.546 ms, and diagnostic export plus native probe copying 101.053 ms: 3,260.857 ms total. The first interval includes fixture source creation/sampling and synthetic row construction, not the production scatter algorithm. These times precede first display. `cold_mode_switch_ms` in case records is an arm switch plus redraw, often after a visual capture has warmed the buffers; it is **not** a calibrated cold edit-to-correct-preview measurement. That product metric remains open.

See the [one-million-row fixture](evidence/points250000-population1000000-fixture.json) and [saved preview](evidence/points250000-population1000000.png).

## Independent presentation trace

An official, valid Intel-signed [PresentMon 2.6.0](https://github.com/GameTechDev/PresentMon/releases/tag/v2.6.0) portable executable captured the 250,000-point / one-million-row case. QPC timestamps align 4,311 presentation records to measured trial intervals on the same main swap chain, **1,437 per arm**, excluding boundary-crossing records. Tool identity is in [presentmon-tool.json](evidence/presentmon-tool.json); raw records and analysis are archived.

| Metric, median / p95 ms | Disabled | Current GW | Retained |
| --- | ---: | ---: | ---: |
| Synchronous camera step | 3.585 / 5.320 | 19.521 / 21.297 | 3.683 / 5.469 |
| Between application presents | 1.834 / 2.945 | 9.858 / 11.162 | 1.905 / 3.026 |
| CPU busy | 1.798 / 2.904 | 9.810 / 11.112 | 1.867 / 2.987 |
| GPU busy | 0.688 / 1.294 | 1.579 / 3.124 | 0.748 / 1.482 |

This supports the diagnosis that repeated CPU submission was expensive. GPU busy is whole application/frame work, not isolated plugin GPU time; the retained point footprint also differs, so the GPU difference cannot be assigned entirely to retention.

Every recorded presentation uses `Composed: Copy with GPU GDI`. Available display-change intervals have a median near **16.67 ms for all arms**; many rows have no display-change measurement. Do not turn the approximately 1.9 ms presentation interval into a 500 FPS claim. There was no calibrated input-latency measurement. PresentMon's [metric definitions](https://github.com/GameTechDev/PresentMon/blob/main/README-ConsoleApplication.md) distinguish application work, GPU activity and display timing.

## Visibility, ownership and cleanup

- Saved GW and retained images show the same canopy locations and colors. The retained cloud is visibly finer; [25k GW](evidence/pilot-gw.png) and [25k retained](evidence/pilot-retained.png) make that difference easy to inspect. A future point-size option or a deliberately accepted fine-point preview needs its own quality test.
- Two actual mouse pan strokes moved the viewport with one million stored rows and the 250k-point preview active. The observation interval recorded 1,977 additional native point-list draws, unchanged data and zero extra explicit buffer realizations. This is a functional navigation check, not a mouse FPS measurement. See [gesture.json](evidence/gesture.json).
- Twelve replacement / hide-show / clone-delete / clear / restore cycles passed. Each restore kept the original point count and fingerprint. Every clear returned the live custom-item counter to zero. Cloning preserved the immutable snapshot; broad transform correctness remains unqualified.
- A four-viewport layout reused the existing point buffers without extra probe initialization. Selection did not change data, but point hit-testing and highlight are deliberately unimplemented in this helper.
- Process private bytes stayed at 4,070,985,728 throughout the final twelve-cycle sample; working set remained around 2.59 GiB. This short observation is not proof of leak freedom or a 32 GB machine qualification. One million float3 positions request 12,000,000 buffer payload bytes, excluding driver/resource overhead; actual VRAM allocation was not measured.
- Scene reset released all custom render items. The empty witness reported zero points, zero live items and no initialization failures. The redraw callback was unregistered, the request timer stopped/disposed, and the known private process exited. No test startup entry was installed in the artist profile.

Evidence: [lifecycle](evidence/lifecycle.json), [multiple views](evidence/lifecycle-extra.json), [reset](evidence/cleanup.json), [shutdown observed](evidence/shutdown-observed.json). Counter definitions and limits are in the [probe runbook](../../tools/performance/native_point_probe/README.md). “Zero uploads” throughout this report means zero additional explicit initialization/realization requests in our code, **not a capture of all GPU bus traffic or driver residency changes**.

## Rejected attempts and evidence corrections

The first `redrawViews` pilot did not execute the retained renderer on each step. Its attractive timing is rejected and kept under `evidence/rejected/pilot25k-*`. The accepted protocol uses `completeRedraw` and asserts draw-counter increments. Initial launch attempts exposed MAXScript syntax issues and the need for a DLH class-registration bridge alongside the DLX; those failures are retained and excluded from timing results.

The locally available older FrameView PresentMon executable exited without a CSV in two attempts. Its cause was not established; the accepted capture uses the independently verified Intel release. No absent trace is treated as evidence.

The first lifecycle export emitted MAXScript Integer64 suffixes; the serializer was corrected and all twelve cycles rerun. The successful final reset export also contained numeric `L` suffixes: its original text is preserved alongside strict JSON with only those suffixes removed, plus an explicit [normalization record](evidence/normalization.json). The checked-in cleanup recipe now casts those counters. Exact as-executed recipes are retained under `evidence/recipes/`; the later serializer fix must not be mistaken for a rerun.

## Decision and next implementation

**Proceed with retained preview integration, with a quality gate.** The result justifies a small native display owner and persistent buffers. It does not justify adding GPU placement, a complex adaptive hierarchy or an asynchronous engine now. The first product milestone is:

1. Integrate one owner per controller with immutable native payload sharing and explicit generation/lifetime handling. Publish complete updates on the host thread.
2. Add the requested **Fast Preview / Full Detail switch** in the authoritative UI generator. Preserve exact placement/render data and each mode's settings; report active caps honestly.
3. Choose point footprint, preview density and colors using bird's-eye and close-view quality comparisons. Keep current drawing as observable allocation/error fallback.
4. Qualify source conversion, especially the earlier BushesCenter/Corona proxy sampling problem, before claiming the original artist scene works in retained point preview. Unsupported sources must not silently disappear.
5. Pass undo/redo, save/open, edits, controller deletion, selection, multiple controllers/views, renderer/IPR and device-recovery gates. Then test actual Max 2026 and a representative larger foliage scene before producing a new handoff package.

Full Detail needs its own matched-geometry retained display experiment, followed by source sharing/instancing if warranted. A preview result does not make unlimited full-detail geometry free. Spatial chunks and prebuilt levels remain later options if a fixed preview budget cannot meet visual quality or GPU cost targets.

## Preservation and reproduction

All eight recorded pre-launch input hashes still match, including the production script, current native binaries and `Test Scene/SaveSelect 2.max`. Original scene SHA-256: `8a40f6a1a5c47eacbbee92920e131f4cae04cfb0de6be1991b4719ea2860bd2c`. This loop did not modify production implementation or the boss's installers. Existing dirty work remains present.

The [runbook](../../tools/performance/native_point_probe/README.md) lists builds, launch guards, recipes and analysis commands. [Archive manifest](evidence/manifest.json) fingerprints raw CSV/JSON, screenshots, exact recipes, probe source and build logs. Original research inputs and binary files are fingerprinted rather than duplicated. `verify_evidence.py` checks archived hashes, the accepted trial counts, retention counters, lifecycle results, shutdown and preservation. The [roadmap](ROADMAP.md) records completed work and remaining gates.
