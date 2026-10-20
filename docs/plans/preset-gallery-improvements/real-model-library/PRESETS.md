# Real-model preset catalog

**24 proposed presets · eight pilots · no new presets qualified yet**

[Guideline](README.md) · [Roadmap](ROADMAP.md) · [Validation](VALIDATION.md) ·
[Execution status](../../improvement-program/PROGRESS.md#real-model-library-planning)

RP identifiers are stable planning references. Assign actual recipe UUIDs through
the supported workflow during implementation and record that mapping in the
delivery manifest. Names describe artistic compositions, not verified ecological
communities. Use actual catalog asset titles when recording source selections.

## Pilot selection

**RP01, RP05, RP08, RP12, RP16, RP19, RP22 and RP24** form the first delivery gate.
They cover leaf opacity, grass shaders, flowers, Corona proxies, large trees,
ordered layouts, multiple layers and deliberate physical scale. Work can proceed
on unblocked pilots while another adapter is being investigated; all eight must
qualify before declaring the pilot milestone complete.

## Leaves and ground detail

| ID | Preset | Proposed source selection | Distinct result | Pilot |
| --- | --- | --- | --- | --- |
| RP01 | Dry Leaf Litter | Dry Broadleaf Beige; Weathered Perforated; Curled Dry Brown; Bulut Leaf 21 | Open ground with irregular small dry leaves and restrained overlap | Yes |
| RP02 | Autumn Sycamore Cover | Rust, mottled, yellow and autumn Sycamore cutouts | Broad seasonal cover with deliberate color balance | No |
| RP03 | Windblown Leaf Drifts | Selected dry 3D and bent leaves | Concentrated strips/patches separated by clear ground; authored distribution, not a wind simulation | No |
| RP04 | Mixed Curled Leaves | Bent Leaf 00–20 plus selected 3D leaves | Rich shape variation and overlapping surface detail | No |

Check contact, opacity from both sides and silhouette at grazing angles. Alpha
cards can reveal flat geometry in close views; identify intended viewing distance.
Keep density and size appropriate to the chosen species/appearance rather than
inheriting every leaf's prepared 20 cm normalization. Avoid interpenetration that
looks like hovering stacks. Bent leaves need explicit Forest-map handling.

## Grass and flowering groundcover

| ID | Preset | Proposed source selection | Distinct result | Pilot |
| --- | --- | --- | --- | --- |
| RP05 | Sparse Grass Clumps | Grass Small Clump; Grass Bushy Clump | Separate tufts with usable negative space | Yes |
| RP06 | Clover Carpet | Clover Patch 04 | Continuous low groundcover at a controlled cost | No |
| RP07 | Clover and Grass Mix | Clover Patch 04; both grass clumps | Low cover with occasional taller grass accents | No |
| RP08 | Violet Patches | Common Blue Violet 04/05 | Flowering islands with clear gaps | Yes |
| RP09 | Creeping Phlox Carpet | Creeping Phlox 01/02 | A continuous flowering bed with varied patch shapes | No |
| RP10 | Mixed Flowering Groundcover | Violet; Phlox; Herb Robert Geranium 04; Spotted Deadnettle 04 | Balanced small flowering groups with deliberate height/color variation | No |

Use physical density and source footprint to establish defaults. Inspect a close
view for gaps and intersections as well as a wider composition. A sparse preset
must retain intentional gaps instead of filling all available surface. The grass
sources include Forest shader dependencies in the prepared records.

## Strappy plants and shrubs

| ID | Preset | Proposed source selection | Distinct result | Pilot |
| --- | --- | --- | --- | --- |
| RP11 | Strappy Groundcover | Arthropodium 01/03/04/05 | Loose groups with distinct leaf silhouettes and controlled overlap | No |
| RP12 | Lavender Bed | Lavender 01/05 Corona proxies | Spaced flowering groups with both variants represented | Yes |
| RP13 | Rugosa Rose Groups | Rugosa Rose 02/03 | Shrub clusters with room for their real canopy size | No |
| RP14 | Myrtle and Abelia Border | Myrtle 03; Glossy Abelia 06 Corona proxy | A layered shrub edge with controlled height and spacing | No |
| RP15 | Mixed Shrub Islands | Black Elder 01; Myrtle 03; Rugosa Rose | Separate shrub groups with open surroundings | No |

Keep proxy geometry paths packaged and persistent after loading/reopening.
Measure proxy viewport and final-render behavior separately. A proxy label does
not prove low memory or correct instancing. RP14's border can use a supported
surface-shaped region or explicitly bound Spline Bands; direct path stations are
not assumed to exist.

## Trees and ordered planting

| ID | Preset | Proposed source selection | Distinct result | Pilot |
| --- | --- | --- | --- | --- |
| RP16 | Mixed Broadleaf Grove | Individual Broadleaf Tree 01/02/03 | Varied silhouettes with plausible canopy spacing | Yes |
| RP17 | Red and Green Maple Grove | One suitable red Norway Maple variant; green Maple | Controlled foliage contrast without duplicate aliases dominating the mix | No |
| RP18 | Cypress Rows | Individual Cypress Tree | Ordered rows with physical spacing and modest variation | No |
| RP19 | Orange Orchard | Individual Orange Tree | A readable orchard grid with restrained rotation and scale variation | Yes |
| RP20 | Peach Orchard | Prefer suitable individual Peach 1/2; evaluate others by cost | Fruit-tree rows without loading the complete collection as one source | No |
| RP21 | Tea Tree Grove | Prefer selected individual Tea Tree variants, starting with Variant 1 | Loose mixed-size planting within measured memory/render bounds | No |

Use supported Rectangular/Staggered layouts for rows and grids. An unimplemented
path-placement feature must not become a hidden dependency. Check the whole
canopy, trunk contact and root appearance. Decide consciously whether a planting
keeps trees upright or follows surface normals; document the chosen behavior.

The recorded Peach Variant 3 has approximately 7.45 million faces and the complete
Peach collection approximately 14.56 million. Exclude these from lightweight
defaults unless a separately qualified representation makes the cost appropriate.
Geometry figures from preparation records are not new render-performance results.

## Layered compositions

| ID | Preset | Proposed layers | Distinct result | Pilot |
| --- | --- | --- | --- | --- |
| RP22 | Woodland with Understory | Broadleaf trees → selected shrubs → groundcover → leaf litter | Readable canopy, understory and ground layers with deliberate collision scopes | Yes |
| RP23 | Layered Garden Border | Selected shrubs → Arthropodium → flowering groundcover | A planted edge with distinct heights and editable layers | No |
| RP24 | Palm Garden | One deliberately selected Palm scale → Arthropodium → low planting | Generous spacing around palms and coherent physical scale | Yes |

The arrows describe intended evaluation/composition order, not one mandatory
collision rule for every layer. Use independent scopes deliberately: tree spacing
must not accidentally erase all useful groundcover. Preserve the product's current
layer limit and leave space for users to extend the scene where possible.

## Common authoring record

For each RP entry, record these fields in the implementation manifest:

| Field | Required content |
| --- | --- |
| Identity | RP ID; actual recipe UUID/revision; title; category; pilot/expansion |
| Sources | Exact model IDs, selected variants, SHA-256 and derived-asset provenance |
| Composition | Layer order; source weights; density/spacing; collision scopes |
| Geometry | Physical dimensions; pivot; forward/up axes; ground contact; UV/material IDs |
| Variation | Seed; scale/rotation range; alignment intent; meaningful source differences |
| Dependencies | Renderer/version; maps; proxy files; other plugin classes; optional vs required |
| Destination | Receiver requirements; mask/Paint/path inputs; supported transfer behavior |
| Cost | Unique geometry; texture footprint; accepted/shown/rendered counts; measured timings/memory |
| Visuals | Exact-package render; close detail; coverage overview; framing/lighting notes |
| Readiness | Draft/blocked/qualified; test-receipt links; open limitations; distribution eligibility |

Do not invent field support in the actual recipe schema. Keep extra curation and
qualification metadata in a companion manifest when the plugin has no such field.
The [validation evidence contract](VALIDATION.md#evidence-record) defines the
minimum receipt needed to claim a preset is ready.

## Expansion rule

Expand beyond 24 only when an additional composition has a distinct use and passes
the same gates. Keep source variations accessible without multiplying cards by
seed or density alone. Do not invent moss, rocks, new species or new geometry to
reuse the names of old demonstrations; the supplied collection determines scope.

