# Physics Lab 0.1.1 — brush and panel correction

16 October 2026. User-reported 0.1.0 clipping/confusing layout and nonworking
brush. Scope is Physics Lab only; the user withdrew the accidental preset-library
request. No Computer Use, artist-profile install or main-plugin integration.
Branch `codex/workflow-0.75`, initial HEAD
`4eed74777e23c4c1c1a6490c80e2e09ded436d37`. Existing `docs/README.md` modification and
unrelated untracked assets are preserved. Knowledge status/search remains stale;
direct current source and SDK inspection is used.

Version: independent lab 0.1.0 -> 0.1.1, a corrective successor for artist-visible
layout and brush contact. Registration IDs and saved parameter order are retained.
No Scatter/preset/library version or source change belongs to this task. Historical
0.1.0 receipts/installers remain unchanged.

Acceptance: responsive native rollouts with readable captions at narrow command
panel widths, visible prerequisites/errors and correctly bound controls; actual
Start/Stop handlers and real timers; SDK Painter TestHit/Start/Paint/End/Cancel;
complete settled result and append/Undo; failed work retains the last result;
scene roundtrip and exact-pair Max 2027 MZP. Physical input remains untested under
the user's restriction and must not be inferred from callback tests.

Baseline `build/physics-lab-ui-baseline-011-01` used the delivered ordinary 0.1.0
pair with the actual Modify panel, Start button and timer, and a private SDK probe.
Painter stayed active and hit all three path points; the pyramid-on-plane stroke
did not complete. Diagnostic successor `...-02` used the fingerprinted private
0.1.0 pair: two of eleven pyramids fell through the open plane to about -1200 m;
the session timed out, retained the prior result, and left its error below the
visible controls. This reproduces a concrete brush failure; it does not prove
every cause of the user's original scene failure. The old tests had not covered
this actual-button/Painter/general-shape path.

Correction: narrow-width native layout in separate Objects, Brush, Collision,
Area and Result rollouts, with primary actions/status at the top and advanced
sections collapsed. Disable Start until receiver/models are bound. Certify filled
horizontal rectangular planes before using finite boxes below the
exact surface, alongside the existing verified solid-box representation. Do not
fill arbitrary meshes or holes; uncertified geometry keeps triangle contact.
Record the corrected solve profile separately from old retained results.

The numerical regression now covers rectangle certification, holes, an equal-area
duplicate/hole case, inconsistent winding, nonplanar rejection, and pyramid contact
in both engines. Other collider representations remain experimental. The new
profile is `cpl-leaf-2`; old retained results keep `cpl-leaf-1` until explicit new
authoring/rebuild. Scene schema and scripted parameter order stay unchanged.

UI iterations found a separate MAXScript issue: a rollout helper invoked without
its scripted-plugin context cannot access plugin locals. Rollouts now capture an
explicit model owner and call its methods. Button/timer callbacks retain that owner
across native operations that may rebuild the panel. Native idle cancellation no
longer sends redundant geometry notifications; teardown cancels without publishing
preview changes, while pre-save/render still remove pending previews visibly.

Native bounds inspection exposed unsupported dynamic width properties on Picker
controls and the spinner's arrow-based position convention. The lab now follows
the existing Scatter layout technique: resize picker HWNDs, anchor spinner arrows
at the right and size their edit fields independently. It does not load or depend
on Scatter's native/UI modules. Unchanged UI visibility/enabled values are not
rewritten on every status tick, and the brush header has a stable height.

The owned-host harness temporarily silences Max's reset dialogs, restores normal
flags before the actual workflow, and can launch with quiet startup. Earlier
timeouts and failed layout images are preserved under `build/physics-lab-ui-011-*`.
Run 12 successfully committed a settled pyramid stroke; its count assertion was
too rigid for screen-pixel quantization (10 instead of the direct-coordinate 11).
Run 15 passed 74 button/timer/SDK-hit/geometry/cancel/append/Undo checks. Neither is
automatically relabeled as qualification of subsequent UI source.

Final current-source receipts and visual/bounds outcomes are recorded below.
These records do not establish physical
mouse/tablet feel or actual mixed-monitor DPI acceptance.

Later layout checks detected a naming collision between the first rollout named
`controls` and the rollout's built-in `controls` array: its child enumeration was
empty while individually named controls could still be called. Renamed the page
`brushHeader` and removed an unused automatic parameter/UI association; parameter
names, types and order are unchanged. Every page now has measured children. Run
24 exposed the narrow Start caption; run 25 passed the then-current 150% layout.
Those intermediate runs do not qualify the final successor.

At 150% custom-control scale the owned profile retained a 162-pixel command-panel
body, leaving only 108 logical pixels. Labels/fields and paired actions now stack
at small widths; rollout heights account for Max's scaling convention. Start has
more width than Stop in the 162-logical-pixel layout. Six sections retain native
Max controls and spacing, following the current Scatter approach without loading
its modules. The test measures every visible native child, horizontal/vertical
caption fit and intersections between different controls; it renders only owned
rollout HWNDs with `captureScreenPixels:false`. It collapses the other sections
before each capture so offscreen child rendering does not masquerade as a preview.

