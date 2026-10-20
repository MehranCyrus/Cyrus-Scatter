# Original gallery and accessory starter library

Current 0.3.2 example delivery and acceptance are tracked in the [geometry ledger](GEOMETRY_WORKFLOW_0.3.2.md). This page retains the original 0.1.x gallery and library instructions.

These original **3ds Max 2027** examples originated with qualified Cyrus Arrange 0.1.1. Their native21 gallery/functional receipts and `examples/manifest-0.1.1.json` preserve the original source, native and file hashes. **Use the matched 0.1.3 package identified by the [current release report](RELEASE_VALIDATION_0.1.3.md)**: native46's migration suite passes 60 / 0 for the delivered baseline scene/library, current-format SaveAs/reopen and unchanged original inputs. Historical native21 and native28 receipts below retain their own scope. For new examples, use the [native46 book-row scenes](BOOK_ROW_EXAMPLES_0.1.3.md) and [imported furniture scenes](IMPORTED_EXAMPLES.md).

The separate [0.1.2 book-row examples](BOOK_ROW_EXAMPLES.md) add two saved
comparison scenes, six actual final28 renders and their own hash manifest.
They demonstrate individual row members and height balancing in qualified
0.1.2; its external receipt records the later successful installer gate. The
baseline files below and their original evidence remain preserved.

| Project path | Contents | Evidence |
| --- | --- | --- |
| `examples/CyrusArrange-Gallery.max` | Five original furniture assemblies, native setups and generated props; original source accessories; standard materials, lights and overview/detail cameras | From the passed final21 render run; generation 49/0 and six actual images |
| `examples/CyrusArrange-Original-Accessories.cyalib` | Eleven original accessory meshes and their native placement metadata, reusable in another setup | From the passed final21 workflow run, including actual library import/generation |
| `examples/CyrusArrange-Gallery-Performance.csv` | Timings and process memory observations | Separate final21 functional gallery sample, 49/0 |

The scene/library/CSV are delivered beside the source project in `examples/`; the MZP contains plugin files and documentation, not these example assets. Stable image copies are in `docs/images/arrange-gallery-*.png`.

The source factories are `tests/max/fixtures.ms`, `tests/max/furniture_examples.ms` and `tests/max/asset_fixtures.ms`. They create original procedural geometry and scene materials without downloading models, images or textures. The gallery is a functional example of physical fit and reproducible dressing, not a claim of photorealistic rendering or automatic interior design.

## The five furniture examples

- **TV console:** a 1,800 × 450 mm console with an original display and feet. Surface rules retain the bottom shelf at 80 mm, divided middle shelf at 275 mm and top at 600 mm. Display and incidental ledge tops are excluded. The display belongs to the captured assembly and therefore blocks intersecting props.
- **Open shelf:** a 1,200 × 350 × 1,800 mm assembly with dividers. The four intended interior support heights are 30, 450, 890 and 1,330 mm; the upper exterior ledge is excluded.
- **Curved coffee table:** a 96-sided elliptical top with horizontal radii 697.5 and 396 mm, at 420 mm. Gallery checks test actual generated full-bounds corners against both the analytic ellipse and the fixture's polygon edges.
- **Round dining table:** a 96-sided, 650 mm radius top at 755 mm, on a pedestal. The same independent circle/polygon checks apply. It demonstrates table decoration; it does not generate chair-based dining place settings.
- **L-shaped kitchen counter:** a 3,000 × 650 mm main run and a 650 × 1,225 mm return, with top at 935 mm. A nominal 600 × 400 mm sink opening occupies local X 200–800 mm and Y −200–200 mm. Checks test the L-shaped footprint and separately reject any positive-area prop-bounds overlap with the sink rectangle. Checking just four corners would miss this internal hole.

Each assembly has its own native setup, furniture layer and generated-prop layer. Setups are named `CA_GALLERY_SETUP_01_TV_CONSOLE`, `CA_GALLERY_SETUP_02_OPEN_SHELF`, `CA_GALLERY_SETUP_03_CURVED_COFFEE`, `CA_GALLERY_SETUP_04_ROUND_DINING` and `CA_GALLERY_SETUP_05_L_KITCHEN`. Their separation is for readable comparison; it is not a furnished-room composition.

The gallery presets keep minimum and maximum asset scale at **1**, with Scale variation **0** and authored yaw choices of 0°, 90°, 180° and 270°. Physical spacing is 22 mm, edge gap is 25 mm and analysis spacing is 30 mm. Different seeds/densities/empty-space settings demonstrate sparse, full-size dressing. Static collision remains enabled; the gallery disables the horizontal approach requirement so exposed surfaces do not require a clear horizontal insertion path.

