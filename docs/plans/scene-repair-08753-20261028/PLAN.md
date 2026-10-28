# Source workflow, scale and large interaction scenes — 0.87.5.3

The user authorizes investigation, implementation and Max 2027 testing against
`Test Scene/New Plants test 22.max`, selecting 0.87.5.3. Preserve the original
scene, artist profiles and preceding Library/Scene preset implementation.

## Task list and acceptance

- [x] Reproduce the supplied saved setup and record source/instance transforms,
  units, counts, displayed geometry and actual error boundaries.
- [x] Unify Models & Points and Interactions source membership. Remove stale or
  empty rows, support remove/replace without an extra Add operation, and avoid
  consuming pending Manual placement edits through an unrelated UI read.
- [x] Make supported source-node scaling, generated source scale, prepared plant
  and collider frames agree. Keep scale dimensionless and units explicit.
- [x] Permit supported model-scale changes after Cyrus Edit while retaining the
  authored deltas and unaffected source histories; preserve invalidity guards.
- [x] Remove eager full-render-mesh admission from lightweight viewport updates;
  keep actual exact render/Bake construction bounded and report failures honestly.
- [x] Measure dense stone contacts and warm Mesh/Textured mesh orbit. Implement
  justified work reduction while retaining explicit density/geometry controls.
- [x] Test live movement, empty/remove/replace, scale/Edit, Undo/Redo, save/reopen,
  failure retention and Library regression on the final matched package.
- [x] Update guidance/evidence and deliver a verified Max 2027 MZP.

## Ownership and failure boundaries

F01, F03–F11 apply. Source membership is authored once; UI lists view that record.
Published Manual placements are distinct from pending settings. Source geometry,
preparation and collider data are immutable cached snapshots; scale is resolved
at an explicit source/placement frame boundary. Derived render/view data must not
hold scene APIs in workers or invalidate accepted poses because a hypothetical
combined render allocation would be large. Render output must retain all admitted
visible polygons and maps, with bounded construction chunks and retained source
lifetimes. No silent plant-count reduction or removal of failed bends.

All mutations are staged before publication; failures retain the previous
complete output and authored records. Derived caches add no Undo entries. Normal
source settings and Edit deltas preserve meaningful Undo. Exact resource peaks,
new persistent fields/version implications and renderer support are recorded as
the implementation is selected and measured. This is a synchronous rooted-contact
tool; it does not become a stateful physical simulator.

## Selected implementation

Source changes bind canonical authored row IDs in both panels; missing rows stay
removable. Manual source membership retains the prior complete publication until
Update. Replacing geometry clears only that row's incompatible preparation and
custom collider reference inside the same Undo operation. A truly empty numeric
cohort is admitted without discarding its authored Collider role.

Native candidate transforms multiply the source node's positive unsheared axis
scales and the Models Scale once. Position/rotation of a source remain excluded;
its pivot-local mesh, prepared guides and collider share the resulting instance
transform. Interactions retains its positive uniform similarity requirement.
Typed source binding allows only the per-model Scale revision and retains edited
identities/deltas. Genuine geometry/recipe incompatibilities remain guarded.

The exact render output publishes source/pose references and a bounded sorted
instance index, without preflighting a combined full render allocation. It uses
Max's public NumberOfRenderMeshes / GetMultipleRenderMesh / transform callbacks,
verified against local Max2027 object.h:3961–3996 and the
[Autodesk API contract](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_geom_object.html).
Construction targets128MiB per batch and retains the1GiB/20M-element hard
per-batch boundary. RenderBegin pins a complete snapshot through RenderEnd.
Returned meshes belong to the renderer; the construction reservation is not a
claim about renderer-owned memory/RSS. Single-mesh callers retain the explicit
combined-construction bound; Bake emits complete bounded batches with an admitted
4096-node limit and pre-reserved rollback tracking. No render quality reduction.

The selected version is the user's0.87.5.3, managed0.87.5.3, Interactions13,
Edit capability4/storage3, source-transform capability2 and source-command Undo1. Saved scene63,
portable recipe9 and Scene preset metadata1 remain. No new persistent field is
introduced. The existing0=unlimited navigation choice stays authored; the
explicit Fast navigation preset uses the existing finite quota.

[Final delivery and remaining acceptance](DELIVERY_08753.md). This closes the scoped Test22 checklist, not general physics, arbitrary topology, keyed source controllers, external renderers or the broader roadmap. New preparation invalidates shared GPU bindings; required Edit release publication remains, while base/receiver build counters distinguish it from static regeneration.
