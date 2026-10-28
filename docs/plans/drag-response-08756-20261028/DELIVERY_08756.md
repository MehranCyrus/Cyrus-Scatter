# Cyrus Scatter 0.87.5.6 — responsive bending

Delivered 28 October 2026 for **Max 2027 only**, using the user's requested patch label.

[Install the Max 2027 MZP](../../../dist/CyrusScatter-0.87.5.6-Max2027-20261028/CyrusScatter-0.87.5.6-Max2027.mzp) with **Scripting > Run Script**, then restart Max. Install the complete script/native pair. No EXE or Max 2024/2026 payload was produced, and no artist installation was performed.

[Artist controls](ARTIST_GUIDE.md) · [Ownership and implementation scope](PLAN.md) · [Exact qualification and raw samples](QUALIFICATION_08756.json)

## Result and cause

Collider movement now uses a bounded artistic response in Bend/Trim modes. Each relevant guide checks at most four coarse spans per collider and applies one bend. Prepared bounds and geometry are reused; the drag path no longer searches successive bend angles or validates every visible triangle. Complex nearby plants can use parallel CPU work even when fewer than 16 instances are affected. The executed cases used four compute participants. Existing GPU drawing is retained; CUDA/OpenCL simulation was not added.

The delayed feedback had a separate presentation cause. A ready GPU result was waiting on the release-oriented redraw path, and incremental contacts reused a viewport record whose redraw allowance had already been exhausted. Presentation-only redraws now operate while input is held, with a bounded allowance for each new frame ticket. These redraws do not trigger a new placement solve or source preparation.

The campaign also found inactive source-history rows sharing a candidate ID with a replaced collider. Those rows have no live input matrix. Both Cyrus Edit movement and edit replay after changing bend controls now exclude them from contact patches, while preserving their authored history for Undo. This fixes the observed `Native placement index` failures in those two paths.

## Measured viewport scope

Input: `Test Scene/New Plants test 22.max`, loaded with its centimeter units into an isolated Max 2027 profile. The original file was never saved by the campaign; its final hash is recorded in the qualification JSON. Baseline: the preceding 0.87.5.5 build. Final exact package: producer `native-2027-06`, extracted payload `package-payload-06`, owned host `host-final09` under `build/drag08756-20261028-01/`.

The scene contains a 500-request mixed plant layer, a 50-request tree layer, and a 2,000-request small-stone layer. Contact measurements cover **31 accepted reacting Broadleaf Tree – Slender 03 instances**, with approximately 13 nearby candidates and one moving Stone 1 collider. The mixed grass/fern layer remains nonreacting as authored in this scene. This is not a multi-species interaction benchmark or a million-instance qualification.

Each run records 12 movement samples followed by 12 orbit samples, with the drag-held predicate enabled. Ordinary scene-node movement and native Cyrus Edit commands are both exercised. The standard timer requests 200 ms intervals; the faster scene sequence requests 40 ms intervals. Timer intervals are not measured frame rates.

| Case | Median CPU contact fit (ms) | Range (ms) | Compute participants | Distinct presented tickets during 12 moves |
| --- | ---: | ---: | ---: | ---: |
| 0.87.5.5 scene stone / Detailed | 115.57 | 103.81–165.85 | 1 | 1 |
| 0.87.5.6 scene stone / Bend | 29.51 | 24.83–36.83 | 4 | 12 |
| 0.87.5.6 faster scene sequence / Bend | 28.09 | 25.21–33.85 | 4 | 10 |
| 0.87.5.6 Cyrus Edit stone / Bend | 26.82 | 13.75–40.06 | 4 | 12 |

The scene-stone median fell from **115.57 to 29.51 ms** (3.92×). This compares Detailed contact with the simpler artistic Bend response: it is a deliberate quality/performance tradeoff, not identical-physics optimization. The Edit fixture uses the scattered stone's different orientation; its timing is not a direct comparison with the ordinary scene stone.

All 72 final movement/orbit samples reported zero interaction errors and zero failed fits. Source preparation, source capture, collider cooking and layout counters remained unchanged during movement. All measured process-work counters remained unchanged during orbit. Detailed mesh refinement work was zero in the fast response. Actual presented-frame tickets advanced during held movement; the faster sequence coalesced some updates but did not wait for release.

