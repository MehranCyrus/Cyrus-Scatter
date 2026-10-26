# Validation and performance plan

> Original 26 October research/proposal. Implementation was subsequently authorized as 0.87.4. See [current decisions](IMPLEMENTATION_0874.md) and [executed evidence and remaining limits](DELIVERY_0874.md); planned rows below are not all passed.

**All new editor checks below are pending.** This task researched and wrote documents; it did not run the proposed editor or requalify 0.87.3.2. The [current delivery](../scatter-interactions-garden-20261025/DELIVERY_08732.md) remains historical baseline evidence for its exact package.

## Fixtures and provenance

Use owned scene copies and numeric snapshots. Capture source hashes, settings, units, driver/host versions and exact native/script identities for every campaign.

| Fixture | Purpose |
| --- | --- |
| `New Plants test.max`: Decorative05 Neottopteris | Actual difficult fern, elevated crown, drooping broad leaves and many tiny decorative pieces. |
| Same scene: Neottopteris Bush05 variant | Avoid overfitting to a single fern. |
| Same scene: `Outdoor_Plants_01_Grass…` source, resolve exact node/asset at intake | Dense separate blades; preserve the successful automatic workflow and all admitted guides. |
| `Small Test Interaction.max`: Arthropodium flower, resolve exact identity | Stem/flower hierarchy and source-unit handling. |
| Synthetic welded pair and multi-branch component | Honest first-release rejection; no independent motion on a shared vertex. |
| Synthetic coincident/two-sided and stacked leaves | No unintended welding, depth-selection leakage or backface-only selection. |
| `Terraces_Final.max` owned copy | Many instances, unrelated layers, Manual/Live, local collider movement using Cyrus Edit. |

Do not load/reset an artist session to obtain these fixtures. Hash and preserve the originals. No assumption about a source's unit scale or topology can substitute for intake inspection.

## Required functional and geometry checks

| ID | Action / failure | Required result |
| --- | --- | --- |
| V01 | Prepare a source with no editor overrides | Existing automatic behavior, source correspondence and placements remain equivalent under matching settings. |
| V02 | Open editor before preparation or after inference failure | Safe mesh/piece inspection is available; success of the old analysis is not a prerequisite. |
| V03 | Pick, box and brush a front leaf over another leaf | Visible-only selection affects the intended whole piece; through-selection is explicit. Test both sides of thin leaves. |
| V04 | Select by material on a mixed-material component | Full-piece expansion is shown; no unnoticed partial face assignment. |
| V05 | Mark decorative pieces Fixed | Every source face remains; pieces stay at source rest coordinates under contact but move with the plant placement. |
| V06 | Mark flower head Follow stem | Shape is rigid, attachment follows the correct posed parent, parent correction rebinds it and UV/material identities remain unchanged. |
| V07 | Mark a supported drooping leaf Bend and set its root end | Actual base patch is anchored, tip is free, guide direction and descendant bindings are correct. |
| V08 | Move guide points / flip direction, with sphere off | Full rest mesh reproduces the source within recorded tolerance; no pop, rotation or source deformation. |
| V09 | Create a cycle, invalid parent, zero-length guide or distant attachment | Draft remains editable, implicated elements highlighted, Use disabled; no corrupt successor published. |
| V10 | Mark welded multi-branch component Bend | Supported reconstruction or explicit unsupported result; no fabricated single-leaf success. |
| V11 | Delete/reset overrides, including all-Fixed case | Automatic restores only requested intent; no-stems case is explicit and does not invent dummy guides. |
| V12 | Change scatter foliage percentage 1 / 5 / 25 / 100 | Editor selection and saved roles/guides are unchanged. Display sampling never drops solver coverage. |
| V13 | Drag private sphere beside a leaf, between leaves, across flower and away | Production fitter handles all relevant geometry; no failed pieces hidden; away returns rest. Exact faces and root anchors pass, not merely centerlines. |
| V14 | Intersect a fixed base or pinned root | Explicit unresolved conflict, previous complete preview/result retained; no false “all clear”. |
| V15 | First and second real collider contact, narrow passage, Cyrus Edit stone moves | Relevant instances refresh using authored definitions; complete surface checks and reversibility pass. |
| V16 | Test 100% geometry and supported output/Bake/render paths | Vertex/face/UV/material/normal correspondence is preserved; renderer/float-delivery limits are reported separately. |
| V17 | Supported cm/mm/metre scenes, source pivot offsets, instance rotation and positive uniform scale | One physical interpretation and transform application; unsupported nonuniform/sheared/reflected transforms fail explicitly without stale publication. |

Rest error, root displacement, rigid-part strain, guide length error and triangle penetration tolerances must come from the supported physical-unit policy and fitter/audit implementation. Record actual values and rationale in the receipt; do not invent a permissive tolerance merely to pass a fixture. Count all preserved pieces and faces before/after, including Fixed/Follow parts.

## Ownership, lifetime and recovery

