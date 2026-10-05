# Visual source containers — implementation contract

5 October 2026. Authorized feature; implementation and qualification are tracked in the roadmap. These rectangles select **source models**, while the existing receiving surfaces and Brush/Area masks still determine where generated plants grow.

## Artist behavior

- Create or pick one or more ordinary Rectangle splines as containers. Their labels identify their owning setup, layer or paint set.
- Membership uses the source node's pivot, projected into the rectangle's local XY plane; height does not matter. The border is included with a local tolerance of max(0.0001 system units, half-extent × 0.000001) for host float roundoff. Rotated/scaled/parented rectangles follow their transforms; degenerate transforms fail clearly. Rounded corners and shape modifiers are rejected.
- Global containers supply a shared pool. A layer can choose its own pool; a paint set can explicitly override its layer. Existing manual source lists remain available and existing scenes default to manual behavior.
- Sources are registered persistently. Leaving the rectangle parks a source; it does not remove the row or reset weight, scale, Z offset, color, footprint radius or identity. Reentry restores participation. Settings remain independent in each owner that uses that source.
- Default used while the optional preference remains unanswered: park the inactive model's candidates without redistributing its source weight. Other candidate identities/transforms stay unchanged. Because parked plants no longer block spacing, previously rejected candidates can become accepted; accepted-target mode can also replenish within its existing limits. Exact unchanged accepted membership is only promised where those dependent rules do not change it. Candidate-budget mode can show fewer plants. No unlimited fill promise.
- Merely translating models around their staging rectangle must not translate scattered instances. Membership is a preparation dependency, separate from the stable candidate recipe.
- Manual records changed membership but keeps its completed publication until Update. Live coalesces scene edits. Undo/Redo and reopen reconstruct the same registrations and membership. Deletion is distinct from temporarily moving outside.

## Implementation constraints

Keep source-row identity and active membership separate. Do not compact the registered source list on exit, recreate source IDs on reentry, or silently clear CS Edit/radius binding guards. Adding an entirely new source changes the assignment recipe and must follow the existing explicit binding contract.

Use scene/reference events to mark membership dirty. Reconcile only when those inputs change or a scene is first loaded; ordinary navigation must not scan all scene objects. Exclude the receiving surfaces, scatter controllers, container splines and disposable generated output. Keep native computation and Max scene/reference access on their existing appropriate threads.

## Acceptance scenarios

1. Register two different assets and customize all source settings; move one outside and back. Compare the full surviving row transforms/IDs and restored settings.
2. Global, layer and set scopes; multiple and overlapping rectangles; the same node in different owners with different weights/radii.
3. Boundary pivots, height, rectangle rotation, nonuniform/mirrored scale, parenting and singular transforms.
4. Source/container deletion, replacement, Undo/Redo, copy and save/reopen. Distinguish new enrollment from restored membership.
5. Manual/Live and failed evaluation retain coherent publications and source mappings. Parked edited/cloned plants do not leave blockers; their stored edits are preserved.
6. Navigation and moves that retain identical membership do not rebuild candidate buffers. New membership should reuse the unchanged candidate recipe.

Customer licensing must classify automatic enrollment and membership authoring consistently with the corresponding manual source operations. Implementation/test evidence is recorded in [IMPLEMENTATION_RESULTS.md](IMPLEMENTATION_RESULTS.md); this contract alone is not a test certificate.

## Using the development feature

Enable Procedural 0.7 on the setup. For a shared pool, expand Surface Scatter and create or pick a Global source container. For a layer pool, expand that layer's Source containers section, choose Layer containers, then create or pick a rectangle. Child paint sets can select Layer default, Global containers or their own rectangles.

Move original mesh-convertible model nodes into the rectangle. Customize their registered rows in Plant assets. Live updates after the scene-event batch; Manual retains the last completed result until Update. Move models out to park them and back to restore their source settings. Unlink removes the rectangle reference, not the rectangle or the registered source rows. Removing a registered row is an explicit forget operation; an eligible model still inside a watched rectangle can be enrolled again on a later scene/container change.

Group heads, receiving surfaces, scatter controllers and generated output are excluded; geometry group members remain individual eligible assets. A pool supports 32 rectangles and 1,024 registered rows. There is no height/volume test or arbitrary curved container support in this version. Container rotation/scale and source pivot positions are compared in host precision, with the boundary tolerance above.

Spatial registration scans are O(scene geometry × rectangles) when a pool is first reconciled or its rectangles change. Changed subtrees are queued by node events for new enrollment. Repeated recipe reads compare the small container/source transform state and reuse unchanged membership; they do not rescan scene geometry. Full scans are not an unlimited-scene performance promise.

## Local preview launcher

On this workstation, open `build/user-tests/source-containers-20261005/` in File Explorer and double-click `Launch_Source_Containers.cmd`. The [local guide](../../build/user-tests/source-containers-20261005/README.md) explains the demo. Each launch creates a separate Max 2027 profile with the exact final ordinary script/four DLL hashes, a plane, two source primitives, one rectangle and 64 scattered instances. It opens the Modify panel with the Scatter controller selected; expand **Source containers** between **Procedural / Rules** and **Statistics / help**. The existing installed plugin and other Max processes are not replaced.

The launcher checks payload hashes before starting and actual loaded module paths before loading the script. A fresh private smoke run passed registration, parking and restored count/source identity, then saved the demo and exited normally. The first attempt failed a bootstrap MAXScript class-name binding check before creating the demo; an explicit global declaration fixed that launcher issue. This adds startup/demo evidence, not another full pointer qualification. Files stay in the ignored local test workspace and require this workstation's existing Max/Python installation; this is not a portable installer.
