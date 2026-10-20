# Owned and opt-in presentation fixtures

`src/assets/demo.ts` generates owned, deterministic GLB geometry: a 100 m medium-site garden and a 500 m large-site stress input. `npx tsx tools/make-fixtures.ts` writes ignored GLBs under `exports/fixtures/`. The generation argument bounds placement attempts; it is not the final plant count. Record actual geometry/instance counts from inspection. These fixtures establish contracts and recovery, not realistic landscape capacity.

The medium source inspected on 15 October 2026 is 193,592 bytes, SHA-256 `bf798b7241fddbfcc1bb7db7e634a4aaead1bf24a8b9732ccc0b6093aedd97f9`, with 200 persistent node IDs, 1,683 instanced primitive rows and 53,784 triangles. Primitive rows can include trunk/canopy parts; they are not a botanical plant count.

The balanced preparation recipe produced 202,336 bytes, SHA-256 `8cb0137280bb6bbc57b8f85669ed6f3f3a5e8d903e957b1299edcc07aa8ed23e`. IDs, primitive instance-row count, triangle count and global bounds passed the checker, with zero bounds difference. This source grew in size; no compression improvement is claimed. Full per-instance/vertex geometric equivalence is still a preparation acceptance task for representative artist assets.

## User-selected previous Botanical Islands study

The user selected the existing [Botanical Islands GLB](../../website/prototypes/botanical-islands/public/assets/models/botanical-islands-garden.glb) for current acceptance and accepted mobile browser checks while prioritizing desktop studio use. `tools/previous-study-fixture.ts` reads that original GLB, the canonical layout, base SVG and existing artistic PNGs. It writes only ignored app exports, without changing the earlier website/prototype.

The exact 5,234,456-byte original has SHA-256 `a4ae0b17d3bbff359df72360d549f90e99f2fc6878249df6e59d3428551de93d`, 99 nodes, 2,470,066 source triangles and 2,330 rendered component instances. The canonical source records 1,949 botanical plant IDs; components include separate trunk/leaves/flowers. The fixture preserves the original GLB bytes and all sixteen route waypoint positions. It adds an overhead stop and maps named source families explicitly into six project layers. A rasterized PNG of the unchanged base SVG supplies the MVP's calibrated plan; this is format preparation, not a changed drawing.

The four earlier artistic images are separate resources and receive scripted fixture approvals for this preset. They remain labelled artistic interpretations; admin review is still required before publication. Their visual realism is not a claim of exact mesh/leaf fidelity. The new evaluator's timing/orientation interpolation differs from the earlier player; no identical route animation is claimed. Full source/photo hashes and preparation details are in [the generated provenance receipt](../exports/fixtures/previous-study/provenance.json).

## Khronos compatibility fixtures

Run `node tools/fetch-test-assets.mjs` for opt-in downloads from the [Khronos glTF Sample Assets repository](https://github.com/KhronosGroup/glTF-Sample-Assets). Its `main` branch can change: the tool records URLs, byte counts and hashes for the actual download. The observations below identify this run, not a future branch state.

| Fixture | Test purpose | Observed GLB SHA-256 | Attribution from its source README |
| --- | --- | --- | --- |
| [BoxTextured](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/BoxTextured) | Embedded base-colour texture | `b510eca2e2ef33f62f9ed57d6e7ce2d10ebb2bdebc4a8e59d347719ba81abdf4` | © 2017 Cesium; CC BY 4.0. Cesium logo has separate trademark/legal-mark terms. |
| [AlphaBlendModeTest](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/AlphaBlendModeTest) | Opaque, mask/blend and double-sided presentation | `37c3577d143071b42dd46e9d942b157837eb25c6340112171d7faecaa987b14e` | © 2018 Analytical Graphics, Inc.; Ed Mackey; CC BY 4.0. |
| [NormalTangentTest](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/NormalTangentTest) | Normal/tangent materials | `5ac0932355ae1ea05a7485eeddcc3f1fbe56c678e00b519075feced80e9e9d6a` | © 2018 Analytical Graphics, Inc.; Ed Mackey; CC0 1.0. |

Original README/legal links remain beside the ignored downloaded GLBs. Do not include these foreign models in the sample garden or ship them as Cyrus assets. The browser test imports each fixture, confirms corresponding material features, compiles it and starts the actual public player; screenshots are reviewed for visible texture/alpha/normal behaviour. This is bounded compatibility evidence, not reference-renderer pixel equivalence or photographic foliage qualification.

## Owned native Max 2027 cameras

[tools/max2027/qualification.ms](../tools/max2027/qualification.ms) creates disposable Free (animated parent/roll/FOV/nonconstant movement), Target, Physical (animated focal length/zoom/focus) and path-constrained cameras. The isolated [host workflow](../tools/max2027/README.md#reproduce-the-owned-host-test) exports samples and independent world-basis/FOV references at quarter-frame and eighth-frame intervals. Generated JSON, the owned `.max` scene and local receipts are ignored artifacts, not artist assets. Native version/build and hashes are recorded in `exports/qualification/max-camera/max-host.json`.

These fixtures prove the sampled transform/time/lens contract and quantify interpolation error for those specific rigs. They do not establish exact analytic motion between samples, arbitrary third-party camera support or pixel parity with Max rendering. Native export/import is combined with the unchanged user-selected Botanical GLB for browser save/reopen, compiled preview and nested standalone HTTP tests. No artist camera was supplied; the test animation is owned synthetic Max content.
