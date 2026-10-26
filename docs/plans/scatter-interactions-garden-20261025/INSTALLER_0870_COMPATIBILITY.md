# CyrusScatter 0.87.0 — three-host installer build

25 October 2026. The user explicitly requested an EXE for Max **2024, 2026 and 2027**, with **no further testing or installation**.

[CyrusScatter-0.87.0-Setup.exe](../../../dist/CyrusScatter-0.87.0-20261025-Compatibility/CyrusScatter-0.87.0-Setup.exe)

Save work and close the target Max versions. Run the EXE, select the desired versions and choose **Install / Update**. Reopen Max afterwards. The installer reuses existing library content and leaves the independently installed Surface Analyzer in place.

The version remains **0.87.0**: this packages the existing feature set and saved contracts rather than adding a feature. Max 2024 and 2026 have distinct SDK/native and matching managed builds. Both receipts contain only configure/build stages, `BUILD_TESTING=OFF`, `tests_run=false` and `host_launched=false`. These new builds are **untested**. The Max 2027 MZP is byte-identical to the earlier r4 trial; its historical evidence is not new older-host qualification.

No automated tests, Max launches, installer execution, artist-profile changes, commits or pushes were performed for this request. Packaging retains normal producer, host-guard, archive and hash checks. This installer does not include the proposed general mesh-LOD feature, which remains research only.

EXE SHA-256: `46fb5b935fc4345328bd0f5a9f494964a96066ed8c95d40bbf4a9d90b67c1be3`.

The [output folder](../../../dist/CyrusScatter-0.87.0-20261025-Compatibility/) contains the EXE, three individual MZPs, hashes, managed/package build receipts and `BUILD_ONLY_RECEIPT.json`. New native producers are under `build/interactions087-compatibility-20261025-01/max2024/` and `max2026/`; unchanged Max 2027 uses producer 06. `tools/procedural_lab/interactions087/package_compatibility.py` assembles the delivery without invoking tests or Max. Preserve the earlier [r4 trial report](DELIVERY_0870.md) and its narrower qualification.
