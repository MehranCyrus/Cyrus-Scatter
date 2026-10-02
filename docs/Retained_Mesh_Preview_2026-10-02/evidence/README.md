# Accepted Mesh evidence

Curated from isolated `run02`. The report explains the measurement limits. `run01` artist timings are rejected and are not included.

- `analysis.json`, timing CSVs and trial/metadata JSON: raw scripted redraw evidence.
- `images/`: original, unedited captures, including legacy/retained pairs and the 61.7M-triangle stress view.
- Runtime receipt JSON: lifecycle, transform, Point regression and deliberate memory-limit tests.
- `identity.json`, `ready.json`, `packages.json`: tested files, loaded module paths and package identities.
- `environment.json`, `protection.json`: hardware/version and post-test scene/process checks.
- `build-max*/`: incremental build, CTest summary and per-suite logs. Both SDK builds passed nine suites.
- `executed-recipes/`: copies submitted to Max; two memory recipes show the initial process-cap probe and the expanded final test. `mesh-memory.json` is the final expanded test's receipt.
- `harness/`: frozen helper/recipe versions for audit. Use the active repository harness to reproduce, not these copies: their imports and paths expect the repository layout.
- `source-hashes.json`: completion-time production/generator fingerprints. The working tree includes pre-existing work; its base Git commit alone does not identify this candidate.

`manifest.json` hashes every other file here. No scene, mesh asset, native DLL or SDK file is included. Paths and process IDs describe this local test machine, not portable installation instructions.
