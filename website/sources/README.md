# Cyrus Scatter 0.73 — artist reference

7 October 2026. A plain-language guide to the current compact interface, including Advanced settings, source containers and the optional layer window. It describes the current development version; it does not promise that every combination has passed an artist test.

Start here when learning the controls. Older dated guides describe earlier layouts. The current layout has ten main sections below the Enable, Manual/Live and Update controls. Source assignment is now inside **Models & source containers > Advanced**.

## Find a control

| What you want to do | Read |
| --- | --- |
| Start a setup, choose ground, manage layers and paint sets | [1. Setup and layers](01_SETUP_AND_LAYERS.md) |
| Choose models, change their weights and radii, use source rectangles | [2. Models and source containers](02_MODELS_AND_CONTAINERS.md) |
| Arrange model types in clusters, bands, rows or Analyzer patterns | [3. Source assignment](03_SOURCE_ASSIGNMENT.md) |
| Set amounts, density, seeds and replacement attempts | [4. Population](04_POPULATION.md) |
| Paint, erase, edit strokes and fill around other planting | [5. Coverage and painting](05_COVERAGE_AND_PAINTING.md) |
| Keep planting inside or outside shapes, soften boundaries | [6. Areas and falloff](06_AREAS_AND_FALLOFF.md) |
| Rotate, scale and move plants | [7. Transforms](07_TRANSFORMS.md) |
| Separate plants, adjust individual radii and clean small patches | [8. Spacing and cleanup](08_SPACING_AND_CLEANUP.md) |
| Change viewport appearance and prepare rendering | [9. Viewport and render](09_VIEWPORT_AND_RENDER.md) |
| Understand counts and record a problem | [10. Statistics and recording](10_STATISTICS_AND_RECORDING.md) |
| Use the floating layer window or edit individual instances | [11. Other editing views](11_OTHER_EDITING_VIEWS.md) |
| Understand every Surface Analyzer control | [12. Surface Analyzer](12_SURFACE_ANALYZER.md) |
| Understand automation, licensing and future AI work | [13. Automation and current limits](13_AUTOMATION_AND_LIMITS.md) |
| See what was checked and follow a practical artist walkthrough | [14. Documentation review and walkthrough](14_REVIEW_AND_WALKTHROUGH.md) |
| Find an individual control by name | [15. Complete control index](15_CONTROL_INDEX.md) |

## The few ideas everything builds on

- A **setup** is one Cyrus Scatter object, with shared receiving surfaces, update mode and display settings.
- A **layer** is a planting recipe: its population, area limits, transforms and cleanup. Layers run from top to bottom.
- A **paint set** is a part of a layer with its own models, share of the population and painted coverage. Sets also run in their listed order.
- A **source** is an original model used to make repeated plants. An **instance** is one of those placed copies.
- A **source container** is a rectangle for organizing original models. A **receiving surface** is the ground on which instances are placed.
- **Advanced** reveals less frequently used controls. Closing it preserves their settings and does not turn their effects off.

The selected layer and paint set determine what you edit. A layer setting affects all its paint sets. A model setting affects the highlighted source rows in the current paint set. Selecting an option to inspect it is different from changing its value.

## A simple first planting

1. Create a Cyrus Scatter object and pick a static receiving surface.
2. Add a layer in **Layers & paint sets**. Select its Base paint set.
3. Add a model in **Models & source containers**.
4. Start with **Population > Count**, a modest amount, and whole-surface coverage.
5. Choose **Point Cloud** in **Viewport & render**. In Manual mode, press **Update now**.
6. Add painted sets or area limits, then adjust transforms and spacing.
7. Check statistics before assuming that the requested amount was placed.

Distances use the scene's units, except **Plants per m2**, which means plants per square metre. Rotation values are degrees. A scale of **1** means unchanged size; **0.5** means half size. Minimum and maximum values define a random range; matching values give a fixed value.

This guide is explanatory. It introduces no changes to the plugin, scenes, settings or installed files. It was checked against the current controls and their behavior descriptions; the walkthrough remains a checklist for the next interaction-testing round.
