# Cyrus Scatter 1.0.1: Brush compatibility and Randomize resets

3 October 2026. Follow-up to the artist's v1.0.0 screenshots. The native layer-selection layout remains: choose a row in Layers, then edit that layer in the standard Max feature rollouts.

## Cause and fix

The inspected Shrubs layer had a Brush document, painted density enabled and point Relax enabled. Version 1.0.0 deliberately threw an error for that combination because its solver did not constrain movement against the painted field. The calculation guard was documented, but the native UI still allowed the combination. That was an integration defect: an ordinary checkbox could make the layer lose its preview.

Version 1.0.1 pauses point Relax and Boundary Relax while a real Brush density mask is active. It preserves their stored settings and the Brush document instead of throwing or silently rewriting the scene. The native controls show why they are unavailable; an already checked, paused setting can still be unchecked. The Layers details also show `Relax paused by Brush.` Collision and final cleanup remain supported.

Turning off **Use painted density** reactivates the stored Relax settings. A flag without a Brush document is not considered an active mask. The prepared-base key now includes effective point-Relax enablement, so switching off a mask cannot incorrectly reuse the unrelaxed base. Mask-only edits otherwise retain the existing caching behavior. Layer changes, Brush target/enablement changes and passive statistics updates synchronize control availability without rebuilding a rollout or generating geometry.

This is compatibility handling, not a new mask-constrained solver. Relax within painted density remains a separate roadmap item. Brush with unprojected movement remains explicitly unsupported.

## Native reset buttons

Randomize XYZ has four ordinary Max buttons beneath its groups:

| Button | Result |
| --- | --- |
| Reset rotation | All XYZ minimum/maximum angles become 0; the older tilt/yaw ranges also become 0 |
| Reset XYZ scale | All XYZ minimum/maximum scale multipliers become 1; the older uniform scale range also becomes 1 |
| Reset whole scale | Whole Scale minimum/maximum become 1 |
| Reset movement | All XYZ minimum/maximum offsets and the older movement range become 0 |

The buttons affect only the selected layer and their own group. They preserve Align to normal, Keep on surface, source offsets/scales, seeds, other groups, other layers and Brush history. Each click is one named Undo action, with Redo support. The existing Manual/Real-time publication policy remains. The native editor stays mounted.

## Qualification

The focused Max 2027 fixture checks exact masked rows and IDs against the Relax-off reference, stored settings/history, mask-off solver movement and base invalidation, mask restoration, collision/final-cleanup equality, unpainted Relax and layer-control binding. Twenty native editor/statistics refreshes leave placement/base-build counters unchanged.

The reset fixture checks all four groups, neutral values, older ranges, unrelated groups/layers, one Undo/Redo action, the same editor HWND and no Manual publication. The installed-package mouse campaign separately clicked each of the four actual native buttons and verified the resulting values, other groups/layers, one Undo and unchanged publication for that click. Undo can restore/reinitialize transient local cache counters; the mouse fixture takes a fresh baseline before each click, after Undo settles, instead of comparing counters across that restoration.

The five broader v1 fixtures also passed against the installed script: native selection/visibility, Brush, caching/copy, curved surface/Edit, and output/save preparation. A fresh installed process reopened a private scene with both Relax settings checked and paused: all 100 masked placements retained their fingerprint, its Brush history and settings survived, its preview error was empty, and both groups of Relax controls were restored as paused. This count includes the fixture's collision/final-cleanup settings; the earlier 354-row comparison uses its unfiltered masked reference.

The actual Max 2027 MZP installer and restarted startup were verified against package hashes. Both 2026 and 2027 packages have the current script, intact payload hashes and native binaries identical to the v1.0.0 qualification baseline. Existing Python tests passed: **62 tests in 8.15 seconds**. There was no new native compilation or native-suite run for this script/UI patch; the matching baseline passed all 11 native suites per SDK. Max 2026 application-runtime testing remains open.

The [evidence manifest](evidence/MANIFEST.json) fingerprints the sources, two local installers and curated host assertions. The [mouse result](evidence/native-reset-clicks.json), [Brush result](evidence/brush-relax-patch.json), [reopen result](evidence/patch-reopen.json) and [installation verification](evidence/installation-verified.json) record the acceptance scope. The artist's existing Max sessions were preserved; inspection was read-only and all mutations ran in separate private profiles.

Local installers: `dist/v1/CyrusScatter-1.0.1-Max2027.mzp` and `dist/v1/CyrusScatter-1.0.1-Max2026.mzp`. Run the matching MZP through **Scripting > Run Script**, then restart Max to load the new script. Existing scenes keep their Brush histories and Relax values; an active painted mask now pauses the unsupported solver instead of throwing.

## Source and reproduction

- `AminScatter/tools/ui/procedural-brush.cjs` and `templates/brush-integration.ms`: effective Relax state and the base-cache dependency.
- `AminScatter/tools/ui/native-v1.cjs` and `templates/native-layers.ms`: native availability, notices and selected-layer statistics.
- `AminScatter/tools/ui/random-reset.cjs`: the neutral group operations and native buttons.
- `tools/v1/brush_relax_reset_fixture.ms`: focused host assertions; `qualification.ms` remains the broader v1 integration suite.
- `tools/v1/random_reset_ui_fixture.ms`: prepare the native mouse test; call `CyrusPatchArmResetClick 1` immediately before the real Rotation button click and `CyrusPatchVerifyResetClick 1` afterward. Repeat with groups 2 (XYZ Scale), 3 (Whole Scale), 4 (Movement). The verification helper does not manufacture button clicks.
- `tools/v1/brush_relax_save_fixture.ms` and `brush_relax_reopen_fixture.ms`: save/reopen with preserved paused settings and matching placements/history.
- `tools/v1/collect_patch_evidence.py`: dedicated patch collection, separate from the historical v1.0.0 collector.
- `tools/build_max.py`: checks package version against the generated script instead of a fixed historical version.

Generate with `node tools/ui/generate.cjs` from `AminScatter`, package with `python tools/v1/package.py`, and use unused disposable profiles with `launch.py` / `request.py`. The v1.0.0 evidence collector and dated release evidence belong to frozen commit `c78c349`; do not overwrite them with a new patch campaign. Final installers are under ignored `dist/v1` and are outside Git.

For fresh-process patch recovery, pass the scene produced by `brush_relax_save_fixture.ms` and its `patch-reopen-expected.ms` companion to `launch.py --run <unused-name> --installed-from <verified-install-profile> --scene <private-scene> --reopen-expected <companion-file>`, then run `brush_relax_reopen_fixture.ms`. Test helpers are privileged development tools and must not run in an artist session.
