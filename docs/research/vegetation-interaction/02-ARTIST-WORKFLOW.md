# 02 Artist workflow

**Status: proposed behavior for discussion and later qualification.** Existing Manual/Live and publication contracts continue to apply. Names below are working labels, not delivered controls.

## First use

1. Select a Scatter layer or an explicitly supported subset of its accepted placements.
2. Choose Rooted fit and a prepared source preset. Review root positions, base frames and blade/guide associations in an overlay.
3. Add stones or other supported geometry to an explicit obstacle set. Preview the actual collision representation and clearance envelope.
4. Adjust clearance and flexibility; choose a fixed base frame or soft angular attachment. Root position remains planted in rooted mode.
5. Press Update. Review affected, unchanged and unresolved placements, then keep the completed result or revise the request.

Source preparation should be reusable. Moving a stone should generally require another fit, not another mesh binding. A source topology/reference change can require preparation again.

## Essential controls

| Control | Artist meaning | Required clarification |
| --- | --- | --- |
| Obstacles | Geometry that this vegetation must avoid | Independent from placement-spacing scopes; ground participates only when included |
| Clearance | Desired visible separation in scene units | Show the full effective envelope; distinguish numerical tolerance from desired spacing |
| Flexibility | How strongly the plant resists bending | Start from tested source presets; avoid implying measured botanical calibration |
| Root position | Attachment location | Fixed in this mode; conflicts are reported |
| Base attachment | How the blade can turn above its root | Position-only hinge, soft angular attachment and fixed frame are different choices |
| Preserve source shape | Preference for the authored rest shape | A completed fit does not silently become a new rest shape |
| Quality/work limit | Allowed solve and validation effort | A budget limit can produce an unresolved result |
| Update / Cancel / Reset / Bake | Recompute, stop, restore authored shape, or create output | Define Undo and persistence before implementation |

Rigid Settle needs gravity, hulls, friction and a declared start state. Drape needs surface topology, thickness, stretch and optional self-contact. Their controls should be presented with their respective modes.

## After moving a stone

Manual mode marks relevant vegetation Pending and retains the last complete publication until explicit Update. That retained geometry may intersect the newly moved stone; its status must show that it is stale. Update includes the stone's old affected region, new affected region and previously dependent plants, so vegetation released from contact can return toward its rest shape.

Live mode schedules bounded work for relevant dependencies. Interactive edits can be coalesced, but a relevant animated obstacle or source cannot be ignored under a blanket “after drag release only” rule. Navigation, selection and unrelated animation must not refit static vegetation or upload unchanged buffers. These follow the existing [F04 evaluation contract](../../ENGINEERING_FOUNDATION.md#f04-manual-updates-and-relevant-live-dependencies).

A proposed Freeze at sampled time option would need its own explicit time/dependency contract. It must not silently redefine existing Live behavior. Bake is a distinct output action with deliberate source and dependency retention rules.

## Result states and recovery

| State | Meaning | Useful response |
| --- | --- | --- |
| Preparation needed | Roots, correspondence or geometry are unsuitable | Select the source and show the missing preparation |
| Pending | Relevant inputs changed | Keep prior output visibly marked stale; offer Update |
| Root conflict | A fixed root or protected base lies inside the obstacle envelope | Show the root and conflicting obstacle |
| Ambiguous obstacle | Solid occupancy or surface sidedness cannot be established | Highlight the obstacle and request a supported solid proxy or explicit sheet policy |
| Unsupported scale / transform | The input falls outside the qualified numerical or shape profile | Show the affected source and supported profile; do not silently change geometry or clearance |
| Unresolved contact | Requested clearance was not achieved | Show all participating contacts and measured residuals |
| Envelope too conservative | The selected circular proxy blocks a space that may admit an oriented blade | Offer a qualified orientation-aware profile or a revised request; do not call every possible blade route infeasible |
| Excessive deformation | Length, frame or shape limit was exceeded | Inspect binding, representation and requested path |
| Work limit reached | The attempt exhausted its declared budget | Report work used; do not label the result converged |
| Cancelled / stale successor | Work was stopped or its inputs changed | Retire staged work and keep the prior complete publication |
| Output unavailable | The fitted shape cannot be delivered faithfully | Keep the existing complete result and identify the failed output path |

Failure to find a local solution is not proof that no possible three-dimensional shape exists. Reserve a proven infeasible label for a specific contradiction, such as a protected root inside a forbidden volume under the declared rules.

## Partial acceptance is a product choice

The safe default for an unaccepted attempt is to retain the previous complete result. A useful later option could publish a complete generation containing successful fits and explicitly flagged exceptions. Such an option needs a documented choice of compatible previous shape or rest shape for every failed placement. It must preserve the accepted population, label stale exceptions and allow selection of their IDs.

This is different from exposing unfinished worker buffers. A partial-acceptance policy must still publish atomically and must never silently delete plants, move roots or lower requested clearance.

## Reset, save and Undo

Reset to source removes the fit while preserving authored placements. Update starts from the declared source/rest state; use of a prior result as an optimization must preserve the declared repeatability policy. Continue simulation from current state would be a separate future operation.

Describe whether the selected mode validates only the completed static shape or also promises a collision-free path while the plant moves. Whole-segment clearance at one pose does not establish continuous clearance during deformation. The first static mode should make only the supported completion promise.

Save/load must distinguish authored preparation, current fit, stale fit and unavailable dependencies. Undo/Redo must restore the corresponding settings and completed output together, within a measured memory policy. File loading, viewport reading and rendering should consume a completed publication rather than silently solve a new arrangement.
