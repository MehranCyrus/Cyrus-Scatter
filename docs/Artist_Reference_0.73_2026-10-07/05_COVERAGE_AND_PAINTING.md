# 5. Coverage and painting

[Guide contents](README.md)

Coverage and saved Brush strokes belong to the **selected paint set**. Brush needs exactly one shared, static receiving surface. That surface may be flat or curved.

## Paint the allowed area

| Control | Meaning |
| --- | --- |
| Coverage: Whole shared surface | Lets this set use the receiver subject to its other restrictions. Saved paint is retained when you stop using it. |
| Coverage: Painted area | Restricts this set to its saved coverage. New empty coverage allows no ordinary plants until you paint or fill it. |
| Target information | Shows the receiving surface used by the saved paint. A mismatch needs attention; painting on a different receiver is not an automatic transfer. |
| Next stroke: Paint / Erase | Paint adds permission; Erase removes it. This changes the next stroke, not every saved stroke. |
| Radius | The next stroke's size in scene units. A larger value covers more ground. Initial tool value is 20. |
| Strength | How strongly the next stroke paints or erases, from 0–100%. Initial value 100%. |
| Start Brush | Begins painting on the selected set's receiver and creates empty coverage if needed. |
| Stop | Finishes the active Brush interaction and keeps its stroke history. Stop before switching context or using unrelated scene tools. |
| Fill | Fills the coverage and resets the stroke history. Use Undo to recover the previous coverage if this was accidental. Other area and spacing restrictions still apply. |
| Empty | Empties the coverage and resets its stroke history. It does not delete the source models. |
| Brush status | Shows whether the tool is active and reports relevant coverage problems. |

A freehand gesture is stored as an editable stroke. Its painted appearance shows allowed coverage, not a guarantee that plants survive later spacing or cleanup.

## Advanced: Brush feedback and saved history

| Control | Meaning |
| --- | --- |
| Softness | Softens the next stroke's edge. Range 0–100%; initial tool value 50%. |
| Mask % | Thins plants permitted by the coverage. Range 0–100%; starts at 100%. This is separate from the layer's absolute population. |
| Paint feedback: Coverage tint | Shows coverage as a colored surface guide. |
| Paint feedback: Coverage samples | Shows sampled coverage feedback; this is the starting feedback mode. |
| Paint feedback: Off | Hides coverage feedback without deleting coverage or stopping its effect. |
| Color | Changes the coverage guide's color for this set. It does not recolor model materials. |
| Group stroke history | The selected paint set's saved-stroke list. Select a stroke to edit it. Order matters when later strokes paint over or erase earlier ones. “Group” here refers to this set, not a Max object group. |
| Enabled | Enables or disables the selected saved stroke without deleting it. |
| Erase | Changes the selected saved stroke between adding and removing coverage. |
| Saved stroke Radius | Changes the selected stroke's width along its existing path. |
| Saved stroke Strength | Changes that stroke's contribution to coverage. |
| Saved stroke Softness | Changes that stroke's edge. |
| Delete selected stroke | Removes the selected stroke. Undo can restore it. |
| Reset coverage target... | After confirmation, replaces this set's paint with empty coverage on the current receiver. Use it deliberately when changing the painted surface. |

Changing the next-stroke values does not retroactively edit history. To change an old stroke, select it and use the saved-stroke controls. Those controls need an actual selected stroke.

Changing coverage from Painted area to Whole shared surface is a useful comparison: it stops restricting by the saved paint without needing to delete it. **Fill, Empty and Reset coverage target** are different because they replace coverage/history.

## Advanced: Background planting

These controls let a later paint set respond to explicitly selected **earlier sets in the same layer**.

The mode dropdown is labeled **This set: background**.

| Control | Meaning |
| --- | --- |
| Off | No special background relationship. Ordinary area, coverage and spacing rules still apply. |
| Outside painted coverage | Keeps this set outside the earlier sets' covered areas. It excludes the painted area even where no earlier plant survived. |
| Between plants | Uses the earlier accepted plants and an applicable spacing rule to leave room around them. It does not exclude their entire painted area. |
| Outside + between | Applies both restrictions. |
| Earlier paint sets | Selects which preceding sets this background relationship refers to. Select at least one for an active background mode. |
| Apply background | Saves the chosen mode and references together. Unlike automatic spacing fields, this section has an explicit Apply button. |

Between plants requires enabled between-set spacing with a useful radius factor or extra gap. Outside painted coverage needs valid saved coverage for a painted reference; if random movement is used, keep **Keep on surface** enabled. A whole-surface reference can leave little or no outside area.

Background modes do not themselves promise to refill all gaps. Replacement attempts belong to **Population > Accepted target**. Set ordering also matters: a later set cannot be a background reference for an earlier one.

**Example:** paint a curved flower band first. A later grass set using Outside painted coverage leaves the whole flower band clear of grass. Between plants instead allows grass within the band wherever the flower-spacing rules leave room.
