# Release and saved-data versioning

| Domain | Current value | Meaning |
| --- | --- | --- |
| Scatter UI | 0.79.6 | Current source development label |
| Scatter native/package | 0.79.6 source; 0.79.5 last package | Build metadata does not certify a new installer |
| Saved MAXScript schema | 56 | Typed distance storage; explicit immediately preceding schema-55 migration |
| Calculation model | CyrusUnified1 | Current procedural model |
| Surface Analyzer | 0.14 | Independently versioned product |
| MCP package / closed plan | 0.73.0 / 0.73 | Automation contract, not the Scatter UI version |

**Reserve 1.0 for publication readiness.** Earlier artifacts labeled 1.0.x, 1.1.x and 1.2.x were development checkpoints, later relabeled 0.7 onward. A larger-looking historical version is not a newer supported release.

Current 0.79.6 source and bounded Max 2026/2027 evidence are recorded in the [foundation correction handoff](Foundation_0.79.6_2026-10-12/README.md). It adds typed distances and migration from schema 55 without changing existing saved parameter types. Earlier model-set/stroke formats remain rejected. The last packaged delivery is the 0.79.5 creation correction. The older metadata-only and team-pilot notes below remain historical.

0.79 begins the [offline team licensing pilot](licensing/ROADMAP.md#079-offline-team-pilot): owner-issued licenses, 30 days from issuance, creation/editing locked without valid authority, and existing scenes loadable/renderable. The initial version bump changes no enforcement or saved format. The subsequent [coding loop](licensing/TEAM_PILOT_0.79_2026-10-11.md) implements the team pilot and records fresh matched Max 2026/2027 builds. Do not relabel the earlier 0.78.3 artifacts as 0.79.

Version-bump checks on 11 October 2026 passed: generator reproducibility/integration, approved layout guards, four catalog/package-version tests, package metadata consistency and `git diff --check`. The integration receipt is local at `build/licensing-079-preflight-20261011-01/generated/generated-check.json`. No 0.79 native build, Max runtime test, package, artist installation or new licensing-runtime qualification was performed in this metadata/plan update.

Preserve internal class IDs and registration names. A caption or matching schema number is not enough to establish a coherent installation: record exact script/payload fingerprint, native hashes, loaded paths and package identity. Never combine new scripts with stale loaded native modules.

0.78 deliberately changes the saved schema and native brush payload. Older development setups and stroke documents are rejected without conversion or compatibility evaluation. Start new scenes/setups; preserve original files and the matching old build. General receiver-local sampling and stable Edit identities remain part of the current engine.

Before delivery, regenerate UI, run appropriate offline/native/host checks, package the tested pair, verify archive contents and hashes, and record remaining gates. Installer execution and host restart need their own qualification. SDK coverage does not certify Max runtime. Use [current acceptance](BACKLOG.md), [build instructions](Max_2027_Installation.md), and [the latest matched package receipts](Container_and_Radius_0.78.3_2026-10-10/README.md). The 0.78 vector payload and script schema are deliberately new. The independent Analyzer freshness format remains unchanged; older Analyzer guides need one explicit Analyze. The dated manifest identifies the exact payload.

0.78.2 removed repeated brush panel layout and refreshed borders from Painter input callbacks. 0.78.3 preserves those changes, corrects cursor radius, repairs source-container selection, adds collection switches and unfolds Painting controls. Schema 55 and the vector payload remain unchanged. The new source-container flag defaults off, including in older saved rectangles without that flag. Separate Max 2026 and 2027 binaries/installers are required.

- **0.79.1**: Point identities and direct spline assignment, separate source-container section, accessible source/falloff controls and area-selection fixes. Retains schema 55 and the 0.79 team licensing authority; Analyzer 0.14 and MCP 0.73.0 are independently versioned. See the [focused qualification](Point_Workflow_0.79.1_2026-10-11/README.md).
