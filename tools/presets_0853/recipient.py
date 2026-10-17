"""Launch a copied distribution in an owned Max 2027 recipient profile."""
from pathlib import Path
import argparse, hashlib, json, os, re, shutil, subprocess, sys, time, uuid, zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/procedural_lab/source_container_preview'))
from launch import DIRECTORIES

p = argparse.ArgumentParser()
p.add_argument('--package', required=True, type=Path)
p.add_argument('--exe', type=Path, help='Install through the actual copied EXE handler before launching this owned recipient.')
p.add_argument('--scale',type=float,choices=(0.,1.,1.5),default=0.)
a = p.parse_args()
package = a.package.resolve()
assert package.is_relative_to(ROOT / 'build') and package.suffix == '.mzp'
folder = ROOT / 'build/mcp-qualification' / ('foundation-presets0853-recipient-' + uuid.uuid4().hex[:8])
folder.mkdir()
copied = folder / package.name
shutil.copy2(package, copied)
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
with zipfile.ZipFile(copied) as archive:
    assert archive.testzip() is None
    manifest = json.loads(archive.read('manifest.json'))
    assert set(archive.namelist()) == set(manifest['files']) | {'manifest.json'}
    for name, digest in manifest['files'].items():
        target = (folder / 'payload' / name).resolve()
        assert target.is_relative_to(folder / 'payload') and ':' not in name and '\\' not in name
        assert hashlib.sha256(archive.read(name)).hexdigest() == digest
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(archive.read(name))
for relative in DIRECTORIES.values():
    (folder / relative).mkdir(parents=True, exist_ok=True)
profile = Path(os.environ['LOCALAPPDATA']) / 'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
ini = profile.read_text(encoding='utf-16')
for key, relative in DIRECTORIES.items():
    ini, count = re.subn(r'(?m)^' + re.escape(key) + r'=.*$', lambda _: key + '=' + str(folder / relative), ini)
    assert count == 1, key
(folder / 'max.ini').write_text(ini, encoding='utf-16')
# Trusted fixture script invokes the same packaged engine as MZP/EXE.
install = folder / 'install-owned.ps1'
install.write_text('''param([string]$Root)
$ErrorActionPreference='Stop'
Add-Type -Path (Join-Path $Root 'payload/CyrusInstaller.dll')
$data=[IO.File]::ReadAllBytes((Join-Path $Root 'payload/InstallInventory.txt'))
$engine=[Cyrus.Setup.InstallEngine]::new((Join-Path $Root 'payload'),[Cyrus.Setup.InstallEngine]::Hash($data))
$paths=[Cyrus.Setup.InstallPaths]::new((Join-Path $Root 'scripts'),(Join-Path $Root 'startup'),(Join-Path $Root 'macros'),$Root)
$release=$engine.Install($paths)
[IO.File]::WriteAllText((Join-Path $Root 'release.txt'),$release)
''', encoding='utf-8-sig')
if a.exe:
    executable=a.exe.resolve();assert executable.is_relative_to(ROOT/'build') and executable.suffix=='.exe'
    build=json.loads(executable.with_suffix('.build.json').read_text(encoding='utf-8'))
    assert build['package_sha256']==sha(copied) and build['artifact_sha256']==sha(executable)
    shutil.copy2(executable,folder/executable.name)
    subprocess.run(['powershell.exe','-NoProfile','-Sta','-File',str(ROOT/'tools/presets_0853/installer_exe.ps1'),
      '-Executable',str(folder/executable.name),'-OutputDir',str(folder),'-ProfileTemplate',str(folder/'max.ini')],check=True)
    release=Path((folder/'scripts/CyrusScatter/installed.txt').read_text(encoding='utf-8-sig').splitlines()[2])
else:
    subprocess.run(['pwsh', '-NoProfile', '-File', str(install), '-Root', str(folder)], check=True)
    release = Path((folder / 'release.txt').read_text(encoding='utf-8-sig'))
assert release.is_relative_to(folder / 'scripts')
# Bootstrap deliberately does not fileIn a product script: installed startup must do it.
shutil.copy2(ROOT / 'tools/mcp/development_transport.ms', folder / 'development_transport.ms')
bootstrap = '''global CyrusPerfHeadless=true,MCPFixtureDir=@"__FOLDER__/"
CustomControlsOptions.UIUserScaleFactor=__SCALE__
setSilentMode false;setQuietMode false
fileIn (MCPFixtureDir+"development_transport.ms")
try (
    if CyrusScatterObject==undefined do throw "Installed startup did not register Cyrus Scatter."
    if toLower (trimRight CyrusRecipeScriptDirectory "\\\\/")!=toLower @"__RELEASE__" do throw ("Unexpected script location: "+CyrusRecipeScriptDirectory)
    local log=createFile (MCPFixtureDir+"loaded.tsv"),process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    for name in #("AminScatter.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh","CyrusScatterEdit.dlm") do (
        local found=false
        for i=0 to process.Modules.Count-1 do (
            local module=process.Modules.Item[i]
            if toLower module.ModuleName==toLower name do (
                if toLower module.FileName!=toLower (pathConfig.appendPath @"__RELEASE__/bin" name) do throw "Wrong installed native module"
                found=true;format "%\\t%\\n" name module.FileName to:log
            )
        )
        if not found do throw ("Missing installed native module: "+name)
    )
    close log
    local bundled=CyrusRecipeBundledDirectory "0.85.3"
    if not doesDirectoryExist bundled do throw ("Missing installed library: "+bundled)
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"ready.json") "{}"
)catch((dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"startup-error.txt") (getCurrentException()+"\\n"+getCurrentExceptionStackTrace()))
'''.replace('__FOLDER__', folder.as_posix()).replace('__RELEASE__', str(release)).replace('__SCALE__',str(a.scale))
start = folder / 'start.ms'
start.write_text(bootstrap, encoding='utf-8-sig')
command = ['C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe', '-q', '-silent', '-i', str(folder / 'max.ini'),
           '-p', str(folder / 'Plugin.UserSettings.ini'), '-U', 'MAXScript', str(start), '-listenerlog', str(folder / 'listener.log')]
startup = subprocess.STARTUPINFO()
startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow = 0
process = subprocess.Popen(command, cwd=folder, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, startupinfo=startup)
metadata = {'pid': process.pid, 'command': command, 'max_year': 2027, 'output': str(folder), 'release': str(release),
            'custom_scale':a.scale,
            'installation_route': 'copied EXE actual Install handler' if a.exe else 'copied MZP shared installer engine',
            'package_sha256': sha(copied), 'script_sha256': sha(release / 'CyrusScatter.ms'), 'script': str(release / 'CyrusScatter.ms'),
            'binaries': {name: sha(release / 'bin' / name) for name in ['AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm']},
            'normal_profile_modified': False, 'development_transport': True, 'scope': 'Copied distribution and installed startup/native registration in owned profile'}
(folder / 'launch.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
print(folder, 'PID', process.pid, flush=True)
end = time.monotonic() + 240
while time.monotonic() < end:
    if (folder / 'startup-error.txt').exists(): raise RuntimeError((folder / 'startup-error.txt').read_text(encoding='utf-8'))
    if (folder / 'ready.json').exists(): print('Recipient ready', flush=True); break
    if process.poll() is not None: raise RuntimeError('Recipient exited before readiness')
    time.sleep(.5)
else: raise TimeoutError('Recipient readiness timeout; inspect existing owned process')
