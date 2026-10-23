# Gallery identity correction — Scatter 0.86.8.6

23 October 2026. This patch repairs the library-opening failure in the combined
0.86.8.5 installer. It retains schema 59, recipe 8, CyrusUnified2, optional content
0.86.7 and independently versioned Surface Analyzer 0.14.1. No feature, authored
setting, placement calculation or scatter result is changed.

## Cause and repair

The 0.86.8.5 script required gallery assembly 0.86.8.5, but all three packaged
`CyrusGallery.dll` files retained assembly version 0.86.8.3. The artist's loaded
Max 2027 DLL matched the supplied package. The guard rejected this correct-path
DLL before opening the browser; restarting the same package could not repair it.

Gallery assembly/file versions now come from the CMake release identity during
the managed build. The build reads back the compiled assembly metadata; its
receipt records the actual version. Packaging rejects mismatched release, host,
source or artifact identities. The generated-source check also checks the
library's version guard. Six focused admission regressions cover the original
stale identity, wrong host, modified artifact/source/shared source and valid pair.

The patch label distinguishes these artifacts from the faulty installer.
Release labels and the derived script fingerprint are the only MAXScript changes.
All four native Scatter modules per host and all three Analyzer packages are
reused byte-for-byte from the preceding delivery. Gallery implementation is
unchanged apart from moving assembly attributes into generated build metadata.
No native compilation or new solver qualification is claimed.

## Verification and delivery

Owned run: `build/gallery-version-08686-20261023/`. Exact artifact hashes, managed
builds, native/source parity, installer and host witnesses are retained there.
The [0.86.8.5 report](DELIVERY_08685.md) preserves its original evidence and limits;
its prior installer checks did not catch this gallery version defect.

- All three managed builds report assembly/file version 0.86.8.6.
- Generated/inventory checks pass for 332 controls. Approved-layout and template
  assembly checks pass. The full Python regression passes **198 tests**.
- The exact combined EXE passes **137 installer checks**, including the compiled
  UI's actual install/update handler, repeat/recovery/preservation and installed
  gallery identity for all three hosts.
- **21 explicit 0.86.8.5-to-0.86.8.6 upgrade checks** pass across the three
  payloads: corrected runtime/receipt, retained previous runtime, preserved
  authored recipe/content bytes and library registration, plus repeat update.
  The initial fixture assumed an unconfigured fresh profile already had a
  library-state file; its failed receipt is retained and the successor seeds
  a valid owned registration before checking preservation.
- The actual installed Max 2027 script/native/gallery paths are verified in an
  owned profile. The **Recipes button opens the existing 96-model library**;
  previews render, repeat activation reuses the window, and close/reopen works.
  Rows, publication fingerprint and epoch remain unchanged while browsing,
  including with a pending Manual amount edit. No merge/import is needed for
  this version-guard correction.
- Initial private fixture attempts had MAXScript syntax, old 104-card-count and
  generated-control-name assumptions. Their failed requests remain preserved;
  corrected fixture successors pass without product behavior changes.

New interactive qualification targets Max 2027;
2024/2026 receive rebuilt managed payloads for their respective runtimes, with
archive/installer identity checks and unchanged qualified native payloads.

Corrected EXE: `dist/CyrusScatter-0.86.8.6-20261023/CyrusScatter-0.86.8.6-Setup.exe`
(6,034,944 bytes), SHA-256
`f2ea7be7b74bb1f5b2cf0ab58dc21c735ed775280faee19aab48b6dac76a173b`.
Runnable, host-guarded Max 2024/2026/2027 MZPs are retained beside the EXE. For
the EXE, save work, close selected Max versions, run Install/Update, then reopen.
For the Max 2027 MZP, use **Scripting > Run Script**, then restart Max.
Leave the plant-library option unchecked to retain existing content.

The website's release metadata and cPanel ZIP use this exact EXE; the separate
[website verification](../../../website/verification/WEBSITE_08686_20261023.md)
records the upload archive and download checks.

No artist profile installation, artist Max restart, scene/library asset changes,
live website upload or Git commit/push is performed.
