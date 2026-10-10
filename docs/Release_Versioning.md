# Release and saved-data versioning

| Domain | Current value | Meaning |
| --- | --- | --- |
| Scatter UI | 0.78.1 | Artist-facing development label |
| Scatter native/package | 0.78.1 | Build and package metadata |
| Saved MAXScript schema | 55 | Serialized object format; independent of UI caption |
| Calculation model | CyrusUnified1 | Current procedural model |
| Surface Analyzer | 0.14 | Independently versioned product |
| MCP package / closed plan | 0.73.0 / 0.73 | Automation contract, not the Scatter UI version |

**Reserve 1.0 for publication readiness.** Earlier artifacts labeled 1.0.x, 1.1.x and 1.2.x were development checkpoints, later relabeled 0.7 onward. A larger-looking historical version is not a newer supported release.

Preserve internal class IDs and registration names. A caption or matching schema number is not enough to establish a coherent installation: record exact script/payload fingerprint, native hashes, loaded paths and package identity. Never combine new scripts with stale loaded native modules.

0.78 deliberately changes the saved schema and native brush payload. Older development setups and stroke documents are rejected without conversion or compatibility evaluation. Start new scenes/setups; preserve original files and the matching old build. General receiver-local sampling and stable Edit identities remain part of the current engine.

Before delivery, regenerate UI, run appropriate offline/native/host checks, package the tested pair, verify archive contents and hashes, and record remaining gates. Installer execution and host restart need their own qualification. SDK coverage does not certify Max runtime. Use [current acceptance](BACKLOG.md), [build instructions](Max_2027_Installation.md), and [the latest matched package receipts](Brush_Start_0.78.1_2026-10-10/README.md). The 0.78 vector payload and script schema are deliberately new. The independent Analyzer freshness format remains unchanged; older Analyzer guides need one explicit Analyze. The dated manifest identifies the exact payload.

0.78.1 fixes brush-session UI binding and responsive control bounds. It keeps schema 55 and the same vector payload. Separate Max 2026 and 2027 binaries/installers are required.
