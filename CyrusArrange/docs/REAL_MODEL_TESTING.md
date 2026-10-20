# Prepared real model tests

Final delivery status is tracked in [the 0.3.1 contract](REAL_WORLD_0.3.1.md).
This document explains the test design. A passed earlier development scene is
not acceptance for a later native/script pair.

**Physical, saved-scene readback, rendering and installer qualification passed.**
The final physical07 producer passed 432 checks with normal Max exit and
independent actual-geometry verification. The first complete-plant run had 393 passes
and eight UV-oracle failures. Raw Max exports subsequently proved all 750,204
authored plant mapping corners exact: originally unmapped pot parts receive
valid SDK-added faces. The corrected map/material prerequisites then passed in
a 409-pass development run with two support-area failures on one fresh side
variation and its repeat. A retained actual witness resolved that discrepancy:
the fixture's square-buffer test demanded more clearance at diagonal edges
than the native Euclidean margin. Neither development run is package
qualification. The corrected final fixture retains a deterministic witness
regression. The separate final matching-pair readback/render host also passed;
its exact unchanged scene and three original images are in the release record.

The earlier development render identified `Decor_Set_01_Part_033` as a table
lamp. Its geometric passes remain historical evidence and do not establish
plant coverage. A separate original-material Corona selection probe then
visually confirmed the complete pot, branches and autumnal foliage in
`Decor_Set_01_Group_006`. That probe passed 9 checks, preserving the original
model, metadata, maps and artist-profile files. It did not run the arrangement
solver or qualify the corrected final scene.

The probe's collection and group close-up images are retained under
`build/plant-selection-031-01/host/`, alongside its receipt and material/class
diagnostics. The earlier saved-scene images under
`build/render-saved-031-01/host/` are diagnostic: they show the rejected lamp
and the unsupported original studio-key shadow setting.

## Inputs and preparation

The test uses five prepared Corona `.max` files from the user's organized
library: Coffee_Table_04, Side_Table_01, Books_01, Decor_Set_01 and Decor_Vases_01.
Two individual flat books and the three members of the verified plant group
are selected from their collections. The complete plant is registered as one
reusable asset, `Decor_Set_01_Complete_Plant`; its original Part030, Part031 and
Part032 geometry is kept together. Together with the vase set, these are four
prop variants and two furniture targets. The library and original downloads
remain unchanged. Exact model, metadata and map hashes are embedded in the
fixture input manifest.

The owned scene uses millimetres. Source centimetre scenes are merged with unit
conversion enabled; literal independently recorded physical bounds verify the
result. Collections are ungrouped only in the working scene; the three verified
plant members are regrouped there as one source. Their world vertices,
topology, UVs and material bindings are checked through that operation.
Furniture and selected props are translated and renamed, without resizing,
collapsing, decimating or replacing their meshes or source shaders. Native asset
scales are fixed to 1, with upright quarter-turn yaw options and stacking disabled.

Source material graphs must contain no Missing or V-Ray stand-ins. The copied
map inventory contains 131 byte-identical dependencies. This includes extra
maps from the supplied source collections; some are not used by the selected
pieces. Original prop sources remain in a separate hidden source layer, allowing
the native catalog to retain source appearance and regenerate output.

## Polygon counts and evaluated triangles

The organized library's preparation tool recorded `getPolygonCount`, which
reports the object's polygon representation. These counts are compared with
that same API after merge. They are not compared to `snapshotAsMesh.numfaces`.
For example, the coffee table has 70 source polygons and 140 evaluated triangles;
each selected book has 1,336 source polygons and 2,672 evaluated triangles.
The complete plant's measured envelope is **488.401 × 499.938 × 528.660 mm**.
Its three original members have these independently recorded counts:

| Original plant member | Source vertices | Source polygons | Evaluated triangles |
| --- | ---: | ---: | ---: |
| Decor_Set_01_Part_030 | 36,389 | 33,058 | 62,517 |
| Decor_Set_01_Part_031 | 3,122 | 3,120 | 6,240 |
| Decor_Set_01_Part_032 | 1,442 | 1,440 | 2,880 |
| Complete group | **40,953** | **37,618** | **71,637** |

