# Interactions in 0.87.3.2

Install the matched Max 2027 MZP through **Scripting > Run Script**, then restart Max. Select the Scatter setup and the layer you want to edit.

For plants, choose **React to colliders**. In **Original source model**, use **+** to pick an original scene model. It is added to the same layer's **Models & Points** list. **x** unregisters the highlighted source row and keeps the scene object. **Frame source** shows that original model in the viewport.

Select a source and click **Prepare model** once. Instances reuse that source's prepared guides with their own transforms. **Show source guides** is an optional toggle for inspecting the original model; there is no second acceptance action. Sources prepared by older versions retain their saved definitions, so click **Prepare model** again on the Neottopteris model to adopt this correction.

For a stone or sphere layer, choose **Collider** and **Original closed mesh**. You can use the original sphere directly; assigning it again as a custom collider is unnecessary. Use **Cyrus Scatter Edit** to move individual scattered collider instances. Tree trunks and independently assigned closed colliders retain their existing separate workflows.

The everyday controls are immediately below **Preview leaves / blades (%)**:

| Control | Behavior |
| --- | --- |
| Preview leaves / blades | 1–100% viewport sampling; changing it reuses prepared inference. It does not select which contacting stems are solved. |
| Minimum stem | Changes the inference minimum and automatically prepares already prepared sources in this layer again. |
| Refinement stiffness | Updates contact fitting immediately; it controls refinement rather than adding time-based wind dynamics. |
| Branch connection | Changes the allowed connection reach and automatically prepares existing sources again. |

**Preparation limits** holds geometry, guide, preview, memory and work budgets, along with repair/retry and full-mesh diagnostics. Rejected preparation or contact updates retain the previous complete result. Limits do not silently delete leaves.

**Hide roots inside colliders** hides groups whose fixed roots conflict with the collider/gap. With it disabled, a collider through a fixed root reports a conflict. **Contact gap** adds clearance. A sphere hovering over valid roots should bend the contacting leaves and keep those roots visible.

The Neottopteris Decorative05 correction recognizes 36 broad leaves rooted at an elevated crown, including leaves with drooping tips. Its compact non-ribbon decoration stays fixed. A collider touching that rigid decoration reports a conflict; use a plant-only source if the base should be excluded. Geometry inference remains an approximation, so inspect unfamiliar assets using the guide toggle and **Check full visible mesh**.

The [delivery](DELIVERY_08732.md) records the exact package, saved trial and tested scope. Production-renderer shading, broader species and held-pointer frame rates have separate acceptance from the recorded geometry checks.
