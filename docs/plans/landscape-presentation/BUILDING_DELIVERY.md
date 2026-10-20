# BAILEY building presentation — 16 October 2026

The supplied heavy Max scene now has a reproducible static GLB preparation pipeline, an authored Max camera, an editable studio project and a separately compiled website. Studio/player **0.1.2**, camera exporter **0.1.1** and preparation tool **0.1.0** are independent private versions. Native Scatter products and the existing website are outside this delivery.

## Open the result

In the studio at `http://127.0.0.1:5190/`, choose **Project > Open project** and select [BAILEY-editable-v2.cyrus-presentation.zip](../../../presentation-studio/exports/building-20261016/final-presentation-v1/BAILEY-editable-v2.cyrus-presentation.zip). Choose **Playback**, then Play or scrub the timeline. **Output > Compiled preview** opens the actual public player. There are 16 named presentation layers; neighbouring massing and interior fixtures start hidden, and four layers have viewer toggles.

A local-only preview of the extracted final website is available at **http://127.0.0.1:5194/** while its preview server is running. In 3D playback the public chapter heading becomes a compact caption, keeping the building visible; the introduction retains its larger heading. The v2 ZIPs are the current delivery, with v1 archives retained as historical evidence.

The [standalone website ZIP](../../../presentation-studio/exports/building-20261016/final-presentation-v1/BAILEY-presentation-v2.zip) contains the complete independent presentation. Extract all files into a separate directory and serve that directory through HTTP. For example, run `python -m http.server 5193 --bind 127.0.0.1` in the extracted directory and open `http://127.0.0.1:5193/`. Opening HTML with `file://` is unsupported. Publishing was not performed.

| Deliverable | Local artifact |
| --- | --- |
| Optimized GLB | [BAILEY.optimized.glb](../../../presentation-studio/exports/building-20261016/final-presentation-v1/BAILEY.optimized.glb) |
| Prepared Max 2027 scene with native animated camera | [BAILEY-prepared-with-camera.max](../../../presentation-studio/exports/building-20261016/final-presentation-v1/BAILEY-prepared-with-camera.max) |
| Camera animation JSON | [building-hero.camera.json](../../../presentation-studio/exports/building-20261016/final-presentation-v1/building-hero.camera.json) |
| Native authoring settings | [camera-recipe.json](../../../presentation-studio/exports/building-20261016/final-presentation-v1/camera-recipe.json) |
| Prepared Max texture assets | [textures](../../../presentation-studio/exports/building-20261016/final-presentation-v1/textures/) |
| Reusable preparation entry point | [prepare_scene.py](../../../presentation-studio/tools/max2027/prepare_scene.py) |
| Tool instructions and configuration | [Scene preparation guide](../../../presentation-studio/tools/max2027/scene-preparation/README.md) |
| Qualified building recipe | [building.json](../../../presentation-studio/tools/max2027/scene-preparation/recipes/building.json) |
| Complete preparation run and diagnostics | [reproduction-v4/delivery](../../../presentation-studio/exports/building-20261016/reproduction-v4/delivery/) |
| Historical comparisons and experiments | [BUILDING_STUDY.md](BUILDING_STUDY.md) |

Generated assets, Max scenes and archives under `presentation-studio/exports/` are ignored by Git. Preserve that folder separately. Max bitmap paths reference the local final texture folder; repath them if moving the scene. The GLB and both ZIPs embed their required browser resources.

Source IDs include the original file SHA and node handles. Identical-source repetitions retain IDs; an edited source changes its namespace and requires explicit replacement review. The current studio project preserves all layer UUIDs and camera settings through that review.

## Measured optimization

Targets were recorded before selection: preferred GLB ≤50 MiB, selected ceiling ≤100 MiB, ≤3 million submitted triangles, five-view architectural silhouette IoU ≥0.995, local import ≤15 seconds, local desktop render-interval p95 ≤33.4 ms and no steady playback uploads or rebuilds.

| Measure | Original native baseline | Final prepared GLB |
| --- | ---: | ---: |
| File bytes | 751,495,176 | 37,070,104 |
| MiB | 716.68 | 35.35 |
| Submitted triangles | 18,706,901 | 2,840,802 |
| Unique triangles | 15,282,519 | 2,297,195 |
| Embedded image resources | 0 | 3 |
| Material resources | 183 exporter fallbacks | 62 PBR materials, no fallback marker |
| Production app admission | Rejected at 250 MiB; previous scene retained | Accepted; local GLB import 3.093 s |