## Eleven original source accessories

The starter catalog contains these same original assets. It has eleven models across ten authored categories: upright and flat books are separate Book models, and there is no dedicated Kitchenware model in this starter set.

| Model | Category | Authored stacking |
| --- | --- | --- |
| Upright terracotta book | Book | Individual upright prop |
| Flat blue book | Book | Flat top can support allowed book children |
| Three-book horizontal stack | Book stack | Prebuilt model with an authored flat top |
| Potted green plant | Plant | No top support |
| Brass candle holder | Candle | No top support |
| Standing walnut frame | Frame | No top support |
| Hollow ceramic vase | Vase | No top support |
| Stoneware bowl | Bowl | No top support |
| Wood ring sculpture | Accessory | No top support |
| Ceramic mug | Tableware | No top support |
| Round wooden tray | Tray | No top support in this starter metadata |

The gallery parks these source groups away from the furniture in the hidden layer `CA_GALLERY_99_PARKED_SOURCE_LIBRARY`. Source nodes are deliberately nonrenderable; generated meshes remain visible. Unhide that layer to inspect or edit the originals. The five setups use curated subsets of the shared sources, so one source edit can affect several setups. Duplicate a source and rebind one entry when independent variants are needed.

## Edit or reuse an example

Install the qualified 0.1.2 MZP, restart Max 2027, and keep its native modules, storage companion and UI together. Extract the examples from the matching Source-and-Examples ZIP and open a **working copy** of `CyrusArrange-Gallery.max`. Select a named setup helper and use **Use selected setup** in Cyrus Arrange. Review its Asset Library, Surface rules and Collision scope, then Preview/Commit or Generate. Reopening does not regenerate, arm Live, bump authored revision or rewrite the original scene. Installing 0.1.1 is unnecessary for this supported migration path; it is only relevant when reproducing the historical native21 snapshot.

The qualified reader accepts document3/4 and library1/2; new saves use document4/library2. Use **Save As to a new path** when editing the old gallery and preserve the supplied original. An older 0.1.1 binary is not promised to read the new document4 save.

To adjust the arrangement, change the seed, density, spacing, empty space or category rules. Surface rules restrict allowed categories, stacking and excluded supports. A conflicting locked object rejects generation and preserves the previous complete result; unlock it or revise the rule. Keep both asset scales at 1 when the source's physical size should remain unchanged. Use [ARRANGE_QUICKSTART.md](ARRANGE_QUICKSTART.md) for the complete workflow.

Surface exclusions and category rules control where an accessory's **anchor** may land. Its supported footprint may extend onto a touching, coplanar excluded surface because support is checked across the selected furniture at that height. A gap or hole still rejects unsupported contact. To keep an actual area empty, add a simple **obstacle volume rising above the surface** in Collision scope; obstacles block placement and never supply support. An excluded label or flat outline alone is not a physical keep-clear zone.

To replace an accessory, select its catalog row, select the replacement scene model/group in the viewport, then press **Rebind to selected model**. Keep that catalog row active: **Use selected model / group** starts a new registration and clears the existing entry selection. Rebinding retains the asset identity and validates the replacement against its metadata. **Update selected metadata** edits the existing entry; **Register new asset** adds another entry. A deleted required source is different from an intentionally stored asset: rebind it, restore the source with Undo, or explicitly choose **Use stored geometry**. See [ASSET_LIBRARY.md](ASSET_LIBRARY.md) for contact/top-patch editing and source-state details.

**Load asset library** appends the starter `.cyalib` into another setup. The host assigns new destination IDs. The portable format contains mesh geometry, dimensions, category/eligibility, contact/top metadata, yaw/scale choices and weights. It does **not** contain renderer materials, textures, UV/map channels, source scene references or modifier stacks. It therefore does not reproduce the gallery's colored appearance by itself. Preserve the original `.max` sources, merge the required source groups into the destination scene and rebind the imported entries when source visual data is needed. Bound scene sources supply evaluated materials/map data during generation; generated meshes retain their published appearance in the saved `.max` scene.

## Historical native21 gallery measurements

