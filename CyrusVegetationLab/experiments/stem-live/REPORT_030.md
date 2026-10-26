# Vegetation Preparation Lab 0.3.0 — Max 2027 qualification

24 October 2026. Independent prototype; CyrusScatter remains 0.86.9.2/schema 59. User-authorized scope: a reusable Model Preparation foundation around the successful stem-guided lavender interaction. No Scatter layer integration, wind or tree dynamics is claimed.

## Delivered behavior

A scene-root native catalog owns stable model records and source/output references. The panel adds/removes records, captures a source, runs native ordered-tube analysis, draws inferred guides/root markers, records explicit review acceptance and prepares the interactive model. Original scene objects remain after catalog removal. Eight monotonically allocated slots are available per catalog; removing a row does not reuse its ID. Source edits invalidate review; publication rechecks the exact captured geometry fingerprint. Failed/cancelled successors keep earlier preparation/output. Native geometry evaluates changed sphere dependencies; idle UI polling does not rebuild geometry or analyze the source.

The worker consumes owned SI position/face/material arrays, with no SDK access. Host capture, fingerprint recheck and publication remain on the Max thread. Cancellation is cooperative between bounded loops/stages. Document destruction joins the job; closing the panel requests cancellation. MAXScript is the thin UI/command layer. Model catalog Undo states share immutable analyses; prepared geometry serializes bindings and accepted poses separately. DLO alone registers the geometry and preparation classes; DLX exports the primitives, preventing the earlier duplicate-class warning.

## Executed evidence

- Native build: `build/vegetation-preparation-plugin-20261024-05/receipt.json`, MSVC 19.38 / C++20 Release, Max 2027 SDK. Exact source, frozen/private-header, three reused static-library and binary hashes recorded. Those static libraries come from the previously verified collision/fitter/Jolt build; this delivery does not claim to rebuild or requalify all upstream research.
- Headless `preparation_test.exe`: ordered synthetic tube, deterministic metadata, bad indices, nonfinite input, cooperative cancellation, unsupported triangle, actual lavender detection. `stem_kernel_test.exe`: nine successful sphere positions, rest reconstruction, saved-pose round trip and independently checked delivered float geometry. Both exited 0; commands/logs and source hash comparison in `test-receipt.json` and adjacent logs.
- Owned Max 2027: `build/vegetation-preparation-host-20261024-05/receipt.json`, exit 0. Add/Analyze/Review/Prepare; acceptance Undo/Redo; prepared node creation Undo/Redo with restored catalog reference; automatic sphere sweep; twenty unchanged idle reads; cancelled successor retention; in-flight source-edit rejection; unsupported box rejection; catalog removal Undo/Redo; saved catalog/output reopening; guide overlay; full viewport and full Scanline render. Artist INI unchanged. Original source asset was only read; the test scene is a new derivative.
- Physical pointer witness, earlier native 04 with the same interaction body: `build/vegetation-preparation-pointer-20261024-01/receipt.json`, exit 0. A real injected Move-gizmo drag changed sphere X from 0.500 m to 0.349 m, produced another accepted pose (27 active stems) and rebuilt the light viewport. The tool's short stroke captured zero left-button-held samples. This proves a pointer-driven update, not continuous publication while the button remains held. Final build 05 retains that interaction code and adds catalog-row removal; its direct host sweep passed separately. Held-drag latency remains an explicit acceptance gate.

## Actual model and costs

Original `A084 - Lavender - 05/model.max`: SHA-256 `78e8b37e7f08c4a52050a4f274da5b6de3baad886b41b0327ffe69359a5e41a3`; 577,792 vertices, 832,240 triangles. Native analysis finds 1,290 stem guides / 27,486 connected parts / one ground root, reproducing the prior source geometry hash `37c47c41a072fcada508951380cb22ffb4693228e5949d4c44ec68b8fc5c2650`. Maximum inferred parent separation: 6.897 mm. Foliage attachment distances reach 88.303 mm; inspect the inferred anatomy.

Default preview: 69,736 triangles. Native numeric analysis: 0.278 s; explicit capture/worker/poll wall time: 715.84d0 (Stopwatch milliseconds). Initial binding/cache realization is a separate cost; this fresh reopen measured 3335.2 ms. Warm viewport builds during the changed-sphere sweep ranged 7.51–31.47 ms. A cold build after node creation Undo/Redo took 4207.3 ms; these are CPU evaluation/build measurements, not presented FPS. Cached model preparation is reused during sphere movement. The numeric analysis timing excludes file loading, review, binding and renderer work.

Full delivered float mesh at X=0.42 m / sphere radius 0.167 m: minimum surface gap 8.703 mm; root-ring error 1.93e-09 m; 1674168 rigid-part edge comparisons, zero changes above 10%, maximum relative change 0.01748%. Maximum stem triangle-edge change was 27.95%. Stem volume/cross-section preservation therefore needs improvement even though the measured pose cleared the sphere and preserved rigid foliage well. Full mesh audit took 162.8 ms and is explicit, not run every drag update. The contact solver includes a bounded rigid socket hinge fallback for difficult child stems. A successful guide fit is not universal visible-mesh collision certification.

## Identity

- `CyrusVegetationStemLab.dlx`: `122ad3060e4e0eacea23cf28990c39f3fa904ff04011b4257a2704523f534d61`
- `CyrusVegetationStemGeometry.dlo`: `26b6f572a3e25779a03f6b1e62f2f05c605c3a0db66486ab1e796b2d4c112391`
- Core frozen contract remains SHA-256 `f5c9b72e513a1c6ceea74f79bc0005175381691b65c99af47dc2debaebc7e42f`.

## Limits and next acceptance

The analyzer supports separated ordered round tubes with authored base-to-tip order; it is geometric inference, not a universal automatic rig. No manual guide editor/import, multiple collider manager, wind, inertia, plant self-collision or production Scatter integration exists yet. Authoring settings apply on Analyze. Catalog removal preserves scene objects and high-water IDs. Bounds and cancellation limitations are detailed in GUIDE_030.md / PLAN.md; actual process peak memory, global catalog/history admission and cancellation inside host conversion/serialization are unqualified.

The renderer/full conversion uses the source topology and current guide pose, while the viewport uses an approximation. Only the supplied Scanline/material test is qualified; original Corona/texture/opacity/explicit-normal fidelity is not. A failed fit can show an older pose relative to the current sphere. Missing/changed source geometry after a cold reopen is not qualified for retained output recovery. Keep prepared output transforms locked and source geometry, source transform and units unchanged. New scenes with arbitrary edited/merged flora need explicit validation.

Before Scatter integration: instrument sustained human-held dragging, improve stem deformation/attachment review, test additional botanical source families, add authored-guide correction/import, evaluate multiple collider influence bounds, qualify render/Undo/lifecycle under production scene pressure and measure total memory. The original research's 68 cases and 8 experiments keep their own Pending/observed status; these focused tests do not close that matrix. Wind/tree modes require their own time/state/cache and validation contracts.

Package CRC/payload hashes are in package.json. Installer/fresh-open execution receipts, when run, are separate from this source/host report; do not infer package execution merely from ZIP generation.
