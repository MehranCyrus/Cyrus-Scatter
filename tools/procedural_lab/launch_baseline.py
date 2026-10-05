"""Start the frozen 0.64 Max 2027 package in a disposable profile, without installation."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]


def main():
    output = ROOT / 'build/mcp-qualification/procedural07-baseline-064'
    output.mkdir(parents=True, exist_ok=False)
    for folder in ('startup', 'plugcfg', 'temp', 'bin', 'autoback'):
        (output / folder).mkdir()
    package = ROOT / 'dist/retained-mesh-0.64/CyrusScatter-0.64-Max2027.mzp'
    with zipfile.ZipFile(package) as archive:
        for name in ('AminScatter.dlx', 'CyrusScatterEdit.dlm', 'AminScatterObject.ms'):
            (output / 'bin' / name).write_bytes(archive.read(name))
    source = Path(os.environ['LOCALAPPDATA']) / 'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
    config = source.read_text(encoding='utf-16')
    for key, folder in {'Additional Startup Scripts': 'startup', 'PlugCFG': 'plugcfg', 'Temp': 'temp', 'Page File': 'temp', 'AutoBackup': 'autoback'}.items():
        config, count = re.subn(rf'(?m)^{re.escape(key)}=.*$', lambda _: key + '=' + str(output / folder), config)
        if count != 1:
            raise RuntimeError('Unrecognized private Max configuration: ' + key)
    (output / 'desktop.ini').write_text(config, encoding='utf-16')
    (output / 'plugins.ini').write_text('[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max 2027/PlugIns/\nCyrus=' + str(output / 'bin') + '\n[Help]\n')
    script = output / 'start.ms'
    script.write_text('(\n' + '\n'.join([
        'global MCPFixtureDir="' + output.as_posix() + '/"',
        'fileIn @"' + str(ROOT / 'tools/mcp/development_transport.ms') + '"',
        'fileIn @"' + str(output / 'bin/AminScatterObject.ms') + '"',
        'global CyrusPerfHeadless=true',
        'fileIn @"' + str(ROOT / 'tools/performance/CyrusPerformanceMonitor.ms') + '"',
        'local ready=createFile (MCPFixtureDir+"ready.txt");format "ready" to:ready;close ready',
    ]) + '\n)\n', encoding='utf-8')
    command = ['C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe', '-q', '-i', str(output / 'desktop.ini'), '-p', str(output / 'plugins.ini'), '-U', 'MAXScript', str(script), '-listenerlog', str(output / 'listener.log')]
    process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    metadata = {'pid': process.pid, 'output': str(output), 'package': str(package), 'package_sha256': hashlib.sha256(package.read_bytes()).hexdigest(), 'binaries': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in (output / 'bin').iterdir()}}
    (output / 'launch.json').write_text(json.dumps(metadata, indent=2))
    print(json.dumps(metadata, indent=2))


if __name__ == '__main__':
    main()
