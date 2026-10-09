# Models and painting: recommendation for 0.74

8 October 2026 historical recommendation. Superseded by the [October 9 implementation and remaining gates](../Layer_Paint_Areas_0.74_2026-10-09/README.md). The implemented areas restrict their layer; they do not own models or add another population.

## What the references establish

[Forest Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry) manages the models available to a Forest object. [Forest Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas) defines include/exclude regions; a paint area is one kind of region. An area can optionally select a subset of the object's models. Picking an area changes the properties being edited. These are documented responsibilities, not recovered original source code.

The existing local Ghidra inspection provides supporting native evidence: the `areaParams` registration contains named, typed area records, while the selected contour-publication function constructs closed `PolyLine` records in a `PolyShape`. The inspected artifacts are in ignored `build/forest-brush-research-20261008-01` (`batch03/area_parameter_registration.c` and `batch03/area_publish_contours.c`). This supports a region representation; it does not establish all model-selection, overlap or allocation policies. Vendor decompilation is not incorporated into Cyrus.

[Chaos Scatter](https://documentation.chaos.com/space/CRMAX/124525180/Chaos%20Scatter) separates target objects from instanced model objects and exposes relative model frequency. That supports separating **where** objects scatter from **what** is scattered. It is not evidence that Chaos uses Cyrus-style layers or sets internally. Forest's area painting must also not be conflated with directly painting/editing individual instances.

The reusable tools are Ghidra 12.1.4, ghidra-mcp 6.0.0 and Java 21 from the existing tyFlow tool directory. The original tyFlow project is preserved. See the [Forest research handoff](../ForestPack_Research_2026-10-08/HANDOFF.md) for isolated projects and reproducible helpers. No new tool installation is needed.

A [fresh Chaos adapter inspection](CHAOS_OWNERSHIP_EVIDENCE.md) also found separate model/target parameters and painted-instance override parameters. Region painting and direct instance painting must remain distinct concepts; this pass does not claim a complete reconstruction of either vendor's system.

## Recommended artist workflow

1. **Surfaces**: choose receiving scene objects for the setup.
2. **Layers**: organize independent scatter populations, such as Grass and Trees.
3. **Models**: choose the selected layer's models and relative amounts.
4. **Painting**: optionally create named **Paint areas** and paint/erase their regions. Ordinary scattering requires no paint-area selection.

A paint area should use the layer's model list by default. An optional **Models for this area** override can select a subset when needed. Different population counts or substantially different transforms belong in another layer. Selecting a paint area should edit that area's mask and properties, without silently switching the main Models panel to another owned source list.

Example: the Grass layer lists two grass models and flowers. Normal scattering uses that list. A named Flower patch can restrict its painted region to flowers. The interaction between a patch and whole-surface scattering still requires an explicit policy: do painted regions replace, restrict or add to the base distribution? Avoid quietly double-counting overlapping regions.

## Why moving the current dropdown is insufficient

Current Cyrus sets own source lists, source settings, coverage, share weights and some spacing rules. They can scatter across the whole surface without painting. The layer owns shared population and transforms. Hiding these records under Painting would hide active non-painting behavior; renaming them Paint areas would promise ownership they do not yet have.

Keep this item open until the overlap/population policy and treatment of existing multi-set setups are settled. Implement the independent list, resizing, disclosure and state-retention changes without silently rewriting the engine. Do not mark the naming/ownership item complete merely because captions changed.

## Confirmed name-edit decision

The artist explicitly chose **Change only its label inside Scatter**. Source labels must default to the scene object's name and preserve source identity. Editing the Scatter label must not rename the 3ds Max scene node or change placements.
