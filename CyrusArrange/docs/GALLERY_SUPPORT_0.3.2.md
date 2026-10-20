# Gallery support regression: 0.3.2

The original release08 gallery failed because its nominal sink-hole test ignored
the modeled 6 mm sink rim. A supplemental owned Max 2027 diagnostic and independent
actual-mesh verification establish that cause. The updated gallery fixture is
adopted into the 189-input release09 freeze; its actual host acceptance is pending.
This record is supplemental evidence, not a qualified 0.3.2 release.

## Observed failure and actual geometry

The unchanged [original gallery result](../build/host-032-release08-gallery-original01/result.txt)
records **48 passes and one failure**, with all five ownership/identity guards
passing. Only the kitchen assertion about complete asset bounding corners and
holes failed. The saved scene contains 15 TV-console, 8 shelf, 3 coffee-table,
4 dining-table and 7 kitchen placements; those counts are observed outputs.

The [supplemental host result](../build/host-032-release08-gallery-mesh-diagnostic01/result.txt)
records **9 passes, zero failures**, exit 0 and all five guards. It loads the exact
saved scene without generation, exports its bound receiver, seven original
sources and seven live outputs, and preserves source names, transforms, material
roots, object count and original scene bytes. It is explicitly a supplemental
probe, not another passed suite in the final 32-host campaign.

The [independent result](../build/host-032-release08-gallery-mesh-diagnostic01/independent-gallery-mesh.json)
uses frozen existing mesh helpers. Actual upward receiver triangles define an
orthogonal cell grid; exterior flood-fill identifies its enclosed void. This
derivation uses actual geometry, without the factory's nominal hole rectangle
or the plugin's stored support footprint as an oracle. The 18 top triangles
leave a **588 × 388 mm** void, area **228,144 mm²**:

| Coordinates | Actual unsupported sink interior |
|---|---|
| World XY, mm | `(5806, 156)` to `(6394, 544)` |
| Relative to kitchen offset `(5600, 350)`, mm | `(206, -194)` to `(794, 194)` |
| Top Z, mm | `935` |

The old test used local `x=200..800, y=-200..200`. Four modeled 6 mm wall tops
occupy the difference. Only **output row 3**, source index **5** (Stoneware bowl,
stable ID `8334904723137038528`), intersects that old nominal rectangle. Its whole
body bounding rectangle intersects **zero area** of the actual void; its actual
base also intersects zero void area, and no body-bounds corner lies outside the L.
Thus this observed failure demonstrates a rim/nominal-hole mismatch. It does not
demonstrate upper-body overhang beyond actual support.

## Independent checks on all seven outputs

The verifier compares every output vertex and triangle topology with its original
source under reported upright yaw, scale and translation. The exported source
anchor supplies the pose reference only. Every scale is 1, topology matches, all
seven bases contact the actual top, and all seven root bases have complete
top-triangle coverage and zero actual sink-void overlap.

| Output row | Source index | Source vertices / faces | Maximum vertex error, mm | Base coverage |
|---|---|---|---|---|
| 1 | 2 | 940 / 1776 | 0.00052505 | 100% |
| 2 | 4 | 416 / 768 | 0.00048924 | 100% |
| 3 | 5 | 288 / 512 | 0.00050331 | 100% |
| 4 | 3 | 250 / 480 | 0.00048850 | 100% |
| 5 | 1 | 32 / 48 | 0 | 100% |
| 6 | 6 | 408 / 768 | 0.00050587 | 100% |
| 7 | 7 | 224 / 384 | 0.00052149 | 100% within numeric roundoff |

The source/pose admission is 0.04 mm; observed error stays below 0.000526 mm.
The referenced 0.5 mm bottom-band hull is independently clipped against actual
support triangles; area agreement uses `max(0.001 mm², base_area × 1e-8)`.
Actual minimum/contact checks use 0.03 mm. These are the supplemental verifier's
criteria, distinct from the maintained fixture's 0.02 mm support allowance.

## Updated maintained gallery oracle

The existing gallery file now reconstructs each actual generated mesh's referenced
lowest 0.5 mm triangle band, projects it into Double XY arrays and constructs its
convex hull. World `snapshotAsMesh` Mesh-value vertices are already evaluated in
world space; no second ObjectTM multiplication is applied. Temporary meshes are
deleted on success and failure. Native contact/region/fit results do not provide
the support footprint.

