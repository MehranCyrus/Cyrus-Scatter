# 01 — System Overview

## Product architecture

```text
3ds Max
│
├─ Cyrus Scatter scripted object (generated MAXScript)
│  ├─ persisted scene parameters and layers
│  ├─ UI / invalidation / caching
│  ├─ calls native scatter primitives
│  ├─ calls native preview primitives
│  ├─ composes native CS Edit stack
│  └─ builds transient PFlow for production render
│
├─ AminScatter.dlx
│  ├─ Max scene/mesh/MAXScript bridge
│  ├─ native preview/cache
│  ├─ CS Edit implementation/exported primitives
│  └─ links host-independent amin_scatter
│
├─ CyrusScatterEdit.dlm
│  └─ exposes the CS Edit modifier descriptor through a dedicated Max module
│
└─ CyrusSurfaceAnalyzer.dlx + CyrusSurfaceAnalyzer.ms
   ├─ Max bridge
   ├─ host-independent analyzer engine
   ├─ realtime scripted lifecycle/UI
   └─ publishes boundaries/paths/points used by Scatter
```

## Core separation

The most important design decision already present is that `amin_scatter` and `analyzer` are static C++ libraries with their own data types and native tests. Autodesk types are introduced in bridge modules, not in the public scatter/analyzer APIs.

## Main runtime path

```text
User/scene changes
 -> generated MAXScript marks layer dirty
 -> previewCache decides whether to rebuild
 -> placements()
 -> fast path: aminScatterTransforms
    OR advanced path: aminScatterAdvanced
 -> whole scale
 -> Analyzer Area filter
 -> boundary/area falloff
 -> source Z/scale transforms
 -> cross-layer overlap filtering
 -> optional final cleanup/relax
 -> optional boundary/edge orientation
 -> CS Edit stack
 -> preview cache/draw
```

Production rendering uses the same placement result but transports it through transient PFlow objects.

## Surface Analyzer path

```text
Analyzer scripted object
 -> inputSignature/liveDirty
 -> cyrusAnalyzeSurface
 -> bridge converts evaluated Max mesh to cyrus::Mesh
 -> elements() splits connected components
 -> analyzeElement() classifies/extracts paths
 -> global spacing / fit / minimum-point logic
 -> scripted object stores flattened boundaries/paths/points
 -> Scatter reads published Analyzer properties
```

## Architectural strengths

- pure native mathematical cores;
- deterministic seeded behavior;
- generated UI source rather than hand-maintained 964 KB output;
- native preview cache;
- explicit test executables;
- persistent CS Edit identity migration;
- clear native bridge choke points suitable for future licensing.

## Architectural debt

- 2026 SDK is hard-coded;
- multiple version systems disagree;
- installer modifies `Plugin.UserSettings.ini` instead of using a commercial bundle;
- production MAXScript is generated through textual patch stages, making generator anchors a maintenance risk;
- render bridge is renderer/host-lifecycle sensitive;
- CS Edit module descriptor relationship should be clean-install validated;
- licensing is not yet implemented.
