# Confirmed review findings and remediation plan

23 October 2026. **Investigation and planning only. No product implementation, version change, installer rebuild, artist installation or website publication was performed.** This plan checks the four supplied reviews against the current Scatter **0.86.8.6** tree and its delivered artifacts. The companion [validation matrix](REVIEW_REMEDIATION_VALIDATION_20261023.md) defines the future acceptance tests.

## 1. Decision

All seven distinct review findings remain applicable, with the evidence levels below. Preserve the existing native architecture and fix the specific unsafe or expensive paths. Native bulk storage, candidate identity, independent clearance scopes, ordered acceptance, receiver-bound Paint and staged publication remain the foundation.

The new gallery correction is already implemented and must be retained. It does not change the native density/Relax or projection paths. Its packaging guard addresses gallery release/host/source/artifact pairing; it does not complete the top-level native build-input manifest.

There is one important extension to the reviews: **the interrupted-backup problem also exists in the newer C# Analyzer installer used by the combined EXE**. This is separate from the standalone Analyzer MZP's destructive customized-wrapper policy. Both backup writers need the same correction.

R01–R07 below are local remediation identifiers, not P/I/PG/N roadmap phases or release labels. The older [quality proposal](IMPLEMENTATION_PLAN.md) and [simplification proposal](SCATTER_SIMPLIFICATION_PLAN_20261022.md) retain their historical baselines. This plan takes precedence for these confirmed defects; it does not resume all their optional work.

## 2. Current baseline and concurrent work

| Item | Verified baseline |
| --- | --- |
| Branch / HEAD | `codex/workflow-0.75` / `3d387550cacf37fe1aeae7a01455f7644d9cf08b` |
| Current delivery | Scatter 0.86.8.6, schema 59, recipe 8, CyrusUnified2; Analyzer 0.14.1 |
| Current handoff | [Gallery correction and exact delivery](../combined-installer/DELIVERY_08686.md) |
| Other conversation | `Compare versions 86.8.2 and 64`; its latest repair was complete when inspected. Scope: gallery version pairing, actual library opening, installer and website ZIP |
| Working tree | Extensive pre-existing tracked and untracked changes. HEAD alone is not the delivery. A 5,754-file source snapshot and full Git status/diffs were captured before investigation |
| Native comparison | All 428 current files under Scatter `src`, `include` and `third_party` match the native source entries in the Astra Max review build receipt |
| Current artifacts | Current EXE, website ZIP and installer ZIP hashes match the .6 final receipt; the Max 2027 Scatter MZP passes CRC and manifest payload checks |
| Analyzer comparison | Current embedded Max 2027 Analyzer native/script/startup/installer bytes match the exact historical Analyzer reproduction inputs |
| Knowledge | Selected generation `8a58031bf6efb27cf7c8e30a81d6059206b292269b5e5e24bf1045b704989059`; 38/48 enrolled parents verify, ten are changed. Search returned `stale_evidence`; this investigation uses direct source inspection. No refresh/activation performed |
| New execution | Targeted native, filesystem and Python probes only; no Max launch, full SDK rebuild or full-suite rerun |
| Future qualification | Max 2027 only under the current development rule. Historical Max 2024/2026 qualification remains attached to its original payloads |

The current EXE SHA-256 is `f2ea7be7b74bb1f5b2cf0ab58dc21c735ed775280faee19aab48b6dac76a173b`.
The current Max 2027 Scatter MZP SHA-256 is `c60ce788cd92708d2626aec5ea7616e0c116ce4eab31640c8136001f1d10df88`.
The inspected installer core SHA-256 is `a2b6a62c418b26f4f254efccebb7add06484c555321ac01d06d123e1927dcd4f`.

The local evidence root is [build/review-remediation-plan-20261023](../../../build/review-remediation-plan-20261023/). These ignored files are local evidence, not a Git backup. The [baseline verification](../../../build/review-remediation-plan-20261023/baseline-verification.json) records package/source identities. Keep original .3/.4/.5/.6 receipts immutable.

