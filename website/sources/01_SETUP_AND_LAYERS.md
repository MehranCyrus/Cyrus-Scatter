# 1. Setup, receiving surfaces, layers and paint sets

[Guide contents](README.md)

## Top controls — Enable and Viewport update for the whole setup

| Control | What it means and when to use it |
| --- | --- |
| Enable Cyrus Scatter | Enables calculation and output for this setup. Turn it off to disable the setup as a whole. Use Show preview instead when you only want to hide its viewport display. |
| Manual | Keeps the last completed planting while you adjust settings. Press Update now when ready to calculate the changes. A visible old result is not proof that the new values have been applied. |
| Live | Updates after relevant changes and a brief pause. Opening a section, browsing settings or playing unrelated animation should not create new planting. Live is the starting mode for a new setup. |
| Update now | Explicitly calculates the enabled layers and sets in order. Use it after edits in Manual or when deliberately requesting a fresh result. |
| Status below Update | Explains whether updates are waiting or will follow relevant edits. For a calculation failure, also check Statistics & diagnostics. |

Opening **Advanced**, selecting a row or closing a section does not itself enable or disable the planting feature. Changes to a recipe follow Manual/Live. Display controls and help can change what you see without changing where plants belong.

## Receiving surfaces — the whole setup

| Control | What it means and when to use it |
| --- | --- |
| Pick receiving surface | Click, then pick the ground mesh. This replaces the current receiving-surface selection with that one surface. |
| Receiving surfaces... | Choose one or several receiving surfaces by name. Confirm the selection to use that list. Ordinary scattering can use multiple surfaces; Brush requires exactly one shared surface. |
| Surface name / surface count | Shows the current receiver. The message that paint needs one surface explains why Brush may be unavailable. |
| Layer, plant and population counts | Summarizes the setup. Cached plants are from the last completed result. The population count includes every layer's Base set and each additional paint set. |

Use static mesh surfaces. Brush supports flat and curved static surfaces; an animated or deforming-ground workflow is not qualified here. Changing the receiver does not safely transfer old strokes onto unrelated geometry. See [coverage targets](05_COVERAGE_AND_PAINTING.md).

### Advanced: Global model palettes

| Control | What it means and when to use it |
| --- | --- |
| Global source containers list | Select a shared source rectangle. These rectangles are available to sets that explicitly choose Global containers. Creating one does not automatically change every set's source pool. |
| Create source rectangle | Creates a shared source container in the scene. Place original model pivots inside it. |
| Pick source rectangle | Links a suitable existing source container to this setup's global pool. |
| Unlink selected rectangle | Removes the link to this pool. It keeps the rectangle, scene models and registered source settings. |
| Container information | Reminds you which pool is being edited. It is separate from receiving-surface information. |

The current compact layout puts these controls under **Advanced**. There is no separate procedural-mode activation step to unlock the unified workflow.

## Layers & paint sets — layer controls

| Control | What it means and when to use it |
| --- | --- |
| Layer list | Selects the layer edited by the sections below. Each row shows its name, placed count and result status. Double-clicking can open its optional editor. |
| Add | Creates a layer with a Base set. An empty layer still needs a receiving surface and useful sources before it can produce planting. |
| Copy | Copies the selected layer and its paint sets/settings. The new layer is independent; it can still refer to the same original scene models or shared source containers. |
| Remove | Removes the selected layer and its sets. If it still owns baked output, clear that output first. This is more destructive than turning Enabled off. |
| Move up / Move down | Changes calculation order. Earlier layers normally get space first when a between-layer spacing rule applies. These buttons do not move scene objects. |
| Enabled | Includes the layer in calculation and final output. Disabling it also takes its sets out of that calculation. |
| Visible | Controls the layer's viewport display. An invisible but enabled layer still participates in spacing and can appear in final output. |

### Advanced: Layer management

| Control | What it means and when to use it |
| --- | --- |
| Name | Renames the selected layer. It keeps that layer's saved relationships. |
| Edit layer in window... | Opens an optional floating view of the same settings. It does not create another layer or a second independent planting. |
| Count / status details | Shows the selected layer's last completed result and whether it needs updating. |

## Selected paint set

| Control | What it means and when to use it |
| --- | --- |
| Selected paint set | Chooses which set's models, coverage, background and source-specific values you edit. Layer-wide controls continue to affect the whole layer. |
| Share weight | Divides the layer population between enabled sets. It is relative, not a plant count. Two sets with weights 1 and 3 receive roughly one quarter and three quarters of the requested layer population before rejection. Zero gives no ordinary population share. |
| Enabled | Includes this set in calculation and output. |
| Visible | Hides or shows this set in the viewport; it still participates in calculation and output while enabled. |

### Advanced: Paint-set management

| Control | What it means and when to use it |
| --- | --- |
| Add set | Adds another set within this layer. New additional sets begin with painted coverage, initially empty when a valid single receiver is available. Paint or Fill it, or choose whole-surface coverage. |
| Remove | Removes the selected additional set. The Base set cannot be removed separately; disable it or change its coverage instead. |
| Name | Renames the selected paint set without discarding its saved settings. |
| Move up / Move down | Changes set order inside this layer. Background references must remain earlier than the set using them, so some moves are refused. |
| Set information | Identifies the selected set and its place within the layer. |

A setup currently allows **ten total populations**, counting Base sets and additional sets together. For example, three layers with two sets each use six. A disabled set still occupies a saved slot.

New sets start with share weight 1. Sharing population does not guarantee the same final ratio: coverage, spacing and other restrictions can reject different numbers in each set.

**Example:** use one layer for a meadow, Base for grass and another painted set for flowers. Changing the layer's count changes the meadow budget. Changing the flowers' share changes how much of that budget they receive. Painting changes where that share is allowed.
