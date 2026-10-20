# 0.1.2 qualified delivery

The immutable 0.1.2 delivery is qualified for the recorded Max 2027 scope. The earlier 0.1.1 r3 delivery remains preserved. This milestone adds individually generated upright book rows, complete-row protection and optional height-profile balancing for TV consoles and open shelves. The full-system goal remains active; geometry/query reuse is separate unfinished work.

## Recorded evidence

| Receipt | Actual result and scope |
| --- | --- |
| `build/native-arrange-22/receipt.json` | Full Max 2027 SDK build and nine CTest targets pass, containing 90 reported suites. Includes independent old-output goldens, row constraints/balance and pure document codec tests. |
| `build/host-migration-01/receipt.json` | 60/0 on native22: original document3/library1 baseline loads without generation or authoring, preserves five setups/35 outputs, saves/reopens current formats and repeats previous complete poses. |
| `build/host-composition-01/receipt.json` | 0/1: test helper was undefined before first fixture because later-fileIn names were not explicitly global. Corrected in successor tests. |
| `build/native-arrange-23/receipt.json` | Full SDK build and all nine CTest targets pass with unchanged source map. |
| `build/host-composition-02/receipt.json` | 46/5 on native23. Three source-dimension checks and two table-bound checks fail; they used group-head bounding boxes. UI commands, real row publication, preview agreement, deterministic regeneration, profile staleness and portable profiles pass their scoped assertions. Successor tests measure actual descendant geometry and compare the table to independently authored dimensions; that diagnosis still needs execution. |
| `build/host-composition-lifecycle-01/receipt.json` | 71/0 on native23: whole-row locking and invalid capture rejection; selective retention; missing output/source recovery; atomic complete-row removal; Undo/Redo; setup-only/full zero-offset clones; save/reopen; transient stats; hard-failure retention. |
| `build/native-arrange-24/receipt.json` | Full SDK build and all nine CTest targets pass. Includes actual-geometry fixture bounds and promoted gallery source. |
| `build/host-composition-03/receipt.json` | 52/0 on native24. Actual member geometry measures 20x120x100, 30x120x200 and 40x120x300 mm; group-head bounds were approximately 0.02 mm. Independent table geometry and both complete row-support checks pass. The previous five failures were test-oracle errors, not placement defects. |
| `build/host-book-rows-gallery-01/receipt.json` | Gallery stops at compile time before execution: compact numeric case labels parse as malformed number/time syntax. Whitespace corrected for the successor; no gallery-generation or render claim from this run. |
| `build/native-arrange-25/receipt.json` | Full SDK build and all nine CTest targets pass with the repaired gallery script. |
| `build/host-book-rows-gallery-02/receipt.json` | 35/0 on native25: TV 16 props/3 rows, shelf 25 props/5 rows, independent full-bounds/gap/scale checks, repeat identities/poses, two actual saved Max states and six native Scanline renders. Bounded search chooses seed5 for the same generated locked prop and row; measured height imbalance changes 0.26442307 to 0.25 without scale/model/yaw changes or hand-positioned outputs. |
| `build/host-final-25-inspect/receipt.json` | 69/0 on native25 for actual inspector UI, transformed geometry, units, preservation and save/reopen. Strict independent validation of all five exported JSON fixtures also passes. |
| `build/native-arrange-26/receipt.json` | Full Max 2027 SDK build and all nine CTest targets pass, now containing 92 reported suites. Includes the corrected clustered-anchor membership, pre-allocation round-join admission, unchanged immutable historical golden and exact unaffected-pose checks. |
| `build/host-regions-03/receipt.json` | 83/0 on native26. Retains the original 74 regional/UI checks and adds two-board excluded/category-denied regressions across 32 seeds each: requested3, accepted1, underfilled2; complete actual mesh remains on the allowed board and every locked successor preserves all pose fields. |
| `build/host-migration-02/receipt.json` | 60/0 on native26. The exact delivered five-setup/35-output gallery and eleven-asset library load, save to owned current-format files, reopen and reproduce all old poses. Original input bytes remain unchanged. |

