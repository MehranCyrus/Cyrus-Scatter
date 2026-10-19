# Preset and gallery contracts

**Current 0.86.2 delivery:** [qualification, installers and demo](DELIVERY_0862.md). The universal EXE includes Max 2026/2027 runtime-qualified payloads and a clearly labeled Max 2024 preview. D01–D11 are complete within their recorded scope; D04 final artwork is explicitly user-supplied later. Further roadmap work remains paused.

## 0.86.1 delivery contract

Retained 0.86.1 workflow/compatibility evidence: [delivery report](DELIVERY_0861.md).

The user authorizes workflow, UI and host compatibility first. Capture one
explicit selected receiving surface when opening the Library; browsing creates
no Scatter or scene assets. Load assigns the preset to that captured surface,
creates a setup only when required, and adds fresh layers without replacing
existing planting. A compatible existing destination must be unambiguous;
multiple possible owners need a clear choice. Revalidate captured owners before
commit and preserve one authored Undo/Redo including new assets/setup.

The selected surface is authoritative. Missing mesh-channel data, incompatible
Paint or saved spline context must be explained before scene mutation; do not
silently substitute included terrain or disable authored planting rules. Retire
the default binding-heavy/automatic-included-terrain load route. Preserve typed
internal binding and the existing supported Save Recipe/package contracts.
Broader renderer shaders/proxies, animation and authored Edit adapters remain
outside this delivery. Save uses a valid existing setup and captures supported
layers/dependencies; metadata browsing stays available without a setup.

Use explicit readable enabled, disabled, hover, pressed and dropdown colors.
Measure passive gallery/panel counters and actual DPI layouts. Build and test
distinct native/managed pairs for Max 2024, 2026 and 2027, with matching guarded
MZPs and a distributable EXE. Native calculations and licensing remain enabled.
Test empty scene/new setup, repeated Add, prior layers/Undo history, target
deletion or selection change, incompatible masks/Paint/path data, cancellation,
late failure, save/reopen, passive browsing and actual toolbar entry. Package
identity and host guards must be verified; no artist installation is authorized.

Current status and sequencing are owned by the [execution ledger](../improvement-program/PROGRESS.md). The declared PG01–PG08 subset and PG09 explicit scene reuse are delivered; PG09 broader Share/XRef/material adapters and PG10 authored/effect adapters remain pending. Ready preset loading adds new layers with included supported assets and preserves the existing setup. The [0.86.0 native delivery](../native-placement/DELIVERY_0860.md) requalified eight ready presets, Undo/Redo without package files and save/reopen.

| Maintained contract or evidence | Scope |
| --- | --- |
| [0.86.2 delivery](DELIVERY_0862.md) | Current image/mesh density, persistent fields, recipes, demo, installers and exact qualification limits |
| [0.86.1 delivery](DELIVERY_0861.md) | Retained selected-terrain and older-host qualification |
| [Artist workflow](ARTIST_WORKFLOW.md) | Save, browse, style, Add Layers and ready presets |
| [Format 5](FORMAT_5.md) | Recipe identity, revision and typed data |
| [Style contract](STYLE_CONTRACT.md) | Explicit selected groups and retained destination ownership |
| [Package contract](PACKAGE_CONTRACT.md) | Closed static mesh/Standard/PNG graph, dependencies and bounds |
| [Installer contract](INSTALLER_CONTRACT.md) | User/bundled library ownership and distribution |
| [Browser layout](BROWSER_LAYOUT.md) | Gallery navigation and presentation |
| [Validation](VALIDATION.md) | Required Max 2027 correctness, lifecycle, resource and failure gates |
| [0.85.3 ready loading](LOAD_0853.md) | Implemented asset-backed loading and retained Paint/terrain semantics |
| [0.85.2 UI correction](UI_CORRECTION_0852.md) | Historical Modify navigation and library sizing fix |
| [0.85.1 delivery](DELIVERY_0851.md) | Exact initial adapter qualification and limits |
| [Candidate history](PROGRESS_0851.md) | Earlier failures and iterations, not current instructions |
| [Actual Forest comparison](FOREST_RUNTIME_2026-10-16.md) | Bounded Lite 9.4.3 / Max 2027 observations, not proprietary implementation proof |
| [Forest save/load review](FOREST_LIBRARY_REVIEW_2026-10-18.md) | Fresh native reinspection, current 0.86.1 comparison, channel/Paint portability limits and independent research prompt |

The supported subset includes action clarity/no-op numeric apply, bounded thumbnail browsing, explicit capture, revision-aware file maintenance, selective style projection, supported asset collection/import and MZP/EXE distribution. Unsupported authored Edit/radius/effects, arbitrary renderer graphs, automatic Paint transfer to incompatible terrain and broader XRefs do not become supported by being mentioned in a proposal. Contracts define required behavior; exact delivery reports define what passed.

