# Recipe 7 and receiver fields — 0.87.0

This contract describes the implemented delivery. Scoped release acceptance is in
[the reliability ledger](RELIABILITY_0870.md); earlier passing receipts do not
qualify later source or package changes.

Recipe format **7** appends integer `meshMaskSource` to the complete settings
record (262 captured fields). Value 1 selects the existing authored mesh channel;
value 2 selects relative local elevation. The scene parameter is appended to its
existing block, preserving preceding parameter IDs and scene schema 58. The
native surface-density payload appends this value as its eighth argument and
advances `cyrusMeshDensityVersion` to 2. Recipe capability becomes 7. Asset graph
2, package manifest 1, library capability 4 and independent products are retained.

Formats 1–6 are upgraded explicitly. Every settings record gains source 1;
existing channel requirements are preserved. A format-6 record containing the
new field is rejected. Reauthoring the bundled Valley and Mountain examples is
an intentional content revision, not an automatic reinterpretation of user data.

Relative elevation measures evaluated receiver-local vertex Z. Only vertices
referenced by geometry faces determine the minimum and maximum. Low is 0, high
is 1, and flat terrain is 0. Face values interpolate barycentrically and then use
the same input range, inversion and response curve as the numeric-channel field.
Placement and mask preview share this evaluator. No channel or modifier is
created on the receiver. Node translation, rotation, mirror and scale do not
change this local field. Slope and explicit world-altitude filters remain separate.

**Map coordinates** is image coordinate mode 3. Supported texture graphs sample
the receiving node, face, barycentrics, local/world position and declared map
channels at the current frame. The Map picker selects this mode; Image and the
pattern picker select projected World XY. Vertex Color, Color Correction,
Output, Checker, Bitmap, Mix, Noise, RGB Multiply and Gradient are admitted;
unqualified classes and renderer/camera-dependent requirements fail explicitly.
Derivatives are zero and density samples are unfiltered scalar eligibility.
This does not add arbitrary procedural graph serialization to portable packages.

For complete ready presets, Paint contours and saved spline guide positions fit
the admitted source receiver footprint to the destination's local XY footprint.
Brush radius, falloff and path widths convert by system units, independently of
the footprint stretch. Original Paint bytes are immutable. Unsupported folded,
closed or stacked local-XY geometry rejects during preflight. Settings-only Paint
continues to require its exact compatible receiver; the format never discards
coverage to make an incompatible binding appear successful.

No sources is a valid empty population, independent of missing receiver channels
or an oversized retained grid. Adding a source makes those authored dependencies
active again and subject to validation. Actual calculation/import failures keep
the last complete publication. Clear explicitly removes the image rule and its
map, while preserving the separately authored surface-density field.
