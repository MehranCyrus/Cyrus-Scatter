# Development test delivery — 7 October 2026

This is the matching **0.73.0** approved-layout candidate. Controlled Max 2027 campaigns pass, but the first cold container Undo history remains unresolved. This is not publication readiness. The earlier 0.73 installers do not contain this exact script/native pair.

| Delivery | Current local artifact | Qualification |
| --- | --- | --- |
| Scatter / Max 2027 | [CyrusScatter-0.73.0-Max2027.mzp](../../dist/Full_Qualification_0.73_2026-10-07/Max2027/CyrusScatter-0.73.0-Max2027.mzp) | Matching SDK/native, scripted, pointer, heavy-scene and Corona campaigns; known cold Undo finding |
| Analyzer / Max 2027 | [CyrusSurfaceAnalyzer-0.14-Max2027.mzp](../../dist/Full_Qualification_0.73_2026-10-07/Max2027/CyrusSurfaceAnalyzer-0.14-Max2027.mzp) | Matching native suite and current Scatter assignment/playback integration |
| MCP / Python 3.11 Windows | [Offline package instructions](../../dist/Full_Qualification_0.73_2026-10-07/CyrusMCP-0.73.0/README.md) | 29 pinned wheels, fresh hash-verified offline install, 22 source/host/wheel files equivalent, 12 tools / seven resources |
| Max 2026 | [SDK-only packages](../../dist/Full_Qualification_0.73_2026-10-07/Max2026/START_HERE.txt) | Matching SDK/native builds; no Max 2026 runtime qualification |

Save work, run the appropriate Scatter MZP, and restart Max before opening the new test scenes. Run the matching Analyzer MZP for Analyzer features. A new script with an older loaded DLL is not a valid test. Use copies while the cold Undo issue is open. No package was installed into the normal artist profile by this campaign.

The [build manifest](../../dist/Full_Qualification_0.73_2026-10-07/BUILD.json) contains every archived entry hash, runtime boundaries and `publication_ready: false`. Scatter Max 2027 archive SHA-256 is `a852849e9033b89d07d5bed9a0ed7e366d3bce13b1212a47b992e4e53000794b`; Analyzer Max 2027 is `7a473fa9911ec539d528794475c9a3c23589c13b6e6f0648e736bd588a3b0bfc`. The final MCP wheel is `a313ce89b9bac6254409e110c99a34ae86e3405b693107afc47a5ba4a4e6fd2d`. The folder named `CyrusMCP-0.73.0-intermediate` preserves an earlier candidate and is not this delivery.

The full generated script hash is `15390e733aac8a02433bfbc938f61fbe95f7f41eb35102baedf100dfe6c1a268`; the first-line payload fingerprint intentionally differs. Scene/render and tracked/untracked source identities are recorded in [the final snapshot](evidence/current-snapshot.json). Binaries, installers and artist scenes stay in ignored local folders rather than the Git documentation evidence.

Open the [garden](<../../Test Scene/Cyrus_073_Qualification/Cyrus_073_Heavy_Garden.max>) for the five-layer/eight-set workflow and curved painted flowers, or the [100k field](<../../Test Scene/Cyrus_073_Qualification/Cyrus_073_100k_Stress_Field.max>) for controlled load testing. The [artist guide](ARTIST_GUIDE.md) explains their initial Manual/Point Cloud settings and the stress scene's disabled exact render. The supplied original is unchanged.

Read [results](RESULTS.md), [measured performance](PERFORMANCE.md) and [next acceptance loops](ROADMAP.md) before interpreting this as a final product. Seven original material maps, large Proxy draw cost, first cold Undo, full DPI/docking/long-session coverage, commercial licensing and trained reference-image ML remain separate work.
