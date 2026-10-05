# Artist testing guide — Cyrus Scatter 0.7

> **Build applicability:** The steps below describe the packaged 4 October candidate, which still has Apply spacing. The later working-tree UI saves spacing fields automatically; Manual still requires Update to calculate. That native-column/UI update is unfinished and has not been packaged. Read the [current handoff](../Review_Handoff_2026-10-05/CURRENT_STATE.md) before testing current source; use matching script/native binaries in a fresh private process.

Do not replace the plugin inside a running Max session. The candidate packages have different native content IDs and require a clean restart. Begin with a separate disposable test scene/session; keep the current working scene and installed baseline available for comparison.

Max 2027 has completed isolated qualification; Max 2026 has build/native-suite evidence only. When opening a saved painted scene, **adopt the file's system units**. Automatic rescaling into different system units is not supported for the saved Brush/Edit/radius state. Keep Proxy display limits modest; at very high counts prefer retained Mesh, Point Cloud or centres. Details and measured limits are in the [runtime report](RUNTIME_REPORT.md).

## First setup

1. Install the package for the chosen Max year and restart. Verify **Cyrus Scatter 0.7** / `uiVersion() == "0.7.0"` and that only the intended native package is loaded.
2. Add a receiving plane and a Garden layer. Add Red flowers, Blue flowers and Grass paint sets. Assign a distinct simple source to each.
3. In **Surface Scatter**, choose **Enable Procedural 0.7**. Conversion is explicit because the new sampler changes candidate positions. A setup with CS Edit cannot be converted in place.
4. Put flower sets before Grass with **Move up/down**. A Base set can move within the set order; its role as the layer's settings owner does not change.
5. Paint flower regions. Use candidate centres when judging accepted instances; coverage tint/samples are a mask visualization.

## Spacing

To set source radii, open the layer, choose the desired **Paint sets → Edit set**, then open **Plant assets**. Select the object row(s) under **Sources (Ctrl/Shift)** and scroll down to **Collision radius**. **Follow Scale** adjusts the spacing radius with the final plant scale. **Show Radius** enables the radius overlay, subject to the viewport's radius display limits. Source radius is spacing metadata; it does not resize the plant mesh.

Open **Procedural / Rules**. The top identifies the current layer and selected paint set.

- **This paint set:** controls plants within the selected set. Until Apply, it inherits `2 × Collision radius` from Collision / Relax.
- **Default between sets:** controls sibling sets independently of self spacing.
- **Pair of paint sets:** choose a sibling and override that default, including explicitly disabling it.
- **Pair of layers:** choose another layer and define the inter-layer relationship.

Radius factor multiplies the sum of both plants' effective radii; Extra gap is added afterward. Source radius is set in Plant assets. A factor alone creates no clearance if both source radii are zero. XY deliberately ignores vertical separation.

For a source-radius rule, choose the scope and peer where applicable, check **Enable this spacing**, set **Radius factor = 1**, choose **Extra gap**, and press **Apply spacing**. In Manual mode, use **Update → Update now** afterward. For example, radii of 50 cm and 20 cm with a 10 cm extra gap require 80 cm between centres. Equality is allowed. Earlier ordinary layers/sets win and conflicting later candidates are rejected. Eligible protected CS Edit instances are preserved and their conflicts reported. These are centre-distance checks, not triangle-by-triangle mesh collision tests.

To edit an individual radius, select its plant/clone in CS Edit, select the matching paint set, choose World radius or Radius multiplier, and press **Set selected radii**. These overrides do not resize the geometry. They belong to the generation binding; use the explicit clear action when intentionally replacing that binding.

## Two different fill tasks

For grass around flower beds, select Grass → **Outside painted coverage** → select earlier flower sets → **Apply background**. Soft Brush fields remain soft. A referenced Whole-surface set can consume the whole shared Area domain even when its plant count is small or zero. Hidden sets still contribute; disabled sets do not.

For grass between actual flowers, configure the relevant sibling/pair spacing rules and choose **Between plants**. This mode does not create a hidden margin or switch those rules off when disabled. The **Outside + between** option uses both constraints.

To replace plants rejected by masks/collision, change **Layer population → Accepted target**. Attempt factor and Max rounds bound the search. Read **Shortfall**, **Attempts** and **Rounds** after Update. A target may remain unmet, especially with tight space or cleanup. Point placeholders count as slots; weighted Empty assets require Candidate budget mode.

## What should remain stable

- Reordering changes ordinary spacing winners but not seeds or allocation tie order.
- Renaming, collapsing/opening panels and changing visibility do not regenerate positions.
- Changing display mode rebuilds display resources from the completed placements.
- Manual retains the last completed output until Update; pending settings and errors must not masquerade as new completed statistics.
- Failed calculation keeps the previous display; restoring valid settings should recover without losing Brush or Edit history.
- Eligible protected edits survive a reduced or zero ordinary quota, including clones. Erasing their input coverage suppresses them until that input is eligible again.

Report the scene copy, Max year, system units, display mode/budgets, exact parameter change, error text and cached diagnostics when a behavior differs. The [validation record](VALIDATION.md) distinguishes completed fixtures from remaining release gates.