These counts describe the original source, actual selection-probe snapshots
and the generated complete plant in the passed final physical07 scene.

Actual world-space source and output vertices and triangle indices are exported
to CSV. Each output's asset ID links it to its registered source. The separate
Python verifier reads this data without importing the plugin's solver, geometry
library or MAXScript test functions. It recomputes rigid source-to-output
correspondence, dimensions, support coverage and conservative collisions. A
group source uses its actual geometry leaves in native node-handle order:
vertices are concatenated and triangle indices receive their corresponding
vertex offsets. The group helper's bounding box is not a geometry oracle.

## Physical oracles

All numerical checks operate on actual evaluated world meshes, in millimetres.
The source tables have upward-facing, near-horizontal top triangles. The host
checks pairwise overlap; the independent Python verifier additionally bounds
the sum of pairwise duplicate area to 0.02 mm². True projected boundary edges
are extracted from exact endpoints: internal edges must occur twice with
opposite orientation, and every boundary vertex must have degree two.

Each accepted prop's complete actual world bounding rectangle is clipped
against those top triangles without expansion. Covered area must equal the
footprint area within the published measurement allowance. A separate minimum
segment-distance calculation requires 10 mm Euclidean clearance to the true
exterior and hole boundaries. An enclosed hole or crossing boundary gives zero
clearance. Double arrays preserve calculation precision after the original
float mesh snapshot; they do not recover precision absent from that snapshot.

The prop's actual minimum height must coincide with the tabletop. A separate
triangle-versus-box separating-axis test rejects furniture surface crossings
inside the output's conservative envelope. Pairwise envelope distance must
retain 15 mm spacing. The Python verifier additionally proves that each table
ends at its tested top height and that other furniture AABBs are disjoint from
each output, closing closed-solid containment concerns for these particular
two tables. This is not a general solid-containment oracle.

Every output vertex must match its registered source after the recorded rigid
translation and yaw, with scale 1. For the plant, this comparison retains each
original leaf's identity and vertex/face offsets. Triangle indices, smoothing
groups, supported mapping vertices/faces and the original assigned material
leaves are checked per part. Originally authored mapping arrays and face indices
remain exact. The originally unmapped pot leaves may receive SDK-added faces
only with valid indices; they require the inspected zero-anisotropy Corona
material and no assigned texture submaps. An empty source material slot requires
identical root material and unchanged face ID, rather than undefined-to-undefined
leaf equality alone. Exact complete source snapshots also check that
native operations preserve all three originals. These checks distinguish
preserving a source from merely producing a plausible bounding box.

| Check | Tolerance or rule |
| --- | --- |
| Source/output vertex correspondence | 0.03 mm |
| Physical dimensions | 0.04 mm |
| Contact height | 0.03 mm |
| Top triangle plane | 0.02 mm |
| Collision interior shrink for contact | 0.03 mm |
| Support area | greater of 0.05 mm² and 0.000001 times area |
| Edge margin | 10 mm Euclidean, with 0.03 mm world-measurement allowance |
| Prop spacing | 15 mm, with 0.03 mm numeric allowance |

The test repeats a fixed seed, generates and repeats a fresh native seed, moves
the setup icons without moving furniture/output, and saves/reopens the scene.
It verifies actual geometry and complete logical poses again. Authored category
limits are three books, one plant group and one vase set on the coffee table,
and one vase set on the side table. Amount is a density target. The larger
complete-plant footprint is included in the new coffee amount calculation.

Side seed **412004** is an explicit regression before restoring the artist
composition. The retained actual diagnostic witness has full footprint support
and 11.7468387 mm nearest-edge distance, while the old square-buffer test loses
3.4634045 mm² at a curved boundary. A square border demands more corner clearance
than the solver's Euclidean contract. The final fixture checks this known case
and its repeat; it does not filter random seeds or change native margins. Every
physical stage logs the actual complete saved settings, including its Int64 seed.

