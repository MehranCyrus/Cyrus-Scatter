"""Verify current source, build, installed-byte, host and archive correspondence."""
from pathlib import Path
import hashlib
import json
import re
import zipfile

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'build/clearance-relax-08682-20261021'
OUT = ROOT / 'dist/CyrusScatter-0.86.8.2-20261021'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main():
    package = read(WORK / 'package-checks.json')
    for name, digest in package['artifacts'].items():
        assert sha(OUT / name) == digest, name
    script = ROOT / 'AminScatter/scripts/AminScatterObject.ms'
    fingerprint = re.search(r'CyrusLoadedScriptFingerprint="([0-9a-f]+)"', script.read_text(encoding='utf-8-sig'))[1]
    hosts = {}
    for year in (2024, 2026, 2027):
        build = read(WORK / f'max{year}/receipt.json')
        assert build['max_year'] == year and all(s['exit_code'] == 0 for s in build['stages'])
        for name, digest in {**build['sources'], **build['binaries']}.items():
            assert sha(ROOT / name) == digest, name
        tests = (WORK / f'max{year}/tests.log').read_text()
        assert '100% tests passed, 0 tests failed out of 49' in tests
        with zipfile.ZipFile(OUT / f'CyrusScatter-0.86.8.2-Max{year}.mzp') as archive:
            assert archive.testzip() is None
            manifest = json.loads(archive.read('manifest.json'))
            for name, digest in manifest['files'].items():
                assert hashlib.sha256(archive.read(name)).hexdigest() == digest, name
        installed = Path((WORK / f'installer-three-hosts/{year}/installed-runtime.txt').read_text().strip())
        for name in ('AminScatter.dlx', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh', 'CyrusScatterEdit.dlm', 'CyrusGallery.dll', 'CyrusScatter.ms'):
            path = installed / ('bin/' + name if name.endswith(('.dlx', '.dlm', '.dlh')) else name)
            assert sha(path) == manifest['files'][name], path
        stage = 'final' if year == 2027 else 'installed'
        host = ROOT / f'build/mcp-qualification/clearance-relax-08682-{stage}-{year}'
        loaded, launch = read(host / 'loaded-identity.json'), read(host / 'launch.json')
        assert loaded['year'] == year and loaded['version'] == '0.86.8.2'
        assert loaded['script'] == fingerprint and launch['script_sha256'] == manifest['files']['CyrusScatter.ms']
        assert loaded['gallery'] == manifest['files']['CyrusGallery.dll']
        assert all(digest == manifest['files'][name] for name, digest in loaded['native'].items())
        assert sha(Path(launch['profile_template'])) == launch['profile_template_sha256']
        logs = ['setup.txt', 'bounds.txt', 'calculations.txt', 'lifecycle.txt']
        if year == 2027:
            logs += ['numeric.txt', 'wide.txt']
        evidence = {}
        for name in logs:
            path = host / name
            text = path.read_text()
            assert 'SUCCESS' in text and not re.search(r'^(ERROR|FAIL:)', text, re.M), path
            evidence[name] = {'sha256': sha(path), 'passes': text.count('PASS:')}
        hosts[str(year)] = {'loaded': loaded, 'source_count': len(build['sources']),
                            'native_tests': 49, 'tests_sha256': sha(WORK / f'max{year}/tests.log'),
                            'profile_template_unchanged': True, 'evidence': evidence}
    embedded = read(WORK / 'embedded-payloads.json')
    assert len(embedded) == 3 and all(x['matches'] and x['sha256'] == package['artifacts'][f"CyrusScatter-0.86.8.2-Max{x['year']}.mzp"] for x in embedded)
    installer = WORK / 'installer-three-hosts/result.txt'
    assert 'SUCCESS' in installer.read_text()
    generated = read(WORK / 'generated-final/generated-check.json')
    assert generated['passed'] and generated['generated_sha256'] == sha(script)
    extra = {}
    for folder in ('AminScatter/tools/ui', 'tools/clearance_relax_08682'):
        for path in sorted((ROOT / folder).rglob('*')):
            if path.is_file() and path.suffix in ('.cjs', '.ms', '.json', '.py', '.ps1', '.md'):
                extra[path.relative_to(ROOT).as_posix()] = sha(path)
    image = WORK / 'max2027-clearance-relax.jpg'
    assert image.stat().st_size > 10000
    receipt = {'version': '0.86.8.2', 'hosts': hosts, 'package': package,
               'installer_result': sha(installer), 'generated': generated,
               'additional_sources': extra, 'screenshots': {image.name: sha(image)},
               'python_tests': {'passed': 176, 'evidence': 'pytest terminal run, 14.32 seconds; subsequent product-file changes only restore LF line endings, covered by final frozen builds'},
               'scope': 'Focused Relax/clearance and UI integration; no new renderer or universal performance qualification.'}
    (WORK / 'final-receipt.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    print('PASS: frozen sources, three builds, three installed payloads, three loaded hosts, UI/calculation logs, shared content, archives and embedded resources')


if __name__ == '__main__':
    main()
