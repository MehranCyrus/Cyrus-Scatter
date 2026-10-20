# Native geometry inspection

This records the geometry contract first qualified for the independent Cyrus Arrange 0.1.0 inspector. It detects sampled support and vertical clearance. Inspection alone does not place accessories or prove object fit. The implemented [placement system](PLACEMENT.md) supplies separate footprint and collision checks. This inspection core is dependency-free C++20; Max 2027 snapshot/overlay/export integration belongs to the adapter.

Version 0.1.3 adds the bounded [numerical support correction](NUMERICAL_SUPPORT.md) for imported level boards in zero-degree mode. Native46 and its imported workflow/render trial pass; [release validation](RELEASE_VALIDATION_0.1.3.md) records exact acceptance and delivery status. Historical fixture counts and 0.1.0 qualification below describe the original inspector delivery.

## Input and ownership

`inspect(const Mesh&, const Settings&)` reads caller-owned arrays and returns a complete, owned `Result` or throws `std::exception`. It never changes input geometry and retains no references after returning. The adapter must preserve its previous completed result when a successor throws. No partial result is published by the core.

Coordinates are physical millimetres in a translated, near-origin, Z-up frame. The adapter must bake object offsets, nonuniform scale and evaluated deformation into the copied mesh and correct triangle winding for mirrored transforms. Upward support uses geometric triangle normals, not render normals. Outward winding is required; the core cannot repair or certify arbitrary imported winding.

Every vertex, including unused vertices, must be finite and within +/-1,000,000,000 mm of the origin. Bounds use only referenced vertices. Triangle indices must be valid. Empty geometry is rejected. Degenerate faces are counted and skipped; an all-degenerate or vertical-only mesh returns no support regions with diagnostics. Degeneracy uses a scale-relative area threshold, so excessively thin triangles below numerical resolution can be skipped.

## Sampling and layers

1. Validate settings, counts, coordinates, indices and referenced bounds before creating a grid.
2. Anchor an XY grid to the captured minimum X/Y and derive its dimensions with checked division/product bounds. Reject excessive extents before allocating grid arrays.
3. Index nonvertical triangles into the grid cells covered by their projected bounding boxes using compact offsets and 32-bit triangle references. Check known indexing plus five-ray work and storage sizes before allocation. Vertical triangles have zero projected ray area and remain in input bounds, but do not contribute ray hits.
4. In each cell, query five vertical lines: the centre and four corners inset by 5% of the cell size from its edges. Sort intersections by height and triangle index. All intersected triangle sides contribute overhead hits, including downward faces.
5. Each distinct upward centre hit meeting the slope threshold proposes a support layer. The other four rays must find upward, slope-qualified support near the centre triangle's predicted plane, within the height tolerance. This permits a shallow continuous slope rather than treating every cell as exactly flat.
6. At every sample position first check for a downward-facing hit coincident with its support height. This blocks clearance at zero: a divider bottom beginning on the shelf is material above the support, not free space up to the divider top. Also evaluate oriented crossings (downward entry, upward exit) grouped by height/facing to avoid double-counting triangle seams. A positive balance above support with remaining net exits conservatively blocks an apparent closed-shell interior. An isolated upward overhead sheet does not itself imply solid occupancy. Otherwise find the closest hit strictly above support. The cell clearance is the minimum of these five vertical distances. No hit is represented by positive infinity. Numerical ray epsilon is independent of the authored height tolerance, so a 0.1 mm overhead obstruction is not hidden by a 0.5 mm plane tolerance.
7. Keep supported cells even when their clearance is below `minimum_clearance_mm`; mark them `usable=false`. Usability requires clearance strictly greater than numerical ray epsilon as well as meeting the authored minimum (within numerical epsilon). Occupied zero-clearance cells remain unusable even when the authored minimum is zero. This preserves diagnostic evidence about occupied/covered portions. A downward-facing underside is never a support candidate under the outward-winding precondition.
8. Connect cells through the four XY neighbours when their predicted planes agree in both directions within height tolerance. Different shelf layers remain separate. Gaps remain absent at sampling resolution; corner-only diagonal contact does not join regions.

The algorithm visits every upward layer, so a shelf beneath another shelf is considered even though a single top-down projection could not see it. It does not construct a signed solid or assume watertightness. It can work on disconnected furniture parts and open shells with valid upward winding. It does not distinguish an accessible shelf from an internal surface behind a closed door.

## Result meanings

