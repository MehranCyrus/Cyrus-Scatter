# Stage 07 — Product support matrix

## Goal

Choose a beta scope and establish exactly what configurations can be demonstrated or advertised.

## Why this matters

A plugin loading in Max does not prove rendering, interactive updates, old scenes, farms, or low-memory workloads. This matrix directly governs landing-page claims.

## What we currently know

**VERIFIED BY TEST:** previous Max 2027.1 batch smoke and seven native suite results, with the limits in [98](98_Repository_Review_and_Deliverables.md). **VERIFIED IN SOURCE:** 2026/2027 target configuration and Corona-specific rendering code. Required product target remains Max 2024–2027 and a 32 GB minimum workload qualification target.

The actual tested updates, renderer builds, OS and workload must be recorded. Use [quality/release strategy](../Product_Strategy_2026-09-29/10_Quality_Qualification_and_Release.md) and [Autodesk host strategy](../Product_Strategy_2026-09-29/06_Max_2024_2027_and_Autodesk_Opportunities.md). Any vendor host/renderer support is not a Cyrus test.

## My tasks

- [ ] List hosts/renderers you can actually test.
- [ ] Run selected MT cases and keep results against exact configuration rows.
- [ ] Arrange a second workstation/operator where possible.
- [ ] Choose provisional beta scope and clearly excluded workflows.
- [ ] Update allowed claims only when the evidence changes.

## Engineering / Codex tasks

- [ ] Prepare per-year binaries with matching SDK/toolchains.
- [ ] Build version-compatible scene builders; a saved newer .max file may not open in older hosts.
- [ ] Qualify installation, persistence, render/IR lifecycle and clean workers.
- [ ] Establish real 32 GB and Intel/AMD coverage plus ordinary viewport and optional-compute-absent behavior.
- [ ] Capture reproducible logs/counts/transforms and release identity.

## Boss / Product-owner decisions

Choose the first beta/release scope from tested rows and known limits. A limited beta can begin before the full required host range is qualified, if explicitly described. Advertising 2024–2027 support still requires completing that requirement.

## Step-by-step procedure

1. Fill exact package, host/build, renderer/build, OS and hardware before testing.
2. Start on the working 2027.1 baseline. Run basic creation, nonempty edits/reopen and a small actual render.
3. Add renderer/IR tests separately. A Corona pass does not establish V-Ray CPU/GPU or Arnold behavior.
4. Test lifecycle and install/rollback using disposable profiles/processes.
5. Prepare older-host rows and second-workstation/farm tests when access exists.
6. Record evidence, exclusion or missing access. Do not use NOT APPLICABLE merely because a required test could not be run.
7. Copy the permitted wording to the claims matrix; preserve narrower claims for narrower evidence.

## Support verification matrix

WORKS in this matrix means a specific test passes. Advertised support requires the complete selected regression set and engineering signoff.

