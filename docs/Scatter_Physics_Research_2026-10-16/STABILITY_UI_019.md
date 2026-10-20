# Physics Lab 0.1.9 — hull robustness, model removal and creation UI

18 October 2026. Independent experimental Lab; Max 2027 only. No CyrusScatter
integration, preset work, Computer Use, normal-profile installation or commits.

## Delivery and acceptance

0.1.9 is the patch successor to delivered 0.1.8: it repairs valid-geometry hull
rejections and the quality popup, adds Undoable palette removal, and corrects
creation-icon sizing. Scatter remains 0.86.0. Registration IDs, native numeric
input format 2 and saved wrapper schema 2 are unchanged. Native scene policies
gain optional `listed` membership and explicit palette ordering. Absent membership
defaults to visible, and old files retain their original ascending source order.

**Qualified standalone delivery: 0.1.9, Max 2027.** The [machine evidence](STABILITY_UI_019_EVIDENCE.json) verifies the final source hashes, exact native/script pair, payload hashes, loaded installed paths, clean exits and scene witnesses. The [testing guide](TEST_SCENE_019.md) explains the delivered scenes.

| Final evidence | Result |
| --- | --- |
| Native suites | 7 passed; captured-hull suite has 24,224 assertions, including repeated wire checks |
| Actual captured-object plane cases | 27 source/quality/scale cases, 324 assertions |
| Actual mountain workflow | 9 source/quality cases plus palette/lifecycle/icon checks, 327 assertions |
| Reused source-slot ordering | 14 enablement/quality/material/Undo/clone checks |
| Installed automatic startup | 57 continuous-workflow checks plus 22 toolbar/empty-state/failure-retention checks; real popup/rollout metrics at 100% and 150% |
| Cold scene reopening | 57 continuous baseline checks plus 31 ordering/retired-source/result-Undo/clone/ready-scene checks |
| Long fresh-schedule replays | 12, no whole-body interior tunnels; retained-palette endpoint depth about 0.793 mm |
| Accepted host exits | All 0, with 0 fatal exception notifications |

The fixed captured regression (the same 19-body inputs that exposed the discarded candidate) now measures 0.092 mm, matching the old engine. Fresh brush schedules differ with callback timing and are not bit-identical repeats.

Final artifacts: `dist/CyrusPhysicsLab-0.1.9-20261018-06/`.
Installer SHA-256: `d3d533f825f7cbee70905fdd9110283ba333066372b04f411cbde1457c734336`.
The archive has its Max 2027 guard, verified payload hashes and licenses, and contains no private probe or PDB. No normal-profile installation/restart was performed.

## Artist-visible corrections

| Action | Result |
| --- | --- |
| Open Collision quality or resize its rollout | Fast, Balanced and Detailed retain sufficient popup height |
| Click **+** | Pick a model to add |
| Highlight a row, click **x** | Unlink that model from future emission; retain scene geometry and placed bodies |
| Highlight a row, click **Replace...** | Replace that binding; explicit Rebuild applies changed geometry to saved strokes |
| Tick model checkboxes | Choose one or several models for future strokes |
| Undo/Redo Add, Remove or Replace | Restore the binding, policy, visible list and applicable material assignment |
| Clear and reuse removed slots | Reclaim unused historical prototypes instead of retaining their geometry budget |
| Create a new Lab | Default 10 scene units; small first-click marker, followed by drag sizing |

All/None/Solo are removed from the toolbar. Palette editing remains locked during
pending physics; selecting a row for inspection remains possible. An empty
palette disables Start and clears stale collision-cache information. Already
saved icon radii are retained. The Viewport radius remains stored in metres.

Geometry/quality changes affecting saved objects still require explicit Rebuild
or Clear. The message identifies the model; the UI removes MAXScript's generic
runtime-error prefix while the diagnostic log preserves the original message.

## Hull failure: evidence and correction

The artist recording `20261018-120809-331-pid51828/context-3.json` has SHA-256
`3a663c56b2f8e14ad97642a07877ec9e6c7c3ff6af2db15062bbf3ded3d2ed28`.
Its exact captured source data is retained in
`CyrusPhysicsLab/tests/fixtures/artist-hulls-018.json`; original logs and scene
were not edited. The teapot is about 14 cm across. Four of its pieces reproduce
the former fixed-1-micrometre Jolt hull rejection. Both display preparation and
the simulation worker used the same construction path, explaining both errors.
Clearing output cannot repair a failed source prototype.

