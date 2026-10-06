# Max 2027 installer follow-up

6 October 2026. Created after the runtime campaign, in response to the request for an installer. This packages the exact tested `final03` Scatter script and native binaries. Runtime behavior and serialization are unchanged; installer help now describes the floating editor instead of the previous command-panel layer stack.

## Files and use

The local delivery folder is `dist/live-runtime-0.7.1-20261006/`:

- [CyrusScatter-0.7.1-Max2027.mzp](../../dist/live-runtime-0.7.1-20261006/CyrusScatter-0.7.1-Max2027.mzp)
- [CyrusSurfaceAnalyzer-0.14-Max2027.mzp](../../dist/live-runtime-0.7.1-20261006/CyrusSurfaceAnalyzer-0.14-Max2027.mzp), the matching companion for courtyard/Analyzer features.
- [START_HERE.txt](../../dist/live-runtime-0.7.1-20261006/START_HERE.txt) and [build manifest](package-evidence/BUILD.json).

1. Save current work and use an empty Max 2027 scene for installation.
2. Choose **Scripting > Run Script** and run the Scatter MZP. Run the matching Analyzer MZP for the supplied courtyard.
3. Close and restart Max. The installer registers the matching files for the next startup; it does not reload the new script into the old running DLLs.
4. Reopen a copy of the courtyard scene. Select Cyrus Scatter and use **Modify > Layer Manager > select a layer > Edit layer...**.

The version caption is still **0.7.1**. The script SHA-256 is `c3f0b693a3854e9d11077bdea739469290e9a8a6e45f82ba44f38c6a1b486c8f`; the installed Scatter native folder is `bin-max2027-01e8f6e316b7`. MZP hashes and all payload hashes are recorded in the build manifest and adjacent `.sha256` files.

## Verification and boundaries

Both real MZPs were executed through Max's package reader in a disposable profile. All installed scripts, startup files, macros and native binaries matched their package manifests. A fresh process loaded both products automatically from their installed locations, verified all five native module paths, reopened the copied courtyard with five logical layers/eight populations, and opened the floating editor's Spacing page. See [installation receipt](package-evidence/INSTALLATION_VERIFIED.json) and [evidence index](package-evidence/index.json).

The first restart fixture compared different Windows slash conventions; the fixture was corrected and rerun. An intermediate startup had no completion receipt. Max subsequently showed Startup Failure Detection, and **Continue Without Restore** was selected. No factory reset was performed. The final explicit successful restart is the evidence used here; failed/incomplete attempts are not counted as passes.

All private test processes exited. The 28 protected installation/scene files in this follow-up's snapshot stayed byte-identical, including the artist's installed 0.7.0 files and both supplied scene originals. The normal Max session was not installed into, restarted or closed. No commit or push was performed.

These are Max 2027 development packages. The [runtime limitations](RESULTS.md) remain, including tiny-coordinate Brush BR-01 and unqualified host/renderer combinations. MCP/Automation is a separate installation and is not upgraded by these MZPs. No licensing experiment was enabled.

Reproduce packaging with `python tools/procedural_lab/package_live_runtime.py` while the pinned local qualification artifacts are present. The builder refuses a different script/native identity and uses the ordinary package builder's licensing-marker and ZIP/payload checks.