The [archived original plan](../../archive/plans/preset-gallery-plan-0851.md) and [archived checklist](../../archive/plans/preset-gallery-checklist-0851.md) retain PG01–PG08 implementation detail and earlier statuses. Future acceptance below remains required and is not a pass. PG09/PG10 progress is updated only in the execution ledger.

## Remaining adapter requirements

### Planned density, mask preview and recipe follow-up — 18 October 2026

**Delivered as 0.86.2 within the [recorded scope](DELIVERY_0862.md).** The retained requirements below describe the starting problems and intended acceptance, not current defects or independent pass claims. The latest UI follow-up installs the three original grayscale starter patterns, superseding the earlier QA-only catalog decision; final artwork still comes from the user. D01–D11 are local task identifiers, not new P/I/PG/N phases. Status lives in the [execution ledger](../improvement-program/PROGRESS.md); exact passes and limits live in the delivery report. Foundation contracts F02–F11 apply throughout. Unrelated roadmap work remains deferred.

The intended workflow is **choose a pattern/image or compatible Max texture map,
optionally combine a numeric mesh-channel mask, inspect the density, save the
complete supported recipe, select terrain and Load as new layers**. Image
coordinates and numeric mesh data are different inputs; both can be enabled.

**D01 — Fix preview controls and persistent visibility.** Baseline source inspection
found that `meshMaskChanged()` cleared the preview when Invert/range/curve
changes. Separate visible intent from invalid cached samples. Use exact labels
**Show mask** and **Hide mask**, side by side. While visible, coalesce relevant
edits into bounded refreshes; retain the captured owner across panel rebuilds and
unrelated selection. Hide explicitly stops the view. Owner deletion/scene departure
releases resources; invalid inputs show an error/stale state without silently
turning the view off. **Performance/Max 2027:** cache-only redraw, no idle sampling,
Invert/range/curve/Undo/Redo and panel/layer/scene lifecycle; Manual plants and
publication epochs stay at the last Update.

**D02 — Clearly separate the two density inputs.** Present Image / pattern density
and Mesh-channel density with independent enable state. Mesh input retains channel,
R/X–G/Y–B/Z component, input range, invert and response curve. On-demand diagnostics
show support and sampled values; a channel number is not proof of curvature.
Both inputs combine with existing Paint/areas and slope/altitude; disabled inputs
are neutral. Existing slope/altitude logic is unchanged. **Performance/Max 2027:**
opening controls does not capture all meshes; image-only, channel-only, combined,
neutral-white and different-value/same-channel fixtures agree with numeric oracles
and preserve unrelated layer settings.

**D03 — Native pattern projection and sampling.** The existing texture reader
clamps receiver UVs to 0..1; physical repeat controls require real new sampling
behavior. Define a saved world/Scatter-local projection frame, physical X/Y tile
size/aspect lock, rotation, offsets, repeat/clamp and filtering. Explicit advanced
UV mapping uses its own UV channel and dimensionless repeats. Image resolution
controls detail, not physical size. Freeze inverse-transform order, pivot, negative
wrapping, bilinear seams, scalar/linear-data interpretation and invert/curve order.
Bulk sampling/storage is C++; Max texture evaluation/capture stays on the host
thread. **Performance/Max 2027:** independent tests for units, transformed terrain,
negative offsets, seams, 90-degree rotation, UV distortion and extreme sizes;
bounded cached sampling and separate decode/bake costs. Pattern edits must not
silently reseed candidates or switch placement generators. Fixed Total underfill
uses bounded policy and never weakens a mask merely to fill the count.

**D04 — Pattern catalog with a small starter set.** The user's latest 19 October UI follow-up explicitly requests installed patterns. Package the three existing original masks (Uniform, Soft patches and Wide bands) from `AminScatter/patterns`; retain their deterministic test copies under `tools/density_0862/patterns`. This supersedes the earlier empty-installer-catalog decision. Do not expand this into the deferred final artwork collection; the user will supply that later. Preserve prior Forest reference research as historical evidence, not a source of product pixels. **Performance/Max 2027:** reproduce the three fixtures, check ranges/seams and thumbnail limits, exercise empty/populated catalogs and custom images, and verify the three exact product images/catalog in the installer and clean-profile browser.

**D05 — Pattern picker and custom image/map inputs.** Use a compact fixed-aspect
thumbnail with adjustable larger inspection view, family choices, Load image and
Pick map. Reuse catalog infrastructure without confusing pattern selection with
full recipe loading: selecting a pattern changes only density controls, preserving
models, seeds, Paint, layers and spacing. Accept user images and qualified Max
texture maps from the Material Editor, initially Bitmap/Noise; Composite/other
graphs require demonstrated evaluation/persistence support. A whole surface
Material is not itself a scalar mask: pick its supported texture output. Declare
which coordinate controls own mapping so a host map transform is not applied twice.
**Performance/Max 2027:** lazy bounded thumbnail decoding, stale-job cancellation,
no browsing/hover/cancel solves or uploads, one authored Undo per committed choice;
Unicode/missing/corrupt files, map replacement/parameter edits and Manual/Live.

