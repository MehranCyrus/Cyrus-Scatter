# Implementation sequence

Implementation is authorized and in progress; see [PROGRESS.md](PROGRESS.md) for actual acceptance. Read [DESIGN.md](DESIGN.md) for the behavioral contract and [VALIDATION.md](VALIDATION.md) for test definitions. Keep each milestone reviewable; passing one stage does not qualify the later display and radius stages.

## Requirement coverage

| ID | User requirement / necessary correction | Milestone | Acceptance families |
|---|---|---|---|
| R01 | Rounded and Sharp corners, with Rounded preserved | P3 | G, D, F, P |
| R02 | Paths list instead of dropdown | P2 | U, S, M |
| R03 | Adjacent Add closed line / Remove path icons | P2 | U |
| R04 | Add Outside / Add Inside / Remove on one icon row; retain Band list | P2 | U, R |
| R05 | Per-Band identification color and readable viewport Band regions | P2/P4 | V, M, F, P |
| R06 | Existing source swatch plus `Name | Weight | Band`; no color names in text | P2 | U, T, S |
| R07 | Clear per-Band model/group assignment and scale ownership | P1/P2 | R, U, D, S |
| R08 | Density strength, editable falloff curve and Preview Falloff checkbox | P3/P4 | D, G, U, V, M |
| R09 | Independent overlapping ranges, including Sphere 0–10 cm and Box 0–40 cm | P3 | R, D, G, T |
| R10 | Auto Radius with Manual control, correct spacing and visualization | P5 | A, M, S, F, P |
| R11 | Preserve empty consecutive intervals; distinguish empty assignment from fallback | P1 | R, T, S |
| R12 | Explain Radius/Z Offset correctly; correct world-Z tooltip | P1/P5 | A, U, S |

Every row also requires unchanged-feature regressions and the supported host qualification in P6. The apparent width-coupling screenshots were resolved by explicit assignments; they are not a confirmed second width bug. Shared spacing may alter accepted counts when a neighboring Band changes without altering its geometric range.

## P0 — Establish oracles and bounded prototypes

Recheck current branch, dirty files, generated source identity and current workflow. The research baseline is not permission to overwrite later work. Work only in disposable fixtures once implementation is authorized.

Deliver these short receipts before production integration:

1. **Transport inventory:** enumerate every raw/post-Edit row producer, validator, copier and reader. Choose the versioned internal contract, specifying candidate/anchor identity, Band owner and protection explicitly; identify the renderer/export boundary. Prefer a single contract with stage-specific named helpers. Use a sidecar only if a documented inventory proves it is smaller and complete. Include clone identity, source remapping and receiver concatenation.
2. **Geometry proof:** implement a narrow offline Sharp-field experiment using the already vendored Clipper2. Compare against analytic rectangles and dense independently chosen offset membership checks. Record tolerances, topology behavior, error bounds and aggregate limits. Include inward collapse and steep/narrow curves. No feature proceeds with a fixed number of levels that cannot meet its stated accuracy.
3. **Sampling oracle:** independently calculate occupancy and conditional mixture probabilities for flat, rising, falling and overlapping fields. Pin deterministic candidate keys and separate random channels. Confirm the Accepted-target rejection rule before UI wiring.
4. **Radius and units inventory:** identify transform order and supported source classes; choose a non-mutating proxy bounds route or mark that proxy unsupported for Auto. Inspect saved unit types and exactly-once conversions for touched distances. Identify where published geometry revisions can be retained without unbounded memory.
5. **Cost baseline:** record the workloads in VALIDATION, existing native cache/resource limits and baseline timings. Set and record finite limits for total prepared vertices, offset levels, query work, overlay samples and simultaneous old/staged resources. Choose time regression thresholds before measuring the new implementation.

Completion: independent oracles and bounded limits are reproducible; the selected transport is explicit; no unresolved choice is hidden in a production feature. If Sharp cannot meet accuracy within measured limits, revise this specific design before integrating it. Do not silently substitute rounded geometry.

## P1 — Correct range transport and introduce stable ownership

Dependencies: P0 transport and units decisions.

- Add stable Path/Band IDs and a layer namespace to authored records; implement copy, remove, reorder, Undo and persistence together. Namespace is address identity only; preserve the copied random recipe (`randomSeed`, `procSamplingSalt`, receiver keys and local Band/source IDs) for identical initial pre-spacing distribution.
- Resolve all consecutive intervals before source resolution. Send explicit lower/upper bounds and explicit selection state, including an empty interval. Native fallback must not reinterpret explicit empty assignments as all sources in a group.
- Propagate selected Band ownership through native Instances, stage transport, receiver operations, transformations, Brush/falloff filtering, Edit/protected/cloned output, spacing, publication and preview samples. Keep candidate identity distinct from Band identity.
- Include provenance with complete publication metadata. Retain Analyzer behavior; audit its shared row consumers without adding an ordinary-spline orientation feature.
- Correct the Z Offset explanation to world Z. Preserve calculation behavior.
- Introduce the selected schema/payload version once; update generators and native/script consumers as one matched development package. Per the subsequent user instruction, remove retired schema migrations and transport adapters. Qualify schema-57 creation, units, copy, Undo and reopen; earlier scenes are explicitly unsupported.

