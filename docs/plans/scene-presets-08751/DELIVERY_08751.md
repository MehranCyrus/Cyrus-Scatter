# Scene presets — 0.87.5.1

The Library now offers **Scene preset**, **Portable preset** and **Settings only**.
Scene presets use Max's native serialization to save a complete Scatter setup,
including editable models, preparation, Paint, controllers and instance edits.
Loading adds an independent setup in its saved arrangement. Existing portable
recipes remain available for adapting supported static planting to another terrain.

## Install and use

[Download the Max 2027 MZP](../../../dist/CyrusScatter-0.87.5.1-20261027/CyrusScatter-0.87.5.1-Max2027.mzp).
Run it through **Scripting > Run Script**, then restart Max. Install the complete
matched package. No artist profile was installed or restarted during development.

Open **Layers > Recipes > Save**, choose **Scene preset** and save. The card
appears in **My recipes**. **Load > Merge** restores a separate setup. As the
load dialog states, standard Max merge clears Undo history. This is the user's
selected behavior; the portable import retains its existing transaction.
See the short [artist guide](ARTIST_GUIDE.md).

## Executed checks

The final package was installed in an owned disposable profile and its loaded
native modules and script identity checked against the package. Max 2027 checks
on that exact pair passed for:

- Grass and Brainea Insignis fern setups, prepared interactions and matching
  canonical placement transforms after restore; maximum compared error 0 WU.
- Two authored Edit modifiers with move/delete/clone history and clone-targeted
  radius values, plus independent repeated imports. This case uses interactions off.
- Native Paint bytes and its independent imported receiver, pending Manual
  settings, original placements and original material paths retained by Save.
- Collected texture loading with its owned original unavailable, parent hierarchy,
  a two-key animation controller, save/reopen and transferred Library content.
- Real Save/Load rollouts and the save action, scene-card listing, mismatched-unit
  rejection, missing-file failure, cancelled staging cleanup and a static portable
  format-9 import.

Metadata revisions with attachment reuse and `.cyruslib` export/import passed
in the earlier owned development host using the same managed implementation.
The final exact pair independently restored content from that transferred store.
These earlier checks are explicitly separated in the [qualification record](QUALIFICATION_08751.json).
Physical viewport/button input was not qualified after Computer Use reported
manual input/capture issues; the actual rollouts were exercised through Max.

All **61 native test executables** passed. Generated-source validation and five
focused Python recipe/host-version tests passed. Archive CRC, every manifest
payload hash, version/host guards and the owned installer run passed.

## Identity and limits

| Item | Value |
| --- | --- |
| Scatter / managed version | 0.87.5.1 / 0.87.5.1 |
| Scene preset metadata | 1 |
| Existing contracts retained | Interactions 12, scene 63, portable recipe 9, Edit/storage 3 |
| MZP bytes | 2,627,863 |
| MZP SHA-256 | `d220e943c7bac04cc8f7dd98bd8e8e32dca1ca8486085c441b34b2f38d8fbbb6` |
| Generated script SHA-256 | `fab1e19e80459537710c6ad8f033c0f33cc6a024865db495d3768a0ef0ad780a` |
| AminScatter.dlx SHA-256 | `29c0358096b4ff772a3aa2abe57e4125ba3582af8bd4d2001e1c6bfd39b61c04` |

This delivery is **Max 2027 only**. Scene presets require matching system units
and the object/material plug-ins used by their saved content. Files declared by
Max are collected; unresolved files, nested external scenes and unresolved
sequence patterns are rejected. Plug-in installations and licenses are not bundled.
Destination render, environment and colour settings follow ordinary Max merge.

Plant interactions retain their existing one-Edit-per-controller limit. Arbitrary
third-party graphs, production renderer frames and other colour configurations
remain unqualified. Original-file unavailability was tested on an owned PNG;
the vendor asset tree was preserved. A large fern preparation exceeded the
existing portable authored-text bound; the native Scene preset saved/restored it.

The final native producer receipt, generated check, package identity, installer
receipt and host results are under
`build/scene-presets-08751-20261027-01/`. The qualification record seals their
identities and executed scope. Earlier deliveries retain their original evidence.
Next acceptance is the artist's real-library save/merge workflow with their own
materials, edits and destination scenes. No older-host build, EXE, Git push or
website publication is part of this delivery.
