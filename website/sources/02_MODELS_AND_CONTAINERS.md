# 2. Models and source containers

[Guide contents](README.md)

Find these controls in **Models & source containers**. The source list and per-model settings belong to the selected paint set. The same scene model may have different saved settings in different sets.

## Source pool

| Choice | Meaning |
| --- | --- |
| Manual sources | Use models added directly to this paint set's source list. The rectangle list is empty unless a container pool is selected. Create and Pick are still available and switch to an own container pool. |
| Global containers | Use rectangles linked in Receiving surfaces > Advanced. Multiple layers or sets can share this scene palette. |
| Layer containers | On the layer's Base set, use that layer's own rectangles. |
| Layer default | On an additional set, inherit the layer's declared container pool. Source weights, scale and other per-model settings still belong to the consuming set. A manual layer pool does not become a rectangle automatically. |
| This set's containers | On an additional set, use rectangles owned by this particular set. |

The choices differ between Base and additional sets. To create a layer rectangle, select Base and press **Create**; the source pool switches to **Layer containers** automatically. There is no extra enable step.

| Control | What it does |
| --- | --- |
| Rectangles list | Selects a linked rectangle for unlinking or inspection. |
| Create | Creates a source container owned by this layer/Base or this additional set, and switches to that own pool. To create a shared global rectangle, use Receiving surfaces > Advanced instead. |
| Pick | Links an existing Cyrus container to this owner's pool and switches to that pool. Picking a suitable square-corner Rectangle creates a Cyrus container from it and keeps the original spline. |
| Unlink | Removes the selected rectangle from this owner's pool without deleting it or the original models. It is unavailable while using an inherited/global pool; edit that pool at its owner instead. |
| Active / registered count | Active models are currently eligible in the pool. Registered models include previously admitted models whose settings are retained while parked outside. |

Membership uses the **model pivot inside the rectangle's local footprint**. Height is ignored. A large model can extend outside while its pivot is inside. A model visually overlapping the rectangle can still be outside if its pivot is outside.

A source pool can contain up to 32 linked containers. One model inside several rectangles of the same pool is still one source, not a reason to add it repeatedly.

Moving a model out parks it; moving it back reuses its saved identity and settings. Do not use **Remove rows** when you want temporary parking: that unregisters the source record. Manual mode needs Update now to refresh the planting.

## Models and their settings

Select one or several source rows. Ctrl/Shift selection lets you apply the same value to several models.

| Control | What it does and when to use it |
| --- | --- |
| Sources list | Shows the registered models or placeholders, their weight and color group. Highlight the rows you intend to edit. |
| Pick model | Picks one scene model for this set. The layer editor stays on its current layer while you choose a model. |
| Add selected | Adds the scene objects already selected in Max. |
| Weight | Relative chance of choosing this model within the set. Range 0–1; 0 disables that source. Weights do not have to add to 1. Values 1 and 0.5 mean roughly twice as much of the first model before other restrictions. |
| Scale | Multiplies the size of instances made from the selected model. Default 1; 0.5 halves size. It works together with layer scale and any boundary/band scale. |
| Radius | The selected model's collision footprint, in scene units. Default 0. It does not measure the mesh automatically. Give it a useful positive value when spacing should account for plant size. |
| Z Offset | Raises or lowers instances along their placement normal. Default 0. Use it to correct a model that appears buried or floating. |
| Follow Scale | Makes the collision footprint respond to instance scale. Without it, the source radius remains a fixed distance. Starts off. |
| Show Radius | Displays this source's collision-radius guides. It does not turn spacing on. Viewport radius limits may show only some guides. Starts off. |

With no highlighted source, source-value fields cannot meaningfully edit a model. Multi-selection applies the entered value to each highlighted row; it does not preserve each row's previous difference.

### Advanced: Source details

| Control | What it does |
| --- | --- |
| Choose from list... | Adds one or several models by name instead of picking in the viewport. |
| Select sources | Selects the highlighted source models in the scene. |
| Remove rows | Removes the highlighted registered sources and their row settings. The original scene models remain. |
| Forward axis | Chooses +Y, -Y, +X or -X as the model's forward direction for orientation. Use it when a path-facing model points sideways or backwards. |
| Add Point | Adds a placement placeholder. A Point can count as an accepted placeholder without providing final model geometry. |
| Add Empty | Adds a weighted intentional gap. Use Candidate budget population for positive-weight Empty rows. |
| Replace Point: pick object | Select exactly one Point row, then pick its replacement model. This keeps a placeholder workflow without adding another unrelated source row. |
| Existing color groups | Assigns highlighted sources to a previously used group. The group's color identifies a family for clustering and pattern assignment. |
| Color | Chooses a color group for highlighted sources. Accepting the color applies it. This is not a material-color editor. |
| Apply to selected rows | Applies the chosen color group to all highlighted source rows. |

**Example:** put three grasses in a layer rectangle. Give a tall grass weight 0.3 and a low grass weight 1. Move the tall grass outside to compare the meadow without it. Move it back to restore its saved contribution.

## Selecting and moving the rectangle itself

Selecting a Cyrus Source Container opens its linked Scatter controls in Modify, with an extra **Source Container** section.

| Control | What it does |
| --- | --- |
| Edit linked Scatter context | Chooses which linked setup/layer/set to edit if more than one uses this rectangle. Changing this view does not change the rectangle's membership. |
| Width / Length | Resizes the rectangle. Starting dimensions are 500 by 300 scene units. Models keep their transforms; a changed boundary can admit or park them. |
| Show viewport label | Shows or hides the rectangle's context and active/saved counts beside it. |
| Active / parked source models | Shows models retained for this container and their current state. Select a row before assigning movement ownership. |
| Follow this container | Assigns the selected source's movement following to this container. Use it to resolve overlapping rectangles. The model can still be used by other sets. |
| Edit layer... | Opens the optional window for the currently linked layer. |
| Last move / context information | Explains the current linked context and whether the last following move succeeded or was refused. |

Moving a rectangle can translate its active, assigned static models with it. A model follows one movement owner, even if several rectangles overlap. Parked models are not dragged along just because their settings are remembered. This is a controlled source-following feature, not an unrestricted replacement for Max groups.

Translation is the supported following operation. Do not expect resizing, rotation or scale to transform all source models as a group. Models with animation or unsupported transform relationships can be refused. Whole group/hierarchy handling must preserve the models' existing relationships.

An unlinked rectangle can remain in the scene without a Scatter context to show. Link it through the desired source pool first.

A first container-move Undo lost its history in an earlier test and is still unresolved. Use a saved test copy for movement/Undo experiments; see [current limits](13_AUTOMATION_AND_LIMITS.md).