**D06 — Useful surface mask visualization.** The baseline preview was at most 2,048
face-centre dots, so a low-poly plane cannot display a continuous mask. Add a
non-destructive bounded surface overlay using the same field sampler and response
as placement. Preview detail must not depend on mesh tessellation or plant count.
Provide Image, Mesh and Combined density views, opacity and compact
preview sizing. Combined density is eligibility before spacing/collision/count
limits, not a promise of final plants. Keep marker mode optional for diagnosis,
with smaller adjustable markers rather than a fixed distracting screen size.
Never change the artist material or mesh channels to display it. Show a legend
and Manual pending-field/last-Update-plants distinction. **Performance/Max 2027:**
numeric/pixel comparisons including nonlinear responses, low/high-poly mountains,
cache-only redraw, hidden-view zero work, stale errors/resources and no invalidation
loop. Test narrow/wide panels and 100/150/200 percent layouts; qualify physical
4K/mixed-monitor interaction where available, separately from scripted bounds.

**D07 — Complete recipe/package storage.** Extend the existing authored document
with pattern identity/content revision, scalar interpretation, frame/units,
physical size or UV repeats, offsets/rotation/wrap/filtering, invert/curve,
mesh-channel purpose/settings and existing models/materials/Paint/paths/spacing.
Package original/custom image bytes with portable paths. Live scene maps can stay
editable; portable Save needs a supported graph adapter or an explicitly declared
bounded baked snapshot with time/space/resolution provenance. A bake does not
preserve the live producer. Report unsupported graphs before declaring Save
complete. Preserve complete Paint and original user files. Derived overlay/decoded
caches are not recipe content. **Performance/Max 2027:** exact settings/Paint/asset
round trips, moved library/fresh profile, same-name changed bytes, unsupported maps,
cancel/write failure and packaging failure after settings Save. Readiness reflects
both phases; choose schema/version changes deliberately without reviving retired
unpublished compatibility.

**D08 — Unified dependency preflight and recovery.** Validate enabled numeric
channels/map-face indices/components, texture UVs, map assets/evaluation, Paint
geometry/frame/units and paths before adding scene content. Baseline Direct Load
had an early texture-UV gap: later Update could fail after layers were committed.
Retain the actual reason; missing data, invalid topology/nonfinite values,
resource limits and missing asset packages are distinct. Display plain `2`, not
`2L`. Keep the selected terrain/preceding layers authoritative; never silently
remove a mask/Paint or substitute another channel/terrain. Define rollback and
Undo ownership across delayed notifications before implementation. Do not report
partial application as success. **Performance/Max 2027:** valid/missing UV2 positive
controls, numeric0/2/7, incompatible Paint, locked/missing assets, stale/deleted
owners, cancel, failure after staging and first calculation; preserve previous
complete output and Undo history, with one reliable Undo/Redo for successful Add
even when source package files are later unavailable.

**D09 — Repair examples and library readiness.** Audit all eight examples and
Save/Update/Load operations. Ordinary starter recipes use supported portable
image/terrain rules without hidden mesh preparation. Valley moss presently needs
authored channel2 in all three layers: preserve its data and mark it specialized,
or create an explicitly revised portable design and actual-result thumbnail.
Painted examples retain full Paint plus clear compatibility requirements. Keep
selected terrain -> Load -> new layers and existing authored settings. Distinguish
ready recipes, settings-only entries and incomplete/missing packages; a thumbnail
does not establish readiness. Preserve personal Documents/custom libraries through
upgrades/uninstall, separately from bundled assets. **Performance/Max 2027:**
new/existing setup, repeat Add, Save/Update/Delete/details, digest/path linkage
after metadata changes, fresh profiles and different terrains; no scene-wide idle
polling or browser-driven placement work. Arbitrary Paint reprojection, terrain
modifier reconstruction, broader renderer/proxy assets and authored Edit/radius
codecs remain separate adapters, not implied solutions in this follow-up.

**D10 — Integrated qualification and package.** After each implementation step,
run focused native checks and owned Max 2027 witnesses. Finish with a visible
plane/mountain demo using image-only, channel-only and combined density, simple
models, Paint, Bands, existing slope/altitude, Manual/Live, Undo/Redo and reopen.
Compare the same heavy fixtures and stage counters: idle evaluations, solves and
unchanged instance uploads stay at zero; browsing/panels remain responsive; map
baking, mask refresh, thumbnail decode, native memory and publication are measured
separately. Exercise spinner drags, physical navigation/layout and clean-profile
install/upgrade/uninstall. Choose a version under the release policy, then package
the exact qualified pair as Max 2027 MZP and EXE with original patterns and complete
working recipes. Preserve previous host labels; Max 2027 passes do not qualify
older-host runtime behavior. The user installs; this planning request does not
authorize artist installation/restart or Git push. The later active goal authorizes
D01–D11 implementation; unrelated roadmap work remains deferred.

