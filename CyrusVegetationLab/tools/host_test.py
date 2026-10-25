"""Scripted owned-profile Max 2027 qualification. Never touches an artist scene."""
from pathlib import Path
import argparse, hashlib, importlib.util, json, os, re, shutil, subprocess, time, zipfile
ROOT=Path(__file__).resolve().parents[2]
PROJECT=ROOT/'CyrusVegetationLab'
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for key in ('build','output','fixture'):parser.add_argument('--'+key,type=Path,required=True)
    parser.add_argument('--script',type=Path,default=PROJECT/'scripts/CyrusVegetationLab.ms')
    parser.add_argument('--package',type=Path)
    parser.add_argument('--restart-fixture',type=Path)
    parser.add_argument('--timeout',type=int,default=240)
    parser.add_argument('--development',action='store_true')
    parser.add_argument('--visible',action='store_true',help='Show only the owned process for an authorized physical UI test')
    args=parser.parse_args();folder=args.output.resolve();native=args.build.resolve()
    if not folder.is_relative_to(ROOT/'build'):raise RuntimeError('Owned profiles must stay inside ignored build/')
    folder.mkdir(parents=True,exist_ok=False)
    receipt=json.loads((native/'receipt.json').read_text())
    if not args.development:
        if receipt['status']!='complete':raise RuntimeError('Native build is incomplete')
        for name,expected in receipt['source_hashes'].items():
            if sha(PROJECT/name)!=expected:raise RuntimeError('Build source changed: '+name)
        for name,expected in receipt['shared_source_hashes'].items():
            if sha(ROOT/name)!=expected:raise RuntimeError('Shared build input changed: '+name)
    spec=importlib.util.spec_from_file_location('cvl_owned_paths',ROOT/'tools/procedural_lab/source_container_preview/launch.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
    for relative in {'bin',*mod.DIRECTORIES.values()}:(folder/relative).mkdir(parents=True,exist_ok=True)
    template=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini';original=template.read_bytes();ini=original.decode('utf-16')
    for key,relative in mod.DIRECTORIES.items():
        ini,count=re.subn(r'(?m)^'+re.escape(key)+r'=.*$',lambda _:key+'='+str(folder/relative),ini)
        if count!=1:raise RuntimeError('Profile field is missing or ambiguous: '+key)
    (folder/'max.ini').write_text(ini,encoding='utf-16')
    hashes={}
    for name in ('CyrusVegetationLab.dlx','CyrusVegetationStorage.dlh'):
        shutil.copy2(native/name,folder/'bin'/name);hashes[name]=sha(folder/'bin'/name)
        if not args.development and hashes[name]!=receipt['binaries'][name]:raise RuntimeError('Native module differs from build')
    script=folder/'scripts/CyrusVegetationLab.ms';shutil.copy2(args.script,script)
    if not args.development and sha(script)!=receipt['source_hashes']['scripts/CyrusVegetationLab.ms']:raise RuntimeError('Script differs from receipt')
    fixture=folder/'fixture.ms';shutil.copy2(args.fixture,fixture)
    (folder/'plugins.ini').write_text('[Directories]\nStandard=C:/Program Files/Autodesk/3ds Max 2027/stdplugs\nVegetationLab='+str(folder/'bin')+'\n[Help]\n')
    install=''
    if args.package:
        package_root=folder/'package';package_root.mkdir()
        with zipfile.ZipFile(args.package) as archive:
            if archive.testzip():raise RuntimeError('Package CRC failure')
            for entry in archive.infolist():
                if not (package_root/entry.filename).resolve().is_relative_to(package_root):raise RuntimeError('Unsafe ZIP path')
            archive.extractall(package_root)
        install=r'''
    cvlStage "installer"
    fn cvlCanonical path = (toLower (substituteString ((dotNetClass "System.IO.Path").GetFullPath path) "\\" "/"))
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"install-paths.txt") ((getMAXIniFile())+"\n"+(getDir #userScripts)+"\n"+(getDir #userStartupScripts))
    if cvlCanonical (getFilenamePath (getMAXIniFile()))!=cvlCanonical CVLTestDir do throw "Installer INI path escaped owned profile."
    if findString (cvlCanonical (getDir #userScripts)) (cvlCanonical CVLTestDir)!=1 do throw "Installer scripts path escaped owned profile."
    if findString (cvlCanonical (getDir #userStartupScripts)) (cvlCanonical CVLTestDir)!=1 do throw "Installer startup path escaped owned profile."
    global CVLInstallerValidateOnly=true
    global CVLInstallIndependentLab
    fileIn @"__INSTALL__"
    CVLInstallIndependentLab quiet:true
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"installed.txt") (getINISetting (pathConfig.appendPath (getFilenamePath (getMAXIniFile())) "Plugin.UserSettings.ini") "Directories" "CyrusVegetationLab")
'''.replace('__INSTALL__',(package_root/'install.ms').as_posix())
    bootstrap=r'''
global CVLTestDir=@"__FOLDER__/"
fn cvlStage name = ((dotNetClass "System.IO.File").AppendAllText (CVLTestDir+"__PREFIX__stages.txt") (name+"\n"))
cvlStage "bootstrap"
setSilentMode false
setQuietMode false
fn cvlResetScene = (setSilentMode true;setQuietMode true;try(resetMaxFile #noPrompt)catch(setSilentMode false;setQuietMode false;throw());setSilentMode false;setQuietMode false)
try
(
    __LOAD__
    local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    local log=createFile (CVLTestDir+"__PREFIX__loaded.tsv")
    for i=0 to process.Modules.Count-1 do (local item=process.Modules.Item[i];if matchPattern item.ModuleName pattern:"CyrusVegetation*" do format "%\t%\n" item.ModuleName item.FileName to:log)
    close log
    cvlStage "fixture"
    fileIn @"__FIXTURE__"
    __INSTALL__
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"__PREFIX__completed.json") "{}"
)
catch ((dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"__PREFIX__error.txt") (getCurrentException()+"\nSOURCE: "+(getErrorSourceFileName() as string)+" LINE: "+(getErrorSourceFileLine() as string)+"\n"+getCurrentExceptionStackTrace()))
quitMax #noPrompt
'''.replace('__FOLDER__',folder.as_posix())
    def run(prefix,fixture,load,install):
        start=folder/(prefix+'start.ms');start.write_text(bootstrap.replace('__PREFIX__',prefix).replace('__FIXTURE__',fixture.as_posix()).replace('__LOAD__',load).replace('__INSTALL__',install),encoding='utf-8-sig')
        command=['C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe','-q','-silent','-i',str(folder/'max.ini'),'-p',str(folder/'plugins.ini'),'-U','MAXScript',str(start),'-listenerlog',str(folder/(prefix+'listener.log'))]
        startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=5 if args.visible else 0
        process=subprocess.Popen(command,cwd=folder,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,startupinfo=startup)
        metadata={'pid':process.pid,'command':command,'host':2027,'development':args.development,'computer_use':False,'max_executable_sha256':sha(command[0]),'binaries':hashes,'script_sha256':sha(script),'fixture_sha256':sha(fixture),'profile_template_sha256':sha(template)}
        (folder/(prefix+'launch.json')).write_text(json.dumps(metadata,indent=2));print(f'Owned Max 2027 PID {process.pid}: {folder} ({prefix or "initial"})',flush=True)
        deadline=time.monotonic()+args.timeout
        while process.poll() is None and time.monotonic()<deadline:time.sleep(1)
        if process.poll() is None:
            process.terminate();process.wait(timeout=30);raise RuntimeError('Owned Max process timed out; retained logs')
        if template.read_bytes()!=original:raise RuntimeError('Normal profile changed during run; inspect concurrent activity')
        error=folder/(prefix+'error.txt')
        if error.exists():print(error.read_text(encoding='utf-8'),flush=True);raise SystemExit(1)
        if not (folder/(prefix+'completed.json')).exists():raise RuntimeError(f'Max exited without completion ({process.returncode})')
        loaded=(folder/(prefix+'loaded.tsv')).read_text(encoding='utf-8-sig')
        expected_root=folder/'bin' if not prefix else Path((folder/'installed.txt').read_text(encoding='utf-8-sig'))
        for name,expected in hashes.items():
            if str(expected_root/name).lower().replace('\\','/') not in loaded.lower().replace('\\','/') or sha(expected_root/name)!=expected:raise RuntimeError('Loaded module identity differs: '+name)
        metadata.update(status='pass',exit_code=process.returncode,normal_profile_modified=False,loaded_directory=str(expected_root));(folder/(prefix+'receipt.json')).write_text(json.dumps(metadata,indent=2))
    run('',fixture,'fileIn @"'+script.as_posix()+'"',install)
    if args.restart_fixture:
        if not args.package:raise RuntimeError('Restart verification requires a package')
        (folder/'plugins.ini').write_text('[Directories]\nStandard=C:/Program Files/Autodesk/3ds Max 2027/stdplugs\n[Help]\n')
        second=folder/'restart-fixture.ms';shutil.copy2(args.restart_fixture,second)
        run('restart-',second,'global CVLOpen; if CVLOpen==undefined do throw "Installed startup did not load Vegetation Lab."','')
    print('PASS scripted Max 2027 qualification; artist profile preserved',flush=True)
if __name__=='__main__':main()