- `Result.bounds`: bounds of referenced input vertices, including obstacles and vertical walls.
- `Result.sampled_cells`: all returned supported cells across all shelf layers, including blocked cells.
- `Region.cells`: supported cells, with per-cell clearance and usability. The centre Z is the support height at the centre ray.
- `sampled_area_mm2`: supported cell count multiplied by cell size squared. `usable_area_mm2` counts only cells meeting the clearance threshold. Neither is exact polygon or sloped-surface area.
- `Region.bounds`: XY extent of full represented cells and minimum/maximum sampled support Z. The 5% unsampled border means bounds can extend slightly beyond the sampled support. A partial outer grid cell may be absent or represented according to its five samples.
- `minimum_clearance_mm`: minimum over every supported cell in the region, including blocked cells. A region can have finite minimum clearance while some cells are open above.
- `open_above`: true only when every cell has no overhead hit at any of its five sample positions.
- `id`: one-based deterministic region order for this exact snapshot/settings. It is not a persistent topology identity after mesh edits or reimport.
- `work`: charged validation, projection indexing, sample-query, sorting, matching and connectivity operations. It is a resource guard, not a time or memory measurement.

Grid traversal, sorted hits, seed order and four-neighbour visitation are deterministic for identical inputs in the same floating-point environment. Cross-compiler/platform bit equality and stable IDs after topology edits are not promised.

## Hard limits and failure

Settings may reduce these ceilings but cannot increase them:

| Limit | Absolute ceiling |
| --- | ---: |
| Input triangles | 1,000,000 |
| Input vertices | 3,000,000 |
| XY grid cells | 1,000,000 |
| Distinct upward centre-layer candidates, including candidates rejected at corners | 1,000,000 |
| Regions | 4,096 |
| Charged work | 50,000,000 |
| Raw triangle intersections on any one sample ray | 16,384 |

`max_cells` independently bounds the XY grid and the cumulative layered candidates. It is not just an output-count cap. Highly overlapping triangles can exhaust the intersection or work limits even when they would ultimately represent one support layer. All allocation counts are derived from validated, bounded quantities. A long thin mesh can still be rejected because the bounding grid contains too much empty space; this first implementation intentionally chooses a bounded dense XY index over an unbounded sparse-world representation.

Settings validation also requires: cell size 0.1–1,000,000 mm; finite nonnegative clearance at most 1,000,000,000 mm; slope 0–45 degrees; and finite positive height tolerance at most 1,000 mm. Height tolerance should be small relative to furniture details; a deliberately excessive tolerance can merge small steps or match different nearby surfaces.

Budget or allocation failure throws without publishing a result. Intermediate arrays are RAII-owned. Ray index storage is released before connected-region output expands; temporary sample cells coexist with returned region cells during grouping. Caller input, the previous result and a staged successor can coexist in the adapter. These count/work limits bound storage cardinalities, but they are not a measured Max process memory ceiling or a responsiveness guarantee.

## Uncertainty and excluded behavior

Five samples are a deliberate approximation. Small holes, slats, thin vertical obstacles and overhangs between rays can be missed. An object wider than its contact base can hit geometry even when the base's sampled cell is usable. Negative/incorrect winding can omit legitimate support or mislabel interior surfaces. The core returns warnings explaining sampling, outward-winding and crossing ambiguity for every inspection.

Oriented crossings are an additional conservative rejection, not general solid classification. The flattened input has no per-solid identities. Independent shells sharing a downward crossing height are grouped like duplicate triangles on a seam and can undercount occupancy. For example, a shelf box and penetrating upright divider with the exact same bottom Z can leave the shelf top inside the divider while its crossing balance is zero; this case is not certified by the inspector. Open upward sheets can similarly offset a surrounding shell's balance, while mixed open/downward sheets can cause conservative false rejection. Touching dividers whose bottom equals the shelf support Z are blocked directly, and overlapping closed panels with distinct crossing heights are covered by a regression fixture. Future exact object-fit/collision qualification needs identified, validated solid colliders rather than inference from these triangle-soup rays.

Geometry outside the captured mesh is absent. Closed doors, insertion paths, front/back direction, material strength, actual thickness, gravity stability, accessory contact polygons, collision volumes and semantic categories are not inferred. No sampled region should be marketed as an exact placement/cavity/stability certificate. A later placement system needs explicit asset metadata, footprint containment, full 3D collision checks and a support graph.

## Verification

The native executable has thirteen independent fixture suites: known box top/area, three shelf heights and undersides, half-covered support, a corner-only blocker, a ring hole and disconnected/diagonal islands, missing corner support and height steps, shallow slope, mirrored winding and baked nonuniform scale, thin cover and nearest-hit ordering, coincident divider bottoms and distinct-height closed-shell overlap with open-sheet controls, invalid/degenerate input, invalid settings, all budget families, translated frames and unused vertices. Tests use known analytic coordinates/areas rather than calling the implementation to derive expectations.

Run from `CyrusArrange/`:

```powershell
python tools/build.py --core-only --output build/core-check-unique
```

The final frozen Max 2027 build compiled with MSVC 19.38 and passed all thirteen suites. The matching UI/native pair also passed the bounded Max host campaign. See [exact qualification and remaining limits](QUALIFICATION.md); these fixtures do not establish general imported-asset or production-performance qualification.
