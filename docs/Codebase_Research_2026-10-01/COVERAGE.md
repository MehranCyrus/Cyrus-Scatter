# Scope, fingerprint, read/run coverage and reproduction

Observed on **2026-10-01**, Asia/Tehran. Run JSON timestamps are UTC. Repository: `F:/Cursor/_Cyrus_Apps/CyrusScatter`. The user authorized the first codebase investigation in the three supplied text files. The independent external brief/report was not read, and no second model task was launched.

## Baseline and preservation

No applicable `AGENTS.md` was found in the inspected root/ancestor locations or repository file inventory. HEAD was `f3f30ce98c4c1a8105e47805870ba73aef47794d`, with pre-existing tracked modifications and untracked files. This research did not treat HEAD as the complete source identity. The initial [113-file source fingerprint](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Codebase_Research_2026-10-01/evidence/source-fingerprint.json), [Git status](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Codebase_Research_2026-10-01/evidence/git-status-before.txt), [HEAD](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Codebase_Research_2026-10-01/evidence/git-head.txt) and [binary-capable working-tree diff](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Codebase_Research_2026-10-01/evidence/working-tree-diff.txt) preserve that distinction.

Only this new research directory and its scratch outputs under `build/codebase-research-2026-10-01` were intentionally written. No installation, production code change, scene overwrite, live scene interaction, external upload, PR, commit or publishing occurred. Existing fixture save/open operations were confined to newly created synthetic scenes in fresh hidden batch processes and research scratch paths. No cleanup/deletion was performed. The original live Max process was left open. The normal installed module/script files were inspected for identity rather than reloaded or edited.

Final [preservation.json](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Codebase_Research_2026-10-01/evidence/preservation.json) compares the source hashes and Git state with the baseline. [artifact-manifest.json](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Codebase_Research_2026-10-01/evidence/artifact-manifest.json) contains sizes and hashes of the delivered research files, excluding itself and Python bytecode. It does not archive SDKs, installers or large build trees. Temporary binary outputs remain in scratch; build identities and commands are in evidence.

## Source/evidence read coverage

The machine-readable [read-coverage.jsonl](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Codebase_Research_2026-10-01/evidence/read-coverage.jsonl) records requested ranges, source hashes and timestamps for 39 files through the range reader. [read-coverage.csv](F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Codebase_Research_2026-10-01/evidence/read-coverage.csv) unions those ranges for navigation. These are requested reads, not a claim that every large tool output displayed without truncation. Important truncated regions were recovered through smaller reads, source searches or focused extraction. Early UTF-8 output problems are recorded below. Broad directories were inventoried with `rg`; files in an inventory were not automatically considered read.

| Area | Actually inspected | Boundary |
|---|---|---|
| Assignment | All three supplied files: START HERE, codebase research brief, project context | Did not read independent researcher output or automatically execute its second task |
| Entry reports | `docs/README.md`, `Max_2027_Installation.md`, CPU implementation report, viewport implementation report, round-two report | Reports treated as historical claims; source inspected separately |
| Historical records | CPU evidence JSON and result/scene hashes; both viewport indexed archives; three raw CSV/cases matrices; reports' parity/visual/fallback conclusions | Hashes and numeric summaries rechecked; original scene timing/visual captures not recreated or independently judged pixel-by-pixel |
| Older proposals | September 29 performance/resource strategy and documentation governance; roadmap references/status via docs index | Not a full reread of every historical roadmap or licensing/AI plan; current source takes precedence |
| Core | `scatter.h`, `execution.h/.cpp`, `scatter.cpp`, `cluster.inc`, `prepared_band.inc`, `spacing.inc`, `final.inc`, `orientation.inc`, `boundary_falloff.inc` | Core decisions grounded in these implementations; not a new proof of all geometry algorithms |
| Bridge/preview | `max_bridge.cpp` extraction, filters/transforms, overlap and native entry points; `preview.cpp`, `geometry_preview.inc`, `preview_batches.inc` | Not every bridge settings conversion line exhaustively audited |
| Script/generator | Generated `placements`, population/preview/cache/sync/layer/draw/live/time/Undo paths; compute/viewport/performance patches, responsive module and PFlow template | Targeted ranges in the 11,820-line controller; not all UI panels. PFlow template is under `tools/ui/templates` |
| Analyzer/edit | Analyzer native analyzer/elements/bridge; script run/revision/live/timer sections; CS Edit stack identity logic and modifier display/lifecycle symbols | Not a full CS Edit modifier security/correctness review or renderer integration test |
| Build/tests | Both CMakeLists, shared SDK CMake module, build_max.py environment/build flow; 3 host wrappers and fixtures; compute benchmark; native test enforcement/selected differential cases | All native suites executed, but every line of every native test was not manually reviewed |
| Performance tools | compute benchmark wrapper, viewport summarizer, report schemas/trace entry points and historical recipes through reports | Existing UI interaction/renderer tools were not run against the live scene |
| SDK | Actual 2027 InstanceDisplayGeometry header ranges, display/interface declarations through compilation, version guards/libs for both SDKs | Documented instancing sample absent at checked path; no runtime rendering by SDK probe |
| Web | Autodesk thread/render-item/2027 display/instance docs; tyFlow Display; Chaos performance; CUDA 13.4; OpenCL device/sharing refs; SYCL 2020 rev12; Microsoft FP/DirectCompute/GPUView/timestamps/ASan; oneAPI arena; official PresentMon metric definitions | Exact URLs/sections, versions, dates/access and contrary evidence are in claims.csv; no proprietary source, forums or search snippets used to support implementation |

