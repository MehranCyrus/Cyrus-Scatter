# Maintained website content

The 23 October 2026 website edition follows **Scatter 0.86.9.2 / schema 59**. `guide-chapters.json` supplies five curated customer-facing chapters, rendered into HTML/search data. Current wording adds Viewport memory controls, source-aware Edit history and its Copy limitation, live Edit handles, procedural map previews/drop and restored native column sizing. Max 2027 is tested; included Max 2024/2026 builds are untested for this patch. Original Paint, independent model clearance, layer-owned Relax and optional shared content remain. Analyzer and MCP retain their independent versions and qualification limits.

`release.json` is the public download record: exact EXE filename, byte count, SHA-256, date and supported hosts. `src/content/release.ts` resolves its relative download path for root and subfolder hosting. `tools/stage_release.py` checks the matching local release artifact before placing **only the main EXE** in the production download folder. Content ZIPs and MZPs are excluded from the website upload.

`source-manifest.json` records reviewed source fingerprints. The changed Artist Guide, MCP guide, architecture, version policy, capability matrix and library workflow were reviewed against the current delivery; the 0.86.8, 0.86.8.1 and 0.86.8.2 reports are enrolled as supporting evidence. This website update does not refresh the separate knowledge index or establish new Max qualification.

`changelog.json` preserves earlier chronology and adds 0.86.8.7, 0.86.9, withdrawn 0.86.9.1 and corrected 0.86.9.2. Internal evidence paths are stripped from public data. `control-explanations.json` includes all eight source-policy controls and the corrected shared Relax distance. `gallery-reading-notes.json` preserves the historical 0.78.3 edition of the 19 concept posters.

Run `npm run docs:sync`, `npm run docs:check`, then `npm run package:cpanel`. Only `src/content/reference.json` is generated from the curated content. No raw Markdown or implementation source is published. The production build requires the exact approved EXE in the local release directory; a missing or mismatched artifact fails the build rather than publishing a broken download.

Local builds and upload packages are distinct from a published website. Historical receipts retain their original scope.
