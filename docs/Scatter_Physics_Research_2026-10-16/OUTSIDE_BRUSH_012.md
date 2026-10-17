# Physics Lab 0.1.2: brushing outside the receiver

Test-only follow-up, 16 October 2026. **The brush centre can leave and re-enter
the Plane safely in the tested paths. However, an on-surface centre whose random
brush footprint crosses the edge can cancel the entire pending stroke.** Saved
results were preserved in every tested case. No feature implementation, version,
package, installer, preset or Scatter integration changed.

## What was tested

Three successful owned, hidden **Max 2027** runs exercised 11 scenarios and 113
scripted assertions against the ordinary, frozen **0.1.2** native/script pair.
The fixture invoked the actual **Start brush** button, then a private SDK driver
used viewport projection, **Painter `TestHit`** and canvas
`StartStroke`/`PaintStroke`/`EndStroke`/`CancelStroke` callbacks. This used no
Computer Use, OS mouse/keyboard events or artist-session automation. Subsequent
ticks, native error state, displayed status, saved transforms, birth recipes and
Undo were inspected. Split paths call StartStroke again through the driver;
the existing session remains active across those continuations.

The receiver was a 5,000 × 5,000 mm Plane with 4 × 4 segments at Z=0, bounded by
X/Y ±2,500 mm. The source was a normal Sphere32 with radius 32.788 mm, automatic
collision geometry and its complete 482-vertex rendered mesh. Tests used seed 42,
scale 1, 200 mm birth spacing, 100 mm emission height and 10/250 mm brush radii.
Each scenario first saved a two-body baseline. A disposable, hidden 12,000 ×
9,000 mm framing Plane kept the paths inside the Top viewport; the receiving
Plane was the only Painter target. Exact paths and hashes are in the evidence.

## Observed behavior

| Scenario | Actual result |
| --- | --- |
| Entire stroke outside, centres X=3,000–3,500 mm | All three samples missed; no births or changed saved poses. An empty gesture still committed metadata; see Undo below. |
| Leave the Plane and return elsewhere | The outside samples emitted nothing and retained two pending bodies. Returning emitted two further bodies, with no births bridging the gap. Four new bodies settled; saved count went from 2 to 6. Undo restored the exact baseline export. |
| Release the stroke outside | Three valid pending bodies from the inside segment settled and committed. Saved count went from 2 to 5. Outside samples emitted nothing. |
| Start outside, then move inside | No emission before entry; inside emission resumed and saved count went from 2 to 4. |
| Centre outside but radius overlaps the Plane | With centre X=2,600 mm and radius 250 mm, both samples missed. No bodies were emitted through the overlapping part of the brush circle. |
| First inside-centre edge approach | The approach to X=2,450 mm with radius 250 mm happened to emit only accepted points and completed: 17 new bodies, 19 saved total. This is not a guarantee for other edge strokes. |
| Extended sweep along the same edge | Reproduced the footprint failure described below; three earlier valid pending bodies disappeared and the two saved bodies remained unchanged. |
| Cancel while outside | Pending bodies cleared; the exact saved baseline remained. |
| Hold outside for 240 additional solver steps, then return | Three pending bodies remained; physics continued, with near-zero measured velocity after the hold. The stroke resumed and settled after release. |
| Hold outside beyond the stroke step budget | At the existing 3,600-step budget, the pending stroke cancelled with `Settle timeout; previous result preserved`. Saved results remained exact; a new stroke worked. |
| Undo after an entirely outside stroke | First Undo removed the empty gesture's metadata change and left the two-body baseline; second Undo removed that preceding actual brush stroke. |

Counts reflect these viewport-quantized paths, not a general spacing guarantee.
Body origins and the retained recipe were checked, rather than inferring behavior
from a successful callback return alone.

## Reproduced edge problem

With a 250 mm radius and centre 50 mm inside the Plane's right edge, the extended
path was `[2450,1000,0] → [2450,1800,0] → [2450,-1800,0]` mm, following an earlier
valid segment in the **same unreleased stroke**. A generated point missed the
receiver, and the native/UI status reported:

> Brush footprint leaves the receiver; reduce radius or move inward

