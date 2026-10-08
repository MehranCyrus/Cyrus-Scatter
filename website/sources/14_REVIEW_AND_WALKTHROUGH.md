# 14. Documentation review and artist walkthrough

[Guide contents](README.md)

## What was checked for this guide

This is a documentation review dated 7 October 2026. No new plugin feature, production fix, installation or artist-scene change was made in this round.

The guide was compared with the current compact interface, its available choices and control behavior, the 240-entry control inventory, and existing development test reports. A second pass checked the explanations, names, ownership, unavailable states and cross-links. The [complete control index](15_CONTROL_INDEX.md) gives every inventory entry a destination.

| Coverage | Documentation result |
| --- | --- |
| Top controls and ten Modify sections | Explained, including Advanced options and status messages. |
| Layer and paint-set ownership | Explained separately; population sharing and visible/enabled differences are explicit. |
| Source containers | Creation, inheritance, parking, linked editing, labels, resizing and following are explained. |
| Optional layer window | Current tab contents and its shared settings are explained. |
| All 240 inventory entries | Accounted for, including repeated views and four disclosures now presented through Advanced. This is not a count of independent visible buttons. |
| Falloff graph and CS Edit | Additional editing controls and important consequences are explained. |
| Surface Analyzer | Its separate controls and its relationship to Scatter are explained. |
| Automation panel | User choices and limits are explained without requiring programming knowledge. |
| Existing test results | Used with their original limits. Documentation coverage is not treated as a new interaction-test pass. |

The second pass corrected several easy-to-misread descriptions:

- **Create/Pick source container** can switch to an own pool automatically; creating a rectangle does not require a separate procedural enable step.
- Creating a **global** container happens in Receiving surfaces > Advanced. The Models section's Create/Pick actions create or link an **own** pool even if the previous selection was global.
- **Reset rotation** sets the limits to zero; it does not restore the new-layer 0–360 Z range.
- Later layers can start with different **population seeds**.
- **Mask %**, **Paint feedback**, **Group stroke history**, **Attempt factor** and **Refresh fields** are named as they appear in the current interface.
- **Source assignment** is under Models & source containers > Advanced, including in the popup's Assets topic. Some older help text still points to the former placement.
- **Refresh preview** and radius-guide refresh controls can request an update. **Read cached statistics** is the passive inspection action.

Older dated implementation reports remain historical. Their installation references and former sixteen-section layout are not the instructions for navigating today's compact UI.

## What this does not certify

This round did not rerun Max, perform new rendering or measure playback. It did not confirm every artist gesture, every input combination or every Undo/save/reopen path. Existing issues, including the unresolved first container-move Undo case, remain listed in [current limits](13_AUTOMATION_AND_LIMITS.md).

The following is an **unperformed checklist for the next testing round**, not a list of new passing results.

## A practical walkthrough for the next round

Use a saved test copy and a small planting first. For each change, check the selected setup/layer/set, the expected visual result, and the status text.

| Step | Action | What to look for |
| --- | --- | --- |
| 1 | Open an empty setup; inspect unavailable fields | Controls should explain the missing selection or input instead of editing an unrelated owner. |
| 2 | Add, select, rename, copy, move and remove layers | The intended layer changes once; the UI remains bound to it. Check Undo and Redo after each supported operation. |
| 3 | Add sets, change shares, reorder, enable and hide them | Shares divide one layer population. Hiding differs from disabling. Base cannot be removed separately. |
| 4 | Pick receivers individually and by list | One shared receiver allows Brush. Multiple receivers produce the appropriate Brush limitation. |
| 5 | Add/select/remove models through every source action | The intended rows change; scene source objects survive unregistering. |
| 6 | Try Weight, Scale, Z Offset, Radius, Forward axis and colors | Changes affect the selected source rows in the intended set. Compare one-row and multi-row selection. |
| 7 | Create/pick/unlink own, inherited and global containers | Pool ownership is clear. Switching the pool does not silently edit another pool. |
| 8 | Park and return a source with custom values | Its saved values return with the model. Compare Manual before/after Update and Live. |
| 9 | Select, resize and translate a rectangle; test overlap ownership | Linked controls stay correct. Resizing changes membership. Translation follows only eligible assigned models. Check the known Undo concern in a disposable copy. |
| 10 | Compare Count, Plants per m2, maps, inversion and seeds | Population and allowed regions change as explained. Confirm actual count and shortfall. |
| 11 | Compare Candidate budget and Accepted target | Retry limits are respected, impossible targets can remain short, and positive-weight Empty sources explain their restriction. |
| 12 | Paint and erase on flat and curved static ground | Strokes land on the intended receiver and set. Test Stop, Fill, Empty and Undo. |
| 13 | Edit, disable and delete saved strokes | Only the selected stroke changes; the next-stroke settings remain a separate choice. |
| 14 | Switch receiver and coverage modes | Saved paint is not silently transferred to unrelated ground. Reset coverage target clearly replaces the old coverage. |
| 15 | Compare all background modes and earlier-set references | Outside coverage and Between plants visibly differ. Apply background commits the chosen combination. |
| 16 | Add include/exclude shapes and edit their falloff graphs | Exclusion wins; the selected area's own graph changes. Closing the graph keeps its edits. |
| 17 | Try every transform range and individual Reset button | Each reset affects only its category; per-axis and whole scale remain distinct. |
| 18 | Compare Random, Clusters, Line Pattern and all Analyzer channels | Only relevant controls appear; selected bands, source choices and row settings change the intended pattern. |
| 19 | Test every spacing scope with two sets and two layers | Each rule affects its intended relationship. Pair/default inheritance and XY/3D differences are clear. |
| 20 | Edit individual instances and their radii | Selected instances receive the changes; clearing one selection's overrides differs from clearing the whole set's overrides. |
| 21 | Compare both Relax modes, cleanup and cleanup retries | Their different roles are visible and protected edits remain identifiable. |
| 22 | Try every preview mode, budget, radius guide and color option | Shown detail can change without being mistaken for final population. Check explicit refresh behavior in Manual. |
| 23 | Read statistics and record/save a small problem sequence | Reading does not request planting. Recording is optional and saving stays local. |
| 24 | Open the popup, change every topic and retarget between layers | The displayed owner and edited owner agree. Compare the same values in Modify and container views. |
| 25 | Change each Analyzer setting and create each output type | Manual/Real-time behave separately from Scatter. Exported guides remain snapshots. |
| 26 | Exercise automation inspection, proposal approval and revocation | The assistant stays within the chosen supported scope. Recording and image sharing require their own choices. |
| 27 | Save, close and reopen the test copy | Layer order, source settings, coverage and supported edits remain associated correctly. |
| 28 | Leave Live and the popup idle; play unrelated animation | No unexplained repeated planting updates. Compare normal rendering and interactive rendering separately. |

For full control-by-control testing, use the [control index](15_CONTROL_INDEX.md) to mark the individual fields attempted inside each walkthrough step. Record the scene and outcome; do not turn a whole step green because only its first button worked.
