"""Freeze 1.2.2 layout evidence; never rewrite earlier release measurements."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[2]
PROFILE = ROOT / 'build/cyrus-v1/hosts/classic-layout-check'
OUTPUT = ROOT / 'dist/classic-layout-1.2.2'
EVIDENCE = ROOT / 'docs/Classic_Layout_2026-10-04/evidence'
NATIVE = ('AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read(name):
    return json.loads((PROFILE / name).read_text(encoding='utf-8-sig'))


def main():
    source_path = ROOT / 'AminScatter/scripts/AminScatterObject.ms'
    source = source_path.read_bytes()
    loaded = read('loaded-identity.json')
    layout = read('classic-layout-acceptance.json')
    flow = read('classic-native-flow.json')
    manager = read('classic-manager-acceptance.json')
    features = read('layers-features.json')
    ownership = read('layers-first-acceptance.json')
    gesture = read('classic-ui-gesture.json')
    assert loaded['script_version'] == layout['version'] == manager['version'] == '1.2.2'
    assert layout['control_bounds_checks'] == 618 and layout['rollout_toggles'] == 52
    assert layout['retained_controls_and_caches'] and layout['main_body_width'] == 246
    assert flow['passed'] and len(flow['sections']) == 10
    assert all(manager[key] for key in ('selection_and_add_remove', 'expansion_restore',
                                      'closed_layer_child_restore', 'general_and_feature_ownership', 'cached_statistics'))
    assert features['independent_erase_history'] and features['manual_and_live']
    assert ownership['visibility_enable_copy_delete_undo'] and ownership['density_budget_shared']
    assert gesture['grass_open_flowers_closed'] and gesture['ten_sections_mounted'] and gesture['no_generation_paint_or_upload']
    assert (PROFILE / 'classic-campaign-stage.txt').read_text().strip() == 'PASS'
    # Final source was reloaded in the private host after the Undo fix. Every
    # published result must come from after that reload, with unchanged source.
    reload_recipe = max(PROFILE.glob('recipe-classic_layout_reload-*.ms'), key=lambda p: p.stat().st_mtime_ns)
    assert source_path.stat().st_mtime_ns <= reload_recipe.stat().st_mtime_ns
    names = ('classic-layout-prepared.json', 'loaded-identity.json', 'classic-layout-acceptance.json',
             'classic-native-flow.json', 'classic-manager-acceptance.json', 'layers-features.json',
             'layers-first-acceptance.json', 'classic-campaign-stage.txt', 'classic-ui-gesture.json')
    for name in names:
        assert (PROFILE / name).stat().st_mtime_ns >= reload_recipe.stat().st_mtime_ns, name
    packages = {}
    for year in (2026, 2027):
        path = OUTPUT / f'CyrusScatter-1.2.2-Max{year}.mzp'
        old = ROOT / f'dist/layers-first-1.2.0/CyrusScatter-1.2.0-Max{year}.mzp'
        with zipfile.ZipFile(path) as z, zipfile.ZipFile(old) as baseline:
            manifest = json.loads(z.read('manifest.json'))
            assert manifest['version'] == '1.2.2' and manifest['max_year'] == year
            assert z.read('CyrusScatter.ms') == source and z.testzip() is None
            for name, digest in manifest['files'].items():
                assert sha(z.read(name)) == digest
            for name in NATIVE:
                assert z.read(name) == baseline.read(name), f'Native changed: {year}/{name}'
            if year == 2027:
                for name, module_path in loaded['modules']:
                    assert Path(module_path).resolve().is_relative_to(PROFILE.resolve())
                    assert Path(module_path).read_bytes() == z.read(name)
            packages[str(year)] = dict(path=path.relative_to(ROOT).as_posix(),
                                       sha256=sha(path.read_bytes()), native_unchanged_from_1_2_0=True,
                                       manifest=manifest)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    for name in names:
        shutil.copy2(PROFILE / name, EVIDENCE / name)
    sources = [source_path, ROOT / 'tools/v1/package.py', ROOT / 'tools/v1/collect_classic_evidence.py',
               ROOT / 'tools/v1/layers_first_qualification.ms', ROOT / 'tools/v1/layers_features_fixture.ms']
    sources += list((ROOT / 'AminScatter/tools/ui').glob('*.cjs'))
    sources += list((ROOT / 'AminScatter/tools/ui/templates').glob('layers-*.ms'))
    sources += list((ROOT / 'tools/v1').glob('classic_*.ms'))
    receipt = dict(version='1.2.2', scope='Source-loaded private Max 2027 classic layout; default panel width',
                   last_source_reload=reload_recipe.relative_to(ROOT).as_posix(),
                   sources={p.relative_to(ROOT).as_posix(): sha(p.read_bytes()) for p in sorted(set(sources))},
                   packages=packages,
                   evidence={p.name: sha(p.read_bytes()) for p in EVIDENCE.iterdir() if p.name != 'MANIFEST.json'})
    (EVIDENCE / 'MANIFEST.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    shutil.copy2(ROOT / 'dist/layers-first-1.2.0/Cyrus_Scatter_1.2_Layers_Demo.max', OUTPUT)
    (OUTPUT / 'README.md').write_text(
        '# Cyrus Scatter 1.2.2\n\n'
        'Restores the 0.64 layout: Update, Surface Scatter, Viewport and Render, Layer Manager, '
        'then named layers. Open a layer to see its settings. Sections use the panel width and '
        'fit their contents; the command panel scrolls through the stack.\n\n'
        'Run the MZP matching your Max year with **Scripting > Run Script**, then restart Max. '
        'The included demo requires Max 2027. Read ARTIST_GUIDE.md for the workflow.\n\n'
        'Verified in private Max 2027: 618 native control-component bounds, 52 root/layer/section toggles, '
        'ten section displacement/collapse checks, retained controls/caches, layer management, '
        'Undo/Redo, areas, independent Brush erase, shared population/collision and Manual/live updates. '
        'Native binaries match 1.2.0 exactly; this is a layout patch.\n\n'
        'Max 2026 host behavior, other DPI configurations and renderer qualification still need testing. '
        'The optional MCP 1.1.0 installation is unchanged.\n', encoding='utf-8')
    entries = sorted(p for p in OUTPUT.rglob('*') if p.is_file() and p.name != 'SHA256SUMS.txt')
    (OUTPUT / 'SHA256SUMS.txt').write_text(''.join(f'{sha(p.read_bytes())}  {p.relative_to(OUTPUT).as_posix()}\n' for p in entries), encoding='utf-8')
    print(f'PASS: final Max evidence and both packages verified; {len(entries)} handoff files hashed.')


if __name__ == '__main__':
    main()
