# Test Cyrus Arrange with the example scenes

Status: the 0.3.2 producer tests and portable delivery are undergoing qualification.
The final portable paths below are reserved for that delivery; do not substitute
an older installer or an earlier development scene. The [release ledger](GEOMETRY_WORKFLOW_0.3.2.md)
tracks the current acceptance.

## Open and regenerate

1. Install the matching Max 2027 MZP through **Scripting > Run Script**, then
   restart Max yourself. Installing into an already open artist session is not
   part of automated qualification.
2. Keep each scene beside its **maps** folder. Open a working copy and adopt
   the file's millimetre system units when prompted.
3. Select an arrangement named below, then open **Modify > Cyrus Arrange**.
   The receiver and original props are already bound; there is no category step.
4. Turn **Repeat seed** on to keep the seed unchanged while testing.
   Turn it off and press Generate for a fresh variation. Repeatability requires
   the same accepted settings and unchanged inputs; an older saved arrangement
   can adopt the current geometry workflow on its first Generate.
5. Change Copies or Scale, then Generate. Undo restores the complete accepted
   generation. A rejected draft retains the previous result and explains the error.

The road uses Standard materials and Scanline. The imported books, furniture
and real models retain their original Corona materials; their renderer plugin
is needed for their original appearance. Geometry checks and preview images
have separate scopes in the scenario reports.

## Four practical examples

| Scene | Select this arrangement | What to try |
| --- | --- | --- |
| [Books and stairs](../examples/geometry-portable-0.3.2/shelves-stairs/CyrusArrange-Shelves-Stairs-032.max) | `SS_Books_Arrangement` | Repeat 100 detailed books across the cabinet levels. Change the random scale range and Generate. |
| Same scene | `SS_Stairs_Arrangement` | Repeat 48 mixed books, fruit and bins on six stair treads. Change the chosen props or their minimum counts. |
| [Curved two-way road](../examples/geometry-portable-0.3.2/cars-road/CyrusArrange-TwoWay-Cars-032.max) | `ROAD_Cyrus_Arrange` | Open Path: three cars each way, opposing headings, lateral offsets/widths and seeded sideways/along variation. |
| [Device and imported tables](../examples/geometry-portable-0.3.2/device-tables/CyrusArrange-Device-Imported-032.max) | `DEVICE_Cabinet_Arrange` | Compare original size with Shrink to fit and inspect the clearance/fit feedback. |
| Same scene | `DEVICE_Table_Arrange_1` or `DEVICE_Table_Arrange_2` | Regenerate complete devices on supplied furniture with their original geometry/materials. |
| [Supplied tables and decor](../examples/geometry-portable-0.3.2/real-models/CyrusArrange-Real-Models.max) | `REAL_Coffee_Arrange` or `REAL_Side_Arrange` | Generate another arrangement of the supplied books, full plant and decor. Choose Quantity for a specific target or Fill for a density target. |

The cabinet/stairs, fruit/bin, road/sedan and appliance are authored test models.
The detailed books, plants/decor and imported tables are complete prepared
models. The book example includes 100 declared map files and the real-model
example 131; copied-file totals are not counts of active material-map objects.

## Understand an unfilled result

Copies is a target. The solver may leave some unfilled when support, height,
collision, permitted scale or its bounded search prevents placement. Select a
prop in Props to see contextual feedback. **Show fit space** displays the tested
space or obstruction. **Use checked size**, when offered, changes the scale draft;
press Generate to apply it.

A plant's pot can fit a narrow top while foliage overhangs it, but the complete
plant still must clear other geometry. An object is never scaled beyond your
allowed range to force a fit. For another scene object to block placement, add
it under **Keep clear > Pick obstacles**.

Min copies reserves part of the total for a selected source. If you reduce total
Copies below the sum of its minimums, lower those values or increase the total.
Protected generated copies also count toward the target. Unprotect them before
asking Generate to rearrange them.

For cars, sideways spread follows the curve's local direction. Narrow lanes,
large offsets, final scale and end clearance can reduce the accepted count.
**Keep inside width** checks the complete footprint, not only the car center.
The supported road case is static and upright on a flat-Z curved road.

See the [user workflow](GEOMETRY_USER_WORKFLOW_0.3.2.md) for every control and the
[book/stair](SHELVES_STAIRS_0.3.2.md), [road](ROAD_SCENE_0.3.2.md),
[device](DEVICE_IMPORTED_0.3.2.md) and [geometry-core](GEOMETRY_PLACEMENT_CORE_0.3.2.md)
reports for calculations and limitations. The solver performs bounded placement;
it does not simulate gravity or guarantee globally optimal packing.
