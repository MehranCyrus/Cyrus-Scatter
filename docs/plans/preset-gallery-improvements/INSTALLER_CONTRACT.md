# Installer contract and versioned qualification

## Historical 0.86.2 artist-install correction

The artist reported legacy .NET path-length rejection and a clipped EXE path
error on Max 2024. The corrected [delivery](DELIVERY_0862.md) keeps 0.86.2 and
adds actual owned-profile Max 2024 qualification. Further roadmap work remains
paused; [knowledge maintenance](../../../tools/rag/README.md) records its separate status. Artist profiles are not installation targets
for these tests.

The correction uses short `p/NNNN.ext` archive source names with an explicit,
hash-pinned logical destination mapping (installer inventory 2), and a compact per-host
runtime root under LocalAppData/CyrusScatter. Asset identities, logical library
paths and full hashes stay intact. Standard Max profiles use the per-user root;
an explicitly relocated profile keeps its runtime beside that profile. The
existing four-directory constructor and inventory 1 remain readable for exact
upgrade/recovery tests. New artists select a detected Max year and Install;
profile paths and diagnostics belong in an optional Details view. Preserve
registration ownership, cancellation, rollback, repair, old recovery content,
personal recipes and activation. Do not change Max's process-wide path switches
or Windows policy. Bound/check destination lengths before publication and save
complete failure details to a copyable log.

Evidence is pinned in [the current qualification](QUALIFICATION_0862_INSTALLER.json).
This machine's default Max 2024 admitted the preceding deep source path; it did
not reproduce the artist's runtime configuration. An isolated CLR process with
legacy path limits enforced reproduces the actual preceding installer core's
`PathTooLongException`; the corrected exact EXE passes 95 recipient checks under
those limits. The actual EXE handler/layout/error view passes 70 checks, including
150% scripted scaling. Complete final MZP extraction and installed startup are
checked in Max 2024/2026/2027. All eight examples, custom image/Paint save/reload,
Undo, density channels, heavy count changes and idle checks pass on the unchanged
Scatter pair in Max 2024. Scripted panel checks do not establish physical input,
mixed-monitor behavior or renderer qualification.

The older [0.86.1](DELIVERY_0861.md) and first 0.86.2 compatibility receipts retain
their preview labels and original SDK/managed-only Max 2024 scope. They are not
the current runtime qualification.

## Ownership and publication

The MZP and Windows EXE use the same `Cyrus.Setup.InstallEngine`. The EXE embeds a complete hash-verified MZP for each supported host; it neither downloads a runtime nor executes library scripts. It uses Windows .NET Framework 4.8 and is currently **unsigned**. Loading the exact framework-built core through the complete MZP has been exercised inside Max 2024/2026/2027.

For standard Max profiles, each install creates an immutable `%LOCALAPPDATA%/CyrusScatter/<year>/r/<content-id>/`; explicitly relocated profiles use `<profile>/cs/r/<content-id>/`. It contains the matching native modules, script, gallery helper and versioned bundled library. The content ID derives from all installed files, including scripts, helpers and library content; per-file verification keeps full SHA-256 values. New archives flatten only the physical Library sources; inventory 2 preserves their full logical paths and hashes. Inventory 1 and older `userScripts/CyrusScatter/Releases/<version>-<content-id>/` remain readable for upgrades/recovery. Runtime files are staged and verified before registration. Missing owned files can be repaired; modified files are preserved and cause an explicit rejection. Old release directories are retained for recovery.

Normal EXE use selects a detected installed Max year and Install / Repair. Initialized ENU profiles are preferred; a unique other initialized language profile is detected when ENU is absent. Ambiguity requires explicit Details selection or the matching MZP inside the intended Max. Custom executable installation paths use the MZP. Details contains technical paths, full failure text, a saved-log location and Unregister; it is collapsed initially. Completion/error status survives destination refresh.

Only the owned startup wrapper, creation macro, install receipt and `Plugin.UserSettings.ini` registration are published. A bounded recovery journal stores their before/after bytes; the INI changes last. Recovery accepts only before/after contents and preserves an externally changed file for review. The startup wrapper loads the script adjacent to the native module actually loaded by Max, preventing an interrupted update from pairing a new loose script with an older native module. Max must restart to use the new native version; neither installer launches or restarts it.

Unregister removes owned startup/macro/receipt and the exact owned native registration. It retains personal recipes, activation, imported textures and versioned recovery content. It is intentionally not a recursive cleanup of all product directories. Unknown/custom wrappers are rejected; upgrading the prior 0.85.0 wrapper is allowed only by its exact delivered hashes.

