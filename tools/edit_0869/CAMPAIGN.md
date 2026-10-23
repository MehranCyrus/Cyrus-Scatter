# 0.86.9 installer and compatibility campaign

Executed on 2026-10-23 after the explicit source freezes. Implementation baseline:
branch `codex/workflow-0.75`, commit `7d5fd264f8c39e306389977d1eda7c4f358bd3c8`.
The final delivery is `dist/CyrusScatter-0.86.9-20261023`; qualification is limited
to the recorded owned-profile scope below.
Do not overwrite `build/edit-0869-20261023/baseline.json` or any earlier run.

The requested delivery is one EXE for **Max 2024, 2026 and 2027**, with Scatter
**0.86.9** and independently versioned Surface Analyzer **0.14.2**. Each host has
its own SDK-produced Scatter, Edit, Brush, storage and Analyzer modules, plus its
matched Gallery runtime. Gallery's assembly version is `0.86.9.0`.

## Ownership and bounds

- Installer agent: this directory's `package.py`, `compatibility_host.py`,
  `compatibility_smoke.ms`, `installer_checks.py/.cs`, `installed_host.py`,
  `mzp_adapter.py/.ms`, this campaign, older-host runs
  and final package construction. New helper files are confined to this directory.
- Root: `edit_workflow.ms`, `run_workflow.py`, `legacy_fixture.ms`, any common
  fixture helper, source integration, source freeze and Max 2027 acceptance.
- Proposed older profiles: `build/edit-0869-20261023/hosts/max2024-01` and
  `hosts/max2026-01`. A replacement uses a new suffix. Every process is recorded
  in that profile's `launch.json` and `qualification.json`; never act on a PID
  without verifying its full command line and exact private INI.
- Root may use the same launch helper for `hosts/max2027-01`. All three ADSK
  profile environment directories, INI script/startup/macros paths, plugin paths,
  transport requests and results remain within owned build profiles.
- Read the user's normal INI only as the launch template. Do not change artist
  profiles, running sessions, `Test Scene/`, private asset originals or content.
- Preserve original producer directories. Version-2 receipts contain frozen
  source/config/compiler/reference/dependency paths; copying a sidecar does not
  replace those originals or authorize a source freshness bypass.

Contracts: F04/F08 Manual publication and display reuse; F05 complete publication
and failure recovery; F06 bounded admission; F07 host-thread ownership; F11 saved
authored identity and original-scene preservation; F12 independent Analyzer state.

## Toolchains found by read-only inventory

All three host EXEs exist at `C:/Program Files/Autodesk/3ds Max YEAR/3dsmax.exe`.
All three SDKs exist at
`build/tooling/maxYEAR-sdk/Program Files/Autodesk/3ds Max YEAR SDK/maxsdk`.

| Component | Selected path/version |
| --- | --- |
| Native compiler | VS 2022 Community, MSVC `14.38.33130` |
| Windows SDK | `10.0.19041.0` |
| Managed compiler | VS Community `MSBuild/Current/Bin/Roslyn/csc.exe` |
| Max 2024 Gallery | .NET Framework 4.8 (`Framework64/v4.0.30319`) |
| Max 2026 Gallery | .NET / WindowsDesktop `8.0.16` |
| Max 2027 Gallery | .NET / WindowsDesktop `10.0.0` |
| Shared installer / EXE | .NET Framework 4.8, exact verified core producer |
| Python | `build/mcp-venv/Scripts/python.exe` |

These are file-presence observations. Successful configure/build/test receipts
must establish the effective compiler, SDK, flags and dependency closure.

## Recorded commands after source freeze

These output directories now contain preserved evidence. A future run must use
fresh suffixes. Run from the repository root. Root produces and
qualifies Max 2027; the installer agent produces Max 2024/2026 only after the
shared source freeze. Production builds keep both diagnostic flags OFF.

```powershell
python tools/procedural_lab/offline_build.py --project scatter --year 2024 --generator Ninja --jobs 2 --output build/edit-0869-20261023/scatter-2024-01
python tools/procedural_lab/offline_build.py --project analyzer --year 2024 --generator Ninja --jobs 2 --output build/edit-0869-20261023/analyzer-2024-01
python tools/procedural_lab/offline_build.py --project scatter --year 2026 --generator Ninja --jobs 2 --output build/edit-0869-20261023/scatter-2026-01
python tools/procedural_lab/offline_build.py --project analyzer --year 2026 --generator Ninja --jobs 2 --output build/edit-0869-20261023/analyzer-2026-01
```

The existing offline builder performs configure, clean compilation and that
product's CTest suite, then checks before/after inputs and compiler dependencies.
There is no broad website, MCP, Paint or unrelated performance campaign here.

For an initial product test before installer construction:

```powershell
python tools/edit_0869/package.py stage --year 2024 --scatter-output build/edit-0869-20261023/scatter-2024-01 --analyzer-output build/edit-0869-20261023/analyzer-2024-01 --output build/edit-0869-20261023/stage-2024-01
python tools/edit_0869/compatibility_host.py launch --year 2024 --native build/edit-0869-20261023/stage-2024-01 --folder build/edit-0869-20261023/hosts/max2024-01 --require-edit-version
```

