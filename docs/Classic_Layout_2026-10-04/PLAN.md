# Restore the 0.64 layout on the current engine

User reference: the actual `dist/retained-mesh-0.64/CyrusScatter-0.64-Max2027.mzp`, inspected without installation. The 1.2.1 width-only patch was rejected because it retained fixed scrolling boxes.

- [x] Restore one flowing stack: Update, Surface Scatter, Viewport and Render, Layer Manager, then named layer rollouts.
- [x] Put selection, naming, visibility, enable, copy/remove and cached counts in the manager. Open each layer directly into its settings, including Brush and paint sets.
- [x] Fit inner containers to their contents and use the command panel for scrolling. Retain native automatic width layout and editor identities; avoid the old width timer and Win32 resize/paint workarounds.
- [x] Check actual Max expansion, collapse, height/width, scrolling and layer management. Verify UI navigation preserves placement/paint/display caches and feature ownership.
- [x] Package a separate UI patch with matching unchanged native binaries, update documentation and preserve historical evidence.

Generation, collision, Brush, render, Edit and MCP retain the current model. This is a layout restoration, not a rollback to the 0.64 engine or its old event/refresh behavior.

Completed in 1.2.2. See [the report](README.md), [artist guide](ARTIST_GUIDE.md), and exact [qualification/package manifest](evidence/MANIFEST.json). Max 2026 UI and other DPI configurations remain separate qualification work.
