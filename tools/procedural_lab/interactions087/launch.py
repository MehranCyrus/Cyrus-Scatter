"""Matched Max 2027 owned-profile runner for 0.87 integration qualification."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,os,re,subprocess,time
ROOT=Path(__file__).resolve().parents[3]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    p=argparse.ArgumentParser();p.add_argument('--output',required=True,type=Path);p.add_argument('--script',required=True,type=Path)
    p.add_argument('--payload',type=Path,default=ROOT/'build/garden-investigation-20261025-01/scatter-payload')
    p.add_argument('--renderer',action='store_true');p.add_argument('--inspect',action='store_true');p.add_argument('--visible',action='store_true');p.add_argument('--stay-open',action='store_true');p.add_argument('--timeout',type=int,default=360)
    p.add_argument('--reset-before-exit',action='store_true',help='Release the owned scene before renderer/plugin process teardown')
    a=p.parse_args();out=a.output.resolve();assert out.is_relative_to(ROOT/'build');out.mkdir(parents=True,exist_ok=False)
    spec=importlib.util.spec_from_file_location('owned',ROOT/'tools/procedural_lab/source_container_preview/launch.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
    for rel in mod.DIRECTORIES.values(): (out/rel).mkdir(parents=True,exist_ok=True)
    artist=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini';original=artist.read_bytes();ini=original.decode('utf-16')
    for key,rel in mod.DIRECTORIES.items(): ini,count=re.subn(r'(?m)^'+re.escape(key)+r'=.*$',lambda _:key+'='+str(out/rel),ini);assert count==1
    (out/'max.ini').write_text(ini,encoding='utf-16')
    directories='[Directories]\nStandard=C:/Program Files/Autodesk/3ds Max 2027/stdplugs\n'
    if a.renderer: directories+='Installed2027=C:/Program Files/Autodesk/3ds Max 2027/Plugins/\n'
    (out/'plugins.ini').write_text(directories+'[Help]\n')
    payload=a.payload.resolve();modules={name:payload/name for name in ['AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm']}
    if a.inspect: modules['CyrusStemInspect.dlx']=ROOT/'build/vegetation-root-plugin-20261025-03/CyrusStemInspect.dlx'
    start='global GardenRun=@"'+out.as_posix()+'/"\ntry (\n'
    for name,path in modules.items(): start+='loadDllsFromDir @"'+path.parent.as_posix()+'/" "'+name+'"\n'
    start+='fileIn @"'+(payload/'CyrusScatter.ms').as_posix()+'"\n'
    preflight='''from pathlib import Path
import hashlib,json
from pymxs import runtime as rt
expected=EXPECTED
modules=rt.execute('(local p=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(); for i=0 to p.Modules.Count-1 collect #(p.Modules.Item[i].ModuleName,p.Modules.Item[i].FileName))')
loaded={str(x[0]).lower():Path(str(x[1])) for x in modules}
result={}
for name,path in expected.items():
 actual=loaded[name.lower()];assert actual.resolve()==Path(path).resolve(),name
 result[name]={'path':str(actual),'sha256':hashlib.sha256(actual.read_bytes()).hexdigest()}
assert int(rt.maxVersion()[0])==29000
(Path(str(rt.GardenRun))/'loaded-identity.json').write_text(json.dumps({'status':'pass','host':2027,'modules':result,'script_fingerprint':str(rt.CyrusLoadedScriptFingerprint)},indent=2))
'''.replace('EXPECTED',repr({name:str(path) for name,path in modules.items()}))
    (out/'preflight.py').write_text(preflight,encoding='utf-8')
    start+='python.ExecuteFile @"'+(out/'preflight.py').as_posix()+'"\n'
    start+='if not doesFileExist (GardenRun+"loaded-identity.json") do throw "Identity preflight failed"\n'
    if a.script.suffix.lower()=='.py': start+='python.ExecuteFile @"'+a.script.resolve().as_posix()+'"\n'
    else: start+='fileIn @"'+a.script.resolve().as_posix()+'"\n'
    if not a.stay_open:
        if a.reset_before_exit:start+='resetMaxFile #noPrompt\ngc light:true\n'
        start+='quitMax #noPrompt quiet:true exitCode:0\n'
    start+=')catch((dotNetClass "System.IO.File").WriteAllText (GardenRun+"bootstrap-error.txt") (getCurrentException()+"\\n"+getCurrentExceptionStackTrace());quitMax #noPrompt)\n'
    (out/'start.ms').write_text(start,encoding='utf-8-sig')
    cmd=['C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe','-q','-silent','-i',str(out/'max.ini'),'-p',str(out/'plugins.ini'),'-U','MAXScript',str(out/'start.ms'),'-listenerlog',str(out/'listener.log')]
    si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=5 if a.visible else 0
    proc=subprocess.Popen(cmd,cwd=out,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,startupinfo=si)
    report={'pid':proc.pid,'host':2027,'output':str(out),'command':cmd,'script':str(a.script.resolve()),'script_sha256':sha(a.script),'payload_script_sha256':sha(payload/'CyrusScatter.ms'),'native':{name:sha(path) for name,path in modules.items()},'artist_ini_sha256':hashlib.sha256(original).hexdigest()}
    (out/'launch.json').write_text(json.dumps(report,indent=2));print('Owned Max 2027 PID',proc.pid,str(out),flush=True)
    if a.stay_open: return
    end=time.monotonic()+a.timeout
    while proc.poll() is None and time.monotonic()<end: time.sleep(1)
    timed_out=proc.poll() is None
    if timed_out: proc.terminate();proc.wait(timeout=30)
    errors={name:(out/name).read_text(encoding='utf-8-sig') for name in ['error.txt','bootstrap-error.txt'] if (out/name).exists()}
    passed=not timed_out and proc.returncode==0 and not errors and (out/'completed.json').exists() and (out/'loaded-identity.json').exists() and artist.read_bytes()==original
    report.update(status='pass' if passed else 'failed',exit_code=proc.returncode,timed_out=timed_out,errors=errors,artist_ini_unchanged=artist.read_bytes()==original)
    (out/'receipt.json').write_text(json.dumps(report,indent=2));print(json.dumps({'status':report['status'],'exit_code':proc.returncode,'errors':errors}),flush=True)
    if not passed: raise SystemExit(1)
if __name__=='__main__': main()
