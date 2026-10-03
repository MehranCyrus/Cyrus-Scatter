# Cyrus Scatter 1.1 — plant groups

One Cyrus Scatter object owns the receiving surface. Inside it, Grass, Red flowers, Blue flowers and Yellow flowers are independent **plant groups**. A group's brush paints its coverage; it does not create another scatter layer. Select a group to edit its assets, density, paint history and spacing.

## Install and open

1. Save your work. In **Scripting > Run Script**, run `CyrusScatter-1.1.0-Max2027.mzp` or the matching Max 2026 installer.
2. Restart Max so all four native modules and the script use the same version. Do not file-in the project script over older loaded binaries.
3. Create through **Create > Geometry > Cyrus > Cyrus Scatter**, then use Modify. The main rollout says **Cyrus Scatter 1.1 | Plant groups**.

The supplied `Cyrus_Scatter_1.1_Plant_Groups_Demo.max` is a synthetic **Max 2027** scene with simple stand-in assets. Max 2027 has been tested interactively. Max 2026 has matching SDK builds and passing native tests; its installation and viewport behavior still need testing in an actual Max 2026 application.

## Grass and three painted flower colors

1. **Pick shared surface** once. A plane or a static curved mesh works. Painting currently needs exactly one receiving object per setup.
2. Add the first group, name it **Grass**, and assign grass models in **Plant assets**. Leave **Coverage / Brush > Coverage** on **Whole shared surface**.
3. Add **Red flowers**, assign the red flower model, and choose **Painted area**. The group gets an empty coverage document on the shared surface automatically.
4. Set radius, strength and softness, then **Start Brush**. Paint the receiver. Right-click or press **Stop** when finished. In Manual mode, press **Update** to publish the plants.
5. Add Blue flowers and Yellow flowers the same way. Selecting another group stops the previous brush session. Each group retains independent editable strokes.
6. In **Group spacing / Cleanup**, choose another group, enable **Keep this pair apart**, and enter its distance/gap. Repeat for the pairs you want separated. A pair's rule is shared in both directions.

New setups give the first group priority 0; the next groups start at 99, 98 and 97. Higher priority gets space first. This makes the first group suitable for background grass. You can change these numbers. Equal priorities use persistent creation order. Pair spacing starts disabled until you enable it; the demo has its flower/grass rules enabled.

**Collision / Relax** controls spacing within the selected group. Its collision radius means a minimum centre separation of twice that radius. **Group spacing / Cleanup** controls relationships between different groups.

| Pair distance rule | Meaning |
| --- | --- |
| Centre distance | Require at least the entered distance between plant centres |
| Footprints + gap | Require radius A + radius B + the entered gap; configure source radii in Plant assets |
| XY distance enabled | Ignore height; useful for a ground plan |
| XY distance disabled | Use 3D distance; useful on rounded geometry |

Source footprints are radius approximations. These rules do not test individual leaf/branch intersections and are not surface/geodesic distances.

## Painting remains procedural

- **Paint / Erase** sets the next stroke's operation. Radius, strength and softness control its field.
- **Group stroke history** lets you enable, disable, resize, soften, change strength, change Paint/Erase, or delete a saved stroke. Undo/Redo remains available.
- **Whole shared surface** temporarily bypasses paint but retains its history. Returning to Painted restores it.
- **Fill / Empty** replaces coverage and clears stroke history; Undo restores the previous document.
- **Reset coverage target...** explicitly creates an empty document on the current receiver. It asks before replacing saved paint and is undoable.

Replacing the shared surface or changing its topology does not silently reattach strokes. Restore the original receiver/topology or explicitly reset coverage. Static curved meshes and nonuniform object scale are supported; animated/deforming or multiple painted receivers are outside this version's qualified scope.

## Understand the counts

| What you see | What it counts |
| --- | --- |
| Candidates / plants per m² | Initial distribution across the receiver, before coverage and spacing |
| Placed | Accepted plants after coverage, spacing and cleanup |
| Plant centres | One marker per accepted plant, subject to the display budget |
| Point Cloud | Many source-surface samples per plant; this is not an instance count |
| Shown instances | Mesh/Proxy instances actually displayed within their preview budgets |
| Coverage tint / samples | Painted field feedback, independent of the plant population |
| Removed | Eligible candidates removed by spacing and final cleanup |
| Manual conflicts | Preserved manual overrides that violate a spacing rule |

For a direct count comparison, select **Plant centres** under **Viewport and Render**, then Mesh with sufficient instance/face budgets. A small painted patch does not receive the entire Candidates count: increase the whole-surface candidate density if that patch is too sparse. The existing 100,000-candidate limit per group and 10-group UI limit remain.

Coverage tint appears while Brush is active, in the group's chosen color. It follows the surface and uses darker shades for lower coverage. It is a bounded preview, so very complex or extensive coverage may use reduced detail; this does not reduce the actual saved field or final plants. Coverage samples and Off are available under **Paint feedback**.

## Visibility, updates and manual edits

**Visible in viewport** hides the group and its CS Edit handles; its plants still influence spacing and final output. **Enabled group** removes it from generation, spacing and final output after the next update. Manual mode keeps the last complete planting until Update. Changing Mesh/Proxy/Point Cloud only changes its representation.

Spacing uses actual accepted positions, including CS Edit movement/scale. Edited and cloned plants are preserved; conflicting manual overrides are reported instead of silently deleted. If coverage excludes an edited candidate, its edit remains dormant and returns when that candidate is eligible again. Changing the seed/base distribution can invalidate an Edit binding and produces an explicit error.

Brush-constrained Relax is still paused. Boundary Relax is paused for shared groups. Saved settings are retained; ordinary unpainted point Relax remains available. Removal-only collision and final cleanup are supported.

## Existing scenes

Existing 1.0.1 scenes open with **legacy spacing** to preserve their result. **Upgrade legacy spacing...** opts into the new policy and is one Undo action; survivors can change. Existing CS Edit bindings prevent automatic conversion because remapping them is not yet qualified. Keep such setups in legacy mode rather than resetting artist work.

Save comparisons as separate files. The old 0.64 build is not expected to understand new Brush documents. Analyzer remains 0.14; MCP is optional and unchanged by this release.
