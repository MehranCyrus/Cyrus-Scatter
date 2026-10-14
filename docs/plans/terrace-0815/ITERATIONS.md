# Terrace production-scene work — 0.81.5

13 October 2026. User-authorized goal: use a copy of `Test Scene/Terraces Buiding Test.max`
to reproduce the supplied planted landscape using the scene's models and Cyrus
Scatter; investigate and fix population limits, source/layer/UI behavior, caching
and performance; test the completed workflow and render through `PhysCamera002`.
The full requested result remains the acceptance target.

Version decision: the user explicitly selects **0.81.5** for this delivery. The
baseline is 0.81.3/schema 58, HEAD `2b9ad12b24f9d91241db4567037f64db71fe9726`
plus existing modifications. Capacity/identity contract changes may exceed the
normal patch classification; the requested label takes precedence. Schema and
native interfaces will change only if their actual contracts require it. Analyzer,
licensing and MCP remain separately versioned. No release certification is implied.

## Required final evidence

- Preserved original scene hash, owned working/final copies and asset references.
- Current scene inventory: receiver geometry, sources/materials, layer ownership,
  amount/masks/errors, render settings and `PhysCamera002` composition.
- Population above 100,000 through the real UI/native/publication/render path,
  explicit finite resource bounds and useful error reporting, stable identities,
  failure retention, save/reopen and relevant Undo/Redo.
- Correct independent layers, local/global containers, source parking/settings,
  receiver assignments, Amount/density, model/Point/Empty and relevant layout,
  transform, spacing, coverage, exclusion and display controls exercised in
  meaningful fixtures and the project scene.
- Responsive rectangle creation/selection and cached viewport navigation measured
  separately from calculation, preview preparation, upload and render output.
- Editable greenery covering the intended terraces: ground cover, coherent pink,
  yellow and pale flower ribbons, shrubs and framing trees, with the path/building
  kept readable. Use the supplied reference as the visual target and inspect
  actual rendered revisions rather than substitute an unrelated demonstration.
- Final saved scene reopened and rendered through `PhysCamera002`, with the actual
  generated population/materials and no unresolved Scatter/render errors.
- Matched 0.81.5 source/native packages, focused offline/host regressions, truthful
  feature coverage and remaining limitations; docs and website source descriptions
  aligned with the delivered behavior. Installation/publication is tracked
  separately from source/build/scene work.

## Current evidence

- The baseline had a deliberate 100,000 candidate/population ceiling in both UI
  and native receiver/procedural validation, plus a 1,000,000 root admission
  ceiling. Candidate changes extend each population to 1,000,000 while retaining
  the shared root cap. Ordinal pages preserve existing IDs below 100,000 and
  prevent higher ordinals from aliasing another receiver's 131,072 stride.
- The screenshot reports `Layer_01 | 100.0k | Error`, 24 active/registered sources,
  Live mode and Texture Density. All 11 receivers lack UV channel 1, reproducing
  `Surface requires UV channel 1`. The candidate identifies the failing receiver
  and the mapping/Layout remedies while retaining preceding output.
- The prior [container investigation](../../Source_Containers_Performance_2026-10-13.md)
  provides measured current-source causes, not a delivered fix.
- Knowledge retrieval remains stale; current source inspection is authoritative.
  Original artist Max processes are separate from all owned test hosts.

### Candidate evidence (work remains)

- Original copied and hashed by `tools/terrace_0815/prepare.py`; baseline receipt
  and frozen source are in `build/terrace-0815-20261013-01`. The 831 MB original
  scene is not an output target. `Terraces_0815_Prepared.max` adds receiver UVs,
  resolves local texture paths, replaces missing lighting/rock materials, removes
  recorded Missing_OSM/Missing_Light placeholders and creates Corona sun/sky in
  the owned copy. Its 960x540 `PhysCamera002` lighting draft is an empty-scene
  checkpoint, **not the requested planted result**.
- `native-2027-01` passed 27 native tests and generated 150,001 instances in Max,
  retaining all original 100,000 IDs/full transforms. Its million-instance host
  run exposed a real failure: point preparation copied every input transform and
  exceeded the unchanged 64 MiB owner allowance. Preserve that failure receipt.
- `native-2027-02` validates every point input but reads transforms only for the
  bounded displayed samples. It passed 27 native tests. Matched script fingerprint
  `c72c820355badc43c89b32a8c7451fd0091f252420cfa34d36aa7c55bf203175`, native
  interface 10; schema remains 58 because existing saved recipe/identity semantics
  are preserved. MAXScript loaded successfully in an isolated Max 2027 process.
