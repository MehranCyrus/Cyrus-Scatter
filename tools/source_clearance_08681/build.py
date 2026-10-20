"""Matched, owned Max 2027 development builds for the 0.86.8.1 correction."""
from pathlib import Path
import argparse
import subprocess
import sys
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import build_max

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--targets', nargs='+')
    args = parser.parse_args()
    dest = ROOT / 'build/clearance-performance-08681-20261020' / ('core' if args.core else 'max2027-dev')
    dest.mkdir(parents=True, exist_ok=True)
    env = build_max.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'), '14.38.33130', '10.0.19041.0')
    commands = []
    if not (dest / 'CMakeCache.txt').exists():
        configure = ['cmake', '-S', str(ROOT / 'AminScatter'), '-B', str(dest), '-G', 'NMake Makefiles', '-DCMAKE_BUILD_TYPE=Release']
        if args.core:
            configure += ['-DAMIN_BUILD_MAX=OFF']
        else:
            configure += ['-DCYRUS_MAX_YEAR=2027', f'-DMAXSDK_ROOT={ROOT}/build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk',
                          '-DCYRUS_TEAM_LICENSE=ON', f'-DCYRUS_TEAM_TRUST_DIR={ROOT}/CyrusLicensing/team',
                          '-DCYRUS_NATIVE_LICENSE_EXPERIMENT=OFF', '-DCYRUS_LICENSE_INSTALLATION_CONTEXT=OFF']
        commands.append(('configure', configure))
    commands.append(('build', ['cmake', '--build', str(dest), *(['--target', *args.targets] if args.targets else [])]))
    for label, command in commands:
        with (dest / f'{label}.log').open('w', encoding='utf-8') as log:
            result = subprocess.run(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
        print(label, result.returncode, flush=True)
        if result.returncode:
            print((dest / f'{label}.log').read_text(encoding='utf-8')[-12000:])
            return result.returncode
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