Before each implementation slice, recheck the specific inputs against the snapshot and current handoff. If the other conversation changes a shared file, inspect that delta and integrate with it; never restore the whole older file to make a patch apply. Especially protect the .6 changes in `build_gallery.py`, `build_max.py`, gallery identity tests, generated labels and release metadata.

A separate [high-poly Mesh preview plan](../viewport-memory/HIGH_POLY_MESH_PLAN_20261023.md) appeared during the final preservation check. It is planning-only and addresses preview admission/storage rather than the projected-movement query in R05. Keep its implementation and qualification separate; coordinate shared memory/publication tests and version selection if both later become part of one delivery. The [planning verification](../../../build/review-remediation-plan-20261023/planning-verification.json) distinguishes that concurrent addition from this task's documents.

## 3. Reconciliation of the seven findings

| ID | Severity / state | Current evidence and applicability | Primary source |
| --- | --- | --- | --- |
| R01 | P1; fresh native reproduction | Boundary Relax with a native white 2×2 image crashes; equivalent array input succeeds. Optimized exit `0xC0000005`; ASan identifies `final.inc:45`. This is current-source native execution, not a fresh Max crash witness | [final.inc](../../../AminScatter/src/final.inc), [image input bridge](../../../AminScatter/src/max_bridge.cpp), `cspImpl_placements` in [controller](../../../AminScatter/tools/ui/templates/unified-core.ms) |
| R02 | P1; current source plus exact historical host-input parity | Standalone Analyzer MZP still overwrites any existing startup and deletes the successful replacement backup. The historical Max reproduction uses byte-identical installer/startup/native/script inputs. The combined EXE has a separate ownership-aware path | [Analyzer MZP installer](../../../CyrusSurfaceAnalyzer/installer/install.ms), lines 13, 45 and 47 |
| R03 | P2; fresh exact-package filesystem reproduction | A simulated 10-byte final backup blocks two consecutive public Install calls for both Scatter .6 and Analyzer .14.1 using the .6 core. Original startup bytes remain intact and no receipt is published. This is retry blockage, not demonstrated original-file loss | `PreserveLegacyWrappers` in [InstallEngine.cs](../../../AminScatter/setup/InstallEngine.cs); `PreserveStartup` in [AnalyzerInstallEngine.cs](../../../AminScatter/setup/AnalyzerInstallEngine.cs) |
| R04 | P2; confirmed missing validation, host consequence unverified | `meshOf` checks UV indices but directly reads `mesh.verts[f.v[k]]`. No geometry-index guard precedes that dereference. A malformed evaluated mesh can therefore escape ordinary rejection/retained-publication handling; no malformed SDK fixture was executed in this task | [max_bridge.cpp](../../../AminScatter/src/max_bridge.cpp), `meshOf`, line 213 |
| R05 | P2; fresh numerical measurement | Moved candidates with projection enabled still exhaustively scan eligible receiver triangles. Three-run medians for 2,000 candidates: 21.44 ms/1,000 faces; 88.34 ms/4,000; 365.18 ms/16,000. This demonstrates numerical scaling, not Max UI latency or FPS | [scatter.cpp](../../../AminScatter/src/scatter.cpp), projected movement loop around line 332 |
| R06 | P2; fresh synthetic mutation reproduction | The real `source_hashes` function misses selected Licensing CMake/source/header/trust inputs and shared Gallery source. Mutating those synthetic dependency paths leaves its result unchanged; included controls are detected. .6 Gallery package verification is stronger, but the top-level before/after guarantee remains incomplete | [offline_build.py](../../../tools/procedural_lab/offline_build.py), [native CMake](../../../AminScatter/CMakeLists.txt), [build_max.py](../../../tools/build_max.py), [managed builders](../../../AminScatter/tools/build_installer.py) |
| R07 | P3; fresh parser reproduction | Both top-level and nested assertion `status: fail, status: pass` duplicate keys pass `read_result`. An ordinary failure is rejected and a normal record passes. This does not establish that existing qualification records contain ambiguity | [results.py](../../../tools/quality_validation/results.py), line 27 |

