# 14 — Installation, Startup, and Uninstall

## Current Cyrus Scatter installer

`install.ms` requires Max internal version `28000` (3ds Max 2026).

Destination:
`<userScripts>/AminScatter`

Native folder:
`<userScripts>/AminScatter/bin55`

It installs:
- `AminScatter.dlx`;
- `CyrusScatterEdit.dlm`;
- generated `AminScatterObject.ms`;
- `Uninstall.ms`;
- `AminScatter.mcr`;
- `AminScatterStartup.ms`.

It registers `AminScatter2026` in `Plugin.UserSettings.ini`.

If an existing native binary differs byte-for-byte, installer asks for restart/removal rather than overwriting a loaded different build.

## Startup

`AminScatterStartup.ms` fileIns the scripted class before user scenes open.

Macro `AminScatterOpen` starts object creation for `AminScatterObject`.

## Uninstall

Uninstall removes known callbacks, plugin INI registration and startup script, then instructs the user to restart Max before deleting the remaining folder so loaded DLLs are released. Existing baked scene instances are intentionally preserved.

## Surface Analyzer installer

Requires Max 2026, installs to:
`<userScripts>/CyrusSurfaceAnalyzer/bin05`

Copies:
- `CyrusSurfaceAnalyzer.dlx`;
- `CyrusSurfaceAnalyzer.ms`;
- startup script;
and registers `CyrusSurfaceAnalyzer2026`.

## Version mismatch visible

Scatter MZP metadata says 0.53 while install message says 0.59. Analyzer MZP/README says 0.14 while native/CMake says 0.5. These are concrete reasons to centralize release metadata.

## Commercial migration

Replace INI editing with Autodesk Application Plug-in Package where practical. Keep a migration/uninstall path for existing userScripts installs so customers do not end up loading both old and new copies.
