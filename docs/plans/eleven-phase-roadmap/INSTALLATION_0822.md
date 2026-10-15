# Scatter 0.82.2 — Max 2027 local delivery

14 October 2026. The user authorized creating the 0.82.2 installer and installing
it for **Max 2027 only**, followed by their manual acceptance of Phases 1–5.
Phase 6 remains paused. This delivery reuses the exact corrected build in
[P05](P05.md#corrected-0822-compilation--14-october-2026).

## Installer and provenance

- [Max 2027 installer](../../../dist/CyrusScatter-0.82.2-20261014/CyrusScatter-0.82.2-Max2027.mzp).
- Archive SHA-256: `bf2469dfc8d71682acf25d3f63284e27a457792cf5b53d203ea6640267090aa0`.
- Native folder: `bin-max2027-e541650c7fd6`.
- Script SHA-256: `901a43ebb86622bfbfdf2295772308c6dbe8d6274eb4d52e2151274604902d30`.
- [Package receipt](../../../build/install-0822-20261014-01/package.json).
- [Installation receipt](../../../build/install-0822-20261014-01/installation.json).

The existing package builder was called for Scatter alone, with the verified
four native modules and matching generated script. All native build source
hashes, module hashes, ZIP contents and manifest payload hashes were checked.
The installer is guarded for Max version 29000 (2027); build placeholders are
expanded. Product licensing authority and the schema/capabilities are unchanged.
No Analyzer or Max 2026 package was created. INSTALL.txt now describes the five
completed feature phases. The six existing package-version tests passed.

## Installation and preservation

The verified MZP payload was installed into the existing per-user Max 2027 paths.
Files were replaced atomically, and only the CyrusScatter2027 directory value in
Plugin.UserSettings.ini was published last. The new native files use their own
content-specific folder; previous native modules remain intact. The installer
dialog itself was not exercised.

The prior 0.81.6 product files, macro, startup script and plugin INI were backed
up under `build/install-0822-20261014-01/backup/Max2027`. The installation receipt
records exact before/after hashes. Max 2026 product files/registration, Max 2027
Analyzer files, the previous native modules and normal 3dsMax.ini were verified
unchanged. There was no scene operation or license change.

**Restart required:** normal Max 2027 process 33104 was left running with its
four original 0.81.6 modules loaded. Their paths/hashes were inspected read-only
in [running-max2027.json](../../../build/install-0822-20261014-01/running-max2027.json).
The new 0.82.2 files are installed on disk; save work and restart Max 2027 before
testing. No loose script was loaded into that older host and no artist host was
closed or restarted. New normal-profile runtime acceptance is therefore pending.

## Artist acceptance

Use the [phase-by-phase test checklist](ARTIST_ACCEPTANCE_0822.md). Start with a
small new scene, then test copies of production scenes. Check the 0.82.2 caption
after restarting, and retain saved scene units for Paint/CS Edit bindings.

The build has 31 passing native suites, 161 passing Python tests and generated
UI/catalog checks. Original P01–P05 host evidence retains original labels and
hashes. These counts do not replace the artist's physical/production/renderer
acceptance. Installers, backups, binaries and detailed receipts are ignored local
artifacts and are not included in Git. No source commit, push or website
publication is implied by this delivery.