`build/host-final-21-gallery/receipt.json` passed **49 assertions with zero failures** against `build/native-arrange-21/receipt.json`. Checks include nonempty generation for every category, deterministic repeat IDs/poses, full-size/quarter-turn checks, independent surface/hole checks and camera-facing title planes. The delivered scene comes from the separate passed render run using that same frozen generator and native pair, so its images correspond to the delivered scene. The table below reports the functional gallery's separate timing sample. The 35 generated props have not been hand-positioned for presentation.

| Fixture | Generated props | Analyze, ms | First Generate, ms | Repeat Generate, ms |
| --- | ---: | ---: | ---: | ---: |
| TV console | 12 | 6 | 300.16 | 245.17 |
| Open shelf | 8 | 3 | 74.95 | 71.40 |
| Curved coffee table | 3 | 2 | 32.79 | 31.46 |
| Round dining table | 5 | 3 | 58.83 | 63.64 |
| L-shaped kitchen counter | 7 | 5 | 131.88 | 127.21 |

These are single first/repeat measurements from `build/host-final-21-gallery/gallery-performance.csv`: Analyze uses Max `timeStamp`, and the Generate columns use `System.Diagnostics.Stopwatch`. Generate includes host capture, native analysis/query construction/placement, material staging, node publication and Undo work. Repeat Generate in that native21 run recaptured/reanalyzed and rebuilt the precise query; it is **not a cached reroll** or an isolated C++ solver benchmark. The separate render helper also generated the example and recorded its own CSV; those independent samples are not pooled into this table.

The same CSV records process `WorkingSet64`/`PeakWorkingSet64` before and after each generation. Observed working set was approximately **2.860–2.869 GB** on that run. This includes Max itself, the scene, source assets, existing outputs and history. It is process-wide memory, not plugin/solver allocation attribution or a resource guarantee. Earlier native16 counts and measurements remain preserved in `build/host-arrange-gallery-03`; they do not replace the matched native21 evidence above.

## Historical actual native21 renders

`build/host-final-21-render/receipt.json` passed against native21 with **Default Scanline Renderer**, preserving the recorded artist profiles. It saved the generated scene and produced the following actual images under `build/host-final-21-render/`:

| View | Image | Dimensions |
| --- | --- | --- |
| Overview | `CyrusArrange-Gallery-Overview.png` | 2,400 × 1,000 |
| TV console | `CyrusArrange-Gallery-TV.png` | 1,400 × 1,050 |
| Open shelf | `CyrusArrange-Gallery-SHELF.png` | 1,400 × 1,050 |
| Curved coffee | `CyrusArrange-Gallery-COFFEE.png` | 1,400 × 1,050 |
| Round dining | `CyrusArrange-Gallery-DINING.png` | 1,400 × 1,050 |
| Kitchen | `CyrusArrange-Gallery-KITCHEN.png` | 1,400 × 1,050 |

The overview render/write took about **6.90 seconds**; individual details took **3.82–5.38 seconds** on that host. These are genuine Max renders of the unchanged generated arrangements, with original standard materials and scene lights. They establish this Scanline fixture/render scope, not Arnold, V-Ray, Corona, third-party proxy or general renderer compatibility.

Read-only review of the five detail images found no obvious floating props, visible overlaps, table-edge overhangs or sink intrusions. It also found presentation limits: TV/coffee captions and the shelf base/caption are cropped, neighboring assemblies appear in detail frames, and hard shadows/faceted ceramics show the procedural source style. Sparse books and mugs demonstrate functional scatter rather than authored book rows or dining place settings. Visible support is consistent with the independent geometry checks; an image alone does not certify hidden contacts, dynamics or arbitrary asset fidelity. No rendered image was edited and no generated prop pose was adjusted to improve the images.

## Isolated generation and render scripts

`tests/max/arrange_gallery_tests.ms` and `tests/max/arrange_gallery_render.ms` are qualification harnesses. They require runner-supplied owned paths and **reset or load scenes**. Do not fileIn them in an artist session. The root qualification runner supplies an isolated Max 2027 process/private profile; this documentation does not launch it.

The test script writes an owned gallery `.max`, `gallery-performance.csv`, progress and exception files. The render script loads that owned scene, checks five nonempty native setup owners, and renders the overview plus optional detail cameras. It can create the gallery first when its owned output has none. The original delivered checksums and receipt/image paths are already recorded in `examples/manifest-0.1.1.json` and [0.1.1 release validation](RELEASE_VALIDATION_0.1.1.md); the later supported migration is recorded in [0.1.2 validation](RELEASE_VALIDATION_0.1.2.md). Any successor run needs its own exact-source receipt and must not overwrite immutable delivered evidence.
