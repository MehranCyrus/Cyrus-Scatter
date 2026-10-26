# Contract change request — semantic vertex identity in `EvaluatedMesh`

## Requested smallest shared change

In a coordinated future contract edition, add:

```cpp
std::vector<Id> render_vertex_ids;
std::vector<Id> logical_vertex_ids;
```

to `EvaluatedMesh`, each with the same count and order as `positions`.

## Reason

The frozen v1 evaluator can preserve semantic identity only indirectly by retaining the original `PreparedRibbon` and keeping output order unchanged. `EvaluatedMesh` itself cannot carry the distinction between:

- coincident but intentionally independent render vertices;
- UV/normal seam duplicates sharing one logical vertex;
- vertices with different semantic IDs but identical coordinates.

That is sufficient for this isolated validator because it receives both `PreparedRibbon` and `EvaluatedMesh`, but it is insufficient for a downstream host/Bake handoff that may store or transport the evaluated mesh independently. Coordinates must not become an implicit weld key.

## Required semantics

- `evaluate_ribbon` copies both ID arrays from `PreparedRibbon::bindings` without reordering or deduplication.
- `validate_candidate` requires exact ID arrays and order.
- Duplicate `logical_vertex_ids` remain allowed for seams; duplicate `render_vertex_ids` remain invalid.
- The change does not alter geometry, collision or fitting mathematics.

## Affected tests

- `evaluator.seam_ids_uvs`
- `validator.mesh_correspondence`

The current implementation does **not** alter the frozen header and uses binding order as the v1 association.