Evidence: [native runs and exact commands](../../../build/review-remediation-plan-20261023/native-probe.json), [backup retries](../../../build/review-remediation-plan-20261023/backup-probe.json), [Analyzer historical-input parity](../../../build/review-remediation-plan-20261023/analyzer-review-parity.json), [dependency mutation successor](../../../build/review-remediation-plan-20261023/source-manifest-probe02.json), [duplicate-key probe](../../../build/review-remediation-plan-20261023/duplicate-key-probe.json).

The affected `scatter.cpp` translation unit was freshly compiled in optimized and ASan configurations and linked with the matching review build's native libraries. This is a focused reproduction, not a new qualification of every module. Existing gallery-identity and result-protocol tests were also run: **20 passed**, comprising six gallery cases and fourteen result cases. Their passing result demonstrates the missing duplicate-key case rather than disproving it.

## 4. Required behavior and ownership

Use [F02–F12](../../ENGINEERING_FOUNDATION.md) as applicable, especially F04 pending Manual settings, F05 complete publication, F06 work admission, F07 host-thread boundaries, F09 geometry and F11 persistence. Current schema 59 is authoritative; older schema-58 wording in the foundation's F11 limits paragraph is documentation debt.

| Work | Owner / lifetime | Invalidation and work | Undo / failure |
| --- | --- | --- | --- |
| Density sampler | Native borrowed view over validated settings-owned image pixels; at most a bounded mapping/curve copy | Construct once per numerical pass; existing relevant density/mapping keys continue to govern preparation | No authored mutation or new RNG draws; reject invalid input before installing a successor |
| Receiver validation | Host adapter owns evaluated TriObject through its existing RAII holder and produces copied triangles | Validate counts/buffers/indices before reads; keep existing face limits and degenerate-face semantics | No scene edits or Undo changes; controlled diagnostic and retained publication |
| Projection index | Native read-only index over a frozen receiver mesh, initially scoped to one generation call | Build only when projected movement needs it; reuse across all candidates in that call; admit build/query work and storage | Same candidate schedule and nearest-face results; budget/allocation failure retains the preceding complete publication |
| Installer backups | Installer lock and transaction own bounded byte snapshots and verified backup files | Same-volume staging, verified create-only final publication, explicit recovery | Outside Max Undo; unknown edits remain intact; interrupted processes recover from persistent state |
| Build receipts | Build invocation owns an immutable input/configuration description and linked producer receipts | Complete selected dependency set is checked before and after work | Failed or changed inputs leave pending/failed evidence, never a completed qualification |
| Scenario parser | Bounded read-only protocol consumer | Reject ambiguous JSON before trusting identity/status fields | Never repairs records or triggers retries; invalid results fail visibly |

Preserve schema 59, recipe 8, registration/class IDs, source/layer identities, radius calculations, Count admission, protection/preference ordering, original Paint documents and the optimized export/Bands contracts. Preserve successful unaffected ordered results, including full transforms, source/receiver correspondence, radii and reason/order metadata.

These are defect corrections, so exact output preservation is not appropriate for a broken density check. Boundary Relax may legitimately change near mapped density exclusions once it respects the actual sampler. Record those intended changes explicitly. No change is intended to random acceptance draws, positive-density population counts, ordinary non-density Relax, original Paint, or independent spacing scopes.

## 5. Implementation sequence and exit gates

