"""Launch one owned Max profile with pinned development/test payloads."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,os,re,subprocess,time
ROOT=Path(__file__).resolve().parents[3]
NAMES=('AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    p=argparse.ArgumentParser();p.add_argument('--year',type=int,choices=(2024,2026,2027),required=True)
    p.add_argument('--output',type=Path,required=True);p.add_argument('--payload',type=Path,required=True);p.add_argument('--script',type=Path,required=True)
    p.add_argument('--data',type=Path,required=True);p.add_argument('--renderer',action='store_true');p.add_argument('--visible',action='store_true');p.add_argument('--timeout',type=int,default=900)
    p.add_argument('--fixture-archive',type=Path)
    p.add_argument('--installed',type=Path,help='Exact owned installer installed.json; exercise automatic startup')
    p.add_argument('--ocio-default',action='store_true',help='Explicitly configure this owned test scene to the supported default OCIO profile')
    a=p.parse_args();out=a.output.resolve();payload=a.payload.resolve();data=a.data.resolve()
    if not out.is_relative_to(ROOT/'build') or not data.is_relative_to(ROOT/'build'):raise ValueError('Owned build paths required')
    out.mkdir(parents=True,exist_ok=False);data.mkdir(parents=True,exist_ok=False)
    spec=importlib.util.spec_from_file_location('profile',ROOT/'tools/procedural_lab/source_container_preview/launch.py');profile=importlib.util.module_from_spec(spec);spec.loader.exec_module(profile)
    installed=None
    if a.installed:
        installed=json.loads(a.installed.read_text())[str(a.year)];payload=Path(installed['release']).resolve()
        if not payload.is_relative_to(ROOT/'build'):raise ValueError('Owned installed release required')
    for rel in profile.DIRECTORIES.values():(out/rel).mkdir(parents=True,exist_ok=True)
    artist=Path(os.environ['LOCALAPPDATA'])/f'Autodesk/3dsMax/{a.year} - 64bit/ENU/3dsMax.ini'
    template=artist if artist.exists() else Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
    original=artist.read_bytes() if artist.exists() else None
    ini=template.read_text(encoding='utf-16')
    for key,rel in profile.DIRECTORIES.items():
        destination=Path(installed['startup']) if installed and key=='Additional Startup Scripts' else Path(installed['macros']) if installed and key=='Additional Macros' else out/rel
        ini,count=re.subn(r'(?m)^'+re.escape(key)+r'=.*$',lambda _:key+'='+str(destination),ini)
        if count!=1:raise ValueError('Private INI directory boundary missing: '+key)
    (out/'max.ini').write_text(ini,encoding='utf-16')
    plugins=f'[Directories]\nStandard=C:/Program Files/Autodesk/3ds Max {a.year}/stdplugs\n'
    if a.renderer:plugins+=f'Installed=C:/Program Files/Autodesk/3ds Max {a.year}/Plugins/\n'
    if installed:plugins+='OwnedScatter='+str(payload/'bin')+'\n'
    (out/'plugins.ini').write_text(plugins+'[Help]\n')
    files={name:payload/('bin' if installed and name in NAMES else '')/name for name in (*NAMES,'CyrusScatter.ms','CyrusGallery.dll')}
    for file in files.values():
        if not file.is_file():raise FileNotFoundError(file)
    start='global GardenRun=@"'+out.as_posix()+'/"\nglobal CyrusSharedLibraryRootOverride=@"'+(data/'author').as_posix()+'"\ntry (\n'
    if a.fixture_archive:
        fixture=a.fixture_archive.resolve()
        if not fixture.is_relative_to(ROOT/'build') or not fixture.is_file():raise ValueError('Explicit owned fixture archive required')
        start+='global GardenLibraryArchive=@"'+fixture.as_posix()+'"\n'
    if installed:start+='if CyrusLoadedScriptFingerprint==undefined do throw "Installed automatic startup did not load the paired script"\n'
    else:
        for name in NAMES:start+='loadDllsFromDir @"'+payload.as_posix()+'/" "'+name+'"\n'
        start+='fileIn @"'+(payload/'CyrusScatter.ms').as_posix()+'"\n'
    preflight='''from pathlib import Path
import hashlib,json
from pymxs import runtime as r
expected=EXPECTED
modules=r.execute('(local p=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(); for i=0 to p.Modules.Count-1 collect #(p.Modules.Item[i].ModuleName,p.Modules.Item[i].FileName))')
loaded={str(x[0]).lower():Path(str(x[1])) for x in modules}
assert int(r.maxVersion()[0])==HOST
for name,path in expected.items():assert loaded[name.lower()].resolve()==Path(path).resolve(),name
assert str(r.CyrusLoadedScriptFingerprint)==FINGERPRINT
(Path(str(r.GardenRun))/'loaded-identity.json').write_text(json.dumps({'host':YEAR,'modules':{name:{'path':str(loaded[name.lower()]),'sha256':hashlib.sha256(loaded[name.lower()].read_bytes()).hexdigest()} for name in expected},'script_fingerprint':str(r.CyrusLoadedScriptFingerprint)},indent=2))
'''.replace('EXPECTED',repr({name:str(files[name]) for name in NAMES})).replace('HOST',str((a.year-1998)*1000)).replace('YEAR',str(a.year)).replace('FINGERPRINT',repr(re.search(r'CyrusLoadedScriptFingerprint="([0-9a-f]{64})"',files['CyrusScatter.ms'].read_text(encoding='utf-8-sig'))[1]))
    (out/'preflight.py').write_text(preflight,encoding='utf-8');start+='python.ExecuteFile @"'+(out/'preflight.py').as_posix()+'"\n'
    start+='if not doesFileExist (GardenRun+"loaded-identity.json") do throw "Loaded identity preflight failed"\n'
    start+='global GardenSupportedOCIO='+('true' if a.ocio_default else 'false')+'\n'
    if a.ocio_default:start+='ColorPipelineMgr.Mode=#OCIO_Default\n'
    start+=('python.ExecuteFile' if a.script.suffix.lower()=='.py' else 'fileIn')+' @"'+a.script.resolve().as_posix()+'"\n'
    start+='format \"Owned editor host ready.\\n\"\n'
    start+=')catch((dotNetClass "System.IO.File").WriteAllText (GardenRun+"bootstrap-error.txt") (getCurrentException()+"\\n"+getCurrentExceptionStackTrace());quitMax #noPrompt)\n'
    (out/'start.ms').write_text(start,encoding='utf-8-sig')
    exe=Path(f'C:/Program Files/Autodesk/3ds Max {a.year}/3dsmax.exe')
    cmd=[str(exe),'-q','-silent','-i',str(out/'max.ini'),'-p',str(out/'plugins.ini'),'-U','MAXScript',str(out/'start.ms'),'-listenerlog',str(out/'listener.log')]
    si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=5 if a.visible else 0
    proc=subprocess.Popen(cmd,cwd=out,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,startupinfo=si)
    receipt={'pid':proc.pid,'host':a.year,'command':cmd,'script':str(a.script.resolve()),'script_sha256':sha(a.script),'payload':{name:sha(path) for name,path in files.items()},'artist_ini_sha256':hashlib.sha256(original).hexdigest() if original else None,'data':str(data),'explicit_test_ocio_default':a.ocio_default}
    (out/'launch.json').write_text(json.dumps(receipt,indent=2));print('Owned Max',a.year,'PID',proc.pid,flush=True)
    until=time.monotonic()+a.timeout
    while proc.poll() is None and time.monotonic()<until:time.sleep(1)
    timeout=proc.poll() is None
    if timeout:
        print('Owned profile stays open for the scoped editor campaign',flush=True)
        return
    unchanged=(artist.read_bytes()==original) if original is not None else not artist.exists()
    errors={n:(out/n).read_text(encoding='utf-8-sig') for n in ('error.txt','bootstrap-error.txt') if (out/n).exists()}
    passed=not timeout and proc.returncode==0 and unchanged and not errors and (out/'completed.json').exists() and (out/'loaded-identity.json').exists()
    receipt.update(status='pass' if passed else 'failed',exit_code=proc.returncode,timed_out=timeout,artist_ini_unchanged=unchanged,errors=errors)
    (out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(json.dumps({'status':receipt['status'],'host':a.year,'errors':errors}),flush=True)
    if not passed:raise SystemExit(1)
if __name__=='__main__':main()
