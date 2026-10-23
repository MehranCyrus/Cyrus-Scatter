# Cyrus Scatter 0.86.9 Edit instance implementation plan

Implementation follow-up: [0.86.9 delivery, exact evidence and limits](DELIVERY_0869.md).
The dated planning text below preserves the original design and acceptance scope.

23 October 2026. **Planning only.** The requested delivery is Scatter **0.86.9**, with a combined installer for **3ds Max 2024, 2026 and 2027**. The current delivered plugin remains 0.86.8.7 until implementation and qualification finish. This plan addresses Edit marker colours, marker alignment and recovery after removing a source model. Existing artist edits, Undo/Redo and saved scenes are release requirements.

## 1. Scope and baseline

The source baseline is `7d5fd264f8c39e306389977d1eda7c4f358bd3c8` on `codex/workflow-0.75`. [The 0.86.8.7 delivery](../code-quality/DELIVERY_08687.md) is qualified for Max 2027 only. [The older combined delivery](../combined-installer/DELIVERY_08686.md) documents the existing three-host installation workflow; it does not qualify the new native code on the older hosts.

The user's new request explicitly authorizes planning matched 2024/2026/2027 builds and owned compatibility tests for this delivery. Max 2027 remains the development host. Preserve unrelated Arrange/Physics changes, private assets, original Paint, current source-clearance calculations, library content 0.86.7 and the artist's running sessions.

