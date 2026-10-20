# Cyrus Arrange product sequence

The current qualified release is **0.3.1**, adding native Modify controls, a selectable
viewport icon and prepared real-model tests. Its current status is in
[the acceptance record](REAL_WORLD_0.3.1.md). The prior qualified **0.3.0**
[delivery](RELEASE_VALIDATION_0.3.0.md) includes simplified controls, bulk prop
selection and reusable groups. Older releases remain immutable.

## Preserved 0.1.3 milestone

The qualified 0.1.3 milestone includes validated geometry reuse, imported-board
precision handling, clear Preview/Commit feedback and portable examples. Its
exact archives remain in `dist/CyrusArrange-0.1.3`. The following figures and
sequence describe that historical milestone, rather than the successor's
qualification.

The practical workflow is implemented: furniture inspection and rules, native asset library, seeded whole-footprint placement, conservative collision/approach checks, individual book rows and stacks, density/spacing/empty-space/style controls, locks/selective reroll, Preview/Commit, Manual/Live, Undo and saved native scene ownership. Version 0.1.3 adds bounded same-time geometry reuse, dependency/lifetime validation, numerical support for imported level boards and readable placement targets.

Native46 passes 117 native cases, sixteen functional host suites / 3,034 assertions, five independent JSON exports, two opposite-order performance runs, the original imported workflow with four renders and fresh book-row gallery with six renders. [The release report](RELEASE_VALIDATION_0.1.3.md) distinguishes these scopes and records package qualification. [GOAL.md](GOAL.md) maps the requirement coverage.

Extensions remain explicit: relational dining place settings, broader composition scoring, leaning/physics, detailed concave accessory fitting and qualification of additional renderers/proxy classes. They are future capabilities, not hidden parts of the current workflow. Imported and original examples show practical fit and repeatability, not automatic finished interior design. Two historical startup failures retain unresolved cause in [startup diagnostics](STARTUP_DIAGNOSTICS.md).

The material below preserves the earlier implementation sequence and its stage-specific status; it does not override the current evidence above.

## Historical qualified 0.1.1 baseline

The following native21 results describe the preserved 0.1.1 baseline. Current delivered evidence is in [0.1.2 validation](RELEASE_VALIDATION_0.1.2.md); the working successor is tracked separately in [0.1.3 validation](RELEASE_VALIDATION_0.1.3.md).

| Matched snapshot and receipt | Result and scope |
| --- | --- |
| `build/native-arrange-21/receipt.json` | **68 native suites** across six geometry/asset/arrangement/query/integrated/registry targets |
| `build/host-final-21-inspect/receipt.json`, `json-validation.json` | **69 / 0** plus independent strict JSON validation of five exports |
| `build/host-final-21-native/receipt.json` | **21 / 0** for native scene-owner/API integration |
| `build/host-final-21-workflow/receipt.json` | **147 / 0** for workflow and actual rollout handlers |
| `build/host-final-21-lifecycle/receipt.json` | **89 / 0** for persistence, dependencies, Manual/Live, Undo/Redo and clone ownership |
| `build/host-final-21-preview/receipt.json` | **38 / 0** for transient preview, staleness/Live and Preview/Commit identity/pose cases |
| `build/host-final-21-regions/receipt.json`, `host-final-21-obstacles/receipt.json`, `host-final-21-library/receipt.json` | **74 / 0**, **78 / 0**, **6 / 0** for region policy, independent obstacle lifecycle and unsupported-library failure retention |
| `build/host-final-21-visual/receipt.json` | **83 / 0** with distinct authored normals at every face corner, mirrored/nonuniform transforms, UVs/materials/smoothing, source preservation, Undo/Redo and save/reopen |
| `build/host-final-21-gallery/receipt.json`, `host-final-21-render/receipt.json` | **49 / 0** across five original furniture categories, deterministic poses, independent surface/hole checks and scene staging/save; separate saved scene, Scanline overview and five detail images |

