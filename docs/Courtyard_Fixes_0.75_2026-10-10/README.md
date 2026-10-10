# Courtyard fixes and qualification — 10 October 2026

Scatter **0.75 / package 0.75.0**, paired with the updated **Analyzer 0.14** development script. This fixes measured courtyard issues; it is not full product or 1.0 certification. The baseline was `codex/workflow-0.75` at `f5bc9737378d097cd469d20b32d5576cf10dab01`, with the existing documentation cleanup preserved. Product source was initially clean. No computer use, artist installation or Git push was performed.

## Changes and verified behavior

- [x] **Box, Sphere and Pyramid Proxy use retained instanced geometry.** They share Mesh's existing immutable face/transform snapshots and retained renderer. Shape topology, budgets and source colors remain intact. No per-instance expanded proxy triangle array is prepared in normal operation. GraphicsWindow fallback still reads the same cache.
- [x] **Explicit Update refreshes the root once.** One evaluation stages and installs all layers atomically; it no longer repeats root validation/key construction for each leaf. Ten-layer tests verify one publication, one preparation per layer, last-layer changes, Manual pending behavior and complete failure retention.
- [x] **Installed previews retain the Analyzer revision.** Unchanged Live redraw no longer repeatedly treats the same Analyzer output as new.
- [x] **A successor calculation rejects stale Analyzer guides.** Layout, Analyzer Area and Analyzer falloff dependencies are checked. The last complete Scatter result survives and the error identifies the Analyzer to update. Analyze remains explicit for a Manual Analyzer. An unchanged cached read continues to consume its last publication.
- [x] **Freshness survives save/reopen and merge.** The producer saves the pending flag, input references, settings/transform signature and time-validity interval. Parameter replay while restoring does not overwrite the saved flag.
- [x] **Immediate geometry edits are covered.** A polling node-event queue can be drained before validation, Analyze and save. The delayed notifier retains Live/mouse-release scheduling. Consumed notifications do not later invalidate the analysis they preceded.

Old saved Analyzer guides lack the freshness record and need one explicit **Analyze / Update Analyzer**, then **Update scatter** if Scatter is Manual. Install both matching packages below. No existing scene is silently rewritten to invent a valid freshness record.

The retained resource/shader implementation in `point_display.cpp` is unchanged. Proxy routing and cache construction changed, so the generator integration check now preserves the resource implementation rather than falsely asserting that all of `preview.cpp` is unchanged. The host tests qualify the changed routing.

## Same-scene performance

The original courtyard contains **53,520 placements in ten layers**. Each mode used the same shown subset before/after, the same camera, an 843×741 viewport, three warm-up redraws and 20 camera-mutation/redraw/message-pump samples. Counts and triangle budgets differ **between modes**, not within a before/after comparison.

| Display | Shown items | Triangles | Median before → after | P95 before → after |
| --- | ---: | ---: | ---: | ---: |
| Box Proxy | 23,183 instances | 278,196 | 149.8 → 125.4 ms | 191.1 → 135.8 ms |
| Sphere Proxy | 23,183 instances | 3,894,744 | **937.7 → 116.3 ms** | **986.1 → 126.8 ms** |
| Pyramid Proxy | 23,183 instances | 139,098 | 130.6 → 118.2 ms | 139.6 → 127.9 ms |
| Mesh | 10,930 instances | 17,107,129 | 123.4 → 123.1 ms | 142.7 → 125.6 ms |
| Point Cloud | 127,294 points | 0 | 123.0 → 111.1 ms | 146.7 → 124.3 ms |

Sphere's median synchronous redraw improved **8.1×**. Sphere display-switch preparation measured 2,964 → 1,116 ms. Mesh and Point Cloud switches were slightly slower in this sample (1,099 → 1,149 ms and 1,120 → 1,143 ms); their navigation remained stable. These are wall-clock synchronous operations, **not presented FPS or isolated GPU time**. Background/session variation remains possible; a mixed development session measured roughly 160 ms across several modes, so the final comparison was rerun in a clean private process.

Navigation changed neither placement epochs/preparation counts nor retained generation/resource/upload counters. Retained draw counters advanced with no failure. The Sphere case's old expanded CPU triangle payload was 21,394,240 bytes; that allocation is now zero. Retained snapshots and graphics buffers still consume memory; this is not a total-memory or VRAM figure.

All ten per-layer position/model fingerprints match the baseline. That particular fingerprint hashes positions and source indices; it is not an independent full-matrix/ID comparison. Separate Edit, region and save/reopen regressions cover their stated identity cases.

### Cold Update remains a limitation

The baseline cold Update took 20,874 ms; the final run took 16,568 ms. A warm **forced Update**, which intentionally prepares again, measured 6,706 → 3,609 ms. These single operations are not a statistically controlled cold-start benchmark.

The separate baseline decomposition measured 5,177 ms refreshing ten leaves, 23 ms retained synchronization and **13,636 ms inside the first `redrawViews()`**. The final cold first-leaf/root work was 3,327 ms. Removing repeated root work helps, but it does not eliminate Max's cold viewport realization. The earlier study's 96–120 ms **unchanged cached reads** are a different operation and must not be presented as full Update performance.