Autodesk's [rollout property documentation](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-DC435555-362D-4A03-BCF2-21179C5442F2.html)
describes the built-in `controls` array; its [scripted-plugin clauses](https://help.autodesk.com/cloudhelp/2021/ENU/3DSMax-MAXScript/files/GUID-461915FA-31A2-49CE-84AF-2544B782ACA3.htm)
describe automatic parameter/UI association. The actual failure and correction
are local runtime observations, not claims inferred from those documents.

The first frozen 0.1.1 candidate (`build/physics-lab-011-delivery-20261016`) passed
the full 100% host regression in `build/physics-lab-011-final-01`. Its 150% run
(`...-final-02`) passed all six sections/60 native child rectangles, glyph metrics
and overlap checks, and the first 11-body stroke, but a three-pyramid append did
not settle. Private diagnostic `build/physics-lab-011-diagnostic-02` reproduced
it: body 12 fell to -1226 m, while bodies 13/14 rested at zero. This was a contact
failure, not just slow pile motion. A separate 10-birth variant passed; it did
not invalidate the 11-birth failure.

Captured input, frozen blockers and the three births are now
`CyrusPhysicsLab/tests/fixtures/pyramid_append_plane.json`. The unchanged 1 cm
slab failed this exact case offline (`build/physics-lab-011-append-baseline`),
independent of UI scale. Increasing the certified ground slab to **10 cm below
the same exact top surface** passed it in both Jolt and PhysX. This does not add
volume to general meshes or holes. The final numerical successor passes 2,481
checks. The profile remains `cpl-leaf-2`, which has not previously been delivered.
The old 0.1.0 profile and frozen historical receipts are unchanged.

The final native message names the actual Keep preview/Stop buttons. A deliberate
step-limit fixture exercises their real rollout handlers, disabled pending inputs,
retained completed rows, explicit unfinished acceptance and Undo. Final validation
uses the ordinary frozen pair in `build/physics-lab-011-delivery-20261016-03`.

## Final 0.1.1 qualification

The timeout fixture initially queried a collapsed header and compared its raw
wrapped text. Runs `...-final-03/04` were rejected by that test. The final fixtures
explicitly open the real header before interacting, normalize line breaks for
the action-name assertion and restore the normal three-open-section layout after
bounds inspection. These are fixture corrections; failed receipts are preserved.

- `build/physics-lab-011-final-05`: full ordinary-pair Max 2027 regression passed.
  Includes six-section native bounds/caption/overlap checks at 100% (162 logical
  pixels), 78 actual-button/timer/SDK-hit checks, deliberate timeout recovery,
  basic and extended authoring, clone, append/Undo, erase/rebuild, centimetres and
  transformed inputs, save/reopen, the unchanged 60-body 0.1.0 cached scene with
  profile 1, and a newly solved/rendered 60-leaf demo.
- `build/physics-lab-011-final-06`: 150% custom-control scale passed all six
  sections/60 measured native children at 108 logical pixels, timeout recovery
  and 78 button/timer/SDK-hit checks including append/Undo. No clipping or
  intersections between different controls were reported in either layout.
- `build/physics-lab-011-timeout-native-01`: supplemental ordinary-pair timeout
  test passed native HWND visible/enabled style checks after processing posted
  messages. Its direct owned-control render shows Keep preview and Stop. Earlier
  immediate prints could omit queued visibility/paint updates; they are not the
  accepted visual evidence.
- `build/physics-lab-011-faults-02`: fingerprinted private build passed injected
  pre-commit/post-assignment failures, timeout retention, explicit unfinished
  acceptance and JSON roundtrip. Packaging that private build was rejected before
  output creation. Only the ordinary frozen pair is in the installer.

Ordinary build receipt SHA-256:
`97db5ec53a83e01cf0edf9ebe60847f183013fef763d4344f534b3c886733e9e`.
Qualified script SHA-256:
`29a442b91f3e521684a28b7c85c7c589ddb3ab703d859c5b986e37a15af1c981`.
Native module hashes, fixture hashes, owned renders and installation receipts are
in [BRUSH_UI_011_EVIDENCE.json](BRUSH_UI_011_EVIDENCE.json).

One delivery package:
`dist/CyrusPhysicsLab-0.1.1-20261016/CyrusPhysicsLab-0.1.1-Max2027.mzp`
(652,682 bytes), SHA-256
`7b2c5c0aec38d121332df67e2a15f049023d88200f3c10eb8dd94c14c6915f13`.
The archive has the exact qualified native/script pair, host/version guards and
verified payload hashes. It excludes the Painter probe and private fault commands.

The first isolated installer run completed automatic loading and the brush test,
but its normal-profile equality guard failed. A different normal Max process
appeared during the run; the normal INI subsequently matched the run's initial
template hash. This is an observed concurrency event, not proof of its cause.
That run is not accepted as an isolation pass. The complete installer test passed
in fresh owned profile `build/physics-lab-011-installed-02`: payload hash checks,
isolated registration, automatic class loading after restart, installed native
pair identity and 78 button/timer/SDK-hit checks. The normal INI, plugin registration
and lab startup script match separately captured before/after fingerprints. All
owned Physics Lab Max sessions have exited. The artist session was not controlled.

Source remains separate from Scatter. Current-task edits are confined to
`CyrusPhysicsLab/` and this research folder. Concurrent main/preset work changed
HEAD during the task; it was neither reverted nor included in this lab package.
No artist installation/restart, Computer Use, commit, push or main integration was
performed by this task.

Use **Scripting > Run Script** for the supplied MZP, save work and restart **Max
2027**, then create **Geometry > Cyrus Labs > Cyrus Physics Lab**. Open Objects,
pick a receiver, add models and press Start brush. Keep this package with test
scenes. Physical mouse/tablet feel, real Windows/mixed-monitor DPI, general thin
mesh contact and production pile/performance acceptance remain open.
