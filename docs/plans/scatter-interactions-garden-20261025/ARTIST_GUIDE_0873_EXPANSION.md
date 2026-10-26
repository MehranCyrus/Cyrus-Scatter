# Revised 0.87.3 — preparing more plant models

This revision expands the Interactions preparation workflow. It retains the 0.87.3 label at the user's request. Use the revised installer linked by its delivery report; the earlier Library-only 0.87.3 installer does not contain these changes.

The subsequent [1–100% preview follow-up](PREVIEW_100_0873.md) retains 0.87.3 and requires its own matched MZP. It is compiled and packaged for user testing; the preceding runtime evidence does not qualify that follow-up.

## Prepare a plant

1. Add the model to a Scatter layer and select that layer.
2. In **Interactions**, select the source model and choose **Analyze model**.
3. Inspect the displayed guides, especially the ground roots, the direction of branches and leaf attachments. Geometry inference still requires an artist's review.
4. Choose **Accept reviewed guides**, then enable **React to colliders**. Each unique source needs acceptance; its instances reuse that definition with their own transforms and contact poses.
5. Enable **Collider** on the obstacle layer. Choose **Closed source mesh** for a closed sphere or rock, **Bounding box proxy** for a deliberate coarse approximation, or **Separate trunk / custom mesh** for a tree. Full visual trees remain visible independently of their collision mesh.

The readiness check explains which source needs preparation before enabling React. Failed analysis retains a technical report and reviewable candidate guides, while acceptance remains blocked until the analysis is valid. An unsuccessful successor preserves the last complete interaction result.

## Adjustable preparation limits

Open **Advanced** in Interactions. Limits belong to the selected layer and are saved with the scene. Increase the particular allowance named in an error, then analyze again where requested. These are resource allowances, not quality or speed controls. Higher settings can use more memory and take longer.

| Allowance | New default | Maximum |
|---|---:|---:|
| Source vertices | 2,000,000 | 8,000,000 |
| Source triangles | 4,000,000 | 16,000,000 |
| Connected pieces | 100,000 | 500,000 |
| Prepared guides | 8,192 | 32,768 |
| Preview triangles | 500,000 | 2,000,000 |
| Estimated preparation memory | 2,048 MiB | 16,384 MiB |
| Preparation work | 256 million units | 2,048 million units |

Available system memory and internal representation bounds still apply. Estimated preparation memory does not measure the entire Max process or graphics memory. These controls do not change placement-count limits. Separate custom collider proxies retain their independent 100,000-vertex / 200,000-triangle admission; the guide review overlay samples at most 4,096 guides while preparing the complete admitted definition. Do not raise every value to its maximum by default.

**Branch connection** bounds the inferred attachment reach (default 15 cm, range 1 mm–50 cm). Inspect any long inferred attachment before accepting. This does not alter the source geometry's scale. Some exports separate foliage and stems into disconnected pieces, so increasing this value cannot by itself establish botanical correctness.

**Preview leaves / blades (%)** controls a stable sample of complete components. The preview follow-up allows **1–100%**, retaining the 5% default. At 100%, every leaf/blade component is selected, subject to the existing preview triangle and memory limits; stem tubes still use their coarse preview. If a dense source exceeds its allowance, increase **Preview triangles** or reduce the percentage. After accepting guides, changing this display density reuses the accepted inference. Full visible render and Bake geometry remain independent of the light preview. Full-mesh validation is a separate, slower check.

## Collider and scene checks

- **Build trunk colliders** is intended for tree geometry. A sphere or box should use its closed source mesh or a custom collider; it no longer goes through the trunk fitting heuristic.
- **Review collider** shows the actual collision representation. A small proxy made for the wrong source will leave unexpected gaps or miss contact.
- **Clean unused collider links** removes bindings for sources no longer in the layer. It keeps the scene meshes.
- The **Contact gap** is physical clearance beyond the prepared geometry envelope. Start at zero when diagnosing an unexpected empty margin.
- Minimum stem length and connection distance use physical units; changing display units does not rescale the model. Legacy settings can be converted with **Repair preparation settings**.

Connectivity-based tubes and ordinary triangulated ribbons supplement the earlier ordered profiles. Nonmanifold meshes, ambiguous airborne parts, invalid transforms and genuinely unresolved structures can still require geometry repair or authored guides. This revision does not add wind, self collision, or an exposed-root tree collider generator.
