# Cyrus Scatter discussion backlog

Updated 8 October 2026. The artist authorized a 0.74 implementation pass and Git backup. See [the implementation checklist and acceptance limits](../UI_Refinements_0.74_2026-10-08/README.md). Descriptions below preserve the original 0.73 discussion baseline; the implementation report supersedes those baseline descriptions where marked complete. The layer/set ownership decision remains open; see [the research-backed recommendation](MODELS_AND_PAINTING.md).

| Item | Subject | Status |
| --- | --- | --- |
| Issue 1 | Receiving-surface selection and management | Implemented; additive/dedup/multi-remove/Undo/Redo host checks pass |
| Issue 2 | Expanded sections reset after deselecting and reselecting Scatter | Implemented; mixed/all-open/all-closed session restoration host checks pass |
| Issue 3 | Drag handles for resizing list height | [Shared cursor error fixed; flat grip design](../UI_Refinements_0.74_2026-10-08/GRIP_FIX.md); all 27 mounted handles pass event tests; physical pointer/DPI review remains |
| Issue 4 | Independently collapsible settings groups inside main sections | Implemented for layer/source Properties; folding and reflow host checks pass |
| Issue 5 | Simple naming and placement of paint-set controls | Painting-only presentation proposed; artist is examining current behavior before deciding |
| Issue 6 | Compact action icons and editable names and identification colors | Implemented; label-only rename, independent colors, copy/save and Manual isolation checks pass; visual/DPI acceptance remains |
| Reference 1 | Separate downloadable library packages | Observation recorded; no addition agreed |
| Reference 2 | Forest settings and presentation | Comparison recorded; no feature-parity goal agreed |

## Issue 1 Receiving surfaces

### Current behavior

The artist reports that multiple surfaces can only be chosen through **Receiving surfaces…**. **Pick receiving surface** replaces the assignment with one picked surface. The panel displays one name or a count rather than a persistent list of all assigned receivers.

Source inspection confirms this behavior in [the authoritative template](../../AminScatter/tools/ui/templates/unified-core.ms): the viewport picker calls `setSurfaces #(node)`, while the by-name dialog allows multiple selection and replaces the assigned list with its result. The supplied [two-surface screenshot](references/cyrus-two-surfaces.png) shows the panel reporting two assigned surfaces.

### Desired behavior confirmed by the artist

- Show all assigned receiving surfaces in a visible list, with correct scene-object names.
- Use a compact **+** icon to pick and add receivers while preserving previously assigned surfaces.
- Use a compact **×** icon to remove selected list entries from this Scatter setup, leaving the scene objects intact.
- Use a **list-selection icon** to choose and add multiple receivers by name while preserving existing assignments.
- Allow as many receiving surfaces as the artist needs. Do not introduce an arbitrary UI limit; actual performance and resource bounds still need evaluation.
- Replace the current two-button arrangement with this list and compact controls, following the supplied [Forest surface-list reference](references/forest-surface-list.png).

### Details still to discuss

- Whether viewport picking remains active for repeated additions until the artist exits it.
- Whether multiple list rows can be selected and removed together.
- How list selection helps locate the corresponding scene object, if that interaction is wanted.
- How duplicate picks, renamed objects and deleted scene objects should appear or be handled.

The current single-receiver requirement for Brush painting remains a separate capability limitation. The artist has not yet decided whether or how to change it; adding a receiver list alone would not provide multi-surface painting.

### Proposed future acceptance

After implementation is explicitly requested: add receivers by picking and by name without losing existing assignments; inspect every assigned receiver; remove assignments without deleting scene geometry; retain names and identities correctly through save/reopen and relevant Undo/Redo. Confirm that browsing the list does not rebuild placements. These are proposed checks, not completed results.

## Issue 2 Remember expanded UI sections

### Reported behavior

The artist opens all or some settings sections, deselects Cyrus Scatter and selects it again. The panel returns with sections collapsed instead of restoring the previous open/closed combination. This interrupts work by requiring the same sections to be opened repeatedly.

Here, "layers" in the artist's description refers to the UI rollout sections, such as Models & source containers, Population, Coverage & painting and Transforms. This issue concerns the view state; it does not describe missing Scatter layers or paint sets.

