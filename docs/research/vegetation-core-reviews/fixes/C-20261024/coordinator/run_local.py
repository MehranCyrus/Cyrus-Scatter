from pathlib import Path
import argparse
import json
import os
import subprocess
import time

stage = Path(__file__).resolve().parent
repo = stage.parents[1]
tools = Path('C:/Users/Mehran/AppData/Local/Programs/Python/Python310/Scripts')
vc = Path('C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.38.33130')
kits = Path('C:/Program Files (x86)/Windows Kits/10')
sdk = '10.0.19041.0'


def environment():
    env = os.environ.copy()
    task_temp = stage/'temp'
    task_temp.mkdir(exist_ok=True)
    env['TEMP'] = str(task_temp)
    env['TMP'] = str(task_temp)
    env['PATH'] = os.pathsep.join(map(str, [vc/'bin/Hostx64/x64', kits/'bin'/sdk/'x64'])) + os.pathsep + env['PATH']
    env['INCLUDE'] = os.pathsep.join(map(str, [vc/'include', vc/'atlmfc/include'] + [kits/'Include'/sdk/p for p in ('ucrt','shared','um','winrt','cppwinrt')]))
    env['LIB'] = os.pathsep.join(map(str, [vc/'lib/x64', vc/'atlmfc/lib/x64'] + [kits/'Lib'/sdk/p/'x64' for p in ('ucrt','um')]))
    return env


def run(label, command):
    receipt_path = stage/(label+'.json')
    log_path = stage/(label+'.log')
    assert not receipt_path.exists() and not log_path.exists(), 'Use a fresh run label'
    started = time.monotonic()
    with log_path.open('w', encoding='utf-8') as log:
        result = subprocess.run([str(x) for x in command], cwd=repo, env=environment(), stdout=log, stderr=subprocess.STDOUT)
    receipt = {'command': [str(x) for x in command], 'cwd': str(repo), 'exit_code': result.returncode, 'wall_seconds': time.monotonic()-started,
               'scope': 'Windows headless native prototype; no Max SDK or host used'}
    receipt_path.write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(receipt, indent=2), flush=True)
    print(log_path.read_text(errors='replace')[-5200:], flush=True)
    if result.returncode:
        raise SystemExit(result.returncode)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['configure', 'build', 'ctest'])
    parser.add_argument('--source', type=Path, default=stage/'starter')
    parser.add_argument('--binary', type=Path, default=stage/'release')
    parser.add_argument('--label', required=True)
    parser.add_argument('--pattern', default='^delivery_')
    parser.add_argument('--jolt', action='store_true')
    args = parser.parse_args()
    if args.action == 'configure':
        cmd = [tools/'cmake.exe','-S',args.source,'-B',args.binary,'-G','Ninja','-DCMAKE_BUILD_TYPE=Release','-DBUILD_TESTING=ON','-DCMAKE_CXX_COMPILER=cl','-DCMAKE_EXPORT_COMPILE_COMMANDS=ON']
        if args.jolt:
            cmd += [f'-DCYRUS_COLLISION_JOLT_SOURCE_ROOT={repo / "build/physics-lab-dependencies/jolt-1b2e77e3c6c09709e5edc79dc208459b8ff32051"}']
    elif args.action == 'build':
        cmd = [tools/'cmake.exe','--build',args.binary,'--parallel','6']
    else:
        cmd = [tools/'ctest.exe','--test-dir',args.binary,'-C','Release','-R',args.pattern,'--timeout','30','--output-on-failure','-V']
    run(args.label, cmd)
