# Street layout controls (0.56)

Analyze Surface > Analyzer data > Street Side:
- Trim start / Trim end shorten each connected selected street chain in scene units.
- Direction follows the Analyzer boundary traversal (not screen left/right).
- Intermediate segments remain joined. Trimming beyond total length leaves no street band.
- Closed street loops have no endpoints and are not trimmed.
- Existing Straight/Round stroke end behavior remains in effect.

Center Line (Analyze Data, and Surface Analyzer Area):
- Street offset moves centerline vertices in world XY relative to their nearest
  Street Side segment. Positive = away, negative = toward.
- Zero preserves existing output and does not require Street Side data.
- Nonzero requires Street Side data. Original Analyzer output is not modified.
- Each layer stores its own offset; its Area and Analyze Data controls share it.
- Existing surface restrictions still apply: shifted bands outside the surface
  do not create off-surface scatter points.
- Large negative values can cross the street edge; this is a relative offset,
  not a constraint specifying an exact distance from the street.

Defaults are zero; layer copy, scene persistence and PFlow keys include all controls.
