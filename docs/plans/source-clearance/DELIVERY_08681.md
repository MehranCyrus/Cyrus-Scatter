# 0.86.8.1 — clearance corrections and viewport reuse

20 October 2026. **Qualified for scoped Max 2024, 2026 and 2027 user testing.** The user
authorized the review corrections, real-leaf viewport investigation, performance
improvements, patch version and package/Git backup, then explicitly requested
Max 2024 and 2026 compatibility. The [final three-host verification
receipt](../../../build/clearance-performance-08681-20261020/final/compatibility-final-receipt.json)
checks 479 build-source hashes per SDK build, payloads, installed files and loaded identities.
No artist profile, original model, content library or open artist session was
modified. Performance and real Corona leaf qualification were conducted in
Max 2027; the additional hosts exercised Standard-material opacity cards using
existing library image maps.

## Corrected behavior

The [independent 0.86.8 review](REVIEW_0868_20261020.md) remains unchanged as
historical evidence.

- **F1:** A preferred refill candidate can displace an earlier blocker. Rejections
  that still refer to that missing blocker are now reconsidered in the same
  candidate prefix before final acceptance. Exact two-round and sixteen-round
  reproductions pass, including dependent candidate-budget and accepted-target
  layers. Fulfilled layers no longer keep a provisional limit warning.
- **F2:** A source contributing no authorized candidates cannot change the
  settlement schedule through its preference or unused policy. Protected rows
  and eligible refill suffixes still participate; unauthorized cached suffixes
  do not. All authored metadata is still validated.
- **F3:** One compiled native context supplies schedule classification and spatial
  query bounds. Equivalent participating policies share a small witness cohort.
  Empty/unused source pairs are skipped. Many distinct effective policies can
  still require bounded pair comparisons; this is not a universal linear solver.
- **Colored Mesh leaf shape:** A014 is a four-vertex, two-triangle Sycamore leaf
  card. Its material opacity supplies its silhouette. Colored Mesh now prepares
  supported opacity and clips it while retaining identification colors.
  Textured mesh additionally displays material color. Ordinary opaque Mesh
  sources do not need an opacity atlas.

Count admission, independent scope inheritance, protected-edit precedence,
source preference, stable order and post-acceptance cleanup retain their
contracts. Candidate-budget cleanup without authorized repair may leave holes.
No new saved fields were added: schema **59**, `CyrusUnified2`, complete recipe
**8**, native placement **2**, publication bridge **4**.

## Performance and invalidation

Radius/clearance changes reuse unchanged source UV/material data across changed
placement snapshots. Exact triangle correspondence guards this reuse. Weak
snapshot references allow retired geometry to be reclaimed. GPU source
geometry, UV, texture and immutable shader resources can be retained while
changed instance transforms are uploaded.

Relevant material/map/UV changes invalidate appearance without changing
placement publication. Animated consumed maps advance a shared time revision
for all consumers; unrelated whole-material instantaneous validity no longer
forces static bitmap rebaking. Geometry changes still obey Manual pending-edit
and source-correspondence guards. Host preparation/publication stays on the host
thread. Existing conservative memory admission and failed-successor retention
remain. Same-prefix clearance settlement has a fifty-million examined-row
ceiling, separate from the existing fifty-million neighbor-visit ceiling.

The [timing receipt](../../../build/clearance-performance-08681-20261020/final/performance.json)
compares the exact same frozen A006/A007 scene, Count 200, across five warm radius
edits. Accepted counts match: 138, 134, 132, 130 and 126.

| Textured mesh median | 0.86.8 baseline | 0.86.8.1 |
| --- | ---: | ---: |
| Solve and preview preparation | 788.033 ms | 95.903 ms |
| Setter, solve/preparation and redraw combined | 921.322 ms | 186.688 ms |

That is approximately 4.9 times faster for this measured combined operation,
about 80% less elapsed time. These are diagnostic wall-clock observations on a
busy machine, not controlled presented-FPS measurements or promises for every
scene. Old-build material-counter placeholder zeros mean **unavailable**, not
zero bakes. GPU assertions come from separate callbacks with presentation
opportunities between observations, not from nested redraw timing counters.

The final native metadata probe took **1.5169 ms** for ten empty layers with
512 source records each, compared with the independent review's approximately
199 ms observation. A populated equivalent-policy case took **1.1222 ms**.
These probes measure metadata work; they are not end-to-end Max timings.

## Qualification

| Evidence | Exercised scope |
| --- | --- |
| Native suite | 49/49 tests on each of the three SDK builds; exact F1/F2 regressions, authorized suffixes, protected-only sources, Count admission, limits and deterministic acceptance |
| Exhaustive reference tests | 240 ordinary randomized scenes plus 500 randomized stateful refill scenes; independent small-scene acceptance oracle |
| Stress | 100,000 sparse candidates; empty/populated metadata probes at 1, 32, 128 and 512 sources across ten layers |
| Python and generation | 176 Python tests passed; generated source, inventory and approved layout checks passed; 329 controls and 32 fixtures |
| Real library workflow | A006 broadleaf, A007 curled leaf and A014 Sycamore card; third import into existing layer; colored/Textured switching, Color Correction and nested property changes |
| Presented-frame invalidation | Radius uploads changed transforms while retaining geometry and maps; selection uploads neither; opacity and UV edits refresh appearance; Manual geometry guard and explicit Update; Live radius update |
| Time dependencies | Unrelated timeline change retains static placement/material data; animated Noise consumed by two layers refreshes in forward and reverse time and reuses shared preparation |
| Layer lifecycle | Real dropdown notifications, multi-selection, independent inheritance, source replacement, Undo/Redo, targets, failure retention and explicit schema-58 upgrade/reopen |
| Installed-byte test | Fresh disposable Max profile loaded exact installed native/script/Gallery bytes; real three-leaf workflow, zero-weight preference parity, save/reopen identity and placement fingerprints, frame-separated invalidation checks |
| Installer | Plugin-only without adjacent ZIP; selected missing ZIP fails before installation; verified existing content reuse, no second library, zero-byte repeated update |
| Max 2024/2026 compatibility | Installed-byte layer/UI acceptance, Undo/Redo, schema-58 upgrade, save/reopen, third opacity-card model, material correction, relevant/irrelevant invalidation, Manual/Live and shared animated maps |

