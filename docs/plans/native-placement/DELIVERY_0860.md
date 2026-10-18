# Cyrus Scatter 0.86.0 native foundation

**Scoped-qualified 0.86.0 delivery; installers ready for user testing.** This page is the successor handoff for the N01–N09 migration. Earlier receipts retain their original hashes, failures and scopes. Max 2027 only; no artist installation, restart or later roadmap feature is part of this delivery.

## Implemented boundary

The default controller keeps candidate generation, receiver joins, mesh/UV masks, Paint, boundary falloff, Bands/Analyzer guidance, transforms, Relax, Edit, radii, acceptance, cleanup and preview preparation in native storage. It reuses the established numerical kernels and precision boundaries. It does not replace the scatter algorithm or alter slope/altitude settings.

Immutable 96-byte records and source/receiver cohorts replace full-population MAXScript row and matrix arrays. Accepted results use shared index views or compact copies when rejection would otherwise retain an oversized input pool. Publication binds placements, radii, sources, receiver revisions and statistics to one owner and epoch. The previous complete frame survives a failed successor.

CS Edit keeps authored identities, deltas and selection separate from evaluated inputs. Copy-on-write row blocks and compact selection blocks share unchanged state across Undo. History excludes derived matrices and charges changed blocks. Large edits still have proportional costs. Existing Edit serialization is preserved; no old-scene compatibility framework or registration change is added.

PFlow pins native publication groups and retrieves each particle transform through the existing Script Operator. It no longer retains a parallel full script matrix population. Bake and cached inspection use pages of at most 500 placements. UI, authored parameter blocks, bounded orchestration and host node creation remain scripted; the library remains managed/native. Native Particle Flow channel filling was not required for this bounded replacement and is not claimed.

The candidate cap remains one million across a controller, including retry and protected requirements. Admission checks conservative native working allowances against Windows commit headroom, while bounded authored script work retains its workspace guard. It does not reserve MAXScript heap proportional to Count. Light collection occurs at measured allocation/large-shrink boundaries, never on passive UI or idle. Required Undo/render/publication pins remain intact.

## Failures found and corrected during qualification

- The initial shared Edit history attributed both complete generations to Max's Undo Size, which rejected 200k all-selection history. The replacement separates authored from derived state and attributes changed blocks. Sparse and all-select history were then exercised through one million placements.
- Large Count decreases left obsolete wrapper roots alive until later pressure. Explicitly dropping rollback-only references before the bounded collection released the tracked million-row storage on the successful smaller update.
- Copy/preset Undo could recycle a scripted layer key while the native Edit map still held its former owner. Structural layer commands now record native Edit ownership in the same host hold.
- Preset Undo restored script fields but retained the successor native frame. The publication restore now restores native frame/context/admission state with epoch, manifest and display. The regression checks agreement immediately.
- Abandoned layer copies/imports retained native cache storage through Max's scripted-owner lifetime. Newly authored layer/area owners now join the existing abandoned-creation cleanup. Undo/Redo retains required caches; discarding an undone creation releases transient caches only after it has no scene dependent.

The failed candidates/scenes remain in owned qualification directories. No failed iteration is relabeled a pass, and the final source pair repeated the scoped acceptance below.

## Measurements and limits

Ten warm repetitions compare 0.85.4 with the frozen final pair using the **same saved scenes and complete variation identities**, matching profile templates, display mode and authored settings. Fingerprints match in every sample. The Count fixture selects Modify and retains its scalar-change history; the Paint fixture clears selection in both builds. Warm-up, fingerprinting and logging are outside the Update windows. Empirical p95 is the nearest rank of ten samples.

| Fixture | Requested | Old median / p95 | 0.86.0 median / p95 |
| --- | ---: | ---: | ---: |
| Plane, Count | 5,000 | 955 / 1,228 ms | 212 / 372 ms |
| Mountain, Count | 5,000 | 939 / 2,128 ms | 198 / 310 ms |
| Plane, Count | 200,000 | 3,126 / 4,857 ms | 517 / 733 ms |
| Mountain, Count | 200,000 | 3,182 / 4,708 ms | 519 / 662 ms |
| Two Paint Areas, curves and holes | 5,000 | 326 / 518 ms | 289 / 364 ms |
| Two Paint Areas, curves and holes | 200,000 | 2,805 / 3,432 ms | 1,076 / 1,113 ms |

The 200k Paint case accepts 126,161 placements. Its median sampled whole-process private peak falls from 5,415 to 4,707 MiB; the Count plane/mountain peaks fall from 5,275/5,285 to 4,769/4,752 MiB. Those figures include Max and allocator retention, not just plugin data. Paint's script heap capacity is 704 MiB in the old run and 100 MiB in the native run; capacity is not used memory. Final native hot-path tests report zero full-population script rows/matrices. Native placement high-water in the Paint fixture is 83,082,240 bytes, excluding other categories.

The machine remained in ordinary desktop use; the final Count repetition ran alongside the mixed-history soak. These are scoped Update measurements, not a universal speed multiplier, isolated input-latency benchmark or presented FPS. Earlier profile-mismatched and independently authored comparisons remain recorded with their limitations and are superseded by the exact-scene comparison here. Raw windows, samples and identities are in `build/native-fields-0860-20261018-01/performance-final.json`.

Allocation counters cover native placement capacities, index buffers, native schedule/radius buffers and tracked Edit allocations. Shared storage is counted once; conservative owner/history attribution is separate. These counters do not claim every SDK allocation, STL node overhead outside the tracked allocators, renderer memory or driver VRAM. Windows private commit is sampled separately. An admission allowance is not a measurement. A 25% engineering target is not an advertised saving without a comparable measured denominator.

