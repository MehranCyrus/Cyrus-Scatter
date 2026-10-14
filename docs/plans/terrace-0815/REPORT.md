# Terrace planting and source rectangles — 0.81.5

13 October 2026. Source, matched Max 2026/2027 packages and an editable planted
scene are complete. The final 1920x1080 Corona image has been rendered and visually
inspected. This is scoped development qualification, not release certification.

## Findings and changes

- **Slow rectangle selection:** both local and global rectangles constructed the
  full 14-rollout, 486-control Scatter editor. The user confirmed selection is for
  moving/resizing. Rectangles now open compact collection properties; planting
  settings remain on the Scatter controller.
- **Repeated creation/label work:** labels now use a presentation-only native
  update; unchanged registrations retain weak references; creation removes one
  redundant full reconciliation. Full reconciliation still checks ownership and
  movement hierarchies.
- **100,000 was an actual UI/native ceiling:** the new bound is **1,000,000 per
  population within a shared 1,000,000 controller candidate budget**, including
  retries/protected work. Paged receiver IDs preserve existing candidate identities.
  Admission failure retains the previous complete publication.
- **Million-count point staging:** the first candidate copied every transform and
  exceeded the 64 MiB owner allowance. The correction validates every row but
  copies only displayed samples; the memory limit remains unchanged.
- **Missing receiver mapping:** all 11 original receivers lacked UV channel 1.
  Texture Density errors now name the receiver/channel and explain the mapping or
  Layout remedy. Planar UV mapping is added only to the working copy.
- **Render source-scale mismatch:** Particle Flow applied source-node scale again,
  unlike pivot-local native preview/Auto Radius. A scaled-box witness had a
  111-unit bounds error. The render bridge now snapshots evaluated geometry into
  one normalized transient prototype per distinct source. Ordinary cleanup owns
  these helpers. Unit, nonuniform and mirrored scale agree within 0.00001 units;
  original source transforms are unchanged. Other third-party source/modifier
  families are not universally qualified.

Edits are in the authoritative UI templates/generator and native receiver,
procedural, preview and source-container code. The script is regenerated. The
[original investigation](../../Source_Containers_Performance_2026-10-13.md) and
[iteration record](ITERATIONS.md) preserve preceding measurements and failures.

## The actual garden

Scene: `Test Scene/Terraces_0815/Terraces_0815_Final.max`.
Camera: **PhysCamera002**, preserving the original transform/framing and building.
Image: `Test Scene/Terraces_0815/Terraces_0815_Final.png`; 12 passes, Corona denoiser
with blend 0.65, **805.21 seconds**. The render reports no Scatter bridge error,
preserves every placement fingerprint and releases all 178 transient render nodes
through the normal scheduled idle cleanup. The final scene was reopened before
this render. `garden-final-render.json` records these assertions; the first harness
checked cleanup before yielding to the event loop and its receipt is preserved.
The planted terraces follow the reference's pale/rose/gold flower drifts, palms,
shrubs, framing trees, woodland and warm atmosphere. This is a recreation using
available models, not a pixel-identical reproduction. The reference's person is
not included.

| Layer | Requested candidates | Accepted placements |
| --- | ---: | ---: |
| Grass and clover | 220,000 | 220,000 |
| Ivory rose drifts | 6,000 | 3,590 |
| Warm lavender | 9,000 | 5,730 |
| Golden flowers | 23,000 | 15,342 |
| Evergreen structure | 900 | 725 |
| Palms | 220 | 22 |
| Framing trees | 120 | 5 |
| Woodland backdrop | 5,000 | 163 |
| Foreground roses | 400 | 87 |
| **Total** | **264,640** | **245,664** |

Spacing, exclusions and bounded regions explain the difference between requested
and accepted counts. Nine ordered populations, editable receivers/guides, seven
source rectangles, accessible parked models and 56 stepping stones are saved.
Manual mode waits for explicit Update. Used source originals are non-renderable.

Ten retaining-wall infill meshes close actual gaps in the original terrain, only
in the copy. A baked upright/base-pivot palm copy and a combined copy of the
existing trunk/leaves pair correct asset preparation. Additional flowers come from
the local `Reference_Garden_075/Source_Plants.max` library. All bitmap paths resolve
after reopen. Original models and the disabled baseline Scatter setup are retained.

## Performance evidence

Times are synchronous scripted wall time in owned hosts, not physical pointer
latency, presented FPS or a controlled cross-version benchmark. Concurrent host
work/rendering affected some measurements.

| Action | Measurement |
| --- | --- |
| Earlier full rectangle selection | 5,908 ms median, 0.81.3 fixture |
| First compact candidate selection | 169 ms median, Max 2027 fixture |
| Final matched fixture selection | 270 ms Max 2026 / 420 ms Max 2027 |
| Final garden selection with redraw/messages, 8 samples | **296 ms median**, 263–328 ms |
| Final 250-model labels-only refresh | 2.84 ms Max 2026 / 2.02 ms Max 2027 |
| Final 250-model full reconciliation | 125 ms Max 2026 / 131 ms Max 2027 |
| Final Create layer/global buttons | 251/248 ms Max 2026; 402/437 ms Max 2027 |
| Garden warm published snapshot read | 0.073 ms median, excludes UI/rendering |
| Garden first explicit update after load | 22.26 s, cold source preparation included |
| Warm explicit grass Amount update | 2.34 s; eight sibling placements preserved |
| Final save / reopen | 4.25 / 19.19 s; approximately 1.08 GB scene |

