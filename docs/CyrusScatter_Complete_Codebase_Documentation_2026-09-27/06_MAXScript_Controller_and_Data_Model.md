# 06 — Generated MAXScript Controller and Data Model

## Production scripted class

```maxscript
plugin simpleObject AminScatterObject
name:"Cyrus Scatter"
classID:#(0x617d43a1,0x395c2e17)
category:"Cyrus"
version:44
```

The internal class name remains `AminScatterObject` for compatibility even though product-facing branding is Cyrus Scatter.

## Generated nature

The 964 KB `AminScatterObject.ms` is build output. Source maintenance belongs in `tools/ui/generate.cjs`, templates and stage files.

## Persisted parameter families

The generated object contains 153 typed parameters. Major groups:

### Base/shared
surface/surfaceNodes, sources, bakedNodes, amount, randomSeed, scale/tilt/yaw/movement, alignNormal, updateMode, population mode/density, display controls.

### Layer management
`layerObjects`, `layerNames`, `layerEnabled`, `activeLayer`.

### Distribution/diversity
advanced XYZ ranges, density map/invert, cluster controls, source colors, source weights.

### Areas/falloff
Area nodes/modes, Analyzer Area node/settings, Analyzer boundary falloff, per-Area serialized falloff configs and graph data.

### Source-specific
Z offsets, source scales, source radii, follow-scale flags, radius display flags, forward axes, empty/point placeholder flags.

### Collision/final
within-layer collision/relax, cross-layer overlap settings/blockers, final cleanup/island/relax settings.

### Line/Analyzer/Edge
pattern lines/widths/groups, stroke side/mode/source/color mappings, Analyzer node, street controls, edge offsets/jitter/corners/local rotations/facing.

### Activation
`cyrusEnabled` is the current feature-enable switch. It is **not commercial licensing**.

## Placement orchestration order

`placements()` currently performs:

1. feature/analyzer-enabled checks;
2. validate surfaces/sources;
3. count or plants-per-m² calculation;
4. optional density-map rasterization;
5. Area inputs;
6. fast native path or `aminScatterAdvanced`;
7. whole-scale;
8. Analyzer Area mask;
9. falloff;
10. empty/point-source filtering;
11. source Z/scale post-transform;
12. cross-layer blockers/overlap removal;
13. final cleanup/relax;
14. boundary/Edge orientation;
15. CS Edit stack.

This order is important. Changing it can change saved-scene appearance.

## Layers

The root controller stores up to ten layer objects. Generator logic creates separate rollout declarations/factories per slot because Max rollout declarations are singleton-like. Layers store their own settings; the root owns shared surface/layer management and dependency propagation.

## Migration

`migrateLayers()` converts older root-held settings into a first layer when `layerObjects` is empty and old data exists. Generated `on update` also contains version migrations such as `migrateLayers()` and `syncStrokes()`.

## Bake

`bakeInstances()` creates permanent Max instances, tags them with user property `AminScatterOwner`, replaces prior owned baked nodes, hides point preview and disables auto render for that controller.

## Do not rename casually

The scripted class name, Class ID, parameter names and migration behavior are saved-scene compatibility surface.