The scene-stone median `redrawViews()` call fell from 141.0 to 48.5 ms; final orbit calls had a 6.0 ms median. These are host-call timings, **not end-to-end viewport FPS**. Isolated-profile textured foliage appeared dark; trunk comparison used Mesh identification display. Material and renderer appearance were not qualified.

## Trunk controls and UI

The primary controls are **Trunk bend**, **Fixed base**, and **Bend fade**, expressed as percentages. Preparation sizes and technical work limits are under **More settings**. Structural root guides carrying branch children are treated as trunks; independent grass roots are not automatically treated as trunks.

The final control check runs after the Cyrus Edit movement, through the same response-setting command used by the UI. All four settings changes succeeded without another source preparation.

| Trunk bend (%) | Fixed base (% height) | Bend fade (% height) | Changed guides | Posed plants |
| ---: | ---: | ---: | ---: | ---: |
| 0 | 0 | 25 | 659 | 3 |
| 100 | 0 | 25 | 714 | 3 |
| 100 | 100 | 25 | 0 | 0 |
| 20 | 30 | 30 | 714 | 3 |

These counts describe guide poses, not a full-mesh clearance certificate. At a 100% fixed base, all guides remained undeformed. Guide hierarchy is geometric preparation data; arbitrary trunks may still need authored fixed regions.

## Persistence and limits

Scene schema **65** and native Interactions capability **15** carry the new controls. Source transform/Undo **2/2**, Edit capability/storage **4/3**, recipe **9**, Library and independent product identities remain unchanged. Scenes saved at schema 64 or earlier with Detailed contact intentionally open in Bend. Existing Bend/Trim choices remain; Detailed contact can be explicitly selected again. Native .max/Scene presets carry the new fields; portable recipes retain their existing narrower response subset.

Fast bending can leave overlap at complex corners, deep contact and rooted regions. Full source geometry, textures and draw limits can still dominate navigation. This patch does not promise exact collision clearance, arbitrary topology support, or universal realtime frame rates.

Verification follows the user's restricted scope: Max 2027 SDK compilation, scripted viewport/stone movement, orbit and trunk-response checks. No Computer Use or physical mouse gesture was used. Native test suites, renderer tests, installer UI execution, save/reopen/Undo campaigns and older hosts were not run. Their previous evidence remains historical. The package's producer receipt says build-only; the separate qualification JSON records the host checks actually executed here.

## Package identity and source record

Archive SHA-256: `1ae8f32491433f258a5ed24b35be09767b1ff8ef6568247deb008afa5e038b04`

| Payload | SHA-256 |
| --- | --- |
| CyrusScatter.ms | `54af240bb3d64f8478121ef9b3239c1626ba144d444904159283b932d817f14c` |
| AminScatter.dlx | `fa1d43a8e5ffd90463a09508191cfc05ca942414abf471b88ff13a46a6753782` |
| CyrusScatterEdit.dlm | `a1e9222f37b994e7d9e6612aa8dac7cc0dbfade0c8c1f8cdf530faff0b607009` |

Archive CRC/integrity, manifest payload hashes, Max 2027 guards, frozen source inputs and loaded native paths/hashes were checked. The loaded script fingerprint matches the packaged script. Source base: branch `codex/workflow-0.75`, HEAD `d24b880816ab367874f417f79d1253aafa9a60f5`, plus the existing working tree and this patch. Unrelated changes were preserved; no Git commit/push, website build/upload or knowledge-index refresh was performed.

Principal code: `interactions_fast_bend.inc`, `interactions_source.cpp/.h`, `interactions_engine.cpp/.h`, `interactions_host.cpp`, `point_display.cpp`, `cyrus_edit.cpp`, `source_authoring_undo.cpp`, interaction templates and generated UI. Reproducible scoped scripts live in `tools/procedural_lab/drag08756/`. Earlier candidate failures and timing observations remain in the owned run directory; only `host-final09` qualifies this final package.
