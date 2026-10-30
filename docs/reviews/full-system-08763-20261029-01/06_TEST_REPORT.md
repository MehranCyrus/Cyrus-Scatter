# Test report and reproducibility

## Identity

| Item | Value |
|---|---|
| Branch / HEAD | `codex/workflow-0.75` / `75c60d54dbfd736ffef135d211863516a63543a7` |
| Product / host | Scatter 0.87.6.3 / Max 2027 only |
| Capabilities | scene schema 65; recipe 9; Edit storage 3; Interactions 16; viewport selection 1 |
| Generated script SHA-256 | `95265649f3147d73c105ba6403849c8b9c106d15c3799aa1c431f021627e158e` |
| Shipped Max 2027 MZP SHA-256 | `de3a2a17d0d4cf2237d8532901c494323495c9c1d4f4c1a4ca9547baf53ffacf` |
| Fresh source manifest | 638 build-input entries; later concurrent differences recorded separately |
| Earlier qualified source comparison | Fresh build snapshot matches qualified source; final workspace has subsequent changes |
| Garden input SHA-256 | `bd41e91c6da20aa5184693535f86899350f44fb11946bb7b9fdaf2aa3085c132` |

The existing dirty/untracked product tree was the input. No Git reset, checkout, cleanup or commit was performed. [Initial status](evidence/git-status-start.txt), [final status](evidence/git-status-end.txt), [identity](evidence/identity.json), [native receipt](evidence/native-receipt.json), [source hashes](evidence/source-hashes.json) and [package verification](evidence/package-check.json) are retained. An initial relevant diff is retained in the owned build directory, with its hash recorded here; unrelated source content is not republished in the ZIP.

The final identity check caught concurrent edits to picking/native integration and several UI templates. Tests used the recorded build libraries and copied host payload; their passes do not qualify the subsequent workspace edits. The finding-specific sources and native interaction/placement probe inputs remained unchanged. Final coverage rows contain source hashes and explicit drift labels. Reproduction against a later revision requires its own build and qualification; do not combine new headers/scripts with these retained binaries.

Build root: `build/full-system-review-08763-20261029-01`. Report root: `docs/reviews/full-system-08763-20261029-01`. Test Library roots are short owned paths under `build/`, required by the supported Library path limit. Original `Test Scene/`, shipped scenes and artist profiles were not overwritten.

## Executed commands

Run from the repository root unless stated otherwise. These are the exact campaign commands or equivalent invocations of the checked-in review drivers. Use a **fresh owned run/data directory** for a new campaign; drivers intentionally refuse to overwrite store/host fixtures. Their directory constants are explicit. Existing raw evidence should be preserved.

```powershell
python tools/procedural_lab/offline_build.py --project scatter --year 2027 --generator Ninja --jobs 4 --output build/full-system-review-08763-20261029-01/native
python tools/procedural_lab/check_generated.py --output build/full-system-review-08763-20261029-01/generated
build/mcp-venv/Scripts/python.exe -m pytest tools/tests -q --basetemp build/full-system-review-08763-20261029-01/pytest-temp --junitxml build/full-system-review-08763-20261029-01/python-tests.xml
python tools/shared_library_0871/managed_tests.py --output build/full-system-review-08763-20261029-01/managed-r08763b
python docs/reviews/full-system-08763-20261029-01/drivers/run_native_probe.py
python docs/reviews/full-system-08763-20261029-01/drivers/run_native_probe.py --benchmark
python docs/reviews/full-system-08763-20261029-01/drivers/run_supplemental.py
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests/test_publication.py CyrusMCP/tests/test_license_boundary.py CyrusMCP/tests/test_feature_catalog.py CyrusMCP/tests/test_source_scale.py CyrusMCP/tests/test_procedural_plan.py CyrusMCP/tests/test_recipes.py -q --basetemp build/full-system-review-08763-20261029-01/mcp-temp --junitxml build/full-system-review-08763-20261029-01/mcp-tests.xml
```

From `AminScatter/`, both `node tools/ui/assemble-template.test.cjs` and `node tools/ui/approved-layout.test.cjs` passed deterministic assembly, namespaces/declaration scope, complete control mapping, cold-event guards, independent Band scale channels, lazy-page owner capture and action cleanup.

The synthetic licensing suite reuses freshly built `native/license-core` libraries, compiles current signed-license tests and generates ephemeral vectors. No old multi-host licensing runner was invoked. See `drivers/run_supplemental.py` for compiler arguments and groups.

