# 0.86.7.2 — Hide surface correction

20 October 2026. This supersedes the first 0.86.7.2 installer for user testing.
The [original delivery](DELIVERY_08672.md) and its receipts remain historical.
The label stays **0.86.7.2**: this repairs the delivered button, with no schema,
native, material, content or installer-engine change.

## Cause and correction

The artist's installed script SHA-256 matched the original delivery:
`b7a53162f376bcd7abbffcc38309e28b7c08749623dae1a951e5fafd01d41dd8`.
With one assigned receiver and no selected list row, the fallback used
`nodes=copy receiverRows`. In the host this copied the scene node and returned
`OK`; the following iteration raised **No "map" function for OK**.
The isolated reproduction recorded one extra scene node after the failure.
The prior button test explicitly selected the receiver and missed this fallback.

The authoritative `unified-core.ms` handler now constructs
`#(receiverRows[1])`: one reference to the existing receiver, without a copy
operation. The generated script was regenerated and checked. Existing surface
ownership, native visibility, Undo and failure behavior remain unchanged.
Affected contracts are F01 ownership, F04 display-only edits and F11 persistence.
The action adds only a one-element reference array; it does not copy geometry
or change placement storage. No worker or native lifecycle changed.

The correction does not delete any duplicates created by earlier failed clicks
in an artist's scene. Such objects are not reliably distinguishable from
intentional copies. Artist scenes and installation profiles were not modified.

## Fresh evidence

- **Max 2024, 2026 and 2027:** 17 assertions each, through the actual native
  button `WM_COMMAND` notification. Single receiver with no selection; selected
  receiver; no receiver; ambiguous multiple receivers; selected subset and mixed
  visibility; repeated Hide/Show; Undo/Redo; deselect/reselect; exact scene-node
  identities; retained pending Manual result and renderable flag.
- **Max 2027:** all five display modes and Manual retention; new-layer receiver
  inheritance, Point and sphere replacement, independent assignments and Live
  update. Start Brush/Stop controls retain a hidden-sphere paint session.
- **Max 2027:** hidden plane/sphere/box Paint, Erase and viewport hit tests;
  unchanged actual Scanline render checksum; filter restored after render;
  ordinary Hide/Freeze exclusions; save/reopen of the visibility preference.
- **Corrected EXE:** actual form execution against disposable profiles;
  matched plugin installs, concise success, running-host and missing-ZIP errors,
  existing-library reuse across all three hosts, repeat update with zero new
  plugin/library bytes, and uninstall preserving shared content/other hosts.
- Generator and approved-layout checks; MZP CRC and every member hash;
  host/version guards; exact script/native/Gallery hashes from loaded hosts;
  embedded EXE MZP hashes; unchanged content ZIP hash.

Receipts:

- `build/mcp-qualification/update08671-test-hide-repro-2027/hide-repro.txt`
- `build/mcp-qualification/update08671-test-hide-fixed-{2024,2026,2027}/`
- `build/final-08672-20261020/exe-ui-hide-correction/`
- `build/hide-surface-08672-20261020/correction-receipt.json`

Test-driver corrections are preserved separately: `BM_CLICK` did not activate
Max's custom button, so the regression uses its native command notification.
The first Brush UI fixture targeted the original layer while the preceding
new-layer test had selected another; it was rerun from its declared fresh scene
and passed. Neither result was counted as product acceptance.

These are automated host witnesses, not physical mouse/tablet acceptance or
all-scene performance certification. The previous broader content/material
receipts retain their original scope; this correction did not rerender the
complete catalog or rerun unchanged native unit tests.

## Corrected packages

Folder: `dist/CyrusScatter-0.86.7.2-corrected-20261020/`.
Close selected Max hosts, run the EXE and choose Update. Leave the library
option unchecked when keeping existing content. Alternatively run the matching
MZP through **Scripting > Run Script**, then restart Max.

| Artifact | SHA-256 |
| --- | --- |
| `CyrusScatter-0.86.7.2-Setup.exe` | `656736a780730fae6bddd5e59572ffc233ec461ac5eaa41338924d9b9ea2fd60` |
| `CyrusScatter-0.86.7.2-Max2024.mzp` | `ebbd488fdf1e0f198eab40828494593f79cba7921a236d29d98453a069d731ac` |
| `CyrusScatter-0.86.7.2-Max2026.mzp` | `8847710fb08b8a7ca87a8dad9e558c66dda25d248bce9a01388e749518142e86` |
| `CyrusScatter-0.86.7.2-Max2027.mzp` | `7db775a7e5f05eb5d49272e206dba0e19f41c78deb198fc215ff2433237d935b` |
| `CyrusScatter-Content-0.86.7.zip` | `db5a63e87f81abd78563ec80039fed066a6cb73f585779749ed23faf548f2c58` |

Corrected generated script SHA-256:
`20c1f695e2b1052feb301411b4f9182400611c94b80d785dd017f39160c6436c`.
Loaded script fingerprint:
`d0f87fddde3cc3a30dcbb126223dbfb46af977819d42d5529ef55fbc7ee567bc`.
The four native modules and Gallery/Installer assemblies are reused byte-for-byte
from the qualified original host-specific build. Content is an NTFS hard link to
the existing ZIP in this workspace, consuming no second archive-sized allocation.
There is no model regeneration or new extracted content copy.
