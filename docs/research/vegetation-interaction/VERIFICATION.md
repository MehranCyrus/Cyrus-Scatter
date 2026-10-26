# Documentation verification receipt

**24 October 2026 | Documentation package only**

This receipt records the integrity and presentation checks for the organized research library. It does not qualify vegetation fitting, a solver, a renderer or a plugin build. The implementation/host [validation matrix](checklists/VALIDATION-MATRIX.md) remains Pending.

## Inputs and review

Fourteen user-supplied originals, through the final R14 delivery, were copied intact from Downloads. Their byte counts, SHA-256 hashes, paths and relationships are in the [manifest](sources/manifest.json). R09's practical workflow study was read in full; its paired R10 PDF has 64 pages. Its text was compared with the HTML and representative pages were visually inspected. They represent the same practical study with presentation/text differences, not identical or independent reports.

The new R11 Source Preparation and Geometry Delivery HTML was read in full. Its embedded 73,202-byte evidence ZIP was decoded without executing page scripts, preserved separately, verified against its printed SHA-256 and CRC-checked. The supplied seven topology and ten evaluator result records were inspected. An independent standard-library recount of its two OBJ/GLB assets confirmed vertex/triangle/component counts and opposite-winding pairs. The bundled scripts were not executed and their 17 stored results are not presented as independently repeated tests. [R11 review details](references/R11-evidence-review.json).

Earlier supplied studies and the recipe matrix were incorporated using their review findings from this conversation. Corrections and unresolved claims are consolidated in [Chapter 09](09-EVIDENCE-AND-OPEN-QUESTIONS.md). Primary-source checks cover the consequential static/quasistatic, wire-deformation, solver-role, version and collision-shape distinctions; this is not a fresh audit of every bibliography entry in all originals.

R12's Collision and Solver Reuse study was read in full. Its original copy is 102,065 bytes and matches the Downloads SHA-256. Eleven local dependency files were compared with public files at Jolt commit 1b2e77e3c6c09709e5edc79dc208459b8ff32051; all match after line-ending normalization. We inspected relevant bare-rod contact, inverse-mass, triangle-helper and error-bit code, plus the separate soft-body-face CCD path and local Lab pin/limits. The [source review](references/R12-source-review.json) records the exact file scope. No dependency build, runtime fixture, timing, cancellation or renderer experiment was performed. Its eight decision experiments remain Pending.

R13's Jolt Collision and Solver Reuse HTML was read in full, including the authored harness, provenance, initial/follow-up result records and source ledger. Its 580,451-byte original is preserved by hash. Both embedded downloads were decoded as data: a 92,941-byte ten-member reproduction ZIP and a 2,307-byte result JSON. ZIP CRC, all six declared artifact hashes and equality of the separate JSON/final archive member pass. All 48 cited file hashes agree with the local dependency after line-ending normalization; all 82 cited ranges exist. Relevant point-parity, query-sign and canonical-reset originals were also inspected directly. [R13 evidence review](references/R13-evidence-review.json).

R13 reports one Linux/GCC headless build and execution, without performance measurements, GPU hair, a full fitter or a host adapter. We did not run its commands, rebuild Jolt, reproduce those simulations or independently repeat its tag/archive comparison. Its supplied results remain attributed evidence.

R14's final Collision and Solver Reuse HTML was read in full, including 17 sections and the 94-entry source register. Its 724,160-byte original is preserved by hash. The embedded 362,872-byte ZIP contains 109 files and passes CRC; six artifact hashes declared by its provenance agree. We inspected its native harness, analytic oracles, stored outputs, build recipe/logs, provenance and reproduction wrapper as data. All 49 cited local source-file hashes agree after line-ending normalization, and 86 cited ranges are valid. Critical rigid/soft callback, multiple-world service and no-scalp sample originals were inspected directly. [R14 evidence review](references/R14-evidence-review.json).

R14's native and analytic JSON are preserved both in the ZIP and as exact convenience member copies. Seven native records/five dynamic rod runs and nine analytic fixtures/fifteen stored checks are reported evidence, not executions repeated here. The single-precision/SSE2/assert profile remains distinct from R13's double/AVX profile. The saved comparison metadata lists 78 changed files overall, 47 under Jolt; that scope difference was checked within the supplied data, without repeating the remote tag comparison. No bundled script, engine build, Max/renderer test or performance benchmark was run. All 68 Cyrus validation cases and all eight decision experiments remain Pending.

R09/R10's companion grass initialization JSON and reported example manifests were not supplied. R11's source-preparation archive is a separate artifact and does not fill that gap. No original fixture was reconstructed or claimed to have been executed in Max.

## Package checks

The [machine-readable receipt](references/package-verification.json) records current counts, hashes and integrity checks. The verifier checks preserved original and associated artifact hashes, ZIP CRC, R13/R14's declared member hashes/result agreement, owned Markdown/local HTML navigation, chapter/source/case/experiment counts and PDF heading coverage. The earlier 31-, 36-, 44- and 49-page editions retain historical visual reviews. The current edition's page count, rendered-page review and exact PDF hash are recorded in [visual-review.json](references/visual-review.json). Package integrity is separate from visual inspection and from every pending implementation test.

The handbook is generated from the numbered Markdown plus checklist/source/reference appendices. The HTML also includes the main document index. JSON templates, exact source hashes and original reports remain accompanying files rather than independently edited handbook text.

## Rebuild and verify

Use Python with ReportLab and pypdf; the desktop bundled runtime supplies them on this machine. The builder also requires Calibri fonts for PDF. The HTML build uses Python's standard library. From this folder:

1. Edit the canonical Markdown and preserve any new original under a new source ID.
2. Run `python tools/build_handbook.py --pdf` with the configured runtime.
3. Run `python tools/verify_library.py`.
4. Render the PDF with Poppler and inspect the changed pages before sharing.

The renderer/builder support files are local documentation utilities. No host application is required for these package checks.

## Repository and knowledge limits

The [source snapshot](references/repository-snapshot.json) identifies inspected local files in the existing dirty working tree on branch codex/workflow-0.75 at HEAD 588abff0ce211d7dc63798b8c5310631895465c7. That HEAD does not identify all working-tree content. Unrelated changes were preserved.

The knowledge service returned stale evidence after source verification was requested. Direct source was used for baseline claims; no corpus rebuild or activation occurred. The only maintained navigation change is a link in the main docs index.

No plugin source or product version was changed, no host tests or new simulations were run, and no commit, push, install or publication was performed for this documentation task.
