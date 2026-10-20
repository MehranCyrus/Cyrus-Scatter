# Imported model fixture credits

These eleven model/map files are original Poly Haven assets provided under CC0-1.0. They are included unchanged for reproducible offline import and placement tests. Author credits are retained voluntarily; Poly Haven and its artists do not endorse Cyrus Arrange.

[Provider asset license policy](https://polyhaven.com/license), [CC0 deed](https://creativecommons.org/publicdomain/zero/1.0/), [CC0 legal code](https://creativecommons.org/publicdomain/zero/1.0/legalcode). License links checked 2026-10-18. The provider's preview renders, logos and website prose are not included.

| Asset | Author | Original asset page |
| --- | --- | --- |
| Modern Wooden Cabinet | Patrik Pangerl | [Source](https://polyhaven.com/a/modern_wooden_cabinet) |
| Wooden Bookshelf Worn | Ulan Cabanilla | [Source](https://polyhaven.com/a/wooden_bookshelf_worn) |
| Standing Picture Frame 02 | James Ray Cock | [Source](https://polyhaven.com/a/standing_picture_frame_02) |
| Ceramic Vase 02 | James Ray Cock | [Source](https://polyhaven.com/a/ceramic_vase_02) |
| Wooden Bowl 02 | Kuutti Siitonen | [Source](https://polyhaven.com/a/wooden_bowl_02) |

`asset-download-manifest.json` pins every original asset relative path, URL, byte count and SHA256. The five FBX files and six 1K maps total5,235,387 bytes. Its original research-only status is historical provenance, not a current test result. `LICENSE_PROVENANCE.json` records the license/source evidence; no API license field is fabricated.

Layout: `assets/<asset-id>/<model.fbx>` and `assets/<asset-id>/textures/<map>`. The test sidecar resolves this directory only from the owned runner's `CA_TEST_ROOT`; it has no absolute-drive or download fallback. Imports use verified copies inside the private output directory. Original files are never resized, remeshed or adapted by copying this fixture.

Catalogue dimensions/triangle counts in the test sidecar are approximate provider metadata. In the vase FBX,5,564 quads triangulate to11,128 faces, differing from the catalogue2,756 count. In the cabinet FBX, two original meshes contain144 points and no polygons; preserve them separately from the three triangle surfaces. This fixture alone establishes no Max/material/renderer/placement qualification.
