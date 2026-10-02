# Integrated Point Cloud results — candidate 0.63

2 October 2026. Decision: keep the retained display integration in the existing Point Cloud mode and qualify it as a Max 2027 test candidate. The original scene comparison shows substantially less CPU-side redraw time with unchanged point data. Automatic wide-to-close detail and broad production qualification remain open.

## Main result

The primary comparison used `Test Scene/SaveSelect 2.max` in a private Max 2027 process, with a maximized application and a **1,302 × 750** active perspective viewport. Preview settings were changed only in memory to Point Cloud, 1,000 samples/plant and a 500,000-point controller budget. The six enabled layers produced **52,143 placements and 447,332 displayed points in 43 source groups**. The budget is divided between layers; unused quota from sparse layers is not redistributed by this change.

Each arm contains three repetitions of 90 camera steps. Lower is better:

| Display arm | Median step (ms) | p95 (ms) | p99 (ms) |
| --- | ---: | ---: | ---: |
| Scatter preview disabled | 22.847 | 41.939 | 57.045 |
| Existing native GraphicsWindow markers | 77.462 | 105.825 | 130.078 |
| Retained native point buffers | **21.836** | **35.646** | **42.464** |

That is **71.8% less median step time** than marker drawing, or about 3.55 times the step throughput in this fixture. The retained result is close to the disabled-preview control. Its slightly lower time than the control is measurement variation, not a claim of negative scatter cost. Other visible scene work already costs more than a 16.7 ms frame budget in this test.

The metric is a synchronous camera-transform change, `completeRedraw()` and message processing measured with a high-resolution host clock. **These are not measured presented FPS or input-to-photon latency.** No new presentation trace was collected for this integrated candidate. The earlier prototype's trace does not qualify this package.

Both active arms use the same candidate's immutable point cache; the switch changes the drawing backend. This is an equal-data comparison against the old drawing path, not a comparison between complete 0.62 and 0.63 binaries. The retained point primitive has a finer raster footprint than GraphicsWindow markers, so equal data is not equal pixels.

Evidence: [raw steps](evidence/run04/artist-maximized-frames.csv), [per-arm counters](evidence/run04/artist-maximized-trials.json), [viewport metadata](evidence/run04/artist-maximized-metadata.json), [retained image](evidence/run04/artist-maximized-retained.png), [marker image](evidence/run04/artist-maximized-gw.png).

## Environment and procedure

- AMD Ryzen 5 5600X, 6 cores / 12 logical processors; approximately 95.9 GiB visible RAM.
- NVIDIA RTX 3090, 24 GiB, driver 610.47; Windows 11 Pro 10.0.26300.
- Interactive 3ds Max 2027.1, build 29.1.0.11426. Candidate script version 0.63, native engine description 0.24; Analyzer remains 0.14.
- Primary case: one active perspective viewport, `smoothhighlights`, maximized and visibly foregrounded before recording. No build was running during the accepted comparison. Adaptive geometry degradation was disabled in fixture setup.
- Full MAXScript GC occurs outside each timed arm, followed by 12 warm-up steps. The middle repetition reverses arm order. All recorded steps are retained; no tail trimming.
- Each arm asserts unchanged snapshot fingerprints, owner generations, explicit buffer initialization/failure counters and placement-build counters. Active retained arms also require native draw calls. These counters measure plugin requests, not driver transfer traffic or completed GPU frames.

See [host/closure evidence](evidence/run04/closure.json), [loaded modules](evidence/run04/ready.json), [binary/script identities](evidence/run04/identity.json), and the [exact benchmark implementation](evidence/harness/benchmark.ms).

A synthetic 5,000-placement / 500,000-point fixture provides a supporting result, also 270 steps per arm:

| Display arm | Median step (ms) | p95 (ms) | p99 (ms) |
| --- | ---: | ---: | ---: |
| Preview disabled | 5.201 | 10.507 | 14.870 |
| GraphicsWindow markers | 63.936 | 104.300 | 212.639 |
| Retained buffers | 5.832 | 11.319 | 15.563 |

The synthetic window was not explicitly foreground-verified at recording time, so use it as supporting evidence, not the primary absolute latency claim. Its marker tail is variable and is reported in full. [Raw data](evidence/run04/synthetic-500000-frames.csv) and [metadata](evidence/run04/synthetic-500000-metadata.json) are preserved.

## Correctness checks

The actual generated controller script and integrated native owner passed the following in the final private run:

| Area | Observed result |
| --- | --- |
| Unchanged navigation | 500,000-point fixture remained visible across 90 camera steps; no placement rebuild, publication change or extra explicit upload |
| Real mouse input | A separate Pan View drag changed the camera and issued native draws with unchanged points, generation, placement builds and upload count; no file-operation event occurred during this accepted check |
| Manual / automatic | Manual held old results until explicit refresh; automatic source changes published new data |
| Modes and visibility | Point Cloud / Proxy / Mesh, preview on/off, layer disable and controller hide/show behaved correctly in tested fixtures |
| Ownership | Clone received its own owner; deletion released it; GC retained live shared data; multiple views reused buffers |
| Undo and persistence | Parameter undo/redo, save/open, removal/recreation of transient display nodes and scene dirty-flag behavior passed |
| Failure handling | Empty source mesh reported its name and aggregate preview error, cleared stale output and recovered when restored |
| Memory guard | Two additional 60 MB payload reservations succeeded; a third exceeded the 128 MiB process limit and was rejected. Original CPU data survived and reservations were released |
| Render data | Display-mode/source-preview checks preserved final-placement fingerprint `12831264586494362244`; PFlow transport evaluated all 5,000 fixture instances and clearing PFlow preserved preview |
| Shutdown | Reset left zero objects, owners and registry entries; private PID 33636 exited |

