# 8. Spacing and cleanup

[Guide contents](README.md)

Choose **Spacing scope first**. The same fields edit different relationships depending on that choice. Enabling one relationship does not automatically enable the others.

## Choose the relationship

| Spacing scope | What it controls |
| --- | --- |
| This paint set | Separates ordinary plants within the selected set. Initially follows the layer's within-set default. Editing these values gives this set its own rule. |
| Default between sets | The selected layer's ordinary rule between its different sets. A specific pair rule can override it. |
| Pair of paint sets | The relationship between the selected set and another set in the same layer. Choose the other set in Other owner. |
| Pair of layers | The relationship between the selected layer and another layer. Choose the other layer in Other owner. |
| Layer default within sets | The starting within-set rule inherited by sets that have no individual override. |

The three kinds of separation are **within a set, between sets, and between layers**. Pair choices let you refine the latter two. A pair field needs another owner to select; an empty setup cannot supply one.

## Rule fields

| Control | Meaning |
| --- | --- |
| Other owner | Selects the other set or layer for a pair rule. It is unavailable for a default or within-set rule. |
| Enable this spacing | Turns on this particular rule. New layer defaults start off. |
| Radius factor | Multiplies the combined collision radii of the two plants. Default 1. Larger values leave more room. |
| Extra gap | Adds a fixed clearance after the radii. Default 0, in scene units. Useful even when source radii are zero. |
| XY distance (off = 3D) | On measures top-down separation and ignores height. Off measures full spatial distance, so plants at different heights can have more room. Default is off for a fresh rule. |
| Rule information | Tells you whether this set is inheriting or overriding, and whether another owner is needed. |

Spacing uses the combined two radii, multiplied by the factor, plus the gap. For example, radii 0.5 m and 0.3 m, factor 1 and gap 0.2 m ask for 1 m between centres. These are simplified footprints, not exact mesh-on-mesh collision shapes.

Fields **save automatically**. There is no Apply spacing button. In Manual, saved edits still wait for Update now; in Live, relevant changes request an update.

### Advanced: Use inherited / default

**Use inherited / default** removes a selected set override or pair override. A set returns to its layer's within-set default; a set pair returns to the between-set default. A layer pair without a rule has no between-layer separation. On a default scope, this button resets that default to disabled, factor 1 and gap 0.

Earlier layers and sets normally occupy space first. Protected artist edits can remain even if that creates conflicts; inspect their reported conflicts instead of assuming every overlap was removed.

## Advanced: Individual CS Edit radii

These controls belong to the current **paint set's selected CS Edit instances**. They do not change the original source's radius for every instance.

| Control | Meaning |
| --- | --- |
| World radius | Uses a fixed radius in scene units for the selected instances. |
| Radius multiplier | Multiplies their source-based radii. A multiplier of 1 keeps the source size. |
| Value | The radius or multiplier to apply. Entering it alone does not apply anything. |
| Set selected radii | Applies the chosen mode and value to the selected instances. Requires a valid CS Edit selection in this set. |
| Clear selected overrides | Returns selected instances to their inherited source radii. |
| Clear this set's overrides | Removes every individual radius override belonging to the current paint set. |
| Selection / override information | Explains the current edit selection and whether an override can be applied. |

Use a larger override to reserve extra space around a hero tree without enlarging every tree made from the same model.

## Advanced: Candidate Relax — the layer

Relax adjusts proposed ordinary positions before painting restrictions, individual edits and final spacing. It does not replace the three spacing relationships. Fixed anchors stay fixed.

| Control | Meaning |
| --- | --- |
| Point Relax | Tries to spread nearby proposed positions more evenly. Starts off. |
| Desired spacing | The separation it tries to improve toward. Initial value 0.2 scene units; this is not a final guarantee. |
| Iterations | Number of adjustment steps, 1–100; default 10. More steps can cost more time. |
| Strength % | Size of each adjustment, 0–100%; default 50%. |
| Boundary Relax | Smooths neighboring proposed positions with limited movement. Starts off. It does not reshape the receiving mesh or Area splines. |
| Strength | Boundary Relax strength from 0–1; default 0.3. |
| Iterations | Boundary Relax steps, 0–100; default 5. |
| Max movement | Limits how far Boundary Relax may move a position. Default 10 scene units. |

Small, controlled values make comparison easier. More relaxation is not automatically better, and final eligibility checks may still remove a moved candidate.

## Advanced: Cleanup — the layer

Cleanup examines the accepted planting across the layer's sets together. It runs after spacing. Protected artist edits are retained.

| Control | Meaning |
| --- | --- |
| Remove isolated plants | Enables cleanup. Starts off. |
| Neighbor distance | Distance within which plants count as neighbors. Default 100 scene units. |
| Minimum neighbors | Removes unprotected plants that have too few neighbors. Default 2. A value of 0 removes this neighbor-count requirement. |
| Minimum island size | Removes unprotected connected patches that are too small. Default 5. Zero removes this patch-size requirement. |
| XY neighborhoods (off = 3D) | Chooses top-down or full spatial neighbor measurement. Starts on. This choice is separate from the spacing rule's XY checkbox. |

Cleanup can lower the population after spacing. **Population > Accepted target > Retry cleanup gaps** controls whether bounded replacement attempts may follow. It is separate from background fill.

**Example:** keep shrubs apart with source radii and between-layer spacing, then use cleanup to remove tiny grass islands. Do not increase retry limits before checking whether cleanup and spacing are asking for an impossible arrangement.
