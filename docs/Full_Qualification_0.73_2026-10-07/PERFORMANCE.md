# Measured performance — matching 0.73 build

7 October 2026. Final owned Max 2027 process **51112**, `real073-ui-assets08`. 
Full script SHA-256: `15390e733aac8a02433bfbc938f61fbe95f7f41eb35102baedf100dfe6c1a268`. Native identities are in the build receipts and package manifests; prior 0.73 candidates are not substituted.

Hardware: Ryzen 5 5600X, six cores/twelve logical processors, 102,986,215,424 bytes physical RAM, RTX 3090. The artist Max remains open and untouched. This is a controlled owned-process workload, not an otherwise isolated machine. Resources include assets, renderer, Max, driver and the private 200 ms diagnostic transport; they are not exclusive Cyrus allocations.

## Rebuild and publication

Each row is one completed requested rebuild, including generation/publication and its redraw work. It is not a pure solver microbenchmark, startup time or statistical scaling curve. Resource sampling and transport elapsed time are separate.

| Scene / requested population | Accepted plants | Measured rebuild/publication ms | Whole-host CPU delta, s |
| --- | ---: | ---: | ---: |
| garden_60000 | 17,198 | 2355.18 | 5.219 |
| garden_100000 | 24,613 | 2550.08 | 5.281 |
| stress_10000 | 10,000 | 672.88 | 3.359 |
| stress_50000 | 50,000 | 1007.52 | 3.781 |
| stress_100000 | 100,000 | 993.69 | 3.797 |

The garden has five parent layers/eight sets. Its final accepted counts are **65, 15, 83, 101, 414, 3,460, 20,394, 81**, total **24,613**. The requested meadow population is 100k and painted-walk population 30k; their coverage/areas/spacing deliberately reject many candidates. The separate flat stress field accepts exactly **100,000**, with all 15 plant types present. A point budget is not a plant count.

## Warm navigation and retained drawing

Eight warm redraws precede twenty camera steps per mode. The viewport is **1176 × 750**. These are synchronous completed-redraw timings, **not presented FPS**. All five modes retain placement, preview, membership and upload counters during the measured navigation. Drawing counters advance when Max draws; those are not mistaken for calculation.

| Mode | Drawn representation | Median synchronous ms | p95 synchronous ms |
| --- | --- | ---: | ---: |
| Preview off | No scatter preview; cached shown metadata retained | 24.87 | 32.82 |
| Point Cloud | 300,000 points for 100,000 plants | 24.19 | 47.65 |
| Proxy | 100,000 boxes / 1,200,000 triangles | 1075.44 | 1132.19 |
| Mesh | 839 admitted plants / 19,999,083 expanded triangles | 27.55 | 31.89 |
| Centres | 100,000 centres | 21.82 | 53.87 |

The Mesh budget reuses 15 source geometries totalling **3,048,092 source faces**, rather than creating 100k full unique meshes. Its measured CPU retained mesh payload is **329,234,208 bytes** (about 314 MiB), against 512 MiB CPU/1 GiB GPU admission budgets. Reported admission budgets are limits, not measured GPU allocation. Mesh displays a budgeted subset, not all 100k plants.

**Proxy is the measured weak path.** Its cached boxes still have immediate submission cost on each draw. Retained Point Cloud/Mesh improvements are preserved; `preview.cpp` and `point_display.cpp` are unchanged. Do not promise huge Proxy FPS or recommend GPU placement to solve this draw-only finding.

## Actual playback and presentation

An unrelated animated car runs for ten seconds in each case after warmup/settling. The five primary cases have no epoch, preparation, preview, membership, bridge or retained-upload changes. The extra two-case test explicitly changes controller Enable, separately from merely turning preview off. Those transitions occur before the quiet playback baseline.

