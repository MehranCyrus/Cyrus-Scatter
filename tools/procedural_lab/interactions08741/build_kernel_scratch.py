"""Incrementally build the 2027-configured interaction test in an owned scratch tree.

This fast numerical development build is not a sealed release receipt. The
eventual delivery must use the full frozen-input SDK build and test workflow.
"""
from argparse import ArgumentParser
from pathlib import Path
import importlib.util
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
parser = ArgumentParser()
parser.add_argument('--output', required=True, type=Path)
args = parser.parse_args()
out = args.output.resolve()
if not out.is_relative_to(ROOT / 'build'):
    raise ValueError('An owned build directory is required')
out.mkdir(parents=True, exist_ok=True)
spec = importlib.util.spec_from_file_location('cyrus_build_max', ROOT / 'tools/build_max.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
env = module.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),
                                  '14.38.33130', '10.0.19041.0')
sdk = ROOT / 'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk'
configure = ['cmake', '-S', str(ROOT/'AminScatter'), '-B', str(out), '-G', 'Ninja',
             '-DCMAKE_BUILD_TYPE=Release', '-DBUILD_TESTING=ON', '-DAMIN_BUILD_MAX=ON',
             '-DCYRUS_NATIVE_LICENSE_EXPERIMENT=OFF', '-DCYRUS_LICENSE_INSTALLATION_CONTEXT=OFF',
             '-DCYRUS_PREVIEW_TEST_FAULTS=OFF', '-DCYRUS_PLACEMENT_QUALIFICATION=OFF',
             '-DCYRUS_TEAM_LICENSE=ON', '-DCYRUS_TEAM_TRUST_DIR='+str(ROOT/'CyrusLicensing/team'),
             '-DCYRUS_MAX_YEAR=2027', '-DMAXSDK_ROOT='+str(sdk)]
for label, cmd in [('configure', configure),
                   ('build', ['cmake', '--build', str(out), '--target', 'interactions_tests', '--parallel', '4'])]:
    result = subprocess.run(cmd, cwd=ROOT, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (out / ('scratch-' + label + '.log')).write_text(result.stdout, encoding='utf-8')
    print(label, result.returncode, flush=True)
    if result.returncode:
        print(result.stdout[-12000:], flush=True)
        raise SystemExit(result.returncode)
