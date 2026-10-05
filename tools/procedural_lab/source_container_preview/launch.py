"""Local artist preview of the qualified ordinary build; no product installation."""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import re
import shutil
import subprocess
import time
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
WORKSPACE = ROOT / 'build/user-tests/source-containers-20261005'
MAX = Path('C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe')
CANDIDATE = ROOT / 'build/qualification-07-20261005/final02'
QUALIFIED = ROOT / 'build/mcp-qualification/procedural07-ui-final02-ordinary'
SCRIPT = CANDIDATE / 'source/AminScatter/scripts/AminScatterObject.ms'
SCRIPT_HASH = '4f88237f486d49e067a6f3d65a28d46dea457de15cd4aa65c1ecd4501d11fd33'
MODULES = {
    'AminScatter.dlx': '4a098d7e4c66350a09738dfa239880150394d7a2e2fec944754e8941d96bbe99',
    'CyrusBrush.dlx': 'b4e71258329f1ffb05779d8cad82748132e6deaec6e550d8e48378cefe71826c',
    'CyrusBrushStorage.dlh': 'c669007ae8dae77f8c09464f970b544902f5ccfdef5691d28957571b27c45f49',
    'CyrusScatterEdit.dlm': 'ecf052b72e61f6758ae49ccaf4feb9937dac0a342a1ea7674500ed94ac13bf39',
}
DIRECTORIES = {
    'Additional Startup Scripts': 'startup', 'Additional Scripts': 'scripts',
    'Additional Macros': 'macros', 'PlugCFG': 'plugcfg', 'Temp': 'temp',
    'Page File': 'temp', 'AutoBackup': 'project/autoback', 'ProjectFolder': 'project',
    'Scenes': 'project/scenes', 'MaxStart': 'project/scenes', 'MaxData': 'maxdata',
    'Hardware Shaders Cache': 'shadercache', 'PlugCFG_ln': 'plugcfg_ln',
    'Additional Icons': 'icons', 'Additional Startup Templates': 'templates',
    'Import': 'project/import', 'Export': 'project/export', 'Previews': 'project/previews',
    'RenderOutput': 'project/renderoutput', 'Materials': 'project/materiallibraries',
    'Images': 'project/sceneassets/images', 'Sounds': 'project/sceneassets/sounds',
    'Animations': 'project/sceneassets/animations', 'RenderAssets': 'project/sceneassets/renderassets',
    'Archives': 'project/archives', 'Downloads': 'project/downloads', 'BitmapProxies': 'project/proxies',
    'VideoPost': 'project/vpost', 'Expressions': 'project/express', 'RenderPresets': 'project/renderpresets',
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-only', action='store_true')
    parser.add_argument('--smoke-test', action='store_true')
    args = parser.parse_args()
    if not MAX.is_file() or digest(SCRIPT) != SCRIPT_HASH:
        raise RuntimeError('The qualified Max executable/script is missing or changed.')
    for name, expected in MODULES.items():
        if digest(QUALIFIED / 'bin' / name) != expected:
            raise RuntimeError('Qualified binary changed: ' + name)
    template = (QUALIFIED / 'max.ini').read_text(encoding='utf-16')
    for key in DIRECTORIES:
        if len(re.findall(r'(?m)^' + re.escape(key) + r'=.*$', template)) != 1:
            raise RuntimeError('Private profile field is not unique: ' + key)
    if args.verify_only:
        print('PASS: four ordinary DLL hashes, script hash, and private-profile fields.')
        return

    session = WORKSPACE / 'sessions' / (datetime.datetime.now().strftime('%Y%m%d-%H%M%S') + '-' + uuid.uuid4().hex[:8])
    session.mkdir(parents=True, exist_ok=False)
    (session / 'bin').mkdir()
    ini = template
    for key, relative in DIRECTORIES.items():
        destination = session / relative
        destination.mkdir(parents=True, exist_ok=True)
        ini = re.sub(r'(?m)^' + re.escape(key) + r'=.*$', lambda _: key + '=' + str(destination), ini)
    (session / 'max.ini').write_text(ini, encoding='utf-16')
    for name, expected in MODULES.items():
        target = session / 'bin' / name
        shutil.copy2(QUALIFIED / 'bin' / name, target)
        if digest(target) != expected:
            raise RuntimeError('Copied module mismatch: ' + name)
    script = session / 'scripts/CyrusScatter.ms'
    shutil.copy2(SCRIPT, script)
    if digest(script) != SCRIPT_HASH:
        raise RuntimeError('Copied script mismatch')
    (session / 'plugins.ini').write_text(
        '[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max 2027/PlugIns\n'
        + 'CyrusContainerPreview=' + str(session / 'bin') + '\n[Help]\n')
    ready = session / 'ready.txt'
    error = session / 'error.txt'
    scene = session / 'project/scenes/Source_Containers_Demo.max'
    expected_rows = ',\n'.join('#(@"' + name + '",@"' + str(session / 'bin' / name) + '")' for name in MODULES)
    bootstrap = '''global AminScatterObject,cyrusOwnedLabStatus,cyrusOwnedLabBrushEnd
(
    try (
        local expected=#(__MODULES__),p=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
        local log=createFile @"__LOADED__"
        for spec in expected do (
            local found=false
            for i=0 to p.Modules.Count-1 do (
                local m=p.Modules.Item[i]
                if toLower m.ModuleName==toLower spec[1] do (
                    if toLower m.FileName!=toLower spec[2] do throw ("Different Cyrus DLL already loaded: "+m.FileName)
                    found=true;format "%\\t%\\n" m.ModuleName m.FileName to:log
                )
            )
            if not found do throw ("Required private DLL was not loaded: "+spec[1])
        )
        close log
        if cyrusOwnedLabStatus!=undefined or cyrusOwnedLabBrushEnd!=undefined do throw "Unexpected development authority"
        fileIn @"__SCRIPT__"
        if AminScatterObject==undefined do throw "Cyrus script did not register"
        fileIn @"__DEMO__"
        saveMaxFile @"__SCENE__" quiet:true
        (dotNetClass "System.IO.File").WriteAllText @"__READY__" "PASS: matching ordinary modules and script; source-container demo ready."
        if __SMOKE__ do quitMAX #noPrompt
    ) catch (
        local message=getCurrentException()
        (dotNetClass "System.IO.File").WriteAllText @"__ERROR__" message
        if __SMOKE__ then quitMAX #noPrompt else messageBox message title:"Cyrus private preview failed"
    )
)
'''
    replacements = {
        '__MODULES__': expected_rows, '__LOADED__': str(session / 'loaded.tsv'),
        '__SCRIPT__': str(script), '__DEMO__': str(HERE / 'demo.ms'), '__SCENE__': str(scene),
        '__READY__': str(ready), '__ERROR__': str(error), '__SMOKE__': 'true' if args.smoke_test else 'false',
    }
    for key, value in replacements.items():
        bootstrap = bootstrap.replace(key, value)
    start = session / 'start.ms'
    start.write_text(bootstrap, encoding='utf-8-sig')
    command = [str(MAX), '-q', '-i', str(session / 'max.ini'), '-p', str(session / 'plugins.ini'),
               '-U', 'MAXScript', str(start), '-listenerlog', str(session / 'listener.log')]
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0 if args.smoke_test else 1
    process = subprocess.Popen(command, cwd=session, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, startupinfo=startup)
    launch = {'pid': process.pid, 'profile': str(session), 'command': command, 'scene': str(scene),
              'native': MODULES, 'script_sha256': SCRIPT_HASH, 'smoke_test': args.smoke_test,
              'normal_Max_profile_installed': False}
    (session / 'launch.json').write_text(json.dumps(launch, indent=2) + '\n')
    print('Separate Max preview launched. Session: ' + str(session), flush=True)
    if not args.smoke_test:
        return
    deadline = time.monotonic() + 120
    while not ready.exists() and not error.exists() and process.poll() is None and time.monotonic() < deadline:
        time.sleep(.5)
    if error.exists() or not ready.exists():
        if process.poll() is None:
            process.terminate()  # Only this process created above; no other Max process is targeted.
            process.wait(timeout=20)
        raise RuntimeError(error.read_text(encoding='utf-8-sig') if error.exists() else 'Private startup timed out or exited')
    process.wait(timeout=30)
    launch['status'] = 'PASS'
    launch['normal_exit'] = True
    launch['scope'] = 'Private launch, actual module paths, script load and demo population/parking/reentry; no new pointer qualification'
    (WORKSPACE / 'smoke-test.json').write_text(json.dumps(launch, indent=2) + '\n')
    print(ready.read_text(encoding='utf-8-sig'))


if __name__ == '__main__':
    main()
