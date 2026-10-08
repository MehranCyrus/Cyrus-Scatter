# 4. Population

[Guide contents](README.md)

Population belongs to the **layer**. Enabled paint sets divide it according to Share weight. It is not a separate full amount for every paint set.

## Common controls

| Control | Meaning |
| --- | --- |
| Population: Count | Requests a fixed layer amount. Useful when you want a predictable starting budget. |
| Requested count | Starts at 200; range 1–100,000. Restrictions can reduce the final result. |
| Population: Plants per m2 | Derives the request from receiving-surface area rather than entering a fixed count. |
| Plants per m2 | Plants per square metre, regardless of the scene's display units. Starts at 100. The population request is capped at 100,000. Painted coverage and exclusions do not promise to preserve that number inside a smaller area. |
| Seed | Changes the initial random layout. The first layer starts at 42; later new layers receive different starting seeds. Use a non-negative whole number and keep it fixed when comparing other settings. Changing it can require resetting individual CS Edit changes. |

Only the amount field relevant to Count or Plants per m2 is shown. Increasing density cannot force plants through excluded areas or enabled spacing.

## Advanced: Sampling

| Control | Meaning |
| --- | --- |
| Method: Random | Samples the receiving surfaces without a texture-density mask. |
| Method: Texture Density | Uses a density map to decide where sampled plants are permitted. |
| Choose density map | Selects the map. White permits planting; black excludes it; intermediate values thin the planting. It reads the receiver's UV channel 1. |
| Invert density | Reverses the map's light/dark permission. Starts off. |
| Map / UV information | Reminds you that the map needs suitable receiver mapping. A uniform or badly mapped texture may not produce the pattern expected. |

Texture density, Brush and area limits work together. A white pixel does not override an excluded area.

## Advanced: Target and bounded retry

| Control | Meaning |
| --- | --- |
| Candidate budget | The default. Tries the generated population once; rejected plants leave a lower final count. Use it for predictable work and intentional Empty-source gaps. |
| Accepted target | Tries replacements for rejected plants until the target or the attempt limits are reached. It can still finish short. |
| Attempt factor | Limits how many candidates can be tried as a multiple of the request. Default 8; range 1–32. Higher values may help fill difficult areas but cost more work. |
| Max rounds | Limits repeated passes. Default 8; range 1–16. It is not an animation or display refresh setting. |
| Retry cleanup gaps | Allows bounded attempts to replace plants removed by final cleanup. Starts on, but matters when Accepted target is selected. |

The retry fields are unavailable in Candidate budget. There is also a hard attempt ceiling, so multiplying a large request does not permit unlimited work.

The Candidate budget / Accepted target dropdown is labeled **Layer population**. It chooses how to pursue the amount; Count / Plants per m2 chooses how that amount is specified.

Accepted target does not support a positive-weight **Empty** source: that would conflict with an intentional gap. Use Candidate budget, set the Empty weight to zero, or use a Point placeholder when a reserved placement is what you mean.

**Example:** a request for 1,000 trees in a small courtyard may end at 180 after spacing. Accepted target can try other positions; it cannot make 1,000 large trees physically fit. Read the shortfall before raising limits.