The first migration remains synchronous. Heavy generation, many real Bake nodes, complex source geometry and large authored Edit commands can block the host. Future scheduling/cancellation design is separate from moving storage into C++. Actual low-memory exhaustion, arbitrary renderer/device failure, physical 4K mixed-monitor behavior and every renderer family require separate qualification.

## Final acceptance and installer

Completed on the frozen candidate: 44 normal native suites, 44 separate fault-build suites, 168 Python checks and generated-source checks; 50 frozen complete-result scenes; Count progression through one million; 500k/1M sparse and all-selection Edit Undo/Redo; structural copy/remove/clone/topology/history release; sparse-view compaction, pinned lifetime, ten-layer cap and high-face-count tests. Same-frame mesh and real Data Channel notifications, Manual pending changes, missing-channel failure retention, save/reopen and 65-second passive-field checks pass on plane and mountain.

Actual wheel up/down, hold-drag and readable library layouts pass at process-local 100% and 150% scale, with unchanged calculation counters. This does not qualify a physical 4K mixed-monitor desktop. At 150%, automation activation/coordinate timeouts required fresh observations and the final gallery refresh used its actual rollout method; no general input-latency or FPS result is claimed. Actual Corona 15 production Stop was observed and clicked in the owned test session; the complete publication stayed unchanged, a subsequent render and Update succeeded, and reset released PFlow consumers. The first proposed timer-based cancellation fixture did not dispatch during the synchronous renderer call; that failed fixture is retained, not counted as a pass.

All eight packaged ready presets pass Load/Add, Undo/Redo with the original package moved away, and save/reopen. Exact PFlow/Bake output and page-two Bake failure cleanup/retry pass. Actual Corona 15 floating IR passes idle, Live Count edit, save/resume, repeated Stop, production render and reset. Docked IR and other renderer families retain separate qualification requirements.

One preparation test initially included a pending authored Manual-to-Live switch inside its idle interval. The counters showed one update. After completing that transition before the baseline, repeated panel browsing and 65 seconds idle pass with no calculation/upload increments. Both the original failure and the corrected test are preserved; no product change was made to hide it.

The one-hour mixed-history soak passed: **3602.9 seconds / 60 complete cycles**. At equal history states after warm-up, tracked placement bytes stayed at 27,473,280, Edit bytes at 16,749,664 and schedule/radius bytes at 984,720 each. Passive intervals added no calculation/preparation/preview work. Each cycle preserved the earlier Undo sentinel and exact baseline, and final last-owner reset released tracked placement and Edit storage to zero. The fixture uses light collection outside timed commands for equal-state observations; it preserves Undo/Redo and does not claim arbitrary session-lifetime or whole-process memory constancy.

The [machine-readable qualification](QUALIFICATION_0860.json) pins the exact builds, source hashes, launches, tests and local evidence. The [package record](PACKAGE_0860.json) pins every archive entry and the EXE's identical embedded MZP. Native capability/Brush POD are 2/2; scene schema remains 58.

| Qualified component | SHA-256 |
| --- | --- |
| Generated script | `de9f1b7888d9cb7068e6f8d96c502b0abbe3e119e5fdf139e2f80b0f16b3c220` |
| AminScatter.dlx | `fdc4f3354ccc0d9004e1761efb4c2e6e6210cd20102d314ce29a2130145a3073` |
| CyrusBrush.dlx | `519f0f8233d87315d1df2c7fcc0500fb698e5f1cf97aff501c48e2e464847ea9` |
| CyrusBrushStorage.dlh | `43a162af2685776c7c301f25ff978f1bd467e2c8a600f68b3d2cead9f39806fa` |
| CyrusGallery.dll | `9cb9e69e3cb9fe08f65e69c956eafcfc718e754aef514415b780896eb162a5cc` |
| CyrusScatterEdit.dlm | `62494b956eac278352ffc8981cb447a4bb0c926ebcf98cb94871f486a947e0d1` |

Ready for user testing:

- [Max 2027 MZP](../../../dist/CyrusScatter-0.86.0-20261018/CyrusScatter-0.86.0-Max2027.mzp) — 10,585,303 bytes; SHA-256 `cfee125b741864763647acf33023d80d51949f4bd94d4cde7596175b9c9f09b4`.
- [Windows EXE](../../../dist/CyrusScatter-0.86.0-20261018/CyrusScatter-0.86.0-Max2027-Setup.exe) — 10,621,440 bytes; SHA-256 `b38ca0e04f9bc53a529f79a932c3804496e6704ba6533dff182b78047b2d8709`.

Save your scene, choose **Scripting > Run Script**, select the MZP, then restart Max 2027. Alternatively use the unsigned EXE; use one installation route. Neither installer was executed by this task. Private profiles loaded the exact packaged script/native pair directly. Analyzer 0.14, MCP 0.73 and licensing keep their independent versions. `dist/` and raw host evidence are ignored by Git; the tracked JSON records preserve their identities, not the binary payloads themselves.

Artist acceptance should use copies of real scenes: change Count up and down, Undo/Redo with preceding history, browse and scroll Modify/Library, edit Paint and mesh masks, Load/Add a ready preset, save/reopen, and render with your usual assets. Compare planting, controls and responsiveness. Existing one-million work bounds and synchronous expensive operations remain; report a scene and exact action for anything outside the qualified fixtures.

Maintained architecture, artist guidance and website reference sources are updated. The website is built locally, not deployed. The [knowledge refresh record](../../../tools/rag/NATIVE_DELIVERY_REFRESH_2026-10-18.md) records separate index verification/activation and complete-contract retrieval. This completes the scoped N01–N09 native delivery, not the remaining P/I/PG roadmap.