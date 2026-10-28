# Cyrus Scatter native engine and UI

For interaction changes, preserve the [artist-endorsed performance baseline](../docs/PERFORMANCE_BASELINE.md). Artistic guide response, shared preparation, workload-aware CPU execution and held-input presentation are separate boundaries; compare visible results and work counters before retaining an optimization.

Current package **0.87.6**, saved schema **65**, model **CyrusUnified2**. [Delivery and scoped evidence](../docs/plans/ui-settings-0876-20261028/DELIVERY.md) cover Point source repair, clearer painting/preview controls and contextual panel layout. Max 2027 has runtime UI checks and 23 focused native suites; Max 2024/2026 have separate compiled packages without runtime tests. Interactions **15**, source transform/Undo **2/2**, Edit capability/storage **4/3**, recipe **9** and Scene preset metadata **1** remain. The 0.87.5.6 interaction algorithms and 0.87.5.1 Library implementation remain their respective baselines. Independent products, licensing and registration identities are unchanged.

Historical **0.86.9.2** / scene **59** evidence remains in [its delivery](../docs/plans/edit-instances/DELIVERY_08692.md). Its three-host installer and native Edit 2 scope do not qualify the current Max 2027-only package.

- [Current artist workflow](../docs/ARTIST_GUIDE.md)
- [Architecture and source ownership](../docs/ARCHITECTURE.md)
- [Layout, Analyzer and falloff details](../docs/LAYOUT_AND_FALLOFF.md)
- [Build/install instructions](../docs/Max_2027_Installation.md)
- [Current limits and work](../docs/BACKLOG.md)
- [Latest qualification](../docs/plans/ui-settings-0876-20261028/QUALIFICATION.json)

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