Creation timings do **not** show a consistent improvement on both hosts. The
strong result is removal of the multi-second full editor from rectangle selection.
Selection in the garden left publication, preparation, native uploads and uploaded
bytes unchanged. Ordinary Manual reads and layer selection retain publication.
Full-controller cold construction and large hierarchy reconciliation remain costs.

## Qualification and identities

Baseline: branch `codex/workflow-0.75`, HEAD
`2b9ad12b24f9d91241db4567037f64db71fe9726`, plus preserved pre-existing changes.
Knowledge retrieval was stale; direct current-source inspection was authoritative.

The user explicitly selected **0.81.5**. The expanded identity bound would normally
justify a minor version; that instruction takes precedence. Schema 58 and
publication interface 2 remain. Band/native requirement is 10. Analyzer 0.14 and
MCP 0.73 remain independent.

Script SHA-256: `6e75dfbb64b31d2fee3b4fdb0fc71bcf6b63aca4fe1b4d9e62323b4bdea09dbd`.

| Evidence | Max 2026 | Max 2027 |
| --- | --- | --- |
| Build under `build/terrace-0815-20261013-01/` | `native-2026-02` | `native-2027-03` |
| Host under `build/mcp-qualification/` | `foundation-terrace0815-candidate2026-02` | `foundation-terrace0815-candidate2027-04` |
| Native offline tests | 27 passed | 27 passed |
| Amount/capacity, IDs/full transforms, retention, reopen | 14 checks passed | 14 checks passed |
| Compact local/global UI, 250-model collection, uploads | passed | passed |
| Native Move, Undo, Redo, resize with 20 sources | passed | passed |
| Render source-frame parity | 3 cases passed | 3 cases passed |
| Point/retained/workflow/invalidation/publication regressions | 89 passed | 89 passed |
| Nine-layer production-scene acceptance | not run | 22 passed |

The 89 checks comprise 4 independent point sampling/validation checks, 17 retained
publication/upload checks, 11 generated-control workflow checks, 8 Manual/Live
invalidation checks and 49 publication failure/recovery checks. Adapters record
source/adapter hashes. The garden verifies counts, selection buffer reuse, pending
Manual edits, explicit updates with unchanged siblings, restored IDs/transforms,
complete save/reopen parity and resolved textures.

Generator/layout assertions and generated-source integration passed. MCP/tools:
**161 passed (13.15 s)**. Package manifests, payload hashes, loaded module paths
and source/build receipts were checked. This is not physical all-control testing.

Packages in `dist/terrace-0815-20261013/`:

- `CyrusScatter-0.81.5-Max2026.mzp`: SHA-256
  `e5a74bcc6f78cd64402296f7af0900cc5ae362c7c8222db977730774caac831c`.
- `CyrusScatter-0.81.5-Max2027.mzp`: SHA-256
  `70b21b9a9f2e831f0263a7f19561b6462275e8aa48370a3952049332998f3ef1`.

Exact native hashes and test receipts are linked by `package-2026.json` and
`package-2027.json` in the build root above. Packages are prepared, not installed.
The normal installation remains 0.81.3. Use the matched Max 2027 package for the
new scene; do not mix a new script with old modules. No Git commit/push or website
publication was performed. Website sources/imported content are updated; static
content checks and the local production build pass. The website is not deployed.

Original scene SHA-256 remains
`03a005a9b3a58e9eb1b7450fa32d3680c29313f60b079a06bdc2eac62bb6cbff`.
Both normal Max profile hashes also match launch-time baselines. Artist processes
and `Test Scene/Terraces Buiding Test.max` were preserved.

## Remaining acceptance boundaries

Final image inspection confirms complete planting, upright palms, visible stepping
stones and no open white terrain gaps. The retaining walls and plant distribution
differ from the supplied reference, as does the available architecture/material
detail; this is not a claim of exact visual equivalence. Physical cold Undo B05,
DPI/docking/tablet, long sessions, sustained interactive rendering, other
renderers and all third-party source/modifier families remain outside these checks.
Max 2026 has focused runtime qualification but no actual-garden render.
Million-count testing uses simple sources; it is not a million-heavy-plant render
or FPS promise. Preview budgets still apply. Full Scatter editor construction is
not redesigned by the compact-rectangle correction.

Failed/inconclusive receipts are retained. One final harness initially invoked the
explicit solver `evaluateGroups` as though it were an ordinary Manual reader.
Corrected acceptance uses `procReadSnapshot`; the extra explicit solve is not
misreported as a passing Manual read. Earlier movement attempts under an enclosing
Undo hold were superseded by fresh native-first fixtures.

Vendor context: [Autodesk Shape Instance](https://help.autodesk.com/cloudhelp/2025/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/MAXScript-Extensions/MAXScript-Extensions-for/Particle-Flow-Classes/Operators/Shape/GUID-8EF8B1F2-B734-400A-B7BC-F63568C6582D.html),
[evaluated mesh snapshots](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Editable-Meshes-Splines-Patches/Editable_Mesh-and-TriMesh/GUID-0532C071-4401-4846-8450-3DA5510A3883.html),
and [Corona denoising](https://support.chaos.com/hc/en-us/articles/4528588388113-How-to-use-denoising-in-Corona-for-3ds-Max).
Local before/after witnesses establish Cyrus behavior; vendor wording alone does
not establish acceptance.
