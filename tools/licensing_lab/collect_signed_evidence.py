"""Curate bounded signed-lab evidence; no binaries, scenes or private keys."""
from pathlib import Path
import argparse
import collections
import json
import re
import shutil

from run import ROOT, digest, write_json


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', required=True)
    parser.add_argument('--destination', type=Path, required=True)
    args = parser.parse_args()
    if not re.fullmatch(r'[a-z0-9-]+', args.run):
        raise SystemExit('Invalid run name')
    original = ROOT / 'build/licensing-l1-2026-10-04' / args.run
    result = json.loads((original / 'result.json').read_text())
    if result['status'] != 'PASS':
        raise RuntimeError('Only curate a completed experiment')
    source = json.loads((original / 'source.json').read_text())
    for row in source['files']:
        if digest(original / 'source' / row['path']) != row['sha256']:
            raise RuntimeError('Snapshot drift: ' + row['path'])
    destination = args.destination.resolve()
    destination.mkdir(parents=True, exist_ok=False)
    names = ['result.json', 'source.json', 'native_inventory.json', 'binaries.json',
             'baseline.json', 'issuer-generation.log', 'issuer-generation.json',
             'fixtures/issuer.json', 'fixtures/lab_public_key.h', 'fixtures/vectors.json',
             'signed-active.png', 'signed-expired.png', 'signed-reopened.png']
    counts = {}
    sdk_artifacts = {}
    for year in (2026, 2027):
        for phase in ('configure', 'build', 'tests'):
            for suffix in ('log', 'json'):
                names.append(f'lab-{year}-{phase}.{suffix}')
        log = (original / f'lab-{year}-tests.log').read_text()
        if '100% tests passed, 0 tests failed out of 12' not in log:
            raise RuntimeError('Missing twelve-group CTest completion')
        assertions = list(map(int, re.findall(r'PASS \w+: (\d+) assertions', log)))
        if len(assertions) != 12:
            raise RuntimeError('Unexpected assertion groups')
        counts[str(year)] = {'signed_groups': 6, 'signed_assertions': sum(assertions[:6]),
                             'policy_groups': 6, 'policy_assertions': sum(assertions[6:])}
        sdk_artifacts[str(year)] = {name: digest(original / f'lab-{year}' / name) for name in (
            'CyrusSignedLicenseLab.dlx', 'signed_license_tests.exe',
            'policy/cyrus_license_token.lib', 'policy/license_policy_tests.exe')}
    host_counts = {}
    host_versions = set()
    binaries = json.loads((original / 'binaries.json').read_text())
    for name, sha in binaries.items():
        if digest(original / 'bin' / name) != sha:
            raise RuntimeError('Binary drift: ' + name)
    for stage in ('create', 'reopen'):
        names += [f'{stage}/{name}' for name in ('checks.tsv', 'modules.tsv', 'verified_modules.json',
                                                 'launch.json', 'session.log')]
        checks = (original / stage / 'checks.tsv').read_text(encoding='utf-8-sig').splitlines()
        if not checks or checks[-1] != 'COMPLETE' or any(s.startswith('FAIL\t') for s in checks):
            raise RuntimeError('Incomplete host checks')
        modules = json.loads((original / stage / 'verified_modules.json').read_text())
        if {name: row['sha256'] for name, row in modules.items()} != binaries:
            raise RuntimeError('Loaded module evidence differs')
        host_counts[stage] = {'assertions': sum(s.startswith('PASS\t') for s in checks),
                              'observations': sum(s.startswith('OBSERVED\t') for s in checks),
                              'verified_modules': len(modules)}
        session = (original / stage / 'session.log').read_text(encoding='utf-8-sig', errors='replace')
        version = re.search(r'Product version: (.+)', session)
        if not version:
            raise RuntimeError('Missing host version evidence')
        host_versions.add(version[1].strip())
    if len(host_versions) != 1:
        raise RuntimeError('Host version changed between stages')
    for name in names:
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(original / name, target)
    # Keep the exact fixture transport and dependency lock with the evidence.
    for name in ('signed_fixture.ms', 'requirements-signer.txt'):
        shutil.copy2(original / 'source/tools/licensing_lab' / name, destination / name)
    vectors = json.loads((original / 'fixtures/vectors.json').read_text())
    code_drift, documentation_drift = [], []
    for row in source['files']:
        if not row['path'].startswith(('CyrusLicensing/', 'tools/licensing_lab/')):
            continue  # Product baseline is deliberately frozen, not the current checkout.
        path = ROOT / row['path']
        if not path.is_file() or digest(path) != row['sha256']:
            (documentation_drift if path.suffix == '.md' else code_drift).append(row['path'])
    if code_drift:
        raise RuntimeError('Licensing code changed since tested snapshot: ' + str(code_drift))
    write_json(destination / 'summary.json', {
        'status': 'PASS (bounded signed-license experiment; not production qualification)',
        'original_run': str(original), 'source_head': source['head'],
        'source_files': len(source['files']), 'source_scope': source['scope'],
        'product_baseline': source['product_baseline'], 'native_declarations':
            json.loads((original / 'native_inventory.json').read_text())['count'],
        'licensing_code_drift_at_capture': code_drift,
        'documentation_changes_after_build': documentation_drift,
        'ctest': counts, 'sdk_artifact_sha256': sdk_artifacts,
        'signed_cases': len(vectors['cases']), 'case_groups': dict(collections.Counter(
            row['group'] for row in vectors['cases'])), 'deterministic_malformed_probes': 256,
        'host': host_counts, 'host_version': next(iter(host_versions)),
        'renderer': 'Default Scanline', 'scene_instances': 64, 'render_size': [128, 128],
        'render_pixels_equal': result['render_pixels_equal'],
        'production_enforcement': False, 'real_device_binding': False, 'real_clock_recovery': False,
        'scene_provenance_verified': False, 'max2026_runtime_tested': False,
        'L0_complete': False, 'L1_complete': False,
    })
    files = sorted(p for p in destination.rglob('*') if p.is_file())
    write_json(destination / 'manifest.json', {
        'scope': 'Curated experiment evidence only; manifest excludes itself',
        'files': [{'path': p.relative_to(destination).as_posix(), 'bytes': p.stat().st_size,
                   'sha256': digest(p)} for p in files],
    })
    print(json.dumps({'destination': str(destination), 'files': len(files) + 1,
                      'host': host_counts, 'ctest': counts}, indent=2))


if __name__ == '__main__':
    main()