The complete pending stroke was cancelled, including its three previously valid
bodies. The exported saved state stayed **identical**, including poses, birth
recipe, revision, gesture and next ID; no partial result was published. Painter
stayed active and a subsequent safe stroke succeeded, bringing saved count from
2 to 4.

Source inspection explains the difference: `Emitter::sample(hit=false)` returns
no births and disconnects the distance interpolation. In contrast,
`Document::sample` throws if any generated footprint ray misses; `PaintStroke`
catches that exception and cancels the session. This explains why moving the
centre fully outside is tolerated, while brushing close to an edge may abort.
The first edge approach's success was retained as evidence; it does not override
the extended failure. Expected boundary behavior remains a design decision for a
later fix: the test establishes the current whole-stroke cancellation.

## Additional findings

An entirely off-surface gesture advances `revision` and `gesture` and creates a
`Physics Brush stroke` Undo step even with zero births. Rows, recipes and next ID
stay unchanged. Actual Max Undo confirmed that this extra step must be consumed
before undoing the preceding populated stroke.

The existing session limit continues to count while a stroke is held outside.
At 240 steps, the three-body preview remained valid and resumed on re-entry. An
accelerated test then exceeded the normal 3,600-step budget while unreleased:
the preview was discarded, the error appeared, and saved results remained exact.
This path does **not** offer Keep preview because the stroke was not released.
The limit follows the session's solver steps; this experiment does not measure
how many wall-clock seconds an artist can hold the mouse outside. The source
applies this budget to held strokes generally, not solely to off-surface samples.

## Receipts and reproduction

- [Machine-readable evidence](OUTSIDE_BRUSH_012_EVIDENCE.json) includes settings,
  every sampled path, loaded identities, raw-file hashes, counts, status, recipes,
  before/after comparisons and preservation checks.
- `build/physics-lab-012-outside-01`: seven scenarios, **65 assertions**.
- `build/physics-lab-012-outside-03`: extended edge rejection/recovery,
  **15 assertions**.
- `build/physics-lab-012-outside-04`: held stroke, budget and empty-gesture Undo,
  **33 assertions**.
- `build/physics-lab-012-outside-02` was a **test-fixture compile failure** from a
  top-level local declaration. It exercised no brush behavior. Only that ignored
  fixture was corrected; successor run 03 passed. The failed receipt is retained.
- Exact executed fixtures are copied into
  [outside-brush-fixtures](outside-brush-fixtures/edge_cases.ms). Follow-up fixtures
  deliberately read the helper definitions captured in run 01, as they did during
  execution. The collector can recheck the retained outputs without launching Max.

The existing launcher command is:

```powershell
python CyrusPhysicsLab/tools/host_test.py --build build/physics-lab-012-delivery-20261016-01 --script build/physics-lab-012-delivery-20261016-01/source/CyrusPhysicsLab/scripts/CyrusPhysicsLab.ms --output build/physics-lab-012-outside-NEW --fixture docs/Scatter_Physics_Research_2026-10-16/outside-brush-fixtures/edge_cases.ms --timeout 300
```

Use a fresh output name for each invocation. For the two follow-ups, choose
`edge_sweep.ms` or `hold_outside.ms`; the retained run 01 helpers must still exist.
The private Painter driver is excluded from the product package.

All 45 captured project/package/profile fingerprints remained unchanged, and all
35 project source entries still match the frozen build receipt. The original MZP
SHA-256 remains
`81b97157e364ea44fa11d58dc595d024014836e972f96faed966ad094714acae`.
The normal Max INI, plugin registration and startup file were preserved. Owned
test processes exited. No build, installation, artist-session restart, commit or
push was performed. The knowledge index was stale and did not enroll Physics
Lab; current/frozen source inspection and loaded binary hashes were used instead.
Concurrent main Scatter/preset working-tree edits appeared during the final audit;
they were preserved and excluded from this standalone test. The lab's captured
source/package/profile files remained unchanged.

Limits: no physical mouse/tablet feel, arbitrary curved/concave receivers, holes,
other asset types, production-scale scenes or motion of bodies beyond the edge
was qualified. The observed edge cancellation and empty Undo entry remain in
0.1.2; this task deliberately made no implementation change.
