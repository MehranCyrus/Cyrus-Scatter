# CyrusScatter 0.87.6 — UI and settings

0.87.6 repairs Point sources, corrects Band button text, clarifies painting fades
and mask previews, and puts less-used controls into named groups. The endorsed
0.87.5.6 Bend/Trim algorithms and shared viewport foundation are preserved.

- [Artist guide](ARTIST_GUIDE.md)
- [Every control and its purpose](CONTROL_LEDGER.md)
- [Panel decisions and causes](AUDIT.md)
- [Executed checks and limits](QUALIFICATION.md)

## Download and install

- [Combined EXE — Max 2024, 2026 and 2027, installer r2](../../../dist/CyrusScatter-0.87.6-20261028-installer-r2/CyrusScatter-0.87.6-Setup.exe)
- MZP: [2024](../../../dist/CyrusScatter-0.87.6-20261028-installer-r2/CyrusScatter-0.87.6-Max2024.mzp) · [2026](../../../dist/CyrusScatter-0.87.6-20261028-installer-r2/CyrusScatter-0.87.6-Max2026.mzp) · [2027](../../../dist/CyrusScatter-0.87.6-20261028-installer-r2/CyrusScatter-0.87.6-Max2027.mzp)

The [installer r2 repair](INSTALLER_REPAIR_R2.md) fixes upgrades from verified old
Max 2024/2026 installations, including the reported Max 2026 0.81.6 setup. Every
plugin/runtime byte is identical to the original 0.87.6 delivery. Original native
qualification receipts remain unchanged; r2 adds separate installer evidence.

Save work and close the Max versions selected in the EXE, install, then reopen.
For MZPs use **Scripting > Run Script**, then restart Max. Install the complete
matching package; do not replace only the script. The EXE is unsigned. Existing
Library content and the independent Surface Analyzer installation are retained.

Max 2027 has scoped UI/runtime checks and 23 passing native suites. Max 2024 and
2026 have distinct compiled payloads with archive, guard, hash and embedded-resource
verification, without runtime tests. Native Scene presets remain Max 2027 only.
Artist profiles/scenes were not installed, restarted or overwritten.

## Version and preservation

The user explicitly selected **0.87.6** for this substantial UI/settings follow-up.
Scene **65**, Interactions **15**, source transform/Undo **2/2**, Edit capability/storage
**4/3**, recipe **9** and Scene metadata **1** are unchanged. Independently versioned
products remain independent. The [receipt](QUALIFICATION.json) records 67 protected
native source hashes and the exact delivered package.

This is not a new performance benchmark or universal production certification.
The next performance run, website rebuild and knowledge-corpus activation are
separate tasks. Git stores the relevant source/docs; ignored installers and scenes
remain local delivery artifacts.
