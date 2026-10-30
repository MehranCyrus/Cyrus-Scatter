# 0.87.6.7 compatibility installer and website

30 October 2026. After accepting the Max 2027 delivery, the user explicitly
requested an EXE for Max 2024, 2026 and 2027 and an updated website upload ZIP.
This extends packaging scope without changing the plugin version or the original
[Max 2027 qualification](QUALIFICATION.json).

The [combined EXE](../../../dist/CyrusScatter-0.87.6.7-20261029/CyrusScatter-0.87.6.7-Setup.exe)
contains three distinct SDK/native/managed packages. Max 2024 and 2026 were built
from the same frozen 648-file source snapshot using their matching SDKs; these
applications were not launched. Their native test executables were not run. Max
2027 retains its original 62 native suites and focused owned-host qualification.
The exact original Max 2027 MZP remains unchanged, including its SHA-256
`92eb40e16751c0f3fdf4bef63001959e70f8b9290e77b9f45d93c3e05321eefa`.

The compatibility qualification binds producer receipts, host guards, every MZP
member hash, embedded EXE resource hashes and an owned-directory installer-engine
campaign. No artist profile was installed, no artist Max session was restarted
and no plugin source was changed for compatibility packaging. Existing plant
content and independent Surface Analyzer installations are retained.

Save your work and close the Max versions you select, run the EXE, choose the
desired hosts and reopen Max. Save upgraded scene copies because the new Edit
storage and preparation formats require the matching new plugin.

The canonical website now documents pinned edits, held Mesh/Proxy previews,
panel/Band fixes and selected-piece plant preparation. The download points to
the verified combined EXE. The full static website ZIP includes that exact file
under `downloads/`. Upload/extract the full website ZIP in the site's document
root, with `index.html`, `assets/` and `downloads/` directly in that folder.
An additional Installer ZIP contains only the EXE and is not the full website.

See [website verification](../../../website/verification/UPLOAD_08767_20261029.md)
and [upload instructions](../../../website/CPANEL_UPLOAD.md) for final archive
paths and integrity. This prepares a local upload; it does not deploy to a host,
push Git, install into artist profiles or refresh knowledge indexes. The compact
knowledge selection was stale; current original source and delivery records were
used directly.
