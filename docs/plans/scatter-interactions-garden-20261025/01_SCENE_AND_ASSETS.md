# Scene reconstruction and asset intake

## Composition

Use the approved garden concept as a composition guide: a dominant stone, smaller scattered stones, meadow grasses, two flowering species and one small broadleaf tree. The available library provides lavender and pink geranium rather than the reference's white daisies. This substitution is explicit. The baseline is a geometry/placement diagnostic, not a photorealistic match.

The supplied `Test Scene/Rock_Boulder_10` is read-only input. Its Max rock is a broad, low slab rather than a round boulder. The owned derivative tilts it 35 degrees and normalizes its longest dimension to 1.75 m. This is an authored scene choice, not inferred asset scale. The OBJ has six independent groups and no authoritative physical units; the fixture explicitly normalizes each owned source to 0.34 m before per-placement variation.

## Measured original sources

Intake used a fresh Max 2027 profile, reading each original asset without saving it. Triangle counts are mesh counts, not viewport draw counts.

| ID | Original source | Triangles | Original extent, metres | Preparation intake |
|---|---|---:|---|---|
| Hero rock | Rock_10.max / Stone_10 | 752 | 7.957 × 8.372 × 1.910 | Collider geometry; not a plant rig |
| Small rocks | Stones 1/stones.obj, six groups | 2,774 total | Unitless OBJ; intake interpreted cm | Collider geometry; not a plant rig |
| A069 | Grass — Small Clump | 4,360 | 0.145 × 0.145 × 0.050 | Current round-tube profile rejects it |
| A068 | Grass — Bushy Clump | 8,222 | 0.172 × 0.171 × 0.068 | Current round-tube profile rejects it |
| A083 | Lavender 01 | 563,380 | 1.172 × 1.135 × 0.836 | 560 guides, 3 grounded roots, 0 unresolved; review required |
| A066 | Herb Robert Geranium 04 | 16,356 | 0.247 × 0.246 × 0.134 | 22 guides, 6 grounded roots, 0 unresolved; review required |
| A064 | Creeping Phlox 01 | 15,424 | 0.206 × 0.161 × 0.141 | 69 guides, 54 unresolved; preparation blocked |
| A072 | Broadleaf Tree 01 | 432,640 | 4.798 × 5.151 × 6.539 | Exceeds the current 40,000 connected-part budget |

Sources come from `dist/CyrusScatter-0.86.7-20261020/Content/Library/Models`. That is the content edition, not the executable version used in this investigation. Exact paths/hashes are in [asset-inputs.json](../../../CyrusVegetationLab/experiments/garden-contact/asset-inputs.json). Actual intake is in [assets.json](../../../build/garden-assets-host-20261025-01/assets.json).

`PREPARATION_INTAKE.json` preserves initial diagnostic runs. Those runs intentionally supplied expected guide count zero, so executable exit 1 does not by itself mean preparation failed. Follow-up runs supplied the correct 560/22 counts and both exited zero; see the results document. These original-source results do not automatically qualify every rescaled or edited derivative rig.

## Baseline layer organization

| Layer | Sources | Fixture request | Role in a future integrated fixture |
|---|---|---:|---|
| Hero stone | Rock 10 | 1 | Obstacle and root cover |
| Small stones | Six OBJ groups | 11 | Obstacles and root cover |
| Small grass | A069 | 1,700 | React; needs blade preparation |
| Bushy grass | A068 | 700 | React; needs blade preparation |
| Lavender | A083 | 9 | React; needs instance pose delivery |
| Geranium | A066 | 100 | React; needs instance pose delivery |
| Small tree | A072 | 1 | Static trunk obstacle first |

These are candidate requests. Existing area exclusions reduce accepted counts; no acceptance-target refill was added. The final receipt gives actual counts. Receivers anchor the hero/tree and distribute the remaining layers. Hidden source nodes remain shared sources; there is no plant scene node per accepted placement.

The 5.2 × 4.2 m flat meadow deliberately keeps the initial footprint question bounded. Each rock's transformed mesh vertices generate a closed XY convex-hull spline used by existing Exclude Areas. Source object offsets are applied before instance transforms. This is a conservative, static projected footprint: it can suppress roots under an overhang and does not follow a moved stone. It is not solid-mesh occupancy or live contact.

## Presentation and asset delivery

The final preview uses real Scatter meshes and diagnostic layer colors to inspect composition and placement. It is not a beauty render. Existing library shaders/maps need separate renderer qualification. Raw intake recorded relative map names as unresolved relative to the process directory; that did **not** establish missing assets. The normal library merge resolves paths through its catalog. The owned scene resolves Bitmaptexture filenames against the known library/rock folders and records every attempted mapping.

Three hero TGA files are approximately 50 MB each; the smaller-stone set includes several large normal/base-color maps. Texture/decode pressure can exceed the cost of their very light collision meshes. Do not infer collider cost from texture size or render-poly detail. The baseline retains materials but does not certify all map classes, opacity/color-management paths or third-party renderers.

Do not overwrite or recenter originals. Production source preparation must retain the existing pivot/object-offset contract and transform the rig accordingly. The canonicalization used to compose this disposable fixture is not an authorized migration of artist library assets.