The ten functional counts sum to **654** (69 + 21 + 147 + 89 + 38 + 74 + 78 + 83 + 6 + 49). Native suites, strict JSON checks and rendered images are separate; the render run's repeated 49 generation checks are not counted again. All final host receipts verify both actual loaded module paths/hashes, private profiles and unchanged artist profiles on the same native21 pair. Installation/startup was still pending at that stage; the later exact 0.1.1-r3 archive passed its separate 43 / 12 checks. Qualified 0.1.2 has its own installer evidence; the working 0.1.3 candidate does not inherit either release's qualification.

Historical receipts remain preserved with their own scopes: native18/native19 each pass 68 native suites; native18 inspector05 69 plus five JSON exports, visual07 83 / 0 and workflow07/lifecycle04/preview04 147 / 0, 89 / 0, 38 / 0; native19 workflow08 147 / 0; native12 regions02/obstacles01 74 / 0 and 78 / 0; native11 library-validation01 6 / 0. Native16 gallery03 passes 48 / 0 and render01 saves a scene plus six images, with scoped host time/process measurements. Native18 gallery05 and native19 gallery06 each record 47 generation/fit/determinism passes followed by one camera/title API failure; those runs did not qualify their scene-save/render stage. The repaired final native21 gallery and render receipts now pass that stage. No failed receipt is discarded or treated as a pass.

## 1. Geometry inspector — qualified 0.1.0

Explicitly selected TV consoles/open shelves, multi-object assemblies, millimetre normalization, sampled support regions and overhead clearance, bounds/diagnostics, snapshot overlays and export. C++ numerical tests and procedural Max 2027 furniture establish the first geometry contract. Category is user-assigned intent, not automatic mesh recognition.

Support discovery remains sampled; candidate validation adds precise footprint coverage, clearance and obstacle queries. Production-model qualification still needs bevels, unwelded faces, material-ID segmentation, evaluated modifiers, mirrored assemblies and imported proxy/conversion behavior. A sampled region alone is not a collision certificate.

## 2. Asset metadata and fit

Native versioned asset records: category, real dimensions, support footprint, anchor, upright/front axes, allowed rotations, stackability, and allowed surfaces. Preserve original pivots with authored placement anchors. Track asset/source identity separately from generated instances. Add explicit access/front direction and exclusion regions for shelves, screens, doors, handles and existing props. Validate footprint containment and full 3D overlap against selected furniture and chosen obstacles.

Implemented in qualified 0.1.2: bounded native assets/libraries, artist-authored anchors/top patches, quantized whole-footprint coverage, conservative full-bounds collision, per-body closed-component containment, persistent region policy and independent obstacle/approach scope. The library rejects unsupported authored stack tops atomically. Historical native21 region/obstacle/library tests passed **74 / 0**, **78 / 0**, **6 / 0**, and its strong visual test passed **83 / 0**. Earlier visual04 / 05 preserved **77 passes and six failures**, isolating mirrored normal-ID reassociation; vertex-derived corner remapping first passed visual06/native17 and passed the later qualified release suites. Geometry-only portable libraries require source `.max` assets for complete renderer appearance. Regional rules govern the anchor; physical keep-clear areas require explicit obstacle volumes, as explained in [the quick start](ARRANGE_QUICKSTART.md).

## 3. Arrangement recipes

The implemented TV-console/open-shelf workflow combines compatible books, stacks, vases, plants, frames and accents with reproducible seeds, spacing, clusters, negative-space targets and optional individual book rows. The bounded row-height score can move eligible rows; it does not judge the finished interior. Artists can reroll, lock, replace sources and adjust density before committing. Relational dining layouts and broader visual-hierarchy optimization are deferred recipe extensions.

Qualified 0.1.2 retains five category presets, editable allowed categories/weights/counts, deterministic sampling, physical spacing/negative-space targets, local clusters, uniform scale variation, metadata-defined stacks, locks and selective regeneration. It adds atomic individual book rows and bounded regional row-height scoring, with separate row/UI/lifecycle and render evidence. The original native21 gallery passed **49 / 0** across TV/shelf/curved-coffee/round-dining/L-counter scenes; its separate render produced an overview and five details. The qualified 0.1.2 book-row gallery adds **35 / 0** and six images. These establish functional fit and reproducibility, not artist composition acceptance or the deferred dining/visual-hierarchy recipes.

