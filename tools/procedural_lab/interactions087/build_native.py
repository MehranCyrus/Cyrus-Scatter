"""Incremental development build; release packaging still requires offline_build."""
import argparse, json, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
from build_max import compiler_environment

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--name', required=True)
    parser.add_argument('--build', default='build/interactions087-native-20261025-01')
    parser.add_argument('--targets', nargs='+', default=['AminScatter', 'CyrusScatterEdit', 'CyrusBrush', 'CyrusBrushStorage', 'interactions_tests'])
    args = parser.parse_args()
    build = (ROOT / args.build).resolve()
    if not build.is_relative_to(ROOT / 'build'):
        raise ValueError('Owned build directory required')
    env = compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'), '14.38.33130', '10.0.19041.0')
    cmd = ['cmake', '--build', str(build), '--target', *args.targets]
    started = time.perf_counter()
    with (build / (args.name + '.log')).open('w', encoding='utf-8') as log:
        result = subprocess.run(cmd, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
    receipt = {'exit_code': result.returncode, 'seconds': time.perf_counter()-started, 'command': cmd}
    (build / (args.name + '.json')).write_text(json.dumps(receipt, indent=2))
    print(json.dumps(receipt))
    print('\n'.join((build / (args.name + '.log')).read_text().splitlines()[-28:]))
    return result.returncode

if __name__ == '__main__':
    raise SystemExit(main())
