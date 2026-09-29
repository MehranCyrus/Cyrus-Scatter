# 08 — Preview and Viewport System

## Native point cache

`preview.cpp` defines `AminPointCache : Value`. Point preview data is grouped natively and drawn through one native call rather than exporting every point through MAXScript on each redraw.

Primitives:
`aminScatterBuildPreview`, `aminScatterPreviewCount`, `aminScatterDrawPreview`, `aminScatterPreviewPoints`.

## Geometry preview

`geometry_preview.inc` extends the same cache with source geometry/proxy representations:
- Box;
- Sphere/ellipsoid;
- Pyramid;
- evaluated mesh.

Source meshes are copied into cache data, not instantiated as scene nodes. Final placement matrices are stored as instances.

Limits:
- instance limit up to 100,000;
- face budget up to 20,000,000;
- invalid/deleted/placeholder sources are handled separately.

## Display modes

The generated UI exposes Point Cloud / Proxy / Mesh. These affect viewport representation only, not render placement.

## Radius overlay

Source collision radii can be cached and drawn separately. `radius-display.cjs` adds per-layer display limits/all-radii behavior.

## Redraw callback

`AminScatterObjectDraw`:
- draws the controller icon;
- iterates enabled layer entries;
- ensures preview cache;
- draws radii;
- draws point/center preview through native code.

## Interaction throttling

Performance stage behavior:
- while a mouse button is held, `previewCache()` returns the existing cache;
- `CyrusWasDragging` records that a final redraw is needed;
- a 200 ms timer redraws after release.

This intentionally trades live-drag recomputation for responsive interaction.

## Preview cache invalidation

Dirty state depends on update mode, scene/node events, Analyzer revisions, layer dependency propagation, edit-stack revision and explicit refresh.

Manual mode preserves old preview until explicit update, but production render evaluates current inputs.

## Licensing rule

Viewport drawing should never require an online license call. The entitlement decision should be cached/authorized before generating authoring results.
