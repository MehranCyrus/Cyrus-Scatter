# Cyrus Arrange 0.1.0 qualification — 17 October 2026

The geometry-inspector milestone is built and qualified for the scenarios below. All source, docs, procedural assets, build runs and packages are inside `F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusArrange`. Three subagents implemented the numerical core, native adapter, and UI/fixtures; the root integrated, reviewed and ran the final qualification.

## Delivery

- [Max 2027 MZP](../dist/CyrusArrange-0.1.0/CyrusArrange-0.1.0-Max2027.mzp)
- [Package hashes and inventory](../dist/CyrusArrange-0.1.0/package-receipt.json)
- [Original procedural demo scene](../examples/CyrusArrange-Inspector-Demo.max)
- [Actual Max render](images/inspector-demo.png)
- [Artist guide](ARTIST_GUIDE.md), [native API](NATIVE_API.md), [geometry limits](GEOMETRY.md), [next milestones](ROADMAP.md)

Run the MZP through Scripting → Run Script, restart Max 2027, then use Cyrus → Cyrus Arrange in Customize User Interface. The installer was packaged and verified but was **not executed in the artist profile**. Its install/startup bodies compiled in the owned Max host without performing installation. Actual fresh-recipient installation/restart remains an acceptance step. No EXE installer, code signing or automatic installation is included.

## Final evidence

| Boundary | Result | Receipt |
| --- | --- | --- |
| Max 2027 SDK build | Passed, C++20, x64 Release, MSVC tools 14.38.33130 / compiler 19.38.33145.0, Windows SDK 10.0.19041.0 | [native-04](../build/native-04/receipt.json) |
| Pure C++ geometry | 13 suites passed, CTest target 0.08 s in final run | [test log](../build/native-04/tests.log) |
| Max host/UI | 69 checks passed, 0 failures, actual Max 2027.1 / 29.1.0.11426 | [host-04](../build/host-04/receipt.json), [checks](../build/host-04/result.txt) |
| Native export | Five strict JSON documents independently validated against analytic fixture expectations | [JSON validation](../build/host-04/json-validation.json) |
| Illustrative scene/render | Passed in a separate owned Max batch process; Scanline render inspected visually | [demo-01](../build/demo-01/receipt.json) |
| Package | Exact native/UI payload and archive member bytes verified; ZIP CRC passed | [package receipt](../dist/CyrusArrange-0.1.0/package-receipt.json) |

The runner used copied, frozen scripts/DLLs, a private INI, private plugin path and new hidden Max processes. Loaded DLL paths matched those private copies. The recorded artist `3dsMax.ini` and `Plugin.UserSettings.ini` hashes remained unchanged. No computer-use API, desktop clicking, artist-scene reset, normal-profile installation, Git commit/push or parent-product changes were performed by this task. All owned Max test processes exited normally.

Final native SHA-256:
`f2fd285dcda0f92ac995a55ff35f4d59479ed6397222d43b8e490b6454660ec0`

Final UI SHA-256:
`8cbd683347b94e94d0bfb0f4e40a1749fcc1e7d9772f01d777776dfbf4cde926`

The native build receipt pins 17 implementation/test/tool/installer source files. The package receipt pins the actual shipped file bytes. Build and host folders are ignored local evidence; preserve them separately when distributing a source-only checkout.

## Covered behavior

Native fixtures cover known surface heights/areas, multiple shelf layers, overhead/corner obstructions, ring holes, disconnected supports, slopes, mirrored winding and nonuniform scaling, nearby cover, touching divider bottoms, distinct-height closed-shell overlap, invalid/degenerate geometry, all resource-limit families and deterministic output. A zero minimum-clearance setting still rejects occupied zero-clearance samples.

The Max campaign invokes real production rollout button handlers. It checks group expansion and deduplication; world-axis dimensions; expected shelf heights; native/UI failure retention for empty selection, helpers, invalid settings and excessive sampling; overlay creation/deletion Undo and Redo; generated-overlay exclusion; quoted Unicode source names; source mesh/transform/name preservation; mirrored/rotated/scaled geometry with independent host bounds; centimetre unit conversion; passive panel reopening; JSON export; scene save/reopen; saved overlay tagging; and explicit native-cache clearing.

At 25 mm spacing, the TV console returns 5 support regions / 3,780 supported cells / 3,708 usable cells. The shelf returns 5 support regions / 3,136 supported cells / 3,080 usable cells. Regions are connected sampled support patches, not semantic cabinet compartments. Export validation checks that the known central hole remains empty and that sampled divider footprints have zero clearance and are unusable.

## Corrections made during qualification

The first host fixture needed explicit MAXScript global forward declarations; this was a test binding failure. A second fixture used signed scaling followed by rotation, which Max decomposed into an upside-down transform; an explicit affine matrix plus independent host-bound checks corrected the oracle. The core initially treated coplanar divider bottoms as free space; direct coincident-face rejection, conservative crossing checks and new regressions corrected that case. Passive panel reopening initially lost displayed results; the new read-only `caSummary()` restores the current native snapshot without evaluating geometry. Early runs remain preserved as iteration evidence, not final passes.

## Limits

This is sampled support inspection, not certified accessory fitting, exact polygon reconstruction, general solid classification, automatic furniture recognition or decoration scattering. Narrow features between samples may be missed. Independent shells sharing crossing heights and mixed open/nonmanifold meshes can leave occupancy ambiguous; see the explicit example in [GEOMETRY.md](GEOMETRY.md). Dimensions are world-axis bounds. Source changes require reinspection. Geometry outside the captured selection is excluded.

Physical mouse/DPI behavior, prolonged artist sessions, arbitrary imported/proxy models, allocation/device-loss failures and production renderer integration are not qualified. The demo proves a standard Scanline render of ordinary fixture/overlay meshes, not a renderer-specific procedural plugin integration. No sustained FPS, universal performance or exact peak-memory claim is made. Automatic accessory arrangement is future work.
