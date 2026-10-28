# 0.87.5.6 — compatibility installer follow-up

28 October 2026. The user explicitly requested the latest website and an EXE
for Max 2024 and 2026 after endorsing the Max 2027 performance delivery. This
adds packaging for those hosts; it changes no Scatter behavior or saved format,
so the version remains **0.87.5.6**. Earlier receipts keep their original scope.

## Download and install

[Combined Windows EXE](../../../dist/CyrusScatter-0.87.5.6-20261028/CyrusScatter-0.87.5.6-Setup.exe)
contains separate Max **2024, 2026 and 2027** payloads.

Save work and close the Max versions selected for installation. Run the EXE,
select the installed versions and choose **Install / Update**, then reopen Max.
The installer is unsigned. Existing shared content and the independent Analyzer
installation are retained; the optional plant-content archive is not embedded.

Alternative packages are beside the EXE: select the matching Max-year `.mzp`
through **Scripting > Run Script**, then restart Max. Native Scene presets remain
Max 2027 only, with their existing units and dependency restrictions.

EXE: **8,352,256 bytes**. SHA-256:
`84ec5636dd30b380a55288ee59dfa53d7e75de13ef6477391ff7ebb16f80f3af`.

## Build and verification scope

- Max 2024 and 2026 each have a clean Release build against their own SDK,
  with matching native modules and host-specific `CyrusGallery.dll` receipts.
  Both use `--build-only`; no native suites or Max host tests were run.
- The original Max 2027 MZP is copied without modification. Its SHA-256 remains
  `1ae8f32491433f258a5ed24b35be09767b1ff8ef6568247deb008afa5e038b04`.
  It retains only the [original scripted viewport/stone qualification](DELIVERY_08756.md).
- All package CRCs, manifest file inventories/hashes, year guards, frozen build
  inputs and identical script bytes are checked. Reflection verifies the three
  actual embedded MZP resource hashes without executing the installer entry point.
- No Max process was launched, artist profile installed, session restarted or
  scene modified for this follow-up. Installer UI execution and older-host runtime
  compatibility remain untested, as requested earlier by the user.

Exact artifacts and hashes: [delivery receipt](../../../dist/CyrusScatter-0.87.5.6-20261028/DELIVERY_RECEIPT.json)
and [SHA256SUMS](../../../dist/CyrusScatter-0.87.5.6-20261028/SHA256SUMS.txt).
Producers are under `build/website08756-20261028-01/native-2024` and `native-2026`;
the retained 2027 producer is `build/drag08756-20261028-01/native-2027-06`.
The reproducible [packaging command](../../../tools/procedural_lab/drag08756/package_compatibility.py)
verifies the original 2027 source and package before constructing the EXE.

## Website

The existing website follows 0.87.5.6, schema 65 and all 378 semantic controls.
It documents Bend/Trim, trunk/falloff, preparation reuse, migration from older
Detailed-contact scenes, and the correct build/runtime scope. The production
download contains this exact EXE. See [website verification](../../../website/verification/WEBSITE_08756_20261028.md)
and [cPanel upload instructions](../../../website/CPANEL_UPLOAD.md). Build/upload
packaging is local; no hosting deployment, Git commit or push is implied.
