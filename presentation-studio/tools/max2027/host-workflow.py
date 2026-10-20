"""Owned Max 2027 camera qualification; never attaches to an existing Max process."""
from pathlib import Path
import argparse
import datetime
import hashlib
import json
import os
import re
import shutil
import subprocess
import uuid

ROOT = Path(__file__).resolve().parents[3]
APP = ROOT / 'presentation-studio'
MAX = Path('C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe')
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


def launch():
    source = Path(os.environ['LOCALAPPDATA']) / 'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
    session = ROOT / 'build' / ('max-camera-2027-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S') + '-' + uuid.uuid4().hex[:6])
    session.mkdir(parents=True, exist_ok=False)
    ini = source.read_text(encoding='utf-16')
    for key, relative in DIRECTORIES.items():
        destination = session / relative
        destination.mkdir(parents=True, exist_ok=True)
        pattern = r'(?m)^' + re.escape(key) + r'=.*$'
        if len(re.findall(pattern, ini)) != 1:
            raise RuntimeError('Profile field is not unique: ' + key)
        ini = re.sub(pattern, lambda _: key + '=' + str(destination), ini)
    (session / 'max.ini').write_text(ini, encoding='utf-16')
    (session / 'plugins.ini').write_text('[Directories]\nAdditional MAX plug-ins=' + MAX.parent.as_posix() + '/PlugIns\n[Help]\n')
    start = 'global MCPFixtureDir=@"' + session.as_posix() + '/"\nfileIn @"' + (ROOT / 'tools/mcp/development_transport.ms').as_posix() + '"\n(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"ready.txt") ((maxVersion()) as string)\n'
    (session / 'start.ms').write_text(start, encoding='utf-8-sig')
    command = [str(MAX), '-q', '-silent', '-i', str(session / 'max.ini'), '-p', str(session / 'plugins.ini'), '-U', 'MAXScript', str(session / 'start.ms'), '-listenerlog', str(session / 'listener.log')]
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    process = subprocess.Popen(command, cwd=session, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, startupinfo=startup)
    metadata = {'pid': process.pid, 'run': str(session), 'command': command, 'normal_profile_path': str(source), 'normal_profile_sha256': digest(source)}
    (session / 'launch.json').write_text(json.dumps(metadata, indent=2))
    print(json.dumps(metadata, indent=2))


def owned_session(path):
    session = Path(path).resolve()
    if session.parent != (ROOT / 'build').resolve() or not session.name.startswith('max-camera-2027-'):
        raise RuntimeError('Session must be an owned max-camera-2027 directory under build.')
    metadata = json.loads((session / 'launch.json').read_text())
    if Path(metadata['run']).resolve() != session or Path(metadata['command'][0]).resolve() != MAX.resolve():
        raise RuntimeError('Session provenance does not match.')
    return session, metadata


def queue(session, text):
    if not (session / 'ready.txt').exists():
        raise RuntimeError('Max is not ready yet; inspect listener.log and retry after startup.')
    request = session / ('request-' + uuid.uuid4().hex + '.ms')
    request.write_text(text, encoding='utf-8-sig')
    temp = session / 'dev-request.next'
    temp.write_text(request.as_posix())
    temp.replace(session / 'dev-request.txt')
    print('Queued: ' + str(request) + '\nInspect dev-result.txt for this exact request before proceeding.')


def collect(session, metadata):
    if (session / 'qualification-complete.txt').read_text() != 'PASS':
        raise RuntimeError('Host fixture has not passed.')
    target = APP / 'exports/fixtures/max-camera'
    target.mkdir(parents=True, exist_ok=True)
    names = ['free.json', 'target.json', 'physical.json', 'path.json', 'metres.json']
    names += [name + suffix for name in ['free', 'target', 'physical', 'path'] for suffix in ['-reference.json', '-subframe-reference.json']]
    for name in names:
        shutil.copy2(session / name, target / name)
    receipt = dict(metadata, version=(session / 'ready.txt').read_text(), host_checks=(session / 'host-checks.txt').read_text().splitlines(),
                   exporter_sha256=digest(APP / 'tools/max2027/CyrusCameraExporter.ms'), fixture_sha256=digest(APP / 'tools/max2027/qualification.ms'),
                   normal_profile_unchanged=digest(Path(metadata['normal_profile_path'])) == metadata['normal_profile_sha256'],
                   resources={name: digest(target / name) for name in names})
    qualification = APP / 'exports/qualification/max-camera'
    qualification.mkdir(parents=True, exist_ok=True)
    (qualification / 'max-host.json').write_text(json.dumps(receipt, indent=2) + '\n')
    shutil.copy2(session / 'host-checks.txt', qualification / 'host-checks.txt')
    print('Collected real Max exports and references: ' + str(target))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['launch', 'status', 'qualify', 'collect', 'close'])
    parser.add_argument('--session')
    args = parser.parse_args()
    if args.action == 'launch':
        launch()
    else:
        session, metadata = owned_session(args.session)
        if args.action == 'status':
            for name in ['ready.txt', 'dev-result.txt', 'qualification-complete.txt']:
                print(name + ': ' + ((session / name).read_text(encoding='utf-8-sig') if (session / name).exists() else 'pending'))
        elif args.action == 'qualify':
            queue(session, 'global CyrusCameraExporterNoUI=true\nfileIn @"' + (APP / 'tools/max2027/CyrusCameraExporter.ms').as_posix() + '"\nfileIn @"' + (APP / 'tools/max2027/qualification.ms').as_posix() + '"\n')
        elif args.action == 'collect':
            collect(session, metadata)
        else:
            # The request is evaluated only by the timer in this owned profile, never another Max session.
            queue(session, 'quitMAX #noPrompt\n')
