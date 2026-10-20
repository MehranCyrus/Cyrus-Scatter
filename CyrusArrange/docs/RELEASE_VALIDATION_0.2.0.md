# Cyrus Arrange 0.2.0 validation

**Qualified for the documented Max 2027 workflow.** The unchanged [MZP](../dist/CyrusArrange-0.2.0/CyrusArrange-0.2.0-Max2027.mzp) passed actual isolated installation and fresh automatic startup: install: SUCCESS passes=43 failures=0; startup: SUCCESS passes=13 failures=0. The [external qualification receipt](../dist/CyrusArrange-0.2.0/qualification-receipt.json) binds the exact archive and native/script pair.

Archive SHA-256: `d6da6661544b412b904912f3b7f3dea67f42579f59d0c63758b3022dd26c4339`. No artist installation was performed.

## User-visible result

The main window follows choose furniture, add Props, Generate. Selecting real furniture or generated output can resolve an existing native arrangement; ambiguous matches require choosing one. Generate chooses a fresh nonnegative 63-bit seed by default. Keep seed repeats its supplied seed. A native staged command publishes settings, seed and output together, with one Undo/Redo transaction and failure retention. Advanced retains the detailed controls.

Untouched main fields preserve exact current native settings, including values rounded by float controls. Explicit main drafts take precedence for that command and survive prop addition and same-owner Advanced refresh. Main Generate covers all eligible regions; selective generation remains Advanced. Opening/selecting only discovers actual references and never solves. Stale Props windows cannot change a previous owner.

## Exact acceptance

Pinned full Max 2027 SDK build `build/native-arrange-020-02/receipt.json` passes **12 CTest executables / 117 native cases**. All **17 serial functional Max suites pass 3,119 assertions / 0 failures**, including **85 new main-workflow assertions**. All host runs use the same **127-input source map**, actual loaded two-module pair, hidden owned process, private INI and unchanged watched artist profiles. Five inspector exports pass independent JSON validation. The Python validator suite passes **36 / 36**, with retained log and exact source map in `build/python-validator-020-01/receipt.json`.

| Functional scope | Passed / failed | Exact receipt |
| --- | ---: | --- |
| simple-workflow | 85 / 0 | `build/host-final-020-02-simple-workflow/receipt.json` |
| inspect | 69 / 0 | `build/host-final-020-02-inspect/receipt.json` |
| native | 21 / 0 | `build/host-final-020-02-native/receipt.json` |
| workflow | 162 / 0 | `build/host-final-020-02-workflow/receipt.json` |
| lifecycle | 89 / 0 | `build/host-final-020-02-lifecycle/receipt.json` |
| preview | 38 / 0 | `build/host-final-020-02-preview/receipt.json` |
| regions | 83 / 0 | `build/host-final-020-02-regions/receipt.json` |
| obstacles | 78 / 0 | `build/host-final-020-02-obstacles/receipt.json` |
| visual | 156 / 0 | `build/host-final-020-02-visual/receipt.json` |
| library-validation | 6 / 0 | `build/host-final-020-02-library-validation/receipt.json` |
| cache | 685 / 0 | `build/host-final-020-02-cache/receipt.json` |
| cache-atomic | 233 / 0 | `build/host-final-020-02-cache-atomic/receipt.json` |
| cache-boundaries | 1182 / 0 | `build/host-final-020-02-cache-boundaries/receipt.json` |
| gallery | 49 / 0 | `build/host-final-020-02-gallery/receipt.json` |
| composition | 52 / 0 | `build/host-final-020-02-composition/receipt.json` |
| composition-lifecycle | 71 / 0 | `build/host-final-020-02-composition-lifecycle/receipt.json` |
| migration | 60 / 0 | `build/host-final-020-02-migration/receipt.json` |

