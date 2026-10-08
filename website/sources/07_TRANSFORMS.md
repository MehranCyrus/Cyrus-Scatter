# 7. Transforms

[Guide contents](README.md)

These settings belong to the **layer** and apply to all its paint sets. Per-model Scale and Z Offset are separate controls in Models & source containers.

## Common controls

| Control | Meaning |
| --- | --- |
| Rotation Z min / max | Random turning around the placement's upright direction, in degrees. New layers start at 0–360 for varied facing. Set both to the same value for consistent facing. |
| Whole scale min / max | Uniform size multiplier that preserves a model's proportions. Both start at 1. Use 0.8–1.2 for modest size variation. |
| Align to normal | Tilts a plant's upright direction to match the receiving surface. Starts on. Turn it off when plants should remain upright independently of ground slope. |
| Keep on surface | Projects random movement back onto the receiver. Starts on. Turning it off can allow moved candidates away from the surface and conflicts with some coverage workflows. |

## Advanced: Per-axis rotation, scale and movement

| Control | Meaning |
| --- | --- |
| Rotation X min / max | Adds tilt around the placement's X axis. Both start at 0. |
| Rotation Y min / max | Adds tilt around the placement's Y axis. Both start at 0. |
| Reset rotation | Sets every random rotation limit to 0, including Z. This removes rotation variation; it does not restore the new-layer 0–360 Z range. |
| Scale X min / max | Changes size independently along X. Both start at 1. |
| Scale Y min / max | Changes size independently along Y. Both start at 1. |
| Scale Z min / max | Changes size independently along Z. Both start at 1. Useful for height variation, but can stretch the model. |
| Reset XYZ scale | Sets all separate-axis scale limits to 1. Keeps the whole-scale setting. |
| Reset whole scale | Sets the uniform scale limits to 1. Keeps the separate-axis scale settings. |
| Movement X min / max | Adds random offset along X, in scene units. Both start at 0. |
| Movement Y min / max | Adds random offset along Y. Both start at 0. |
| Movement Z min / max | Adds random offset along Z. Both start at 0. |
| Reset movement | Sets the movement limits to 0. It does not reset rotation, scale or individual CS Edit changes. |

Changing one end of a range beyond the other brings the other end along so the range remains valid. Rotation fields allow -360 to 360 degrees. Separate-axis scale allows 0.001–100; whole scale allows 0.001–1,000. Ordinary use should stay close to the model's intended size.

Source scale, layer scale and enabled boundary/band scale combine. A model scaled to 2 at its source and 0.5 at the layer returns to its original size before other adjustments. If **Follow Scale** is on for that source, its collision footprint follows the resulting instance scale.

**Example:** for natural grass, leave X/Y tilt modest, vary Z rotation and use a small whole-scale range. For a formal hedge, narrow rotation and size ranges. Use CS Edit for a deliberate change to one particular plant.