Let `U` be the intended top's measured usable area and `M` the mean source slot
area. With equal source/category weights, scale 1 and 15 mm spacing, each slot
is `(sqrt(full source bounds width × depth) + 15)²`. For Natural style and empty
space 0.2, the requested count is `ceil(U × Amount × 0.8 / M)`. The amount
interval for five slots is `(4M / (0.8U), 5M / (0.8U)]`. The fixture chooses its
midpoint and checks the actual float roundtrip. Measured area, mean slot,
interval, chosen amount and native counts are logged. The final physical07
producer requested and placed five coffee-table props with zero underfill;
its independent actual-geometry verification passed. The side table requested
and placed one vase set. See [the release record](RELEASE_VALIDATION_0.3.1.md)
for exact scene and evidence identities.

Fresh-seed generation and exact repeated-seed behavior are tested separately
from the saved artist composition. The saved coffee composition tries explicit
seeds starting at 412031, with at most 32 trials. Every trial records its seed,
requested/accepted/unfilled counts and distinct source count. A chosen state
must contain five actual placements using all four sources, so both book
variants, the complete plant and the vase set occur. Output poses are never
hand-adjusted. The side composition uses 412032. The chosen states must then
repeat exactly. Any unsuccessful bounded search fails the fixture.

Native result rows are `#(requested, accepted, kept, candidates, underfilled,
warnings)`: underfilled is field **5**. Actual requested and accepted counts are
reported separately, including honest fit or category shortages.

## Appearance and limits

Final appearance testing uses a byte-identical relocated copy of the passed
physical scene, renders its three saved cameras, and repeats complete geometry,
pose, material and texture-resolution readback. It does not regenerate the
arrangement or save over the producer scene. The separate full-fixture render
wrapper remains available as development tooling. Source
materials are retained; only the studio floor, lights and cameras are authored.
The selection probe proved the installed `CoronaShadows` constructor and its
assignment to a native light. The corrected studio key uses that generator and
checks its class. Corona documents that an unsupported native-light shadow
mode can make the light fail to render. See the
[Chaos explanation](https://support.chaos.com/hc/en-us/articles/4528318056465-You-need-to-either-set-shadows-to-CoronaShadows-or-disable-them).
The final matching-pair render passed with this lighting correction.
PNG dimensions and hashes are checked, then the images are inspected separately
for the plant's complete pot/foliage, apparent scale, contacts and arrangement.
Numerical success alone does not establish renderer appearance.

These are conservative mesh-envelope placement checks, not rigid-body physics,
mass stability or a guarantee for arbitrary third-party modifiers and render
displacement. Tight valid fits can be rejected. New scene files and maps are
published only after the final matching pair passes its required host and
installation gates. The full qualification records exact source, loaded module,
private-profile and output identities.

## Independent final scene measurements

The root verifier reads actual exported WORLD vertices and triangles, not the
producer's proposed placement boxes. It imports neither the native solver nor
the fixture math. The passed saved scene contains 13 exported source, furniture
and output meshes: 94,207 vertices and 167,614 triangles. Full-size output poses
match original geometry with maximum vertex error below 0.000194 mm. The nearest
saved footprint edge is 14.722694 mm from the true support boundary; the nearest
same-table prop gap is 50.769440 mm. Both exceed the requested 10/15 mm margins.
These measurements describe the saved artist composition, rather than every
possible random variation. Twenty-six analytic checks cover the verifier's
geometry operations.

The immutable preparation snapshot converts some original centimetre bounds to
Float64 millimetres; MAXScript Point3 literals store Float32 components. Every
one of the eight selected parts equals the correctly rounded preparation
components exactly. The independent metadata gate compares those representations
exactly, with no increased geometric tolerance. Sixteen additional positive
and one-ULP-negative checks verify that gate. The initial overly strict
1e-6 mm cross-representation comparison and its diagnostic are preserved.