The initial reads before introducing the range helper (assignment, entry reports, repository/build inventory) are recorded here rather than retroactively presented as timestamped range reads. Some later focused `rg`/direct reads also appear only in this table and the tool history. Source hashes identify the complete snapshot, not complete manual coverage.

## Named local runs

| Run | Work performed | Artifacts and limits |
|---|---|---|
| R00 | Repository/machine/module/package inventory and source fingerprint | `machine.json`, `loaded-modules.json`, `nvidia-smi.txt`, `git-*`, `source-fingerprint.json`; on-disk module hashes, no in-memory script interrogation |
| R01 | Fresh isolated Release builds for 2027 then 2026; 8 + 1 native suites each | `configure-*`, `build-*`, `ctest-*` text+JSON; `build-2026-identity.json`, `build-2027-identity.json`; native success is not runtime support |
| R02 | Three original byte-identical fixtures in separate hidden 2027 batch hosts | `max2027_smoke-*`, `compute_performance_smoke-*`, `viewport_performance_smoke-*`; all SUCCESS. Original runs recorded privateINI/configured binaries, without module enumeration |
| R02I | Follow-up identity-logging wrappers around the same copied fixtures | `verified-*`, `verified-v2-*`, `verified-v3-*` preserve failed logger attempts; final `verified-v4-*` records actual module paths/hashes and fixture results. See diagnostics below |
| R03 | Existing17-case native suite, serial vs automatic, three order-reversed blocks | Six `threads-{block}-{policy}.txt/.json` plus `threads-summary.json`;21 samples/policy; generated binary output hashes recorded; no Max workflow timing |
| R04 | Actual-source projection query probe with tie counterexample | `projection-compile.*`, `projection-raw.*`, `projection-summary.json`; two warmups/nine paired trials, seed 47291; no production change |
| R05 | SDK display-interface compile/link probe for 2026/2027 | `sdk-probe-*`, `sdk-probes.json`; not loaded/executed and not a viewport benchmark |
| R06 | Copy generator to scratch and regenerate; verify packages | `generator.*`, `generator-parity.json`, `package-identity.json`; source/package untouched |
| R07 | Verify historical hashes and recalculate raw CSV summaries | `historical-audit.json`, three `recomputed-*.json`; historical performance stays class C; no historical files overwritten |
| R08 | Report/ledger/link/source-preservation audit | `document-audit.json`, `preservation.json`, `git-status-after.*`, manifest; self-audit only |

Research Max2027 Scatter DLL: `6e2eb2bb6565420d578b3c7137194b6b2f70df7a891a96ea091a411b9f6ef799`; CS Edit: `85f206a209311dfef07c3425f28b732393066ddbc97429b86871fd176144a716`; Analyzer: `b607557a9e1899e51db20d67acc816bd18deca42a192d542465f63305e6e9f36`. These differ from the installed package's binary hashes; commands and exact source snapshot are preserved rather than claiming reproducible byte-identical linker output. Native benchmark hash: `0a0881015f85dab03152182d433f5741f76092cde5fcc952eaefa31a4d622de0`; projection executable: `0b8cba9cd15ccb7b8c0d552a42da71d0d51581db6399c1b214524077ed922663`.

