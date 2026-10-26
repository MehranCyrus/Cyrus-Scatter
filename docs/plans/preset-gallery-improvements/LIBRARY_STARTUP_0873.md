# Library startup correction — Scatter 0.87.3

26 October 2026. The user authorizes fixing the Library error and puts the exposed-root work on hold. This patch fixes **B39**, retains schema **61**, Interactions capability **2**, shared-store **1**, recipe **8**, numeric **3** and Edit **2**. Analyzer 0.14.2 and content 0.86.7 remain independent. Qualification is **Max 2027 only**.

## Install

Use [CyrusScatter-0.87.3-Max2027.mzp](../../../dist/CyrusScatter-0.87.3-20261026/CyrusScatter-0.87.3-Max2027.mzp) through **Scripting > Run Script**, follow the result and restart Max. The existing [prepared 0.87.2 scene](../../../dist/CyrusScatter-0.87.2-20261026-r2/Trials/Small_Test_Interaction_0.87.2.max) remains compatible and was loaded without overwriting it. No plant content reinstall is needed for this code correction. An already loaded installer helper may require a restart before retrying. No artist profile was installed or restarted.

## Cause and correction

Opening **Layers > Recipes** could display `Call needs function or class, got: undefined` while still showing 96 model cards. The exact 0.87.2 stack identifies `CyrusSharedStore`: the default settings branch calls the unavailable bare `getEnvVariable` to locate `LOCALAPPDATA/CyrusScatter/personal-library.txt`. The same invalid call occurs when remembering a newly chosen root. Both calls were also in 0.87.1. Its tests supplied an explicit library-root override, bypassing this default branch.

The authoritative `shared-library.ms` template now uses `System.Environment.GetEnvironmentVariable` for both existing read/write paths. Folder selection, registration format and atomic preference publication are unchanged. Generated script, gallery version guards and native/package identities are matched at 0.87.3. No global compatibility shim is introduced. The separate over-80-character warning in the first investigation came from a temporary test path and was corrected as test setup, not by relaxing the product bound.

## Executed checks

- Fresh sealed Max 2027 producer: **59/59 native tests**. **573/573 Python tests** and generated checks pass: 351 controls, 13 panels, 37 features and 32 delimiter fixtures.
- Exact MZP archive CRC, complete payload hashes, source/configuration closure, version/host guards and loaded native paths/hashes are verified. Producer: `build/library0873-release-20261026-01/AminScatter/receipt.json`; archive SHA-256 `9a292a12fb95446e9f1f31eb85bd5485174af4156dbb4cb8b4598efed1621f4e`; script SHA-256 `4c192c5f9b61c964cdaa93229f0c5f9135437ffe3a47170049bab23f64ffb05a`.
- **No `CyrusSharedLibraryRootOverride`** is used. The owned process redirects only its `LOCALAPPDATA`, and its fixture binding supplies an owned managed fallback while reading the installed plant content. This exercises the normal production branch without modifying artist preferences or assets.
- Missing preference: opens the Library using the installed-registration fallback, loads 96 cards without a notice, and does not write a new user choice merely by opening.
- Save location: writes a new owned preference through `CyrusSharedUseRoot`, clears the in-memory store, then opens again and recovers the saved root. A rejected overlong root keeps the previous preference bytes and active root intact.
- Actual **Sky mouse click on Layers > Recipes**, with large tiles: Library opens with no red banner and **96 cards**. Pending Flower amount **209** retains **71** placements; placement epoch/build counters stay **1/1**. Manual input during initial window targeting was detected; the observation was refreshed after the user left the window idle, before the successful click.
- The unchanged prepared interaction scene reopens at schema 61 with **3,650 reacting plants / 2 colliders**, valid contacts and the existing accepted counts. This is a scene-load/numeric smoke, not a repeat of every 0.87.2 drag, full-mesh audit or renderer campaign.

The exact [qualification record](QUALIFICATION_0873.json) and local `build/library0873-20261026-01/host-01/` receipts separate results and limits. Original before-state traces remain in `build/library0872-investigation-20261026-01/`; its initial harness failures are retained. Artist INI, saved preferences and the input scene were preserved. A private host was used; its startup/test transport is not shipped.

## Remaining scope

The 80-character shared-root bound remains. B38's installed-model `.max` merge/Undo-history issue, broader library failure/renderer/platform/soak cases and malformed preference recovery are separate. No new 2024/2026 build or execution, full installer transaction/automatic-startup campaign, Git push or website publication is claimed. **B40 exposed-root collider fitting remains on hold and is not part of 0.87.3.**