`stage_payload()` verifies the full current producer closure and emits a flat
`payload.json` with exact bytes and original receipts. `launch_owned()` validates
that manifest, copies the exact pair into the private profile and records every
loaded destination plus source/fixture hashes. It supplies `EWHostYear`.

The shared Python interface is:

```python
launch_owned(folder, year, native, script=None, bindings={},
             require_edit_version=True, visible=False)
run_case(folder, fixture, case, assertion_ids, timeout=120,
         setup="", entrypoint="EWRun")
bind_suite(folder, bindings={})  # only after the previous request is terminal
verify_owned(folder)
close_owned(folder)
```

The root fixture receives `EWRun "feedback"`, `"stack"`, `"bands"`, `"removal"`,
`"saved"` or `"guards"`; its legacy entrypoint is `EWLegacyRun`. The exact
assertion lists live in the root-owned `run_workflow.py`. Each emits `QAssert`
records and is invoked with an explicit unique assertion list.
The existing strict result parser checks request/run/artifact/scenario identity,
terminal status and the complete assertion set. Timeout means observe the
original request; never resend it as a new mutation. `bind_suite()` preserves
loaded product bytes while recording a successor fixture revision.

Legacy scene creation uses `stage-packages --historical-baseline` with the exact
preserved .7 Scatter and Analyzer MZPs. This verifies archive integrity, every
member hash and completed v2 sidecars; it explicitly does not claim historical
sources are current. `require_edit_version=False` permits that old interface.
No baseline package or scene is rewritten. Root's `legacy_fixture.ms` creates
small authored move/clone/delete/radius witnesses and saved fingerprints.

Construct final packages only after all six native producer receipts and the
shared managed core are selected:

```powershell
python tools/edit_0869/package.py package --scatter 2024=build/edit-0869-20261023/scatter-2024-01 --scatter 2026=build/edit-0869-20261023/scatter-2026-01 --scatter 2027=build/edit-0869-20261023/scatter-2027-02 --analyzer 2024=build/edit-0869-20261023/analyzer-2024-01 --analyzer 2026=build/edit-0869-20261023/analyzer-2026-01 --analyzer 2027=build/edit-0869-20261023/analyzer-2027-01 --core build/remediation-08687-20261023/managed01/CyrusInstaller.dll --output build/edit-0869-20261023/packages01
```

The core argument may select an earlier exact producer only if its complete
frozen source/reference/tool closure still verifies. This recipe compiles the
EXE only; it does not rebuild native or core artifacts. It retains six MZPs,
their `.sha256`/`.build.json` sidecars and the EXE's complete producer receipt.
The existing content 0.86.7 is read for metadata only and is never copied.

The new `installer_checks.py/.cs` exercises the exact EXE's real Install/Update
button with all three host cards selected. It expects 53 assertions: six product
installs with exact member/runtime checks, repeat binding preservation, distinct
completion reports, preserved existing content and three custom-registration
preflight refusals. It replaces every profile target before bypassing the normal
running-Max check; no artist process is controlled. Use a short owned path:

```powershell
python tools/edit_0869/installer_checks.py --exe build/edit-0869-20261023/packages01/artifacts/CyrusScatter-0.86.9-Setup.exe --library-state build/remediation-08687-20261023/host08/gallery-library-state.txt --output build/e869e01
```

The independent compatibility supplement uses `ECSRun "EC-A"` (four Analyzer/
Gallery assertions) and `ECSRun "EC-M"` (six real Maple admission/recovery
assertions). Call `bind_library(folder, registration)` to copy only the small
existing registration into the profile, and bind the two Maple input files
before running `EC-M`. It reconstructs two explicit green-Maple placements from
the unchanged version-compatible assets, avoiding the Max-2027-only scene.

## Minimum acceptance matrix

| Host / route | Required evidence |
| --- | --- |
| Exact combined EXE, all three selected cards | Fresh Install and repeated Update; embedded MZP/member hashes; per-host receipt/runtime/Gallery/Analyzer identities; unrelated INI preservation; plugin-only content reuse; unknown custom preflight refusal; no artist writes |
| Exact MZP adapters, all three hosts | Wrong-host refusal, helper hash refusal, fresh/repeat installation, verified v2 backup migration and unknown custom registration preservation |
| Fresh EXE-installed startup, all three hosts | Automatic native/plugin registration and startup wrappers in a new owned process, exact paths/hashes, Edit feedback and Analyzer/Gallery use |
| Core Edit smoke, 2024 and 2026 | Model/Layer/Bands colour; final matrices and SDK Move for asymmetric/offset sources; source removal/inactive history; Undo/Redo; save/reopen; one genuine old-format authored fixture |
| Analyzer / Gallery, 2024 and 2026 | Analyzer creation/update and Scatter use; actual Gallery open using the host's managed assembly while Manual pending settings and complete publication remain unchanged |
| Memory/display, 2024 and 2026 | One carried-forward real high-poly source; complete Mesh; explicit low-budget successor refusal retaining the prior complete result; recovery without placement changes |
| Root 2027 campaign | Full bounded E1–E4 cases, saved-state and failed-successor boundaries, actual tree/asymmetric pivot witness |

