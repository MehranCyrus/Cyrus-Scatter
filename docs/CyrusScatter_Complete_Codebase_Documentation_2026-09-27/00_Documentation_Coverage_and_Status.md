# 00 — Documentation Coverage and Status

## Coverage result

The repository baseline contains 97 tracked files. This pass covered every file at inventory level and every implementation family at source-analysis level.

| Area | Static source coverage | Runtime coverage in this pass |
|---|---|---|
| Scatter C++ core | complete architectural/function pass | not executed |
| Max native bridge | complete primitive/boundary pass | not loaded in Max |
| Native preview | complete primitive/cache pass | not drawn in Max |
| CS Edit | storage, identity stack, transform/mutation pass | not interactively tested |
| Generated MAXScript | generated structure, 153 persisted parameters, callbacks and key flows | not executed |
| UI generator | all stage files and templates inventoried/inspected | generator not run |
| PFlow render bridge | build/clear/signature/callback flow traced | renderer not run |
| Surface Analyzer C++ | element/analysis/spacing flow traced | tests not executed |
| Analyzer MAXScript | analysis/export/realtime/event flow traced | not executed |
| Install/startup/uninstall | scripts traced | not installed |
| CMake | targets/dependencies traced | not configured/built |
| Tests | all native test sources inspected | not executed |
| Existing guides | release/feature history read | historical claims not independently rerun |

## Production generated object facts

`AminScatter/scripts/AminScatterObject.ms` is about 964 KB, generated, class version **44**, and contains:
- scripted class ID `#(0x617d43a1,0x395c2e17)`;
- category `Cyrus`;
- 153 typed persisted parameters detected in the generated file;
- 500+ generated/local function declarations because ten layer UI factories are duplicated intentionally;
- native calls into scatter, preview, falloff, orientation, overlap and CS Edit primitives;
- redraw, node-event, time, undo/redo, render and file lifecycle callbacks.

`CyrusSurfaceAnalyzer.ms` is about 22 KB, class version **13**, class ID `#(0x45a201c7,0x1829bc63)`.

## What is now documented that was missing before

The earlier package was strong on architecture/licensing. This package adds:
- exact repository inventory;
- generator stage order;
- native MAXScript primitive catalog;
- generated controller data model;
- callback/event/timer lifecycle;
- render/PFlow construction and cleanup;
- CS Edit chunk/identity migration details;
- Analyzer algorithm stages;
- installer/startup/uninstall behavior;
- compatibility identifiers;
- documented feature-evolution timeline;
- exact static test coverage;
- open questions that require runtime validation.

## Definition of “complete” used here

“Complete documentation” means the current repository can be understood subsystem-by-subsystem without first reverse-engineering its folder structure. It does **not** mean every implementation line is restated in prose, and it does not substitute for running the product.