| ID | Action / failure | Required result |
| --- | --- | --- |
| L01 | Source/other layer selection changes while editing | Editor remains bound to its captured owner; another layer receives no edits. |
| L02 | Two layers reference one source, but have different overrides | One commit changes only the intended logical owner; compatible immutable data may still share memory. |
| L03 | Rapid role/settings changes while a job runs | At most one running/one pending job; latest revision wins; no stale preview or commit. |
| L04 | Close/Cancel, delete source, remove source slot, delete controller, reset/load/exit | Safe cancellation/retirement; no dangling callback, hidden scene object or leaked GPU/source resources. |
| L05 | Change positions, topology, order, material IDs or units during editing | Exact invalidation; same counts/names do not pass identity checks. Original draft/published snapshot remains preserved. |
| L06 | Change only node placement, material display, camera or unrelated timeline | No unnecessary guide inference when source-local geometry is compatible. Unsupported animated source changes are explicit. |
| L07 | Local Undo/Redo of a brush stroke and guide edit | One gesture restores exact selection/intent; scene history and output remain unchanged. |
| L08 | Use, Max Undo/Redo, then save/reopen | Exact source association, authored intent, compiled definition and compatible output restore. Test with existing unrelated Undo history. |
| L09 | Use with Manual Count/source edits pending | Pending recipe remains pending; source definition/contact update uses only compatible published rows. |
| L10 | Failure during binding, source admission, output allocation, early commit and late commit | No mixed source/output generations; old complete scene and editable draft retained. |
| L11 | Layer copy, supported scene merge, source removal/Undo | New owner IDs remap correctly; intent references do not alias the wrong node or guide. Unqualified pre-existing copy cases stay documented. |
| L12 | Older delivered definition and unknown/newer authored envelope | Deliberate supported read/upgrade or clear rejection; no silent loss of overrides. |
| L13 | Prepare again and automatic Minimum/Branch-connection refresh | Authored overrides persist and dependent definitions rebuild consistently; Reset is the only removal action. |
| L14 | Recipe export on an edited contact layer | Existing unsupported-export guard remains clear; no apparently complete recipe omits the preparation. |
| L15 | Physical + source, Edit preparation, paint/select, root correction, Use, Cancel | Actual generated handlers, timers and focus behavior pass; direct native tests alone are insufficient. |

Test narrow and wide windows, 100/150/200% DPI, monitor changes, minimize/restore and repeated open/close. Verify user text has no new hover tooltips, controls do not overflow, and keyboard gestures cannot accidentally edit the underlying Max scene.

## Performance experiment

Compare automatic and authored preparation on **the same full source and same collider path**. Report full-mesh correctness beside time; fewer guides alone is not a pass.

1. One fern/grass instance to isolate source capture, component discovery, guide inference, binding and GPU upload.
2. 100, 1,000 and 10,000 instances using one prepared source, within declared scene/admission budgets. Include sparse contacts and concentrated contacts separately. Do not create millions of real mesh nodes to simulate procedural instances.
3. Multiple source variants and layers in a terrace/garden copy. Move one stone through Cyrus Edit and measure only affected contact work.
4. Synthetic 250k- and 1M-triangle source snapshots for editor display/picking stress. These are stress datasets, not proof that arbitrary high-poly trees are supported bendable sources.
5. At least 20 open/edit/cancel cycles and a bounded Undo history run to detect retained memory growth. Record CPU/GPU resource release, not just script heap/free RAM.

Measure separately: cold/warm editor open, host capture, component preprocessing, inference, binding, candidate validation, display upload, pick/selection feedback, private sphere fitting, scene commit, cancel latency and peak/retained CPU/GPU allocations. Report p50/p95 and the actual hardware. Warm orbit/selection must show **zero** source-analysis and scene-placement work; source analysis count must not grow with the number of identical instances.

Initial targets for representative accepted assets, **not guarantees or current results**:

| Metric | Initial target / evaluation rule |
| --- | --- |
| Click/selection/overlay feedback | p95 ≤ 50 ms on the fern/grass test machine; measure actual events, not only BVH calls. |
| Warm orbit | Aim for ≤ 33 ms presented frame intervals on those assets. Measure separately from solver time; no universal FPS claim. |
| Updating state | Visible within 100 ms after an edit needing work, except explicitly measured host-capture stalls. |
| Cancellation checks | Aim for ≤ 100 ms between numeric checkpoints; report any non-interruptible host/GPU operation separately. |
| Jobs/caches | One running + one latest pending request; no unbounded snapshot, draft history or GPU growth. |
| No-op interactions | Zero inference, placement rebuild or unchanged buffer upload. |
| Rest/mesh correctness | Same or stronger complete-mesh proof than the current fitter; speed does not justify dropping pieces. |

If a target fails, record whether capture, inference, picking, rendering, contact or publication dominates. Fix the measured cause before introducing a new renderer, GPU solver or finer incremental authoring system.

## Release receipt

Record current branch/HEAD **and dirty source hashes**, input scene/model hashes, unit/frame settings, authored envelope and compiled hashes, native/script/Qt/Max versions, commands, passed/failed rows and remaining limits. Preserve failed attempts and original historical receipts.

An artist delivery requires a matched Max 2027 MZP with verified ZIP integrity, manifest payload hashes and host/capability guards, plus an owned saved trial. New renderer support, other Max years and arbitrary plant-family coverage require their own evidence. Documentation and a viewer spike do not satisfy release acceptance.
