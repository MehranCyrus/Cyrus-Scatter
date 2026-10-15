# 0.82.4 mesh channel density and Paint help

15 October 2026. User-authorized implementation, isolated Max 2027 testing and
runnable installer; no normal-profile installation. Phase 6 remains paused.

## Version and scope

0.82.3 is the preceding delivered package. The user explicitly selected 0.82.4
for a layer-owned mesh-channel density mask and the reviewed Paint tooltips.
This consumes the next small version step: planned P06-P11 labels become
0.82.5 through 0.83.0. Schema 58 gains neutral saved settings; registration
identities, Analyzer 0.14 and MCP package 0.73.0 remain separate.

Baseline HEAD `604e3aa3fd1c84c5ef128dc564f4abaf6f4978e4`, branch
`codex/workflow-0.75`. Pre-existing work is preserved in
`build/mesh-mask-0824-20261015-01/baseline/`. The knowledge corpus reports stale
sources; current source and contracts F01/F02/F04-F11 are authoritative here.

## Implementation contract and TODO

- [x] Add direct selected mesh-channel sampling: channel 0 vertex colors and
  channels 1..99, selectable X/R, Y/G or Z/B component, explicit ordered input
  range, invert and a 0..1 density response curve. Max's Data Channel and
  VertexPaint produce the values; viewport display gradients are not inputs.
- [x] Interpolate map-face corners at each moved/reprojected candidate anchor;
  apply stable eligibility before Edit, independent of texture/transform random
  streams. All active layout types and Paint coverage compose without reordering
  layer or Band ownership. Disabled masks preserve the preceding calculation.
- [x] Keep selected channel data keys separate from Edit geometry bindings.
  Bound snapshot/preview work, validate all indexed reads, preserve previous
  complete output after missing/invalid-channel failure. Manual waits for Update;
  Live observes relevant channel/modifier/animation changes, never idle browsing.
- [x] Expose owner-bound controls and an explicitly requested bounded grayscale
  mask preview. Preview uses copied cached values; drawing does not sample Max.
- [x] Add the reviewed short tooltips to Paint controls; preserve richer existing
  conversion instructions and clarify independent density and scale fading.
- [x] Run analytic native checks, generated checks, focused/full Python tests,
  isolated Max 2027 channel/curvature/VertexPaint, lifecycle, failure, Manual/Live,
  Paint/Bands/texture/Relax/Edit and idle/performance checks.
- [x] Align guides/catalog/website/version navigation, record exact evidence and
  limitations, then package the exact qualified pair as a Max 2027 MZP.

The installer will be delivered for the user to run. No Git push, deployment,
normal-host restart or Max 2026 work is included.

## Delivered behavior and source owners

**Amount > Mesh channel density** exposes Use mesh channel mask, channel,
component, input min/max, Invert, Density curve, Preview mask and Hide preview.
Defaults are disabled, channel 0, R/X, range 0..1 and a linear response. All
receivers assigned to the enabled layer must contain its selected channel.
The new graph owns saved handles and samples independently of selection; named
presets for this graph are not implemented. Existing preset categories retain
their behavior.

The native reader copies evaluated map-face corner values on the host thread.
It interpolates the selected scalar at the moved/reprojected anchor, remaps and
clamps it, applies Invert, then the response curve. A separate deterministic
random channel thins candidates. Source choice, transform and identity of
survivors remain unchanged in the tested scenarios. The filter runs after
candidate movement/final Relax and before Analyzer falloff, Paint and Edit.
Ordinary masked base edits become dormant; existing explicit protected-edit
replay semantics are unchanged. Nonzero movement requires Keep on surface.

Selected channel keys participate in receiver candidate caching separately from
the geometry keys used by Edit. Relevant edits invalidate only affected receiver
work when possible. Manual waits for Update; Live follows relevant channel,
modifier and animation notifications. A failed successor retains the prior
complete publication. Preview is explicitly requested, clears on relevant
events and draws only cached grayscale face-centre markers. It does not evaluate
Max data during redraw and does not represent the combined final mask.

Native limits: 2,000,000 evaluated faces per receiver, the existing
1,000,000-candidate controller budget, 2..257 curve samples and at most 2,048
preview markers across the layer. Missing/incomplete channels, invalid selected
values, invalid anchors and input ranges report errors. VData, selection,
negative map channels and automatic curvature generation are outside this scope.
Data Channel/VertexPaint remain Max's producers; the rainbow display gradient
does not determine the numeric mask.

