# Preparation foundation 0.3.0 — delivery

24 October 2026. User-run Max 2027 kit:

- `dist/CyrusVegetationPreparationLab-0.3.0-20261024/CyrusVegetationPreparationLab-0.3.0-Max2027.mzp`
- Same folder: `OpenTest.ms`, `OpenLab.ms`, `Vegetation_Preparation_Max2027.max`, artist README, qualification report, exact native pair, licenses, package manifest and `verification.json`.
- `evidence/` retains the native test logs, installed/fresh-open receipt, loaded-module paths/hashes, full mesh audit and physical pointer receipt. `Prepared_Lavender.png` is the full Scanline render.

Use **Max 2027 > Scripting > Run Script** on the MZP. It copies the kit under the user's versioned scripts folder and reports its launcher path. Save work and restart Max 2027 if an older Stem Lab module is loaded, then run that folder's **OpenTest.ms**. The portable folder's **OpenTest.ms** works directly too; **OpenLab.ms** opens the panel in an existing scene. No artist profile installation or session restart was performed here.

The final native build is `build/vegetation-preparation-plugin-20261024-05`. The full authoring/Undo/cancellation/source-change/save/reopen/render fixture passed in `build/vegetation-preparation-host-20261024-05`. Installer copying, hash checks, installed launcher, full native geometry and saved catalog reopening passed in a fresh owned profile, `build/vegetation-preparation-package-host-20261024-03`; loaded hashes match the kit. Archive CRC, every payload hash and compiled input/dependency identity were verified again after execution. Native classes register once through the DLO.

Final package physical interaction: `build/vegetation-preparation-package-pointer-20261024-02`, exit 0. The compact panel and clean one-model catalog were visually inspected. A Move-gizmo stroke moved sphere X from 0.500 m to 0.393 m, publishing a new pose with 23 active stems, 20.39 ms native solve and 26.91 ms viewport build. Full delivered float audit after that stroke found 8.825 mm minimum sphere gap, no rigid foliage edges changed above 10%, and approximately 20.1% maximum stem-edge change. These are CPU timings, not presented FPS. Zero button-held samples were captured during the tool's short stroke; sustained held-drag publication is still unqualified.

The original/source geometry is retained. The current supported analysis profile is separated ordered round tubes; the tested lavender has 1,290 guides and a 69,736-triangle viewport preview from 832,240 full triangles. Automatic rigging of arbitrary merged plants, manual guide correction/import, multiple collider layers, wind and tree dynamics are next work. [The detailed qualification report](REPORT_030.md) keeps shape, memory, renderer and cold missing-source limitations explicit. [The artist guide](GUIDE_030.md) describes the workflow. This is independent of CyrusScatter 0.86.9.2/schema 59 and does not close the original research matrix.

Intermediate package-host failures came from the qualification harness compiling native function references before loading their DLL. The corrected loader runs a second script after module initialization; final fresh-profile execution passed. Earlier failed run receipts are preserved and are not counted as passes.
