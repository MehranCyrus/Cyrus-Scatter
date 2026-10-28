# 0.87.6: finding the controls

The interaction behavior remains the 0.87.5.6 Bend/Trim system. This release repairs
Point sources and makes the existing settings easier to find. It does not introduce
a new solver or change the approved performance baseline.

## A short working sequence

1. Add a layer, choose its **Surfaces**, then add models in **Models & Points**.
2. Use **Layout** for planting positions and model assignment. Use **Amount** for
   count, density and image/surface masks.
3. Use **Painting** for local coverage, or **Include / exclude** for closed boundaries.
4. Change appearance in **Transforms**. Use **Spacing & cleanup** when plants need
   separation or isolated placements need removal.
5. Choose **Viewport & render** display/budgets. Prepare reacting models in
   **Interactions** only when the scene needs Bend/Trim.

**Manual** keeps edits pending until **Update scatter**. **Live** responds to relevant
changes. Opening a panel or changing a preview overlay does not generate placements.
Collapsing a settings group preserves its values and effects.

## Models and Points

**Add point** creates a placeholder row. **Use point** converts the selected model
row to a Point while keeping its identity and settings; it does not delete the scene
object. **Replace selected...** assigns a scene model to that row. A model already
registered in another row cannot be registered twice in the same source list.

The Point path now works with source scale and Z offset. Models & Points and
Interactions continue to show the same source membership.

Common model settings stay visible. **Spacing overrides** contains the model's
radius and clearance policy. **Clearance distance** contains its explicit factor,
gap and metric. **Assignment groups** contains group color and the optional Empty
source; an Empty source creates intentional gaps and is different from a Point.

## Painting and fade

Each Paint Area belongs to one receiving surface. Select the area before editing it.

- **Fade inward** thins or changes size inside the painted boundary.
- **Extend outward** spreads that transition outside the painted boundary, still
  within the receiving surface. It cannot extend beyond the receiver itself.
- **Fade density** controls thinning. **Fade plant size** controls scale; **Edge size**
  and **Inner size** appear only when size fade is enabled. Endpoints stay ordered.
- **Fade curves** opens the optional curve controls.
- **Paint preview** contains vector borders, coverage samples and overlay color.
- **Spline tools** contains export and Replace/Add import.

Stop the active brush before changing its edge fade. Those controls are disabled
during painting, and the status explains why. In Manual mode, the status reminds
you to click Update scatter. Overlapping Paint Areas combine coverage: another
area can cover the edge you are trying to fade. Test one area in isolation when
checking its transition. Fill covers the receiver, so outward fade cannot enlarge
that result beyond the receiver.

## Masks, Bands and transforms

**Show density preview** is a single show/hide button in Amount. This preview is
separate from the Paint Area overlay and the Band overlay.

Band buttons now read **Out +**, **In +** and **x**. Analyzer channels use **Line +**,
**Radius +** or **Point +** where appropriate. **Show band density** and **Show band
borders** are inspection controls. The selected Band still owns its width,
assignment, density and scale profile.

Transforms keeps proportional scale in the main flow. Open **Non-uniform scale**
for independent X/Y/Z scale. Slope and altitude ranges appear when their filters
are enabled. Boundary fade distances appear when their corresponding effect is
enabled. The layer's independent rules and units have not changed.

## Where the less common controls went

| Panel | Secondary controls |
|---|---|
| Surfaces | Surface tools |
| Models & Points | Source access, Spacing overrides, Assignment groups |
| Layout | Band order & details, relevant to the selected assignment mode |
| Amount | Sampling & display options |
| Painting | Fade curves, Paint preview, Spline tools |
| Include / exclude | Analyzer tools |
| Transforms | Non-uniform scale |
| Spacing & cleanup | Cleanup & instance overrides |
| Viewport & render | Display options |
| Stats & diagnostics | Diagnostic recording |
| Interactions | More settings; common Bend/Trim and trunk controls remain visible |

[Every control and its owner](CONTROL_LEDGER.md) · [Validation scope](QUALIFICATION.md)

## Install

Save your work and close the Max versions selected in the EXE, install, then reopen
Max. Alternatively run the matching year’s MZP through **Scripting > Run Script**,
then restart Max. Keep script and native modules from the same package.

Max 2027 has the recorded UI/runtime checks. Max 2024 and 2026 receive separate SDK
builds and verified packages; they were not launched for this release. Native Scene
presets retain their existing Max 2027-only scope. Analyzer and content remain
independently versioned.
