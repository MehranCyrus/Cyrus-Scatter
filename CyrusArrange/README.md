# Cyrus Arrange

**0.3.2 is in development and release testing for 3ds Max 2027.** It uses a C++
geometry and placement core with MAXScript controls inside Modify. The last
qualified installer remains [0.3.1](docs/RELEASE_VALIDATION_0.3.1.md). Keep each
version's scripts and native modules together.

## Current workflow

1. Select receiving geometry and run **Create Cyrus Arrange**.
2. Select the arrangement icon, open **Modify → Cyrus Arrange**, and add the props
   you want to repeat. Complete models and groups are supported.
3. Set **Copies**, then **Generate**. Generate applies the visible settings and
   chooses a new seed. **Repeat seed** reproduces the saved variation.

The solver finds support and clearance from the selected geometry. There is no
required furniture type, category restriction or separate Apply button. Optional
Scale, Keep clear and Path controls stay in the same modifier. A selected spline
can supply one path or two opposing lanes.

For 100 books, add one book source and set Copies to 100. Enable Random scale if
wanted. For an oversized device, enable Shrink to fit and choose the permitted
percentage range. Original size is preferred when random scaling is off; sources
stay unchanged. Unsupported or obstructed copies remain unfilled and receive
contextual feedback.

Start with the [step-by-step development guide](docs/GEOMETRY_USER_WORKFLOW_0.3.2.md)
and [Modify interface](docs/UNIFIED_MODIFY_0.3.2.md). The
[14-requirement implementation ledger](docs/GEOMETRY_WORKFLOW_0.3.2.md),
[release regression record](docs/RELEASE_WORKFLOW_REGRESSIONS_0.3.2.md) and
[release policy](docs/RELEASE_POLICY_0.3.2.md) distinguish implemented behavior
from completed validation. Final current-build regression, independent geometry
proofs, controlled performance, installation and portable-example acceptance
remain open. No qualified 0.3.2 installer has been delivered.

Placement is static and upright on horizontal support, with explicit receiving
and obstacle references. Bounded geometry, fit and packing checks may leave valid
but difficult spaces unfilled; this is not a physics simulation or an optimal
packing guarantee. See the guide for support, collision and path scope.

Historical checkpoints and their exact source identities remain in the
[documentation index](docs/README.md). Counts from different builds are separate.
The [automatic sampling contract](docs/REGION_SAMPLING_IDENTITY_0.3.2.md),
[gallery support investigation](docs/GALLERY_SUPPORT_0.3.2.md) and
[owned startup investigation](docs/STARTUP_FAULT_0.3.2.md) record current release
work and its limits.

## Qualified 0.3.1 workflow

Cyrus Arrange places accessories on furniture in **3ds Max 2027**. Native C++20 owns geometry, seeded placement, collision checks and saved scene state; MAXScript provides the controls.

The main workflow is **choose furniture → add props → Generate**. New arrangements have a selectable viewport icon and an actual **Cyrus Arrange** modifier with controls in Modify. The main and advanced windows use the same saved arrangement. Generate chooses a fresh seed by default; **Repeat seed** repeats a variation. **Advanced...** retains surface rules, category limits, book rows, Preview/Commit and Live controls.

**0.3.1 is qualified for the documented Max 2027 workflow.** Install the [matching MZP](dist/CyrusArrange-0.3.1/CyrusArrange-0.3.1-Max2027.mzp) through **Scripting > Run Script**, then restart Max. The [source and examples archive](dist/CyrusArrange-0.3.1/CyrusArrange-0.3.1-Source-and-Examples.zip) contains the exact code, current documentation and scenes. See the [release record](docs/RELEASE_VALIDATION_0.3.1.md) for the exact pair, twenty functional suites / 3,809 checks, native icon, saved-scene Modify controls, three actual Corona renders and 43 installer / 17 automatic-startup checks. The [scope](docs/REAL_WORLD_0.3.1.md) preserves the acceptance contract.

