# Maintained website content

The 29 October 2026 edition follows the **Scatter 0.87.6.7 testing release**, with 379 semantic
controls, 14 plugin sections and 37 capability families. Surface Analyzer
0.14.2, optional plant content 0.86.7 and the packaged MCP 0.73.0 foundation
retain their independent versions and qualification.

`release.json` identifies the documented edition and the exact approved EXE.
Production builds verify its size, producer receipt and SHA-256 before staging
it under `downloads/`. The full static upload ZIP includes that verified file;
no optional plant-content archive or native plugin modules are exposed separately.

`guide-chapters.json` contains curated artist text. It covers instance selection,
shared setup controls, artistic Bend/Trim, independent root hiding, source-aware
Edit, Scene presets and the Library. MCP development extensions are labeled
separately from its packaged release and do not grant general authoring access.

`control-explanations.json` maps every current semantic key, including Multiple
Scatters. `source-manifest.json` records reviewed source hashes. Its
artistWorkflowVersion is the historical poster-reading baseline, not the current
product version. Historical images and changelog entries retain their dates.

Run `npm run docs:sync`, `npm run docs:check` and `npm run build` from website/.
Public content excludes raw Markdown, implementation bodies and internal reports.
Local source updates, a built static site, packaging and live hosting are separate.
See [current validation](../verification/UPLOAD_08767_20261029.md).

The **0.87.6.7** scoped delivery is complete. Its own receipt records the matching
Max 2027 runtime checks and build-only Max 2024/2026 payloads. The earlier
website-only preview receipt remains historical; current packaging evidence is separate.