Sources: [lifecycle results](evidence/run04/lifecycle.json), [hardening results](evidence/run04/hardening.json), [mouse check](evidence/run04/manual-navigation.json), [shutdown](evidence/run04/shutdown.json).

The process failure counter is **1** after the deliberate memory-cap test. Accepted navigation arms require no increase; this is not an unexplained drawing failure. Memory reservations cover float3 position payload only. CPU snapshots, the SDK system copy, driver overhead and transient old generations also consume memory. Integrated cold-edit latency, peak RAM/VRAM and long-session growth still need measurement.

All **nine Scatter native suites passed for each of the 2026 and 2027 SDK builds**. The new preview-sampling suite checks exact budget fill, ordering, uniqueness, small exhaustive cases and large integer boundaries. The unchanged Analyzer suite passed for both SDKs: 20 native suite executions in total. The existing 14 Python report tests also passed during this work; their console result was observed but a separate Python test log was not archived. Native logs are in [2027 build evidence](evidence/builds/max2027/build-2.log) and [2026 build evidence](evidence/builds/max2026/build-2.log).

These checks do not establish a production renderer/IPR session, device-loss recovery, arbitrary source animation/transforms, selected/frozen/layer combinations, save-selected/merge/export, or Max 2026 application behavior.

## Source coverage and visual limits

All **43 original-scene sources** returned samples, including three Corona `CProxy` sources. The earlier research fixture's BushesCenter sampling failure was not reproduced. Its original cause is unknown; this is not a claim of universal Corona proxy support. [Source report](evidence/run04/artist-sources.json).

The corrected budget selector increased this scene from the earlier candidate's 427,506 dots to 447,332 under the same 500,000-point cap. It also fixes the more extreme boundary case where 500,100 candidates used to produce only 250,050 dots with a 500,000 budget. Placement RNG and render transforms are unaffected.

The real-foliage quality fixture used a 228,483-triangle Sambucus shrub source with its source transform unchanged:

- **10,000 shrubs / 500,000 dots:** about 50 dots per shrub. The [wide image](evidence/run04/real-shrubs-10000-wide.png) shows coverage, while the [close image](evidence/run04/real-shrubs-10000-close.png) is visibly sparse. Faster submission alone does not solve close-up detail.
- **50 shrubs / 500,000 dots:** 10,000 samples per shrub. The [focused image](evidence/run04/real-shrubs-50-detail.png) reveals more shape. A subsequent [darker-color mouse-check image](evidence/run04/manual-pan-after.png) improves contrast, but leaf-level accuracy and artist acceptance are not established.

Those are **different populations**, not an automatic LOD demonstration. The candidate does not yet reproduce FStorm's wide-to-close experience in one massive scene. Sampling levels selected by projected size are the next experiment, compared against a simpler increase in the retained point budget.

## Excluded runs and remaining qualifications

The archive keeps alternate run04 timings for transparency. `artist-point-cloud` used the saved multi-view layout without an explicit foreground check and had large transients. `artist-single-view` ran after window activation restored Max to a small window. Neither is combined with the primary maximized result.

Local runs run01–run03 remain under ignored build output. Early harness attempts required fixes to MAXScript scope, camera-target handling and recipe syntax; a product diagnostic's rethrow was corrected before run04. A run03 timing attempt overlapped compilation and exposed GC warm-up sensitivity. They are pilots, not accepted current-candidate measurements.

The first manual-navigation attempt also spanned several minutes, window changes and a display-owner replacement (revision 4 → 1; one new upload). It failed its retention assertion and is not accepted evidence. A save/autobackup callback is a plausible explanation, but was not traced then. The repeated short check added file-event tracing and passed with no file events or buffer uploads. An invalid `max pan` command in one intervening recipe was a harness error; the final check used the visible Pan View button. The failed recipe copies are retained. Do not describe every exploratory attempt as passing.

Next acceptance work: measure cold edit-to-visible latency and peak memory, establish an artist-approved detail target on one heavy wide-to-close scene, then qualify Max 2026, a second workstation/GPU, production rendering and broader lifecycle cases. No fixed FPS guarantee is supported by this result.

## Candidate packages and preservation

The installers are local artifacts, not installed by this test:

| Package | Qualification | SHA-256 |
| --- | --- | --- |
| `CyrusScatter-0.63-Max2027.mzp` | Exact binary/script match to interactive-tested run04 | `602f8db4aab5982f13823feb89602cd85ba50287e2487ac8b9e033c6fd56c183` |
| `CyrusScatter-0.63-Max2026.mzp` | SDK build and native tests; application runtime untested | `4b570c14a6726e67f53bdc6dfbf91cb879189694da78c3454c7f4b29a78f0b36` |

Both are in `dist/retained-point-0.63/`. Read the [installation steps](README.md#try-the-candidate). ZIP integrity and every packaged file hash were verified against the embedded manifest. The 2027 native binary and generated script hashes match the copies loaded in the private Max process.

The original 185,442,040-byte artist file retains SHA-256 `8a40f6a1a5c47eacbbee92920e131f4cae04cfb0de6be1991b4719ea2860bd2c`. Existing installed plugins, previous packages and the boss's 0.62 handoff were preserved. New build output and packages remain in ignored local folders. Curated source, recipes, measurements and images are archived with a byte manifest; no artist `.max`, SDK or native binary is included in that documentation archive.

Run `python tools/performance/retained_integration/archive.py --verify` to check archived bytes. This verifies provenance/integrity, not the truth of every claim or a fresh Max runtime pass.
