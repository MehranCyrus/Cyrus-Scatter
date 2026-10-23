# Cyrus Scatter native engine and UI

Current development/package version **0.86.9.2**, saved schema **59**, model **CyrusUnified2**. The [current delivery](../docs/plans/edit-instances/DELIVERY_08692.md) adds procedural-map previews/drop targets, restored native column ownership and live Edit movement. One EXE contains matched Max 2024/2026/2027 packages with Analyzer 0.14.2; **only Max 2027 was tested for this patch, while older hosts are built and untested**. Native Edit capability/storage remains 2; preserve original scenes and save upgraded copies from older readers. Schema 58 has an explicit Undoable upgrade; earlier development schemas remain unsupported. Ordinary development remains Max 2027 unless another host is explicitly requested. Licensing and internal registration identities are unchanged.

- [Current artist workflow](../docs/ARTIST_GUIDE.md)
- [Architecture and source ownership](../docs/ARCHITECTURE.md)
- [Layout, Analyzer and falloff details](../docs/LAYOUT_AND_FALLOFF.md)
- [Build/install instructions](../docs/Max_2027_Installation.md)
- [Current limits and work](../docs/BACKLOG.md)
- [Latest qualification](../docs/plans/edit-instances/DELIVERY_08692.md)

## Development

Edit `tools/ui/templates/unified-core.ms` and the relevant generator modules. From this directory:

```powershell
node tools/ui/generate.cjs
node tools/ui/generate.cjs --check
node tools/ui/approved-layout.test.cjs
```

The generated `scripts/AminScatterObject.ms` must match its sources. Native calculation lives under `src/` and `include/`; tests under `tests/`. The four installed Scatter modules are `AminScatter.dlx`, `CyrusScatterEdit.dlm`, `CyrusBrush.dlx` and `CyrusBrushStorage.dlh`. Use matching script/native packages and restart Max after installation.

Layers own receivers, models and generation settings. Optional Paint Areas own receiver-bound vector coverage. Source containers organize models, not receivers. Manual pending edits preserve the last complete publication; display limits do not reduce the accepted output. See the current guides for stable receiver streams, Edit guards and vector painting limits.

Earlier numbered feature notes and the old 0.15/0.23 README are preserved in Git history. Their migration, installer, late-Relax and render-update claims are not current contracts.