## Private Max campaign

The first build above retains the normal public-trust configuration for offline checking. Host tests use a separate build:

```powershell
build/mcp-venv/Scripts/python.exe docs/reviews/full-system-08763-20261029-01/drivers/test_authority.py --root F:/Cursor/_Cyrus_Apps/CyrusScatter --output build/full-system-review-08763-20261029-01/test-authority
python tools/procedural_lab/offline_build.py --project scatter --year 2027 --generator Ninja --jobs 4 --build-only --team-trust-header build/full-system-review-08763-20261029-01/test-authority/team_public_key.h --output build/full-system-review-08763-20261029-01/test-native
```

The authority runs concurrently during this setup. The four native modules and Gallery from `test-native`, plus the exact generated script, were copied to `test-payload`. Each launch used `tools/shared_library_0871/launch.py --year 2027 --payload .../test-payload --ocio-default`, a fresh `--output`, fresh short `--data`, the corresponding script below, and a bounded timeout. Only the garden added `--renderer` to load installed plugin classes required by its saved assets. The launcher uses private INI/plugin/startup paths, verifies loaded module paths/hashes and script fingerprint before testing, and closes only its own process.

| Driver | Output directory / owned PID | Result |
|---|---|---|
| `host_review.py` | `host` / 48184 | Missing/malformed license denied, synthetic import admitted; role/hiding/budget/selection fixtures complete |
| `host_library.py` | `library-host` / 3316 | Real native Scene save, units guard, independent merge, save/reload complete |
| `host_garden.py` | `garden-host` / 50052 | Copied garden, 77 rays, 24 camera submissions, 30 held/release/orbit samples complete |
| `host_render.py` | `render-host` / 24440 | Eight posed plants, actual 192×192 Default Scanline automatic output complete |

All four launcher receipts report exit 0, no timeout and unchanged artist INI. [Loaded identity and launcher receipts](evidence/) distinguish the test build from the shipped archive. The test authority process was stopped afterward. Real owner licensing storage was never used.

The rendered [image](evidence/scanline.png) was inspected: nonblank green posed blade geometry and the fixture's purple collider are visible on the gray background. This is a small material/output smoke test; it does not certify normals, UVs, fixed-part clipping or external renderers comprehensively.

## Results and limitations

- Native CTest: 62/62 pass; generated 379-control mapping and 32 fixture delimiter checks pass; 155 Python tools tests and 84 selected MCP tests pass.
- Managed Library: 244 transaction assertions pass, plus supplemental archive/path checks. The abandoned load-stage behavior is a reproduced **finding**, not a test that recovery is correct.
- Signed licensing: 954 assertions in ten groups pass; policy/local client groups also pass in CTest.
- Contact math: 648 deterministic settings cases, 6,480 face comparisons; 288 incremental/full comparisons; fixed-parts/bounds regressions; sparse overlays and thread equivalence pass.
- Real garden: plugin-reported displayed tickets advance while held, static navigation avoids re-evaluation/uploads, original file preserved.
- Shipped MZP: CRC/member hashes/manifest/host guards pass. No new installer was made and no installation was executed.

Harness corrections were made only in review drivers: the overlay test initially lacked its required source cohort; the new neighbor fixture initially omitted explicit SI units and correctly hit the 64-shape admission guard; a PowerShell wildcard passed literally to pytest initially selected no files; one collector command initially used the wrong working directory. Corrected runs pass. These are not product defects. The first benchmark is retained separately from the expanded final benchmark; allocation-instrumented samples are not included in reported timing medians.

No true OOM/device loss, physical UI/mouse/tablet/DPI, all-renderer comparison, prolonged soak, every ordinary scalar Undo/Redo interaction, full multi-Edit copy matrix, clean-machine installer execution or other Max-year runtime was performed. Other supplied scenes were available for future qualification but were not silently counted as tested. The current native/host witnesses do not establish arbitrary topology/material support.

## How to read the bundle

The ZIP contains reports, CSV/JSON evidence, source manifests and reproducible drivers. It excludes binaries, `.max` models/scenes, installed libraries, issuer vectors, grants/requests, local license state and unrelated source diffs. The manifest hashes every included file except itself; the ZIP has a separate SHA-256 receipt. Product sources and the local SDK/toolchain are required to rerun native/host tests. The bundle is evidence and review tooling, not an installer.
