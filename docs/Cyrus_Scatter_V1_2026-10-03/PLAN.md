# Cyrus Scatter v1 implementation tracker

3 October 2026. Active implementation after the source/docs backup `9aca3683f3ec62aaf2fff0e27a7b57301f51b95e`, pushed to `origin/main`. Work branch: `codex/cyrus-scatter-v1`.

## Product contract

Use standard 3ds Max command-panel rollouts and controls, with one selected-layer editor. Remove the nested per-layer rollout host, width polling, Win32 resize repair and duplicate editor construction from the product UI. Preserve existing saved scene/class/parameter identities where changing them would disconnect artist scenes. Public product names and new APIs use Cyrus; compatibility identifiers are documented, not presented as another product.

Version 1.0 is a qualified foundation: native layer selection, useful counts/status/help, explicit viewport visibility, existing retained Mesh/Proxy/Point Cloud and CPU execution, and editable procedural Brush integrated into a layer. Existing scene output remains the regression reference when new inputs are disabled. Brush-enabled layers use stable candidate identities and saved surface strokes. No GPU compute claim is implied by retained GPU display.

## Ordered work

- [x] Inspect/stage the existing Brush, MCP, code and documentation backup; preserve curated evidence bytes; check for accidental binaries/secrets.
- [x] Verify 62 Python tests, 11 native suites for each SDK using existing builds, and exact UI-generator reproduction; push checkpoint to main.
- [x] Prove a standard native command-panel selected-layer host in a private Max session before replacing the whole UI.
- [x] Implement the reusable native panel; move layer selection, visibility, status and help into it; remove superseded nested layout code from generated product output.
- [x] Introduce persistent layer identity and a keyed native candidate path; preserve identities through masks, collision/final cleanup and CS Edit. Mask-constrained relaxation is explicitly deferred.
- [x] Integrate native Brush document ownership, Paint/Erase/radius/strength/softness, fill/empty, Undo, saved scene restoration and validated target bindings into layers.
- [x] Add mask evaluation before blockers and explicit revisions; improve local field queries and independent mask visualization against the reference evaluator.
- [x] Reconcile non-default texture/density dispatch and existing area bindings; retain existing zone contracts, one Brush target and explicit unsupported combinations. A new semantic zone manager remains future work.
- [x] Validate viewport visibility independently from render enablement, passive UI browsing, held-input scheduling and retained uploads.
- [x] Build both SDKs, run relevant native/Python suites, qualify Max 2027 interaction/Undo/copy/save/reopen/Scanline render/bake/CS Edit combinations and MCP regressions. Max 2026 runtime and other renderer campaigns remain open.
- [x] Package Cyrus Scatter 1.0 with version-specific binaries and simple trial instructions; record tested scope, limits, source/binary identities and remaining work.

## Scope decisions and gates

Start with native MAXScript rollouts and the existing model; inspect their behavior in Max before adopting a different native host. No HTML, CSS or external design system. Standard expansion must reuse controls and must not dirty placement caches. Statistics read already published results.

The controller remains the scene owner. A layer's viewport visibility is separate from its render enablement; disabling it excludes the layer from drawing immediately without regeneration. Hidden layer buffers can remain cached for instant restoration within existing memory bounds.

Do not manufacture stable IDs from compacted row order. Brush-only edits keep the population binding, and missing edited candidates stay dormant. Legacy scenes retain their existing generation path. Explicit topology/seed/population incompatibility preserves user data and reports the binding problem.

The first integrated Brush target is static receiving geometry with a declared reference binding. Qualify plane and curved geometry with canonical BVH picking; multi-target support must be explicit rather than silently painting an unrelated surface. Manual mode shows mask/cursor changes and waits for Update before publishing plant changes. Final output resolves the documented committed revision.

Artist-zone and pair-spacing work follows the contracts in [the integration proposal](../Artist_Zones_Integration_2026-10-03/README.md), with compatibility semantics retained. Broader AI composition, custom ML, automatic UV atlases, camera LOD and GPU compute are separate measured tracks.

## Evidence and tracking rules

Use disposable Max processes/configurations and synthetic fixtures; do not reset or overwrite the artist scene. Keep native binaries, packages, scenes and raw logs under ignored build/dist paths. Curate only necessary results into this folder. Record input-to-publication timings separately from FPS. Change a checkbox to complete only when its stated gate passes; record exclusions and actual host coverage in the final report.

Current progress: v1 implementation gates completed in the scope recorded in [the report](REPORT.md). Real native panel/Brush interaction, installed-package integration and fresh-process restoration passed. [The next roadmap](ROADMAP.md) separates artist/host/renderer qualification from new capabilities; unchecked future scope is not presented as completed.