| Item | Current evidence | Required test | Test owner | Result | Allowed claim now |
|---|---|---|---|---|---|
| Max 2024 | Required port; no target in shared config | Matching build + create/edit/save/render/install | Engineering + you/host tester | NOT TESTED | Target only, no support claim |
| Max 2025 | Required port; no qualified build | Same per-year suite | Engineering + host tester | NOT TESTED | Target only |
| Max 2026 | Source configuration present | Build and runtime matrix | Engineering + host tester | NOT TESTED | Configuration exists; no qualified support |
| Max 2027.1 / 29.1.0.11426 | Retained isolated smoke 2026-09-28 | Normal-profile UI, mutations, renderer and lifecycle | You + engineering | PARTIAL | Internal “batch smoke tested on 2027.1”; broad support held |
| Other 2027 updates, including 2027.2 | Vendor context; no local Cyrus qualification | Matched runtime; API changes and full affected cases | Engineering + you | NOT TESTED | No inferred update support |
| Windows | Host requirements referenced in strategy; exact runtime qualification incomplete | Record actual Windows/build + clean-user dependencies | Engineering + you | NOT TESTED | Hold product OS/minimum claim |
| Point Cloud/Proxy/Mesh | Cache/box construction in smoke; UI/draw quality pending | MT17 navigation, bounds, selection, budget and DPI | You + engineering | PARTIAL | Source display choices; no FPS guarantee |
| Corona production | CProxy/PFlow code | MT32, materials, mirrored/nonuniform, proxy cases | Renderer tester + engineering | NOT TESTED | No certified Corona support |
| Corona IR | Timer/start/stop source | MT33, source changes, save, abort/restart, cleanup | Renderer tester + engineering | NOT TESTED | Implementation present; qualification pending |
| V-Ray CPU production / interactive | No current rendered proof | Separate MT32/33 fixtures with exact build | Renderer tester + engineering | NOT TESTED | No V-Ray support claim |
| V-Ray GPU | CPU support would be insufficient | GPU renderer cases, memory, materials and lifecycle | Renderer tester + engineering | NOT TESTED | No GPU renderer claim |
| Arnold/other renderer | No current image proof | Selected host/PFlow render; optional Point Instance separately | Renderer tester + engineering | NOT TESTED | No blanket renderer claim |
| Command-line/batch rendering | Batch smoke is not an actual render | Fresh process, no prior preview, assets, no dialogs, result/exit code | Engineering + you | NOT TESTED | No unattended-render claim |
| Render farm / distributed render | Architecture proposal | Exact launcher/worker/modules/assets/licensing + matching images | Studio tester + engineering | NOT TESTED | No farm/free-worker promise |
| Deadline | Named in older design; no integration result | Exact studio launcher/version and worker test | Studio tester + engineering | NOT TESTED | No Deadline integration claim |
| Save/reopen unedited | Previous narrow smoke | MT27 with ordinary UI/settings | You + engineering | PARTIAL | Narrow smoke fact |
| Save/reopen edited | Empty modifier persisted in smoke | MT20–27 with actual records and suspension | You + engineering | NOT TESTED | No broad editing persistence claim |
| Backward compatibility / migration | Legacy readers exist; historical guide reports | Actual historical scene and expected transforms; rollback limits | Engineering + owner of fixture | NOT TESTED | Reader exists; no universal compatibility |
| Units/transforms/Unicode paths | Source conversions; limited fixtures | cm/m scenes, negative/nonuniform, Unicode/space/UNC paths | Engineering + you | NOT TESTED | Hold generalized portability claim |
| Animation/deformation/motion blur | Time callbacks/transport code alone insufficient | Frames/shutter samples, topology and identity policy | Engineering + renderer tester | NOT TESTED | Static scope unless qualified |
| Large scenes / 32 GB | UI limits and higher-RAM developer machine | S07 envelope on real 32 GB system including renderer peak | QA + engineering | NOT TESTED | Target, not proven minimum envelope |
| Upgrade/uninstall/rollback | Packages and Scatter uninstaller; Analyzer removal missing | Clean profile, mixed installs, downgrade, reopen | Engineering + you | NOT TESTED | Internal installer availability only |
| Licensing/render continuity | Proposed policy, no implementation | Stage 10/11 runtime/capability/outage tests | Engineering + you | NOT TESTED | No final activation/offline/render-node terms |

## Evidence to collect

For each exact configuration:

~~~text
Row ID / date / operator:
Max full build + SDK/toolchain where relevant:
Windows / CPU / RAM / GPU/driver:
Renderer full build / production-IR-CPU-GPU-DR mode:
Package/script/native hashes + loaded paths:
Scene/asset hashes / units / test IDs:
Expected versus actual:
Results + image/count/transform/log paths:
Known limitations:
Engineering qualification outcome:
Permitted wording / owner / date:
Retest trigger:
~~~

Retest when binaries, host update, renderer, scene schema, relevant algorithm or transport change. Use a comparison on the affected path; unrelated source presence is not a qualification shortcut.

## Status table

| Item | Status | Notes |
|---|---|---|
| Test access and intended beta rows listed | NOT TESTED | — |
| Baseline creation/edit/reopen/render row | NOT TESTED | — |
| Missing/excluded combinations explicit | NOT TESTED | — |
| Claims copied from qualified scope | NOT TESTED | — |

## Completion criteria

For preparing this stage, each row has evidence, owner and next test or an explicit scope decision. For beta/release, every advertised combination passes its required cases. Unavailable older hosts/farms stay pending rather than quietly disappearing from the target.

## Do not do yet

Do not publish broad renderer/host/farm badges, a 32 GB guarantee for all scenes, or “all GPUs supported.” Do not update a working host merely to try 2027.2.

## Optional / later

Qualify enterprise farm launchers, animated proxies, advanced source hierarchies and newer Points transport when the selected product scope requires them.

## Next stage

[Stage 08 — Demo and benchmark scenes](08_Demo_and_Benchmark_Scenes.md).