The supplied screenshots show [the expanded layout](references/cyrus-sections-expanded.png) and [the collapsed layout](references/cyrus-sections-collapsed.png). The artist describes deselection/reselection as the trigger; the screenshots illustrate the two states.

### Source finding

The current [main UI template](../../AminScatter/tools/ui/templates/approved-main-ui.ms) explicitly resets every editor to `r.open=false` in `mountTimer tick`. It then opens Receiving surfaces only when no receiver is assigned, and always opens Layers & paint sets. The same reset is present in the generated script. This explains why remounting the panel discards a previously chosen section arrangement.

The close handler clears UI references and the editor array; this mount path does not restore a captured open/closed arrangement. Existing [approved-layout tests](../../tools/procedural_lab/Max_Approved_Layout_073.ms) check expansion and folding while mounted, but do not establish restoration of the artist's arrangement after deselection/reselection. No new Max runtime test was performed for this discussion entry.

### Desired behavior

- On returning to the same Cyrus Scatter object, restore exactly which settings sections were expanded and which were collapsed.
- Support any combination: all open, only some open, or sections deliberately left closed.
- Keep this view restoration independent of calculation, saved recipe values and Manual/Live updates.

### Related details to discuss

- Preserve each section's Advanced disclosure state as well; the expanded screenshot contains several open Advanced sections. This is a proposed part of remembering the view, awaiting explicit confirmation.
- Decide whether remembered state belongs to each Scatter object, each selected layer, or a shared user preference. Independently remembering each Scatter object is a proposed starting point.
- Decide separately whether state should persist across save/reopen or restarting Max. The confirmed request is restoration after deselection/reselection during work.
- Consider scroll position and column placement separately if the artist wants the entire panel arrangement restored.

### Proposed future acceptance

Open a mixed combination of sections, select another scene object and reselect the same Scatter object: the combination must return unchanged. Repeat with all sections expanded and with sections deliberately collapsed. Verify switching between two Scatter objects follows the chosen ownership policy and that view restoration does not publish pending Manual edits, rebuild placements or use stale UI references. First-use defaults should still apply to an object with no remembered state. These checks await an authorized implementation and host qualification.

## Issue 3 Resize lists with a drag handle

The artist wants a small horizontal drag handle beneath a list, like the supplied Forest Geometry reference. Dragging it downward makes the list taller and shows more entries; dragging it upward makes the list shorter and saves panel space. The screenshots show [a compact list](references/forest-list-compact-properties-open.png) and [a taller list](references/forest-list-tall.png).

This refers to resizing a UI list box, not resizing a source rectangle or scene object. List height should be adjustable without changing assignments, selected items or scatter settings. The controls and settings below the list should move with its resized boundary.

The receiving-surface list proposed in Issue 1 is a natural application. Which other lists receive the handle, their useful minimum heights and whether heights are remembered when returning to the object remain details to discuss. Remembering list height can be considered alongside Issue 2.

Proposed future acceptance: drag a list taller and shorter, confirm more or fewer rows are visible, and check the controls below remain readable and usable without overlap. Resizing must not change scene geometry, list membership, item selection or calculated placements. These are future checks, not implemented behavior.

## Issue 4 Fold settings groups independently

The artist wants a second level of expand/collapse inside a main rollout. In the supplied Forest reference, Geometry can remain open with its list and action icons visible while the nested **Properties** group is expanded or collapsed using the icon beside its title. This is a disclosure toggle, not a dropdown selection menu.

The references show [expanded Properties](references/forest-properties-expanded.png) and [collapsed Properties inside Geometry](references/forest-properties-collapsed.png). Collapsing the group hides its contained settings while leaving other controls in the main section visible, as illustrated by Global Scale and Consolidate Materials in the collapsed reference.

Desired interaction:

- Retain the main section's own open/close control.
- Give relevant settings groups a labelled header and a small direction indicator that opens or closes that group independently.
- Keep the list and its action icons available when the related properties are hidden.
- Preserve values and enabled states when hiding settings; collapsing a group is a view action.
- Reflow the controls below the group to use the freed space, without overlap or a large empty reservation.