The native cooker now:

1. Checks finite points, the 4–256 point bound, finite extent and volumetric rank.
2. Tries the previous cooking/rounding path and checks original double-precision
   points against its hull planes. Already valid pieces retain their previous
   representation and dynamics. A full-normalization candidate caused deep
   overlap in an extended compound replay; that candidate is not delivered.
3. Repairs a failed/out-of-envelope piece by recentering in double precision and
   normalizing its diagonal before float conversion. It attempts at most six
   tolerances per radius pass: at most two original plus twelve repair cooks.
   The point-to-hull-plane envelope is
   bounded by `min(0.25 mm, 0.1 × authored thickness, 0.001 × piece diagonal)`.
   Successful hulls are checked against that bound rather than accepting a retry
   solely because Jolt returned success.
4. For a repaired piece, restores size and pivot through the child's scale and translation.
   Render geometry is unchanged. Diagnostic wires apply the same transform.
5. Keeps the preceding size-dependent rounding policy. No box, single-hull or
   coarse-quality fallback silently replaces a Detailed compound.

Cold source preparation validates the same native shapes before creating a live
worker. A real failure identifies the model and collision piece, logs
`source.cook.error`, and retains the previous complete result. Warm unchanged
source-cache hits avoid this extra preflight. Drawing never decomposes geometry.

The envelope concerns supplied hull points and face planes; it is not a true
closest-distance accuracy guarantee for the original render mesh. Convex-radius
rounding has its separate preceding bound, and instance scale multiplies physical
errors. Normalization is a chosen Lab policy, not a vendor-prescribed recipe.

## Why the dropdown clipped

Autodesk distinguishes the creation `height:` parameter (item lines) from the
runtime `.height` property (pixels). Our generic row layout assigned the closed
row's height to the entire dropdown. Merely skipping that assignment was
insufficient: Max's width setter could shrink the popup again during real narrow
resizing. The final layout measures the native item height after width changes
and restores space for all three items plus borders.

The test queries the real ComboBox dropped-control rectangle and item height,
forces owned rollout widths, and checks capacity numerically. It does not infer
popup capacity from the collapsed rectangle or require screenshots/OS input.
The requested widths are 140/180/225 logical pixels. Max reclaims some 225-pixel
requests for its command-panel layout; those rows retain the actual observed
width rather than claiming a 225-pixel pass. Each scale covers a measured narrow
width (at most 150) and middle width (at least 175), with one-pixel scale rounding.

## Ownership, persistence and bounded work

Native source slots remain stable when a visible row is removed. A removed slot
has zero emission weight and no live model/proxy references; used historical
prototypes remain numeric snapshots for completed bodies and their rebuild
history. Existing material IDs retain their slots. Public model-option operations
map visible rows to those stable slots. A persisted order value keeps newly added
models appended in the visible list even when their physical slot reuses an
earlier hole. The cook cache ignores this presentation ordering. New bindings
reuse removed, unused slots;
otherwise they append within the 64-slot bound. Clear makes historical slots
unused, and subsequent preparation substitutes tiny placeholders for unused
retired geometry. The combined 200k source vertex/face limits still apply to
active and used historical prototypes.

Binding Undo holds bounded policy/count metadata and SDK references, not a copy
of all placements. Those references can retain source objects/material resources
until the host releases its Undo records; this is not a whole-process memory cap.
Completed result history retains its preceding shared-state ownership. Native
Save/Load and clone preserve membership and policies; the script's authored
`sourceNodes` tab shares the same host Undo operation.

Host references, publication and controls remain on Max's host thread. Numeric
decomposition retains its copied-data worker and joined lifetime. Preflight hull
work is bounded native work during explicit preparation. Physics remains on the
existing continuous worker. No new work runs per viewport redraw or unrelated
selection. F05–F11 govern these changes.

## Validation record

The maintained drivers are in [repair-019-fixtures](repair-019-fixtures/).

- Seven native suites, including the captured-hull regression, core, continuous
  worker/history, grip, collision bindings and mountain/display checks.
- The captured-hull regression witnesses four legacy failures; tests single and
  mixed worlds, 0.1×/1×/10× scale, offsets, reordered/duplicate points, thin solids,
  all teapot quality modes and explicit rejection of flat/non-finite pieces.
  Its many assertions include repeated wire-bound checks, not independent scenes.
