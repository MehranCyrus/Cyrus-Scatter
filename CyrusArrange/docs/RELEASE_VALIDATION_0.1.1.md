# Cyrus Arrange 0.1.1 release validation

This report identifies the arrangement baseline for 3ds Max 2027. The whole-system goal remains active. An archive is qualified only when its SHA-256 matches the adjacent external `qualification-receipt.json`; creating an MZP or passing functional tests alone does not establish installation/startup success. The external receipt is written after testing the unchanged archive, so it is deliberately not embedded in that archive.

## Exact native build

`build/native-arrange-21/receipt.json` records a passed Windows x64 build using MSVC 14.38.33130, Windows SDK 10.0.19041.0 and the external Autodesk Max 2027 SDK. Its 72 source/test/tool/installer inputs are hashed. All six CTest executables pass, containing 68 scoped suites: geometry 13, asset records 10, arrangement 16, placement queries 17, integrated arrangement four and persistent region registry eight.

| Native module | SHA-256 |
| --- | --- |
| CyrusArrange.dlx | `cae878fd26f9971a7a7420d412cf21809ec6fc6e01800a5a26c7a130b382c4f4` |
| CyrusArrangeStorage.dlh | `debee83d9320ba63cd1ee22923f14e0280e3d72aa90b4ecb5fc563346fb793a3` |

## Matching functional host runs

Each run starts a separate owned Max **2027.1, build 29.1.0.11426**, batch process with private configuration and frozen scripts/modules. Receipts verify both actual loaded module paths, both hashes, the private INI and unchanged artist INI hashes. No computer use, existing artist scene attachment or artist-profile installation is used. A pass qualifies that precise fixture and workflow, not all models that Max can open.

| Suite | Run folder under `build/` | Result |
| --- | --- | --- |
| Inspector and actual rollout handlers | host-final-21-inspect | 69 passes, zero failures |
| Native registration/generation/persistence | host-final-21-native | 21 passes, zero failures |
| Complete accessory and arrangement UI | host-final-21-workflow | 147 passes, zero failures |
| Dependencies, Undo/Redo, clone and scene lifecycle | host-final-21-lifecycle | 89 passes, zero failures |
| Preview and commit | host-final-21-preview | 38 passes, zero failures |
| Persistent surfaces and policy UI | host-final-21-regions | 74 passes, zero failures |
| Independent obstacles and front approach | host-final-21-obstacles | 78 passes, zero failures |
| Maps/materials/smoothing/distinct corner normals | host-final-21-visual | 83 passes, zero failures |
| Independent portable-library rejection fixtures | host-final-21-library | 6 passes, zero failures |
| Five-category original gallery | host-final-21-gallery | 49 passes, zero failures |

All ten suites pass **654 functional host assertions with zero failures**. The inspector additionally passes `tools/verify_exports.py` on five independent JSON exports. That checks strict JSON, physical dimensions, counts/areas, bounds, known holes, coplanar dividers, clearance and transformed support heights.

`build/host-final-21-render/receipt.json` separately passes actual Scanline rendering of the saved native gallery: a 2400 x 1000 overview and five 1400 x 1050 detail images. Its gallery generation also passes 49 checks. The gallery contains 35 generated accessories across five independent setups; the test compares complete repeated poses/IDs and independently checks full accessory bounds against the curved surfaces and real sink opening. See [EXAMPLES.md](EXAMPLES.md) for fixtures and measured end-to-end timings.

The overview and five detail images were visually inspected. No obvious floating objects, intersections or edge/sink intrusions were visible. Detail frames retain some cropped captions and neighboring furniture, and their simple materials/lighting are procedural test presentation. Images are not a substitute for collision assertions, artist composition review or production-renderer testing.

## Installation gates

The package tool requires all ten matching functional receipts before producing the candidate. The installer stages and hashes the complete payload, preserves older immutable payloads, registers only the native `bin/` folder and restores exact configuration preimages if publication fails. Separating scripts from registered binary directories follows Autodesk's documented [startup loading order](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Introduction/General-MAXScript-Topics/GUID-615D14FB-0F2D-4801-B381-1128C4128C70.html).

The first archive at `dist/CyrusArrange-0.1.1` is **not qualified**. Actual `build/installer-qualification-01/receipt.json` fails with 12 passed checks and two failure records: `Directory.GetFiles` returned a native MAXScript array, so an installer `.Length` access failed before configuration publication. Earlier rollback assertions in that run did not establish that the intended macro/INI failure stages had been reached. The successor uses `.count`, explicit stage diagnostics and stage-specific assertions, and adds tracked creation/cleanup for absent startup/macro directories. Both the failed archive and run remain unchanged.

