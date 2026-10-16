# 0.85.1 installer contract

Contract finalized for the supported local NTFS subset, 16 October 2026. Exact delivery evidence is in [DELIVERY_0851.md](DELIVERY_0851.md). Only Max 2027 is targeted. No installer has been run against the artist profile.

## Ownership and publication

The MZP and Windows EXE use the same `Cyrus.Setup.InstallEngine`. The EXE embeds the complete hash-verified MZP; it neither downloads a runtime nor executes library scripts. It uses the Windows .NET Framework runtime and is currently **unsigned**. MZP loading of the same framework-built core has been exercised inside Max 2027.

Each install creates an immutable `userScripts/CyrusScatter/Releases/<version>-<content hash>/` containing the matching native modules, script, gallery helper and versioned bundled library. The hash includes all installed files, including scripts, helpers and library content. Runtime files are staged and verified before registration. Missing owned files can be repaired; modified files are preserved and cause an explicit rejection. Old release directories are retained for recovery.

Only the owned startup wrapper, creation macro, install receipt and `Plugin.UserSettings.ini` registration are published. A bounded recovery journal stores their before/after bytes; the INI changes last. Recovery accepts only before/after contents and preserves an externally changed file for review. The startup wrapper loads the script adjacent to the native module actually loaded by Max, preventing an interrupted update from pairing a new loose script with an older native module. Max must restart to use the new native version; neither installer launches or restarts it.

Unregister removes owned startup/macro/receipt and the exact owned native registration. It retains personal recipes, activation, imported textures and versioned recovery content. It is intentionally not a recursive cleanup of all product directories. Unknown/custom wrappers are rejected; upgrading the prior 0.85.0 wrapper is allowed only by its exact delivered hashes.

Supported destination: local NTFS, explicit absolute paths, no linked ancestors. Inventory limits: 512 installed files, 128 MiB per file, 512 MiB total; inventory 256 KiB, recovery journal 8 MiB and individual registration files 2 MiB. Extraction additionally bounds archive count, bytes and paths. These are admission bounds, not a disk-performance promise. Staging cancellation is checked between files and before each registration publication; a single filesystem operation is not interrupted halfway.

## Current evidence and remaining gates

- Current core `setup-pilot-08/CyrusInstaller.dll`, SHA-256 `6651533cf07f0e5035223274614528170693a2c150802859df296195eac82b4b`, passes 22 owned inert-payload filesystem checks: fresh install, Unicode/space paths, identical reinstall, repair, modified-file rejection, injected publication rollback/retry, unregister and reinstall. Six further actual process-exit/locked-file/cancellation/previous-wrapper-upgrade cases pass in `installer-crash-659311ac56fe482ba1e007670b4fb480`; old library content and external modifications are preserved.
- The exact packaged `install.ms` runs inside owned Max 2027 final150-01 with redirected scripts/startup/macros/profile paths. `installer_mzp.py` verifies its success notice and installed release. The earlier DialogMonitorOPS fixture timed out at the Qt message box; its installation had completed, and its own notice was closed before the corrected Qt-aware fixture repeated the wrapper. This was a fixture limitation, not an artist installation or restart.
- `exe-test-06` passes eight actual EXE Install-handler and scripted layout checks on the preceding payload. `setup-candidate-03` embeds the scene-cache successor package. Copied EXE recipient `15b9068e` passes the same actual handler and starts Max through installed registration, with all four native paths and the script location checked. Its exact-pair gallery/idle/lifecycle tests are tracked separately; readiness is not a lifecycle pass.
- The first copied-EXE fixture `516a7680` completed installation but failed while hashing its receipt because that PowerShell child could not auto-load Get-FileHash. The successor uses .NET SHA-256 and passes. Original failed receipts remain. No product install code changed for that fixture repair.
- Physical full-disk/ACL behavior, non-NTFS/network filesystems, code signing, actual mixed-monitor input and additional host versions remain unqualified. The final package/hash handoff is recorded separately; earlier candidates under `build/` retain their original evidence.

The EXE is distribution packaging. Recipe saving continues to work inside Max without an executable or separate background service.


The final `setup-candidate-04`/`package-pilot-5c04e564059e4039873d53ead00ab520` pair passes the actual copied-EXE Install handler, installed Max startup, exact MZP wrapper, eight examples and 30-minute gallery matrix in recipient `dbb3c981`. Final six-case recovery is `installer-crash-d225f09722b545158458c63b6ab8bc49`. [PACKAGE_0851.json](PACKAGE_0851.json) pins the exact copied MZP/EXE; core08 is unchanged. These final witnesses supersede readiness-only claims above, without changing those historical receipts.
