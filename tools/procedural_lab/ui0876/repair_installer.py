"""Installer-only 0.87.6 r2 derivation; preserve every delivered runtime byte.

This is deliberately pinned to the original delivery, not a substitute for native
build admission. Its original native/Gallery producer records remain historical.
Only the installer helper, adapter and their inventories may change.
"""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json
import re
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
import build_inputs

BASE = ROOT / 'dist/CyrusScatter-0.87.6-20261028-final'
PINNED = {
    2024: '17a89cc27acdd40c1637329360567cd2a8db683b29bcf3d4712de7de4a5d386a',
    2026: 'aee328bb5be7dc372cceb4770dcbcc6b56597ecdab9d14fb3e08e51c1554ca7a',
    2027: '0dd193dc54accf658fad54ce339a1e00a7b401e2621f4f3c51c602bac2547a89',
}
ALLOWED = {'CyrusInstaller.dll', 'install.ms', 'InstallInventory.txt', 'manifest.json'}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def write_json(path, value):
    path.write_bytes((json.dumps(value, indent=2) + '\n').encode('utf-8'))


def repack(year, core, core_receipt, output):
    base = BASE / f'CyrusScatter-0.87.6-Max{year}.mzp'
    if build_inputs.digest(base) != PINNED[year]:
        raise ValueError('The original delivered package identity differs.')
    original_receipt = build_inputs.verify_package_receipt(base, ROOT)
    with zipfile.ZipFile(base) as archive:
        if archive.testzip() is not None or len(archive.namelist()) != len(set(archive.namelist())):
            raise ValueError('Invalid original archive.')
        original = {n: archive.read(n) for n in archive.namelist()}
    manifest = json.loads(original['manifest.json'])
    if (manifest['version'] != '0.87.6' or manifest['max_year'] != year
            or manifest['producer_receipts'] != original_receipt['producer_receipts']
            or set(original) != set(manifest['files']) | {'manifest.json'}):
        raise ValueError('Original manifest/producer mismatch.')
    for name, digest in manifest['files'].items():
        if sha(original[name]) != digest:
            raise ValueError('Original member differs: ' + name)

    producers = dict(manifest['producer_receipts'])
    producers['installer'] = build_inputs.producer_link(core, core_receipt)
    inputs = build_inputs.frozen(
        [base, base.with_suffix('.build.json'), core, core.with_suffix('.build.json'),
         Path(__file__), ROOT / 'tools/build_inputs.py', Path(sys.executable)],
        {'operation': '0.87.6-installer-only-r2', 'max_year': year,
         'base_package_sha256': PINNED[year], 'producers': producers}, ROOT)
    payload = dict(original)
    payload['CyrusInstaller.dll'] = core.read_bytes()
    rows = original['InstallInventory.txt'].decode('utf-8').splitlines()
    if rows[0].split('\t')[:3] != ['CyrusScatterInstall2', '0.87.6', str(year)]:
        raise ValueError('Unexpected original inventory.')
    installed = {}
    for row in rows[1:]:
        name, digest, size, source = row.split('\t')
        if name in installed or sha(original[source]) != digest or len(original[source]) != int(size):
            raise ValueError('Original inventory entry differs: ' + name)
        installed[name] = (source, payload[source])
    content_id = sha(''.join(n + ':' + sha(data) + '\n'
                            for n, (_, data) in sorted(installed.items())).encode('utf-8'))[:12]
    inventory = ('CyrusScatterInstall2\t0.87.6\t' + str(year) + '\t' + content_id + '\n' +
                 ''.join(n + '\t' + sha(data) + '\t' + str(len(data)) + '\t' + source + '\n'
                         for n, (source, data) in sorted(installed.items()))).encode('utf-8')
    payload['InstallInventory.txt'] = inventory
    adapter = original['install.ms'].decode('utf-8')
    old_mvids = set(re.findall(r'ModuleVersionId\.ToString\(\)\)!="([0-9a-f-]{36})"', adapter))
    if len(old_mvids) != 1 or f'(maxVersion())[1]!={(year - 1998) * 1000}' not in adapter:
        raise ValueError('The original host/helper guard is missing.')
    for previous, updated in (
        (sha(original['CyrusInstaller.dll']), sha(payload['CyrusInstaller.dll'])),
        (old_mvids.pop(), core_receipt['module_version_id']),
        (sha(original['InstallInventory.txt']), sha(inventory)),
    ):
        if previous not in adapter:
            raise ValueError('A required installer identity is missing.')
        adapter = adapter.replace(previous, updated)
    payload['install.ms'] = adapter.encode('utf-8')
    manifest.update(producer_receipts=producers, package_inputs_sha256=build_inputs.identity(inputs),
                    installer_revision='r2', repackaged_from={
                        'package': base.name, 'sha256': PINNED[year],
                        'receipt_sha256': build_inputs.digest(base.with_suffix('.build.json')),
                        'scope': 'Installer-only; native/Gallery producers and all runtime bytes reused unchanged.'})
    manifest['files'] = {n: sha(data) for n, data in sorted(payload.items()) if n != 'manifest.json'}
    payload['manifest.json'] = (json.dumps(manifest, indent=2) + '\n').encode('utf-8')
    if set(payload) != set(original) or any(payload[n] != original[n] for n in original if n not in ALLOWED):
        raise ValueError('Installer-only repair changed runtime payload.')
    target = output / base.name
    if target.exists():
        raise FileExistsError(target)
    write_json(target.with_suffix('.build.json'), {'schema': 'cyrus.package-build/2', 'status': 'pending'})
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name, data in sorted(payload.items()):
            info = zipfile.ZipInfo(name, date_time=(2026, 10, 28, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, data)
    with zipfile.ZipFile(target) as archive:
        if archive.testzip() is not None or any(archive.read(n) != data for n, data in payload.items()):
            raise ValueError('Repacked archive verification failed.')
    build_inputs.verify_frozen(inputs, ROOT)
    write_json(target.with_suffix('.build.json'), {
        'schema': 'cyrus.package-build/2', 'status': 'complete',
        'artifact_sha256': build_inputs.digest(target), 'input_manifest': inputs,
        'input_manifest_sha256': build_inputs.identity(inputs), 'producer_receipts': producers,
        'derivation': manifest['repackaged_from'],
    })
    target.with_suffix('.sha256').write_bytes((build_inputs.digest(target) + '  ' + target.name + '\n').encode())
    build_inputs.verify_package_receipt(target, ROOT)
    return target, {'year': year, 'sha256': build_inputs.digest(target), 'base_sha256': PINNED[year],
                    'unchanged_members': len(original) - len(ALLOWED),
                    'changed_members': sorted(n for n in original if original[n] != payload[n]),
                    'runtime_bytes_unchanged': True, 'content_id': content_id}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    run, output = args.run.resolve(), args.output.resolve()
    run.mkdir(parents=True, exist_ok=True)
    output.mkdir(parents=True, exist_ok=False)
    spec = importlib.util.spec_from_file_location('installer_builder', ROOT / 'AminScatter/tools/build_installer.py')
    builder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(builder)
    core = run / 'core/CyrusInstaller.dll'
    builder.build(core)
    receipt = builder.verify_core(core)
    results = [repack(year, core, receipt, output) for year in PINNED]
    exe = output / 'CyrusScatter-0.87.6-Setup.exe'
    builder.build_exe(exe, [p for p, _ in results], core)
    write_json(output / 'INSTALLER_REPAIR.json', {
        'version': '0.87.6', 'installer_revision': 'r2',
        'exe': str(exe), 'exe_sha256': build_inputs.digest(exe),
        'core_sha256': build_inputs.digest(core), 'packages': [r for _, r in results],
        'qualification': 'Packaging only; managed filesystem checks recorded separately. No new Max runtime qualification.',
    })
    print(exe)


if __name__ == '__main__':
    main()
