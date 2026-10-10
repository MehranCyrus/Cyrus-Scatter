# Courtyard study — Cyrus Scatter 0.75

This study evaluates the **main artist plugin** through a new landscape scene. AI/MCP product design is outside scope. The scene uses the pavilion's plant library and the supplied courtyard reference, with the buildings omitted. All Max work ran through scripts in an owned disposable Max 2027 process; the artist's session was not controlled.

Work began 9 October and continued into 10 October 2026.

The owned test process is closed; artist Max PID 9000 remained running.

The result is an editable landscape and a bounded functional/performance study. It is **not a claim that every physical control is certified**, that the scene exactly matches the reference, or that the current plugin is ready for commercial release.

## Open the work

Local deliverables, intentionally ignored by Git:

- `Test Scene/Courtyard_Study_075/Courtyard_075.max` — editable scene, Manual mode, Point Cloud preview, hero camera, painting layer selected.
- `Courtyard_Hero.png` and `Courtyard_Overview.png` in that folder — actual Corona renders, not generated concept images.
- `Reference.jpg`, earlier `Draft_01.png` through `Draft_05_*.png`, and `Placements.tsv` — reference, iteration history and final placement export.

Use the matching 0.75 Scatter modules and Analyzer 0.14. Asset paths resolve locally into the existing plant-library/map folders; this is not a portable asset archive. The original pavilion and `Reference_Garden_075/Source_Plants.max` are preserved. No product code, installed module or normal Max profile was changed; no Git push was made for this study.

## Design interpretation and limitations

The reference's useful structure is a network of pale paths around open lawn, dense flowering borders, canopy trees and small play/seating destinations. The new scene retains that organization: three branching gravel ribbons, eight irregular bed guides, two flat courtyard receivers, a curved sensory mound, picnic tables, a canvas tent, timber play tower, sandbox, stepping logs, boulders, fence and low masonry seating. A planted perimeter replaces the omitted buildings.

The site is approximately 32 × 35 metres; dimensions are an interpretation, not a survey. Existing myrtle, rose, elder, abelia, Arthropodium, lavender, geranium, lamium, phlox, viola, clover and grass assets substitute for the reference's species. Canopy trees are assembled from available shrub geometry and new trunks. Furniture/play equipment is modeled for this exercise. No people were added. The reused plant library also carries earlier map relinks and a simplified myrtle leaf shader; resolving every bitmap does not certify original material fidelity. These substitutions and the simplified hardscape limit photorealistic fidelity; the scene is a design/testing study, not an exact finished reproduction.

### Layers actually used

| Layer | Design role / actual feature use | Published placements |
| --- | --- | ---: |
| 01 Structural shrub islands | Three models; weighted clusters, source palette, Include beds, Exclude paths/objects, radii | 184 |
| 02 White flowering matrix | Two Arthropodium variants; palette, boundary density falloff, spacing | 299 |
| 03 PAINT — lavender ribbons | Shared layer models; separate west/east receiver-bound Paint Areas; soft multi-dab strokes | 131 |
| 04 Clustered low flowers | Four models; assignment/color groups; final cleanup and path falloff | 1,188 |
| 05 SPLINE — path edge bands | Six consecutive outside bands on three closed path outlines: 25 cm clover + 45 cm lamium | 760 |
| 06 Open lawn grass and clover | Density at 75 candidates/m²; beds and circulation excluded; clover remains registered with zero weight | 38,337 |
| 07 PAINT — curved sensory mound | Three models; a third native Paint Area on a nonplanar receiver | 185 |
| 08 ANALYZER — precise bed edging | Explicitly linked planar Analyzer boundary with 30 cm edge spacing | 70 |
| 09 Gravel grains | Three path meshes as receivers; synthesized small stone source | 12,000 |
| 10 Texture-sampled accents | Noise eligibility, elder and grass, Include/Exclude | 366 |
| **Total** | **41,520 vegetation placements + 12,000 gravel placements** | **53,520** |