Source map:

- `AminScatter/include/mesh_density.h`, `src/mesh_density.cpp` and
  `src/mesh_density_bridge.inc`: scalar interpolation/remapping, independent
  eligibility, validated SDK copies, keys, preview and counters.
- `tools/ui/templates/unified-core.ms` and `approved-layout-rows.cjs`: saved
  ownership, cache integration, curve/Amount controls, sparse feedback and Paint
  tooltips; generated script and inventories are reproducible.
- `tools/mesh_density_mask/`: owned-host qualification and diagnostic fixtures.
  `CyrusMCP` catalog describes the new local controls; public write schema 0.73
  is unchanged. Inventory: 280 controls, 36 capability families.

## Exact qualification

The full Max 2027 SDK build and 32 native suites passed in
`build/mesh-mask-0824-20261015-01/native-01`. That first script candidate exposed
an invalid floatTab default at host startup. The authoritative template was
fixed to use an empty neutral table and explicit instance callback dispatch.
`script-02` passed functional tests. Final `script-03` only shortens the checkbox
caption and uses the actual layer caption in the graph title. Each staging step
verifies every compiled input is unchanged before reusing native binaries.
The final receipt freezes **119 build inputs** plus generator/packager sources.

Final generated script file SHA-256:
`a911b47f1c3f1c47fbad81e76a5fea1c3b5f6633850b39b0aa3d5c388a698b30`.
Loaded payload fingerprint:
`2d8bae08fe70002044d7338d896dee6bd042e903bf79931e054559983d6910ea`.

| Native file | SHA-256 |
| --- | --- |
| AminScatter.dlx | `9037037df0af455f5b0af812db546e9d8b20fef8fb12748c98d8e4477dc94bdc` |
| CyrusBrush.dlx | `8d8190bbc19d2587e702a8bcb5a56ada928d9b6cfb3b69a19b436df46d67f13f` |
| CyrusBrushStorage.dlh | `1e777f40f7764815dc8cf7df70c7c4fd4caadc0b98ed14ad139fc5d2ce70c4f8` |
| CyrusScatterEdit.dlm | `a6082dbbf9cb49f2dbe80eaed2a3f0c62e3f3164cf916c91f559de00b33db8a1` |

Owned Max 2027 hosts:
`foundation-roadmap-meshmask-0824-20261015-02` and
`foundation-roadmap-p05-meshmask0824-20261015-01`. Launch/module receipts and
verified script-successor receipts retain the original inputs rather than
rewriting launch history. Final runtime identity checks match script-03 and the
four native hashes. The failed initial host receipt is preserved separately.

Passed checks:

- **32 native suites**, including analytic mesh interpolation, range/invert,
  nonlinear curves, stable eligibility and invalid scalar settings.
- **161 Python tests** and final generated/catalog integration with 280 controls.
- **467 inherited P01-P05 host assertions** on script-02. Only the two captions
  changed afterward; final controls and all new witnesses below ran on script-03.
- **171 new host assertions** across named receipts: channels 0/2/99, R/G/B,
  independent probability and transform/identity preservation, actual map seams,
  Paint/texture/slope/altitude/Bands/Relax composition, bounded refill, missing
  channels, Manual/Live, real Data Channel animation, Edit dormancy, Undo/Redo,
  copy, current-schema save/reopen, owner capture and native curve/preview controls.
- Real Curvature -> Vertex Output channel 7 and channel 0 workflows; display
  colors/normalization do not affect numeric keys. VertexPaint above Data Channel
  preserves the output. This is a modifier-stack/pass-through witness, **not a
  physical VertexPaint brush-stroke qualification**.
- Final Amount layout and marker display were visually observed in the owned
  mountain. Actual curve handlers passed Apply/reopen and owner-switch tests.
  An occluded final popup capture returned an unrelated foreground image and was
  rejected; it is not evidence of a final physical graph gesture.

