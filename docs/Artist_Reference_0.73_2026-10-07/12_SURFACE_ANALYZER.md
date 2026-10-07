# 12. Surface Analyzer

[Guide contents](README.md)

Surface Analyzer is a separate helper that reads a surface and produces **boundaries, central paths and sample points**. Scatter can use those results for masks and source patterns. Analyzer alone does not scatter your models.

Use planar mesh elements with valid open boundaries. Separate elements may face different directions, but a curved nonplanar element or closed solid is not the same supported input. Brush on curved static ground is a separate Scatter feature.

## Enable and update

| Control | Meaning |
| --- | --- |
| Enable Surface Analyzer | Enables the Analyzer's use/output. It is separate from Enable Cyrus Scatter. |
| Manual | Keeps its current results until Analyze / Update. This is the Analyzer's starting mode. |
| Real-time | Updates after relevant input or setting changes. Idle browsing should not continuously repeat analysis. |

The Analyzer and Scatter have separate update modes. If the Analyzer is Manual, a Live Scatter still needs fresh Analyzer results after the analyzed geometry changes.

## Surface Analysis

| Control | Meaning |
| --- | --- |
| Pick Surface | Picks the mesh to analyze. The source mesh is not reshaped. |
| Path method: Auto | Chooses a schematic path method from the element's shape. It cannot infer every artistic intention. |
| Straight region | Uses a main straight region. Useful for roughly rectangular or elongated areas. |
| Ring | Produces a ring-like arrangement for suitable radial areas. |
| Branched centerline | Produces a branching central guide for more complex shapes. |
| Fit radius | Required clearance from edges and holes for each accepted sample point. New nodes start at 0.5 metres. Zero disables this clearance requirement. |
| Min length | Filters out guide regions that are too short. Default 0. |
| Point radius | Controls separation of sample-point centres. New nodes start at 1 metre. It is independent of Fit radius and does not mean plant collision discs cannot overlap. |
| Min points | Requests a minimum number per element. Default 0 uses ordinary spacing. A positive value can reduce point separation, but cannot override Fit radius or invent space where none fits. |
| Resolution | Detail of the analysis, from 48–768; default 256. More detail can capture smaller features but takes more work. |
| Relax steps | Smooths the guide within its allowed area. Range 0–200; default 20. Zero turns smoothing off. |
| Ring factor | Preferred ring size relative to available central space. Range 0.05–0.95; default 0.65. Fit radius can shrink the usable ring further. |
| Analyze / Update | Explicitly calculates the current Analyzer result. |
| Status | Reports success, failure or a minimum that could not be met. An unsuccessful update can leave the previous result visible. |
| Surface / Region / Path statistics | Shows surface area, the estimated usable region and guide length. Region depends on method and clearance; it is not always the entire surface. |
| Element results | Shows Straight, Ring or Branched results for each element and its point count. An asterisk means point spacing was reduced to pursue Min points. |

The fitted guides are schematic design aids. Narrow features can be missed, and not every branch must receive a sample point.

## Street Side

| Control | Meaning |
| --- | --- |
| Pick Street Line | Chooses the line used to identify the street-facing boundary. |
| Clear Street Line | Removes that link while keeping the line in the scene. |
| Angle limit | How directly an edge must face the street. Zero means directly facing; default 75 degrees permits more variation. |
| Max distance | Maximum street distance for eligible edges. Zero means unlimited. |
| Min width | Requires enough surface width inward from the edge. Zero disables the width test. |
| Curve samples | Detail used along the street curve, from 1–64; default 16. |
| Show Street Side | Shows or hides the saved street-side guide. |
| Analyze / Update | Recalculates the Analyzer, including the street-side result. |
| Create Street Side Spline | Creates a separate spline snapshot of the current street-side guide. |

## Viewport and Output

| Control | Meaning |
| --- | --- |
| Include Street Side | Includes the street-facing segments in the boundary output. It is separate from showing the street guide. |
| Boundary | Shows or hides the boundary guide. |
| Center paths | Shows or hides central paths. |
| Sample points | Shows or hides sample-point markers. |
| Create Boundary Spline | Creates a spline snapshot of the current boundary output. |
| Create Path Spline | Creates a spline snapshot of the current path output. |
| Create Point Helpers | Creates ordinary scene helpers at the saved sample points. |

The exported splines and helpers are **snapshots**, not live links. Analyze again and create new output if you want updated copies. Display toggles show saved information without changing the source surface.

Scatter has three separate ways to link Analyzer information: source assignment, area masks and boundary falloff. Choose the link that matches the job. In particular, Scatter's Analyzer Area masks use top-down XY footprints, even though Analyzer can analyze differently oriented planar elements.