The delivered GLB uses **95.07% fewer bytes** and **84.81% fewer submitted triangles**. Baseline app FPS is unavailable because that asset exceeds production admission. Its analytical viewer was used solely for visual comparison.

Preparation processes 267 shared geometry owners once, reducing 56 groups. Protected primary walls, windows and glazing remain unreduced. Native evaluated scope falls from 18,733,346 to 4,398,505 triangles; those figures differ from GLB submitted counts. Max v4 load is 42.483 s, geometry preparation 237.675 s and native GLB export 28.998 s. Staged native GLB is 251,855,816 bytes; the serialized uncompressed comparison is 81,366,372 bytes. Post-export support simplification, 45-degree crease normals, explicit quantization/WebP and lossless Meshopt produce the final result.

The earlier grille study rejected reductions that visibly damaged repetitive facade details. This is the smallest practical qualified variant among tested candidates, not proof of a global size optimum. Comparison variants and rejected diagnostics remain preserved.

Independent v3 and v4 CLI runs produce the same final SHA-256. Exact decoded attributes and oriented triangle topology pass; Meshopt can rotate triangle corners cyclically while preserving winding. Ordinary serialization rounding is measured separately. Against the preceding reviewed candidate, every attribute, oriented triangle, PBR value and texture byte matches; the conservative world displacement bound from transform rounding is **0.059 mm**.

Fresh final silhouette comparisons against the original baseline pass at **0.999617, 0.999578, 0.999691, 0.999825 and 0.999854**, for establishing, street corner, reverse, courtyard and facade detail. These are strict 1320×788 projected masks without dilation; they do not measure hidden-detail retention or world-surface Hausdorff error. [Current mask metrics](../../../presentation-studio/exports/building-20261016/final-silhouette-v1/metrics.json) and [matched material views](../../../presentation-studio/exports/building-20261016/final-browser-v2/render-comparison.json) retain the evidence.

## Materials and cinematic camera

The source uses Corona materials and missing external resources. The delivered appearance is a labelled artistic PBR approximation. Generated brick, painted-timber and mineral albedos retain prompts/provenance in the study texture folder. The GLB embeds three reused WebP images. Source UV tiling outside `[0,1]` remains float rather than being clamped. Palette colours use explicit sRGB-to-linear conversion. Texture colour space, alpha, roughness, metallic response and normal data are covered by source audits, browser views and the native fixture. Architectural environment lighting, exposure 0.8 and shadows are saved in the project.

The native TargetCamera runs **36 seconds at 30 fps**, with establishing/reveal, facade approach, form/courtyard orbit and final wide composition. A **2-second presentation introduction** precedes it. Model translation is `[4000,1700,1900]` source centimetres, equivalent to `[40,19,-17]` metres Y-up; camera authoring occurs in that prepared space with no second app conversion.

The final Max scene recreates the camera data byte-for-byte. Its 4,321 export samples are compared with 8,641 independent native poses: maximum position error **0.01965 mm**, basis-vector error **0.000001169**, vertical-FOV error **0.000010781°**, and zero timestamp error. 1,012 reverse/random evaluator seeks pass. [Camera parity](../../../presentation-studio/exports/building-20261016/final-presentation-v1/building-camera-parity.json) includes authored roll and fixed 16:9 framing.

![Final building composition](F:/Cursor/_Cyrus_Apps/CyrusScatter/presentation-studio/exports/building-20261016/final-browser-v2/final-38.png)

![Facade approach](F:/Cursor/_Cyrus_Apps/CyrusScatter/presentation-studio/exports/building-20261016/final-browser-v2/final-16.png)

## Workflow qualification

Build/typecheck, **34 unit + 15 integration + 50 browser tests** pass, plus **10 Python + 5 Node preparation checks**. The current native fixture covers instance sharing, per-instance materials, hidden/frozen state, hierarchy, mirrored/nonuniform transforms, protected layers, UVs, empty geometry, animated source cameras and nonconsecutive material IDs. Both face colours survive native GLB export and browser import; prepared Max reopens with original `[3,7]` IDs. The workaround uses temporary compact-ID copies and cleans them before saving. The building needs zero such copies.

The final building passes mouse look/pan/wheel, keyboard flight, orbit, plan pan/zoom, capture/save/undo, layer undo, reverse/random timeline seeking and static resource reuse. Its portable project passes exact content reopening, autosave/reload, real menu downloads and compiled preview. The public ZIP passes bounded ZIP/CRC, schema, file-path, resource-hash and camera checks. See [studio workflow](../../../presentation-studio/exports/building-20261016/final-presentation-v1/studio-workflow.json), [save/reopen evidence](../../../presentation-studio/exports/building-20261016/final-presentation-v1/downloads-v2.json) and [regression report](../../../presentation-studio/exports/building-20261016/qualification/final-browser-regression-v2.json).