Supported destination: local NTFS, explicit absolute paths, no linked ancestors. Every destination volume is checked; the runtime volume must have payload plus 16 MiB free, and metadata volumes 16 MiB. Payload destination files must fit below 260 characters and parent directories below 248, independent of the host's long-path policy. Short staging and atomic temporary filenames avoid expanding long asset basenames. No Windows policy or Max process-wide path switch is changed. Inventory limits: 512 installed files, 128 MiB per file, 512 MiB total; inventory 256 KiB, recovery journal 8 MiB and individual registration files 2 MiB. Extraction additionally bounds archive count, bytes and paths. These are admission bounds, not a disk-performance promise. Staging cancellation is checked between files and before each registration publication; a single filesystem operation is not interrupted halfway.

## Historical 0.85.1 evidence and remaining broader gates

The following original receipts retain their scope. They do not qualify the current bytes; use the current 0.86.2 delivery report above.

- Current core `setup-pilot-08/CyrusInstaller.dll`, SHA-256 `6651533cf07f0e5035223274614528170693a2c150802859df296195eac82b4b`, passes 22 owned inert-payload filesystem checks: fresh install, Unicode/space paths, identical reinstall, repair, modified-file rejection, injected publication rollback/retry, unregister and reinstall. Six further actual process-exit/locked-file/cancellation/previous-wrapper-upgrade cases pass in `installer-crash-659311ac56fe482ba1e007670b4fb480`; old library content and external modifications are preserved.
- The exact packaged `install.ms` runs inside owned Max 2027 final150-01 with redirected scripts/startup/macros/profile paths. `installer_mzp.py` verifies its success notice and installed release. The earlier DialogMonitorOPS fixture timed out at the Qt message box; its installation had completed, and its own notice was closed before the corrected Qt-aware fixture repeated the wrapper. This was a fixture limitation, not an artist installation or restart.
- `exe-test-06` passes eight actual EXE Install-handler and scripted layout checks on the preceding payload. `setup-candidate-03` embeds the scene-cache successor package. Copied EXE recipient `15b9068e` passes the same actual handler and starts Max through installed registration, with all four native paths and the script location checked. Its exact-pair gallery/idle/lifecycle tests are tracked separately; readiness is not a lifecycle pass.
- The first copied-EXE fixture `516a7680` completed installation but failed while hashing its receipt because that PowerShell child could not auto-load Get-FileHash. The successor uses .NET SHA-256 and passes. Original failed receipts remain. No product install code changed for that fixture repair.
- Physical full-disk/ACL behavior, non-NTFS/network filesystems, code signing, actual mixed-monitor input and additional host versions remain unqualified. The final package/hash handoff is recorded separately; earlier candidates under `build/` retain their original evidence.

The EXE is distribution packaging. Recipe saving continues to work inside Max without an executable or separate background service.


The final `setup-candidate-04`/`package-pilot-5c04e564059e4039873d53ead00ab520` pair passes the actual copied-EXE Install handler, installed Max startup, exact MZP wrapper, eight examples and 30-minute gallery matrix in recipient `dbb3c981`. Final six-case recovery is `installer-crash-d225f09722b545158458c63b6ab8bc49`. [PACKAGE_0851.json](PACKAGE_0851.json) pins the exact copied MZP/EXE; core08 is unchanged. These final witnesses supersede readiness-only claims above, without changing those historical receipts.


## 0.86.2 distribution

The [current delivery](DELIVERY_0862.md) contains matching Max 2024/2026/2027 MZPs in one universal EXE. The installer/archive changed; the qualified native/script/gallery/library bytes are retained. Max 2024 now has actual scoped runtime qualification. Product `Patterns/` filenames are closed and hash-pinned inside the immutable release. Three original starter masks are included. An empty catalog is also supported; final artist-supplied artwork remains future content. New legacy-path and actual-handler checks supersede the earlier 68 distribution checks for current installer acceptance. Those prior receipts, including 0.86.1 upgrades, remain historical evidence. Current same-version legacy-to-compact upgrades, repair, interrupted publication, cancellation and unregister are exercised in disposable paths. Artist profiles, personal libraries, activation and running artist sessions were not changed.

## 22 October 2026 — 0.86.8.4 correction

The current Max 2027 installer recognizes the exact no-receipt wrapper pairs from 0.81.6, 0.85.0, 0.86.8.2 and 0.86.8.3. [Archived package hashes](../installer-panels/LEGACY_WRAPPERS_08684.json) document the finite allowlist. Missing one recognized wrapper is supported. Before publication, original existing bytes are preserved in a content-addressed `scripts/CyrusScatter/Backups/wrappers-<hash>/` folder; repeat/retry reuses the same verified backup. Unknown/custom bytes and mismatches against a valid receipt are rejected with host/file details. Journal rollback remains authoritative for registration; backups survive rollback. This replaces the older no-receipt 0.85.0-only fallback for this correction, without retrospectively qualifying historical deliveries. See [current evidence](../installer-panels/DELIVERY_08684.md).
