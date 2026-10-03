"""Curate a completed private v1 campaign; never include scenes or IPC secrets."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import zipfile
from build import ROOT, BASE


def digest(data):
    return hashlib.sha256(data).hexdigest()


def check_public(value):
    if isinstance(value, dict):
        for key, item in value.items():
            if key.lower() in {'secret', 'token', 'authorization', 'connection_secret', 'api_key', 'session_secret'}:
                raise ValueError('Refusing a secret-bearing evidence record: ' + key)
            check_public(item)
    elif isinstance(value, list):
        for item in value:
            check_public(item)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--product-run', default='v1-shipped')
    parser.add_argument('--installer-run', default='v1-artist-demo')
    parser.add_argument('--reopen-run', default='v1-shipped-reopen')
    parser.add_argument('--uninstall-run', default='v1-ready')
    parser.add_argument('--ui-run', default='v1-shipped')
    parser.add_argument('--navigation-run', default='v1-final')
    parser.add_argument('--legacy-run', default='v1-legacy-full')
    parser.add_argument('--mcp-run', default='v1-regression')
    args = parser.parse_args()
    evidence = ROOT / 'docs/Cyrus_Scatter_V1_2026-10-03/evidence'
    evidence.mkdir(exist_ok=True)
    records = []

    def collect(source, name):
        data = source.read_bytes()
        if source.suffix == '.json':
            check_public(json.loads(data))
        destination = evidence / name
        destination.write_bytes(data)
        records.append(dict(file=name, source=source.relative_to(ROOT).as_posix(), sha256=digest(data), bytes=len(data)))

    def host(run):
        path = (BASE / 'hosts' / run).resolve()
        if path.parent != (BASE / 'hosts').resolve():
            raise ValueError('Invalid private run name')
        return path

    for name in ('native-v1-fixture.json', 'brush-acceptance.json', 'cache-copy-acceptance.json',
                 'curved-edit-acceptance.json', 'output-restore-prepared.json', 'loaded-identity.json'):
        collect(host(args.product_run) / name, name)
    collect(host(args.reopen_run) / 'reopen-acceptance.json', 'reopen-acceptance.json')
    collect(host(args.installer_run) / 'installation-verified.json', 'installation-verified.json')
    collect(host(args.uninstall_run) / 'uninstall-acceptance.json', 'uninstall-acceptance.json')
    for name in ('ui-baseline.json', 'ui-gesture-acceptance.json', 'ui-update-acceptance.json', 'ui-status-acceptance.json', 'render-acceptance.json'):
        collect(host(args.ui_run) / name, name)
    collect(host(args.navigation_run) / 'navigation-acceptance.json', 'navigation-acceptance.json')
    collect(host(args.legacy_run) / 'legacy-acceptance.json', 'legacy-acceptance.json')
    mcp = (ROOT / 'build/mcp-qualification' / args.mcp_run).resolve()
    if mcp.parent != (ROOT / 'build/mcp-qualification').resolve():
        raise ValueError('Invalid MCP run name')
    for name in ('cycles.json', 'scenarios.json', 'retained.json', 'stdio-acceptance.json', 'inspection.json'):
        collect(mcp / name, 'mcp-' + name)
    for year in (2026, 2027):
        log = BASE / f'max{year}/build-2.log'
        if '100% tests passed, 0 tests failed out of 11' not in log.read_text():
            raise ValueError('No passing native suite log for ' + str(year))
        collect(log, f'native-tests-max{year}.log')
    python_log = BASE / 'python-tests.log'
    if '62 passed' not in python_log.read_text():
        raise ValueError('No passing Python qualification log')
    collect(python_log, 'python-tests.log')

    source_paths = [ROOT / 'AminScatter/CMakeLists.txt', ROOT / 'tools/build_max.py', ROOT / 'tools/mcp/launch.py']
    for folder in ('AminScatter/include', 'AminScatter/src', 'AminScatter/tests', 'AminScatter/scripts', 'AminScatter/tools/ui', 'AminScatter/installer', 'cmake', 'tools/v1'):
        source_paths.extend(path for path in (ROOT / folder).rglob('*') if path.is_file() and path.suffix in {'.h', '.cpp', '.inc', '.rc', '.def', '.cmake', '.txt', '.ms', '.cjs', '.py', '.run', '.mcr'})
    sources = {path.relative_to(ROOT).as_posix(): digest(path.read_bytes().replace(b'\r\n', b'\n')) for path in sorted(set(source_paths))}
    packages = []
    for year in (2026, 2027):
        package = ROOT / f'dist/v1/CyrusScatter-1.0.0-Max{year}.mzp'
        with zipfile.ZipFile(package) as archive:
            manifest = json.loads(archive.read('manifest.json'))
            if archive.testzip() is not None:
                raise ValueError('Corrupt installer')
            for name, expected in manifest['files'].items():
                if digest(archive.read(name)) != expected:
                    raise ValueError('Package payload hash mismatch: ' + name)
            if manifest['files']['CyrusScatter.ms'] != digest((ROOT / 'AminScatter/scripts/AminScatterObject.ms').read_bytes()):
                raise ValueError('Package script differs from current generated source')
            natives = json.loads((BASE / f'max{year}/identity.json').read_text())
            for name in ('AminScatter.dlx', 'CyrusScatterEdit.dlm', 'CyrusBrush.dlx', 'CyrusBrushStorage.dlh'):
                if natives[name] != manifest['files'][name]:
                    raise ValueError('Package differs from the recorded native build')
            target = evidence / f'package-max{year}.json'
            target.write_text(json.dumps(manifest, indent=2) + '\n')
            records.append(dict(file=target.name, source=package.relative_to(ROOT).as_posix() + ':manifest.json',
                                sha256=digest(target.read_bytes()), bytes=target.stat().st_size))
        packages.append(dict(file=package.relative_to(ROOT).as_posix(), sha256=digest(package.read_bytes()), max_year=year))

    verified = json.loads((host(args.installer_run) / 'installation-verified.json').read_text())
    if not verified.get('clean_startup') or verified['package_sha256'] != next(p['sha256'] for p in packages if p['max_year'] == 2027):
        raise ValueError('No current-package clean-startup verification')
    manifest = dict(version='1.0.0', date='2026-10-03', backup_commit='9aca3683f3ec62aaf2fff0e27a7b57301f51b95e',
                    working_branch=subprocess.check_output(['git', 'branch', '--show-current'], cwd=ROOT, text=True).strip(),
                    source_hash_encoding='SHA-256 with CRLF normalized to LF; source snapshot before release commit',
                    source_files=sources, packages=packages, evidence=records,
                    qualification_scope='Max 2027.1 host; Max 2026 and 2027 native SDK suites; no Max 2026 host or broad renderer qualification',
                    earlier_runs='Navigation/legacy/MCP and uninstall runs preceded the final UI cleanup and GUID-independent Brush sampling fix. Their native algorithms/display binaries and installer cleanup are identical; navigation uses a filled mask, legacy/MCP do not use Brush. Fractional copy sampling, product, reopen, install and mouse tests are recorded from the final script.')
    (evidence / 'MANIFEST.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Curated {len(records)} records; {len(sources)} source fingerprints; both package identities verified.')


if __name__ == '__main__':
    main()
