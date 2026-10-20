# Cyrus Arrange large scene lab — 19 October 2026

The test showroom contains **590 generated placements across 15 arrangements**: four libraries, four coffee tables, a side table, a decor-group table, a TV console, stairs, a cabinet, a curved two-way road and a straight plant path. It mixes the prepared real models with original modeled test furniture, a complete appliance and a complete sedan.

Both scene deliveries passed the follow-up save/reopen checks in terminal experiment05. The editable file retains the 15 original accepted arrangements; the viewing copy contains 590 ordinary generated-prop meshes and no native Arrange scene ownership.

## Scene files

- [Plain-mesh viewing scene](../../build/large-scene-lab-20261019-01/runs/experiment05/CyrusArrange-Large-Showroom-ViewOnly.max): generated results converted to ordinary meshes. Use this to inspect the layout without relying on the new Arrange modifier. It cannot regenerate arrangements.
- [Editable scene](../../build/large-scene-lab-20261019-01/runs/experiment05/CyrusArrange-Large-Showroom.max): all 15 native arrangements and their original sources. Requires the matching **0.3.2 development plugin pair/scripts**; your inspected artist profile still uses 0.3.1. This experiment did not install a new version.
- [Original accepted experiment](../../build/large-scene-lab-20261019-01/runs/experiment03/CyrusArrange-Large-Showroom.max): preserved separately with its actual mesh exports and independent geometry evidence.

Use 3ds Max 2027. Materials and the recorded previews use the installed Corona renderer. The viewing scene was prepared and reopened in the private current-build host; opening it under the artist's older Arrange runtime is not an executed compatibility test. Keep the adjacent `maps` folder and the experiment folder in place: assigned map paths were verified there, but this is not a relocation-qualified release example.

## What to inspect

Open a copy of the scene and use the named cameras. The scene is organized by arrangement layer; original prop sources are hidden in `90_Original_Prop_Sources` away from the showroom.

| Area / editable owner | What it demonstrates |
| --- | --- |
| `Arrange_Library_1` … `Arrange_Library_4` | 100 detailed upright books per library, random uniform scale, spacing and shelf support. Library 1 has a protected placement. |
| `Arrange_Coffee_1` … `Arrange_Coffee_4` | Mixed real books/plants/decor, minimum copies, a reserved tray obstacle and Fill available space. |
| `Arrange_Decor_Groups` | Sixteen repeated compound decor groups. |
| `Arrange_Side_Table` | Six props on a small real table. |
| `Arrange_TV_Console` | Twenty-four arbitrary props, screen avoidance and the optional approach control. |
| `Arrange_Stairs` | Seventy-two mixed props on eight treads, with book and fruit minimums. |
| `Arrange_Cabinet_Devices` | Two devices that require permitted uniform shrink fitting. |
| `Arrange_Two_Way_Road` | Twelve full-size cars, six per direction, curved alignment, offsets and seeded spread. |
| `Arrange_Path_Plants` | Fifteen plants using 700 mm center spacing, reverse heading and spread on a supported path. |

With the matching editable build, select an arrangement icon and open **Modify → Cyrus Arrange**. Choose **Repeat seed** before Generate to retain the recorded variation. Leave it off for a new variation. Changes apply through Generate. Keep original sources; do not use generated copies as the source palette.

## Actual renders

- [Showroom overview](../../build/large-scene-lab-20261019-01/runs/experiment03/Showroom-Overview.png)
- [Library detail](../../build/large-scene-lab-20261019-01/runs/experiment03/Library-Detail.png)
- [Curved road](../../build/large-scene-lab-20261019-01/runs/experiment03/Road-Overview.png)
- [Whole scene](../../build/large-scene-lab-20261019-01/runs/experiment03/Whole-Scene.png)

These are actual six-pass Corona renders from the accepted main experiment, not illustrations or image-generation mockups. The follow-up restored the same accepted poses; it did not render a replacement set.

## Reports

- [Findings and next round](FINDINGS_AND_NEXT_ROUND.md): actionable refinements, including the reproduced fit-advice limitation, with suggested acceptance cases.
- [Feature coverage](FEATURE_COVERAGE.md): what was actually exercised, unavailable or outside this scene's scope.
- [Technical results](TECHNICAL_RESULTS.md): counts, timing scope, independent geometry evidence, precise run identity and preservation checks.
- [Delivery manifest](DELIVERY_MANIFEST.json): SHA256 hashes for both scenes, all 131 maps, four previews and the evidence/documents.

The plugin code and the artist installation are unchanged. This is a supplemental scene experiment; the existing 0.3.2 release qualification remains unfinished.