Consolidated hash-pinned evidence:
`build/mesh-mask-0824-20261015-01/final-receipt.json`.
Receipts list exact assertions and preserve failed fixture iterations. The
malformed map-face test proves Max rejects the setter before data enters this
plugin; it does not claim execution of the native invalid-index branch. Fixture
corrections also cover an auto-created test channel, staged observer resets,
serialized candidate IDs, explicit Update for same-event map edits and MaxScript
64-bit operator IDs. The generated check was rerun successfully after catalog
regeneration; its earlier stale-catalog failure is retained.

## Mountain and performance witnesses

Original `Test Scene/Mountain Scene Test.max`: **2,818,048 bytes**, SHA-256
`d5a610d5a6913ffebc59577683155d31e38473f640df254c6e309c64fd4686a1`.
Only a hash-verified copy under the campaign's `mountain/` folder was loaded.
The original and owned source copy were rehashed unchanged. Working results were
saved to a different `Mountain Scene Test - qualified 0824.max` path.

The existing Cyrus setup uses **20,000 candidates**, `Pyramid001` and the
20,000-face `Plane001` receiver. Its two Data Channel modifiers output Curvature
to channel 2 (approximately -0.3413..2.1777) and channel 3 (-1.6217..1.7172), both
X. With range 0..1, channel 2 accepts **3,746**, channel 3 **7,424**; channel 3
inverted accepts **12,391**. Counts agree with an independent Python
interpolation/probability check. Exactly-zero weights exclude and exactly-one
weights retain candidates. Surviving full matrices, sources, anchors and IDs
match the unmasked publication. Modifier edits, restoring either channel,
Paint composition and reopening the owned scene preserve expected results.
The two Forest comparison objects were hidden only in the copy for the viewport
witness. Its original Cyrus model source was retained.

Measured explicit solve wall times in this owned scene were approximately
121-312 ms, including the named mask/range/Paint cases. A separate stress scene
uses 200,000 candidates and 180,200 faces across two receivers: disabled mask
2,501 ms, enabled ramp 2,631 ms, and editing only the smaller receiver's channel
581 ms while reusing the other receiver's candidates. These are scoped wall
times, not presented FPS or guarantees for arbitrary scenes.

Five-second idle windows in **both** the stress scene and the mountain preserve
epoch, evaluations, preparation, preview and input-time counters, perform **zero
new channel reads/filter queries**, and retain native buffer/upload fields.
Separate unrelated-animation and panel-browsing windows also preserve work.
Relevant heavy changes still calculate on demand. This does not close existing
cold-panel, long-session, renderer, tablet or broad DPI acceptance gates.

## Runnable package and artist checks

[CyrusScatter-0.82.4-Max2027.mzp](../../../dist/CyrusScatter-0.82.4-20261015/CyrusScatter-0.82.4-Max2027.mzp),
**904,013 bytes**. Archive SHA-256:
`62c205d0646518a2fc9c99e1788b1163261530341253168d660303bf43497966`.
Native directory: `bin-max2027-b4ac3537ae97`.

The package matches the qualified script/native pair. ZIP integrity, exact file
membership, every payload hash, host/version guards, expanded tokens, team trust
and runnable MZP entry point passed. Reproduction/receipt:
`build/mesh-mask-0824-20261015-01/package_verified.py` and `package.json`.
Verification did not execute the installer.

1. In Max 2027, save work, choose **Scripting > Run Script**, select the MZP, then
   restart Max to load the complete matching pair.
2. Open a **copy** of the mountain with its saved system units. Select the Cyrus
   layer. In **Amount**, enable **Use mesh channel mask**, select channel **2**
   or **3**, component **R/X**, input range **0..1** and a linear Density curve.
   In Manual, press **Update scatter**. Compare the two channels and Invert.
3. Press **Preview mask** and inspect the sparse grayscale markers. Edit the
   Curvature operator and refresh the preview. Check that Manual plants wait for
   Update, while Live follows the change. Then leave the scene idle and browse
   panels to assess responsiveness on your machine.
4. Hover over Paint controls, particularly Fade density, Fade scale, Inside/
   Outside fade and Edge/Inner scale. Check that density and size are independent.
   Try Paint composition, Undo/Redo and save/reopen on the copy. The preceding
   [first-five-phase checklist](ARTIST_ACCEPTANCE_0822.md) still applies.

Documentation/catalog and local website sources/build were updated; nothing was
published. No installer execution, normal-profile restart, Git commit/push,
Max 2026 work or Phase 6 implementation was performed.
