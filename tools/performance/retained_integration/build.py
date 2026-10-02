"""Build the integrated candidate in a fresh private directory; no installation."""
from pathlib import Path
import argparse
import json
import hashlib
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
from build_max import compiler_environment

BASE = ROOT / 'build/retained-integration-2026-10-02'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--year', type=int, choices=[2026, 2027], default=2027)
    args = parser.parse_args()
    output = BASE / f'max{args.year}'
    output.mkdir(parents=True, exist_ok=True)
    env = compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'), '14.38.33130', '10.0.19041.0')
    sdk = ROOT / f'build/tooling/max{args.year}-sdk/Program Files/Autodesk/3ds Max {args.year} SDK/maxsdk'
    subprocess.run(['node', 'tools/ui/generate.cjs'], cwd=ROOT / 'AminScatter', check=True)
    commands = [
        ['cmake', '-S', str(ROOT / 'AminScatter'), '-B', str(output), '-G', 'NMake Makefiles', '-DCMAKE_BUILD_TYPE=Release', f'-DCYRUS_MAX_YEAR={args.year}', f'-DMAXSDK_ROOT={sdk}'],
        ['cmake', '--build', str(output)],
        ['ctest', '--test-dir', str(output), '--output-on-failure'],
    ]
    for index, command in enumerate(commands):
        result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True)
        (output / f'build-{index}.log').write_text(result.stdout + result.stderr, encoding='utf-8')
        print((result.stdout + result.stderr)[-14000:], flush=True)
        result.check_returncode()
    files = [output / 'AminScatter.dlx', output / 'CyrusScatterEdit.dlm', ROOT / 'AminScatter/scripts/AminScatterObject.ms']
    (output / 'identity.json').write_text(json.dumps({str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}, indent=2), encoding='utf-8')

if __name__ == '__main__':
    main()