Primary files under `AminScatter/`: `include/scatter.h`, `include/procedural.h`, `src/scatter.cpp`, `src/placement_identity.inc`, `src/receiver_bridge.inc`, `src/boundary_falloff_bridge.inc`, `src/whole_scale_bridge.inc`, `src/brush_host.cpp`, `src/orientation_bridge.inc`, `src/cyrus_edit_stack.inc`, `src/group_spacing_bridge.inc`, `src/procedural_bridge.inc`, `tools/ui/templates/unified-core.ms`. All subsequent source paths also use this project root. Verify actual symbol locations against the P0 inventory; generated consumers may add files to this list.

Completion: R and T tests pass, particularly an unassigned middle Band followed by another Band on the same side/path, exact protection preservation, source reorder/removal and save/reopen. Flat Rounded assigned Consecutive fixtures preserve their baseline output except explicitly recorded corrections. No display work depends on position-based reconstruction of ownership.

## P2 — Make the existing workflow understandable

Dependency: P1 identity and membership model.

- Replace Paths dropdown with a compact list, initially three visible rows, scrollbar and stable selection. Expose missing/inactive state and Band count.
- Reuse existing icon conventions for adjacent path actions and the single Band action row. Provide tooltips, accessible names and disabled states. Retain Bands list and clear resolved intervals.
- Extend existing owner-drawn source and Band lists; add Band swatches and membership labels without RGB text. Multiple memberships use a compact count and qualified tooltip/chooser.
- Show “Models used by this Band,” explicit empty assignment and direct/groups choice. Preserve reusable group editing in Models/Points. Put per-Band scale range in Advanced with its multiplier explanation.
- Add the saved display-color fields and dependency separation needed by P4. Editing color does not mark placements dirty.
- Establish the curve editor's captured owner lifecycle before connecting it to P3. Reuse the editor; do not introduce a second curve framework.

Primary files: `tools/ui/templates/unified-core.ms`, `tools/ui/approved-layout-rows.cjs`, `tools/ui/approved-layout.cjs`, `tools/ui/colored-lists.cjs`, relevant layout manifest and generated UI. Always regenerate, never patch only `scripts/AminScatterObject.ms`.

Completion: U tests in each supported UI container, same-name Paths, multiple selections, Undo, owner switching, narrow panel and DPI scenarios. Navigation alone performs no placement solve. No control claims an unavailable later milestone is already implemented.

## P3 — Add prepared fields, Independent ranges and density

Dependencies: P0 geometry/sampling gates; P1 transport; P2 owner-safe graph adapter.

- Prepare one shared world-XY path per relevant revision. Preserve Rounded behavior; add bounded Sharp preparation, topology normalization, level sharing and query indices using P0 limits.
- Add layer arrangement mode and per-Band Independent Start/End, density strength and sampled curve. Implement explicit conversion and Undo behavior; ranges are physical distances, graph X is normalized progress.
- Implement the single pure field evaluator from DESIGN. Consecutive keeps first-match geometric ownership across Paths. Independent streams eligible contributions, gates occupancy, selects an owner, then selects its source and scale with separate keyed variates.
- Treat all-zero-weight/unassigned groups as zero contribution; retain intentional Empty outcomes. Validate curve data, strengths and intervals before candidate work.
- Reject Accepted target with Independent/nontrivial Band density before publication. Preserve Count/plants-per-square-metre behavior and do not change the policy silently.
- Apply Band density once. Keep other masks at existing stages and expose useful rejection counts without adding per-candidate logs or dense candidate×Band storage.
- Use the evaluator during automatic movement to preserve occupancy and owner decisions. For this delivery, validate the destination and retain existing intermediate checks; do not claim continuous no-gap-crossing or remove those checks. A stronger continuous guarantee requires a separate bounded segment-crossing implementation and tests before it is advertised. Protected user edits retain their explicit exception.

Primary files: `include/scatter.h`, `src/scatter.cpp`, a narrowly scoped prepared-field module if needed, `src/final.inc`, `src/spacing.inc`, `src/procedural.cpp`, `src/receiver_plan.cpp`, `src/max_bridge.cpp`, the relevant bridge and UI model/generator files. Reuse existing Clipper2 linkage; no package upgrade is required.

Completion: G and D oracles, deterministic receiver/candidate tests, topology/collapse, empty assignments, budget failures and movement fixtures pass. Original Sphere/Box overlap example produces both sources in the inner interval and sparse Box continuation. Accuracy status is measurable, not inferred from preview agreement.