## Tests and evidence

| Check | Result and scope |
| --- | --- |
| Max 2027 Release SDK builds | 14 Scatter native tests + 1 Analyzer native test passed |
| Generated UI / catalog | Current generation, namespace/layout checks and 234-control inventory integration passed |
| Python | 141 tests passed; `CyrusMCP/tests tools/tests -q` |
| Focused host tests | 84 assertions: three Proxy shapes, nonuniform transforms, retained drawing/reuse, CPU fallback/recovery, colors, display switching, save/reopen, ten-layer Update and Analyzer freshness/recovery |
| Core and feature campaigns | Core publication; plane/sphere Paint Areas; Manual/Live and spacing; source containers; Relax; Analyzer assignment; Edit persistence passed |
| Exact output / render publication | Source-container exact output, PFlow/bake mapping and atomic failure regressions passed |
| Scatter/Analyzer playback | **942 assertions passed** on the final matched pair, including unrelated/relevant animation, Manual freeze, retained reuse, failures and lifecycle |
| Corona 15 production smoke | 100 placements, Sphere Proxy selected, 320×240, one pass: render completed in 1,409 ms, no bridge error, publication retained and preview helper nonrenderable. Technical geometry smoke only; not material/lighting fidelity or sustained IR certification |
| Packaging | Both archive manifests and payload hashes verified against the runtime-tested modules/scripts; installer execution itself was not repeated |

Primary evidence: [summary](RESULTS.json), [campaign](evidence/campaign.json), [focused checks](evidence/focused-checks.json), [942-assertion log](evidence/playback.txt), [native Scatter tests](evidence/scatter-native-tests.txt), [native Analyzer tests](evidence/analyzer-native-tests.txt), [generated check](evidence/generated-check.json), [render receipt](evidence/render.json), [render image](evidence/render.png), and [package manifest](PACKAGE.json). Raw before/after navigation and Update samples are in `evidence/before/` and `evidence/after/`.

Development failures were used to refine the fix, not relabeled as passes: the first Proxy test measured before queued source-creation notifications had settled; the initial Analyzer guard marked valid reopened data stale during parameter replay; an immediate width edit exposed the delayed-notification gap; merge testing showed that the normal post-merge callback was also necessary; playback caught validation occurring before a cached-read return. The final campaign reran their corrected cases and the complete playback suite. Earlier build/profile directories remain under ignored `build/courtyard-fixes075` and `build/mcp-qualification/courtyard-fixes075-*`.

## Reproduction and delivery

Use an owned redirected Max 2027 profile. Never run resetting fixtures in an artist session. Build with the current `offline_build.py` commands from [the agent workflow](../AGENT_WORKFLOW.md), verify receipt source/native hashes, and load the generated Scatter script plus matching Analyzer script. Load `Max_Procedural_07_Acceptance.ms`, then [Max_Courtyard_Fixes_075.ms](../../tools/procedural_lab/Max_Courtyard_Fixes_075.ms); call `F75Proxy()`, `F75Update()` and `F75Analyzer()`. The [campaign driver](scripts/run_release.py) records the additional fixtures. Copied measurement scripts retain this machine's explicit local workspace/build paths; adapt only their owned output paths for another checkout. The courtyard and plant assets are local, ignored files and are not redistributed here.

The timing/notification design follows Autodesk's [Node Event System](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/GUID-7C91D285-5683-4606-9F7C-B8D3A7CA508B.html) and [file notification contracts](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/General-Event-Callback-Mechanism/GUID-2D8606DF-EF5D-4F5B-A00C-B10D29A14947.html); behavior was then checked in Max rather than inferred solely from documentation.

Install these **together**, then restart Max:

- [Cyrus Scatter 0.75.0 — Max 2027](../../dist/Courtyard_Fixes_0.75_2026-10-10/Max2027/CyrusScatter-0.75.0-Max2027.mzp)
- [Cyrus Surface Analyzer 0.14 — Max 2027](../../dist/Courtyard_Fixes_0.75_2026-10-10/Max2027/CyrusSurfaceAnalyzer-0.14-Max2027.mzp)

These local archives are ignored by Git. The original `Test Scene/Courtyard_Study_075/Courtyard_075.max` SHA-256 remains `e0f32e1cd041c5e71ad5dc58877ddd493ce0eef7927ba0bc5fff96df3b0c9e32`. The test copy is `build/courtyard-fixes075/Courtyard-fixes.max`. Artist files and the normal Max profile were not modified. Source and package identity, rather than the unchanged 0.75/0.14 captions, identify this candidate. The owned test process was closed after verifying its redirected profile; [final protection and delivery checks](evidence/protection.json) record 81 source/binary hash checks and package/link verification. No other Max process was targeted.

## Still open

Cold viewport realization, receiver-local placement stability, long Brush-history/feedback scaling, physical mouse/tablet/all-control acceptance, device-loss and sustained renderer sessions remain open. Max 2026 runtime and an exhaustive scene/asset matrix are not qualified by this run. Continue from the single [maintained backlog](../BACKLOG.md); these fixes do not make every outstanding item complete.
