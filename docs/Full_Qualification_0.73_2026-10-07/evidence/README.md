# Evidence inventory

The [index](index.json) identifies allowlisted receipts and their hashes. The [snapshot](current-snapshot.json) records the exact branch/HEAD, tracked and untracked file hashes, changes since the starting inventory, protected licensing identities, supplied original and three saved test scenes/render images. The native/MCP package manifests identify delivery contents.

Passing controlled receipts and failing/intermediate observations are preserved separately. In particular, `real-assets/pointer-container-first-redo-failed.json` records successful Move/Undo but failed Redo; its `passed` member describes the earlier Move check, not the whole gesture. `redo_passed: false` remains visible. The later controlled receipt does not erase that finding. Likewise the unsettled Brush baseline does not qualify Manual idle.

This inventory excludes IPC connection descriptors, authentication, journals, full private traces, vendor decompilation listings, native binaries and scene bytes. Raw measurements/fixtures remain in the ignored test workspace. A source fingerprint proves identity, not correctness, every feature combination or publication readiness.

See [results](../RESULTS.md) for interpretation and [performance](../PERFORMANCE.md) for measurement limits. All final owned hosts were stopped; the normal artist Max process was not operated.
