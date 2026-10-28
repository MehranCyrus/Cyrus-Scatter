# 0.87.6 installer r2 — legacy Max registration repair

Date: 2026-10-28. Scope: the installer and its filesystem tests. Product version
stays **0.87.6** because this repairs installation of the same delivered plugin;
the four native modules, MAXScript, Gallery and all other runtime files are reused
byte for byte. No interaction, placement, display or performance algorithm changed.

## Download

[Combined EXE for Max 2024, 2026 and 2027](../../../dist/CyrusScatter-0.87.6-20261028-installer-r2/CyrusScatter-0.87.6-Setup.exe).
Close the selected Max versions and use **Install / Update**, then reopen Max.
The recognized old installation does not need to be removed manually.

MZP alternatives: [2024](../../../dist/CyrusScatter-0.87.6-20261028-installer-r2/CyrusScatter-0.87.6-Max2024.mzp),
[2026](../../../dist/CyrusScatter-0.87.6-20261028-installer-r2/CyrusScatter-0.87.6-Max2026.mzp),
[2027](../../../dist/CyrusScatter-0.87.6-20261028-installer-r2/CyrusScatter-0.87.6-Max2027.mzp).
Use **Scripting > Run Script**, then restart Max. If an older installer helper is
already loaded, restart before running the new MZP. The EXE is unsigned.

## Cause and changes

The user's Max 2026 profile had the original 0.81.6 loader/macro and
`CyrusScatter2026=.../bin-max2026-866ea3d51489/`, without the modern installation
receipt. All four installed native modules matched the archived Max 2026 0.81.6
package. Wrapper recognition passed, but `CheckRegistration` admitted historical
native registrations only for Max 2027. Preflight therefore refused the selected
multi-version update before publishing a new installation.

- Legacy registration records now include the SDK year and verify the exact
  historical native set and supported path. Added 0.81.6/2026 and
  0.86.8.2/2024/2026; retained the five original 2027 entries.
- The EXE reports **Older installation found** when startup, macro or registration
  exists without a valid modern receipt. This read-only presence check does not
  grant replacement or uninstallation permission.
- A verified, content-addressed copy of the original plugin INI survives a
  successful unreceipted migration, alongside the original wrapper backups.
- Existing unknown/custom registrations, modified modules, duplicated keys,
  edited wrappers and invalid receipts remain protected. Transaction rollback and
  retry continue to use the original atomic publication mechanism.

## Executed evidence

- **37 focused tests passed**, including archived migration layouts for the three
  years, mismatch/customization rejection, backup integrity, rollback and killed
  installer-process retry. These are managed/filesystem tests.
- **9 delivered-package scenarios / 76 checks passed**: clean installation and
  modern-receipt update for each year, archived Max 2024 and Max 2026 upgrades,
  and the combined EXE's actual three-version command followed by a repeat update.
  The EXE form was constructed without showing a window. Its labels, selection
  state and legacy-uninstall restriction were checked programmatically.
- The combined test verified every embedded MZP against the delivered archive.
  Each repacked MZP preserves **27 members** exactly; only `CyrusInstaller.dll`,
  `install.ms`, `InstallInventory.txt` and `manifest.json` differ.
- Recorded artist-profile registration, startup/macro, receipt and old native
  hashes stayed unchanged. No Max process was launched or artist installation run.

Reproducible commands:

```powershell
build/mcp-venv/Scripts/python.exe -m pytest tools/tests/test_installer_repairs.py tools/tests/test_installer_docs.py tools/tests/test_installer_adapter.py -q
build/mcp-venv/Scripts/python.exe tools/procedural_lab/ui0876/repair_installer.py --run build/<fresh-run> --output dist/<fresh-delivery>
build/mcp-venv/Scripts/python.exe tools/procedural_lab/ui0876/check_installer_repair.py --run build/<fresh-run> --package-dir dist/<fresh-delivery>
```

The repacker pins all three original 0.87.6 package hashes, verifies their complete
package receipts, and permits changes to only four installer members. It records
the new installer producer and the unchanged historical native/Gallery producers.
It does not rewrite or claim a fresh native build receipt. The normal native
package verifier remains unchanged.

See [repair receipt](evidence/installer-r2/receipt.json),
[delivered checks](evidence/installer-r2/delivered-tests.json) and
[focused test results](evidence/installer-r2/tests.xml). Original
[plugin qualification](QUALIFICATION.json) and its package hashes remain historical
evidence for the original delivery. This repair adds no new Max 2024/2026/2027
native runtime, renderer or viewport qualification. Website and knowledge indexes
were not refreshed by this repair.

## Exact deliverables

| Artifact | SHA-256 |
| --- | --- |
| EXE | `68eb237ae36a45582df6e9334c99fa9dfd46a3411b2d4333e54877588718189a` |
| Max 2024 MZP | `95ffb18da66d3fc64b82e618fbc5086abf99d224ae5b1efdd82e0ef122afc2bb` |
| Max 2026 MZP | `5d464ed0defd10b89f208bce209a19d7ff9c2b26c818a0ae95329cfb2b458c90` |
| Max 2027 MZP | `a139edc83fc30f7ad89e8e9274da07e20803c5bbaa6a60359e7a05ef541d9d8b` |