The final public ZIP also passes **180.010 seconds** of independently served nested-HTTP forward/reverse playback, covering 4.737 traversals and 10,800 observations. At 1366×768, DPR 1.5, Balanced quality and architectural shadows, RAF-observed render interval p95 is **16.8 ms**, CPU submission p95 **5.0 ms** and GPU-query p95 **6.169 ms**. Adaptive render scale changes from 0.85 to 1 during the run; these are not fixed-resolution or presented-FPS measurements. Rebuilds stay **1→1**, geometry uploads **975→975**, and all tracked GL create/delete/live counters remain unchanged. Estimated GPU resources change from 146.03 to 151.27 MB with resolution; backing storage remains about 177.45 MB. Observed JS heap is 21.22→27.31 MB without forced GC; this is not a driver-VRAM or zero-allocation claim. Draw calls are 553→586 across the measured poses, including shadow rendering. There are no runtime errors, external requests or failed requests. [Full standalone report](../../../presentation-studio/exports/building-20261016/final-presentation-v1/standalone-v2/report.json) includes layer/reset controls, reverse/random seeks, play/pause, restart, reduced motion and portrait browser checks.

Hardware is Ryzen 5 5600X / RTX 3090 24 GiB / about 96 GiB RAM, Chromium 145.0.7632.6 on Windows. A separate cold-network check at 10 Mbps and 80 ms latency shows the opening after **0.925 s** and complete 3D after **33.282 s**. This transfer time is distinct from the **3.093 s local GLB import** and **4.936 s local portable project opening**. Driver memory and physical mobile performance are not measured.

## Reproduce preparation

From `presentation-studio/`, with Windows, Max 2027, Python 3.11+ and installed Node 22.14+ app dependencies:

```powershell
python tools/max2027/prepare_scene.py "../Test Scene/Big building.max" "exports/my-building-run" --recipe tools/max2027/scene-preparation/recipes/building.json --plan
python tools/max2027/prepare_scene.py "../Test Scene/Big building.max" "exports/my-building-run" --recipe tools/max2027/scene-preparation/recipes/building.json
```

Use a fresh output name. The tool makes a verified input copy, launches its own hidden Max 2027 profile, prepares/exports, waits for that host to close, validates post-processing, rehashes inputs and atomically publishes `delivery/`. A failed run retains staging/diagnostics; a wait timeout never launches a duplicate host. The effective published recipe uses relative texture paths and can be supplied to another fresh run. Other scenes should start from the conservative recipe and opt into reductions/material approximations deliberately. Camera authoring/export remains the separate supported workflow in the studio guide.

## Limits

The original contains 122 unresolved reachable bitmap references and five unique missing Corona proxy owners across 44 placements, plus an empty Editable Poly. Four matching grass basenames were found locally; that is not full original dependency recovery. Unavailable proxy geometry cannot be reconstructed. The prepared Max retains source metadata; the browser result presents the available building with documented artistic materials. Obsolete mental-ray custom-attribute metadata is also reported.

This is static architectural preparation, not a Corona rendering match, arbitrary animated-scene importer or automatic camera collision solver. Performance qualification is specific to the recorded RTX desktop; portrait browser emulation is not physical mobile or mainstream-device certification.

The original Max hash and normal Max INI hash match enrollment. The preparation module hashes and all published v4 preparation files match their report. Seven tracked website files changed in independent Scatter commits after enrollment; the current website has no tracked diff against HEAD. Those concurrent updates and the pre-existing untracked prototypes were preserved. This goal edited only the presentation app and its documentation; it did not commit, push, install, restart artist Max or publish. See [preservation evidence](../../../presentation-studio/exports/building-20261016/qualification/final-preservation-v1.json).

## Integrity and audit

[Current artifact hashes](../../../presentation-studio/exports/building-20261016/final-presentation-v1/artifact-manifest-v2.json), [qualified source hashes](../../../presentation-studio/exports/building-20261016/qualification/final-source-qualification-v2.json) and [completion audit](../../../presentation-studio/exports/building-20261016/qualification/completion-audit-v2.json) identify the delivered files and evidence. The owned Max test host is closed; the artist Max session was left running. The loopback preview server on port 5194 is intentionally retained for review.
