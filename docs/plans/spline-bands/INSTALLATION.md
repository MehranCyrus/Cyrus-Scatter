# Scatter local installations

## Latest: Band selection and scale layout, 0.81.2, 13 October 2026

**0.81.2 is packaged and installed on disk for Max 2026 and 2027.**
Save work and restart Max to load it. Open artist sessions were preserved.

Scale Min/Max, profile and graph controls sit directly below the density curve.
Click a model, Point or assignment group again to remove it, including the last
selection. Empty Bands keep their intervals. Manual applies changes on Update.

Saved schema 58 and native Band interface 9 are unchanged. Previous 0.81.1
schema-58 scenes reopen in both tested hosts. Earlier schemas still require their
matching build. Analyzer and licensing are unchanged.

- [Max 2026 MZP](../../../dist/CyrusScatter-0.81.2-20261013/CyrusScatter-0.81.2-Max2026.mzp)
  - SHA256 `d1b52b487f181ec3011e24a6b486b47a77634c298039c66dbc547af78adc416b`
- [Max 2027 MZP](../../../dist/CyrusScatter-0.81.2-20261013/CyrusScatter-0.81.2-Max2027.mzp)
  - SHA256 `de99d4e0d5f84666470312ce1cc3e6c07176c95eb362c961f149b4743696fe9b`

Script SHA256: `c4a60a37c09a4aff8daafb465a53c199ff5fb3bbdbb5abe020092b6f78f35c41`.

[Delivery receipt](../../../build/band-ui-0.81.2-20261013-01/installation.json)
records verified installed hashes, package/source identities and backups under
`backup/Max2026` and `backup/Max2027`. Previous native directories, normal Max
settings and Analyzer files were preserved; only owned Scatter registration
values changed. Installation used verified payloads without running the interactive
installer dialog or restarting an artist session.

[Validation](PROGRESS.md) includes both Modify views, empty assignments, Manual
retention, Undo/Redo, persistence and scale regressions. Physical pointer/DPI and
fresh normal-profile acceptance remain pending.

## Earlier: Band scale profiles, 0.81.1, 13 October 2026

**Scatter 0.81.1 is packaged and installed on disk for Max 2026 and 2027.**
Save work and restart each Max session to load the matched script/native pair.
Artist processes were preserved. Fresh normal-profile acceptance remains pending.

In Spline bands, select a Band and open **Advanced > Scale**. Choose **Custom**
and **Edit scale curve** for an independent size graph, or **Follow Density** to
reuse the effective density curve shape. **Off** preserves the existing Min/Max
size range. Manual mode applies changes on **Update scatter**.

**Saved schema 58 is current-only.** Create a fresh setup; preserve schema-57
scenes with their original 0.81.0 installer. Native Band interface 9 requires the
matched script. Analyzer and existing licensing are unchanged.

- [Max 2026 MZP](../../../dist/CyrusScatter-0.81.1-20261013/CyrusScatter-0.81.1-Max2026.mzp)
  - SHA256 `8a289baf91ce6248bba54ff58ed108afe26d095489d3fd3b1305cd394007352f`
- [Max 2027 MZP](../../../dist/CyrusScatter-0.81.1-20261013/CyrusScatter-0.81.1-Max2027.mzp)
  - SHA256 `7d95664eb6be6a09941828f303933d595580521ecb7f57a1dbf759d0caf7122a`

Script SHA256:
`88d573ae37d7f007718dcd928e95733bc91e60eaa3dca6992186a83d791e42e3`.

[Delivery receipt](../../../build/band-scale-0.81.1-20261013-01/installation.json)
pins the packages, tested SDK binaries/script, installed files and prior registrations.
Backups are under `build/band-scale-0.81.1-20261013-01/backup/Max2026` and `Max2027`.
All installed hashes were verified. Only the owned Scatter registration value
changed in each plugin INI; normal Max settings, Analyzer files and previous native
directories were preserved. Installation used verified MZP payloads; the interactive
installer dialog was not executed in an artist session.

[Validation](PROGRESS.md) includes both-host graph, scale/radius, Manual/Live,
Undo/Redo and persistence checks. Physical artist interaction, DPI variations,
renderer and heavy-scene acceptance remain separate.

## Earlier: Modify-only workflow, 0.81.0, 13 October 2026

**Scatter 0.81.0 is packaged and installed on disk for Max 2026 and 2027.**
Save your work and restart Max to load the matched script/native pair. Open artist
sessions were left running; fresh normal-profile launch acceptance is pending.