The new suite uses actual Main and Props handlers: binding/ambiguity, fresh and exact Integer64 seeds, Advanced merging, precise untouched values, drafts, invalid settings/missing sources, actual node handles across Undo/Redo, keep/release, stale-owner rejection and save/reopen. Existing detailed-window suites target Advanced and retain their previous assertions.

## Additional saved-example replay

`build/host-020-example-replay-01/receipt.json` passes **52 / 0** separately from the seventeen-suite total. It copies the unchanged 0.1.3 book-row scene into the owned run, discovers actual TV/shelf furniture bindings, repeats saved seeds and ordered rows, measures full-size book bounds/support contacts, chooses new variations and saves/reopens a separate working file. Logical records remain exact except an explicitly witnessed otherwise-identical yaw differing by one full revolution; physical checks use separate stated tolerances. The original scene and manifest hashes remain unchanged.

The [ready-to-open scene](../examples/simple-0.2.0/CyrusArrange-Simple-Workflow.max) and its [guide/manifest](../examples/simple-0.2.0/README.md) derive from that working save. TV and shelf use the existing individually registered book assets; the guide explains adding other props.

## Identity and packaging

| Item | SHA-256 |
| --- | --- |
| CyrusArrange.dlx | `b8500d1144417f60a20f4b7ece6e85d223c63789c9986fda7be441ed8a85eea2` |
| CyrusArrangeStorage.dlh | `7fcf6c553193c6e911e023e3ada9c612c24e3871aab113c78f97dd6846f27d79` |
| Build receipt | `37c14d785e159787efcfc5e3d31474ccb44bd083a6f87d1e2a406198a41cc046` |
| Seventeen-suite summary | `0f6c6e8620554edfbcae02bb8c28060378eedd7bd27598e2b33c972fd3bc2981` |

Version 0.2.0 is independently versioned from the other Cyrus products. Document format 4 (including released format 3 reads), library 2, registry 1, class IDs and five installed script filenames are unchanged. Prior 0.1.3 archives, receipts and original examples remain immutable. Keep seed defaults off when Main reopens; the successful seed is saved in the existing native arrangement settings.

Build prerequisites are MSVC 14.38.33130, Windows SDK 10.0.19041.0 and the separately licensed Max 2027 SDK. The source archive contains owned source, current docs/examples and selected evidence metadata. It excludes purchased vendor payloads, decoded vendor code, Autodesk SDK, PDBs and crash dumps. CRC, member bytes and hashes are verified. The final external receipts identify exact source and package evidence.

## Research and limits

The [exact purchased Scatter Tools source review](research/SPLINE_DYNAMICS_LOCAL_RESEARCH_2026-10-18.md) informs the compact workflow. No vendor code was executed or copied into Cyrus. The three [YouTube references](research/UX_REFERENCE_VIDEOS_2026-10-18.md) could not be fully played/transcribed; actual video coverage is zero seconds. Verified metadata, official docs/static images and supplied local source are distinct evidence.

Fresh seeds cannot guarantee visibly different placement on a constrained or fully kept setup. Amount is a density target. Sampled supports and conservative upright bounds may underfill or reject tight fits. Furniture/prop categories, book spines and labels remain authored metadata. Physics, leaning objects and automatic semantic/aesthetic understanding are outside this delivery.

No new performance benchmark or rendered-image campaign was run for 0.2.0. Native geometry/placement algorithms are retained and their functional suites rerun; [0.1.3 performance/render results](RELEASE_VALIDATION_0.1.3.md) remain historical evidence for their exact pair. Neither campaign establishes zero defects for every model or renderer.

The earlier test-only comparison failure is retained in `build/host-020-simple-01`: after lock/release, yaw 270 and yaw -90 represented the same physical pose. The final suite canonicalizes with Keep-seed Generate before strict save/reopen comparison instead of relaxing equality. All 17 final tests pass against the final frozen source map.

No CUA/computer use, artist installation, artist-session commands or restarts were performed. Qualification runs only hidden disposable Max 2027 processes and preserves watched artist files.