- `foundation-terrace0815-candidate2027-02/capacity-host-01.json`: 14 host checks
  passed, including the Amount control at one million, 1,000,000 accepted
  placements (10.26 s update in a simple mesh fixture), total-admission rejection
  with complete publication retained, actionable UV failure, error recovery and
  150,001-instance save/reopen identity parity. This is not a million-instance
  renderer or artist-scene performance claim.
- User confirmed rectangles are selected for moving/resizing and do not need the
  full Scatter editor. Generation now gives them only `containerUI`; all Scatter
  settings remain on the controller. Label refresh no longer captures movement
  hierarchies. The redundant final creation refresh is removed.
- Eight compact rectangle selections measured median 169 ms (range 142–181 ms)
  versus the earlier full-view median 5,908 ms. Actual opened creation buttons
  measured layer/global medians 160/176 ms versus 353/410 ms. These are bounded
  private-host measurements, not presented viewport FPS.
- At 250 active source boxes, labels-only refresh measured 1.45 ms. Creation and
  selection retained Manual publication/preparation. The following movement
  assertion failed while an enclosing Undo hold was open; this is inconclusive
  for product movement. A fresh native-event fixture is required before claiming
  movement/Undo acceptance. Failed Python/native receipts remain preserved.
- Fresh `foundation-terrace0815-candidate2027-03/container-native-fresh.txt`
  subsequently passed native whole-node Move, Undo, Redo and resize with 20
  collected sources and explicit no-enclosing-hold checks. The earlier Python
  failure is not counted as a product failure or a passing movement test.
- Generator integration and UI generator assertions passed. MCP/tools pytest:
  **161 passed**. Max 2026, full garden, rendering, final docs/package and complete
  workflow acceptance remain open.

## Next work

Complete native container movement qualification, inspect the exact terrace
footprints, and iterate the actual planting design and acceptance tests. Keep
failures and intermediate render receipts. Do not mark this goal complete until
the full final evidence above is inspected and satisfied.

### Real-scene render findings and later script candidate

- The actual copied scene now has eight editable planting layers. The first
  publication generated **220,000 grass/clover placements** plus separate flower,
  shrub, palm and tree populations. `PhysCamera002` renders and saved checkpoints
  are under `Test Scene/Terraces_0815`. Early images are design iterations, not
  final acceptance. The original building, camera and receiver surfaces remain.
- The first render exposed a genuine source-frame mismatch: Particle Flow's
  Shape Instance includes source-node scale, while native display, Auto Radius
  and instance transforms use pivot-local geometry. A unit box with source scale
  `[2,3,4]` and pivot offset had a **111-unit** displayed/rendered bounds mismatch;
  mirrored scale reproduced it. `render-scale-01.json` preserves the failure.
- The render bridge now snapshots evaluated source geometry before normalizing
  its node frame. One transient prototype is reused per distinct source. Original
  source transforms/materials are not changed, and ordinary render cleanup owns
  these prototypes. Corona proxy resolution remains before snapshot evaluation.
  The corrected Max 2026 bounds witness passes unit, nonuniform and mirrored
  source scales (maximum observed bounds error below 0.00001 units).
  This scripted witness does not qualify all third-party sources or modifiers.
- Script candidate SHA-256:
  `6e75dfbb64b31d2fee3b4fdb0fc71bcf6b63aca4fe1b4d9e62323b4bdea09dbd`.
  It is being rebuilt into matched 2026/2027 receipts. Earlier capacity/selection
  receipts retain their preceding script identity; they are not relabeled.
- Max 2026 candidate 01 passes the million-count/save-reopen campaign and a
  subsequent **89-check** regression run: four point sampling/validation checks,
  17 retained publication/upload checks, 11 real generated-control workflow
  checks, eight Manual/Live invalidation checks and 49 injected publication
  failure/recovery checks. Adapters change owned-profile/root paths only and
  record original/adapter hashes. Harness corrections and failed runs are kept.
- Ray inspection of pale terrace bands found no visible geometry: the source
  scene contains open gaps between receiving surfaces. Retaining-wall infill is
  being added only to the working copy. A combined source made from copies of
  the existing trunk/leaves pair supplies a complete branching foreground tree.
  Imported flower library assets have resolved local textures. Further camera,
  material, planting and haze refinement plus final reopen/render remain open.