The second archive at `dist/CyrusArrange-0.1.1-r2` is also **unqualified**. `build/installer-qualification-02/receipt.json` records one passed profile check followed by a MAXScript compile error before installer execution: a new rollback branch attempted to throw an argument inside a catch expression. The successor records that cleanup failure directly in the rollback status and diagnostic. This changes only the installer; both earlier packages and failure evidence remain immutable.

The successor location is `dist/CyrusArrange-0.1.1-r3`. Its native modules, all five UI scripts and functional test inputs remain the exact native21 runtime. Installer-only corrections use an explicitly scoped qualification policy: original build/host receipts remain byte-for-byte intact, every non-deployment input must still match, and new candidate metadata records the old/new deployment hashes. This reuses the recorded 654 functional assertions; it does not claim they were rerun for installer changes. The revised archive still requires fresh actual installation and automatic-startup qualification against its complete current source map. See [QUALIFICATION_SCOPES.md](QUALIFICATION_SCOPES.md).

Actual private-profile qualification must execute the MZP, check damaged-payload rejection, real publication failures and rollback, repeat installation, immutable-file conflicts, every installed byte and preservation of unrelated registration. A second process must discover the installed modules, startup script and macros automatically, then exercise the UI and save/reopen workflow. It does not manually load the startup script to conceal discovery problems. The external installer and qualification receipts record whether those gates passed.

## Scope and limits

- Five furniture categories and eleven original accessory sources exercise the baseline. Name/tag suggestions do not infer arbitrary furniture semantics; compartment labels remain authored.
- Actual source-backed output preserves evaluated Standard materials, maps, smoothing and explicit corner normals in the recorded fixtures, including mirrored/nonuniform source components and Undo/Redo/save/reopen. Corona, V-Ray and imported render proxies have no broad qualification here.
- Footprint checks use quantized support polygons; collision uses conservative accessory bounds against selected furniture/obstacles. Small support features depend on sampling. Porous or concave accessories may be rejected conservatively. This is not rigid-body stability simulation.
- Portable `.cyalib` stores geometry and placement metadata. Keep the source `.max` models for material/map fidelity.
- Repeat Generate currently recaptures and reanalyzes geometry. Gallery timings include host work, publication and Undo; memory readings are process-wide. No reusable-query speedup or isolated solver-RAM claim is made.
- Local clusters, weights and authored stacks are implemented. Relational dining layouts, authored book rows and dedicated height/hierarchy scoring remain planned composition work.
- Generated node handles may change on regeneration; placement record IDs have a different persistence contract. Live remains disarmed after load until explicit generation. Translated setup clones require unlocking and regenerating; automatic frame reconciliation is not claimed.

Historical failure receipts are preserved. Strong distinct corner normals exposed a genuine mirrored normal-corner mapping defect, repaired by remapping normal IDs through the mesh's actual vertex permutation. The final strong visual suite passes all 83 checks without removing those assertions. Gallery staging failures involved script-only camera/title API assumptions; the final matrix-basis implementation passes its facing assertion. Old 0.1.0 evidence and packages remain unchanged.

## Final installer qualification

**Qualified:** `dist/CyrusArrange-0.1.1-r3/CyrusArrange-0.1.1-Max2027.mzp`, SHA-256 `3b39b92867b9fed0984fde8555ff3533adc8f448f03cb34b417600df3b67e55d`.

`build/installer-qualification-03/receipt.json` passes **43 installer assertions and 12 automatic installed-startup assertions**, zero failures. The second private process discovers both installed modules, loads all five UI entry points, executes both toolbar macros, generates geometry and verifies persistent GUID/assets/placements after saving and reopening. Both actual loaded module paths/hashes, every installed payload byte, the private INI, the unchanged archive and preservation of artist profiles pass. No artist installation or restart occurred.

The external `dist/CyrusArrange-0.1.1-r3/qualification-receipt.json` binds the exact unchanged archive to the build, ten functional suites, independent exports and installer receipt. The archive's documentation is the pre-test snapshot; this post-test report and external receipt were written afterward without rewriting that archive. Runtime evidence reuse is explicit and limited to the recorded deployment-only changes.

`CyrusArrange-0.1.1-Source-and-Examples.zip` beside the installer preserves all 72 exact candidate source inputs, the archive's documentation snapshot and original examples (108 files total). Its verified SHA-256 is `b6ea8b5c7007502da5975b05466259fb9fc277c2c34b415a4914bec0909e40a9`; `source-receipt.json` and the embedded source manifest identify its contents. The Autodesk SDK/toolchain remain external prerequisites.