Candidate budgets are not accepted counts. Eligibility, paint, spacing, layer order and cleanup intentionally reduce output. This scene uses the full ten-layer capacity. Structural tree/furniture geometry is additional and is not included in the Scatter total.

Paint history after final reopen: west area **2 strokes / 51 samples**, east **2 / 49**, curved mound **2 / 42**. Multiple gestures stayed inside their named areas; they did not create more populations. Stroke histories remain available for Undo/editing.

## Feature checklist and evidence boundaries

`[x]` means exercised within the stated scope. It does not certify every possible option combination or physical interaction. Isolated fixtures use disposable scenes; some deliberately test retained legacy model-owning sets and must not be mistaken for the modern Paint Area UI.

| Status | Feature | What this campaign actually checked |
| --- | --- | --- |
| [x] | Layers and ownership | Ten scene layers; isolated add/copy/remove/order, names/colors, owner switching and copy isolation |
| [x] | Receiving surfaces | Two flat receivers, separate curved mound, three path receivers; layer-local assignment |
| [x] | Models and settings | Weights/scales/radii/labels in scene; isolated zero weight, source replacement, local alias and color callbacks |
| [x] | Source palettes | Scene palettes; isolated membership, independent settings, parking, hierarchy/lock guards, Undo and persistence |
| [x] | Fixed Count / Density | Both in scene; candidate versus accepted counts recorded |
| [x] | Bounded accepted target | Isolated retry/underfill and bounded failure retention; scene uses candidate budgets |
| [x] | Random mix / Clusters | Scene mixed/clustered layers; isolated seed changes preserve all 10,000 positions while changing assignments |
| [x] | Spline bands | Six scene bands; isolated consecutive band, inside/outside and first-guide overlap behavior |
| [x] | Analyzer assignment | Scene edge border; isolated channels 2–7, warm reuse, amount/spacing distinction and stale-output limitation |
| [x] | Analyzer line/point masks | Isolated point mask 127, line mask 155, union 158 placements; grouping/source Point callbacks in source fixture |
| [x] | Texture sampling | Scene Noise; isolated all-black = 0, all-white = 2,500; nested-map invalidation regression |
| [x] | Named Paint Areas | Three scene areas; separate targets and shared parent-layer models |
| [x] | Native paint/erase | Continuous multi-dab native strokes on flat/curved receivers; erase changed lavender 131 → 122 |
| [x] | Paint overlap/gesture continuity | Extra gesture preserved area count; isolated overlapping-area union, no duplicate population |
| [x] | Fill/Empty/Undo/Redo | Curved Empty = 0; Fill > 0; exact history/output restored by Undo; erase Redo reproduced output |
| [x] | Inactive paint target | East receiver unlinked/restored without losing history; exact placements restored |
| [x] | Include/Exclude | Independent polygon oracle: no final plant pivots in paths; no bed-layer pivots outside Include union |
| [x] | Boundary falloff | Scene controls; independent 100 cm delete margin (2,879 → 1,316), half-scale with unchanged pivots, zero/full density endpoints; physical curve editor untested |
| [x] | Transform/alignment/projection | Scene normal alignment; isolated XYZ/projected movement; paired Min/Max callback/bounds tests; all 185 final mound pivots on actual exported triangles (max error 0.00176 cm) |
| [x] | Spacing/radii | Scene self and between-layer rules; isolated independent scopes, source/radius overrides and XY/3D cases |
| [x] | Relax / cleanup | Isolated relax combinations and 50-million-visit bounded cleanup failure retaining the previous 100 rows |
| [x] | Point / Empty models | Isolated add/replace/grouping/removal and persistence; not left as visible placeholders in final art |
| [x] | Individual instance Edit | Isolated stable identities, selected radii, protected placements and zero-quota reopen |
| [x] | Manual / Live | Manual edit did not publish; explicit Update did; Live seed edit prepared only layer 10 |
| [x] | Passive browsing | Ten layer selections preserved epoch and placements; navigation preserved preparation/publication counters |
| [x] | All six display choices | Points, Box, Sphere, Pyramid, Mesh and centres measured; actual counts/budgets recorded |
| [x] | Retained reuse | Nine navigation scenarios preserved placement/preparation/upload counters; does not close unrelated historical B01 |
| [x] | Enable/visibility/budgets | Isolated fixtures and scene display limits; actual Mesh/Point/Proxy output counts differ |
| [x] | Failure retention | Bounded successor failure preserved prior complete rows; existing acceptance fixtures rerun |
| [x] | Automatic render | Repeated Corona renders; publication fingerprints/epochs checked around final hero/overview |
| [x] | Save/reopen/assets | Exact ten-layer fingerprints and all paint history preserved; 423 bitmap nodes resolve |
| [x] | Exact output / bake | Disposable 100-candidate palette case: 52 surviving instances, correct source and transforms; max matrix-row error 2.53e-7 |
| [x] | Control binding / scripted UI | **234 control bindings** present (214 main + 20 host/editor/container); 94 current Layout/transform callback and native-bounds assertions |
| [x] | Diagnostics lifecycle | Bounded start/snapshot/stop; passive display refresh produced zero events; not a storage-failure test |
| [ ] | Physical artist interactions | Mouse/tablet painting, pickers, docking, DPI, keyboard, graph dragging, long sessions and perceived/presented FPS |
| [ ] | Exhaustive stress combinations | Long soft/erase histories, folded surfaces, extreme radii, all renderers/IR, Max 2026, every combination of controls |

