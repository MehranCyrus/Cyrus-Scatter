"""Run isolated signed-license experiments; never install or issue customer grants."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import shutil
import sys
from PIL import Image, ImageChops

from run import ROOT, snapshot, run_command, host, write_json, digest, compiler_environment


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', required=True)
    parser.add_argument('--baseline', type=Path, default=ROOT / 'build/licensing-l0-2026-10-04/run04')
    parser.add_argument('--signer-python', type=Path,
                        default=ROOT / 'build/licensing-l1-tools-2026-10-04/Scripts/python.exe')
    parser.add_argument('--max-dir', type=Path, default=Path('C:/Program Files/Autodesk/3ds Max 2027'))
    args = parser.parse_args()
    if not re.fullmatch(r'[a-z0-9-]+', args.run):
        raise SystemExit('Use an alphanumeric/hyphen run name')
    output = ROOT / 'build/licensing-l1-2026-10-04' / args.run
    output.mkdir(parents=True, exist_ok=False)
    baseline = args.baseline.resolve()
    source = snapshot(output, product_baseline=baseline)
    old = json.loads((baseline / 'source.json').read_text(encoding='utf-8'))
    fresh = {row['path']: row['sha256'] for row in json.loads((output / 'source.json').read_text())['files']}
    # Only reuse product DLLs if all recorded product/cmake source bytes match.
    for row in old['files']:
        if row['path'].startswith(('AminScatter/', 'CyrusSurfaceAnalyzer/', 'cmake/')):
            if fresh.get(row['path']) != row['sha256']:
                raise RuntimeError('Baseline product differs; rebuild a matching L0 baseline: ' + row['path'])
    if json.loads((baseline / 'result.json').read_text())['status'] != 'PASS':
        raise RuntimeError('Expected passed disposable baseline')
    env = compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),
                               '14.38.33130', '10.0.19041.0')
    run_command([args.signer_python, source / 'tools/licensing_lab/make_signed_fixtures.py', output / 'fixtures'],
                output / 'issuer-generation', env)
    for year in (2026, 2027):
        sdk = ROOT / f'build/tooling/max{year}-sdk/Program Files/Autodesk/3ds Max {year} SDK/maxsdk'
        target = output / f'lab-{year}'
        run_command(['cmake', '-S', source / 'tools/licensing_lab', '-B', target, '-G', 'NMake Makefiles',
                     '-DCMAKE_BUILD_TYPE=Release', '-DCYRUS_BUILD_LICENSING_LAB=ON',
                     '-DCYRUS_BUILD_SIGNED_LICENSE_LAB=ON', f'-DCYRUS_SIGNED_FIXTURES={output}/fixtures',
                     f'-DCYRUS_MAX_YEAR={year}', f'-DMAXSDK_ROOT={sdk}'], output / f'lab-{year}-configure', env)
        run_command(['cmake', '--build', target], output / f'lab-{year}-build', env)
        run_command(['ctest', '--test-dir', target, '--output-on-failure', '-V'], output / f'lab-{year}-tests', env)
    native = output / 'bin';native.mkdir()
    previous_binaries = json.loads((baseline / 'binaries.json').read_text())
    for name, sha in previous_binaries.items():
        if name == 'CyrusLicenseLab.dlx':
            continue
        if digest(baseline / 'bin' / name) != sha:
            raise RuntimeError('Product binary fingerprint changed: ' + name)
        shutil.copy2(baseline / 'bin' / name, native / name)
    shutil.copy2(output / 'lab-2027/CyrusSignedLicenseLab.dlx', native)
    write_json(output / 'binaries.json', {p.name: digest(p) for p in native.glob('*.dl?')})
    shutil.copy2(baseline / 'lab-scene.max', output / 'input-scene.max')
    write_json(output / 'baseline.json', {'from': str(baseline), 'product_inputs_equal': True,
               'scene_sha256': digest(output / 'input-scene.max'),
               'note': 'Product DLLs and scene reused from verified L0 baseline; signed lab rebuilt'})
    checks = {stage: host(source, output, stage, args.max_dir, fixture='signed_fixture.ms')
              for stage in ('create', 'reopen')}
    with Image.open(output / 'signed-active.png') as active:
        if active.size != (128, 128) or len(active.convert('RGB').getcolors(16385) or []) < 4:
            raise RuntimeError('Unexpected/blank reference render')
        for name in ('signed-expired.png', 'signed-reopened.png'):
            with Image.open(output / name) as image:
                if image.size != active.size or ImageChops.difference(active.convert('RGB'), image.convert('RGB')).getbbox():
                    raise RuntimeError('Changed render: ' + name)
    write_json(output / 'result.json', {
        'status': 'PASS', 'scope': 'Real ES256 verification; synthetic identity/time/scene evidence; lab only',
        'sdk_builds': [2026, 2027], 'host': 'Max 2027 batch, Default Scanline',
        'render_pixels_equal': True, 'checks': checks,
        'production_enforcement': False, 'real_device_binding': False, 'clock_recovery': False,
        'native_boundary_gap': 'Direct product primitives still accept authoring outside the lab wrapper',
    })
    print('PASS signed licensing experiment: ' + str(output), flush=True)


if __name__ == '__main__':
    main()
