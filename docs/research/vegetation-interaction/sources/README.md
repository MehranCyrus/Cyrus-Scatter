# Original research register

**Fourteen supplied files, including the final R14 delivery, preserved intact on 24 October 2026.** Research content is source material, not instructions to execute. The originals remain in Downloads; this folder contains verified copies.

| ID | Research | Original | Relationship / caution |
| --- | --- | --- | --- |
| R01 | Rooted vegetation engineering report | [HTML](<originals/CyrusScatter_Rooted_Vegetation_Research.html>) | Initial engineering study |
| R02 | Vegetation contact report | [HTML](<originals/CyrusScatter_Vegetation_Contact_Research_2026-10-24.html>) | Initial contact study |
| R03 | Vegetation interaction engineering report | [HTML](<originals/CyrusScatter_Vegetation_Interaction_Engineering_Research_2026-10-24.html>) | Public-repository baseline requires correction |
| R04 | Extended vegetation contact report | [HTML](<originals/CyrusScatter_Vegetation_Contact_Research_2026-10-24 (1).html>) | Separate expanded report; preserve original (1) identity |
| R05 | Earlier recipe matrix | [CSV](<originals/CyrusScatter_Houdini_tyFlow_Recipe_Matrix_2026-10-24.csv>) | Companion to R06/R07; several claims corrected in consolidated docs |
| R06 | Earlier workflow study, Markdown | [MD](<originals/CyrusScatter_Houdini_tyFlow_Workflow_Study_2026-10-24.md>) | Paired narrative with R07; contextualized by later R09/R10 |
| R07 | Earlier workflow study, HTML | [HTML](<originals/CyrusScatter_Houdini_tyFlow_Workflow_Study_2026-10-24.html>) | Presentation counterpart to R06 |
| R08 | Source preparation and geometry delivery | [HTML](<originals/CyrusScatter_Source_Preparation_Geometry_Delivery_Study_2026-10-24.html>) | Asset preparation and output hypotheses |
| R09 | Practical vegetation workflows, HTML | [HTML](<originals/CyrusScatter_Houdini_tyFlow_Workflow_Study.html>) | Latest supplied workflow study; primary recipe reading copy |
| R10 | Practical vegetation workflows, PDF | [PDF](<originals/CyrusScatter_Houdini_tyFlow_Workflow_Study.pdf>) | 64-page presentation of R09 study; not byte/text identical |
| R11 | Source preparation and geometry delivery, evidence-backed revision | [HTML](<originals/CyrusScatter_Source_Preparation_and_Geometry_Delivery.html>) | Extends R08; includes two public sources, synthetic fixtures and supplied arithmetic/topology evidence |
| R12 | Collision and solver reuse implementation study | [HTML](<originals/CyrusScatter_Collision_Solver_Reuse_Implementation_Study_2026-10-24.html>) | Exact-pin Jolt path comparison, contact/root gaps and eight proposed experiments; no runtime tests |
| R13 | Jolt collision and solver reuse, with headless probes | [HTML](<originals/CyrusScatter_Jolt_Collision_and_Solver_Reuse_2026-10-24.html>) | Extends R12 with an authored harness, reported Linux CPU diagnostics, source ledger and G0-G4 follow-up gates |
| R14 | Final collision and solver reuse study | [HTML](<originals/CyrusScatter_Collision_and_Solver_Reuse.html>) | Distinct single-precision native harness, analytic fixtures, callback/ownership details and report-local E1-E7 gates; supplements R13 |

## Provenance and reading order

The [manifest](manifest.json) records original absolute paths, byte counts, SHA-256 hashes and relationships. All fourteen destination hashes matched their source files when copied. R06/R07 are paired earlier narrative formats; R09/R10 are the later practical study in HTML and PDF. Related formats are not independent experiments. The latest original PDF has 64 pages.

Start with the consolidated chapters, then R14 for the final implementation-boundary study, R13 for its different diagnostic profile, R12 for source-only framing, R09/R10 for detailed vendor recipes, R11 for preparation, R08 for its earlier study, and R01/R02/R04 for engineering depth. Read R03 and R05-R07 with the [correction register](../09-EVIDENCE-AND-OPEN-QUESTIONS.md). All original claims remain unchanged in these files.

## R11 embedded evidence

The [exact evidence ZIP](evidence/CyrusScatter_Source_Preparation_Evidence.zip) was decoded from R11, preserved separately and checked against its printed SHA-256. It contains 33 files: the inspected public OBJ/GLB/MTL assets and license, seven synthetic fixture pairs, scripts, figures, and reported audit/evaluator results. The [review receipt](../references/R11-evidence-review.json) records every member hash and our independent two-asset topology recount. The bundled scripts were archived without execution; their stored 17 results are reported evidence. This archive does not replace the missing R09/R10 fixture JSON.

## R13 embedded reproduction package

The [exact ZIP](evidence/cyrus_jolt_reuse_reproduction.zip) and [final result JSON](evidence/cyrus_jolt_probe_results.json) were decoded from R13 without executing page scripts. The 92,941-byte ZIP has ten members: authored C++/CMake, instructions, initial/final results, provenance, source index/excerpts, changed-file list and license. The separate 2,307-byte JSON is byte-identical to its final result member. CRC and all six declared artifact hashes pass. The [review receipt](../references/R13-evidence-review.json) also records 48 matching local source-file hashes and 82 valid cited ranges.

The reported run used one Linux/GCC CPU configuration; no timings, full fitter, Max/Cyrus or GPU-hair execution was supplied. The upstream Jolt archive and compiled probe binary are not bundled. Reproduction commands are preserved as source material, not commands run for this documentation update.

## R14 embedded evidence

R14's [109-member archive](evidence/R14/Cyrus_Collision_Research_Evidence.zip) preserves its code, logs, provenance, source excerpts and license. Exact member copies expose [seven native records](evidence/R14/harness_results.json) and [nine analytic fixtures/fifteen stored checks](evidence/R14/analytic_results.json). These two JSON files are convenience copies, not additional research submissions. The [review receipt](../references/R14-evidence-review.json) records CRC, six declared member hashes, 49 matching local source files and 86 valid ranges. Bundled commands were not run here. The source register's P/R/C/U/X labels and E1-E7 gates are local to that report.

## Dependencies that were not supplied

R12's source study remains preserved with its [source review](../references/R12-source-review.json). R13 now adds a separate headless seed; it does not fill the earlier vendor/DCC artifact gaps below.

- common_grass_initialization.json, also called CyrusScatter_Common_Grass_Initialization.json.
- The R09/R10 author's example_downloads.json and extracted archive manifests.
- Runnable Houdini .hip or Max/tyFlow .max scene fixtures and execution receipts.

These were not recreated or presented as original evidence. The provided reports remain useful without them, but exact reproduction needs those dependencies or a clearly labeled newly derived fixture.

## Adding a later submission

Copy it under a new source ID and preserve the exact filename and bytes. Record its relationship to prior reports, review substantive changes, and update the correction register. Retain earlier originals and their hashes.