| Phase | Work | Depends on | Exit gate |
| --- | --- | --- | --- |
| A | Freeze .6 inputs, retain reproducers, add R07 parser rejection | Current snapshot | Ambiguous results fail; valid historical records still parse; characterization fixtures identify actual owners and rows |
| B | R01 common Boundary Relax sampling and R04 receiver validation | A | Native negative controls fail before correction; corrected native/adapter tests pass; affected and unaffected host Update cases pass |
| C | R03 shared atomic backup publication, then R02 Analyzer MZP transaction reuse | A | Both installers preserve unknown bytes; failures during backup creation permit safe retry; exact MZP/EXE routes agree |
| D | R06 complete selected build and package inputs | A; before qualifying final binaries | Every selected dependency/configuration mutation prevents a completed receipt or stale package acceptance |
| E | R05 bounded indexed projection | B and D for acceptance | Exhaustive-oracle parity, deterministic ties, lower query counts and honest cold/warm timing/memory evidence |
| F | Interaction, lifecycle and exact-package Max 2027 qualification | B–E | Required matrix rows pass with exact source/package/loaded identities; remaining physical/renderer limits are explicit |
| G | Documentation, independently versioned packages and delivery reconciliation | F | Qualified MZP/EXE identities agree; .6 gallery regression remains closed; current handoff describes actual results |

Independent code changes can be prepared separately, but shared generator outputs and mutations of one Max process must remain serialized. A critical safety correction need not wait for optional readability work. If projection parity needs more time, deliver qualified safety repairs first and retain R05 as open; never report all seven closed in that situation.

### A — Baseline evidence and strict result parsing (R07)

Files: [results.py](../../../tools/quality_validation/results.py), [result tests](../../../tools/tests/test_quality_results.py), existing private scenario manifest/driver.

1. Keep the seven reproduction records and frozen .6 settings/scenes as baseline. Distinguish failures required to change from unaffected behavior required to remain exact.
2. Use a duplicate-rejecting `object_pairs_hook` for JSON decoding. Reject repeated keys at every object level, including identities, terminal state, top-level status and nested assertion status. Equality of repeated values does not make the record unambiguous.
3. Convert decoder/duplicate failures to the existing `IncompleteResult` interface. Retain the byte limit, required identities, terminal marker, exact assertion-ID set and pass/fail checks.
4. Add raw-string tests: fail/pass and pass/fail ordering, identical duplicate values, nested keys, escaped-equivalent keys, and clean controls. Do not construct duplicate fixtures through a Python dictionary, which would remove them before the test.
5. Reparse the sealed historical records using their original requests and manifests. Report an actual conflicting record if found; do not edit it or reinterpret missing results as a pass.

This is a small acceptance-tool correction; it should precede collecting final host receipts. It adds no Max work and no product API.

### B1 — Boundary Relax density correctness (R01)

Files: [final.inc](../../../AminScatter/src/final.inc), [scatter.cpp](../../../AminScatter/src/scatter.cpp), [density_image.h](../../../AminScatter/include/density_image.h), [density_image.cpp](../../../AminScatter/src/density_image.cpp), existing density/scatter tests and owned host fixture.

1. Turn the white-image crash into a permanent native regression. Keep the equivalent array case and a movement-producing three-point configuration so the validator actually runs.
2. Construct one validated `ImageSampler` for the pass using the existing representation precedence: native `densityImage` when present, otherwise the legacy array/dimensions. Keep pixels immutable and borrowed for the sampler's bounded lifetime; do not materialize a second image or per-placement pixel copy.
3. Replace direct array indexing in the Boundary Relax movement validator with the shared sampled-density eligibility check. Apply it to the endpoint and the existing intermediate path samples.
4. For UV coordinates, validate the selected face and finite barycentric/UV calculation. For World/Local coordinates, use projected world positions and the existing copied mapping frame; do not require a UV channel that those modes do not consume.
5. Honor the existing bilinear filtering, repeat/clamp, physical size, rotation, offsets and response curve. Preserve inverted-density preprocessing. The eligibility condition is positive sampled density; do not draw another random number or rerun population admission at each step.
6. Keep receiver-evaluated Map mode on its current host-aware path. The controller currently uses native distribution 0 for it and applies `cyrusReceiverMapFilter` afterward. `ImageSampler` deliberately rejects `Coordinates::Map`; do not force that mode through a copied image or access SDK maps from workers.
7. Preserve source/Band membership, maximum movement, blocker checks and the order relative to Edit/final clearance. Do not weaken path checks or zero-density exclusions to avoid the crash.
8. Give malformed images, nonfinite values or invalid mapping an actionable bounded exception. A successor failure retains rows, epoch, statistics and preview. No catch-and-continue or empty-vector bypass.