**D11 — Full-width layer name.** Put the Name label and identification color on
one row, with the editable name beneath using the whole available width. Preserve
layer identity and presentation-only rename behavior. Qualify long names, keyboard
selection/editing, copy/rename/Undo and 100/150/200 percent narrow/wide panels;
renaming must not generate placements or upload unchanged instance buffers.

**0.86.2 implementation boundary:** authored mapping settings are owned by the
same layer model as both UI views; bulk image sampling and overlay preparation
use copied/native data. Host texture evaluation and publication remain on the
host thread. Visibility intent is transient and separate from invalid samples.
Map bytes/settings/revisions are cache keys; catalog selection is not a solve.
Existing complete output/history survive failures. Add new authored fields through
explicit typed persistence, retaining original qualified receipts and existing
independent product versions. The package includes only our generated assets.

### PG09 — shared/XRef asset ownership and material variants

**Artist outcome:** deliberately reuse or reference large source assets and select a supported material variant without duplicate imports or unexpected changes to other setups.

**Implementation plan:** extend PG07's explicit Merge/Clone policy with Share/XRef only through qualified adapters. Track content identity, dependency revision, ownership claims and external dependents. Never delete shared assets solely because one Scatter setup was removed. Detect same-path replacement and nested-file changes at explicit relevant refresh/host notifications, without idle full-tree scans. Material variants use supported renderer/class IDs and dependency manifests, not name guessing. Define nested population variation separately from root variation; reject unsupported nested graphs. Shader conversion, proxies and renderer plugins remain explicitly qualified combinations under I17, not universal conversion. Restore imported SDK policy state on every exit path.

**Performance:** V01/V07/V09. Reuse unchanged assets only after supported validity checks; compile/prepare only changed variants. Bound graph depth, cache ownership and memory. Repeated unchanged Keep-style apply must not cause another import or solve. An explicit duplicate Add Layers operation still creates layers; it is not an idempotent command. Offline network/XRef failure must not hang ordinary catalog browsing.

**Max 2027 acceptance:** two setups sharing assets; delete one; external non-Cyrus dependents; XRef unload/reload/missing paths; same-path different bytes; nested changes; duplicate material names; variant switch with unchanged placements; clone/save/reopen/Undo/Redo; unit and cancellation cases. Verify source changes recompute final radii/collision when required. No current static Forest trace substitutes for these tests. **Exit:** explicit shared lifetime/freshness with a published adapter matrix.

### PG10 — authored Edit/radius and effect preset extensions

**Artist outcome:** preserve explicitly supported custom placements/radii and reuse typed effects without silently dropping edits or confusing an editing mode with authored records.

**Implementation plan:** split PG10a (I13 authored records) and PG10b (I14 effects). Introduce neither while its underlying service is absent. Reuse each service's codec, full-width stable keys, coordinate frame, dependency declarations and failure contract. Authored data has explicit Keep/Append/Replace plus source/owner remaps. Effect operations have Insert/Replace Selected/Replace Stack with separate definition/instance/parameter IDs, order, values/defaults/curves and bindings. Content/schema changes must invalidate compiled/bound state even if IDs/counts are unchanged. Compile and validate before commit; never serialize VM cursors, live host pointers or caches. Expression-language presets wait for I18; they do not authorize a new compiler in this step.

**Performance:** V04/V07/V10. Budget authored item/effect counts, bytes and evaluation work. Unchanged definitions reuse compiled programs/bindings; changed parameter values invalidate declared outputs only. Source/scale changes update final bounds before acceptance. Browser summaries do not hydrate custom collections or compile effects. Account for Undo memory and the scoped native admission/history guarantees; broader B26 production limits remain in the backlog.

**Max 2027 acceptance:** maximum-width IDs, source reorder/deletion/remap, compatible/incompatible terrain, units, protected edits, effect ID collisions, current values different from defaults, same-ID changed code/schema, missing bindings, compile failure, pending Manual state, Undo/Redo/save/reopen/copy and repeated no-op style apply. Compare full authored records and resulting placements; injected post-staging failure must retain the previous graph/publication. **Exit:** separately qualified adapters; unsupported record types remain explicit blockers rather than partial saves.


Use the [version policy](../../Release_Versioning.md) when a future delivery is chosen. Save/load uses the existing plugin and data formats; the EXE packages distribution. Broader adapters require separately declared supported combinations and exact-pair Max 2027 evidence before artist documentation claims availability.
