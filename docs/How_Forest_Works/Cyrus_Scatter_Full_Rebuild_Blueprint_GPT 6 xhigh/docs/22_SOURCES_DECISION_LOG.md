# 22 — Primary source register, evidence limitations and open decision log

## 1. Source hierarchy

1. **ITOOSOFT official reference:** authoritative about advertised ForestPack feature behavior, but can contain historical-version wording and undisclosed implementation details.
2. **ITOOSOFT changelog/What's New:** authoritative about named feature additions/fixes and approximate release/version scope.
3. **Autodesk official Max SDK:** authoritative about documented 3ds Max interfaces and threading/Undo constraints for referenced SDK releases.
4. **User-supplied Research Forest.md:** project research foundation, retained verbatim in `../reference/Original_Research_Forest.md`.
5. **Our independent design:** proposed algorithms and data structures; not evidence about ForestPack internals.
6. **Controlled reference experiments:** to be created; none were run while preparing this handbook.

**Date checked:** 2026-10-13. Latest ForestPack release entry located on official changelog: **9.4.3, September 8, 2026**. [Changelog](https://docs.itoosoft.com/changelog).

## 2. Official ForestPack references

| Subject | Link |
|---|---|
| Main feature tree | https://docs.itoosoft.com/forestpack/forest-plugin |
| Geometry/source list | https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry |
| Image mode, diversity, collisions | https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode |
| Path mode | https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode |
| Reference mode | https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode |
| Particle Flow | https://docs.itoosoft.com/forestpack/forest-plugin/distribution/particle-flow-mode |
| RailClone input | https://docs.itoosoft.com/forestpack/forest-plugin/distribution/railclone-integration |
| Ordered Areas, Paint, Falloff | https://docs.itoosoft.com/forestpack/forest-plugin/areas |
| Surface XY/UV | https://docs.itoosoft.com/forestpack/forest-plugin/surfaces |
| Transforms | https://docs.itoosoft.com/forestpack/forest-plugin/transform |
| Items Editor | https://docs.itoosoft.com/forestpack/forest-plugin/item-editor |
| Camera | https://docs.itoosoft.com/forestpack/forest-plugin/camera |
| LOD helper | https://docs.itoosoft.com/forestpack/forest-plugin/forest-lod |
| Material rollout | https://docs.itoosoft.com/forestpack/forest-plugin/material |
| Forest Color | https://docs.itoosoft.com/forestpack/forest-color |
| Forest Edge | https://docs.itoosoft.com/forestpack/forest-edge-map |
| Effects | https://docs.itoosoft.com/forestpack/forest-plugin/effects |
| Effects Syntax | https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/effects-syntax |
| Effects Attributes | https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/attributes |
| Effects Functions | https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/functions |
| Effects Parameters | https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/parameters |
| Repulsion example | https://docs.itoosoft.com/forestpack/forest-plugin/effects/effects-examples/repulsion |
| Animation | https://docs.itoosoft.com/forestpack/forest-plugin/animation |
| Shadows (legacy) | https://docs.itoosoft.com/forestpack/forest-plugin/shadows |
| Display / render modes | https://docs.itoosoft.com/forestpack/forest-plugin/display |
| General | https://docs.itoosoft.com/forestpack/forest-plugin/general |
| ForestSet | https://docs.itoosoft.com/forestpack/forestset-plugin |
| Forest Library | https://docs.itoosoft.com/forestpack/forest-library/library-browser |
| Forest Lister | https://docs.itoosoft.com/forestpack/forest-lister |
| ForestIvy | https://docs.itoosoft.com/forestpack/forest-ivy/forest-ivy-overview |
| Render best practices | https://docs.itoosoft.com/forestpack/rendering/rendering-best-practice |
| What's New 9.3 | https://docs.itoosoft.com/forestpack/whats-new/forest-pack-9-3 |
| What's New 8 | https://docs.itoosoft.com/forestpack/whats-new/forest-pack-8 |
| Official release log | https://docs.itoosoft.com/changelog |
| 9.3.5 collisions | https://docs.itoosoft.com/changelog/2026/03/15/forestpack-9_3_5 |
| 9.4.1 RailClone | https://docs.itoosoft.com/changelog/2026/06/17/forestpack-9_4_1 |
| 9.4.3 release | https://docs.itoosoft.com/changelog/2026/09/08/forestpack-9_4_3 |

## 3. Autodesk primary technical references

| Subject | Link |
|---|---|
| Painting canvas interface (Max 2025) | https://help.autodesk.com/cloudhelp/2025/ENU/MAXDEV-CPP-API-REF/class_i_painter_canvas_interface___v5.html |
| Painter interface (Max 2027) | https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_painter_interface___v5.html |
| SDK Undo (`Hold`) | https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_hold.html |
| ViewportDisplayCallback | https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_viewport_display_callback.html |
| NodeDisplayCallback | https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_node_display_callback.html |
| Notification codes | https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/group___notification_codes.html |
| Render-session threading caution | https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/3ds_max_sdk_features/rendering/new_rendering_api/render_session.html |

Review exact SDK version and headers before implementation; links to nearby SDK versions do not guarantee binary/API compatibility with your installed build.

## 4. Important things not established by public sources

These are critical **[TEST-NEEDED]** items, not missing details to fill with intuition:

- ForestPack's exact private collision spatial index, winner-selection and incremental algorithm.
- Private paint history format, raster/vector representation, contour conversion implementation and Undo scheme.
- Cluster underlying noise/territory algorithm.
- The complete internal evaluation order across every Area, Transform, Effect, collision and render rule.
- Stable internal per-instance identity implementation, if any.
- Exact Image Mode candidate placement jitter, threshold rounding, grayscale conversion, Color ID distance metric.
- Precise handling of multi-hit stacked XY and UV overlapping islands for each configuration.
- Renderer-specific internal callbacks/memory ownership; public claims of support do not supply SDK code.
- Whether current Cyrus Scatter already has equivalent/native components and how they are organized.
- Exact numerical defaults/ranges for every version-specific control; the official docs are not a complete certified machine-readable registry.

## 5. Explicit independent design decisions proposed in this handbook

| ID | Decision | Reason | Alternative |
|---|---|---|---|
| DEC-001 | Persistent authoring schema + derived caches | Recoverability and reproducibility | Store generated positions as authority (rejected) |
| DEC-002 | Candidate IDs separate from source choice | Keep placement stable under weight changes | Index-based IDs (rejected) |
| DEC-003 | Typed field interface | Reuse distance/map/surface queries | One-off features (rejected) |
| DEC-004 | Ordered Area contributions with provenance | Match compositional semantics | Union-minus-union (insufficient) |
| DEC-005 | Initially authoritative full occupancy solution | Correctness before local optimization | Approximate dirty tiles only |
| DEC-006 | Hybrid stroke authority + tiled compiled coverage | Editing and fast repeated evaluation | Pure stroke scan/pure bitmap |
| DEC-007 | Snapshot/compute/publish threading boundary | Host safety and cancelability | Off-thread SDK scene access (unsafe assumption) |
| DEC-008 | Sparse manual override layer | Procedural/manual coexistence | Destructive flattening |
| DEC-009 | Renderer capability adapters | Avoid false feature support | Single generic renderer path |
| DEC-010 | Full fixture-based regression | Detect interaction bugs | UI visual test alone |

Decisions are **proposals**, not repository facts. Review/accept them via architecture review after code audit.

## 6. Open behavior investigations ordered by leverage

| Investigation | Reason | Proposed test |
|---|---|---|
| Ordered Area + local override precedence | Fundamental evaluation model | Three overlapping regions, distinct source subsets |
| Density vs collision winner stability | Instance identities, preview flicker | Fixed seed, increasing density and different radii |
| Paint coverage vs falloff | Core paint architecture | Paint shape, erase hole, inspect accepted and effective coverage |
| Random translation/boundary check order | Difficult combined mode | Box centered near spline with large translation |
| Source transform/collision radius relation | Spacing correctness | Swap large/small sources, vary scale |
| Cluster field semantics | Natural environment quality | Two colors, parameter sweeps, distribution heatmaps |
| Surface XY stacked hit policy | Architectural balconies | Two vertically offset floors, identical XY positions |
| UV paint/masks by version | Version restrictions and product scope | Curved receiver, UV and Paint/Area permutations |
| Edge trimming in target renderer | Requires shader/render API | Controlled clump at spline boundary |
| Animated source sample renderer support | Production pipeline | One wind-animated source with random sample offsets |

## 7. Documentation debt / conflict policy

Some official ForestPack reference pages retain notes for older releases and may conflict with newer feature introductions (e.g., UV Areas vs legacy restrictions). Record for each controversial control: source URL, date/version applicability, target installed build screenshot, actual observed behavior, parity policy. Never silently replace a historical claim with a guessed current rule.

## 8. IP and engineering discipline

Independent implementation may reproduce feature ideas and artist-visible workflows but should not copy protected source code, asset libraries, logos, copyrighted UI artwork, license systems, or proprietary binary integrations. Respect SDK licenses and renderer redistributable policies. Use original tests, field algorithms and UI expression to differentiate Cyrus Scatter.
