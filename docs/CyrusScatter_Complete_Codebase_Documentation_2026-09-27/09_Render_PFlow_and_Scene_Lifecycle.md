# 09 — Render, PFlow, and Scene Lifecycle

## Final-render transport

The production renderer bridge is MAXScript/PFlow, not a renderer-native procedural instancer.

`CyrusPFBuild()`:
1. clears prior transient state;
2. scans Cyrus Scatter owners;
3. iterates layers, including disabled ones for baked-node suppression bookkeeping;
4. computes current placements for enabled auto-render layers;
5. groups transforms by source;
6. optionally resolves a Corona proxy copy for viewport-mesh access;
7. creates `PF_Source`;
8. adds RenderParticles, Birth, Shape_Instance, Material_Static and Script_Operator;
9. stores transform arrays in global `CyrusPFData`;
10. tags newly created nodes with `CyrusPFTransient`;
11. forces particle update and verifies observed particle count equals expected.

## PFlow script operator

The generated operator reads the transform array, writes `particleTM`, and separately sets `particleScaleXYZ` from matrix row lengths.

## Render callbacks

- `#preRender` → `AminScatterRenderBegin()`
- `#postRender` → `AminScatterRenderEnd()`
- `#systemPreReset` / `#filePreOpen` → clear transient PFlow
- `#filePreSave` → stop/clear transient state before save

Callback IDs:
- `#AminScatterAutoRender`
- `#CyrusPFBridge`

## Baked nodes

Existing baked nodes are temporarily made non-renderable while auto-render PFlow is active, then their original renderable flags are restored.

## Corona IR support

The script detects Corona interactive render type, uses a 750 ms timer, waits for an input signature to remain stable for about one second, stops/rebuilds/restarts IR as needed.

The repository's own historical README explicitly says several renderer/multi-frame/distributed scenarios were not validated in earlier releases. Do not convert those historical limitations into commercial promises without fresh runtime testing.

## Scene-change safety

`CyrusPFClear()` tracks deleted transient handles so their deletion notifications do not recursively dirty Scatter/Analyzer.

## Licensing implication

A render worker may need the same placement computation path as an authoring workstation. Therefore “free render node” cannot mean “skip all licensing code.” It should mean a restricted `RenderExistingScene` capability detected natively, with authoring/edit/export denied.