This delivery removes the floating layer editor and Go to assigned Band, adds
Pick object / Make point, and reorganizes Band source assignments and scale
controls. Schema 57 is unchanged. Analyzer and existing licensing are unchanged.

- [Max 2026 MZP](../../../dist/CyrusScatter-0.81.0-20261013/CyrusScatter-0.81.0-Max2026.mzp)
  — SHA256 `f36857df7eefe2ac608ddb00ba564974ea50dc1c7fcfdb939c60a86176360756`
- [Max 2027 MZP](../../../dist/CyrusScatter-0.81.0-20261013/CyrusScatter-0.81.0-Max2027.mzp)
  — SHA256 `dd56e60baee51da52af8c4dc20a5a45a8877e137b62f1f3429435f15fc68ed3d`

Script SHA256: `650482e1e1c9d8f6113fc7384dd40608e38bf773ebfa773d83b43e26b517f859`.
The exact native binaries and final script match the preceding automated Max
2026/2027 qualification. Compiled-source and binary hashes were rechecked; native
compilation and host scenarios were not repeated for unchanged inputs. Fresh
generated consistency and eight packaging/version tests passed. Installer help
now describes the Modify-only workflow.

[Installation and package receipt](../../../build/scatter-0.81.0-delivery-20261013-01/installation.json)
records every installed hash, prior native registration, backups and unchanged
normal settings/Analyzer files. Backup folders are
`build/scatter-0.81.0-delivery-20261013-01/backup/Max2026` and `Max2027`.
Only the owned Scatter registration value changed in each plugin INI; other
configuration bytes and previous native directories were preserved. Packages were
installed from verified payloads; the interactive MZP dialog was not executed.

The [implementation evidence](PROGRESS.md) retains physical interaction, DPI,
renderer and heavy-scene performance limits. Hash verification is not runtime
acceptance in the artist's profile.

## Earlier: first-click and panel cleanup, 13 October 2026

Clusters/Spline first-selection and verbose panel text are corrected and installed
for Max 2026 and 2027. **Restart Max to load this script.** The version is still
0.80.0; distinguish the delivery by its hashes and folder.

- [Max 2026 MZP](../../../dist/spline-bands-0.80.0-panel-fix-20261013/CyrusScatter-0.80.0-Max2026.mzp)
  — SHA256 `28e038c480c2e4d6304abe1b2e709580972f94ac3b1f7052877e686514920c1d`
- [Max 2027 MZP](../../../dist/spline-bands-0.80.0-panel-fix-20261013/CyrusScatter-0.80.0-Max2027.mzp)
  — SHA256 `bf096870c8a5c9eba0b6061f2b4ba099b58213d66d9dc8d4112cfd035e49159e`

Script SHA256 `19b9612cb63939078e9f871a47e0d2db148ba108f42cdec284b56b070583ceff`. Native binaries and registration are unchanged.
Both years passed 55 visibility/remount and 51 hover/cache assertions. The
[comparison report](UI_REVIEW_20261013.md) records physical first-click checks,
faster warm UI paths and the remaining changed-calculation slowdown versus 0.79.5.

[Installation receipt](../../../build/ui-first-click-review-20261013-01/installation.json)
and prior-file backups: `build/ui-first-click-review-20261013-01/backup/Max2026`
and `Max2027`. All installed paths were rehashed. Normal artist processes/scenes,
normal profile configuration and prior packages remain preserved.


## Earlier: UI refresh correction, 13 October 2026

The Models & Points hover and Layout switching correction is installed and
hash-verified for **both Max 2026 and Max 2027**. Restart each normal Max session
to load the corrected script. Running artist sessions and scenes were not changed.
The version remains 0.80.0; use these package identities to distinguish this fix
from the earlier delivery below.

- [Max 2026 corrected MZP](../../../dist/spline-bands-0.80.0-ui-refresh-20261013/CyrusScatter-0.80.0-Max2026.mzp)
  — SHA256 `bcc8228d51a9f439e72e8c5932be208910f296b29df332ee050ecb4dbf9cc58c`
- [Max 2027 corrected MZP](../../../dist/spline-bands-0.80.0-ui-refresh-20261013/CyrusScatter-0.80.0-Max2027.mzp)
  — SHA256 `930edf13748d720a5945854f2ee6424aa8c9caa1f84baaf91691cbd8f7bc821c`

