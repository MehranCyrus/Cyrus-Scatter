# 02 — Repository and File Inventory

**Audited baseline:** `b9a9e909b469456a6193337363b7c50b2397e549`

The baseline contains **97 tracked files**. This inventory is generated from the recursive Git tree, not from a guessed folder list.

| Path | Bytes | Role |
|---|---:|---|
| `.gitignore` | 809 | Repository hygiene and secret/build exclusions |
| `AminScatter/Analyzer-Area-guide.md` | 1104 | Existing project guide/release note |
| `AminScatter/Area-Falloff-Graph-guide.md` | 1860 | Existing project guide/release note |
| `AminScatter/Boundary-Falloff-guide.md` | 2098 | Existing project guide/release note |
| `AminScatter/Boundary-facing-guide.md` | 2202 | Existing project guide/release note |
| `AminScatter/CMakeLists.txt` | 2789 | Scatter core, tests and 3ds Max native module build |
| `AminScatter/CS-Edit-guide.md` | 3446 | Existing project guide/release note |
| `AminScatter/Edge-Border-0.44-fix.md` | 413 | Existing project guide/release note |
| `AminScatter/Edge-Border-guide.md` | 4453 | Existing project guide/release note |
| `AminScatter/Performance-0.58-guide.md` | 2453 | Existing project guide/release note |
| `AminScatter/README.md` | 20030 | Existing project guide/release note |
| `AminScatter/Selection-0.59-fix.md` | 1484 | Existing project guide/release note |
| `AminScatter/Street-layout-guide.md` | 1239 | Existing project guide/release note |
| `AminScatter/UI-0.49-guide.md` | 638 | Existing project guide/release note |
| `AminScatter/Viewport-display-guide.md` | 1996 | Existing project guide/release note |
| `AminScatter/include/scatter.h` | 4871 | Public host-independent scatter C++ API |
| `AminScatter/installer/AminScatter.mcr` | 373 | MZP/startup/macro/install/uninstall packaging |
| `AminScatter/installer/AminScatterStartup.ms` | 148 | MZP/startup/macro/install/uninstall packaging |
| `AminScatter/installer/Uninstall.ms` | 1087 | MZP/startup/macro/install/uninstall packaging |
| `AminScatter/installer/install.ms` | 2841 | MZP/startup/macro/install/uninstall packaging |
| `AminScatter/installer/mzp.run` | 87 | MZP/startup/macro/install/uninstall packaging |
| `AminScatter/scripts/AminScatter.ms` | 5741 | Older/prototype scripted UI; not the production generated controller |
| `AminScatter/scripts/AminScatterObject.ms` | 963924 | Generated production Cyrus Scatter scripted plug-in |
| `AminScatter/src/analyzer_area_bridge.inc` | 2117 | Analyzer-area native mask bridge |
| `AminScatter/src/boundary_falloff.inc` | 4021 | Boundary/area falloff implementation or bridge |
| `AminScatter/src/boundary_falloff_bridge.inc` | 3314 | Boundary/area falloff implementation or bridge |
| `AminScatter/src/cyrus_edit.cpp` | 15188 | Native CS Edit modifier/persistence/stack |
| `AminScatter/src/cyrus_edit.rc` | 300 | Native CS Edit modifier/persistence/stack |
| `AminScatter/src/cyrus_edit_stack.inc` | 4412 | Native CS Edit modifier/persistence/stack |
| `AminScatter/src/cyrus_edit_storage.inc` | 2403 | Native CS Edit modifier/persistence/stack |
| `AminScatter/src/edge_border.inc` | 5067 | Edge Border generation |
| `AminScatter/src/edit_plugin.cpp` | 485 | Project source/support file |
| `AminScatter/src/final.inc` | 5626 | Final cleanup and constrained boundary relaxation |
| `AminScatter/src/geometry_preview.inc` | 4367 | Native viewport preview/cache |
| `AminScatter/src/max_bridge.cpp` | 21802 | 3ds Max/MAXScript native bridge |
| `AminScatter/src/orientation.inc` | 8029 | Boundary/edge orientation implementation or bridge |
| `AminScatter/src/orientation_bridge.inc` | 3234 | Boundary/edge orientation implementation or bridge |
| `AminScatter/src/preview.cpp` | 7231 | Native viewport preview/cache |
| `AminScatter/src/scatter.cpp` | 24459 | Core scatter implementation |
| `AminScatter/src/spacing.inc` | 7577 | Native collision/relax solver |
| `AminScatter/src/whole_scale_bridge.inc` | 1278 | Deterministic whole-scale bridge |
| `AminScatter/tests/boundary_falloff_tests.cpp` | 3157 | Native regression test/source fixture |
| `AminScatter/tests/edge_border_tests.cpp` | 3709 | Native regression test/source fixture |
| `AminScatter/tests/orientation_tests.cpp` | 4343 | Native regression test/source fixture |
| `AminScatter/tests/scatter_tests.cpp` | 18188 | Native regression test/source fixture |
| `AminScatter/tests/spacing_tests.cpp` | 3508 | Native regression test/source fixture |
| `AminScatter/tests/weight_tests.cpp` | 2209 | Native regression test/source fixture |
| `AminScatter/tools/ui/activation.cjs` | 2366 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/analyzer-area.cjs` | 2639 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/area-falloff.cjs` | 2234 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/boundary-falloff.cjs` | 8347 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/centers.cjs` | 2900 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/display-modes.cjs` | 4385 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/edge-border.cjs` | 7208 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/edge-corners.cjs` | 2300 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/edge-rotation.cjs` | 1944 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/edit.cjs` | 2156 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/empty.cjs` | 3437 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/final.cjs` | 4741 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/generate.cjs` | 10928 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/orientation.cjs` | 4992 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/overlaps.cjs` | 7083 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/performance.cjs` | 6885 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/point-source.cjs` | 3328 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/radius-display.cjs` | 2510 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/radius.cjs` | 7161 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/responsive.cjs` | 1680 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/source-refresh.cjs` | 884 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/source-transforms.cjs` | 3977 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/spacing.cjs` | 3841 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/street-layout.cjs` | 3330 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/templates/analyzer-area-ui.ms` | 2103 | MAXScript generator template |
| `AminScatter/tools/ui/templates/area-falloff-methods.ms` | 3723 | MAXScript generator template |
| `AminScatter/tools/ui/templates/area-falloff-ui.ms` | 3715 | MAXScript generator template |
| `AminScatter/tools/ui/templates/before.ms` | 59863 | MAXScript generator template |
| `AminScatter/tools/ui/templates/containers.ms` | 4271 | MAXScript generator template |
| `AminScatter/tools/ui/templates/falloff-graph.ms` | 3779 | MAXScript generator template |
| `AminScatter/tools/ui/templates/host.ms` | 3985 | MAXScript generator template |
| `AminScatter/tools/ui/templates/pflow.ms` | 8299 | MAXScript generator template |
| `AminScatter/tools/ui/templates/storage.ms` | 3633 | MAXScript generator template |
| `AminScatter/tools/ui/templates/street-layout-methods.ms` | 3274 | MAXScript generator template |
| `AminScatter/tools/ui/templates/stroke-ui.ms` | 10061 | MAXScript generator template |
| `AminScatter/tools/ui/templates/strokes.ms` | 6284 | MAXScript generator template |
| `AminScatter/tools/ui/weights.cjs` | 3340 | Node.js UI/feature generator stage |
| `AminScatter/tools/ui/whole-scale.cjs` | 1730 | Node.js UI/feature generator stage |
| `CyrusSurfaceAnalyzer/CMakeLists.txt` | 992 | Analyzer core, test and native module build |
| `CyrusSurfaceAnalyzer/README.md` | 5243 | Existing project guide/release note |
| `CyrusSurfaceAnalyzer/installer/CyrusSurfaceAnalyzerStartup.ms` | 81 | MZP/startup/macro/install/uninstall packaging |
| `CyrusSurfaceAnalyzer/installer/install.ms` | 1348 | MZP/startup/macro/install/uninstall packaging |
| `CyrusSurfaceAnalyzer/installer/mzp.run` | 67 | MZP/startup/macro/install/uninstall packaging |
| `CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms` | 21869 | Production Analyzer scripted plug-in/UI/lifecycle |
| `CyrusSurfaceAnalyzer/src/analyzer.cpp` | 10064 | Analyzer native engine/bridge |
| `CyrusSurfaceAnalyzer/src/analyzer.h` | 776 | Analyzer native engine/bridge |
| `CyrusSurfaceAnalyzer/src/bridge.cpp` | 3195 | Analyzer native engine/bridge |
| `CyrusSurfaceAnalyzer/src/elements.cpp` | 7545 | Analyzer native engine/bridge |
| `CyrusSurfaceAnalyzer/tests/samples.h` | 2894 | Native regression test/source fixture |
| `CyrusSurfaceAnalyzer/tests/test.cpp` | 6826 | Native regression test/source fixture |