The exact Cyrus groups and labels remain to be discussed. Existing Advanced controls already disclose less-used settings; decide how named groups and Advanced should work together as part of presentation planning. Remembering the groups' expanded/collapsed states is a proposed extension of Issue 2.

Proposed future acceptance: open the main section, fold and unfold an inner group, confirm the main list stays visible and usable, and verify saved settings and placements do not change. Check layout in narrow and wide panels, then restoration under the chosen Issue 2 policy. These are future checks, not implemented behavior.

## Issue 5 Simple naming and paint set placement

The artist finds the Layer / Paint set terminology confusing and wants simple, familiar names throughout the plugin. The [supplied panel screenshot](references/cyrus-layer-and-paint-set-naming.png) puts layer and paint-set management together without clearly showing their parent/child relationship.

The artist's proposed UI is that ordinary scattering belongs to a layer and paint sets become visible in the painting section when brush painting is enabled. The layer manager should not require the artist to understand or manage a set for ordinary generation. The artist is still unsure and has asked to examine what selecting a paint set currently does before finalizing this arrangement. Nothing has been implemented.

### Current ownership to preserve or deliberately reconsider

In the current system a layer contains a Base set and optional additional sets. Each set owns models, coverage and source-specific settings, and participates in population sharing and spacing. The layer owns the overall population and shared transforms. A set can use whole-surface coverage as well as a painted mask; its role extends beyond the brush. See [the current artist explanation](../Artist_Reference_0.73_2026-10-07/01_SETUP_AND_LAYERS.md).

The current engine's mandatory Base set should not dictate the visible workflow. Decide whether to retain that record internally or revise ownership only after the painting behavior is clarified. Existing population-sharing, background and spacing behavior will need deliberate treatment in the eventual design; no engine change has been authorized.

### Proposed direction

- Use simple artist-facing names and explain the hierarchy visibly.
- Make the main layer list clearly about layers, without paint-set management mixed into it.
- Ordinary setup should read naturally: choose receiving surfaces, choose a layer's models, set its distribution and generate.
- Keep the mandatory Base set implicit during ordinary scattering rather than requiring a visible set selection.
- When brush painting is enabled, show paint-set selection and management inside the painting section. In this workflow the term Paint set can describe its visible purpose.
- Make it clear which models a brush will paint, under the ownership policy still to be decided.
- Review confusing terms across the plugin as concrete examples arise; preserve internal registration identities during any future label changes.

### Remaining design decisions

The earlier suggestion to rename every set **Group** does not resolve the artist's concern. The proposed direction is to make sets part of the visible painting workflow and avoid exposing them during normal layer generation; it remains under discussion.

The main unresolved question is model selection during painting: should every paint set paint from the layer's model list, or should a paint set be able to choose its own models? This determines whether paint sets represent different painted regions of the same models or separately painted model collections. Do not assume either policy.

Also clarify how painted content relates to the layer's ordinary generated content and population count before changing the engine or removing existing sharing behavior.

### What selecting a paint set currently does

The artist supplied [a screenshot with Paint 3 selected](references/cyrus-paint-set-selection.png) and asked what selecting that dropdown changes. Source inspection of `selectSet` and the composer's binding logic shows that selection stops an active brush, stores the selected set identity on the parent layer and rebinds the editors to the relevant owners.

For the selected set, the UI shows its source models/container pool, coverage/painting controls and set-specific rules. Share weight, Enabled, Visible, name and set-management actions target that set. Population and shared transforms continue to target the parent layer. Other enabled sets remain included in the layer's scattering; choosing the editing target does not isolate output to that set or constitute an explicit Update.

This confirms that the current dropdown selects an editing context across multiple sections. Its current role is broader than brush selection, which the eventual presentation or ownership redesign must address explicitly.

### Brush and coverage wording

The artist asks what it means for a set to own models and questions why a separate Coverage concept is needed when normal brush/paint controls should be enough.

In the current model, each set identifies the source models used for its placements: for example, grass models in one set and flower models in another. Coverage describes where that set may place them. Whole surface allows placement across the receiver; painted coverage restricts placement to the region authored with the brush. The brush is the tool for changing that region.

