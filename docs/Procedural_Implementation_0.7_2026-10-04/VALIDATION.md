# Validation and reproduction

> **5 October follow-up:** The 218-control count and runtime/package passes below describe the earlier candidate. Current source has 217 controls after removing Apply spacing, plus a new native layout helper. See the [handoff](../Review_Handoff_2026-10-05/CURRENT_STATE.md) for its partial validation. Do not reuse this evidence's hashes for the newer source.

## Executed without controlling Max

This section records the offline gate. The authorized Max 2027 campaign below and [runtime report](RUNTIME_REPORT.md) are separate evidence; the table's scope does not imply that runtime testing is still pending.

| Check | Result | Meaning |
| --- | --- | --- |
| Max 2026 SDK Release build | Pass; final logs under `build/procedural-07/max2026/` | Native source compiles/links for that SDK, not a successful plugin load |
| Max 2027 SDK Release build | Pass; final logs under `build/procedural-07/max2027/` | Same boundary |
| CTest native suites | 13/13 for each SDK build | Twelve retained suites plus the new procedural suite |
| MCP tests | 64 passed | Local contracts/mocks/transport/stdio tests; no live Max enrollment |
| UI generation | Reproducible bytes; 218 inventoried controls | Generator wiring/delimiter checks, not MAXScript compilation or clicked UI coverage |
| Protected baseline paths | Unchanged point display, preview renderer and scroll implementation | Source preservation, not measured FPS equivalence |
| Candidate archives | Verified file hashes and ZIP integrity | Packaging correctness, not installation qualification |

The new native suite compares 240 randomized three-scope solves against an independently written exhaustive oracle. It also exercises keyed mask filtering, candidate ranges, serial/parallel equality, density after projection, keyed falloff, distance equality, XY/XYZ, disabled pair overrides, protected zero-quota clones, variable/sheared radius bounds, cleanup replay, target extension, warm suffix independence, work caps and invalid input rejection.

The extra MCP tests verify recipe/last-epoch export, metre conversion without scaling multipliers, absence of fabricated results for unbuilt setups, and rejection of policy-3 mutation through old plan schemas. The unchanged schema/model files are checked against the checkpoint.

Detailed generated-source hash, preserved-file list and test/package hashes are captured in [evidence.json](evidence.json). Build logs remain in the ignored build workspace; source, tests and this report remain suitable for the code/docs checkpoint. Earlier `Procedural_Evaluation_2026-10-04/evidence/readiness` describes a different source snapshot and was not rewritten as new implementation evidence.

## Reproduce offline

Run from the repository root in PowerShell. These commands do not install or launch Max:

```powershell
Push-Location AminScatter
node tools/ui/generate.cjs
Pop-Location
build/mcp-venv/Scripts/python.exe tools/procedural_lab/check_generated.py
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests -q
build/mcp-venv/Scripts/python.exe tools/procedural_lab/build_check.py --max-year 2026 --package
build/mcp-venv/Scripts/python.exe tools/procedural_lab/build_check.py --max-year 2027 --package
```

The build helper uses the repository's compiler-environment setup and local Max SDKs. It builds Scatter only, executes the native suites, and optionally stages versioned MZPs under `dist/procedural-0.7-candidate`. It does not alter the installed plugin profile.

## Executed in isolated Max 2027

The matching script and native modules were loaded in a fresh private process. [Runtime evidence](evidence/runtime/summary.json) includes source and loaded-module hashes, scenario receipts, live MCP campaigns, raw navigation steps and summaries.

| Fixture | Result |
| --- | --- |
| `Max_Procedural_07_Fixture.ms` | Core generation, warm cache, modes, reordering, shortfall, rollback, protected edits/clones/radii passed. |
| `Max_Procedural_07_Acceptance.ms` | Three-scope geometry checks, backgrounds/refill, planar and curved Brush, include/exclude, stable surviving transforms, Copy/Remove/Undo, Manual/Live, topology guard and persistence passed. |
| `Max_Procedural_07_Bindings.ms` | Source/receiver replacement and Undo, later-owner failure rollback, selection preservation and stale-radius guard/recovery passed. |
| `Max_Procedural_07_Units.ms` | Reproduced unsupported automatic rescale; paint history preserved and adopted-file-units reopen recovered the original placement/source fingerprint. This is a limitation test, not a unit-migration pass. |
| `Max_Procedural_07_UI.ms` | Twenty native rollout cycles retained HWNDs and did not rebuild calculation/display. |
| Actual computer input | Curved-surface mouse stroke, Start/Stop, wheel scrolling and Apply spacing verified, with API assertions afterward. Planar tests used the native ray/dab API. |
| `layers_release_campaign.py` | All nine existing live MCP programs passed. |
| `mcp_acceptance.py` | Policy-3 pure inspection, ordered rules/IDs, pending recipe versus published epoch, and direct legacy mutation guard passed. |
| `Max_Procedural_07_Navigation.ms` | 20k/100k plants, matched geometry/camera/budgets versus frozen 0.64. Zero navigation builds/uploads; Proxy drawing remains expensive. |

The 100k frozen Proxy test exceeded the command driver's 180-second wait. Max continued, completed its assertions and wrote its matching SUCCESS receipt and full JSON. That completed result is retained; the timeout was not represented as an aborted or successful timing sample by itself.

## Reproduce the runtime campaign

Use disposable Max 2027 profiles, never the artist's current session. `tools/mcp/launch.py --run <unique-lowercase-name> --native-build build/procedural-07/max2027` launches a private profile. The driver only accepts an identified directory below `build/mcp-qualification`; it executes local developer fixtures, not remote MCP scripting.

Load the performance monitor with `CyrusPerfHeadless=true`, load `Max_Procedural_07_Acceptance.ms`, then call `P07Acceptance()`. Run the bindings and units fixtures while their helper globals and saved scene exist. The core fixture requires an empty scene. The UI and navigation fixtures deliberately replace the private test scene.

`layers_release_campaign.py <private-folder>` runs the existing live MCP program set. `tools/procedural_lab/mcp_acceptance.py <private-folder>` adds the new read-only policy check. `launch_baseline.py` extracts only the frozen package's script/native payload into its own profile and never runs its installer. The navigation script accepts a label, population and `procedural:true` for the new policy. Allow at least 300 seconds when measuring 100k displayed proxies. Verify loaded module hashes in each process.

`collect_runtime_evidence.py` verifies the recorded campaign folders and writes concise receipts; `collect_evidence.py` then verifies the final generated source, native artifacts and candidate archives against them. The collector's current fixture-folder names reflect this dated campaign; change them deliberately for a new run.

## Remaining release gates

- Max 2026 host and installer transitions from 0.64 / historical 1.x packages.
- Artist testing with real foliage, renderer/driver combinations and scene sizes; complete UI usability acceptance beyond the tested paths.
- Coordinated automatic unit migration; do not raise caps until update-time distributions and isolated memory costs are measured on representative assets.
- A retained-Proxy experiment, and eventual policy-3 MCP mutation/ML contracts as separate work.

The candidate is ready for scoped Max 2027 artist testing. It is not an unrestricted production or cross-version certification.
