# Cyrus Arrange 0.3.0 validation

Status: **qualified for the documented Max 2027 workflow**, including the exact
runtime pair, immutable MZP installation and automatic startup. The preserved
0.2.0 artifacts remain unchanged. The MZP contains the earlier, explicitly
installer-pending documentation snapshot; this maintained report and external
receipts record subsequent qualification without modifying that tested archive.

## Change and architecture

This additive release implements the [video review](research/UX_VIDEO_PLAYBACK_REVIEW_2026-10-18.md)
through a simpler main window, native bulk prop intake and copied reusable decor
groups. The [workflow decisions](WORKFLOW_IMPROVEMENTS_0.3.0.md) record scope,
ownership, invalidation, admission and Undo behavior. The [artist guide](SIMPLE_WORKFLOW.md)
and [native API](ARRANGEMENT_API.md) explain operation and limitations.

Native code stages a complete catalog successor and publishes it once. Group
creation validates and copies the source hierarchy, preserving originals, before
registering one grouped source. One Undo restores the command. Group placement
uses the existing canonical geometry/material path and full fit checks. There is
no placement-sized MAXScript computation or post-fit random transform pass.

Document 4, library 2, region registry 1, class IDs and the placement engine remain
unchanged. Generate uses a fresh seed by default; Repeat seed exposes the exact
saved seed. Bulk source registration is idempotent by actual node identity.

## Qualification results

Clean final SDK build: `build/native-arrange-030-02/receipt.json`; all **12 native executables passed**. The final Python validator run passed **36/36**. Frozen runtime/fixture/tool inputs: **128**. Actual host: Max 2027.1 / 29.1.0.11426.

| Native module | SHA-256 |
| --- | --- |
| CyrusArrange.dlx | `359ea71784cf8beb37c0c2d82f657c5c62d7d961381d5d9e415ac375f66dd7bb` |
| CyrusArrangeStorage.dlh | `18294f0de671291c1f7135b5af29b5b3118dfc843b6f347dab47517b291be685` |

The [collected campaign receipt](../build/final-030-02-serial/receipt.json) verifies **18 host suites / 3,238 checks**, all actual loaded module paths, unchanged binaries, private INI paths and artist-profile preservation. Three independent cohorts ran concurrently and each serialized its own Max processes. The new bulk suite ran first. These are correctness runs, not controlled performance comparisons.

| Max suite | Passed |
| --- | ---: |
| arrange_bulk_workflow_tests.ms | 119 |
| arrange_simple_workflow_tests.ms | 85 |
| arrange_workflow_tests.ms | 162 |
| arrange_lifecycle_tests.ms | 89 |
| arrange_preview_tests.ms | 38 |
| arrange_regions_tests.ms | 83 |
| arrange_obstacles_tests.ms | 78 |
| arrange_native_tests.ms | 21 |
| arrange_cache_tests.ms | 685 |
| arrange_cache_atomic_tests.ms | 233 |
| arrange_cache_boundaries_tests.ms | 1182 |
| arrange_library_validation_tests.ms | 6 |
| inspect_tests.ms | 69 |
| arrange_visual_tests.ms | 156 |
| arrange_gallery_tests.ms | 49 |
| arrange_composition_tests.ms | 52 |
| arrange_composition_lifecycle_tests.ms | 71 |
| arrange_migration_tests.ms | 60 |

Independent inspector verification passed all **five JSON exports**. The separate [capacity host](../build/host-030-capacity-01/receipt.json) passed **13/13** checks: positive 256-source intake, 512-selection deduplication, one-step Undo/Redo after a no-op, 257th-entry rejection, exact original transforms, two full catalogs sharing their actual sources, and save/reopen. Its exact fixture and launcher are under `build/ux-030-delivery/qa`; the original runtime/tool inputs were unchanged. One 256-entry intake measured 61.9046 ms in this concurrent correctness run; it is not a controlled benchmark.

The [new color-coded TV/shelf example](../examples/simple-0.3.0/README.md) is the unchanged accepted scene saved by the 119-check bulk suite. Its manifest binds the exact scene, test, source build and native hashes. The [detailed earlier example](../examples/simple-0.2.0/README.md) remains available.

### Installer and delivery

The exact candidate and all five current UI scripts passed **43 installer checks** and **13 automatic-startup checks** in two private Max 2027 processes, both exiting normally. The second process discovered the installed startup itself; it loaded the matching native pair from the private installed directory. Archive/source identity and artist-profile preservation passed. No normal artist installation or existing-session command was performed.

- [Qualified installer](../dist/CyrusArrange-0.3.0/CyrusArrange-0.3.0-Max2027.mzp), SHA-256 `2db46739fe867c56f802ddc50e58266d4beedd8cb8ec46cd8d08d0838140b2ef`.
- [External qualification receipt](../dist/CyrusArrange-0.3.0/qualification-receipt.json) and [private installer/startup receipt](../build/installer-final-030-02/receipt.json).
- [Matching source and examples](../dist/CyrusArrange-0.3.0/CyrusArrange-0.3.0-Source-and-Examples.zip), with a member/hash manifest and documented differences from the MZP documentation snapshot.
- [Independent code/runtime review](../build/ux-030-delivery/INDEPENDENT_REVIEW.md). Its installer-pending statement records the earlier audit time; [package review](../build/ux-030-delivery/PACKAGE_REVIEW.md) records the subsequent archive/installer audit.

Run the installer with **Scripting → Run Script**, then restart Max 2027. Open Cyrus Arrange from the existing toolbar action. The normal artist profile was deliberately left for the user to install.

## Boundaries

The first bulk iteration recorded 114 passes and three failing test comparisons.
The successor kept the same literal bounds and 0.02 mm geometry tolerance and
strengthened its exact-seed checks. Actual diagnostics establish that Max's group
head bounds describe its tiny helper, while copied renderable leaves retain
`[4470,-20,0]..[4600,20,55]`. The previous test's unsuffixed decimal string cast to
Integer64 overflowed to `-9223372036854775808L`; native storage, the UI parser,
typed literal and independent maximum-minus-807 all equal
`9223372036854775000L`. No product change resolved these test-oracle defects.
The corrected successor passed 119 checks. Both iterations remain preserved.

Optional offscreen batch-window captures were uniform gray when inspected and
are excluded from visual/DPI evidence. Functional handlers and control properties
are tested in Max; static control bounds were checked separately. The SDK window
capture API is documented in Autodesk's [Windows structure reference](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/Interaction-With-The-Operating/GUID-282F32AC-5A80-4FDB-B8C0-275D2CC15845.html),
but availability of that API does not establish usable pixels in this batch host.

Groups preserve authored relative positions; they do not assemble widely separated
parts automatically. One generated group placement is one evaluated flattened
mesh. Scene sources supply materials; portable geometry libraries remain geometry
and metadata only. Conservative upright bounds and sampled support may underfill.
This scope does not qualify arbitrary third-party renderers or universal aesthetic
quality. Actual normal-profile DPI and artist input remain separate from automated
button and owned-window captures. No universal zero-defect claim is made.
