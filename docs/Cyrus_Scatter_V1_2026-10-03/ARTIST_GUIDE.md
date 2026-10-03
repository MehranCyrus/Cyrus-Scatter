# Trying Cyrus Scatter 1.0

## Installation

1. Save your work. Use the current package matching your Max year: `dist/v1/CyrusScatter-1.0.1-Max2027.mzp` or the Max 2026 counterpart.
2. In Max, use **Scripting > Run Script**, choose the MZP, and wait for the Cyrus installation message.
3. Restart Max. The script and four matching native modules must load together. Running only the source `.ms` over an older engine is insufficient for Brush.
4. Open a copy of your scene, or create **Geometry > Cyrus > Cyrus Scatter** and use **Modify**. The included local synthetic demo is useful for learning; it does not require downloaded assets.

Max 2027.1 was tested interactively. The Max 2026 package was built with its own SDK and passed the native suites; it still needs testing in a real Max 2026 application. Existing Analyzer scenes also need the matching Analyzer 0.14 installed. MCP is optional and installed separately; ordinary Scatter and Brush require no MCP connection.

The installer uses `userScripts/CyrusScatter`, a native folder identified by Max year and binary hashes, and Cyrus-named startup/macro files. It retires the previous product-owned startup registrations while keeping old native folders for recovery. Your original scenes and assets are not removed. To revert, run `Uninstall.ms` from `userScripts/CyrusScatter`, close Max, install the prior matching package and restart. Use the scene copy saved before upgrading; do not assume the old engine can read a newly saved Brush scene.

## Layers and controls

Click a row to select a layer. All the other rollouts edit that selected layer; they are ordinary Max rollouts and open with one click. Use **Add**, **Copy** or **Remove** in Layers. Copy initially preserves the same seeded plants, including soft or partial-density edges, with an independent Brush document and a new layer identity; editing one copy does not edit the other.

**Visible in viewport** hides the selected layer's preview immediately while keeping its final population and blocking behavior. **Enabled in final output** disables the layer's placement and final output, and removes it as a blocker. These switches have different purposes.

Rows show the layer name, its last placed count and state. The selected-layer details show placed count, displayed points or instances, and build time. These values come from the cache: browsing the panel does not regenerate a layer.

| State | Meaning |
| --- | --- |
| `OK` | A cached result is available |
| `Stale` | Settings/input changed; use Update for a current preview |
| `Limited` | The preview shows a subset under the configured instance/face budget |
| `Hidden` | Viewport visibility is off; final enablement is independent |
| `Empty` | The built result contains no placements |
| `Off` | The controller, layer or its Analyzer input is disabled |
| `Error` | Preview generation failed; read the details before continuing |
| `--` | No published result yet |

Build milliseconds measure generation/publication work, not viewport FPS. Point Cloud's displayed count is **points**, whereas Mesh/Proxy counts are **instances**. A heavily detailed source may reach the Mesh face budget after only a few instances. Increasing the base Count does not automatically increase the preview budget.

In **Randomize XYZ**, each group has a Reset button. Rotation and movement reset to zero; XYZ scale and Whole Scale reset to 1 independently. The older tilt/yaw, scale and movement ranges are reset with their corresponding group. Each click affects only the selected layer and supports one Undo/Redo action. Align to normal and Keep on surface are preserved.

## Procedural Brush

1. Add/select a layer and assign source plants in **Source Object**. Choose the base count/density and randomization in **Point Generation** and the other layer rollouts.
2. Open **Procedural Brush** and pick one receiving surface. A plane, sphere or other static mesh is supported. This target overrides the shared receiving-surface list for this layer.
3. Keep **Use painted density** checked. A new document starts empty. Use **Paint** to add coverage, **Erase** to reduce it, or **Fill** to begin with the whole surface covered.
4. Set world-space **Radius**, **Strength %** and **Softness %**. **Density %** thins the layer's stable base population; change Count or plants/m² for more potential plants.
5. Click **Start Brush**, then drag on the receiving surface. The native Max cursor follows the surface. The bounded density-dot overlay is an aid to coverage, not a UV texture or a count of all plants.
6. Right-click in the viewport or click **Stop**. In **Manual** mode, mask/history changes are immediate; click **Update now** to publish plants. Real-time mode publishes committed revisions through the normal deferred update path.
7. Select an earlier stroke to change its enablement, Paint/Erase mode, radius, strength or softness, or delete it. Max Undo/Redo restores document changes. Fill/Empty clear the history and are undoable.

Surviving candidates retain their transforms when density or strokes thin the layer. CS Edit changes on a temporarily masked candidate are dormant and return when that candidate returns. Changing the underlying population/seed can invalidate an Edit binding and requires its normal Reset; paint changes alone do not substitute compacted row positions for identities.

Keep the target visible and unfrozen while painting. It may be hidden for final evaluation. Saved strokes use surface anchors and captured stroke paths rather than a UV image. A changed shape/topology is rejected with history preserved: restore the original target or intentionally create a fresh Brush document. This release does not automatically transfer strokes onto a remeshed or animated surface.

In 1.0.1, painted density **pauses** Relax and Boundary Relax while keeping their stored settings. The controls and Layers details explain the pause. Turn off **Use painted density** to use Relax; your strokes remain saved. This prevents the v1.0.0 runtime error without moving plants out of the painted field. Collision removal and final cleanup remain available. A solver that relaxes points inside the painted field is future work. Unprojected random movement with Brush remains unsupported.

### Known preview and spacing limitations

Brush's coverage dots are independent surface samples, so they can greatly outnumber actual plants. Point Cloud also draws multiple points per plant. To compare with Mesh, use placement centres and the cached **Placed** versus **Preview instances** counts after Update. Check Mesh instance/face limits if the latter is smaller. The [current diagnosis](../Artist_Zones_Integration_2026-10-03/PLANTING_GROUPS_REVIEW.md) reproduces these differences on a plane and sphere.

Within-layer collision currently runs before painted membership. Cross-layer blocking uses intermediate placements before the blocker's own cross-layer removal, final cleanup and CS Edit. Consequently, a removed or moved plant can still reserve its old space, and mutually blocking layers can both lose plants. These are known limitations of the current policy. The planned shared plant-group workflow and accepted-placement spacing are not in 1.0.1 yet.

## First artist checks

Try layer switching and native rollout opening first, then visibility and preview modes in a copy of your original scene. Paint and erase on a small plane and curved object, edit an old stroke, Undo/Redo, and save/reopen. Check a render with your actual renderer. Record the package, source complexity, placed/displayed counts and any failing steps; a new UI is not a qualification of every renderer or asset type.