The completed host runs above verify both actual loaded module paths/hashes, the private profile and unchanged artist profile files. They do not qualify a later source map. Existing artist Max sessions were not used, installed into or restarted.

`build/host-performance-01/receipt.json` records **291/0 in-host on native26**, completing 86 commands and 20 UI refresh pairs. Raw CSV metadata is not fully valid: .NET overload selection narrowed native Integer process/node IDs. The source test formatter and independent validator are corrected for a fresh successor; original outputs remain preserved. Other project Max processes overlapped, so this run is not accepted as a complete benchmark or idle-machine result.

`build/native-arrange-27/receipt.json` passes the full SDK build and 92 native suites. `build/host-performance-02/receipt.json` passes **292/0 in-host**, including the plain-Integer formatter regression, but its saved node handles still narrow because Max supplies pointer-sized handles. The independent validator rejects this run too. The next test handles IntegerPtr explicitly and verifies every actual node-handle text roundtrip plus native node lookup. Both preserved failed-evidence inputs are independently rejected by `build/performance-validator-regressions-01/receipt.json`; the numerical plugin is unchanged by these harness repairs.

`build/native-arrange-28/receipt.json` passes the full SDK build and all 92 native suites. `build/host-performance-03` passes **292/0**, the independent CSV validator and exact native/source/private-profile checks. Its `measurement-qualification.json` binds all raw files and explicitly records background-load limits. All 86 commands and 20 UI refresh pairs complete; no cache or idle-machine claim is made. The complete final native28 functional collection has now passed as recorded below.

`build/host-final-28-composition-lifecycle` exited with code4294967295 during host initialization: result remained PENDING, no test assertions or loaded-module marker were written, and the session log ends after startup GUP entries. Cause is undetermined; it is preserved as failed startup evidence, not attributed to a specific component. The fresh same-source/pair retry, `build/host-final-28-composition-lifecycle-r2`, runs alone among this task's QA and passes **71/0**, including actual loaded pair/private profile and unchanged artist profiles. This confirms that retry's lifecycle scope; it does not identify the earlier initialization failure's cause. The final orchestrator stopped at this failure rather than continuing silently.

## Final exact-source functional collection

All thirteen required suites passed against native28. `build/final-28-functional-receipt.json` binds their receipt hashes, the exact source map and five independently validated inspector JSON exports. The lifecycle retry is identified explicitly; its failed predecessor remains preserved above.

| Host receipt folder under `build/` | Assertions passed |
| --- | ---: |
| `host-final-28-inspect` | 69 |
| `host-final-28-native` | 21 |
| `host-final-28-workflow` | 147 |
| `host-final-28-lifecycle` | 89 |
| `host-final-28-preview` | 38 |
| `host-final-28-regions` | 83 |
| `host-final-28-obstacles` | 78 |
| `host-final-28-visual` | 83 |
| `host-final-28-library` | 6 |
| `host-final-28-gallery` | 49 |
| `host-final-28-composition` | 52 |
| `host-final-28-composition-lifecycle-r2` | 71 |
| `host-final-28-migration` | 60 |

**846 functional host assertions passed with zero reported assertion failures in these thirteen runs.** Separately, the native build passes nine CTest targets containing 92 reported cases. These counts describe the recorded fixtures, not exhaustive correctness.

`build/host-final-28-book-rows-render/receipt.json` passes 35 generation/fit checks and saves two actual Max scenes and six Scanline images. These repeated gallery checks are separate from the 846 assertions. TV: 16 props/three rows. Shelf: 25 props/five rows. The independent balance witness changes 0.26442307 to 0.25 through a generated row translation, preserving models, scales, yaw, gaps and a locked plant. Generated objects were not repositioned for presentation. The image review found no obvious visible placement defect; some overhead clearances are obscured and rely on numerical checks. See [book-row examples](BOOK_ROW_EXAMPLES.md).

