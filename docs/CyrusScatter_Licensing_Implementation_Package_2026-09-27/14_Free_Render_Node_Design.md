# 14 — Free Render-Node Design

## Goal

Studios should not buy one authoring seat per render worker merely to render saved Cyrus Scatter scenes.

## Security boundary

“Render node” is a runtime capability, not a special public license key that unlocks the whole plugin.

## Allowed

- load saved Cyrus objects;
- compute placements required for rendering;
- evaluate saved CS Edit;
- build transient PFlow;
- use source geometry/material data;
- recompute Analyzer only where required for faithful render.

## Denied

- interactive Scatter authoring;
- editing parameters as a licensed workflow;
- CS Edit mutation;
- bake/export;
- license management UI;
- using the render path to obtain unrestricted authoring results.

## Implementation strategy

1. native RuntimeContext classifies trusted render context;
2. authoring bridge requests `AuthorScatter` normally;
3. when trusted restricted render is active, the same bridge requests `RenderExistingScene`;
4. policy allows only the evaluation path;
5. MAXScript cannot grant itself render-worker authority.

## Important unresolved case

Farm tools can use both `3dsmaxcmd.exe` and `3dsmax.exe`. The latter requires runtime experiments to distinguish a real worker from an interactive workstation securely enough for a free-seat policy.

## Acceptance criterion

A scene authored on a licensed workstation must render identically on a clean unlicensed render worker, while opening the same worker interactively must not provide authoring capability.
