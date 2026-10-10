# Release and saved-data versioning

| Domain | Current value | Meaning |
| --- | --- | --- |
| Scatter UI | 0.76 | Artist-facing development label |
| Scatter native/package | 0.76.0 | Build and package metadata |
| Saved MAXScript schema | 54 | Serialized object format; independent of UI caption |
| Calculation model | CyrusUnified1 | Current procedural model |
| Surface Analyzer | 0.14 | Independently versioned product |
| MCP package / closed plan | 0.73.0 / 0.73 | Automation contract, not the Scatter UI version |

**Reserve 1.0 for publication readiness.** Earlier artifacts labeled 1.0.x, 1.1.x and 1.2.x were development checkpoints, later relabeled 0.7 onward. A larger-looking historical version is not a newer supported release.

Preserve internal class IDs and registration names. A caption or matching schema number is not enough to establish a coherent installation: record exact script/payload fingerprint, native hashes, loaded paths and package identity. Never combine new scripts with stale loaded native modules.

Older 0.74 single/multi-set records remain readable within their tested cases, but the receiver-local sampler changes their first rebuilt placement. This is not a position-preserving migration. Old combined-sampler Edit/radius bindings are rejected explicitly instead of applying saved edits to different plants. Multi-set conversion remains unfinished. Retired unpublished scene/Edit/plan formats are not promised automatic migration. Preserve original scenes and matching old packages when testing another development build.

Before delivery, regenerate UI, run appropriate offline/native/host checks, package the tested pair, verify archive contents and hashes, and record remaining gates. Installer execution and host restart need their own qualification. SDK coverage does not certify Max runtime. Use [current acceptance](BACKLOG.md), [build instructions](Max_2027_Installation.md), and [the latest matched package receipt](Receiver_Stability_0.76_2026-10-10/PACKAGE.json). The 0.76 candidate preserves schema 54 and the prior Analyzer freshness state; older guides without that record require one explicit Analyze. The unchanged schema describes storage, not generation equivalence: receiver binding version 2 and receiver-local candidate IDs distinguish the new generation contract. The dated manifest identifies the actual payload.

Historical reports and package identities keep their original version labels. New work updates these current documents in place; it does not rewrite old measurements or create another competing version policy.
