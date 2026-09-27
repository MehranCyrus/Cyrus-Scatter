# Area falloff and native graph editor — 0.51

In a layer's **Area** rollout, choose **Analyzer Boundary** or select one Area spline in the list. Selecting exactly one spline switches the falloff editor to that line. Each line stores its own settings; selecting several disables the falloff controls to prevent editing an ambiguous target.

- **Delete edge band** removes points within Delete width.
- **Scale ramp** multiplies instance scale over Scale width.
- **Density ramp** thins the existing points over Density width without refilling them.
- Ramps begin after the delete band when it is enabled.
- Include lines affect their inside. Exclude lines affect their outside. Distance and sidedness follow the existing Area world-XY projection. Analyzer Boundary retains its existing distance calculation and uses the full boundary.
- Multiple enabled falloffs apply consecutively: deletion accumulates and scale multipliers multiply. Existing Area Include/Exclude masks still apply first.

**Edit Scale Graph…** and **Edit Density Graph…** open the native 3ds Max CurveControl editor. Drag vertices and use its toolbar to insert points and edit Bezier tangents. X is normalized ramp distance (0 = ramp start, 1 = full ramp width); Y is percent (100 = original scale/full density). Density is clamped to 0–100%. Scale can exceed 100%. Beyond the ramp width, its endpoint value applies.

Curve edits update settings immediately. Exact control-point/tangent data is saved with the scene so reopening the graph preserves the editable shape. The calculation uses 257 samples of that curve. Closing/reopening the graph does not reduce it to a five-point curve.

Restart 3ds Max after installing 0.51 to load the new native Area falloff function. Existing scenes default to no falloff on their Area lines; existing Analyzer Boundary settings are retained.