Final gallery CSV times are observational: TV first/repeat 188.64/200.37 ms and shelf 235.15/224.49 ms. Migration QA overlapped. They are not pooled with the separately validated [86-command performance run](PERFORMANCE.md), which reports native28 whole-command timings, exact pose/handle checks and background-load limits.

## Qualified installer and source delivery

`build/installer-qualification-012-01/receipt.json` passes **43 installer checks and 12 automatic-startup checks**. It executes the actual MZP, tests tamper/conflict/rollback handling, verifies every installed file, then lets a second private Max process discover the installed startup itself. Installed native generation and save/reopen pass. Both loaded module paths/hashes and private INI match; artist profiles remain unchanged. No computer use or artist installation was performed.

| Deliverable in `dist/CyrusArrange-0.1.2/` | SHA256 |
| --- | --- |
| `CyrusArrange-0.1.2-Max2027.mzp` | `6d50cc1e2511851c907a1ab8f3b7bce146acce0c33de583b5248c4a98a03d703` |
| `CyrusArrange-0.1.2-Source-and-Examples.zip` | `f6b54e551564842be9dc83514d8416b7ffee47fb2fae51fde5199712de7ccde2` |

The external `qualification-receipt.json` binds the unchanged MZP to native28, all thirteen exact-source functional receipts and the actual installer result. `source-receipt.json` verifies 145 ZIP members including all 89 exact source inputs, original examples, license and qualification receipts. The Autodesk SDK is an external prerequisite.

The immutable MZP and source ZIP intentionally contain the documentation snapshot taken before installer execution, so those copies still describe the installer as pending. Their adjacent external qualification receipt and this current workspace report record the subsequent pass. No archive was rewritten to change its evidence.

Run the MZP through **Scripting > Run Script**, restart Max 2027, then use **Cyrus > Cyrus Arrange**. Download/open scenes from the matching source/examples ZIP or the workspace examples directory. This release is a tested milestone; ongoing 0.1.3 cache work is not covered by these receipts.

Independent source review found two further issues after native25: ordinary clustering could displace an anchor to a neighboring same-height surface while retaining its original region policy, and round-offset expansion was checked only after the library call allocated its generated path. Both narrow corrections pass the native26 numerical suites; the membership correction also passes the real Max regression above. See [the procedural quality research](research/PROCEDURAL_QUALITY_2026-10-18.md) for frozen before/after probes and precise limits. The historical golden is unchanged: valid old poses remain exact, while explicitly identified invalid outputs are corrected. Native25 remains scoped evidence; final functional, performance, render and installer gates use the successor pair.

The supported readers accept document3/4 and library1/2. New writes use document4/library2. Internal document1/2 and unknown future versions reject. Placement arrays, registry schema1, class identities and native reference slots remain unchanged. See [scene ownership](SCENE_OWNERSHIP.md), [asset library](ASSET_LIBRARY.md), [composition contract](COMPOSITION_DESIGN.md) and [book-row guide](BOOK_ROWS.md).

The numerical height profile is a bounded composition aid. It does not establish physical book stability, subjective styling quality, arbitrary imported-model compatibility or renderer qualification beyond the actual fixtures.

## Subsequent allocation-failure finding

During 0.1.3 fault-injection work, three allocation-failure ownership gaps were independently reproduced in the frozen 0.1.2 numerical baseline. Clipper's `AddPaths_` can leak an unregistered vertex array (240 bytes in the fixture); `InsertLocalMinimaIntoAEL` can leak a pending edge (136 bytes); `NewOutRec` can leak an unregistered output record (128 bytes). These exceptional paths were outside the 0.1.2 release's tested scope. Successful geometry/placement results and work remain exact in the new regression fixture. The unchanged released archives are preserved; narrow ownership repairs and all 113 constructor-failure points pass the scoped 0.1.3 tests. See [the local patch record](../third_party/clipper2/LOCAL_PATCHES.md) and `build/query-accounting-diagnostics-01` / `-02`. This does not claim every allocation path of the dependency has been qualified.