Coffee/dining retain their analytic and 96-sided outlines; TV/shelf retain the
original broad literal outlines. Kitchen checks the full convex footprint
against the complete L/notch and confirmed actual sink void, including crossings
that vertex-only tests miss. Its original 0.02 mm allowance is applied to
geometric boundaries. All old whole-body predicates remain per-row and aggregate
diagnostics in `gallery-base-support.txt`; existing material, full-size, yaw,
height, deterministic repeat, statistics and native collision settings remain.
Actual mesh minimum must additionally match recorded base height within 0.02 mm.

Read-only oracle controls measure the existing bowl's actual base band and
156 mm upper body. Its centered base must fit a 130 mm board with a 25 mm
admissible gap; a 50 mm shifted base must fail physical board support. Separate
negative polygons cross the L concavity and sink hole while their vertices alone
would pass. Source transform and material root must remain unchanged. These
controls have been adopted; release09 execution is still pending. They are not
new native placement or collision witnesses.

Work limits per mesh are 10,000 vertices, 20,000 faces, 4,096 band points,
100,000 sort comparisons, 256 hull vertices and 512 clipping input vertices.
Invalid references, nonfinite/out-of-range coordinates and missing/degenerate
referenced bases fail. Exactly zero-area primitive faces are counted and skipped;
this permits the factories' axis-fan degeneracies without admitting a degenerate
base. No new maintained file or source-map input was added.

## Evidence identities and limits

The [preparation manifest](../build/gallery-mesh-diagnostic08/manifest.json)
retains its original `prepared-not-run` status; actual execution is established
by the later host receipt and independent result, not by rewriting that manifest.
All hashes below are SHA-256.

| Artifact | Hash |
|---|---|
| [Original saved scene](../build/host-032-release08-gallery-original01/CyrusArrange-Gallery.max) | `53b9b7d8f479b4750552a13034c5f28279344e1bab90c93cafcf5b5983cd6a25` |
| [Original host receipt](../build/host-032-release08-gallery-original01/receipt.json) | `9b5b5eea009d435e34c2a6a3658987f4ae3d41b47682f7ee39fc882612a7304e` |
| [Supplemental host receipt](../build/host-032-release08-gallery-mesh-diagnostic01/receipt.json) | `8b23f2647e4ffba3b3e6a8206c0a2c910ad91eb60b8629f92315052998b77ddb` |
| [Actual mesh export](../build/host-032-release08-gallery-mesh-diagnostic01/kitchen-meshes.txt) | `e05956a891ea2d1768d5ac264dfda0c640bc0beb142dd8298b6b234328a0b6ba` |
| [Independent result](../build/host-032-release08-gallery-mesh-diagnostic01/independent-gallery-mesh.json) | `3514ce0b1cab75b48ec7a34d69ad3ef477eee98841e7819bcba154b261b15d76` |
| [Independent verifier](../build/gallery-mesh-diagnostic08/verify.py) | `d31438320773b03de28e2249c427127eb6210ec0b318cb0ec05cbe505adfc601` |

The host receipt binds diagnostic script `c3f474eaf552fe6f9f7e4859ff49d31e5a1845db53bab54bf491af4d24e87421`,
native `6d93586589dfef666d5da830f69e58d13e1c7ab0c2839f71f87de9e8e0d405e8`
and storage `02885cba9d7d347c6a891f2f83a68605df4341d7f4ea36835c01c0eef2085841`.
The manifest binds the two frozen helper hashes; the independent result binds
that manifest, host receipt, original scene, mesh export and detailed export.

The authored 25 mm edge gap is logged, **not independently proved** by this
supplement. It adds no pair-collision, arbitrary parent-top support, UV/material
fidelity, renderer or render-quality proof. Existing native body checks stay
enabled; the seven independent release geometry proof families remain mandatory
for the final current pair. Fresh release09 gallery/host acceptance, the complete
campaign, isolated performance and package/installed qualification remain separate
gates under the [release policy](RELEASE_POLICY_0.3.2.md).