Native acceptance covers both representations, all-zero/all-one/gradient/checker images, a curve that maps values to zero, every supported image mapping/wrapping, rotated/scaled frames, path crossing, malformed dimensions and positive-density count preservation. Host acceptance includes actual generated controls, Update, relevant Live edits, pending Manual changes, Undo/Redo and save/reopen.

### B2 — Validate receiver geometry before dereferencing it (R04)

Files: [max_bridge.cpp](../../../AminScatter/src/max_bridge.cpp), a small validation helper only if needed to test the real adapter, and an owned SDK fixture.

1. Check signed vertex/face counts before unsigned conversion or reserve. Require face/vertex buffers when positive counts need them. Preserve established empty/degenerate receiver handling.
2. Validate each geometry face index against the vertex count before reading a vertex or applying a transform. Validate consumed numerical positions/transforms at the existing boundary without changing face order or silently dropping invalid faces.
3. Keep UV validation independent. World/Local image modes still need safe geometry even when no UV channel is required. Preserve the lifetime of converted versus original TriObjects and cleanup on every throw.
4. Report receiver identity, offending face/index and the required repair. The diagnostic should state that the last completed result is retained; it must not imply a new empty result succeeded.
5. Exercise the actual SDK adapter with a private hidden malformed TriObject fixture. Avoid displaying corrupt mesh geometry. A pure-vector test alone does not qualify SDK extraction.
6. Start from a valid publication, inject an out-of-range face index, invoke Update, verify unchanged publication/display, repair the mesh, then verify successful recovery. Include ordinary valid meshes, missing UVs, zero/degenerate geometry and converted-object cleanup controls.

No scene schema, normal valid geometry or clearance semantics should change. Do not add SEH swallowing as a substitute for validating inputs.

### C1 — Atomic, recoverable backup publication for both products (R03)

Files: [InstallEngine.cs](../../../AminScatter/setup/InstallEngine.cs), [AnalyzerInstallEngine.cs](../../../AminScatter/setup/AnalyzerInstallEngine.cs), focused installer fixtures.

1. Introduce one small shared internal helper for publishing a bounded verified backup. Hold the existing product installation lock throughout destination inspection and publication.
2. Validate destination/path length/reparse restrictions and disk allowance before publication. Create a unique temporary file beside the destination using create-new semantics; write bounded bytes, flush, close and read/hash-verify it.
3. Atomically move the verified temporary file to a previously absent final name. If another valid final backup already exists, verify equality and reuse it. Never use replacement semantics to overwrite an unexpected existing backup.
4. Publish any backup-set completion metadata only after all required individual files verify. A partial set of valid final backups is safe to complete on retry.
5. Address already-poisoned legacy backup paths explicitly: use a versioned backup namespace for the corrected writer. Leave prior differing bytes intact. While the original wrapper is still recognized/receipt-owned, create and verify its new backup before registration changes, and record both paths. If original bytes cannot be established, refuse with an actionable path; do not claim lost data was recovered.
6. A process interruption may leave an unreferenced temporary file, but it must never leave a partial canonical final backup. Retry can create a fresh unique temp without deleting unknown files. Cleanup must be restricted to provably owned temporary artifacts.
7. Extend fault points to before create, partial write, flush, verification, before move and after move. Existing journal checkpoints begin too late. Exercise both catchable errors and termination of a verified disposable child installer process.
8. Route Scatter `PreserveLegacyWrappers` and Analyzer `PreserveStartup` through the helper. Preserve independently owned receipts and registration journals. Do not introduce a cross-product/global rollback promise: the combined EXE still reports completed products when a later product fails.

The fresh reproduction simulated interrupted files; future acceptance must include actual process interruption. Power-loss guarantees beyond documented filesystem primitives remain separate from process-kill recovery.

### C2 — Bring the Analyzer MZP onto the ownership-aware transaction (R02)