The existing [full control register](../System_Qualification_0.75_2026-10-09/CONTROL_REGISTER.md) remains the physical walkthrough list. A binding assertion proves the control exists, not that its entire interaction is qualified.

## Performance and caching

These are single-machine observations, not cross-machine targets. Timers run inside ordinary Max 2027 in the owned hidden window. Full-scene geometry/materials, background Max work and host overhead are included. No screen automation or presented-frame measurement was used. Raw samples, settings and counter deltas are in [evidence](evidence/summary.json).

| Operation | Elapsed | Preparation change |
| --- | ---: | --- |
| First evaluation after a reload | 5,023 ms | All ten layers |
| Unchanged warm evaluation | 102 ms | None |
| Explicit Update after pending seed edit | 5,395 ms | All ten layers |
| Live seed restoration | 1,037 ms | Layer 10 only |
| Author one native erase dab | 0.12 ms | None; excludes feedback/recalculation |
| Evaluate that erase | 754 ms | Painted layer 03 only |
| Evaluate Brush Undo | 749 ms | Painted layer 03 only |
| Pre-polish save/reopen, explicit preparation | 19,066 ms | All ten layers; cold transient state, selected UI |
| Pre-polish unchanged reads | 100 / 124 ms | None |
| Final circulation/paint polish: explicit Update | 7,787 ms | All ten layers |
| Final save/reopen preparation | 20,179 ms | All ten layers |
| Two final unchanged reads | 120 / 96 ms | None |

The 19–20-second reopen preparation must not be hidden behind the faster warm figure. These mixed-session measurements do not isolate allocator, source sampling, UI or cold-cache contributions. A fresh-process repeated cold/warm campaign is needed before optimizing that variance.

The nine display measurements used the 53,760-placement scene before the final tent-clearance and curved-paint refinement; the delivered scene has 53,520. Geometry validation and save/reopen were rerun on the delivered scene.

Camera/redraw samples: 20 per mode, after three warm redraws, 843 × 741 viewport. Metric is camera mutation + `completeRedraw()` + posted messages, **not FPS**. The 1,000 and 10,000 limits are per layer. Mesh additionally has a 2M-faces/layer budget; Point Cloud has its own point budget. Comparisons therefore report actual drawn elements rather than pretending all modes show the same plants.