The [real model example](examples/real-world-0.3.1/README.md) contains the coffee and side tables, original full-size books, complete plant, decor, all 131 maps and previews. Open it after installing 0.3.1; select **REAL_Coffee_Arrange → Modify → Cyrus Arrange → Generate**. Adopt the file's millimetre unit scale when prompted. This example uses Corona 15. The earlier [0.3.0 installer](dist/CyrusArrange-0.3.0/CyrusArrange-0.3.0-Max2027.mzp), [source and examples](dist/CyrusArrange-0.3.0/CyrusArrange-0.3.0-Source-and-Examples.zip) and [TV/shelf example](examples/simple-0.3.0/README.md) remain unchanged; that earlier installer does not register the new modifier classes.

Start with the [simple workflow](docs/SIMPLE_WORKFLOW.md), [detailed quick start](docs/ARRANGE_QUICKSTART.md) and [documentation index](docs/README.md). The [0.3.0 workflow decisions](docs/WORKFLOW_IMPROVEMENTS_0.3.0.md) explain the changes. The [purchased Scatter Tools research](docs/research/SPLINE_DYNAMICS_LOCAL_RESEARCH_2026-10-18.md) records the exact supplied archive, observed source logic and limits; [browser video review](docs/research/UX_VIDEO_PLAYBACK_REVIEW_2026-10-18.md) records actual timestamped visual observations and audio limits.

## Using the preserved 0.3.1 interface

The instructions in this section apply to 0.3.1. Use the development guide above
for the redesigned 0.3.2 controls.

Run the qualified matching MZP from **Scripting → Run Script**, then restart Max 2027. Your existing Cyrus Arrange toolbar action opens the new window. To open it without a toolbar, press **F11** and run:

```maxscript
macros.run "Cyrus" "CyrusArrangeStyling"
```

Select a new arrangement's cyan icon, open **Modify**, and choose **Cyrus Arrange** in its stack. You can also add **Cyrus Arrange** from the Modifier List to furniture and use its explicit furniture action. See [the Modify panel guide](docs/MODIFY_PANEL.md).

To add a toolbar button, use **Customize → Customize User Interface → Toolbars**, choose the **Cyrus** action category and drag **Cyrus Arrange** onto a toolbar. **Arrange Inspector** opens the separate geometry inspector.

Select the furniture, choose its type and click **Use selected furniture**. In **Props...**, select several original accessory models/groups, choose their shared category and click **Add selected props**. Use **Create decor group** to copy a prepared cluster into one reusable source asset. Return to the main window and click **Generate**. With a prepared example scene, choose its saved arrangement and Generate immediately.

Installation is per-user and retains previous version payloads. Development qualification uses hidden disposable profiles and does not install into the artist profile or command an existing Max session. The MZP documentation is frozen before installer testing; its external qualification receipt records the final installation result, and workspace/source-archive documentation records subsequent qualification.

Placement validates whole-footprint support, conservative accessory bounds, explicit obstacles and optional front approach. Support detection depends on the sampling grid; conservative bounds can reject tight fits. Categories and compartment labels are authored intent. The plugin does not automatically understand furniture semantics or simulate falling objects. All interface distances are millimetres independent of display units. Amount is a density target rather than an exact item count.

## Build and test

Windows x64, Visual Studio 2022 C++ tools **14.38.33130**, Windows SDK **10.0.19041.0**, CMake, Python 3.10+ and the **3ds Max 2027 SDK** are required for the native extension. Autodesk SDK files are external prerequisites, not redistributed here. The native fit core includes the pinned, licensed Clipper2 source under `third_party/clipper2`; it has no online service dependency.

From this directory, using new output folders for each run:

```powershell
python tools/build.py --output build/native-candidate
python tools/run_max_tests.py --binary-dir build/native-candidate --output build/host-native --test-script tests/max/arrange_native_tests.ms
python tools/run_max_tests.py --binary-dir build/native-candidate --output build/host-workflow --test-script tests/max/arrange_workflow_tests.ms
```

`build.py` accepts `--sdk "path/to/maxsdk"`; its default locates the existing parent workspace's extracted 2027 SDK. `--core-only` builds native tests without Max. CMake can also be used independently with `-DCYRUS_ARRANGE_BUILD_MAX=OFF`.

The runner copies the exact DLL/UI/test scripts to an owned run folder and creates a private Max INI and plugin path. Geometry suites use Max 2027 Batch; the Modify suite uses a hidden normal Max process so a real command panel exists. It never attaches to existing Max sessions. A per-process token, private INI and native-path guard run before fixtures. Receipts record loaded module identity, source hashes and preservation of artist INI files. On timeout, inspect the recorded owned PID and outputs before issuing another run. The runner does not authorize terminating other Max processes.