Files: [Analyzer install.ms](../../../CyrusSurfaceAnalyzer/installer/install.ms), [AnalyzerInstallEngine.cs](../../../AminScatter/setup/AnalyzerInstallEngine.cs), [build_max.py](../../../tools/build_max.py), [build_installer.py](../../../AminScatter/tools/build_installer.py), package/host fixtures.

1. Replace the standalone script's separate file/INI replacement algorithm with a thin host adapter to the shared, corrected Analyzer installation engine. Package the bounded managed helper and its exact descriptor/hash with the Analyzer MZP.
2. The adapter checks the Max year and package/helper identity, resolves this host's actual redirected paths and invokes the intended assembly. Verify the loaded helper's identity; do not silently resolve an older already-loaded global type. If the host cannot load the matching helper safely, preserve destinations and request restart.
3. Preserve ownership rules: valid receipts own exact startup bytes and registered runtime; no-receipt upgrades require exact recognized previous wrappers/registration. Unknown/custom startup, receipt, runtime or registration bytes are preserved and reported with their paths.
4. Retain verified migration backups after success. Journal startup, installed receipt and plugin registration together. Run recovery under the same lock and refuse external changes made since the journal was written.
5. Verify native/script payloads before registration. Keep existing immutable runtime directories, independent Analyzer versioning, shared INI entries for unrelated plugins and startup loading adjacent to the native module. Installation does not Analyze a scene or load a new native module into the current session.
6. Qualify the exact packaged MZP as well as the combined EXE's actual install handler. Testing the C# helper alone does not prove MAXScript loading, payload expansion or real host path selection.
7. Test fresh, repeat, known legacy, current receipt, custom startup, custom registration, wrong host, tampered payload/helper, concurrent installer, interruption/restart/retry and edited recovery destinations. Unknown-byte refusals must happen before replacing registration.

The current combined EXE already rejects unknown Analyzer startup files. Keep that protection and its independent-product behavior while removing the MZP discrepancy.

### D — Complete build provenance and package admission (R06)

Files: [offline_build.py](../../../tools/procedural_lab/offline_build.py), [build_max.py](../../../tools/build_max.py), [build_gallery.py](../../../AminScatter/tools/build_gallery.py), [build_installer.py](../../../AminScatter/tools/build_installer.py), focused tooling tests.

1. Define an explicit selected-input manifest for each actual build configuration. Retain current source/header/textual `.inc`/test/vendor coverage; add selected Licensing CMake, source and public headers, the resolved public team trust header, shared Gallery source, relevant CMake modules and producer/build scripts.
2. Derive external dependency selection from the effective configuration, including licensing flags, BUILD_TESTING, host/SDK, generated inputs and managed targets. Audit it against CMake/compiler dependency information; a hard-coded unrelated checkout-wide file sweep is not a substitute for knowing what the target consumes.
3. Capture effective build identity: generator/configuration, relevant options/defines/compiler/link flags, compiler/linker/CMake versions and hashes, SDK identity, and selected managed reference identities. Record public trust material by hash; do not capture issuer secrets or licensing policy state.
4. Snapshot before compilation and verify the same selected files/configuration after compilation/tests and before completing the receipt. Changed, added, removed or unavailable dependencies leave a pending/failed result. An option change that selects a new dependency must change the manifest.
5. Bind nested Gallery/installer producer receipts and artifact hashes into their consumer. Retain .6's assembly version/host/artifact/source/shared-source checks. Complete the MZP installer-core guard, which currently checks the core artifact and `InstallEngine.cs` but not all the producer's Analyzer/Options/shared-source identities; the EXE builder already checks more of that set.
6. If managed builders promise frozen inputs, capture their consumed source/reference identities before compilation as well as after it. Hashing only after a compile cannot establish that the hashed bytes were the ones consumed.
7. Version the receipt format if its guarantees/required fields change. Historical receipts remain readable as historical evidence with their original completeness limits. Do not rewrite them or stamp them complete under a stronger schema.
8. Add mutation tests for selected external .cpp/.h/CMake/trust/shared inputs, included positive controls, absent files, changed configuration and mismatched nested receipts. Use synthetic trees and copied public fixtures; do not edit live licensing files to demonstrate the guard.

