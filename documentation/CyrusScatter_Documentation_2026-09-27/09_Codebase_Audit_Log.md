# 09 — Codebase Audit Log

## Baseline

Repository: `MehranCyrus/Cyrus-Scatter`  
Branch: `main`  
Commit: `b9a9e909b469456a6193337363b7c50b2397e549`  
Message: `Initial Cyrus Scatter project import`

GitHub reported visibility: **public**.

## Inventoried current files

### AminScatter
`CMakeLists.txt`, `include/scatter.h`, `src/scatter.cpp`, `src/max_bridge.cpp`, `src/preview.cpp`, CS Edit source/storage/stack, edit plugin, spacing/orientation/edge-border/boundary-falloff/final helpers, scripts, UI generator/stages/templates, installer, tests and feature guides.

### Surface Analyzer
`CMakeLists.txt`, `README.md`, `analyzer.h`, `analyzer.cpp`, `elements.cpp`, `bridge.cpp`, MAXScript UI, installer and tests.

## Verified findings

1. Scatter math is native and host-independent.
2. Max integration is a separate native adapter.
3. Generated MAXScript is UI/orchestration rather than the only implementation.
4. Preview is native.
5. CS Edit is a native modifier with persistence/stack logic.
6. Analyzer is a separate native engine and bridge.
7. PFlow/MAXScript participates in final-render lifecycle.
8. Native CTest targets exist.
9. Build scripts explicitly target Max 2026.
10. Versioning is fragmented.
11. Secret/signing patterns are ignored by Git.
12. The architecture has natural native licensing choke points.

## Build observations

AminScatter builds `amin_scatter`, six test executables, `AminScatter.dlx` and `CyrusScatterEdit.dlm`. The edit module depends on AminScatter and links its generated import library; clean-package load ordering should be tested.

Surface Analyzer builds a static `analyzer` library, `analyzer_tests`, and `CyrusSurfaceAnalyzer.dlx`.

## Version observations

Examples at baseline include CMake `AminScatter 0.1.0`, native scatter description `0.21`, Analyzer CMake/native `0.5`, Analyzer README `0.14`, plus later feature-guide numbers. Centralize the public release version before licensing eligibility depends on it.

## Audit limitations

Not performed during reconstruction: compilation, CTest execution, Max launch, renderer/farm validation, binary import inspection, fuzzing, penetration test or Marketplace submission.

## Focus areas before implementation

- full native primitive call graph;
- every CS Edit mutation path;
- generated controller persistence schema;
- PFlow cleanup on cancel/error/network render;
- Analyzer dependencies during render;
- installer/uninstaller state changes;
- Class IDs/chunk IDs/globals required for old scenes;
- renderer-specific branches;
- export/bake paths;
- future updater.
