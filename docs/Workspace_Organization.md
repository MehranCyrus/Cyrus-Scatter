# Workspace organization and Git backup scope

Updated 2 October 2026, Asia/Tehran.

Git contains the two plugin source trees, shared CMake configuration, build and test tools, documentation, research briefs, supplied research reports and the selected evidence used by those reports. The retained-point probe remains a clearly identified private experiment under `tools/performance/native_point_probe`; it is not a product release.

## Local-only data

The root `.gitignore` excludes SDK/build output, installer packages, native binaries, scene files, renderer proxies, archives and scratch output. A Git clone is a source-and-documentation backup, not a backup of the artist's scene assets or an installable distribution.

`build/`, `dist/` and `Test Scene/` retain their established locations. Build scripts and saved scene/asset paths refer to these directories. Moving them would require a separate path migration and scene relinking, with no benefit to the source backup.

The October 2 cleanup made these changes:

| Previous location | Organized location |
| --- | --- |
| `Boss Handoff - Max 2026/` | `_local/handoffs/Boss Handoff - Max 2026/` |
| `Cyrus Scatter.zip` | `_local/archives/Cyrus Scatter.zip` |
| `tmp/` | `_local/scratch/pdf-preview-work/` |
| `output/pdf/CyrusScatter_Viewport_Performance_Guideline_2026-10-01.pdf` | `docs/exports/CyrusScatter_Viewport_Performance_Guideline_2026-10-01.pdf` |
| `GPT 6 Pro Research Brief/` | `docs/Research_Briefs_2026-10-01/` |
| Supplied reports in Downloads/chat attachments | Byte-identical copies under `docs/Research_Inputs_2026-10-01/`, with an origin/hash index |

The handoff's instructions and comparison script also have source-controlled copies in [Max 2026 handoff documentation](handoffs/max2026/README.md) and `tools/performance/CompareViewport.ms`. Installers and its `.max` demo remain local.

The move journal under `_local/maintenance/2026-10-02-git-cleanup/` records source/destination names and before/after hashes. The original `Test Scene/SaveSelect 2.max` is preserved at its original path with SHA-256 `8a40f6a1a5c47eacbbee92920e131f4cae04cfb0de6be1991b4719ea2860bd2c`.

## Documentation rules

- Start with [docs/README.md](README.md), then the current heavy-scene roadmap. Dated reports retain the claims and limits of their original measurement.
- Keep decisions, accepted results and reproducible small evidence together. Keep large raw runs, rendered preview scratch and binary outputs in the ignored directories.
- Do not rewrite historical measurements, recorded absolute paths, source fingerprints or exact submitted recipes to match a later cleanup. The table above is their location mapping.
- Active source text uses LF line endings across platforms. The dated source-and-evidence packages in `.gitattributes` preserve their original bytes instead; their manifests would be invalidated by automatic newline conversion.
- A single small `before-062.zip` under a viewport report contains five frozen source files for a historical comparison. It is curated source evidence, not a plugin installer or a general project backup.
- Root and plugin READMEs describe current status. Historical release notes remain explicitly marked as historical.

Before future pushes, inspect `git status`, stage source/doc changes intentionally and verify that no SDKs, installers, scene assets or credentials are included. Do not use `git clean -fdx` as workspace housekeeping: it would remove the ignored local scenes, packages and research working files.

## Backup verification — 2 October 2026

All 138 pre-cleanup code-file hashes remained unchanged; the comparison helper was added as an identical source copy from the handoff. Five moves passed before/after file-hash checks, and the original artist scene kept its recorded fingerprint. Nine supplied external research files were copied byte for byte.

The existing Max 2026 and Max 2027 build directories each passed eight Scatter native suites and one Analyzer suite. Fourteen Python report tests passed. The generator reproduced the current script exactly in scratch and again from a clean checkout of the staged Git files. All 475 entries in the five dated evidence manifests matched the staged Git blobs, including archived logs that were previously covered by the general log ignore rule. The retained-point evidence verifier also passed from the clean checkout.

These are backup and regression checks using the existing native builds. This cleanup did not build or install a new product release, run another Max viewport experiment, or integrate the retained-display prototype.