A clean build and payload SHA identify useful facts, but neither repairs an incomplete input closure. Final correction qualification must use the strengthened capture from a fresh output directory.

### E — Indexed, bounded projected movement (R05)

Files: [scatter.cpp](../../../AminScatter/src/scatter.cpp), [spacing.inc](../../../AminScatter/src/spacing.inc) or a narrowly extracted geometry helper, native projection/oracle tests and private performance fixture.

1. Preserve the current exhaustive path as a small independent test oracle. Freeze eligible-face order, `closest` arithmetic, strict comparison, final face provenance and full resulting transforms before optimization.
2. Build one immutable nearest-triangle index over the current sampler's eligible receiver faces when nonzero movement and Keep on surface require it. Reuse that index across the call's candidates. Small inputs may keep an explicitly measured exhaustive path with identical semantics.
3. Preserve **first eligible face wins at exact equal distance**. The existing `SurfaceTree::project` starts from a hint and retains it on ties; its tree traversal can also affect equal winners. It is not a drop-in replacement for this loop. Add an explicit stable tie policy or a narrow separate query entry point, and keep existing Point/Boundary Relax tie behavior unchanged unless separately characterized and justified.
4. Keep conservative bounds so pruning never hides an equal or better candidate; retain the existing closest-point arithmetic at leaf evaluation. Test coincident/coplanar faces, shared edges/vertices, identical distances, reordered trees, large coordinates and degenerate exclusions.
5. Define memory and work admission before allocation. Account for face indices, tree nodes, build work, query node visits and actual triangle tests, including rejected candidates. Use checked arithmetic and a per-solve shared budget across receivers so per-receiver resets cannot evade the limit.
6. Set initial numeric limits from measured current fixtures and supported input caps; record the constants, units and diagnostics in the implementation decision. Exhaustion rejects the entire successor with its old publication retained. Do not raise Count/Bands limits or silently publish a partially projected set.
7. Initially keep the index call-owned and release it at return. Current preparation cache hits already avoid generation. Add persistent cross-call caching only if measurements justify it and an explicit bounded receiver-geometry/transform key, eviction and lifetime contract is supplied. Do not retain duplicate full meshes to advertise cache reuse.
8. Preserve all RNG calls/order, explicit candidate anchors, receiver/source correspondence, density eligibility after movement, orientation and downstream Edit/clearance. Leave the separate Analyzer single-anchor loop unchanged in this slice unless its own parity and measurement are added.
9. Compare build time, query time, total solve time, query counts and peak scratch separately. Proposed dense-fixture acceptance: at least 10× fewer exact triangle evaluations on the fixed 16,000-face/2,000-candidate case and lower median total time including index construction. This is a future gate, not a claimed result or a universal complexity/latency guarantee. Bound small-input overhead or retain the measured exhaustive fallback.

No GPU implementation or asynchronous scheduler is required. Workers may share immutable numerical data, but SDK access/publication stays on the host thread and existing synchronous lifetime rules remain.

## 6. Interaction, UI and lifecycle acceptance

The [matrix](REVIEW_REMEDIATION_VALIDATION_20261023.md) lists required cases. The important missing coverage is combinations across stages, not an absence of all tests.