| Mode / per-layer instance cap | Drawn elements | Faces | Median ms | P95 ms |
| --- | ---: | ---: | ---: | ---: |
| Point Cloud / own point budget | 124,630 points | 0 | 120.46 | 133.33 |
| Centres | 53,760 markers | 0 | 113.53 | 124.70 |
| Box / 1,000 | 4,847 proxies | 58,164 | 125.11 | 140.78 |
| Pyramid / 1,000 | 4,847 proxies | 29,082 | 123.86 | 133.20 |
| Sphere / 1,000 | 4,847 proxies | 814,296 | 212.07 | 228.55 |
| Mesh / 1,000 | 1,943 instances | 16,926,077 | 117.89 | 122.61 |
| Box / 10,000 | 23,035 proxies | 276,420 | 139.05 | 159.16 |
| Sphere / 10,000 | 23,035 proxies | 3,869,880 | 1,050.09 | 1,206.08 |
| Mesh / 10,000 | 10,948 instances | 17,107,745 | 116.43 | 128.77 |

The higher-cap group uses the final camera and perimeter polish; compare within each group. All nine runs preserved placement/preparation/upload counters. Sphere and Box at 10k **do** have equal instance counts: Sphere's median was about 7.6× Box. Mesh differs in shown count and uses the retained display path.

Why Sphere is expensive: [preview.cpp](../../AminScatter/src/preview.cpp) submits proxy triangles through GraphicsWindow. [geometry_preview.inc](../../AminScatter/src/geometry_preview.inc) generates 168 triangles per sphere. [preview_batches.inc](../../AminScatter/src/preview_batches.inc) limits expanded triangle storage to 16 MiB/cache and 64 MiB/process. Two 10k-sphere layers had no prepared batches, matching the per-cache limit; the fallback repeats transforms/face shading during drawing. This is draw cost even though placement caches are stable. Merely calling the models “instances” does not make this path GPU-instanced.

Final warm-read whole-Max working set was about 5.61 GiB and private allocation about 8.58 GiB, after prior renders/tests. These are not isolated plugin memory or VRAM. Launch/source hashes and detailed memory observations are retained in evidence. Final Corona 15 renders: hero 1400 × 875, 8 passes, **214.86 seconds**; overview 1200 × 900, 6 passes, **91.77 seconds**. Both preserved placement fingerprints and publication epoch. Post-render checks found no transient PFlow nodes, no active production/busy state, and a recovered retained Point Cloud owner. Exact timings, geometry checks and delivered-file hashes are in [completion evidence](evidence/completion.json); [hardware](evidence/hardware.json) records the test machine.

## What the design exercise teaches us

**The current ownership works in this scenario.** Layers can share receivers while retaining their own models/rules. Paint Areas make it possible to paint west, east and a curved receiver without inventing separate populations for every gesture. Erase/Undo and receiver removal/restoration behaved predictably. Warm reads and focused edits reuse unrelated layer preparation.

Final geometry acceptance also checked the moved tent against all three path polygons and all 185 curved placements against the actual receiver triangles. Maximum projection discrepancy was 0.001753 cm; there were no missed triangles.

**The strongest next fix is Proxy display.** Reproduce with equal Box/Sphere counts and preserve Point Cloud/Mesh behavior. Investigate a bounded retained/instanced proxy route, not just a larger expanded-triangle allocation. The existing B03 backlog remains open; this study adds a concrete workload and counters.

**Brush responsiveness still needs work and physical testing.** The 0.12 ms dab command is not the artist's experience: affected-layer publication took about 0.75 seconds in this case. Measure input → visual feedback independently from final population calculation, then consider coalescing publication at gesture boundaries while retaining immediate coverage feedback. Long-history memory remains unqualified.

**Make density and rejection understandable.** Requested population, eligible candidates, accepted plants and displayed elements are different. Building this scene required inspecting rejection counts to tune the planting. Put actionable reasons beside the result, including the active layer/receiver/area and the limiting spacing rule.

**Keep layout meanings explicit.** Clusters change model assignment; they are not the same thing as painting coverage or moving points into clumps. Consecutive spline bands are useful for deliberate edging. First-guide overlap priority matters. Analyzer edge spacing can determine output count independently of the positive requested amount. These distinctions belong in concise contextual help.

