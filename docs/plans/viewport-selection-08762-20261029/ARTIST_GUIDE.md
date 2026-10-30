# 0.87.6.2 — select geometry and control several Scatters

Install the combined EXE with the selected Max versions closed. It contains separate
2024, 2026 and 2027 payloads. For a matching MZP, use **Scripting > Run Script**, then
restart Max. Existing library content and Surface Analyzer remain separate.

## Find the Scatter in the viewport

In Mesh, Textured mesh or a geometry proxy view, hover the visible object. A yellow
mesh highlight identifies the hovered instance. Click it to select its owning
Scatter controller. Max's object-name feedback uses the controller name.

Viewport draw limits still apply: geometry that is not displayed is not a mesh
selection target. Point Cloud/Centers continue to use the controller icon and Edit
handles. The yellow highlight is sampled for complex meshes to keep it light; this
does not reduce the triangle accuracy of clicking.

## Move an individual instance

Keep the **Cyrus Scatter Edit** modifier. Select its **Instances** level and click
the actual visible stone, plant or other mesh, then use Max's normal Move/Rotate/Scale
tools. The green pivot markers remain available. Rectangle selection retains its
existing marker behavior. Alt and Max's navigation shortcuts are unchanged.

Picking uses the complete displayed result, including prepared bending, hidden
guides and sparse instance edits. It does not change the original source mesh or
recalculate planting merely to find an object.

## Several controllers at once

Select two or more Scatter controllers to open the shared controls, or click
**Viewport & render > Multiple Scatters...**. Choose **Selected Scatters** or the
explicit **All Scatters** scope.

- **Update Scatters** applies pending Manual changes for those controllers.
- **Enable / Disable** controls those Scatter setups.
- **Viewport display**, **Moving triangles**, **Idle triangles** and
  **Show / Hide previews** change their matching display setting.

Only the setting you edit is applied. Different display modes show **Mixed**;
different budgets are noted at the bottom. A shared setting change is undoable.
Changing display budgets does not apply pending Manual planting changes.

Triangle values remain **per controller**, not one combined scene budget. For
example, 500,000 moving triangles across four controllers can allow roughly two
million triangles in total. A value of zero keeps the existing unlimited behavior.

Closing the shared window keeps it closed for the same selection; reopen it with
**Multiple Scatters...** or select a different group.

## Scope

This release changes selection and shared viewport controls. It preserves the
0.87.6.1 contact algorithm and the artist-endorsed Bend/Trim response. Max 2027 is
the runtime qualification host. Max 2024/2026 compatibility is SDK compilation and
package verification only; their viewport/UI behavior needs artist testing.
