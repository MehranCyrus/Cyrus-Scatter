# Private retained point display experiment

This is a disposable Max SDK probe, **not a production plugin or installer**. It compares the current Cyrus GraphicsWindow point draw with a persistent Nitrous vertex buffer containing the same exported positions and colors. Product integration and the Preview / Full Detail UI are separate work.

Read the [dated results](../../../docs/Heavy_Scene_Viewport_2026-10-02/RESULTS.md) and [implementation plan](../../../docs/Heavy_Scene_Viewport_2026-10-02/IMPLEMENTATION_PLAN.md) before interpreting the timings. The stock retained point rasterization is finer than the existing marker; equal data does not mean equal pixels.

## Requirements and isolation

- Windows, Python, CMake, VS 2022 MSVC 14.38.33130 and Windows SDK 10.0.19041.0.
- Repository SDK directories under `build/tooling/max2026-sdk` and `max2027-sdk`.
- The existing production 2027 candidate under `build/max2027-release`.
- Max 2027 installed at the launcher's recorded path. Max 2026 is a compile target only in this experiment.
- The launcher copies the earlier experiment's `build/viewport-round2-2026-10-01/desktop.ini`; this dependency is explicit. It redirects startup, plugin configuration and temporary paths into this experiment. It does not disable Max security or alter artist startup scripts.

Only `launch.py` starts the visible private application. Verify its command line and PID in `launch.json` before sending recipes. Do not file-in `bootstrap.ms`, `cleanup.ms` or `shutdown.ms` in an artist session. The fixtures create and delete their own objects; cleanup resets the disposable scene and shutdown closes that process. No artist scene is required or saved.

The dated output location intentionally refuses another launch while `launch.json` exists. For another run, preserve this evidence and use a new consistent output directory throughout the launcher, request script, archive script and cleanup guards. Do not delete evidence just to bypass that guard. Scripts are not a multi-session service; send one request at a time.

## Reproduction sequence

From the repository root, with an unused experiment output directory configured:

```powershell
python tools/performance/native_point_probe/build.py --year 2026
python tools/performance/native_point_probe/build.py --year 2027
python tools/performance/native_point_probe/launch.py
```

Wait for `ready.json`, inspect the visible canopy and verify the loaded-module paths against `input-identity.json`. The readiness record is produced after the helper and existing native Cyrus cache both work. A transport-ready marker alone does not prove successful fixture setup.

```powershell
python tools/performance/native_point_probe/request.py tools/performance/native_point_probe/matrix.ms
python tools/performance/native_point_probe/request.py tools/performance/native_point_probe/population.ms
```

`matrix.ms` measures six point/source configurations. `population.ms` holds the point budget at 250,000 while growing a synthetic table to one million placement rows. All accepted trials use `completeRedraw`, reversed repeat order, warm-up, data identity checks and actual native draw-count assertions. Ordinary `redrawViews` did not exercise the retained renderer on every pilot step; that pilot is excluded.

To repeat presentation tracing, download the official [Intel PresentMon 2.6.0 release](https://github.com/GameTechDev/PresentMon/releases/tag/v2.6.0), verify the digest/signature, and start a trace targeting the PID in `ready.json`. The recorded command was:

```text
PresentMon-2.6.0-x64.exe --process_id <private-Max-PID> --output_file <experiment-directory>/presentmon-official.csv --qpc_time_ms --no_console_stats --session_name CyrusHeavyViewportOfficial --timed 90 --terminate_after_timed
```

During capture, after the population sweep finishes, submit a recipe containing:

```maxscript
HVPBenchmark "points250000-presentmon" frames:240 repeats:3
```

The exact submitted recipe is archived with the evidence. Do not run benchmarks concurrently. Perform real mouse navigation as a separate functional check; this experiment does not calibrate input latency. Then:

```powershell
python tools/performance/native_point_probe/request.py tools/performance/native_point_probe/lifecycle.ms
python tools/performance/native_point_probe/request.py tools/performance/native_point_probe/cleanup.ms
python tools/performance/native_point_probe/request.py tools/performance/native_point_probe/shutdown.ms
```

Verify that the recorded private PID exited. Shutdown writes its acknowledgement before `quitMax`; that acknowledgement alone is not proof of process exit. Cleanup's numeric serialization was corrected after the original run; the raw original and explicit normalization are retained in the archive.

## Analyze and retain

```powershell
python tools/performance/native_point_probe/analyze.py build/heavy-viewport-2026-10-02
python tools/performance/native_point_probe/analyze_presentmon.py build/heavy-viewport-2026-10-02
python tools/performance/native_point_probe/archive.py
python tools/performance/native_point_probe/verify_evidence.py
```

`archive.py` checks that pre-launch source, artist scene and loaded binary hashes still match; copies raw data, images and exact submitted recipes; fingerprints original research inputs; and writes an archive hash manifest. Its dated `machine.json` and shutdown observation are separately recorded host facts, not inferred by the probe. Binaries, original research documents and artist scenes are not bundled.

## Counter definitions and limitations

`cyrusPointProbeStats node` returns:

| Index | Meaning |
| --- | --- |
| 1–5 | Owner point count, contiguous color groups, data generation, PrepareDisplay calls, UpdatePerNodeItems calls |
| 6–9 | Process totals: successful explicit buffer realizations, requested position-buffer bytes, issued point-list draws, initialization failures |
| 10 | Current live custom render items in this probe DLL |
| 11 | Fingerprint of exported positions and normalized source colors, as a string |

Uploads count explicit initialization/realization calls in this code. They do not measure driver bus traffic, residency, or actual VRAM usage. Draw counts include material passes and repeated viewport draws; they are not displayed frames. Byte totals are cumulative requested payload, not live memory. A million float3 positions require 12,000,000 payload bytes before graphics-resource overhead.

The helper supports a transient immutable snapshot, replacement, hide/show and clone sharing. It has no product persistence, hit-testing, selection highlight, controller lifecycle, renderer qualification, device-loss recovery or production fallback. Its limits are two million points and 1,024 contiguous color groups. The owner uses identity transform for exported world-space positions in the measured cases. Full transform/culling/material correctness remains an integration gate.

The DLX exports MAXScript primitives and the helper descriptor; a small DLH registers the helper class. Loading only the DLX is insufficient. Keep both matching binaries together in the private plugin path.
