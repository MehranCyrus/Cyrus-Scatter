# Garden interaction investigation — 25 October 2026

These scripts create/read owned Max 2027 profiles and derivative scenes. They do not implement production contact integration. See the [organized plan](../../../docs/plans/scatter-interactions-garden-20261025/README.md).

## Reproduce

Run from the repository root with the documented Python runtime. Output directories must be new folders under `build/`.

```powershell
python CyrusVegetationLab/experiments/garden-contact/launch.py --output build/my-garden-assets --script CyrusVegetationLab/experiments/garden-contact/asset_probe_host.py --timeout 360
python CyrusVegetationLab/experiments/garden-contact/launch.py --output build/my-garden-baseline --script CyrusVegetationLab/experiments/garden-contact/build_garden_host.py --timeout 360
python CyrusVegetationLab/experiments/garden-contact/analyze_garden.py build/my-garden-baseline
```

The launcher uses exact previously verified local inputs:

- Extracted 0.86.9.2 Max 2027 payload at `build/garden-investigation-20261025-01/scatter-payload/`.
- Source-inspection module at `build/vegetation-root-plugin-20261025-03/CyrusStemInspect.dlx`.
- Content/rock files pinned in `asset-inputs.json` and the plan's `ROCK_INPUTS.json`.

These ignored dependencies must exist; this is a local reproducibility receipt, not a portable installer. No new binaries are built here. `reopen_garden_host.py` deliberately targets the exact final baseline `build/garden-baseline-host-20261025-03/` for an independent cold reload and five warm cached reads.

`analyze_garden.py` measures only a Python rest-AABB grid over the exported real placements and compares each of 41 shifted-hero queries with brute force. It does not run the contact fitter, model swept/reachable deformation bounds or measure Max input latency. `record_payload_96_bytes` excludes all other allocation classes.

The final scene uses static conservative XY hull exclusions and diagnostic layer colors. Moving a stone does not update those hulls or bend plants. A previous Scanline attempt is retained separately because its materials rendered black. Do not treat the final viewport capture as a beauty render.

The scripts quit only their owned Max process. They never install packages, overwrite source assets or restart artist sessions. The launcher verifies that the original artist INI is byte-identical after each completed run.