| Case | Selected-chain samples | App interval median / p95, ms | Display-change interval median / p95, ms |
| --- | ---: | ---: | ---: |
| stress-playback-0-1 | 195 | 17.38 / 26.45 | 16.67 / 33.35 |
| stress-playback-1-1 | 534 | 17.88 / 29.46 | 16.69 / 36.51 |
| stress-playback-1-2 | 518 | 18.96 / 25.55 | 16.68 / 36.54 |
| stress-playback-3-1 | 540 | 17.74 / 24.76 | 16.68 / 33.33 |
| stress-playback-3-2 | 496 | 19.55 / 26.77 | 16.75 / 36.53 |
| stress-enabled-0-1 | 197 | 16.00 / 26.58 | 16.67 / 33.32 |
| stress-enabled-1-1 | 553 | 17.50 / 23.70 | 16.67 / 33.33 |

`playback-0-1` is preview off/Manual; `1-1` Point/Manual; `1-2` Point/Live; `3-1` Mesh/Manual; `3-2` Mesh/Live. `enabled-0-1` disables the controller; `enabled-1-1` restores enabled Point/Manual.

PresentMon 2.6.0 uses QPC-aligned windows and chooses the dominant swap chain per phase. The selected modes are composed GPU/GDI copy. Off/disabled arms yield fewer selected-chain rows than the visible arms, so these are **limited presentation samples**, not an input-to-photon or guaranteed screen-FPS benchmark. `DisplayedTime` and `DisplayLatency` are unavailable. Do not divide the synchronous redraw median into an FPS claim or infer all gaps/other chains from the interval median.

## Whole-process memory

- Private committed memory: **6.94–7.83 GiB** across these samples.
- Working set: **4.30–4.87 GiB** across these samples.
- Owned-process dedicated GPU counter: **2.27–2.65 GiB**. Shared memory is reported separately in the receipts.

These are finite before/after samples, not a calibrated peak, exclusive plugin VRAM, or a long-session leak certificate. Mesh uploads and display-mode switches have expected memory cost. The host includes high-polygon sources/materials even when scatter preview is off.

## Idle, diagnostics and renderer scheduling

The final `full073-core-idle05` campaign passes eight ten-second idle/edit/failure/recovery cases after settling, including open retained native sections. With no relevant edit, calculation, membership, render keys and unchanged-buffer uploads stay unchanged and plugin scheduling timers stop. Max drawing and the private diagnostic transport can still consume host CPU; this is not a literal zero-process-CPU claim.

The separate diagnostic-overhead experiment alternates 48 rebuilds: median recording off **251 ms**, on **252 ms**. It measures the whole small host fixture, not isolated event-recording cost or a guaranteed percentage overhead. The bounded recorder remains opt-in and requires no MCP.

Real Corona 15: all **4** strict twelve-second quiet windows pass (no edit, IR idle, after one edit, after Stop). One real recipe edit produces exactly one IR Stop/Start and one complete successor epoch/bridge. Actual Stop reaches an empty bridge and stopped timer without forced cleanup. Four-pass 600 × 420 production render takes **22,615 ms**, builds one bridge and preserves the solver epoch; IR pixels are 800 × 560. Both saved images were visually inspected. These are scheduling/render proofs, not final material or image-quality certification.

The garden is resaved with the supplied original render settings (1400 × 980, 24 production passes and original thread/IR limits), rather than leaving the four-pass fixture settings. It opens Manual/Point Cloud with automatic exact rendering enabled. Stress opens Manual/Point Cloud with exact render disabled.

## Remaining performance and correctness gates

- First cold pointer Undo/Redo lost its stack, while the controlled pointer repeat and separate cold-load asynchronous whole-node test pass. Cause remains unisolated; see RESULTS and ROADMAP. No heap enlargement or Undo disabling is claimed as a fix.
- Retained Proxy experiment; long sessions and repeated display/source-memory churn.
- Projection scaling, exceptional-radius neighbor selectivity and aggregate wide-Brush derived-state bounds from the independently reproduced 6 October R&D. They were not rerun as part of this real workload.
- Final pointer border resize, all DPI/tablet cases, docked IR, other renderers and all control combinations.
- Seven original missing material-map placeholders; authored source-material fidelity remains partial.

Concrete source/SDK receipts, all failed observations, final measurements and scene/package fingerprints are indexed under `evidence/`.
