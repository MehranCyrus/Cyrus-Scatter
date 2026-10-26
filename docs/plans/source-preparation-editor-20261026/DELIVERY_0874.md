# 0.87.4 — Source Preparation Editor

27 October 2026. **Scoped Max 2027 delivery for artist testing**, using the exact final MZP payload in an owned profile. The user selected 0.87.4 for this feature. Native Interactions is **8**, saved scene schema **62**, authored definition/source format **2**. Independent products retain their versions. The original proposal’s broader matrix is not fully qualified.

## Install and try

[Max 2027 MZP](../../../dist/CyrusScatter-0.87.4-20261027-final/CyrusScatter-0.87.4-Max2027.mzp).

In Max use **Scripting > Run Script**, select the MZP, follow the installer result, then **restart Max**. The installer has CRC/hash/version/host checks; it was not installed into the artist’s profile during this task. Do not mix its script with another native build. Existing content and the independent Analyzer remain separate.

Select the plant’s Scatter layer, choose **React to colliders**, select the original source and click **Edit preparation…**. Click a leaf/piece and assign Bend, Follow stem or Keep fixed. The popup updates automatically. **Use preparation** commits the complete draft; Cancel discards it. Ordinary **Prepare model** remains the automatic path. [Full artist workflow](ARTIST_WORKFLOW_0874.md).

Saved trial copies:

- [Fern preparation and sphere interaction](../../../Test%20Scene/CyrusScatter_0874_OwnedTests/Fern_Preparation_0874.max) — approximately 269 MiB.
- [Grass preparation and sphere interaction](../../../Test%20Scene/CyrusScatter_0874_OwnedTests/Grass_Preparation_0874.max) — approximately 270 MiB.

Both retain the original scene objects/materials, one reacting placement, a real Collider layer, Live mode, 100% foliage preview and roots kept visible. The viewport is framed near the tested plant/sphere. Select **CyrusScatter001**, then **Layer_01**, to use the preparation editor. For scene contact tests, enter **Cyrus Scatter Edit > Instances** and move the sphere layer’s instance. The private popup sphere is separate and creates no scene node.

These scenes and installers are local ignored artifacts, not Git assets. The owned profile uses standard plug-ins only; renderer-specific plant materials can look black. No material editing or production-renderer qualification was performed.

## Implemented behavior

- A resizable native source-only 3D popup: click, box and brush whole-piece selection; visible-only/through selection, isolation and material-ID assistance.
- Automatic / Bend / Follow stem / Keep fixed, with role colors and full admitted source geometry independent of viewport foliage sampling.
- Optional **Edit guide…** controls: root-end seed, direction flip, existing interior-point edits and explicit parent/root corrections.
- Automatic background draft preparation with one running/latest-pending request, cancellation and complete-result retention.
- Private sphere testing through the production contact fitter, captured layer stiffness and explicit centimetre/millimetre controls.
- Fingerprint-bound source-slot intent, persistent through Prepare and supported setting refresh; all instances reuse the definition with independent placement/contact transforms.
- Local draft Undo/Redo, including corrected Ctrl+Z/Ctrl+Y routing, and separate Max scene Undo/Redo after Use. Manual pending Count changes remain pending.

The original mesh is not destructively edited. Fixed geometry remains visible and moves with the plant placement. A welded component is still one piece; this version does not paint arbitrary face regions or split a welded leaf network.

## Executed final qualification

| Check | Final result |
| --- | --- |
| Max 2027 SDK/native build | **60/60** CTest tests pass; exact frozen native-04 receipt |
| Generated UI | **362** controls; generation/inventory/delimiter and layout checks pass |
| Physical popup input | Leaf click, Keep fixed, box (8 pieces), brush (6 pieces), local Ctrl+Z/Ctrl+Y and Use; persistent source readbacks pass |
| Selection cost boundary | Box/brush selection does not increase the preparation-analysis count |
| Fern preparation | 2,079 pieces; 50,382 triangles; 547 guides → 546 with one Fixed leaf → 547 after Bend/manual correction; every face retained |
| Grass preparation | 566 pieces; 27,501 triangles; 157 guides → 156 with one Fixed blade → 157 after Bend/manual correction; every face retained |
| Guide editing | Flip/flip, interior nodes, root seed and Follow-parent cases pass |
| Ownership/history | Pending Manual Count, reprepare preservation, Cancel, reopen, separate scene Undo/Redo pass |
| Real collider movement | Three contacting Cyrus Edit positions and movement away pass for each plant, with roots visible |
| Complete visible mesh | All 50,382 fern / 27,501 grass triangles checked at contacting positions; zero penetrations/crossings and zero root-anchor error |
| Private sphere | Contact/off restoration reuses preparation and reports no contact failure in the exercised pose |
| Lifetime | Close during work retains scene definition; deleting source blocks Use; reset releases editor |
| Saved scenes | Final framed copies save/reopen with authored intent and Ready sources; full contact audit passes |
| Package/source identity | ZIP CRC, all **30** manifest hashes, Max/version guard, loaded modules/script and **613** frozen source files verified |