The final v4 wrappers log paths from the test host itself before entering the fixture; Python hashes the corresponding files and checks expected research plugin paths. Scripts are byte-identical private copies explicitly loaded by each fixture. No script or logger is injected into the artist process. Each executable/SDK/host identity must be reverified when reproducing; a package name is insufficient.

## Reproduction

Requirements: this Windows checkout, installed Max 2027 runtime for host fixtures, matching extracted SDKs at the recorded paths, MSVC 14.38.33130 / WinSDK 10.0.19041.0 under Visual Studio 2022 Community, CMake/CTest, Python and Node. `validate.py` imports only the existing build tool's compiler-environment helper; it does not call its packaging/install main. Commands/working directories/return codes/timestamps for actual subprocesses are stored in adjacent JSON. No package install is needed for reproduction in this environment.

Use a fresh `CYRUS_RESEARCH_RUN` tag to keep reruns out of the original results. The helper accepts only a short alphanumeric/dash/underscore tag. Run these **sequentially**, stopping on failures; the first snapshot is useful for later preservation checking. The original investigation used the default paths (no tag); the rerun option was added afterward to protect that evidence.

```powershell
$researchDir = 'F:\Cursor\_Cyrus_Apps\CyrusScatter\docs\Codebase_Research_2026-10-01'
$env:CYRUS_RESEARCH_RUN = 'rerun-20261002-a'
python "$researchDir\research_tools.py" snapshot
python "$researchDir\validate.py" build2027
python "$researchDir\validate.py" build2026
python "$researchDir\validate.py" generator
python "$researchDir\validate.py" packages
python "$researchDir\validate.py" hostverified
python "$researchDir\experiments.py" sdk
python "$researchDir\experiments.py" projection
python "$researchDir\experiments.py" threads
python "$researchDir\audit_evidence.py" historical
```

Rerun evidence goes to this folder's `evidence/reruns/<tag>` and large outputs to `build/codebase-research-2026-10-01/<tag>`. Generator/host actions refuse to reuse an occupied scratch directory. Choose another tag instead of deleting or overwriting a prior run. These scripts have hardcoded compiler/runtime assumptions intentionally exposed in source; adapt them explicitly for another machine. Host fixtures create/save/open only their scratch scenes. Do not substitute a live-host automation call. Running the visual experiments X01/X02 requires additional fixtures/instrumentation described in REPORT, not these compile-only probes.

## Failures, unavailable evidence and excluded claims

- The first snapshot printed a Unicode error under the Windows console code page **after** its evidence writes. The range reader initially had the same printing issue. Output encoding was corrected; important source ranges were reread. The snapshot data was preserved, not regenerated over the baseline.
- The first SDK/projection invocation could not resolve `cl.exe` through the initial subprocess lookup. The runner was changed to use the absolute compiler from the prepared environment, and the named successful compile/run logs were retained. This was a harness startup failure, not a native compile failure or performance observation.
- R02I's first three wrappers failed before the smoke fixture: top-level MAXScript `local`, unsupported chained call syntax, and attempting to iterate a .NET module collection as a MAXScript collection. The v4 wrapper uses a scoped block, a separate process variable and indexed collection access. Failed listener/result/run records remain under their distinct prefixes; they are not counted as fixture passes. Original R02 passes remain separate.
- The 2027 developer thread-safety guide could not be fetched. The 2026 guide and 2027 local headers were used with the limitation stated. A oneTBB main documentation fetch exposed navigation but its later body fetch failed; the accessible explicitly provisional oneAPI specification supplied the arena contract. No silent source-version substitution supports a shipment claim.
- No new completed-frame/present capture, retained display runtime, artist-scene navigation benchmark, live gesture timing, GPU compute kernel, renderer run, sanitizer run, 32 GB machine or Max 2026 application test was performed. Historical captures were not reclassified as newly measured results.
- The source-preservation audit is finite: 113 fingerprinted source/tool/test files plus tracked diff/status, package hashes and the original scene hash. It is not an entire-drive forensic audit. The report's technical and citation checks were done by the same investigator.
