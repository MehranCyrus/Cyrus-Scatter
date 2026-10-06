# Matching 0.72 development packages

6 October 2026. Display label **0.72**; package/native metadata **0.72.0**; scene serialization **53**; Analyzer remains **0.14**. The packages contain the exact generated script and native files pinned by the final receipts. MZPs and scenes remain local/ignored; Git backs up source, build tools, documents and curated evidence.

## Max 2027

Use [CyrusScatter-0.72.0-Max2027.mzp](../../dist/integrated-ui-0.72-20261006/Max2027/CyrusScatter-0.72.0-Max2027.mzp). For the Analyzer features/courtyard dependency also use [CyrusSurfaceAnalyzer-0.14-Max2027.mzp](../../dist/integrated-ui-0.72-20261006/Max2027/CyrusSurfaceAnalyzer-0.14-Max2027.mzp). See the local [BUILD.json](../../dist/integrated-ui-0.72-20261006/Max2027/BUILD.json) and [START_HERE.txt](../../dist/integrated-ui-0.72-20261006/Max2027/START_HERE.txt).

1. Save your work.
2. In Max 2027, choose **Scripting > Run Script** and select the Scatter MZP; run the Analyzer MZP if needed.
3. Close and **restart Max** so the matching native modules load before the new script.
4. Select Scatter, then **Modify > Layer Manager > select a layer**. Its settings appear below. **Edit layer in window...** is optional; **Diagnostics** starts/stops/saves local engineering reports.

Do not `fileIn` the loose new script into a session that still has older native modules loaded. Opening a `.max` scene does not install or select this version. This campaign did not change your normal Max installation.

## Qualification and identities

| Package | SHA-256 |
| --- | --- |
| Scatter Max 2027 | `e64891400598a089c9108e412bae07061bcefbf68b4cb5f041e2a6fa3ec7749a` |
| Analyzer Max 2027 | `0813f7daaebe0235db6d15197c140e2dce5198801a49bdf70ff2db18363d384b` |
| Scatter Max 2026 | `04f1e0b61b4cd64563d4b92f96eb149c1bd5fdfaf091725de7aea7ba5ceb37b9` |
| Analyzer Max 2026 | `70db4d82a901f246e7295a3a3bd6da0484a11cc49c4f2d0658f74c67395f7a8c` |

Max 2027 passes the private control/API, headless playback, integrated idle, retained-buffer and actual floating-Corona lifecycle checks described in [RESULTS.md](RESULTS.md). ZIP/payload hashes, version/host guards and development-license marker exclusion are verified. The 0.72 installer itself was not run: earlier private installer/restart evidence belongs to 0.7.1. Artist pointer/DPI and extended renderer qualification remain separate.

[Max 2026 packages](../../dist/integrated-ui-0.72-20261006/Max2026/START_HERE.txt) are SDK/native-test candidates only. Max 2026 is not installed here, so its runtime/installation is unqualified. Do not equate those build passes with host support.

MCP/Automation is separately installed and is not upgraded by these MZPs. Direct Scatter diagnostics works without it. No trained ML or licensing enforcement is enabled by these packages.

## Reproduce from frozen source

The build is pinned to MSVC 14.38.33130 and Windows SDK 10.0.19041.0. Representative commands, from the repository root:

Generate inside `AminScatter/`, then run verification from the repository root:

```powershell
Push-Location AminScatter
node tools/ui/generate.cjs
Pop-Location
python tools/procedural_lab/check_generated.py
python tools/procedural_lab/build_feature_catalog.py
python tools/procedural_lab/offline_build.py --year 2027 --output build/ui-072-20261006/native-max2027
python tools/procedural_lab/offline_build.py --year 2026 --output build/ui-072-20261006/native-max2026
python tools/procedural_lab/test_playback.py --binary-dir build/ui-072-20261006/native-max2027 --analyzer-dir build/playback-20261006/analyzer-max2027 --output build/playback-20261006/ui072-regression05
```

The final private host was launched with `ui_072_qualification.py --run controls10 --native build/ui-072-20261006/native-max2027 --analyzer build/playback-20261006/analyzer-max2027 --full --keep-open`. Against that same folder, sequentially run `live_idle_qualification.py --integrated`, `qualify_ui_metadata_072.py`, then `corona_072_qualification.py`. Each takes the private folder as its positional argument. Use a new run ID/output folder for a new campaign; never overwrite a dated receipt or target an artist process.

`package_ui_072.py --qualified build/mcp-qualification/procedural07-ui-072-controls10 --playback build/playback-20261006/ui072-regression05 --output dist/integrated-ui-0.72-20261006` requires passing frozen receipts and matching identities before packaging. `collect_ui_072_evidence.py` validates/copies concise receipts into a new evidence directory; it does not run tests. The final owned private host was closed after qualification. No binaries, SDKs or artist assets are added to Git.
