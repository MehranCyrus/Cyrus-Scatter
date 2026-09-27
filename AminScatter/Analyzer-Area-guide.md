# Analyzer Area masks (0.54)

Area > Surface Analyzer Area is independent of Diversity / Colors.
Pick an Analyzer and enable Center Line and/or Points.
- Full width: total strip width, half on each side of the centerline.
- Flat: ends stop at the endpoint plane perpendicular to the line.
- Round: a semicircle of half the full width closes each end.
- Points / Radius: disks around the Analyzer sample points.
- Both enabled: union of line strips and disks.

The mask uses world XY, consistent with existing Area Include/Exclude.
It filters the generated positions without changing source assignment, seed,
or surviving transforms. Existing surface and Include/Exclude restrictions
still apply. It does not refill the requested count after filtering.
Boundary Delete/Scale/Density falloff remains independent and runs afterward.
Disabled by default for existing files; missing Analyzer while enabled is an
explicit error. Empty enabled data yields no placements.
Settings are per layer, saved with the scene, and tracked by the PFlow key.
Analyzer re-analysis invalidates the preview in Real-time mode.