Generated script SHA256:
`7a92c0b109359657d65d35a2362ce81c7bc357a127cd608bd1df38607d7925c4`.
The four native modules per year are unchanged and were verified loaded in the
owned test hosts. Native registration and normal profile configuration bytes
are unchanged by this correction. The installed script and manifest match the
packages; all 13 recorded payload/configuration paths per year were rehashed.

Validation: 51 focused host assertions per year, 161 repository tests and
generated-source consistency pass. [Implementation evidence](PROGRESS.md#ui-refresh-correction--13-october-2026)
records the paired timing probe and physical interaction scope. Full heavy-scene
and artist-profile acceptance remains separate.

[Delivery receipt](../../../build/ui-refresh-20261013-01/installation.json) and
prior-file backups are under `build/ui-refresh-20261013-01/backup/Max2026` and
`Max2027`. Preserve this directory when recovering the earlier matched delivery.
No normal Max process was restarted or sent test commands.

## Earlier delivery (superseded by the correction above)

13 October 2026. The user authorized packaging and installation into the existing
Max 2026 and Max 2027 profiles. Both installations are complete on disk and
hash-verified. **A fresh launch is required to load them.** The open Max 2027
artist process was preserved on its previous loaded modules; it was not restarted
or sent scene commands. This is a development delivery, not release certification.

## Installers

- [Max 2026 MZP](../../../dist/spline-bands-0.80.0-20261013/CyrusScatter-0.80.0-Max2026.mzp)
  — SHA256 `f7d32d644ad10c6c4a801e7db6a2756a0cf3f45a7cdfca5dfef6672f4fe588df`
- [Max 2027 MZP](../../../dist/spline-bands-0.80.0-20261013/CyrusScatter-0.80.0-Max2027.mzp)
  — SHA256 `90924415d472f298f1ab57b007a196f99bd6ead26215d4d8c0b5bdb8f873cf09`

The local profiles already contain these payloads. For another installation,
use Scripting > Run Script with the matching year's MZP, then restart Max.
Create > Geometry > Cyrus > Cyrus Scatter opens the current tool.
Create fresh schema-57 setups; older development scenes are not migrated.
Preserve originals with their matching historical build.

## Identity and scope

Both packages reuse the exact four ordinary native modules and generated script
qualified by the [final implementation campaign](PROGRESS.md). No plugin runtime
code changed for installation. The package builder rejects private fault and
licensing-lab binaries and checks the existing team verification key. Installer
wording now describes schema 57 and the current Layer/Surface/Model workflow;
third-party license notices are also copied into the installed directory.

| Max | Installed under the user's `ENU/scripts/CyrusScatter/` | Previous registration preserved for recovery |
| --- | --- | --- |
| 2026 | `bin-max2026-922d39e0748e` | `bin-max2026-906474f8e1e8` (0.79.2) |
| 2027 | `bin-max2027-96ace5ab083e` | `bin-max2027-ec627defe73b` (0.79.5) |

The per-user script, macro, startup loader, manifest and notices are installed
with the matching binaries. Only the appropriate Scatter directory value changes
in `Plugin.UserSettings.ini`; the remaining bytes are preserved. The old binaries
remain intact. Normal `3dsMax.ini` files and Analyzer registration are unchanged.
License state and artist scenes were not modified.

## Verification and recovery

The [installation receipt](../../../build/install-scatter-0.80.0-20261013-01/installation.json)
records package manifests, prior identities, installed hashes and backup paths.
All 13 installed payload/configuration files per year were independently rehashed.
All recorded native build inputs, binary hashes and earlier loaded-module
qualification match. ZIP integrity/content checks and six package guard tests pass.
The open artist process's four loaded module paths/hashes remain unchanged.

Prior overwritten files are backed up under
`build/install-scatter-0.80.0-20261013-01/backup/Max2026` and `Max2027`.
The old native folders were not overwritten. Recovery must restore a matched
script/native registration while Max is closed; review any subsequent profile
changes before restoring configuration backups.

Installation used verified MZP payloads and atomic per-file copies, publishing the
configuration last. The interactive MZP dialog was not executed in the artist
session. Fresh normal-profile launch acceptance remains pending. The earlier
owned-host engineering results retain their scope; this install does not expand
physical UI, renderer, heavy-scene or device-loss acceptance.

`dist/` and `build/` are local ignored artifacts, absent from a source-only clone.
No commit, push or knowledge-base refresh was performed.
