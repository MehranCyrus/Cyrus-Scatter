# Decisions and open questions

## Recommended decisions

| Decision | Reason / boundary |
|---|---|
| Name the panel **Interactions** | Supports the present obstacle/react use case and avoids a claim of wind or general dynamic simulation |
| Reuse one prepared definition per unchanged source | Topology analysis is source work; per-copy transforms and contact poses remain separate |
| Native storage/query/solve/publication | Placement-sized computation and lifetimes belong with Scatter's native foundation |
| Directional roles separate from existing spacing | Preserves established independent radius policies and their saved settings |
| Use automatic conservative bounds | Avoids making the artist guess one radius for dissimilar rocks/plants |
| Keep contact gap independent | Enlarging a search bound must not push the plant farther from the visible stone |
| Preserve base placement IDs under cover | Moving a stone can restore the same plant without reseeding/refilling the garden |
| Start tree as an obstacle | The current analyzer does not admit this tree; flexible-tree support is separate |
| Add a real grass preparation profile | Flat blades are not failed round tubes |
| Stage preview/render paths together | Unique bending breaks the assumption of one shared render shape per source |
| Keep wind out of the first delivery | A stateless contact fit has no timestep/inertia/wind model |
| Keep exact proxies visibly labeled | The current sphere cannot qualify surface fitting to supplied rock meshes |

## Decisions still needing experiments

1. **Collider representation.** The supplied rock meshes are very light. Compare their actual admitted mesh-contact path against convex proxies; do not choose a coarse sphere merely because render assets can be large. Resolve open-mesh/solid semantics before root occupancy.
2. **Root cover semantics.** A short anchored root support test is the recommended default candidate. Compare it with receiver projection for sloped/curved ground, low overhangs and floating stones. The fixture's convex XY hull intentionally demonstrates conservative over-clearing.
3. **Pose rendering.** Measure bounded exact shape variants in PFlow against a dedicated adapter. This determines usable active-plant density and full-render memory. Do not promise whole-garden real-time full meshes before this measurement.
4. **Preparation quality.** Inspect both grass sources' blade topology and author ground directions. Diagnose phlox's unresolved components without relaxing attachment thresholds globally. Trees need hierarchy-aware aggregation rather than an arbitrary higher part cap.
5. **Natural tight contact.** Determine a usable surface-refinement scheme and stem deformation method that reduces capsule halo and excessive cross-section strain. Guide-length preservation is insufficient on its own.
6. **Drag quality policy.** Measure light preview fidelity and release validation latency under continuous physical input. Decide the admitted work/memory envelope before setting final defaults.
7. **Cold recovery and portability.** Decide whether accepted rigs/poses are embedded or external cached data, how missing sources behave and what recipes can export. Keep renderer resources/indexes ephemeral.
8. **Other owners and external objects.** Scope first delivery to this Scatter owner. Cross-owner obstacles and ordinary Max nodes require explicit ownership/dependency/Undo/lifetime contracts.

These questions are engineering gates, not requests to delay the authorized investigation. The next implementation should begin at INT0/INT1 with a small stable adapter fixture; the full garden becomes the regression scene as capabilities are qualified.