The relevant [engineering contracts](../../ENGINEERING_FOUNDATION.md) are F01–F03 for ownership and identity, F04/F08 for Manual and display-only work, F05–F07 for atomic publication and native resource ownership, and F09–F11 for coordinates and persistence. Apply the [version policy](../../Release_Versioning.md#choosing-the-next-version): the explicitly requested 0.86.9 identifies the complete Edit behaviour and compatibility delivery. Keep independent product versions separate.

The knowledge index was checked against all 48 enrolled parents: 31 were fresh and 17 changed. Its exact-path Edit result covers only the transaction section. The findings below therefore use direct inspection of current source, rather than assuming the index covers the complete Edit implementation.

## 2. Confirmed findings and expected behaviour

| Issue | Current evidence | Required result |
| --- | --- | --- |
| All Edit handles are orange | `CSEdit::Display` hardcodes orange for unselected handles and white for selected handles. It never reads the existing preview palette. | Unselected handles follow the existing Model, Layer or Bands identification colours. Selected handles remain clearly distinguishable. |
| A tree handle appears displaced | `visible()` uses the edited placement's translation, not its bounding-box centre. Mesh geometry includes the source object offset before placement. The actual tree discrepancy has not been measured. Multiple Edit modifiers also have a possible intermediate-versus-final display mismatch. | Display, picking and the transform gizmo agree on the intended placement pivot and evaluated modifier state. Resolve the actual tree witness before claiming this issue fixed. |
| Removing a model raises “CS Edit base changed” | Source membership and source arrays are part of the common generation signature. Removal changes that signature. Saved Edit rows identify candidates but do not store persistent model lineage. | An ordinary supported source removal succeeds. Edits for surviving matching instances remain active; edits belonging to removed or reassigned models remain saved and inactive. They never transfer to another model. |

Preserving edits means preserving their authored deltas, deletions, clone identities and ownership. It does **not** promise an identical accepted scatter after changing its model population: weighted model selection and collision acceptance can legitimately change. Undoing the source change must recover the original compatible result.

## 3. Ownership and implementation boundaries

| Data | Owner and lifetime |
| --- | --- |
| Model, layer and Band identification colours | Existing saved Scatter presentation settings; the Edit modifier receives a derived palette. |
| Candidate and source correspondence | Existing native placement view and immutable `SourceCohort`; keep native source IDs distinct from UI `sourceRowIDs`. |
| Move, rotate, scale, delete and clone edits | Native Edit modifier, persistent layer key, candidate or authored ID, and the new stable source lineage. |
| Marker positions, palette lookups and accepted membership | Transient native presentation state tied to a complete publication; omitted from saved scenes and authored Undo snapshots. |
| Dormant edits | The same persistent Edit owner as active edits; retained until an explicit user reset or deletion of that owner. |
| Instance radius overrides | Their existing layer owner. Any source-transition compatibility work must preserve this separate ownership. |

Keep population-sized lookup, matching, matrices and resource lifetimes in C++. MAXScript supplies bounded owner/palette metadata and coordinates existing commands. Do not construct a MAXScript array of every marker or call back into MAXScript per instance while drawing or picking.

Retain the existing copy-on-write Edit blocks. Charge added lineage tables and display lookup storage to native accounting, including real old/new overlap. Do not keep a second full matrix array per Edit modifier when an immutable published view and compact ID lookup can be shared. Release transient references on controller/modifier deletion, scene reset and successful successor replacement. Host SDK access remains on the host thread.

## 4. Fix one — identification colours

1. Reuse the palette built by `procPreviewMetadata` / `procPreviewPalette` and the native preview palette resolver. Model mode uses `sourceIDColor`, Layer mode uses the logical parent's `layerIDColor`, and Bands mode uses the published Band identity and its colour. Missing Band membership follows the existing preview fallback.
2. Extend Edit presentation publication with the immutable source/palette correspondence for the exact published rows. The incoming placement record's model index addresses that source table. `EditLayer::source()` returns a candidate row index and must **not** be used as the model palette index.
3. Use a coloured hollow box for ordinary handles. Keep a white selection mark with a dark outline or equivalent contrasting shape so white models remain visibly selected; retain a visible colour accent if practical with the existing marker path. This changes feedback, not selection membership.
4. Recolour through the existing display-only refresh. A model/layer colour edit, Color by switch, deselect/reselect or Edit panel opening must not solve placements, consume pending Manual settings or upload unchanged geometry/instance buffers. A small palette/overlay update is permitted and should be counted separately.
5. Resolve colours against published source identities while a Manual source change is pending. Keep the previous source's captured colour as a fallback; do not index a compacted pending source list against old published rows.
6. Textured mesh continues to show materials. Edit handles use identification colours, with Model as the fallback when the material presentation mode supplies no identification choice. Do not add a second competing colour system to the Edit panel.

UI work is limited to feedback and explanatory text. Do not change assignment-group colours: the existing `sourceColors` grouping data can affect generation, whereas `visualSourceColors` is presentation-only.

## 5. Fix two — marker alignment

### Establish the coordinate error before changing transforms

Use a copied tree source and a small synthetic asymmetric source. Capture source node transform, object-offset transform, pivot-local geometry, placement matrix, Edit delta and final published matrix. Compare in world space, with source scale, Z offset and parent transforms included.

The current single-modifier relationship is:

`source vertex world position = vertex × source object offset × edited placement`

`placement pivot world position = [0, 0, 0] × edited placement`

The handle is a pivot marker, not an object bounds box. A canopy-centred bounds offset is therefore not a justified fix. A trunk at nonzero pivot-local coordinates can differ from a correct pivot marker without a placement error.

### Implement one shared position rule

1. Introduce or consolidate a native evaluated-handle record containing owner/layer, logical Edit row identity, published membership, position and colour lookup. Display, hit testing, selection bounds and gizmo placement consume the same mapping.
2. For the ordinary single-Edit case, use the exact edited placement matrix used by the visible output. Account for source/object offsets exactly once. Preserve the existing delta multiplication order and local-origin rotation/scale behaviour.
3. Verify any source-space correction against Mesh and Point Cloud. Fix only the erroneous conversion or stale transform if the measured witness proves one. Do not recenter the model, modify its pivot, rewrite old deltas, change Auto Radius or resample placements as a side effect.
4. Check two stacked Edit modifiers with noncommuting translation and rotation. When feedback represents the end result, resolve each editable row to its corresponding final accepted output. Downstream-only clones are not editable through an earlier modifier. If downstream transforms affect manipulation, convert the requested world gesture into the active modifier's space; a final-position-only cosmetic change is insufficient. Reject a non-invertible conversion without changing edits.
5. Keep active-modifier and end-result presentation consistent with the host state actually used by this plugin. Establish that state in the small stacked-modifier witness before choosing its display mapping. Reuse existing transform handling where it already agrees; avoid a general modifier-stack rewrite.
6. On failed regeneration or a pending Manual source change, handles and picking retain the last complete displayed generation. Hide a deleted/inactive placement's handle only when that successor commits.

**Asset-pivot decision:** if the reported tree has an intentionally displaced source pivot and the transform paths agree, record that finding rather than claiming a C++ alignment bug. Do not move the artist's pivot automatically. A separate display-anchor option would require an explicit design for selection and rotation and is not silently added here. The actual tree witness must be resolved, or this item must remain visibly open in the delivery report.

## 6. Fix three — safe source removal

### Separate incompatible generation changes from source membership

Keep the existing receiver binding validator strict. Introduce an Edit-specific compatibility descriptor with three distinct parts:

- The stable generation basis: layer/population ownership, effective seed, generator/grid settings, global transforms and other inputs whose changed meaning invalidates old edits.
- Receiver identity and geometry bindings, with only the existing supported receiver transitions.
- A stable source inventory with identity, kind and relevant per-source settings, compared by identity rather than current array position.

Allow the defined membership transition when the generation basis and retained source settings remain compatible. Removing a row must not be mistaken for changing every later source's scale or offset because arrays compacted. Changing seed, incompatible receiver geometry or retained source semantics still requires explicit recovery. Merely weakening `receiver::mergeBinding` is prohibited: radius overrides and other consumers rely on it.

### Give edits persistent source lineage

1. Associate each authored edit with its persistent layer key, input candidate/authored identity and native source ID from the exact incoming `SourceCohort`. Preserve clone GUIDs and inherited source lineage. Never use node names, current list positions or transient candidate-row indices as the saved model identity.
2. Treat `savedSource` in the old storage as a candidate input-row index. It is not sufficient to migrate model ownership on its own.
3. Preserve a logical candidate's historical edits for different source lineages without letting them overwrite one another. Only the lineage matching the current assignment can be active. Output IDs must remain unique even when inactive histories share a candidate ID.
4. Preserve deterministic base-row and clone ordering. Lookup-map iteration or the order in which dormant variants were discovered must not reorder output or change collision priority.
5. Keep a deletion attached to its original model lineage. A clone whose source is removed becomes inactive. Neither operation may suppress or create an instance of a newly assigned model.
6. If no authored transforms, clones or deletions exist, a source membership change may rebind the untouched modifier without a Reset requirement. Preserve valid selection by identity where possible.

| Transition | Required behaviour |
| --- | --- |
| Remove model A; a candidate still uses B | B's matching edit remains active. Its edited transform follows the unchanged existing delta contract. |
| A candidate changes from A to B | A's edit remains saved and inactive. B receives an unedited base unless a compatible B-specific history already exists for that candidate. |
| Undo removal | Restore original correspondence, edits, selection, clone IDs and deleted states. The prior compatible result is recovered. |
| Re-add the original registered source | Reactivate only when the persistent source identity and generation basis genuinely match. Re-adding a name is insufficient. |
| Add a different node with the same name | Treat it as a different source. Do not inherit the old source's edits. |
| Remove the last source | Publish an empty layer successfully; retain its inactive authored Edit history for recovery. |
| Reduce then restore Count or temporarily exclude candidates | Retain the existing dormant-candidate behaviour and recover compatible edits. |
| Change seed or incompatible receiver geometry | Preserve authored edits and the last result; report the incompatible input. Do not silently remap or reset. |

### Coordinate commands and publication

The actual Models & Points Remove handler must capture the valid controller, layer and selected source identities before list rebuilding. Put authored membership and any necessary migration metadata in one host Undo hold. Derived reconciliation occurs inside the existing procedural Edit transaction.

In Live mode, calculate and publish the compatible successor. In Manual mode, retain the previous displayed result until explicit Update, along with its matching handles, palette and source snapshot. The source-list command must not force evaluation just to populate lineage.

Prepare the next Edit maps and presentation state before publication. Commit them with the complete result; roll back every affected modifier if a later layer or display stage fails. A failed attempt must not leave a new invalid flag, partial migration or dormant classification attached to the old published result.

### Keep radius overrides safe

Source removal can also encounter the separate `procRadiusBinding` guard. Include one radius-override case so an Edit fix does not merely expose a second “base changed” error.

If a source membership transition reaches that guard, apply the same proven candidate-plus-source compatibility to a bounded, versioned radius-binding descriptor owned by the existing layer. Preserve authored override IDs/modes/values; filter active overrides by lineage and keep nonmatching ones inactive. Capture new lineage when an override is authored, and hydrate legacy lineage only from a compatible original candidate view. Reuse the existing saved binding field if it can carry the validated descriptor; do not put radius ownership inside an Edit modifier or invent positional migration.

This is limited to the source-removal contract. Keep seed/geometry rejection and the current meaning of World radius / Radius factor. If an old override's lineage cannot be proven, retain its bytes and give a specific recovery message. Do not bypass its guard, clear it automatically or apply it to a replacement model.

### Recovery wording

Use normal status such as “4 edits inactive because their source is unavailable” for supported membership changes. For an incompatible seed/geometry or an unresolved legacy binding, name the cause and advise restoring the matching setup; do not present Reset as the only remedy.

The existing Reset command clears every layer in the modifier. Keep its operation and Undo behaviour, but label its scope clearly, for example **Reset all edits**, with a tooltip explaining that scope. Do not add an automatic reset or a new reset-management system.

## 7. Existing scenes and Undo

1. Add an explicitly versioned native Edit storage extension with bounded source tables and record references. Retain a reader for the currently supported `0x7301` records. Preserve class IDs and registration names.
2. Read into temporary state, validate counts, references, duplicate active IDs, finite matrices and feature versions, then install complete state. Corrupt or unknown future data must not partially replace loaded edits.
3. For a legacy scene with a matching original binding, recover source lineage from the exact compatible candidate view. Preserve every matrix, deletion, selected bit and clone ID. Migration must not re-solve a warm Manual scene using its pending recipe.
4. For a legacy scene already saved after an incompatible source/seed change, keep the original payload intact. Require recovery of its matching generation before assigning lineage. Historical array indices or matching names cannot establish ownership.
5. Save inactive histories and their compatibility descriptors. Loading a scene while a source is absent must not prune those records. Saving and reopening must preserve the same future recovery behaviour as keeping the scene open.
6. Use the existing authored restore objects and shared blocks for Undo/Redo; extend their owned metadata and accounting. Derived palettes, candidate views and presentation caches remain outside authored history. A cancelled move restores its original transform and selection.
7. Migration associated with an authored command must be in that command's Undo transaction. Pure compatible hydration during evaluation must be idempotent and transactionally rolled back on failure.
8. Clone/remap persistent namespaces through the existing controller/layer-copy rules. An independent copied or merged setup must not bind to the original setup's source history merely because names or ordinal positions match.
9. Keep MAXScript schema 59 and recipe 8 if the changes fit the native Edit extension and existing versioned binding fields. Freeze the precise native capability/storage revision before implementation; if a new persisted parameter is actually necessary, document its migration and advance that schema deliberately rather than silently reinterpreting old fields.
10. Mark newly saved source-aware Edit data as requiring 0.86.9 or later. Use a feature/binding discriminator that older Edit code rejects instead of accepting incomplete lineage or silently dropping the extension. Opening upgraded scenes in older plugin versions is not a supported downgrade path; preserve the original scene file and save a new copy.

## 8. Implementation sequence and source map

| Step | Work | Completion condition |
| --- | --- | --- |
| 1 | Freeze source identities and small existing-scene witnesses. Measure the tree pivot case; inspect one stacked Edit case. | Confirmed causes are separated from asset pivot behaviour; legacy edit fingerprints are saved. |
| 2 | Implement native marker palette plumbing and shared display/hit/gizmo mapping. | Correct colours and coherent feedback without changing placement IDs, matrices or Manual pending data. |
| 3 | Implement Edit-specific binding, source lineage, inactive histories and source-removal command integration. | Surviving edits stay correct; removed-source edits remain recoverable; last-source removal succeeds. |
| 4 | Finish native persistence, migration, Undo and the coupled radius-binding handling. | Original supported scenes load without edit loss; Undo/Redo and inactive save/reopen recover exact authored state. |
| 5 | Apply the 0.86.9 version across script generation, native metadata, capabilities and packaging. Run the focused checks below on the frozen candidate. | No script/native version mismatch; actual evidence identifies the tested bytes. |
| 6 | Build matched 2024/2026 payloads, run compatibility smoke tests and seal the combined installer. | One shareable EXE and guarded per-host MZPs contain the exact verified builds. |
| 7 | Update current artist/install guidance and qualification notes. | Delivered behaviour, recovery wording, tested hosts and remaining limits are accurate. |

Primary implementation locations:

- [Native Edit and modifier callbacks](../../../AminScatter/src/cyrus_edit.cpp), [Edit data](../../../AminScatter/src/cyrus_edit_data.inc), [stack and transaction](../../../AminScatter/src/cyrus_edit_stack.inc), [save/load](../../../AminScatter/src/cyrus_edit_storage.inc), and [Edit panel resource](../../../AminScatter/src/cyrus_edit.rc).
- [Source correspondence](../../../AminScatter/include/placement_binding.h), [placement storage](../../../AminScatter/include/placement_store.h), [native palette](../../../AminScatter/src/preview_palette.inc), and [mesh source transforms](../../../AminScatter/src/geometry_preview.inc).
- [Authoritative UI template](../../../AminScatter/tools/ui/templates/unified-core.ms): `CyrusEditApplyLayer`, `publishGroupEdits`, `procBinding`, `procRadii`, `procPreviewPalette`, `refreshIdentification` and the source Remove handler. Update its relevant generator and regenerate the checked-in script.
- [Existing binding witness](../../../tools/procedural_lab/Max_Procedural_07_Bindings.ms), [native Edit blocks test](../../../AminScatter/tests/edit_blocks_tests.cpp), and [Edit lifecycle driver](../../../tools/native_placement/edit_controller.ms). Extend relevant cases instead of starting a second large test framework.
- [Matched build/package tool](../../../tools/build_max.py), [existing combined packaging](../../../tools/combined_installer_08685/package.py), and the current installer transaction/provenance checks. Reuse their mechanisms, not their historical version assumptions.

## 9. Minimum validation

Keep the scene small: two independent layers, three simple sources with distinct colours, approximately 20–40 candidates and one copied tree for the actual alignment witness. Use one deliberately offset/asymmetric source to expose coordinate mistakes. Frozen fixtures from 0.86.8.7 and a representative supported older-host delivery provide legacy data; a scene written only by the new code cannot prove migration.

### Focused offline checks

- Run generation consistency and the existing UI semantic/layout checks for changed controls.
- Add a compact native case group for colour/source lookup, compatible membership changes, inactive move/delete/clone histories, deterministic active ordering, and legacy/new storage validation. Check rejection of incompatible generation data and allocation failure before state replacement.
- Run the relevant existing Edit blocks, receiver binding and placement publication tests once on the final Max 2027 build. Run those focused targets for each older-host build as applicable to its compiled components.
- Run only affected Python packaging/version/provenance checks. Do not rerun the entire MCP, website, library, Paint and performance campaigns without a failure or changed dependency that justifies them.

### Four Max 2027 scenario groups

| Group | Actions and assertions |
| --- | --- |
| E1 — feedback and coordinates | Switch Model/Layer/Bands colours, select handles, deselect/reselect the controller, and compare the actual rendered markers. With a pending Manual Count change, colours and selection must leave IDs, matrices, publication epoch and solve/geometry-upload counters unchanged. Compare marker, click hit and gizmo against the synthetic source and copied tree before/after a move; exercise rotated/nonuniform/mirrored source transforms in that small fixture. Include one two-Edit translation/rotation case. |
| E2 — source removal and history | Through the actual generated Remove handler, remove a middle source, then the remaining sources. Include a moved instance, deleted instance and clone in both removed and surviving lineages, plus an untouched Edit modifier case. Check no wrong-model replay, empty last-source output, unaffected independent layer, selection and clone identity preservation, Undo/Redo and a cancelled move. Exercise Live once and Manual-before/after-Update once. Add one radius override to verify its coupled binding stays safe. |
| E3 — saved scenes | Load a real old-format fixture, compare authored state, save an upgraded copy and reopen. Save with a source absent and reopen; restore the original registered source and verify compatible history recovery. A different same-name source must not inherit it. Include one copy/merge ownership check and validate the new-format/old-reader rejection boundary. An already-incompatible legacy fixture must retain its payload and report recovery rather than guess. |
| E4 — guard and recovery | Change seed or receiver geometry and confirm the guard still preserves the last result. Inject one failure after Edit reconciliation but before complete publication, then retry successfully. Assert identical previous rows, source bindings, selection and edited state after failure. Where presentation state commits separately, exercise one failure at that boundary too. Use the existing private fault mechanism; never ship it. |

Use exact identity/state comparisons for same-build Undo and failure recovery. For cross-build or saved floating-point transforms, define the existing scene-scale tolerance before the run and record maximum error; compare IDs, source lineage, clone identities and deletion flags exactly. No screenshot-only numerical verdicts.

These are four small scenario groups, not four isolated assertions. Batch related steps in the same owned fixture and avoid repeated launches or large stress scenes. One visual inspection must check actual colours and handles; native return values alone cannot establish visible alignment or hit behaviour.

### Max 2024 and 2026 compatibility smoke

Use one owned profile campaign per host, with the exact EXE-selected payloads. Cover:

1. Fresh installation, repeat update, startup and loaded Scatter/Edit/Analyzer paths, hashes and versions.
2. The small core Edit workflow: model/layer colour, pivot hit/move, source removal, inactive edits, Undo/Redo and save/reopen. Check one untouched legacy scene in each host.
3. Analyzer creation/update and Scatter use, plus opening the existing library without changing pending Manual data.
4. One carried-forward high-poly viewport case and a low-budget refusal/recovery, because 0.86.8.7's newer memory implementation was previously qualified only on 2027. Reuse the recorded witness instead of repeating a performance study.

The complete 2027 scenario set need not be repeated in the older hosts. Their new qualification covers these specific compatibility checks, not every historical renderer, physical DPI or long-session claim. A failed older-host case blocks that host's inclusion in a successful three-host delivery; do not substitute its previous .6 binary under a .9 label.

## 10. Installer and delivery

- Produce **one `CyrusScatter-0.86.9-Setup.exe`** with distinct matched Scatter modules for Max 2024, 2026 and 2027, including each host's Edit, Brush, storage and applicable managed runtime. Do not reuse a native binary across SDK years.
- Include **Surface Analyzer 0.14.2**, independently versioned, with matched payloads for all three hosts. The 0.14.2 installer correction must be qualified on the older hosts; historical 0.14.1 receipts are insufficient. Retain already qualified bytes only when producer inputs and target host match exactly.
- Generate `CyrusScatter-0.86.9-Max2024.mzp`, `CyrusScatter-0.86.9-Max2026.mzp` and `CyrusScatter-0.86.9-Max2027.mzp`. Provide the single EXE as the main shareable download and retain the MZPs as guarded alternate installers.
- Preserve existing create-only backups, interrupted-install recovery, unknown/custom file refusal, host/version guards, helper SHA/MVID validation and source-bound package receipts. Installation preflights selected hosts/products and reports per-host/product completion; do not claim a global transaction across them.
- Verify archive integrity, embedded package hashes, exact native/script pairs, supported host cards and absence of private fault/diagnostic modules. Confirm a plugin-only update reuses installed library content.
- Keep content 0.86.7 optional and separate. The EXE installs the plugins without requiring a fresh plant-library copy. No website build or publication is part of these three fixes.
- Installation instructions: save work and close the target Max version, run the EXE and select the required hosts, then reopen Max. Alternative MZP: **Scripting > Run Script**, then restart that host. Testing uses owned profiles; the artist's installation and current scene remain untouched unless separately requested.

## 11. Release acceptance

Deliver 0.86.9 only when colours follow the chosen identification mode, the real alignment witness has a measured resolution, and normal source removal preserves compatible active edits plus recoverable inactive history. Undo, legacy load, new save/reopen, Manual pending state and failed-successor recovery must pass the focused checks.

Record exact source/package/loaded identities and results by host. Update the artist guide, version policy, installation guidance, architecture and current documentation links around those proven results. Keep historical receipts intact. Knowledge-index refresh is a separate, deliberate publication step; editing documentation does not make the currently stale index fresh.

No plugin code, version constant, installer or artist scene is changed by this plan. No runtime tests have been run for 0.86.9 at this planning stage.
