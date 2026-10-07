# Matching development packages

Corrected packages: [dist/unified-0.73-selection-fix-20261006](../../dist/unified-0.73-selection-fix-20261006/). This build supersedes `unified-0.73-final-20261006` and the earlier `unified-0.73-20261006` package. The [selection correction report](../Container_Selection_Fix_0.73_2026-10-06/README.md) records the reproduced failure and earlier qualification gap. Nothing was installed in the normal Max profile. Entry hashes/provenance: [build record](../../dist/unified-0.73-selection-fix-20261006/BUILD.json), [copied evidence](evidence/packages.json).

| Component | Artifact | Qualification |
| --- | --- | --- |
| Max 2027 Scatter | [CyrusScatter-0.73.0-Max2027.mzp](../../dist/unified-0.73-selection-fix-20261006/Max2027/CyrusScatter-0.73.0-Max2027.mzp) | SDK/native and matching natural selection, host/UI/idle/cache/playback/MCP passes. |
| Max 2027 Analyzer | [CyrusSurfaceAnalyzer-0.14-Max2027.mzp](../../dist/unified-0.73-selection-fix-20261006/Max2027/CyrusSurfaceAnalyzer-0.14-Max2027.mzp) | Matching native, playback and assignment passes; algorithm/version unchanged. |
| Max 2026 Scatter | [CyrusScatter-0.73.0-Max2026.mzp](../../dist/unified-0.73-selection-fix-20261006/Max2026/CyrusScatter-0.73.0-Max2026.mzp) | SDK/native tests only; runtime unqualified. |
| Max 2026 Analyzer | [CyrusSurfaceAnalyzer-0.14-Max2026.mzp](../../dist/unified-0.73-selection-fix-20261006/Max2026/CyrusSurfaceAnalyzer-0.14-Max2026.mzp) | SDK/native tests only. |
| Separate MCP | [CyrusMCP-0.73.0](../../dist/unified-0.73-selection-fix-20261006/CyrusMCP-0.73.0/) / [instructions](../../CyrusMCP/README.md) | Unchanged, source-equivalent bundle; frozen Python/real stdio host passes; offline CPython 3.11 x64 wheels. Not needed for Scatter diagnostics. |

1. Save artist work, retain originals and start in a disposable scene/profile.
2. Use **Scripting > Run Script** on the matching Scatter `.mzp`. Run the matching Analyzer package for Analyzer features.
3. **Close and restart Max** before using the new script/native pair. A new script with an older loaded DLL is unsupported.
4. **Current 0.73/serialization-54 scenes remain supported by this correction.** Create a fresh Scatter setup only for older unpublished settings. Serialization 54/`CyrusUnified1` deliberately rejects retired settings, old Edit chunks and MCP plans. Max may still load ordinary geometry, but retired Scatter records remain blocked after re-save/reopen. The former courtyard demo is not converted automatically; preserve it and use its ordinary assets in a new setup.
5. Select a layer in Modify > Layer Manager. Source containers > **Create rectangle** selects an own pool automatically. Selecting the labelled rectangle opens its linked controls. [Artist guide](ARTIST_GUIDE.md).

MZPs contain no development transport/probes or licensing-test authority. Hashes prove identities, not installation in an artist profile. Pointer/DPI/actual Corona IR/Max 2026 runtime remain [gates](ROADMAP.md). Version 1.0 remains publication readiness.

[Reproduction/evidence](evidence/INDEX.md). `package_unified_073.py` requires the natural-selection regression as well as the broader campaigns, rejects changed inputs or existing native-package destinations and checks every ZIP entry. MCP manifests separately cover host files, source-equivalent wheel contents and pinned dependencies. The unchanged MCP bundle is copied and reverified for this correction; it is not installed into Max.
