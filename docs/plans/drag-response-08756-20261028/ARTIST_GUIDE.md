# Responsive bending — 0.87.5.6

Install the complete Max 2027 MZP with **Scripting > Run Script**, then restart
Max. This patch has no Max 2024/2026 package or EXE.

Choose **React to colliders** on the plant layer and prepare its original source
once. Use **Bend** for everyday work. A stone can be an ordinary picked scene
collider, or a scattered collider moved with Cyrus Edit. Both use the same fast
artistic response. Moving a collider should show new results while it moves.

| Control | What it does |
| --- | --- |
| Bend strength | Overall amount of bending. |
| Trunk bend (%) | How much main stems carrying branches may bend. 0 keeps those guides rigid; 100 permits the full bend strength. |
| Fixed base (% height) | Height of the lower region kept still, measured from the source's root level. 30 means the lower 30% of source height. |
| Bend fade (% height) | Height of the smooth transition from fixed to flexible. 30 spreads the transition over 30% of source height. |
| Clearance | Extra distance used for bending near the collider. |
| Hide margin | Extra hiding distance when Hide covered roots is enabled; independent of Clearance. |
| Preview leaves / blades (%) | Amount of prepared foliage shown in the viewport. This is not a solver accuracy control. |

For a rigid tree trunk with flexible branches, start with **Trunk bend 0**.
For a flexible young tree, try **Trunk bend 20**, **Fixed base 30**, and **Bend
fade 30**, then adjust by eye. Changing these controls reuses the prepared source;
there is no need to prepare it again.

Trunk recognition follows the prepared guide hierarchy: root stems with branch
children are treated as structural. It does not identify every botanical trunk
automatically. Use the preparation editor's fixed parts for geometry that must
never deform. Independent grass blades do not become trunks merely because their
roots are planted.

**Trim** hides eligible branch groups. **Bend and trim** bends first and uses an
estimated remaining overlap for trimming. **Trim amount (%)** controls how many
eligible groups are hidden, using a stable selection. Moving the collider away
restores them. These controls are intended for art direction, not exact cutting.

Preparation sizes, work limits and the optional full-mesh check live under
**More settings**. **Detailed contact (slow)** remains an explicit Response
choice, but the trunk/falloff controls apply to the artistic modes.
Older scenes saved with Detailed contact open in Bend in this release. Existing
Bend/Trim choices remain. This is an intentional performance-first change, so
compare the look before saving over an important scene.

The fast path checks coarse guide spans and applies one response. It can leave
overlaps around complex corners or deeply buried roots. It does not repeatedly
validate every leaf triangle. Full geometry, textures and viewport draw limits
still affect navigation cost even when contact calculation is fast.

Save a native `.max` scene or **Scene preset** for the new controls. Portable
recipes retain their earlier Detailed-contact subset and reject broad response
profiles. The original test scene is preserved; test changes were made only in
disposable profiles. See [the delivery](DELIVERY_08756.md) for measured scope.