**Painting** is a candidate simpler section name. The artist wants brush/paint controls rather than a separate unfamiliar Coverage concept. Any optional choices about painted regions should be explained inside that workflow. Whole-surface generation remains part of normal scattering; how a painted restriction or painted addition interacts with it remains to be decided.

## Issue 6 Compact actions and clear names and colors

The artist requests compact icons for Add, Copy, Remove, Move up and Move down on one row beneath the relevant list. An editable name and small square color swatch should sit below that row. The [supplied Forest reference](references/forest-compact-actions-name-color.png) illustrates a list with color markers, compact action icons and a Properties area containing Name and Color ID.

### Requested interaction

- Use a consistent compact icon row for supported list actions, with tooltips explaining each action.
- Show the selected layer's editable name below its actions.
- For source-model entries, obtain the selected scene object's name so the artist can identify it, then provide a way to rename the entry/object.
- Provide an identification color swatch and show corresponding colors in list rows and suitable viewport previews.
- Points and Proxy previews should make model identities easy to distinguish by color. Mesh should show the actual model geometry/detail.

The user mentions both layers and chosen source objects. Keep their names and colors clearly scoped: editing a layer label and editing a source-object label are separate actions. The precise locations and ownership of color swatches are not yet finalized.

### Current source findings

The current source list reads the scene node's name. Its existing Color control assigns a source color group, which the native preview receives. Point Cloud supports source-group colors or a chosen solid color. Geometry previews also receive source colors; the retained Mesh shader draws actual geometry with shaded preview color. This does not establish textured/material viewport rendering. Final render materials are separate from these identification colors.

The existing source-color value also contributes to procedural grouping for source assignment and is an authored input. It is not purely a cosmetic swatch. If the new swatch is intended only for visual identification, decide how to avoid recoloring silently changing distribution groups or rebuilding placements. See [Models and containers](../Artist_Reference_0.73_2026-10-07/02_MODELS_AND_CONTAINERS.md), [Viewport and render](../Artist_Reference_0.73_2026-10-07/09_VIEWPORT_AND_RENDER.md), `sourceColor`/`assignGroup` and `procStagePreview` in the authoritative template, and [the current Mesh shader](../../AminScatter/src/mesh_display.inc).

### Details to decide

- Confirmed: renaming a source changes only its optional label inside Scatter. Default display identifies the real selected scene source. Preserve stable identity when names change.
- Is color assigned per source model, per layer, or both? If both, define the active display choice and precedence clearly.
- Should Mesh offer an explicit choice between identification colors and model materials? Geometry detail and material appearance are separate choices; do not promise a material preview from the current Mesh implementation.
- Are identification colors purely visual, or also an explicit grouping tool? Clarify this before reusing the current color-group setting.
- What does Copy mean for each type of list entry? Use only actions meaningful to that list rather than implying every list copies scene geometry.

### Proposed future acceptance

Verify that each icon targets the selected item and has an understandable tooltip; names identify the correct scene source even after renaming; colors match list markers and selected viewport display modes; resizing and properties folding still work. A visual-only name/color edit should preserve object identity, source assignment and placement results. No implementation or new host qualification has occurred.

## Reference 1 Downloadable library packages

The supplied iToo Update Manager screenshot shows separately listed packages with version, size, status and download progress. Visible categories include Effects Library, Maps, Materials, 2D Shrubs, 2D Trees, 3D Flowers and Grass, 3D Stones and Rocks, Climbing Plants, Gravel, Green Walls, Lawns and Layered Lawns.

The artist asked us to keep this workflow in mind. A Cyrus library, downloader, package format, update service or delivery plan has not been requested. Keep this as a reference until its purpose and priority are discussed. The screenshot's account details are unnecessary to these notes.

## Reference 2 Forest settings and focus

The [supplied settings overview](references/forest-settings-overview.png) shows many sections, including Geometry, Distribution, Areas, Surfaces, Transform, Items Editor, Effects, Animation and Display. Availability of a visible setting is not proof of its behavior or its applicability to Cyrus Scatter.

The artist finds the amount of settings overwhelming and wants us to work intelligently: first fix existing issues and decide how existing and desired controls should be shown. Keep comparisons connected to a concrete artist workflow. Record new ideas for later discussion instead of expanding the current task automatically.
