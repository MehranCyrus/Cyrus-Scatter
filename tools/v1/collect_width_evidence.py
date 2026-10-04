"""Curate the 1.2.1 layout patch without rewriting frozen 1.2.0 evidence."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[2]
PROFILE = ROOT / 'build/cyrus-v1/hosts/layers-width-final'
OUTPUT = ROOT / 'dist/layers-first-1.2.1'
EVIDENCE = ROOT / 'docs/Layer_Width_2026-10-04/evidence'
NATIVE = ('AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    script = ROOT / 'AminScatter/scripts/AminScatterObject.ms'
    source = script.read_bytes()
    loaded = json.loads((PROFILE / 'loaded-identity.json').read_text())
    result = json.loads((PROFILE / 'width-acceptance-246.json').read_text())
    assert loaded['script_version'] == result['version'] == '1.2.1'
    assert result['retained_controls_and_caches'] and result['control_bounds_checks'] == 618
    assert result['section_toggles'] == 40 and result['layers_body_width'] == 246
    # This campaign loads the generated source at startup, not an installed copy.
    assert script.stat().st_mtime_ns <= (PROFILE / 'launch.json').stat().st_mtime_ns
    packages = {}
    for year in (2026, 2027):
        path = OUTPUT / f'CyrusScatter-1.2.1-Max{year}.mzp'
        old = ROOT / f'dist/layers-first-1.2.0/CyrusScatter-1.2.0-Max{year}.mzp'
        with zipfile.ZipFile(path) as z, zipfile.ZipFile(old) as baseline:
            manifest = json.loads(z.read('manifest.json'))
            assert manifest['version'] == '1.2.1' and manifest['max_year'] == year
            assert z.read('CyrusScatter.ms') == source
            assert z.testzip() is None
            for name, digest in manifest['files'].items():
                assert sha(z.read(name)) == digest
            for name in NATIVE:
                assert z.read(name) == baseline.read(name), f'Native changed: {year}/{name}'
            if year == 2027:
                for name, module_path in loaded['modules']:
                    assert Path(module_path).resolve().is_relative_to(PROFILE.resolve())
                    assert Path(module_path).read_bytes() == z.read(name)
            packages[str(year)] = dict(path=path.relative_to(ROOT).as_posix(), sha256=sha(path.read_bytes()),
                                       native_unchanged_from_1_2_0=True, manifest=manifest)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    for name in ('width-acceptance-246.json', 'loaded-identity.json', 'width-probe.txt'):
        shutil.copy2(PROFILE / name, EVIDENCE / name)
    sources = ['AminScatter/scripts/AminScatterObject.ms', 'AminScatter/tools/ui/layers-first.cjs',
               'AminScatter/tools/ui/templates/layers-first-host.ms',
               'AminScatter/tools/ui/templates/layers-first-panel.ms',
               'tools/v1/layers_width_probe.ms', 'tools/v1/layers_width_acceptance.ms',
               'tools/v1/layers_width_prepare.ms', 'tools/v1/package.py',
               'tools/v1/collect_width_evidence.py']
    receipt = dict(version='1.2.1', scope='Source-loaded private Max 2027 layout patch; default panel width',
                   sources={p: sha((ROOT / p).read_bytes()) for p in sources}, packages=packages,
                   evidence={p.name: sha(p.read_bytes()) for p in EVIDENCE.iterdir() if p.name != 'MANIFEST.json'})
    (EVIDENCE / 'MANIFEST.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    shutil.copy2(ROOT / 'dist/layers-first-1.2.0/Cyrus_Scatter_1.2_Layers_Demo.max', OUTPUT)
    (OUTPUT / 'README.md').write_text(
        '# Cyrus Scatter 1.2.1\n\n'
        'This patch gives Layers and their settings the full native panel width, with small margins for scrollbars. '
        'Buttons, lists and Randomize fields use the additional space.\n\n'
        'Run the MZP matching your Max year with **Scripting > Run Script**, then restart Max. '
        'The existing 1.2 demo is included and requires Max 2027. Read ARTIST_GUIDE.md for its workflow.\n\n'
        'Verified in private Max 2027: 618 visible native component bounds and 40 section toggles, '
        'with retained controls and no added placement generation, paint evaluation or display uploads. '
        'Other panel widths, DPI settings and Max 2026 interactive behavior still need artist testing.\n\n'
        'Native engine binaries are identical to 1.2.0. Scene data, Brush, performance paths and MCP are unchanged. '
        'The optional MCP 1.1.0 package from the previous handoff needs no update.\n', encoding='utf-8')
    entries = sorted(p for p in OUTPUT.rglob('*') if p.is_file() and p.name != 'SHA256SUMS.txt')
    (OUTPUT / 'SHA256SUMS.txt').write_text(''.join(f'{sha(p.read_bytes())}  {p.relative_to(OUTPUT).as_posix()}\n' for p in entries), encoding='utf-8')
    print(f'PASS: both packages verified; native binaries match 1.2.0; {len(entries)} handoff files hashed.')


if __name__ == '__main__':
    main()
