# Cyrus Scatter native engine and UI

Current development/package version **0.86.6**, saved schema **58**, model **CyrusUnified1**. The [current Max 2027 delivery](../docs/plans/preset-gallery-improvements/DELIVERY_0866.md) qualifies surface painting and retains the corrected 0.86.5 library/Amount baseline within its recorded scope. Earlier 0.86.2 host deliveries remain separate. Licensing and internal registration identities are unchanged.

- [Current artist workflow](../docs/ARTIST_GUIDE.md)
- [Architecture and source ownership](../docs/ARCHITECTURE.md)
- [Layout, Analyzer and falloff details](../docs/LAYOUT_AND_FALLOFF.md)
- [Build/install instructions](../docs/Max_2027_Installation.md)
- [Current limits and work](../docs/BACKLOG.md)
- [Latest qualification](../docs/plans/preset-gallery-improvements/DELIVERY_0866.md)

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