- Exercise density representation × mapping/wrapping/curve × Point Relax/Boundary Relax/both, with movement, curved receivers, Bands, Paint and protected Edit controls. Use focused full cross-products for cheap numerical cases and explicit risk-selected host cases.
- Invoke actual generated controls and Update handlers, observe subsequent queued callbacks, and require stable completion. Do not replace Live execution with a hidden forced Analyze/Update to manufacture a pass.
- Verify ordered IDs, transforms, correspondence, radii, accepted order/reasons and publication epochs. Observe solve/preparation/upload counters separately; same rows do not prove avoided work.
- Preserve pending Manual edits during Recipes browsing, owner/layer/source changes, presentation changes and unrelated Undo/animation. Retain the .6 96-model library opening and same-window reuse checks.
- Exercise failures before validation, during preparation, during staging, at installation and after commit observers. Native access violations must be eliminated at their cause; transaction rollback cannot rescue a crashed process.
- Test Undo/Redo, save/reopen, source/receiver deletion and repair, reset, clone/merge ownership and repeated owner switching for changed boundaries. Compare retained native generations/memory over repeated runs and after history release.
- Physical rollout drag/DPI, renderer/PFlow/Bake combinations, true device loss and sustained long-session memory remain separately named qualification work. Passing scripted controls or CPU fault injection must not close those broader gates.

Keep a discoverable scenario map from trigger and contract to fixture, source/package identity, result and limit. No new public MCP mutation or generic testing framework is required.

## 7. Maintainability after correctness

Limit initial cleanup to touched responsibilities: one density sampler construction/eligibility helper, one verified backup publisher, one selected-input manifest builder, explicit projection tie/budget policy and one strict decoder. Name inputs, outputs, ownership and failure behavior in those boundaries.

After the regressions pass, apply the existing simplification plan in small characterized slices: native policy/settlement helpers, publication snapshots and compressed Edit control flow. Preserve arithmetic/traversal, budget charging and resource lifetimes. Textual `.inc` removal or a language-percentage target is not an acceptance criterion. Do not combine broad formatting with the crash fix.

## 8. Release, documentation and knowledge follow-through

No version is changed by this planning task. If this remains the complete bounded corrective scope and .6 is still the latest release, recommend **Scatter 0.86.8.7** and an independently labeled **Analyzer 0.14.2 installer correction**. Recheck the [version policy](../../Release_Versioning.md#choosing-the-next-version) and latest delivery before implementation; these are proposed labels, not reservations or delivered artifacts. Keep authored schema/recipe/POD contracts unless an actual interface change requires otherwise.

The Scatter native binaries must be rebuilt for native fixes; .6's unchanged-native reuse is no longer suitable. Match native modules, generated script, gallery, installer core and host guards. Keep Analyzer algorithm changes separate from installation changes and state any reused payload identities honestly.

Qualify the new work in Max 2027. A later request to extend the correction to Max 2024/2026 requires distinct matched builds and scoped acceptance; do not relabel their old native modules as containing the fix. Preserve current .6 three-host artifacts. When an implementation delivery is authorized, provide the shareable EXE and retain a runnable Max 2027 MZP from the exact qualified pair, with **Scripting > Run Script**, then restart instructions. Plant content keeps its independent revision.

Update the current delivery/handoff, execution ledger, backlog, artist-facing diagnostic/installation guidance and version policy after actual acceptance. Reconcile stale current-navigation/schema wording while preserving dated receipts. Website sources/download staging, ZIP construction and live publication remain distinct actions; any successor site package must reference the exact qualified EXE and preserve the .6 website work.

Knowledge follow-through is a separate reviewed refresh: identify changed/enrolled parents, prepare a successor, validate retrieval and timeout-recovery, then activate only after its checks. A documentation edit or candidate build must not be reported as a live index update. Current stale knowledge did not establish this investigation's conclusions.

## 9. Completion criteria

Each R01–R07 closes only when its original reproduction is addressed, its unaffected controls pass and its relevant host/package boundary is witnessed. Preserve failure and superseded fixture records. Tests must identify exact source, configuration, artifact and request identities.

The delivery report must distinguish native checks, Python cases, assertion labels, host scenarios, physical observations and historical reused evidence. Report failed/blocked/not-run cases explicitly. Do not sum repeated campaigns into an implied exhaustive scenario count.

Implementation is complete for this scope when all seven findings have accepted evidence, the .6 gallery correction remains intact, current docs describe the real limitations and the exact requested installer is qualified. Broader physical, renderer and long-session gates stay open until separately demonstrated.