## P4 — Make Band colors and falloff previews faithful and inexpensive

Dependencies: P1 published provenance and P3 prepared evaluator. Band palettes can be developed earlier, but qualification needs both.

- Add Color by Bands using retained owner keys in Point, Point Cloud, Mesh and supported fallback displays. Preserve render materials and shared source geometry.
- Separate immutable geometry/instance data from owner/palette resources where required. Retain old-generation material state. Color-only edits must not re-upload geometric streams or unchanged sibling data.
- Add Preview Falloff and Show Boundaries within a bounded per-population display bundle. Selected contribution and combined occupancy are explicit modes; both describe the Band stage before independent masks/spacing.
- Keep overlays out of placement counts and render output. Draw from prepared snapshots only; account for all arrays, native buffers, fallbacks and simultaneous generations.
- Implement authored/published epoch labels and the source-geometry revision policy from DESIGN. A display switch cannot silently combine pending source geometry with published radii.
- Qualify new resource publication and failure recovery at CPU and GPU allocation/realization boundaries. Fix any prerequisite lifetime defect narrowly before releasing the mode.

Primary files: `include/point_preview.h`, `src/preview.cpp`, `src/point_display.cpp`, `src/mesh_display.inc`, `src/geometry_preview.inc`, point/mesh bridges and `tools/ui/templates/unified-core.ms` (`procStagePreview`, `procEnsureDisplay`, publication). Include diagnostic counters needed to prove reuse, not permanent verbose logging.

Completion: V, M, F and P gates. Same source in two Bands receives different identification colors; pending field is clearly labeled; renderer/material output is unchanged. Evidence covers physical host display and uploaded bytes, not just script cache identity.

## P5 — Add Auto Radius through the existing spacing system

Dependencies: P0 bounds/units decisions and P1 transport. Can be implemented independently of Sharp geometry after these foundations; qualify Manual display behavior with P4.

- Add per-source Manual/Auto ownership, preserve Manual settings and stable instance overrides. Disable Follow Scale only in Auto with a clear explanation.
- Extract finite pivot-local bounds from face-referenced supported geometry once per relevant revision. Cache eight corners. Establish source validity and finite extraction/work limits.
- Compute XY and 3D radii from final placement bases, once per placement, after all applicable scale/orientation/Edit stages. Validate no second scaling and no translation contamination.
- Extend `Sample`/published radius transport to a pair. Choose self and each external rule's own/blocker metric independently. Keep the existing spacing algorithm and independent scopes.
- Show Radius reads the published pair, with an XY/3D display selector. Points, Empty tokens and unqualified proxies retain explicit Manual behavior.
- Document conservative pivot-centered bounds. Do not market this as mesh-to-mesh collision or automatic qualification of every render proxy.

Primary files: `include/procedural.h`, `src/procedural_bridge.inc`, `src/procedural.cpp`, `src/max_bridge.cpp` or a narrow bounds include, `tools/ui/templates/unified-core.ms` and radius display construction. `group_spacing.cpp` should need no new algorithm; its existing per-rule arrays carry the selected metric.

Completion: A tests, mixed XY/3D scope cases, units, Manual pending geometry, relevant animation and published ring/sphere correspondence. Unsupported source classes are visible and never silently get zero radius.

## P6 — Integrated qualification and documentation

Dependencies: all preceding milestones complete.

- Run focused native/bridge/generator tests, then the repository's required checks for changed areas. Repeat only after changes or unresolved failures justify it.
- Use matched scripts/native modules and disposable scenes/profiles for each supported Max version. Verify loaded module paths/hashes, not a version caption alone.
- Execute the validation matrix and record deviations. Restore original fixture state when comparing baselines. Compare actual placement/source/owner/transform data, not counts alone.
- Update current artist documentation and imported website reference only for proven behavior, plus feature catalog/host automation contracts if their exposed controls changed. Preserve historical receipts.
- Record capability limits, performance distributions, failure witnesses and remaining exclusions. Do not call an offline pass a UI/render/FPS qualification.

Workflow commands, to run only during authorized implementation with a fresh unused run directory:

```powershell
python tools/procedural_lab/check_generated.py --output build/<fresh-run>/generated
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q
python tools/procedural_lab/offline_build.py --project scatter --output build/<fresh-run>/scatter
```

Follow `docs/AGENT_WORKFLOW.md` for focused native tests, host launch and matching package verification. `<fresh-run>` is a placeholder, not an existing output directory to overwrite. Build/install/package/publish actions still require the implementation session's scope; this document does not grant them.

Completion: every required acceptance family has a receipt or an explicit blocking failure. No release/package/commit is implied by plan completion. Follow the outstanding milestones in PROGRESS rather than restarting completed experiments.