**Analyzer freshness needs attention.** The isolated fixture moved its receiver vertically and went from 831 placements to zero using stale analysis. Scatter Update did not perform Analyzer reanalysis; explicit Analyzer Update did. The current UI exposes an Update Analyzer action, but a prominent stale/invalid dependency indication would make this safer to understand.

**Ten layers are a practical design constraint.** This single courtyard fills the current cap. A larger landscape may need multiple controllers, which also affects cross-layer organization and spacing. Review capacity with bounded-work evidence before raising it.

**Visual quality still depends on assets and art direction.** Painting, masks and bands successfully control where plants appear; they cannot supply absent mature tree species, high-quality play equipment or correct material variation. Keep these content issues separate from engine correctness. AI/MCP is not required for the artist to use the underlying features.

## Failures and corrections kept visible

1. **Scene-authoring error:** MAXScript `as array` did not copy an existing array. Joining shared bed/path lists accumulated duplicate records and mismatched Include/Exclude arrays. The early drafts planted the paths and created excessive bands. Corrected with independent arrays and one-to-one count checks, then re-exported positions to an independent polygon oracle. The invalid 24.7-second Update is not a final-scene performance result. Raw earlier receipts remain under the ignored host folder.
2. **Low-level Brush authoring:** native dab rays require object-local coordinates. The scene script was corrected to transform rays to each receiver. This was not evidence that curved painting was broken.
3. **Harness errors:** function binding across `fileIn`, top-level local declarations, and an assumed `areaID` field caused individual script attempts to fail before the intended checks. Corrected harnesses passed; original failure receipts and [correction notes](evidence/harness-corrections.json) remain.
4. **Circulation correction:** visual inspection caught the modeled tent obstructing the main path. Moved the tent and its exclusion guide onto the lawn, repainted the curved mound more fully, then reran geometry and save/reopen checks. The final tent footprint does not intersect any of the three path polygons.
5. **Timing harness:** the initial overview crossed midnight and MAXScript `timestamp()` wrapped, producing a negative raw duration. The final render scripts use a monotonic Stopwatch; the original failed timing remains in the draft receipt.
6. **Product limitations retained:** Sphere drawing, Analyzer freshness, ten-layer capacity, cold preparation variance, and unqualified physical/long-history behavior are not marked fixed. No product source change was made to hide them.

Input validation for malformed parallel area records would also help external scripting, but the list corruption above came from this exercise's script, not a reproduced normal-UI defect.

## Reproduce and extend

- Matching identities: [launch receipt](evidence/launch.json), [loaded paths](evidence/loaded.tsv), [original input hashes](evidence/inputs.json).
- Scene/behavior checks: [scene checks](evidence/scene-checks.json), [save/reopen](evidence/final-scene-checks.json), [assets](evidence/asset-inventory.json).
- Isolated campaigns: [first nine groups](evidence/isolated-results.json), [additional groups and initial harness failure](evidence/isolated-stage2-results.json), [successful Layout assertions](evidence/layout075-checks.txt), [main binding inventory](evidence/control-bindings.tsv) and [20 additional bindings](evidence/other-control-bindings.tsv).
- [Scripts](scripts/) preserve scene construction/refinement and test operations. They contain local paths and several expect the prepared owned host and prior definitions. They are iteration records, not a claimed one-click clean-room builder.

Run only in an owned disposable profile. `tools/procedural_lab/runtime_driver.py` serializes a script through that profile's private developer transport. It wraps top-level locals; do not replace it with unwrapped `fileIn` for scene probes. For future reproduction create a new fixture directory, load the matching modules and saved scene, load the helper definitions, then execute individual probes. Never point reset-scene fixtures at the artist's session. `run_isolated*.py` includes scene resets and restores the saved study afterwards; stop on an unresolved request timeout.

Recommended artist acceptance: open the saved scene, select layer 03, switch west/east Paint Areas, make/erase a stroke, Undo/Redo, then try the curved mound on layer 07. Inspect bands on 05 and Analyzer on 08. Compare Box and Sphere with the same shown count. Check the physical brush, picker, rollout and graph interactions that scripted testing cannot establish. Keep the existing backlog as the single engineering work list.
