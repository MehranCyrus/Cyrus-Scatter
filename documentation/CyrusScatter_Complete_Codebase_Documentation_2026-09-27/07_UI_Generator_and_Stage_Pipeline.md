# 07 — UI Generator and Stage Pipeline

## Why the generator exists

The original template contains a conventional scripted object/UI. `generate.cjs` restructures it into:
- product branding;
- host/root UI;
- layer manager;
- ten independent layer rollout factories;
- storage/migration;
- explicit PFlow template;
- sequential feature patches.

This avoids manually maintaining a nearly 1 MB generated file.

## Base templates

- `before.ms`: original object, parameters, placement/preview behavior and rollout definitions.
- `strokes.ms`: stroke data/methods.
- `stroke-ui.ms`: line/analyzer stroke UI.
- `host.ms`: root command-panel host.
- `storage.ms`: layer persistence/migration/refresh.
- `containers.ms`: manager/layer containers.
- `pflow.ms`: final-render transport.
- falloff/analyzer/street helper templates.

## Exact feature-stage order

After base generation and PFlow replacement:

1. `spacing.cjs`
2. `centers.cjs`
3. `weights.cjs`
4. `source-transforms.cjs`
5. `overlaps.cjs`
6. `empty.cjs`
7. `point-source.cjs`
8. `radius.cjs`
9. `final.cjs`
10. `radius-display.cjs`
11. `edit.cjs`
12. `orientation.cjs`
13. `edge-border.cjs`
14. `display-modes.cjs`
15. `edge-corners.cjs`
16. `edge-rotation.cjs`
17. `source-refresh.cjs`
18. `boundary-falloff.cjs`
19. `area-falloff.cjs`
20. `whole-scale.cjs`
21. `analyzer-area.cjs`
22. `street-layout.cjs`
23. `activation.cjs`
24. `performance.cjs`
25. `responsive.cjs`

Order is semantically important because later stages search/replace anchors introduced by earlier stages.

## Generator risk model

This is a text-patching pipeline. Many stages deliberately throw when an expected anchor is missing, which is good, but silent replacement mismatches are still possible where no explicit guard exists.

Recommended maintenance rules:
- generated file is never edited directly;
- generator output should be deterministic;
- CI should regenerate and fail if Git diff is unexpected;
- add generator smoke tests for required functions/parameter counts/callback IDs;
- document stage dependencies before reordering;
- rename current `activation.cjs` to `feature-enable.cjs` before commercial activation work.

## Responsive/lazy UI

Later stages scale control widths from the command-panel width and lazily mount child rollouts only when a layer expands. This was introduced to reduce UI overhead in dense scenes.