- The flat-plane driver reconstructs the captured render meshes in an owned Max
  scene and adds a Sphere. Its 27 cases cover three sources × three qualities ×
  three source scales, with rotated/transformed meshes, continuous second strokes,
  outside misses, full-state Undo/Redo, Pause/Resume, Freeze and Clear/restart.
- The mountain driver uses a copy of the supplied original mountain and pyramid,
  plus Sphere32 and Teapot. It covers nine quality/model combinations, mixed
  checked emission, warm caches, output preservation, palette binding Undo,
  removal through the final row, re-add, unused-slot reuse, Clear on a clone,
  scene persistence, and icon-size helpers in mm/cm/m.
- Long native replay of twelve schedules (nine model cases, two palettes and
  the retained-palette regression) checks that this
  cooking change does not reintroduce interior tunnelling. This is separate from
  actual host continuation against frozen blockers. The added retained-palette
  case gates deep overlap as well as whole-body tunnelling. It reproduced about
  0.738 m penetration in the discarded full-normalization candidate; the preceding
  0.1.8 engine measured about 0.092 mm on those same inputs.
- The installed-pair driver exercises ordinary continuous brushing, the actual
  Add/Remove/Replace handlers and empty-state/history behaviour, plus popup
  geometry and seven rollout/font bounds at 100% and 150% control scale.

Intermediate failures remain in their owned profiles: a copied fixture's date
was accidentally rewritten; an old mountain stroke assumed cm while the current
profile loaded in mm; one test initially inspected asynchronous Freeze too soon;
and true-width popup checks exposed the remaining product clipping bug. A
clean-start test caught and corrected a syntax mistake in the new empty-list
branch. Installed-fixture fixes made a dynamic global declaration explicit and
set physical units for its guard object. Earlier
concurrent host runs exceeded their overall startup/test/exit bounds and are not
accepted host passes. The final combined fixture and bounded installer test retain
separate startup, fixture/reset and process-exit evidence. No history-clearing
product workaround is used to hide a physics or Undo failure.

## Limits and manual acceptance

This does not guarantee every possible mesh will cook. Invalid, nearly flat,
extreme or out-of-budget inputs still need explicit errors. V-HACD remains the
same pinned archived backend, capped at 16 pieces. The measured teapot opening
that remained filled in 0.1.8 is not fixed by numeric cooking. Inspect collision
wires for concave/hollow assets. Finish may time out; Freeze can retain transient
overlaps. Neither unrestricted dense piles nor arbitrary terrain/renderer/input
combinations are certified.

The final large-teapot Fast replay has about 29.6 mm normal proxy-vertex depth;
Balanced about 16.4 mm and Detailed about 4.0 mm. The Fast result is identical to
the preceding 0.1.8 engine on those exact inputs; it is an inherited contact limit,
not a new hull-fit accuracy claim. The frozen Fast pose has about 11.8 mm depth.
Use collision wires and Detailed for inspection; no zero-penetration or universal
settling promise is made. These geometric endpoint metrics do not replace a
physical-contact or rendered-pixel qualification.

Physical mouse/tablet feel, screen pixels, mixed-monitor DPI and presented FPS
remain artist acceptance. Creation helpers and callback source are tested/read;
there is no claim of a physical first-click/drag test without Computer Use.

## Primary references

- [Autodesk Max 2027 Dropdownlist UI Control](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/Rollout-User-Interface-Controls/Rollout-User-Interface-Controls-3/GUID-172DE6D6-796F-419B-936E-4FD64AD24CB9.html)
  — creation lines versus runtime pixel height.
- [Pinned Jolt hull settings](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/Collision/Shape/ConvexHullShape.h)
  and [constructor checks](https://github.com/jrouwe/JoltPhysics/blob/1b2e77e3c6c09709e5edc79dc208459b8ff32051/Jolt/Physics/Collision/Shape/ConvexHullShape.cpp)
  — hull tolerance, radius error and construction rejection.
- [Autodesk Max 2027 file loading](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/File-Access/3ds-Max-Scene-Files-Access/GUID-624D3D05-B15D-4A97-9F15-DA35CDB0DDD2.html)
  — the cold regression loads explicitly adopt saved file units rather than
  depending on a user's current rescale preference.
- [0.1.8 research and measured fit limits](COLLISION_QUALITY_018.md) — retained
  Houdini, compound-hull and backend investigation; its receipts remain historical.
