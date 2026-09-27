# 17 — Development History and Evolution

This timeline is reconstructed only from versioned repository README/guides. Missing versions are not invented.

| Version | Documented evolution |
|---|---|
| 0.10 | compact UI layout correction |
| 0.11 | higher limits and Area include/exclude |
| 0.12 | update modes, multiple surfaces, plants/m² |
| 0.13 | native cached point-cloud preview |
| 0.14 | Line Pattern diversity |
| 0.18 | consecutive line strokes |
| 0.19 | stroke-only output outside configured bands |
| 0.20 | inside/outside strokes and per-layer enable checkboxes |
| 0.23 | native spacing/collision/relax with grid + triangle BVH |
| 0.39 | earlier CS Edit index-based persistence |
| 0.40 | stable CS Edit identities and legacy migration |
| 0.41 | boundary/Street outward orientation and forward-axis model |
| 0.43 | Point Cloud/Proxy/Mesh viewport display |
| 0.44 | Edge Border UI binding fix |
| 0.45 | Edge Border ordered rows, offset/jitter |
| 0.46 | protected corner points |
| 0.47 | per-row local XYZ rotation |
| 0.48 | Edge Border blend radius |
| 0.49 | source-selection refresh and collapsed UI behavior |
| 0.50 | Analyzer boundary delete/scale/density falloff |
| 0.51 | per-Area falloff + CurveControl graph workflow |
| 0.54 | Analyzer Area centerline/point masks |
| 0.56 | Street Side trim and centerline street offset |
| 0.58 | lazy layer UI, drag suppression, blocker cache, coalesced IR |
| 0.59 | selection-only stall fix; Analyzer revision polling before dependency propagation |

## Architectural trend

The history shows a consistent evolution:
1. prototype scripted scatter;
2. native placement engine;
3. richer layered scripted orchestration;
4. native preview/performance paths;
5. native spatial solvers;
6. native persistent editing;
7. separate native Analyzer;
8. performance/event refinement.

This explains why the present system is hybrid rather than a monolithic C++ plugin or a simple script.
