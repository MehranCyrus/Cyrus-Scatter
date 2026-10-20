# Geometry/path references for 0.3.2

Checked 18 October 2026. Research informs implementation; it does not qualify
our runtime. All numerical placement work belongs in C++.

- Autodesk's [Max2027 ShapeObject reference](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_shape_object.html)
  exposes curve count, closure, point/tangent interpolation, pieces and length.
  Inspect the installed 2027 SDK declarations before capture implementation.
  Scene shape evaluation and transformations must happen on Max's host thread.
- SideFX's [Resample](https://www.sidefx.com/docs/houdini/nodes/sop/resample.html)
  documents curve-length approximation and sampling. Our design uses copied
  world-millimetre samples and an arc-length table; uniform source parameter
  increments must not be treated as equal world distances. Nonuniform node
  transforms are a reason to measure the copied world curve.
- SideFX's [Copy to Curves](https://www.sidefx.com/docs/houdini/nodes/sop/copytocurves.html)
  distinguishes positions, scale and orientation inputs. The corresponding
  design here keeps path positions, tangent orientation, reverse direction,
  lateral offsets and scale explicit before final physical acceptance.

The proposed local horizontal lateral direction is perpendicular to the path
tangent, not a fixed world X offset. A nearest center-point test alone cannot
prove a complete vehicle stays inside a curved lane; lane acceptance needs the
whole transformed footprint. Closed seams, sharp bends, duplicate samples,
degenerate tangents, jitter ordering and collision after final scaling require
independent numerical tests and actual Max spline fixtures. These are design
requirements, not claims that path placement has been implemented.

For the inline Objects section, Autodesk's
[Max2027 viewport node picking](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Interacting-with-the-3ds-Max/Picking-Scene-Nodes/GUID-CB0EBFC3-9360-445B-BCD4-5F5B2031579F.html)
documents multiple picks, selection behavior and cancellation. A viewport picker
can collect props without opening another settings window or changing the
selected controller. Its return can contain duplicates or a cancellation value;
normalize/cancel before invoking the bounded native intake transaction and
revalidate the captured owner/session after the interaction.