Current 0.3.2 packaging requires 32 matching functional host receipts, seven independent geometry proof families, and two serial opposite-order backend performance runs with a truthful isolation record. The exact candidate MZP must then pass private installation and a fresh process's automatically discovered installed startup before qualification. Only the native `bin/` directory is registered as a plugin path; scripts load through the startup loader. The installer preserves older payload versions and rolls back configuration on failure. See the release policy for the complete evidence requirements and scope; the preserved 0.3.1 release used its own earlier policy.

## Components

| Component | Responsibility |
| --- | --- |
| `include/cyrus_arrange/geometry.h`, `src/geometry.cpp` | Owned geometry values, support sampling, clearance, connected regions, limits |
| `src/max_bridge.cpp` | Host mesh snapshot, units/transforms, native result cache, overlays, JSON export |
| `src/assets.cpp`, `src/contact_base.cpp`, `src/arrangement.cpp`, `src/placement_queries.cpp`, `src/collision_proxy.cpp` | Source metadata, contact bases, deterministic quantity/fit/packing and bounded physical validation |
| `src/path.cpp`, `src/path_capture.cpp` | World arc-length placement, local variation, two-way lanes and host spline capture |
| `src/arrange_bridge.cpp`, `src/arrange_document.cpp`, `src/storage_plugin.cpp` | Native scene commands, retained state/references, instances, Undo, persistence and Manual/Live dependencies |
| `src/arrange_presentation.cpp`, `scripts/ArrangeModifier.ms` | Native icon and pass-through modifier, hosted MAXScript parameter view over the same native document |
| `scripts/CyrusArrange.ms` | Artist commands and bounded summary presentation |
| `scripts/ArrangeAssets.ms`, `scripts/ArrangeWorkflow.ms`, `scripts/ArrangeRegions.ms`, `scripts/ArrangeCollision.ms` | Accessory library, arrangement, surface rules and explicit obstacle controls |
| `tests/geometry_tests.cpp` | Independent numerical fixtures and rejection cases |
| `tests/max/` | Procedural furniture and actual Max/UI workflow tests |
| `tools/`, `installer/` | Isolated compilation/host qualification and matched MZP packaging |

## Documentation

- [Documentation index](docs/README.md)
- [Implementation contract and acceptance](docs/IMPLEMENTATION.md)
- [Full-system goal and completion evidence](docs/GOAL.md)
- [Asset library and arrangement workflow](docs/ASSET_LIBRARY.md)
- [Arrangement quick start](docs/ARRANGE_QUICKSTART.md)
- [Original examples and measured scope](docs/EXAMPLES.md)
- [0.3.0 release validation](docs/RELEASE_VALIDATION_0.3.0.md)
- [0.3.1 release validation](docs/RELEASE_VALIDATION_0.3.1.md) and [real model scene guide](docs/REAL_WORLD_SCENE.md)
- [Preserved 0.2.0 release validation](docs/RELEASE_VALIDATION_0.2.0.md)
- [0.1.1 release validation](docs/RELEASE_VALIDATION_0.1.1.md)
- [0.1.2 qualified release](docs/RELEASE_VALIDATION_0.1.2.md) and [book-row workflow](docs/BOOK_ROWS.md)
- [Seeded placement and limits](docs/PLACEMENT.md)
- [Native scene ownership and lifecycle](docs/SCENE_OWNERSHIP.md)
- [Geometry algorithm and resolution limits](docs/GEOMETRY.md)
- [Native/MAXScript API](docs/NATIVE_API.md)
- [Arrangement/MAXScript API and record contracts](docs/ARRANGEMENT_API.md)
- [Artist guide](docs/ARTIST_GUIDE.md)
- [Qualification and exact deliverable](docs/QUALIFICATION.md)
- [Next milestones](docs/ROADMAP.md)
- [Earlier full research report](docs/research/3ds-max-interior-styling-research.pdf) and [research data](docs/research/research-content.json)

Research documents describe options and future capabilities; the current implementation and qualification documents define what this release actually does. All project source, documentation, owned build runs and delivery packages live inside this directory. Existing Cyrus Scatter, Surface Analyzer and Physics Lab are independent products.
