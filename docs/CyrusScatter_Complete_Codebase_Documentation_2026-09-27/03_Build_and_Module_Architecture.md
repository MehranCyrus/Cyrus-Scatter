# 03 — Build and Module Architecture

## AminScatter CMake

`AminScatter/CMakeLists.txt` requires CMake 3.24 and defines project version `0.1.0`.

Targets:

| Target | Type | Purpose |
|---|---|---|
| `amin_scatter` | STATIC | host-independent scatter engine |
| `scatter_tests` | EXE/CTest | core behavior |
| `spacing_tests` | EXE/CTest | relax/collision |
| `weight_tests` | EXE/CTest | source weighting |
| `orientation_tests` | EXE/CTest | boundary/edge facing |
| `edge_border_tests` | EXE/CTest | ordered edge rows |
| `boundary_falloff_tests` | EXE/CTest | falloff behavior |
| `AminScatter` | MODULE → .dlx | Max bridge + preview + CS Edit implementation |
| `CyrusScatterEdit` | MODULE → .dlm | dedicated modifier module descriptor |

`AMIN_BUILD_MAX=OFF` allows the pure core/tests to build without the Autodesk SDK.

The current SDK root defaults to `C:/Program Files/Autodesk/3ds Max 2026 SDK/maxsdk`. `max_bridge.cpp` also has a compile-time assertion for product year 2026.

## CS Edit module relationship

`AminScatter.dlx` compiles `cyrus_edit.cpp` and exports `CyrusEditDesc()`. It reports one class descriptor. `CyrusScatterEdit.dlm` compiles only `edit_plugin.cpp`, depends on `AminScatter`, links the generated `AminScatter.lib`, and also exposes `CyrusEditDesc()`.

This is an unusual two-module relationship. Do not refactor it casually. Before commercial packaging, verify on a clean machine:
- which module Max loads first;
- whether both report the same modifier class;
- whether duplicate descriptor registration occurs;
- whether `.dlm` is required in practice;
- whether packaging/load order can be simplified without breaking existing scenes.

## Surface Analyzer CMake

Targets:
- `analyzer` STATIC from `analyzer.cpp` + `elements.cpp`;
- `analyzer_tests`;
- `CyrusSurfaceAnalyzer.dlx`.

It also hard-codes the 2026 SDK path.

## Compiler posture

The scatter core explicitly enables C++17 and, under MSVC, `/W4 /WX /permissive-`. Analyzer uses C++17 but does not currently mirror the same warning-as-error flags.

## Recommended build cleanup

Before licensing:
1. one top-level CMake entry or documented super-build;
2. explicit Max-version presets;
3. one product-version source;
4. Release CI for core tests independent of Max;
5. Max 2026/2027 matrix jobs where SDK licensing permits;
6. signed release artifact stage separate from compilation.