The initial copied-payload launcher proves a matched host pair. Installed-startup
acceptance separately uses exact EXE-installed owned paths and a fresh owned
process; a copied script launch alone does not prove that route. Final verified copies are in
`dist/CyrusScatter-0.86.9-20261023`, after root accepted the requested host scope.
Failure in an older host blocks the promised three-host delivery; do not substitute
an old native DLL or relabel a partial campaign.

## Existing asset and legacy evidence

The installed content root is
`C:/Users/Mehran/AppData/Local/CyrusScatter/Library/packs/010f43f09172c084/Library`.
All assets are inputs to read or copy into an owned scene, never edit in place.

| Relative tree path | SHA-256 |
| --- | --- |
| `Models/Trees/A097 - Maple - Green Foliage/model.max` | `8f2d4b0f97325e3320f87cfe80e298c25a6fbad7fd8ad6b15f144ce98f8988c5` |
| `Models/Trees/A098 - Norway Maple - Red Foliage/model.max` | `8553d1168492d31396201a584a83a4cc57c167e557cc190ac9b9adc7f8d0848c` |
| `Models/Trees/A076 - Orange Tree/model.max` | `d4652fd353f77980b40a3ec09dab330dc19f069229c632f8bc0d414020af2119` |

The .7 high-poly run used the two Maples, not Orange Tree. Its immutable owned
scene is `build/remediation-08687-20261023/baseline-host01/trees-baseline2.max`
(SHA-256 `a1ed3f386722dcc3102480362ed241aaabc73f9350f0849cb7888c80e2eae280`).
It was saved by Max 2027; older hosts should reconstruct the bounded witness
from the version-compatible original model files, not attempt to load a newer
scene. `tools/viewport_0867/save_content.py` records `saveAsVersion:2024`.

Historical authored two-modifier scene:
`build/mcp-qualification/foundation-memory0854-nativeaccept-controller-20261018-07/edit-baseline-plane.max`
(SHA-256 `779d8914f5b5e2da47d3197b328ba88e10d550c62dcd50e0b84388e4f966f0a4`).
Its original creation script is `tools/native_placement/edit_baseline.ms`; the
followup old-state parity assertions are in `edit_controller.ms`. It is a larger
5,000-candidate historical witness, not the new bounded 40-candidate baseline.

Older schema-59 scenes exist in
`build/combined-installer-08685-20261022/host02-2024/schema59.max`
(`5bbc4e2ed0b9e8c5eb2d44acc204558844c84d73b581e42f5ba3f21ec6c5fca3`) and
`host02-2026/schema59.max`
(`9325def725381e6e393d186ddc2c30c2d195b11c4ae41246c55c4f695ed86914`).
Their actual authored Edit contents must be inspected before claiming migration
coverage. The root's preserved-package baseline producer is the primary route.

## Final execution evidence

- Final native producers: `scatter-2024-01`, `scatter-2026-01`,
  `scatter-2027-02`, and `analyzer-{2024,2026,2027}-01`, under the shared run root.
  Scatter passed 56 native tests per SDK; Analyzer passed one per SDK.
- Older hosts each passed 43 compatibility assertions: Edit feedback, Bands,
  source removal, Undo/Redo, persistence, Point lineage, disabled-radius recovery,
  genuine old-format migration, Analyzer/Gallery and the real Maple budget case.
- Exact MZP adapters passed eight assertions per host. The combined EXE passed
  53 through its actual Install/Update handlers at `build/e869e01/receipt.json`.
- Fresh automatic EXE-installed startup and 11 functional assertions passed on
  `hosts/installed2024-02`, `hosts/installed2026-01` and `hosts/installed2027-01`.
  All owned compatibility/installed processes were closed.
- The installer-owned selected total is **196 assertions**. It excludes the
  root-owned full Max2027 workflow, private fault, old-reader and native results.
- `build/edit-0869-20261023/installer-compatibility-summary.json` records exact
  selected requests and retained failed fixture attempts. `installer-final-audit.json`
  re-verifies complete source/config/producer closure and production fault-hook
  absence. `distribution-seal.json` verifies all 76 copied files and the manifest.

The tested EXE SHA-256 is
`e9e35f5e1c6cb4bf40abb8de293a71faf0c8598a213c9d861e01a9aa91adb208`.
The source/helper identities were unchanged by fixture corrections. The first
Max2024 UI mount, MAXScript supplement parses and installed path comparison failed
in fixture code; explicit corrected successor requests passed. Their original
records remain intact. The Max2026 driver also stopped safely before a new request
when shared fixture hashes changed and resumed only after rebinding.

The 3,281,260-triangle Maple case verifies complete Mesh, refusal at 256 MiB,
retention and recovery. Its black silhouette images do **not** establish textured
material parity, physical mouse interaction or presented FPS. MZP checks execute
the archive's exact adapter after verified extraction; fresh automatic startup is
qualified through the separately tested EXE-installed paths. The old-loaded-helper
scenario is prior 0.86.8.7 corroboration; fresh helper-tamper refusal is covered here.
