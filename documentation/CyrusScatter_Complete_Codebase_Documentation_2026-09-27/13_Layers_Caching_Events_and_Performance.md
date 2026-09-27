# 13 — Layers, Caching, Events, and Performance

## Layer ownership

Root `AminScatterObject` stores layer objects in `layerObjects`. `layerEntries()` synchronizes shared surface state, checks Analyzer revisions and propagates blocker dirtiness.

## Update modes

Historical README documents Real-time and Manual behavior. Real-time responds to relevant scene changes; Manual retains cached preview until Update. Production render evaluates current inputs.

## Node events

Scatter NodeEventCallback:
- `deleted`;
- `geometryChanged`;
- `topologyChanged`;
- `mappingChanged`;
- `modelStructured`;
- `controllerOtherEvent`;
- `controllerStructured`;
- `linkChanged`;
with `mouseUp:true`, `delay:150`.

The 0.59 fix intentionally removed broad `modelOtherEvent` handling to avoid selection-only stalls.

## Time callback

`AminScatterLiveTime` invalidates live layers on time change unless render redraw is held.

## Undo/redo

Scene undo/redo callback `#AminScatterLayers` forces preview rebuilds and refreshes command-panel UI.

## Analyzer revisions

Scatter does not trust Analyzer helper-node display events as data changes. It polls Analyzer's `analysisRuns` counter and includes relevant revisions in cache/render signatures.

## Blocker cache

Performance 0.58 introduced a raw blocker-placement cache keyed by placement inputs, scene revisions, time, Analyzer revisions and manual revision. Downstream overlap/final/orientation/CS Edit are intentionally outside that raw cache.

## PFlow revisioning

Globals `CyrusPFRevision` and `CyrusPFManualRevision` participate in render signatures. External scene changes increment revision; explicit refresh increments manual revision.

## Timers

- PFlow/IR timer: 750 ms.
- interaction release timer: 200 ms.
- Analyzer realtime timer: 250 ms.

## Performance philosophy visible in source

The project repeatedly moves heavy data handling to native code while retaining MAXScript orchestration:
- native scatter;
- native spacing/BVH;
- native preview;
- native overlap filtering;
- native orientation/falloff;
- native CS Edit;
- native Analyzer.

This is the correct direction for both performance and future licensing.