## 4. Native scene lifecycle

Define controller-owned authored parameters, geometry dependencies, persistent instance identities, save/load schema, Undo/Redo, manual versus live update and stale-snapshot rejection. Publish a complete successor atomically; failure retains the previous arrangement. Cache support geometry separately from changing recipes. Host access and publication stay on Max's main thread; parallel work uses immutable copied data. Bound candidates, memory and work before expansion.

Qualified 0.1.2 provides native immutable scene state, real dependency references, atomic publication/Undo, Manual/Live, Preview/Commit, conservative persistent support identities, independent obstacles and protection against stale/invalid protected rows. Its Generate recaptures/reanalyzes furniture and rebuilds the precise query; immutable sharing alone is not geometry reuse. Working 0.1.3 now implements optional same-time geometry/query reuse and passive retained-byte accounting, with host invalidation/lifetime and paired-performance qualification still pending; see [the implementation plan](CACHE_IMPLEMENTATION_PLAN.md) and [current evidence](RELEASE_VALIDATION_0.1.3.md). Retained requested bytes are distinct from Max/process and Undo/history memory. Zero-offset clone ownership is qualified in 0.1.2; translated whole clones require unlocking and explicit Generate, with no automatic frame correction or preserved-offset-pose promise.

## 5. Artist qualification and optional learning

Curate actual product scenes and licensed asset sets. Measure cold inspection, cached rerolls, commit time and retained/history memory independently. Qualify instance/material/render behavior with the intended renderers. Only consider learned classification/ranking after a strong rule-based baseline, an explicit data format, consent and useful training examples exist. No online service or training-data upload is required by the current design.

Qualified 0.1.2 acceptance includes thirteen exact-source functional suites, original five-category generation, actual book rows and bounded balance, deterministic repeats, independent curved/L/sink oracles, saved scenes, scoped Scanline renders, strong corner-normal fidelity, controlled whole-command performance evidence and actual private installation/startup. Historical native16/native21 gallery timing samples retain their small-scene scope; working-set/peak values are process-wide. Artist composition review and intended-renderer/imported-model trials remain open. Working 0.1.3 must pass its own complete functional, paired-performance and installer gates; no cache-speedup claim follows from a native test pass or old timing sample.

Authored rules/footprints, conservative persistent surface identity, explicit obstacle/front controls and Preview/Commit are qualified 0.1.2 capabilities within the recorded scope. Arbitrary automatic surface rebinding, compartment recognition, true dynamic stability, detailed prop-mesh collision and rich portable renderer assets remain explicit limits. Working 0.1.3 reuse qualification and practical artist/imported-model acceptance remain open. The deferred recipe extensions are not implied complete by native test counts. Preserved inspector and released archives remain unchanged.

## Scope of remaining composition and cache work

The initiating request establishes furniture categories, allowed accessories, geometry/empty-space analysis and automatic valid random placement, with a C++ core and MAXScript UI. Qualified 0.1.2 implements the documented manual-authoring workflow plus individual book rows and bounded row-height balance. Same-time query reuse is the selected 0.1.3 performance/reliability milestone and remains under qualification. **Relational dining place settings and broader visual-hierarchy optimization are named deferred recipe extensions; neither is implemented or required for the bounded 0.1.3 release.** Broader imported-model/renderer evidence and artist composition review remain practical acceptance work. This scope statement does not mark the original full-system goal complete. Optional learned classification/ranking remains separate.

## Historical 0.1.1 installer successor evidence

The first actual MZP run (`build/installer-qualification-01/receipt.json`) failed before configuration publication because a .NET directory result had converted to a MAXScript array and did not support `.Length`. The failed archive at `dist/CyrusArrange-0.1.1` remains unqualified. The revised installer used `.count`, explicit failure-stage assertions and missing-parent cleanup tests while preserving the native21 functional runtime. The later exact r3 archive passed 43 installer and 12 startup checks; [qualification scopes](QUALIFICATION_SCOPES.md) and its external receipt preserve the failed and passed deployment evidence. This history is separate from qualified 0.1.2 and the still-pending 0.1.3 candidate.
