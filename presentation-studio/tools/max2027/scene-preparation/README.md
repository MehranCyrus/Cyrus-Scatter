# Cyrus scene preparation — private 0.1.0

Prepare an owned copy of a heavy Max scene, export it, optimize the GLB and validate it against Cyrus Presentation Studio's supported numeric/resource subset. This standalone Python/MAXScript/Node tool does not install a plugin or attach to an existing Max session. The [building study](../../../../docs/plans/landscape-presentation/BUILDING_STUDY.md) records two byte-identical complete building reproductions, the owned native fixture, prepared-Max reopening and actual studio roundtrips. This is qualification of the documented static workflow, not arbitrary Max scenes or renderer equivalence.

## Run

Requires Windows, **3ds Max 2027**, Python 3.11 or later, and the studio's Node 22.14+ dependencies (`npm ci` from `presentation-studio/`). Run from `presentation-studio/`:

```powershell
python tools/max2027/prepare_scene.py "F:/path/source.max" "exports/my-scene-run" --plan
python tools/max2027/prepare_scene.py "F:/path/source.max" "exports/my-scene-run"
```

`--plan` validates inputs and prints the effective recipe without launching Max or creating output. Every real run needs a **fresh output directory**. The original is copied and hash-checked. A new private Max 2027 profile processes that copy, then closes before the output is published. Artist sessions and profiles remain separate.

The default [conservative recipe](recipes/conservative.json) retains geometry, source material assignments, texture encoding and origin. It shares/deduplicates equivalent resources and uses the qualified lossless Meshopt codec. Unsupported source materials that produce the native exporter's `fallback Material` are rejected instead of delivered as black surfaces. Missing dependencies are recorded; they cannot be recovered automatically.

For the supplied building, use the explicit [building recipe](recipes/building.json):

```powershell
python tools/max2027/prepare_scene.py "../Test Scene/Big building.max" "exports/building-repeat" --recipe tools/max2027/scene-preparation/recipes/building.json
```

That recipe authorizes named-layer reduction, protected facade/window/glazing layers, a recorded coordinate translation, artistic scalar/material/texture replacements, selective post-export simplification, support normal reconstruction, WebP preparation and quantization. It depends on the generated texture assets retained in `exports/building-20261016/textures/`. Its artistic materials approximate unavailable source resources; they do not reproduce a Corona render.

## Output and failure handling

Successful results appear together in `<output>/delivery/`:

- `optimized.glb`: static, embedded textures, distinct source placement IDs and useful layer groups.
- `prepared.max` and `textures/`: prepared derivative with source controllers/hierarchy below the explicit origin parent. Max bitmap paths point at this final delivery's texture directory; re-path them if moving the Max scene.
- `native.glb`: useful pre-post-processing comparison.
- `uncompressed.glb`: serialized baseline before lossless Meshopt compression.
- `recipe.json`: portable effective recipe with relative texture paths, suitable for another fresh run.
- `report.json` and audit sidecars: source/output/tool hashes, settings, units, counts, timings, missing dependencies, material decisions and codec/admission results.

`working/` retains the verified input copy and staged recipe textures. `run.json` identifies the exact owned Max process, profile, request, source and tool versions. A failed run leaves diagnostics and `delivery.partial/`; it does not replace another output or publish a final GLB. Preserve those records when investigating a failure.

Entity IDs include the input file's SHA namespace and original node handle. Repeating the identical source preserves those IDs; editing/saving a different source file changes its namespace and requires explicit replacement review in the studio. The building study demonstrates assigning the new layer groups while retaining the studio's layer UUIDs, camera and presentation settings.

The one-hour default native wait can be changed with `--timeout` (30–7200 seconds). An expired observation **does not restart or kill Max**. Inspect the recorded process and exact request/result. To resume waiting for the same unchanged native request or its shutdown:

```powershell
python tools/max2027/prepare_scene.py --resume "exports/my-scene-run"
```

Resume checks process identity and tool hashes. It does not retry a failed worker or relaunch a host. Post-processing failures require inspecting the staged artifacts and using a fresh run after a repair. The owned host remains available after native failures; close only that recorded session with `host-workflow.py close --session <run-directory>` when it is no longer needed.

## Recipe choices and limits

Recipes are closed JSON version 1. Unknown/duplicate fields, invalid ranges, ambiguous layer rules and missing substitution textures are rejected before Max starts. Material rules use either an exact `sourceName` or a case-insensitive wildcard `pattern`, in order; the first match wins. Explicit colours require `srgb` or `linear`. Substitutions and approximation labels remain in the audit. MultiMaterial slot IDs and per-instance assignments are retained.

Max 2027's native glTF exporter ignores nonconsecutive MultiMaterial IDs in the tested `[3,7]` case. Export-only clones compact the face/slot IDs to `1..N`, reuse geometry when source ownership and mappings agree, and retain per-instance materials. The tool deletes those clones before saving `prepared.max`, which keeps the original IDs, hierarchy and instances. `export-material-ids.jsonl` records each normalization. An unmapped face ID fails the run. The owned fixture verifies both exported colours and original IDs after reopening; the building's 41 MultiMaterials already use consecutive IDs and need no clones.

Shared geometry uses the most conservative member-layer rule, including hidden members. Accepted native reductions freeze immediately and reconnect their original instances. Source handle/name/layer/material/parent/world-transform checks guard that operation. A protected or unmatched post-export layer prevents simplification of a shared mesh. `crease45` normal reconstruction, quantization and texture resizing/re-encoding are explicit lossy choices. The configured relative simplification error is not a measured world-surface error guarantee.

Static GLB uses the chosen `bakeFrame`. Canonical translation is metres, Y-up. Recentring uses one static identity parent and checks source controller key counts plus sampled animated world poses across the native animation range; it fails if errors exceed 0.1 mm or basis tolerance 0.00001, or validation would exceed 20,000 poses. The prepared Max keeps its original source cameras, including unsupported third-party classes, but the separate [camera exporter](../README.md) accepts only its documented native camera types. Author the final camera in the prepared scene and avoid a second origin/unit conversion in the studio.

The native working GLB ceiling is 2 GiB. The optimized asset must pass the application's existing file, geometry, image and decoded-resource admission. Those limits do not promise performance on a particular device. A published result still needs visual review and a runtime check at the intended camera distances, viewport and quality profile.

## Reproduce focused checks

```powershell
python -m unittest discover -s tools/max2027/scene-preparation/tests -v
node --import tsx --test tools/max2027/scene-preparation/tests/post.test.mjs
```

The native fixture generator under `tests/` resets a disposable scene and is only invoked through an owned profile. Never run it in an artist session. It exercises shared owners, different materials, protected layers, UVs, mirrored/nonuniform placements, hierarchy, nonconsecutive MultiMaterial IDs, an empty mesh and an existing animated camera. The qualified output is `exports/building-20261016/preparation-end-to-end-v6/delivery/`; reopening evidence is `preparation-roundtrip-v5/`. The browser regression additionally checks red/blue face materials, sRGB conversion, layer reuse, undo/redo, portable reopening and compiled preview.

The building recipe reproductions `reproduction-v3/delivery/` and `reproduction-v4/delivery/` both produce SHA-256 `d8e30599ddc541a5c6170ec1fc27fd4c52423c02e2c0c5f218624a164056727e`: 37,070,104 bytes, 2,840,802 submitted triangles, 295 placements, 16 layers and three embedded textures. v4 records the current preparation module hashes, including the material-ID correction. Consult the building study for visual, camera, workflow and hardware-specific performance evidence.
