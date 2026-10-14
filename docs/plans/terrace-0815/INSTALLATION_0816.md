# Scatter 0.81.6 local delivery

13 October 2026. The user authorized building the installers and installing
0.81.6 for terrace testing. The exact native modules and generated script from
the [owned-host qualification](VIEWPORT_0816.md) are packaged and installed in
the normal per-user Max 2026 and 2027 profiles. No product source changed during
packaging; package instructions now describe the adaptive viewport limits.

## Packages and identity

- [Max 2026 installer](../../../dist/CyrusScatter-0.81.6-20261013/CyrusScatter-0.81.6-Max2026.mzp)
  - SHA-256 `5e9c3067a770b7e45db977609727ae1faafd4ba863ac83b292fc7e088f41db03`.
- [Max 2027 installer](../../../dist/CyrusScatter-0.81.6-20261013/CyrusScatter-0.81.6-Max2027.mzp)
  - SHA-256 `abe24a171edc6cad6b37171d09b70ac506c73098e6cc66c8af21a1019b301aef`.

Generated script SHA-256:
`a7f11f2d960cc0eae26f3a4a41ce5271d4f8527c6b074b0e0ee527da171efce6`.
Native directories: `bin-max2026-866ea3d51489` and
`bin-max2027-7800997061d5`. Schema 58, Band interface 10, publication interface
2 and viewport policy capability 1 require the matched script/native pair.
Analyzer and licensing behavior are unchanged.

`tools/viewport_0816/package.py` verifies build-source hashes, qualified-host
script/module identities and successful host receipts before packaging. Both
archives and every manifest payload hash were rechecked before installation.
Package receipts are `build/install-0816-20261013-01/package-2026.json` and
`package-2027.json`.

## Installation and preservation

[The installation receipt](../../../build/install-0816-20261013-01/installation.json)
records all installed hashes and backups under
`build/install-0816-20261013-01/backup/Max2026` and `backup/Max2027`.
The verified payload installer writes native files, scripts and startup/macro
files, then publishes the owned plugin-registration value last. The interactive
MZP dialog itself was not exercised. Existing native directories, normal
`3dsMax.ini` files and Analyzer files were preserved.
`final-verification.json` rechecks every installed product payload and both
registrations. Max 2027 subsequently added a trailing separator to its native
directory value; that is the only configuration-byte change and resolves to the
same tested directory.

At write time Max 2026 contained 0.81.3. Max 2027 already contained the same
0.81.6 native directory; its payload was verified and synchronized. The original
Max process seen at task start had exited by the final read-only check. A new
normal Max 2027 process, PID 23840, had all four matching 0.81.6 native modules
loaded from the expected directory. Paths and hashes are preserved in
`build/install-0816-20261013-01/running-max2027.json`. This task did not close,
restart or control either artist host. A read-only MCP connection check failed,
so no normal-profile script-runtime or scene acceptance is claimed.

The original `Test Scene/Terraces_0815/Terraces_0815_Final.max` remains unchanged:
SHA-256 `54b006f2cd40183bcdb048d3ab040eaee066ad67728d5e3b76b381685ab65801`.
Only the previously owned qualification copy was used for automated tests.

## User acceptance

Restart any session that still has an older build loaded. Test a copy of the
terrace scene with the **Viewport & render** Navigating and Idle controls for
Point Cloud, Proxy and Mesh. Zero removes the selected phase's draw cap; memory
and input safeguards remain. Check Mesh while orbiting and after the viewport
settles, and compare finite limits with zero. Physical interaction, presented
FPS and prolonged artist sessions remain acceptance gates.

The existing native and owned-host test results apply because their exact
product bytes are delivered. No new render qualification, source commit, push
or website build/deployment was performed. Installers and receipts are ignored
local artifacts and are not backed up by Git.