The matching final-build and installed-byte profiles are:

- `build/mcp-qualification/update08671-test-clearance-perf-final-2027/`
- `build/mcp-qualification/update08671-test-clearance-perf-installed2-2027/`
- `build/mcp-qualification/update08671-test-clearance-compat-2024/`
- `build/mcp-qualification/update08671-test-clearance-compat-2026/`

Their `loaded-identity.json`, acceptance logs and source hashes are indexed by
the final receipt. Computer Use inspection of the final build confirmed matching
leaf silhouettes in both modes:
[colored Mesh](../../../build/clearance-performance-08681-20261020/final/colored-mesh.png)
and [Textured mesh](../../../build/clearance-performance-08681-20261020/final/textured-mesh.png).
The native receipts for
[2024](../../../build/clearance-performance-08681-20261020/final/max2024/receipt.json),
[2026](../../../build/clearance-performance-08681-20261020/final/max2026/receipt.json)
and [2027](../../../build/clearance-performance-08681-20261020/final/max2027/receipt.json),
plus [three-host installer checks](../../../build/clearance-performance-08681-20261020/final/installer-three-hosts/result.txt),
retain detailed evidence. The 176-test Python completion was observed directly
with exit 0; no separate captured Python text log is claimed.

The older-host lifecycle driver initially tried to open the Max 2027 schema-58
fixture. That failed load was caught by the subsequent upgrade assertion.
The corrected driver requires a successful load of the preserved Max 2024
schema-58 fixture and passes both older hosts. The initial logs are retained.
The identity helper now explicitly loads Gallery before calling its hashing
helper; older-host fixtures do not implicitly open the library first.
The Max 2027-only package/verification state was preserved under
`final/max2027-only/` before extending the EXE; its 2027 MZP and native/script
bytes remain unchanged. Computer Use confirmed the combined EXE's three version
cards and optional shared-content checkbox; it was closed without installing.
Visual evidence also confirms colored and textured silhouettes in both older
hosts. These screenshots and the installer view are hashed in the final receipt.

Earlier failed developmental checks, a premature startup command and the first
installed-path staging attempt remain in ignored campaign evidence. They are
superseded by the final passing profiles. No failed run is counted as acceptance.
Build receipts, scenes, previews, content and installers remain outside Git.
The Git backup also restores 16 unchanged pinned libjpeg-turbo configure/package
templates previously hidden by the generic `Release/` ignore rule. Their bytes
match the existing dependency pin and the qualified build receipt. This changes
backup completeness, not the built payload. Sixteen other pre-existing source
files use Git's existing newline normalization; index checks distinguish those
newline-only differences from the exact local build-input hashes.

## Packages

All deliverables are under
`dist/CyrusScatter-0.86.8.1-20261020/`:

| File | SHA-256 |
| --- | --- |
| `CyrusScatter-0.86.8.1-Setup.exe` | `ac704828d65efb5aa1e314a9df1786da3d23549fd03ea28d8bd3d02bb32ebf16` |
| `CyrusScatter-0.86.8.1-Max2024.mzp` | `1d6d4d7da8a5f557db8213c11eff50a991ae745f0bb8c3f990449ec0035c89ad` |
| `CyrusScatter-0.86.8.1-Max2026.mzp` | `73f8716ae2f39ef20b98728f069a1113e7d2bd39235227617aa48e81398d9800` |
| `CyrusScatter-0.86.8.1-Max2027.mzp` | `589a9004011aa77ef0299b5398745d184ea1982ab9394c9886409af2fbf3ae64` |
| `CyrusScatter-Content-0.86.7.zip` | `db5a63e87f81abd78563ec80039fed066a6cb73f585779749ed23faf548f2c58` |

Archive CRC, every manifest entry, host/version guards, loaded module identities
and the EXE's three embedded MZPs match. The EXE remains unsigned. It contains
separately matched Max 2024, 2026 and 2027 payloads. Independent Analyzer, MCP and content versions are unchanged.
The optional content ZIP is a hard link to the existing unchanged archive:
no models were recreated and no second archive allocation was made on this drive.

Close the Max versions to update, run the EXE, select Max 2024, 2026 and/or 2027
and use **Install/Update**. Existing
compatible content is reused. To install content too, keep the ZIP beside the
EXE and select **Install / update plant library**. Alternatively, inside
each Max version use **Scripting > Run Script** with its matching MZP, then restart Max.
No installer was applied to the artist's profile.

## Limits and next artist check

This patch does not implement separately cached acceptance for every independent
component or guarantee that every feature processes only one changed field.
Existing supported material adapters, UV limitations, 256-pixel material tiles,
0.5 opacity clipping, memory/triangle limits and box fallback remain. No new
Corona render, physical painting or tablet campaign is claimed. The additional
2024/2026 profiles did not have matching Corona plug-ins, so their viewport
qualification uses Standard materials and existing leaf images instead of
claiming Corona material/render qualification there.
The website was not changed or published by this task.

In a saved copy of the artist scene, add the third Sycamore leaf, switch between
Mesh and Textured mesh, vary radius, and change one material map. Confirm that
the silhouette stays correct and that relevant material edits appear. Large
or unusual material graphs may still need separate profiling.