Observed draft realization times in the final process were **84.70 / 387.01 / 383.25 ms** for fern initial/Fixed/manual and **43.18 / 82.68 / 79.84 ms** for grass. Initial realization can reuse already prepared inference; these are not cold whole-scene preparation timings. The sampled fern contact fits took **3.39–4.22 ms** for 4–5 guides, and grass **6.86–8.28 ms** for 14–17 guides. Redraw/settling and independent full-mesh audit costs are separate. No presented FPS, held-pointer latency or large-garden performance claim follows from these measurements.

[Qualification and exact identities](QUALIFICATION_0874.json), [retained evidence](evidence-0874/), [implementation/ownership decisions](IMPLEMENTATION_0874.md).

## Corrections and retained failed attempts

Excluding the lowest fern leaf initially moved the inferred ground and changed unrelated guides (547 → 860). Keeping the complete source ground fixed corrected this to the intended 547 → 546 result. Physical testing then exposed popup Ctrl+Z reaching Max’s scene history; modeless registration, scoped accelerators and child/frame routing correct it in **native-04**, with final physical readbacks. The earlier candidate MZP is superseded and is not the delivered package.

A deeper grass pose at a 13 cm sphere radius and offset [5, 0, 18] cm cleared collision but produced **28.54%** maximum stem-edge strain against the existing **25%** quality threshold. It is retained as an unresolved solver-quality limit. The final lighter contacts at [5, 0, 20], [0, 5, 20] and [-5, 0, 20] cm pass that unchanged threshold. No blade removal or root hiding is used to obtain these passes.

Fixture-only failures are retained in the local run: inline Undo inside one MAXScript file reverted the entire setup hold; separate events prove the intended transaction. Initial grass offsets were above its roughly 9 cm source and made no contact. Programmatic Cyrus Edit gestures needed the displayed-frame feedback to settle. Final framing needed cold scene realization before a navigation-only epoch check; a report-only layer-name typo was corrected. These are not counted as product fixes or passing runs.

The on-disk input scene was written at 23:38 on 26 October, before the first owned host campaign at 23:47. Its current identity differs from historical scene receipts; this report does not claim a task-wide unchanged input hash. The campaigns load that newer file and save only their named owned copies. Artist INI bytes remain unchanged. No artist session was restarted or installed into.

## Identity and remaining limits

MZP SHA-256: `40f28bfbc5383660c59ef9d6673cfbc3506f383191f9d1b5a23f1a80a32bf318`.

Script SHA-256: `ecb336b12ad01607fd8b6e7a412a7b864f93eb5059330b3aa1d404202cf72e18`.

Producer: `build/preparation-editor-0874-20261026-01/native-04/receipt.json`. Final profile: `final-host-02`, PID 34720. Source/payload hashes identify this dirty-worktree build; HEAD alone does not.

Qt development headers/libraries were unavailable, so the viewer uses native Win32/Direct3D 11 rather than the proposal’s Qt viewer. Matching host SDK and Windows graphics inputs are recorded in the native receipt. No foreign viewport is embedded.

Partial welded regions, opacity-aware picking, arbitrary botanical topology, reusable prepared-library packages, wider family/scale testing, large gardens, multiple DPI/driver configurations, production renderer/float delivery, actual process-memory peaks and long-session soak remain separate acceptance. Impossible fixed-root/fixed-decoration contact remains explicit. The original source and application budgets still apply; counters are payload estimates, not complete allocator/GPU peaks.

No Max 2024/2026 package, EXE, website build/publish, knowledge-index refresh, commit or push was performed for this request.
