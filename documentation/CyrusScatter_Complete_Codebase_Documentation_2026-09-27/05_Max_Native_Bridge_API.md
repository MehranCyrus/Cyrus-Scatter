# 05 — 3ds Max Native Bridge and MAXScript API

## Geometry conversion

`meshOf(INode*, world, requireUv)`:
- evaluates the node at current Max time;
- requires conversion to `TriObject`;
- converts evaluated vertices/faces to `amin::Triangle`;
- applies world transform for surfaces;
- uses pivot-local conversion for source sampling;
- optionally requires map channel 1.

`surfaceMeshes()` accepts either one node or an array, deduplicates nodes and concatenates triangles.

## Exported visible primitives

### Scatter/bridge
| Primitive | Purpose |
|---|---|
| `aminScatterAdvanced` | full scatter/settings entry point; backward-compatible argument counts |
| `aminScatterTransforms` | simpler/fast transform generation |
| `aminScatterSourcePoints` | deterministic source-geometry samples |
| `aminScatterValidArea` | closed-shape validation |
| `aminScatterSurfaceArea` | evaluated world-space surface area |
| `cyrusRemoveOverlaps` | cross-layer stable row filtering, fixed or per-source radii |
| `cyrusOrientRows` | native boundary/edge orientation |
| `cyrusBoundaryFalloff` | Analyzer-boundary falloff |
| `cyrusAreaFalloff` | Area-spline falloff |
| `cyrusWholeScale` | deterministic uniform post-scale |
| `cyrusAnalyzerArea` | world-XY Analyzer centerline/point mask |

### Preview
| Primitive | Purpose |
|---|---|
| `aminScatterBuildPreview` | point-cloud cache |
| `aminScatterPreviewCount` | cache count |
| `aminScatterDrawPreview` | native point drawing |
| `aminScatterPreviewPoints` | diagnostic/export of preview points |
| `cyrusBuildGeometryPreview` | proxy/mesh geometry cache |
| `cyrusPreviewFaces` | geometry cache face count |

### CS Edit
| Primitive | Purpose |
|---|---|
| `cyrusEditRevision` | edit revision counter |
| `cyrusEditFingerprint` | base placement fingerprint |
| `cyrusEditCommand` | reset/select/delete/clone/transform command multiplexer |
| `cyrusEditTopology` | topology signature |
| `cyrusEditActiveLayers` | layer activity |
| `cyrusEditSelect` | visible-index selection |
| `cyrusEditTransform` | native transform operation |
| `cyrusEditStack` | stable-identity modifier-stack composition |

### Surface Analyzer
`cyrusAnalyzeSurface` accepts 7/8/9/11 arguments for progressively newer settings and returns Analyzer result arrays/statistics.

## Backward compatibility

`aminScatterAdvanced` intentionally accepts several historical argument counts. This is evidence that the bridge has been evolved while preserving older scripted call forms. Treat those accepted forms as compatibility surface until a deliberate breaking release.

## Future licensing choke points

Primary native gates:
- authoring scatter primitives;
- CS Edit mutation primitives;
- Analyzer interactive analysis;
- export/bake operations.

Preview drawing should not perform network checks. Pure scene evaluation for render must have a restricted capability path.
