# 11. The optional layer window and individual instance editing

[Guide contents](README.md)

## Optional layer window

Open **Layers & paint sets > Advanced > Edit layer in window...**, or **Edit layer...** on a linked source container. The native Modify sections remain the main workflow.

| Control | What it does |
| --- | --- |
| Setup/context text | Identifies the setup and layer being edited. Selecting source geometry in the scene does not automatically switch this window to another layer. |
| Layer dropdown | Changes the layer being edited. |
| Paint set dropdown | Changes the set-specific models, coverage and related values. |
| Update setup | Updates the entire setup, including enabled layers and sets in order. It is not limited to the current tab. |
| Assets | Shows Models & source containers and paint-set management. Source assignment is under the Models section's Advanced controls. |
| Population | Shows Population and Include / exclude areas. |
| Paint | Shows Coverage & painting, including background controls in Advanced. |
| Transform | Shows layer transforms. An older tooltip may still mention source assignment; find assignment under Assets in the current layout. |
| Spacing | Shows spacing rules, individual radii, Relax and cleanup. |
| Statistics | Shows result information and the current statistics/diagnostic section. |
| Refresh fields | Rereads settings and existing counts without requesting new planting. Use it to refresh the editing view. |
| Read cached statistics | Reads the existing result from the Statistics topic. It is different from Update setup. |
| Advanced | Reveals the same detailed settings as their Modify equivalents. Closing it preserves values. |
| Window close | Closes the editing view. It does not delete the layer or discard already applied values. |

The window and Modify panel edit the **same saved settings**. They do not create two independent scatters. Merely leaving the window open should not continually regenerate planting.

Stop Brush before switching layers or sets. If a view identifies a different layer than you intended, select the correct layer before changing values.

## Selecting a source container

A selected rectangle has its own Width, Length, label and movement-following controls, plus the linked Scatter sections. Its context dropdown chooses which linked setup/layer/set those sections edit. The full explanation is in [Models and source containers](02_MODELS_AND_CONTAINERS.md).

## CS Edit — individual placed plants

CS Edit provides instance editing through the modifier stack. Use it when one or a few placed plants need a deliberate adjustment rather than changing the whole recipe.

| Control or action | What it does |
| --- | --- |
| Instances | Enters instance selection. Pick the placed instances to edit. |
| Selection/status text | Shows selected, total and suspended instances, or explains why the saved edits no longer match the current layout. |
| Move / Rotate / Scale | Uses Max's transform tools on selected instances. This edits placed plants, not the source models in the palette. |
| Clone selected instances | Uses Max's instance/sub-object cloning interaction to make deliberate additional placements. It is not a new population setting. |
| Delete selected | Removes selected instances through CS Edit. The source model remains available for other instances. |
| Reset Edits | Clears the modifier's saved instance edits. Use it deliberately; it is not a refresh button. |
| Select all / deselect / invert selection | Uses Max's normal selection actions for editable instances. Hidden or inactive populations are not an invitation to edit unrelated planting. |

A seed or layout change can make existing edits no longer match their original placements. Restore the relevant generation settings or explicitly Reset Edits before continuing. Do not assume every recipe change can preserve every individual edit.

The selected-instance radius controls are in **Spacing & cleanup > Advanced**. Choose World radius or Radius multiplier, enter a value, then press **Set selected radii**. Merely selecting an instance does not give it a new radius.

Saved instances and their edits have relationships to the planting that produced them. If an edit becomes suspended, read the status and inspect the layer instead of deleting source geometry to try to repair it.
