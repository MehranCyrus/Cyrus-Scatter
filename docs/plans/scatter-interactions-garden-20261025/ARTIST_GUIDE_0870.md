# CyrusScatter 0.87.0 — Interactions trial

Max 2027. This is the rooted-contact foundation for artist testing. Use the accompanying delivery receipt for the exact installer, scene and qualification scope. The original `Test Scene/Terraces_Final.max` is preserved.

## Layer workflow

1. Add the receiving surfaces and models normally, then **Update scatter**. Use **Mesh** preview for the clearest contact view.
2. On a stone layer, open **Interactions** and enable **Collider**. Use a closed mesh source; **Advanced → Collider shape → Bounding box proxy** is an explicit conservative alternative.
3. On a plant layer, choose a source and press **Analyze model**. A frozen full-model reference and green guides appear at a published instance of that source. Review its planted roots, stem directions and branch attachments. Library source nodes remain hidden and unchanged.
4. Press **Accept reviewed guides**, then enable **React to colliders**. Each unique source is prepared once and shared by its differently placed, rotated and uniformly scaled instances.
5. Select the controller's **Cyrus Edit** modifier, activate the stone layer and move an individual stone. Nearby plants update; departing plants return to their original shapes. Pending Manual amount/seed changes still wait for **Update scatter**.

Choose one role per layer. Collider shapes remain rigid; two-way deforming colliders are outside this version. Use one separate Cyrus Edit modifier per controller. New copied Edit instances need an ordinary placement Update before they become part of the contact layout.

## Controls

- **Contact gap:** extra clearance, from zero to 10 cm. Zero retains the prepared stem/leaf envelope and its small numerical safety margin. The automatically calculated search bounds do not themselves push plants away.
- **Hide roots under colliders:** hides covered rooted groups, including low rock overhangs within the plant's reach. Moving the stone restores them. Turning this off retains covered groups at rest; uncovered groups still react.
- **Preview leaves / blades:** a stable sample of complete leaves or grass blades. Stem tubes use fewer complete rings. Increasing the value needs Analyze/review again and costs more viewport work. Render and Bake retain all visible original source faces.
- **Refinement stiffness:** Advanced resistance weights for the iterative fallback. The fast contact fit rotates guides while preserving their original curves; those rotations are unaffected by this control.
- **Validate full visible mesh:** a slower independent diagnostic near the colliders. Its report includes intersections, planted-root error and edge strain. The ordinary report checks the complete mesh in double precision; the delivery receipts distinguish actual float output checks.

Viewport face limits still apply. If a tree or plant becomes a box, raise **Viewport & render → Mesh face limit**, including its navigation limit. This is a display allowance; the contact solver retains the prepared geometry. The responsive trial uses 8M idle / 5M navigation faces and the detailed trial 20M / 10M. Both keep the same placements and 5% leaf/blade preparation. Larger allowances cost more drawing work.

## Supported preparation

The tested profiles are ordered tube stems and ordered folded grass blades. The supplied small/bushy grasses, lavender and geranium are exercised in the fixtures. Preparation is geometric inference and requires review. Unsupported topology is rejected; arbitrary plants and authored-guide import are not implied. Renderer proxies need an explicit mesh snapshot before preparation. Collider admission checks closed topology; unusual self-intersecting or poorly conditioned meshes are not separately certified.

Reacting instances and colliders require positive uniform scales, without mirrors or shear. The tree layer in the terrace fixture is rigid. Wind, inertia, tree dynamics, moving/deforming obstacle meshes and two-way plant interaction are future work.

## Performance interpretation

The source template is shared. A spatial index selects old/new collider neighborhoods, covered roots are masked before bending, and only affected poses are replaced. Unchanged source faces and instance streams are retained. Explicit resource limits reject a successor while preserving the preceding complete result.

Large scene count and local contact density are different costs. The campaign records command time, contact fitting, preview preparation, synchronous redraw, affected counts and process memory separately. None of those figures is a presented-FPS guarantee. Use the dense foreground to stress contact work and the complete terraces to stress placement/index scale.

## Output and persistence

Prepared definitions and authored settings are saved in schema 60 Max scenes. Schema 59 opens with Interactions off; save upgraded scenes as new copies. Guide/model review objects and private render outputs are temporary and rebuilt when needed. Rendering combines unchanged instances with full-quality posed source meshes; Bake uses the same full-mesh construction. Keep a saved scene copy for these trials. Recipe export currently rejects stored prepared definitions or active contact roles instead of silently omitting them.

The trial has 12,416 reacting plants, ten rigid tree instances and three stones. Eight plant populations share four prepared assets: small grass, bushy grass, lavender and geranium. One supplied closed boulder component is reused at three sizes. Source materials in this derived scene use diagnostic colours; the original asset files and architecture are preserved. Use the controller's stone layer and its Cyrus Edit modifier to move the selected hero stone. The original static foreground rock is hidden in the trial copy so it cannot be mistaken for the interactive stone.

For the supplied scene, run **Trials/Select_Test_Stone.ms** through **Scripting > Run Script** after opening it. This optional helper selects the hero stone and limits Edit markers to the three stones. It does not load a scene, change placements or consume pending Manual population edits. Edit visibility is transient and may need selecting again after a full refresh or reopen. The detailed scene's higher display allowance is recommended for checking the tree and foliage.

The separate final session passes command Undo/Redo and both smaller-stone checks. Physical Undo/Redo without concurrent input, strong-bend appearance and gap preferences remain artist checks. Strong bending can distort stems; the full-mesh report is diagnostic, not a guarantee of natural deformation.

Install only the matching Max 2027 package through **Scripting → Run Script**, then restart Max. Installing and restarting the artist session are left to the user.
