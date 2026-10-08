# Max 2026 — current compact 0.73 build

7 October 2026. Fresh Release x64 compilation against the Max 2026 SDK, using MSVC 14.38.33130 and Windows SDK 10.0.19041.0. Source baseline: `codex/unified-0.73`, commit `d55dfa88cbeda7af366e4510ac3119a749368958`, with the pre-existing documentation/website worktree changes recorded in the build receipt. No production source changed during this build.

## Delivery

- [Cyrus Scatter 0.73.0 for Max 2026](../../dist/Max2026_0.73_2026-10-07_211656/CyrusScatter-0.73.0-Max2026.mzp)
- [Optional Surface Analyzer 0.14 for Max 2026](../../dist/Max2026_0.73_2026-10-07_211656/CyrusSurfaceAnalyzer-0.14-Max2026.mzp)
- [Installation notes](../../dist/Max2026_0.73_2026-10-07_211656/START_HERE.txt) and [full build/package identities](../../dist/Max2026_0.73_2026-10-07_211656/BUILD.json)

Run the appropriate MZP through **Max 2026 > Scripting > Run Script**, then restart Max. The Scatter package includes the compact UI and latest Add/Copy callback correction. The display label remains 0.73. No installation was performed by this build task.

| Artifact | SHA-256 |
| --- | --- |
| Scatter MZP | `c6ecc24bb75ff554894917d3882f813fa80e8922e180904fa4a1e2a062d57f41` |
| Analyzer MZP | `70901f64ed683216a1ff810b2f963b4bae5c107fca8175eb1f904d503c29748b` |
| Included Scatter script | `9614f6b7d95c0e7c97f9bbe7fa2cb5a770f7a3eca813f7a9f55ea68463d114bf` |

## Fresh checks

- Matching SDK year and x64 target accepted by CMake; all five native modules compiled and linked. No compiler warning diagnostics found in either build log.
- All 14 Scatter native suites and the Analyzer native suite passed.
- Three package-version Python tests passed; current package/native/script version agreement was checked by the packaging function.
- Generator integration passed (240 controls, 22 fixture delimiter checks), as did approved-layout scope/property/lifetime assertions.
- MZP ZIP integrity, complete manifest hashes, included source/native byte equality, x64 PE headers and Max 2026 installer guards passed. Development licensing authority markers were rejected by the standard packager; the experimental native licensing flag was OFF.
- Input hashes matched before and after compilation/packaging. Existing source, scenes and installed profiles were preserved.

Commands used: `tools/procedural_lab/offline_build.py --year 2026 --project scatter` and `--project analyzer`, each with a separate fresh output under `build/Max2026_0.73_2026-10-07_211656/`. Packaging used the existing `tools/build_max.py` package function with those freshly tested modules. Full logs and per-project source receipts accompany the delivery.

An initial diagnostic assertion rejected any mention of 2027 in the installer. Inspection showed a historical registration-cleanup key, while the actual host guard correctly required 28000/Max 2026. The diagnostic was narrowed to the actual guard and target directory; product code was unchanged. Only this run's initial package attempt was replaced.

## Qualification boundary

Max 2026 is not installed on this machine. This is SDK compilation, native-test and package verification, **not** Max 2026 UI, installation, rendering, Undo or performance qualification. The known cold container Undo history issue, Manual/unrelated-Undo qualification target and resource limits in [the current review](../Status_0.73_And_Website_2026-10-07/README.md) remain unchanged. Test saved copies in an isolated Max 2026 profile before artist use.

No normal-profile installation, commit or push occurred. `build/` and `dist/` are ignored; these installers and logs need a separate backup from Git.
