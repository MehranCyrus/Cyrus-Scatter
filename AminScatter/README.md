# Cyrus Scatter native engine and UI

Current development version **0.75.0**, displayed as **0.75**; saved schema **54**, model **CyrusUnified1**. The public name is Cyrus Scatter; internal AminScatter identifiers remain for registration.

- [Current artist workflow](../docs/ARTIST_GUIDE.md)
- [Architecture and source ownership](../docs/ARCHITECTURE.md)
- [Layout, Analyzer and falloff details](../docs/LAYOUT_AND_FALLOFF.md)
- [Build/install instructions](../docs/Max_2027_Installation.md)
- [Current limits and work](../docs/BACKLOG.md)
- [Exact qualification](../docs/System_Qualification_0.75_2026-10-09/README.md)

## Development

Edit `tools/ui/templates/unified-core.ms` and the relevant generator modules. From this directory:

```powershell
node tools/ui/generate.cjs
node tools/ui/generate.cjs --check
node tools/ui/approved-layout.test.cjs
```

The generated `scripts/AminScatterObject.ms` must match its sources. Native calculation lives under `src/` and `include/`; tests under `tests/`. The four installed Scatter modules are `AminScatter.dlx`, `CyrusScatterEdit.dlm`, `CyrusBrush.dlx` and `CyrusBrushStorage.dlh`. Use matching script/native packages and restart Max after installation.

Layers own receivers, models and generation settings. Optional Paint Areas own receiver-bound coverage. Source containers organize models, not receivers. Manual pending edits preserve the last complete publication; display limits do not reduce the accepted output. See the current guides for older supported sets, stable Edit guards and incomplete receiver-add stability.

Earlier numbered feature notes and the old 0.15/0.23 README are preserved in Git history. Their migration, installer, late-Relax and render-update claims are not current contracts.
