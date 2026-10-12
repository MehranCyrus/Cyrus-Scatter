# Guide hero layer study — 11 October 2026

The accepted circular garden is integrated into the real React `#/guide` overview alongside “Plant with intention.” The latest user-requested refinement removes individual layer selectors, isolate and reset controls. Only **Garden**, **Layers** and **Build up** remain in the top toolbar.

## Current behavior

- Layers opens with four closely spaced illustrative planes. Garden shows their combined composition. Labels align in a separate right-hand column; pointer lines terminate before the vertically centered text, outside the plane edges.
- Plane spacing is 118 drawing units, reduced from 166. The SVG height is 680 units, reduced from 920; no botanical symbols were rescaled.
- Build up adds Ground cover, Meadow, Shrubs and Trees in sequence. Stop restores the complete composition and clears pending timers. Route teardown also clears timers.
- Both views and playback retain the same 324 deterministic plant IDs and world positions. Separation changes their projection, not the planting recipe.
- Controls use React state, keyboard-accessible buttons and scoped CSS. SVG definitions have per-component IDs.

The supplied botanical style remains. This is labeled explanatory planting, not a plugin result. The separated planes are a teaching illustration, not a claim that Scatter physically elevates its layers.

## Current evidence

`npm run build` passed, including strict TypeScript compilation. The later label-alignment refinement was also rebuilt and inspected at 1440 and 390 pixels. All four mobile labels were within the SVG bounds and clear of their pointer lines; no browser errors were reported. Screenshots and the preceding artwork source are in `build/website-layer-labels-20261011/`. The 12-check compact-layout receipt below predates this label-only adjustment.

The compact refinement passed **12 focused headless checks** in `build/website-layer-compact-20261011/checks.json`; the reproducible `review.py`, CLI logs and inspected desktop/mobile screenshots are alongside it:

- Garden and Layers at 320, 390, 1440 and 1920 pixels: no page overflow, exactly three toolbar buttons, all 324 plants present and contained within the SVG.
- Switching views preserves plant IDs and world coordinates. Build up restores the same plants; stopping cancels pending timers and restores all planting.
- No browser runtime errors. The layer panel measures approximately 504 pixels high at a 1440-pixel viewport.

The original integration's 25-check receipt remains historical in `build/website-layer-integration-20261011/`. Its removed visibility/isolate/reset controls and earlier screenshots do not describe the current toolbar. The preceding written record is preserved in the compact run folder.

`tools/check_selected_interactions.py` now targets the four plane labels within the artwork. Its full site-wide suite was not rerun for this focused visual change. Product source documentation was not re-imported or requalified.

This is website-only evidence, not qualification of native Scatter, Max input, rendering or plugin performance. No product source, scenes, installed profiles or supplied design archives were changed. No Git push or deployment was performed. User visual acceptance remains pending.

## Files

- `src/components/PlantingLayerStudy.tsx`: simplified React controls and lifecycle.
- `src/components/planting-layer-art.ts`: deterministic garden and compact layer projection.
- `src/components/planting-layer-study.css`: simplified scoped toolbar and layout.

The standalone `mockups/planting-layer-study.html` remains the earlier design reference, not the active application entry point.
