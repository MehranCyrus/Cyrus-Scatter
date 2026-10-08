# 3. Source assignment, clusters, bands and rows

[Guide contents](README.md)

Find these controls in **Models & source containers > Advanced > Source assignment — layer**. The arrangement belongs to the layer. Each paint set supplies its own available models and color groups. Changing the selected set does not create a separate layer pattern.

## Source assignment choices

| Choice | Use it for |
| --- | --- |
| Random | Choose among available models using their source weights. This is the simplest starting point. |
| Clusters | Make spatial patches of source color groups. This changes which models occupy different areas; it is not a separate plant-position clustering tool. |
| Line Pattern | Assign models in consecutive bands along selected closed lines. Areas outside the configured assignment bands are not automatically filled by a leftover model group. |
| Analyze Surface | Use an existing Surface Analyzer's boundary, paths or points to guide bands, rows and fixed placements. Create and update the Analyzer before linking it. |

Controls appear for the selected method. A hidden control keeps its value for when you return to that method.

## Clusters

| Control | Meaning |
| --- | --- |
| Size | Spatial size of the color-group patches. Larger values make broader patches. |
| Seed | Changes the assignment pattern. This is separate from Population > Seed, which changes the initial planting layout. Default 42. |
| Roughness % | Adds irregularity to the cluster pattern. Starts at 0. |
| Blur edge % | Mixes source groups around cluster transitions. Starts at 0. |
| Noise % | Introduces more scattered variation in group selection. Starts at 0. |

The three percentages range from 0 to 100. Give sources different color groups first; otherwise a group-based pattern has little useful distinction to show.

## Line Pattern and shared band controls

| Control | Meaning |
| --- | --- |
| Paths | Selects the linked closed line whose bands you are editing. |
| Add: pick closed line | Links a suitable closed spline. It does not turn that spline into the ground surface. |
| Remove path | Unlinks the selected path and its related assignment settings, keeping the original scene spline. In Analyzer mode the caption becomes Remove Analyzer. |
| Consecutive strokes | Selects one assignment band or row to edit. These are pattern bands, separate from the freehand Brush history. |
| Add Outside / Add Inside | Adds a band on the corresponding side of the selected closed line. Consecutive widths build outward or inward from that boundary. |
| Remove Stroke | Removes the selected assignment band and its settings. |
| Width | Sets the selected band's thickness. The meaning changes to Spacing for an Edge Border row. |
| Assign by: Color groups | Lets the band use models from selected color groups. |
| Assign by: Source objects | Lets the band use specifically selected models. |
| Source/group choices | Select the models or groups allowed for this band. Choices must exist in the paint set being used. |
| Scale min / Scale max | Adds a size range for this band. Both start at 1. The values combine with source and layer scale. |
| Refresh sources / groups | Refreshes the choices after editing your source list or groups. It is not the setup's Update now button. |

Select a path and a band before editing its width or choices. A newly added band is only useful when it can choose an available source.

## Analyze Surface: choose the kind of guide

**Pick Surface Analyzer** links an existing Analyzer. **Analyzer data** selects which result you are using:

| Analyzer data | Meaning and add buttons |
| --- | --- |
| Border | Uses the analyzed boundary for inward bands. Add Stroke Inside creates a band. |
| Centerline | Uses the analyzed central paths. Add Stroke creates a band around the path; width is spread to each side. |
| Points | Uses analyzed sample points. Add Radius creates an area around a point; Add Single requests a fixed placement at the point. A Single row has no editable width. |
| Street Side | Uses the part of the boundary identified as facing the street. Add Stroke Inside creates an inward band. |
| Edge Border | Creates a row along the boundary. Add Edge Row adds a row; its Spacing sets the interval between requested row positions. |

These controls use the Analyzer's saved results. Linking it does not replace the Scatter's receiving surface, and drawing an Analyzer guide alone does not create plants.

## Orientation and special row settings

| Control | Where it applies and what it does |
| --- | --- |
| Face outward | Border, Street Side and Edge Border. Orients models outward relative to the boundary. Check the source's Forward axis if the model faces the wrong way. |
| Corner radius / Blend radius | Smooths changes of facing direction around corners when Face outward is on. Edge Border calls this Blend radius. It is not a collision radius or a rounded rectangle edit. |
| Trim start / Trim end | Street Side. Leaves a distance unplanted at each end of the selected street-facing guide. Starts at 0. |
| Straight ends (Street Side) | Uses straight-ended treatment for that street-side pattern. |
| Street offset | Centerline. Moves the guide sideways by a signed distance. It is the same layer offset also exposed by the Analyzer Area controls. |
| Offset inward | Edge Border. Moves the selected row inward from the edge; a negative value goes the other way. |
| Jitter along | Edge Border. Allows variation along the row direction. Zero leaves it regular. |
| Jitter across | Edge Border. Allows sideways variation from the row. Zero keeps that part regular. |
| Keep corner points | Edge Border. Adds corner-preserving positions when a turn meets the chosen threshold. |
| Min turn | The smallest corner angle to preserve, in degrees. Default 45; available when Keep corner points is on. |
| Points/corner | How many corner positions to request. Default 1; allowed values 1–64. |
| Local X / Local Y / Local Z (deg) | Additional rotation of models in the selected Edge Border row. Each starts at 0. |

The layer's area, painting and spacing rules still matter. A guide shows intended organization, not a promise that every requested position will survive those rules.

**Example:** use Edge Border for evenly spaced shrubs around a lawn. Use Centerline for a flower band down its middle. Use separate layers if those plantings need different population, transform or cleanup recipes.
