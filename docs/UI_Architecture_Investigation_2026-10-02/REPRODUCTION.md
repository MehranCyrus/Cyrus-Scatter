# Local reproduction and experiment inventory

This investigation used the repository's private Max fixture transport. It did not install the UI prototypes into the normal Max profile. The production generated script was read to derive test controls; it was not rewritten.

## Locations

- One-time launcher, source-derived prototype generator and recipes: `_local/maintenance/ui-layout-lab-2026-10-02/`.
- Running fixture: `build/mesh-integration-2026-10-02/ui-layer-status-layout-lab2/`.
- Test Max window: **Cyrus_UI_Layout_Lab.max**. The artist window is **SaveSelect 2.max**.
- Research outputs kept with repository documentation: this directory's `evidence/` files. The one-time harness, generated prototype scripts, SDK binaries and `.max` scene remain local/ignored; their checksums are recorded in the manifest. A clean Git clone alone does not contain that harness.

The saved lab `.max` file was written immediately after fixture setup, before later Qt/native test objects and prototype settings were added. Opening that file alone does not install or reopen the prototypes.

## Recipe order used

1. `launch.py` creates an exclusive private startup/config/plugin directory. It copies the exact native binaries, SDK QtObjectDemo and a generated-script derivative with logging at existing layout writes. It fails if the output directory already exists.
2. `baseline.ms` runs `tools/ui-tests/setup.ms`, the existing `open-timing.ms`, and the complete warmed path of `diagnose-selected.ms`. It saves control counts and trace output.
3. `read-trace.ms` snapshots accumulated layout events. A Computer Use click collapsed the already constructed Grass layer; its height/width event sequence is in `interaction-layout-trace.json`.
4. `compare-hosts.ms` mounts the six unchanged production factories in plain and nested floaters, alternating their order for five passes. It records control counts and model integrity, then leaves a flat editor for inspection.
5. `make-prototypes.py` derives six named test factories and a flat scripted object from the production definitions. It exposes their original initialization as an explicit refresh method; the existing engine and parameter handlers remain in use. It preserves Diversity's original expanded height across rebinding.
6. `native-flat-test.ms` mounts source-derived rollouts directly in the command panel. The final version selects Modify once per trial. An initial harness version unnecessarily called `setCurrentObject()` too, doubling initialization; those earlier timings are excluded from the report. Final records show six initialization calls per trial.
7. `qt-reference.ms` loads Autodesk's existing SDK sample from the private plugin folder and records its loaded module path. Final timing also uses only one Modify selection per trial.
8. `shared-editor.ms` creates one set of six source-derived controls. Thirty switches exercise ten real Cyrus owners with distinct values and diversity modes. It asserts stable rollout handles, correct values and unchanged preview build/dirty state.
9. Computer Use entered **137** into Grass's Count spinner and pressed Enter. `check-real-edit.ms` verifies Grass 137, Leaves 200, and correct values after switching away/back. This is an explicit input test; rerunning the check without the input will correctly fail.
10. `qt-pilot.ms` runs `qt-pilot.py` through Max's Python API. The pilot binds Collision/Relax controls to existing layers, checks owner routing and model Undo, and emits a separate receipt. `qt-layout-check.ms` runs the three-width/collapse checks. Python test success was established by the emitted JSON and assertions, not merely by the transport's `SUCCESS` response.

The private transport is invoked from the repository root, for example:

```powershell
python tools/performance/mesh_integration/request.py --run ui-layer-status-layout-lab2 _local/maintenance/ui-layout-lab-2026-10-02/compare-hosts.ms --timeout 55
```

Recipes depend on the fixture globals and ordering above. They deliberately fail outside the private fixture. They are investigative scripts, not a general-purpose public automation API.

To start a completely fresh replication, assign a new exclusive fixture name in the local launcher and update the two Python fixture-name guards consistently. Do not remove or reuse an active run directory. Verify `ready.json` and `identity.json` before submitting recipes. The original helper uses `build/viewport-round2-2026-10-01/desktop.ini` and local SDK/native build paths; those local prerequisites must exist.

## Interpretation limits

Measurements use Max's current main UI thread. They do not measure paint completion, and the full artist scene was not used for this UI comparison. The floater, command panel, reusable editor and one-section Qt pilot are different hosts/workloads; the report labels these differences. No Max 2026, mixed-DPI, memory, production lifecycle or complete editor throughput result is claimed.

The private test tools encountered and corrected fixture-only issues: an exact source anchor mismatch before launch, MAXScript global binding/scoping mistakes, a missing scripted-object creation tool, and an invalid class-ID reporting expression. No test crash or artist-scene modification was observed. Only the final successful receipts are summarized; per-request recipe copies remain in the local fixture directory.

The Qt prototype has no automatic external Undo/selection/deletion notification adapter. Its Undo test restores model data and then explicitly refreshes the view. The two displayed prototype editors also do not synchronize each other's values automatically. These are required production integration tasks, not completed behavior.
